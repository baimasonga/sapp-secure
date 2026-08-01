-- Salone Shield — initial schema, roles and row-level security.
--
-- Design rules this file follows, all of them load-bearing:
--
--   1. Every table has RLS enabled and a policy. A table with RLS off is a
--      data breach waiting for someone to find the anon key, which ships
--      inside the APK and must be assumed public.
--   2. Clients may never set anything that confers trust: report status,
--      confidence, or their own role. Those are enforced by triggers, because
--      RLS cannot restrict individual columns.
--   3. Telephone numbers are stored as peppered hashes only. The pepper lives
--      in the Edge Function's environment and never reaches the device.
--   4. Moderation is append-only. An audit trail you can edit is not one.
--
-- Deliberately NOT created: a table for trusted contacts. The app keeps them
-- on the device on purpose (see PRIVACY.md). A server-side copy of who each
-- user trusts would create exactly the breach the threat model warns about,
-- for a feature nobody asked for.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enumerated values, as check constraints so they are easy to extend later.
-- ---------------------------------------------------------------------------

create domain public.user_role as text
  check (value in ('user', 'moderator', 'admin'));

create domain public.report_status as text
  check (value in (
    'pending',
    'under_review',
    'needs_more_evidence',
    'verified',
    'rejected',
    'duplicate',
    'archived'
  ));

create domain public.threat_type as text
  check (value in (
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
    'other'
  ));

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  -- Peppered hash, written by the Edge Function. Never a raw number.
  phone_hash text,
  preferred_language text not null default 'en',
  district text,
  role public.user_role not null default 'user',
  is_suspended boolean not null default false,
  -- Reporter reputation, maintained server-side (section 17.4).
  reports_submitted integer not null default 0,
  reports_verified integer not null default 0,
  reports_rejected integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.profiles.phone_hash is
  'Peppered SHA-256. The raw number is never stored.';

-- Role checks used by other policies. SECURITY DEFINER so they bypass RLS on
-- profiles: without that, a policy on profiles that reads profiles recurses.
create or replace function public.current_role_is(required text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = required
      and is_suspended = false
  );
$$;

create or replace function public.is_moderator()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.current_role_is('moderator') or public.current_role_is('admin');
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.current_role_is('admin');
$$;

-- A user editing their own profile must not be able to promote themselves or
-- lift their own suspension. RLS cannot express "every column except these",
-- so a trigger does it.
create or replace function public.protect_profile_privileges()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if public.is_admin() then
    return new;
  end if;
  if new.role is distinct from old.role then
    raise exception 'Only an administrator may change a role.';
  end if;
  if new.is_suspended is distinct from old.is_suspended then
    raise exception 'Only an administrator may change suspension.';
  end if;
  if new.reports_submitted is distinct from old.reports_submitted
     or new.reports_verified is distinct from old.reports_verified
     or new.reports_rejected is distinct from old.reports_rejected then
    raise exception 'Reputation counters are maintained by the server.';
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger protect_profile_privileges
  before update on public.profiles
  for each row execute function public.protect_profile_privileges();

-- Every new auth user gets a profile with the lowest privilege.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;

create policy "profiles: read own"
  on public.profiles for select
  using (id = auth.uid());

create policy "profiles: moderators read all"
  on public.profiles for select
  using (public.is_moderator());

create policy "profiles: update own"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "profiles: admins update any"
  on public.profiles for update
  using (public.is_admin());

-- No insert policy: profiles are created by the auth trigger only.
-- No delete policy: account deletion cascades from auth.users.

-- ---------------------------------------------------------------------------
-- threat_reports
-- ---------------------------------------------------------------------------

create table public.threat_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references public.profiles(id) on delete set null,
  threat_type public.threat_type not null,
  reported_number_hash text,
  payment_number_hash text,
  reported_link text,
  -- A short excerpt the user chose to include, never a whole conversation.
  message_excerpt text check (message_excerpt is null or length(message_excerpt) <= 1000),
  risk_signals jsonb not null default '[]'::jsonb,
  district text,
  status public.report_status not null default 'pending',
  confidence_score numeric not null default 0 check (confidence_score between 0 and 100),
  consent_confirmed boolean not null default false,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id),
  -- Set when a moderator merges this into another report.
  duplicate_of uuid references public.threat_reports(id) on delete set null
);

create index threat_reports_reporter_idx on public.threat_reports (reporter_id, created_at desc);
create index threat_reports_status_idx on public.threat_reports (status, created_at desc);
create index threat_reports_number_idx on public.threat_reports (reported_number_hash);

-- A report with no consent is not a report. Enforced in the database as well
-- as the UI, because the UI is the part an attacker controls.
alter table public.threat_reports
  add constraint threat_reports_requires_consent check (consent_confirmed = true);

-- Clients submit; only moderators judge.
create or replace function public.protect_report_verdict()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    if new.status is distinct from 'pending' or new.confidence_score <> 0 then
      raise exception 'A new report starts as pending with no confidence.';
    end if;
    if new.reviewed_at is not null or new.reviewed_by is not null then
      raise exception 'A new report has not been reviewed.';
    end if;
    return new;
  end if;

  if not public.is_moderator() then
    raise exception 'Only a moderator may change a report.';
  end if;
  if new.reporter_id is distinct from old.reporter_id
     or new.created_at is distinct from old.created_at then
    raise exception 'Report provenance is immutable.';
  end if;
  new.reviewed_at := now();
  new.reviewed_by := auth.uid();
  return new;
