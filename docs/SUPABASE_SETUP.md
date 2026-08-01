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

**None of it has been run against a live project.** It is reviewed SQL, not
verified SQL.

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
