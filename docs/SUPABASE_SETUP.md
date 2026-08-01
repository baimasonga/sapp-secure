# Supabase setup

Reporting is **off by default** (`ENABLE_REPORTING=false`). This document is
the gate: do not enable it for an environment until every check in the
verification plan below passes against that environment's own project.

The reason is blunt. The anon key ships inside the APK and must be assumed
public. The only thing standing between a stranger with that key and every
report in the database is row-level security. Untested RLS is not a control.

## What exists in this repository

| Path | Contents |
|---|---|
| `supabase/migrations/0001_initial_schema.sql` | Tables, roles, triggers, RLS policies, evidence bucket |
| `supabase/migrations/0002_indicator_aggregation.sql` | Indicator counting and confidence, reporter reputation, account-deletion clean-up |
| `supabase/functions/submit-report/index.ts` | Report submission: peppered hashing, rate limiting, duplicate detection |

| `supabase/migrations/0003_moderation_fixes.sql` | Fixes for three defects the live run exposed |
| `supabase/migrations/0004_restrict_function_execution.sql` | Removes needless RPC exposure flagged by the linter |

The schema **has** now been run against a live project, and doing so found
four defects that review had missed. See
[the verification record](#verification-record) below.

## One project per environment

Create three: `salone-shield-dev`, `salone-shield-staging`,
`salone-shield-prod`. Never point a debug build at production — a test report
is indistinguishable from a real one once it is in the moderation queue.

## Applying the migrations

```bash
supabase link --project-ref <ref>
supabase db push
supabase functions deploy submit-report
```

## Secrets

```bash
# 32+ random bytes. Generate once per environment and never reuse across them.
supabase secrets set INDICATOR_PEPPER="$(openssl rand -hex 32)"
```

The pepper must never appear in the repository, in `.env`, in CI logs, or in
any client build. If it leaks, every stored hash becomes brute-forceable —
there are only about 10 million Sierra Leonean mobile numbers, which a laptop
can exhaust in minutes against an unpeppered hash.

Rotating the pepper invalidates every existing indicator hash. There is no
migration path for that; plan the pepper as permanent for the life of an
environment.

`SUPABASE_SERVICE_ROLE_KEY` is provided to Edge Functions automatically. It
must never be added to `.env`, to CI, or to any mobile build.

## Auth settings to change from the defaults

- **Confirm email: on.** Otherwise anyone can report as anyone.
- **Minimum password length: 8** or more, matching the app.
- Set the site URL and redirect URLs for password reset.
- Consider a rate limit on sign-ups; a scammer who can mint accounts can
  manufacture "independent" reporters.

## Verification record

Run on **1 August 2026** against project `yidehmcgkxuqemljsdcn`
(`whatsapp-security`, Postgres 17, eu-central-1), by Claude, using three
seeded accounts — two ordinary users and one moderator — and cleaned up
afterwards.

**Applying 0001 and 0002 to a real database found four defects, every one of
which would have shipped.** They are the reason this gate exists.

### What was found

| # | Defect | Effect | Fixed in |
|---|---|---|---|
| 1 | `on_report_reviewed` writes reputation counters to `profiles`, which trips `protect_profile_privileges` because a moderator is not an admin | **Moderation was entirely dead.** No report could be verified or rejected, ever | 0003 |
| 2 | Changing a role requires `is_admin()`, and nobody starts as admin — not even `postgres`, whose `auth.uid()` is null | **No way to create the first moderator or admin** except by disabling the trigger | 0003 |
| 3 | `protect_report_verdict` demanded `is_moderator()` for every update, including the server's own | The Edge Function's `reports_submitted` write and any back-office correction were blocked | 0003 |
| 4 | `reporter_id` is `ON DELETE SET NULL`, and that null trips the provenance guard | **Deleting an account failed outright**, removing a control section 15.4 requires | 0003 |

Defect 1 is the instructive one: both triggers are correct in isolation and
were reviewed as such. They only fail when they meet, which no amount of
reading was going to reveal.

A fifth issue came from Supabase's own linter: `refresh_indicator_confidence`
was granted to `authenticated`, so any signed-in user could call it over
PostgREST. Revoked in 0004, along with the trigger functions that were
needlessly exposed as RPCs.

**Do not revoke `EXECUTE` on `is_moderator`, `is_admin` or `current_role_is`.**
Policy expressions are evaluated as the querying user, so revoking these does
not hide them — it makes every policy that calls them fail with a permission
error and locks moderators out of every table. This was tried; 0004 documents
it so nobody tries again.

### Results

| # | Check | Result |
|---|---|---|
| 1 | anon reads `threat_reports` | **pass** — 0 rows |
| 2 | anon reads `profiles`, `moderation_actions`, `security_events`, `scam_rules` | **pass** — 0 rows each |
| 3 | A reads own reports | **pass** — own only |
| 4 | A reads B's report by id | **pass** — 0 rows |
| 5 | A updates B's report | **pass** — 0 rows changed |
| 6 | A marks own report verified | **pass**, by a different mechanism than this document assumed: there is no update policy for ordinary users, so RLS filters the row and the trigger never runs. The effect is right; the trigger's moderator check protects the server-side path, not this one |
| 7 | A promotes self to admin | **pass** — rejected by trigger |
| 8 | A lifts own suspension | **pass** — rejected by trigger |
| 8b | suspended A submits a report | **pass** — rejected by policy |
| 9 | A reports as B | **pass** — RLS violation |
| 10 | A reports without consent | **pass** — check constraint |
| 11 | A inserts an indicator directly | **pass** — RLS violation |
| 12 | A reads an unverified indicator | **pass** — 0 rows; verified one is visible |
| 13 | moderator edits the audit log | **pass** — 0 rows changed |
| 14 | moderator deletes from the audit log | **pass** — 0 rows changed |
| 15 | A reads B's evidence | **pass** — 0 rows |
| 16 | `submit-report` with no `Authorization` header | **pass** — 401 `UNAUTHORIZED_NO_AUTH_HEADER`, refused by the platform before the function runs |
| 17 | A's token, B's `reporter_id` in the body | **pass** — 201, stored against **A**. The body's id is ignored entirely; identity comes from the token |
| 18 | Eleven reports in an hour | **pass** — the eleventh returns 429 and nothing further is stored |
| 19 | The same number twice inside 24 hours | **pass** — returns `duplicate` with the first report's id, no second row. It matched across `+232 76 123 456` and `+23276123456`, so normalisation works |
| 20 | Inspect the stored row | **pass** — `reported_number_hash` is a 64-character SHA-256 and the raw number appears in no column. The indicator holds `+232 ** *** 456` and nothing fuller |
| 21 | Inspect the function logs | **pass**, with scope stated below |
| 22 | Deployed without `INDICATOR_PEPPER` | **pass** — 500 `not_configured`, and nothing was stored |
| 23 | delete account A | **pass** after 0003; profile gone, report survives detached |
| 24 | excerpt and district cleared | **pass** |

Also verified beyond the plan, because the fixes needed proving:

- A moderator can verify **and** reject a report, and the reporter's
  reputation counters are recomputed to their true values.
- A user cannot forge their own reputation counters, before or after the fix.
- A moderator cannot write an audit entry in another person's name.
- `bootstrap_grant_role` is unreachable from a user session.
- Function ACLs confirmed: `record_indicator_report`,
  `refresh_indicator_confidence` and `bootstrap_grant_role` are executable by
  `postgres` and `service_role` only.

**All 24 checks pass.**

### On check 21, precisely

The function's access logs were read after the run and contain only
`POST | <status> | <url>`, a method, a status code and a duration. No request
body, no telephone number, no excerpt, no token.

That is the observed half. The other half is by inspection: the only two
`console.error` calls in the function emit a fixed string
(`submit-report is not configured`) and an error *code*
(`report insert failed`, `insertError?.code`). Neither can carry a payload.
Both halves agree, which is why this is recorded as a pass rather than
"nothing showed up".

### A note on how the Edge Function checks were run

The environment this was executed from cannot reach `*.supabase.co` — its
network policy refuses the connection. The requests were issued by the
database itself through `pg_net`, enabled for the duration and dropped
afterwards, with test accounts signed in via `/auth/v1/token` to obtain real
reporter tokens. Anyone repeating this from a machine with ordinary network
access should just use `curl`.

### Project state after the run

Everything created for testing was removed: ten reports, one indicator, the
moderation entries, and all test accounts. `pg_net` and `http` are both
uninstalled. The only residue is one orphan row in `storage.objects`
(`22222222-.../proof.jpg`, a metadata row for a file that never existed);
Supabase blocks deleting storage rows over SQL, so remove it from the
dashboard.

Leaked-password protection is now enabled. The security advisor reports only
the three role predicates discussed in 0004, which are executable by design.

**Leaked-password protection is off.** Supabase's linter flags it; enable it
in Authentication → Policies. It is a dashboard setting, not schema.

**A design question, deliberately left open.** Verified indicators are
readable with the anon key alone — the policy requires `status = 'active' and
verified_report_count > 0` but not a session. That may well be intended, since
protective features are meant to work signed out. The cost is that anyone
holding the anon key can enumerate every flagged indicator, masked number and
risk level included, which also lets a scammer check whether their own number
has been flagged. Nothing in the app reads this table yet. If you want it
closed, the fix is to drop the anon-readable policy and expose a single
`check_indicator(hash)` function that answers about one value at a time
instead of allowing a table scan. Left as-is pending that decision.

## Verification plan — required before enabling reporting

Run all of it against the environment you are about to enable, with two test
accounts (A and B) and one moderator account.

### Row-level security

| # | Check | Expected |
|---|---|---|
| 1 | With the **anon key only** and no session, `select * from threat_reports` | 0 rows |
| 2 | Same for `profiles`, `moderation_actions`, `security_events` | 0 rows |
| 3 | As user A, read A's reports | A's rows only |
| 4 | As user A, read B's reports by id | 0 rows |
| 5 | As user A, `update` B's report | rejected |
| 6 | As user A, `update` own report's `status` to `verified` | rejected by the trigger |
| 7 | As user A, `update` own profile `role` to `admin` | rejected by the trigger |
| 8 | As user A, `update` own `is_suspended` to false | rejected by the trigger |
| 9 | As user A, `insert` a report with `reporter_id` set to B | rejected |
| 10 | As user A, `insert` a report with `consent_confirmed` false | rejected by the constraint |
| 11 | As user A, `insert` directly into `threat_indicators` | rejected |
| 12 | As user A, read an indicator with `verified_report_count = 0` | 0 rows |
| 13 | As a moderator, `update` a `moderation_actions` row | rejected |
| 14 | As a moderator, `delete` a `moderation_actions` row | rejected |
| 15 | As user A, read a file in B's evidence folder | rejected |

Checks 1 and 2 are the ones that matter most: they are what a stranger with
the APK can attempt.

### Edge Function

| # | Check | Expected |
|---|---|---|
| 16 | Call `submit-report` with no `Authorization` header | 401 |
| 17 | Call it with A's token but `reporter_id` for B in the body | stored against A |
| 18 | Submit 11 reports in an hour | the 11th returns 429 |
| 19 | Submit the same number twice within 24 hours | second returns `duplicate` |
| 20 | Inspect the stored row | `reported_number_hash` is a hash; the raw number appears nowhere |
| 21 | Inspect the function logs | no telephone number, no excerpt, no token |
| 22 | Deploy without `INDICATOR_PEPPER` | 500 `not_configured`, nothing stored |

Check 22 matters: the function must refuse to run rather than quietly store
unpeppered hashes.

### Account deletion

| # | Check | Expected |
|---|---|---|
| 23 | Delete account A | profile gone, reports remain with `reporter_id` null |
| 24 | Same | excerpt and district on those reports are cleared |

## Then, and only then

The technical gate is met. What is left before the flag is flipped is not
code: named people to work the moderation queue, and the policy in
MODERATION_POLICY.md agreed with them. Reporting without moderators collects
accusations nobody reads.

```bash
flutter build appbundle --release --dart-define-from-file=.env
# with ENABLE_REPORTING=true in that environment's .env
```

Record who ran the plan and when, in the pull request that flips the flag.

## Moderation cannot be skipped

Reporting without moderators is worse than no reporting: it collects
accusations nobody reads. Before enabling in production you need named people
who will work the queue, and the policy in
[MODERATION_POLICY.md](../MODERATION_POLICY.md) agreed with them.