end;
$$;

create trigger protect_report_verdict
  before insert or update on public.threat_reports
  for each row execute function public.protect_report_verdict();

alter table public.threat_reports enable row level security;

create policy "reports: submit own"
  on public.threat_reports for insert
  with check (
    reporter_id = auth.uid()
    and not exists (
      select 1 from public.profiles
      where id = auth.uid() and is_suspended = true
    )
  );

create policy "reports: read own"
  on public.threat_reports for select
  using (reporter_id = auth.uid());

create policy "reports: moderators read all"
  on public.threat_reports for select
  using (public.is_moderator());

create policy "reports: moderators update"
  on public.threat_reports for update
  using (public.is_moderator());

-- No delete policy. Reports are archived, never removed, so a moderator
-- cannot quietly erase a decision. Account deletion nulls the reporter.

-- ---------------------------------------------------------------------------
-- threat_indicators
-- ---------------------------------------------------------------------------

create table public.threat_indicators (
  id uuid primary key default gen_random_uuid(),
  indicator_type text not null check (indicator_type in ('phone', 'link', 'payment_number')),
  indicator_hash text not null,
  -- Never the full value: '+232 ** *** 123' (section 24).
  display_value_masked text,
  risk_level text not null default 'caution'
    check (risk_level in ('caution', 'high', 'critical')),
  report_count integer not null default 0,
  verified_report_count integer not null default 0,
  distinct_reporter_count integer not null default 0,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  status text not null default 'active'
    check (status in ('active', 'retired', 'disputed')),
  unique (indicator_type, indicator_hash)
);

alter table public.threat_indicators enable row level security;

-- Indicators are only readable once a moderator has verified enough
-- independent reports. Raw report counts never make something public, which
-- is what stops a pile-on from labelling an innocent number (section 17.3).
create policy "indicators: read verified only"
  on public.threat_indicators for select
  using (
    status = 'active'
    and verified_report_count > 0
  );

create policy "indicators: moderators read all"
  on public.threat_indicators for select
  using (public.is_moderator());

create policy "indicators: moderators update"
  on public.threat_indicators for update
  using (public.is_moderator());

-- No client insert. Indicators are created by the Edge Function only.

-- ---------------------------------------------------------------------------
-- moderation_actions — append-only audit log
-- ---------------------------------------------------------------------------

create table public.moderation_actions (
  id uuid primary key default gen_random_uuid(),
  moderator_id uuid not null references public.profiles(id),
  report_id uuid references public.threat_reports(id) on delete cascade,
  indicator_id uuid references public.threat_indicators(id) on delete cascade,
  action text not null,
  notes text,
  previous_status text,
  new_status text,
  created_at timestamptz not null default now()
);

create index moderation_actions_report_idx on public.moderation_actions (report_id, created_at desc);

alter table public.moderation_actions enable row level security;

create policy "moderation log: moderators append"
  on public.moderation_actions for insert
  with check (public.is_moderator() and moderator_id = auth.uid());

create policy "moderation log: moderators read"
  on public.moderation_actions for select
  using (public.is_moderator());

-- No update and no delete policy, for anyone including admins. The audit log
-- is append-only by construction.

-- ---------------------------------------------------------------------------
-- scam_rules — remote rule updates (not yet consumed by the app)
-- ---------------------------------------------------------------------------

create table public.scam_rules (
  id uuid primary key default gen_random_uuid(),
  rule_code text not null unique,
  category text not null,
  language text not null default 'en',
  patterns jsonb not null default '[]'::jsonb,
  weight integer not null check (weight between 0 and 100),
  escalation_floor integer not null default 0 check (escalation_floor between 0 and 100),
  explanation jsonb not null default '{}'::jsonb,
  advice jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.scam_rules enable row level security;

create policy "rules: anyone signed in may read"
  on public.scam_rules for select
  using (auth.uid() is not null);

create policy "rules: admins manage"
  on public.scam_rules for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- security_events — the user's own aggregate activity, if they consent
-- ---------------------------------------------------------------------------

create table public.security_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  event_type text not null,
  risk_score integer check (risk_score between 0 and 100),
  action_taken text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.security_events enable row level security;

create policy "events: write own"
  on public.security_events for insert
  with check (user_id = auth.uid());

create policy "events: read own"
  on public.security_events for select
  using (user_id = auth.uid());

create policy "events: delete own"
  on public.security_events for delete
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Evidence storage — private bucket, owner-only
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('evidence', 'evidence', false)
on conflict (id) do nothing;

create policy "evidence: upload own"
  on storage.objects for insert
  with check (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "evidence: read own"
  on storage.objects for select
  using (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "evidence: moderators read"
  on storage.objects for select
  using (bucket_id = 'evidence' and public.is_moderator());

create policy "evidence: delete own"
  on storage.objects for delete
  using (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
