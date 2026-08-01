// Secure report submission (specification sections 16.3, 17.4 and 24).
//
// Everything here exists because the client cannot be trusted with it:
//
//   * The hashing pepper. If the app hashed numbers itself the pepper would
//     ship inside the APK, and anyone could brute-force the hash of every
//     Sierra Leonean mobile number in an afternoon. The raw number therefore
//     reaches this function over TLS, is hashed here, and is never written to
//     the database or the logs.
//   * Rate limiting and duplicate detection. Both are trivially bypassed if
//     enforced in the UI.
//   * Indicator counters. A client that can increment "how many people
//     reported this" can manufacture a reputation for an innocent number.
//
// The service-role key is available here and must never leave the server.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const INDICATOR_PEPPER = Deno.env.get('INDICATOR_PEPPER');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

/** No more than this many reports per reporter per rolling hour. */
const RATE_LIMIT_PER_HOUR = 10;

/** The same indicator from the same reporter inside this window is a repeat. */
const DUPLICATE_WINDOW_HOURS = 24;

const MAX_EXCERPT_LENGTH = 1000;

const THREAT_TYPES = new Set([
  'impersonation',
  'hijacked_account',
  'financial_help_scam',
  'verification_code_theft',
  'qr_code_scam',
  'mobile_money_scam',
  'malicious_link',
  'fake_job',
  'fake_loan',
  'fake_investment',
  'fake_prize',
  'blackmail',
  'other',
]);

interface ReportPayload {
  threat_type?: string;
  reported_number?: string | null;
  payment_number?: string | null;
  reported_link?: string | null;
  message_excerpt?: string | null;
  district?: string | null;
  risk_signals?: unknown;
  consent_confirmed?: boolean;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

/**
 * Peppered SHA-256 over a normalised value, namespaced by indicator type so
 * the same digits as a phone and as a payment number do not collide.
 */
async function hashIndicator(type: string, value: string): Promise<string> {
  const normalised = value.replace(/[^\d+]/g, '');
  const data = new TextEncoder().encode(`${type}:${INDICATOR_PEPPER}:${normalised}`);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

/** '+23276123456' becomes '+232 ** *** 456'. Never the whole number. */
function mask(value: string): string {
  const digits = value.replace(/\D/g, '');
  if (digits.length < 4) return '***';
  return `+${digits.slice(0, 3)} ** *** ${digits.slice(-3)}`;
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'method_not_allowed' }, 405);
  }
  // Refuse to run mis-configured rather than silently storing unpeppered
  // hashes, which would be worse than storing nothing.
  if (!INDICATOR_PEPPER || !SUPABASE_URL || !SERVICE_ROLE_KEY) {
    console.error('submit-report is not configured');
    return json({ error: 'not_configured' }, 500);
  }

  const authHeader = request.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return json({ error: 'unauthorised' }, 401);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // Identify the caller from their own token; never trust an id in the body.
  const { data: userData, error: userError } = await admin.auth.getUser(
    authHeader.replace('Bearer ', ''),
  );
  const user = userData?.user;
  if (userError || !user) {
    return json({ error: 'unauthorised' }, 401);
  }

  const { data: profile } = await admin
    .from('profiles')
    .select('id, is_suspended')
    .eq('id', user.id)
    .single();

  if (!profile) return json({ error: 'no_profile' }, 403);
  if (profile.is_suspended) return json({ error: 'suspended' }, 403);

  let payload: ReportPayload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  if (payload.consent_confirmed !== true) {
    return json({ error: 'consent_required' }, 400);
  }
  const threatType = payload.threat_type ?? '';
  if (!THREAT_TYPES.has(threatType)) {
    return json({ error: 'invalid_threat_type' }, 400);
  }
  const excerpt = payload.message_excerpt?.trim() || null;
  if (excerpt && excerpt.length > MAX_EXCERPT_LENGTH) {
    return json({ error: 'excerpt_too_long' }, 400);
  }
  if (!payload.reported_number && !payload.payment_number && !payload.reported_link) {
    return json({ error: 'nothing_to_report' }, 400);
  }

  // Rate limit (section 17.4).
  const hourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const { count: recentCount } = await admin
    .from('threat_reports')
    .select('id', { count: 'exact', head: true })
    .eq('reporter_id', user.id)
    .gte('created_at', hourAgo);

  if ((recentCount ?? 0) >= RATE_LIMIT_PER_HOUR) {
    return json({ error: 'rate_limited' }, 429);
  }

  const reportedNumberHash = payload.reported_number
    ? await hashIndicator('phone', payload.reported_number)
    : null;
  const paymentNumberHash = payload.payment_number
    ? await hashIndicator('payment_number', payload.payment_number)
    : null;

  // Duplicate detection: the same reporter flagging the same number again
  // within the window is one report, not two. Counting it twice is how a
  // single angry person manufactures a "campaign".
  if (reportedNumberHash) {
    const windowStart = new Date(
      Date.now() - DUPLICATE_WINDOW_HOURS * 60 * 60 * 1000,
    ).toISOString();
    const { data: existing } = await admin
      .from('threat_reports')
      .select('id')
      .eq('reporter_id', user.id)
      .eq('reported_number_hash', reportedNumberHash)
      .gte('created_at', windowStart)
      .limit(1);

    if (existing && existing.length > 0) {
      return json({ status: 'duplicate', report_id: existing[0].id }, 200);
    }
  }

  const { data: report, error: insertError } = await admin
    .from('threat_reports')
    .insert({
      reporter_id: user.id,
      threat_type: threatType,
      reported_number_hash: reportedNumberHash,
      payment_number_hash: paymentNumberHash,
      reported_link: payload.reported_link ?? null,
      message_excerpt: excerpt,
      risk_signals: Array.isArray(payload.risk_signals) ? payload.risk_signals : [],
      district: payload.district ?? null,
      consent_confirmed: true,
    })
    .select('id, status, created_at')
    .single();

  if (insertError || !report) {
    // Deliberately vague to the client, and the payload is never logged: it
    // contains a telephone number.
    console.error('report insert failed', insertError?.code);
    return json({ error: 'submission_failed' }, 500);
  }

  // Track the indicator, but only as counts. Nothing here makes the number
  // publicly visible: reading an indicator requires a moderator to have
  // verified at least one report first (see the RLS policy).
  for (const [type, hash, raw] of [
    ['phone', reportedNumberHash, payload.reported_number],
    ['payment_number', paymentNumberHash, payload.payment_number],
  ] as const) {
    if (!hash || !raw) continue;
    await admin.rpc('record_indicator_report', {
      p_indicator_type: type,
      p_indicator_hash: hash,
      p_masked: mask(raw),
      p_reporter: user.id,
    });
  }

  await admin
    .from('profiles')
    .update({ reports_submitted: (await countReports(admin, user.id)) })
    .eq('id', user.id);

  return json({
    status: 'submitted',
    report_id: report.id,
    submitted_at: report.created_at,
  }, 201);
});

async function countReports(
  admin: ReturnType<typeof createClient>,
  userId: string,
): Promise<number> {
  const { count } = await admin
    .from('threat_reports')
    .select('id', { count: 'exact', head: true })
    .eq('reporter_id', userId);
  return count ?? 0;
}
