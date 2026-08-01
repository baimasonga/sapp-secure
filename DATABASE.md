# Database

PostgreSQL on Supabase. Migrations live in `supabase/migrations/` and are the
only way the schema changes.

**Nothing here has been run against a live project yet.** See
[docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) for the verification plan that
must pass before reporting is enabled.

## Tables

| Table | Holds | Who can read it |
|---|---|---|
| `profiles` | Display name, language, district, role, reputation counters | Own row; moderators read all |
| `threat_reports` | Submitted reports, with numbers as hashes | Own rows; moderators read all |
| `threat_indicators` | Aggregated counts per hashed indicator | Only once a moderator has verified a report; moderators read all |
| `moderation_actions` | Append-only audit log | Moderators |
| `scam_rules` | Remote rule updates | Any signed-in user; admins write |
| `security_events` | The user's own aggregate events | Own rows only |

## What is deliberately absent

**There is no table for trusted contacts.** The app keeps them on the device
and never uploads them. A server-side copy of who each user trusts would be one
of the most sensitive datasets the project could hold, for a feature nobody
asked for. See T14 in [THREAT_MODEL.md](THREAT_MODEL.md).

**There is no table of raw telephone numbers.** Numbers exist in the system
only as `sha256(type + pepper + e164)`, plus a mask like `+232 ** *** 456` for
display. The pepper lives in the Edge Function's environment and never reaches
a device. A database breach therefore yields hashes an attacker cannot reverse
without also stealing the pepper.

**There is no table of message content.** A report may carry a short excerpt
the user chose and edited, capped at 1000 characters by both the UI and a
database constraint. Whole conversations are never accepted.

## Things enforced by the database, not by the app

The UI is the part an attacker controls, so these live in Postgres:

- A report cannot be inserted without `consent_confirmed = true` (check
  constraint).
- A new report is always `pending` with confidence `0` (trigger).
- Only a moderator can change a report's status, and `reporter_id` and
  `created_at` are immutable (trigger).
- Only an administrator can change a `role` or a suspension, so a user cannot
  promote themselves (trigger).
- Reputation counters are server-maintained; clients cannot write them
  (trigger).
- `moderation_actions` has no update or delete policy for anyone, including
  administrators. The audit log is append-only by construction.
- Deleting a profile clears the excerpt and district from its reports, so a
  deleted account leaves nothing that identifies the reporter (trigger).

## Confidence

An indicator is invisible to users until `verified_report_count > 0`, which
only a moderator can cause. Levels then follow:

| Level | Requires |
|---|---|
| `caution` | One verified report |
| `high` | Two or more independent verified reporters |
| `critical` | Five or more independent verified reporters |

Raw report counts never promote an indicator. A number reported ten times by
one person stays at `distinct_reporter_count = 1`, which is the whole point:
it is what stops a pile-on from labelling someone innocent.

Rejecting the last verified report retires the indicator automatically, so a
retraction cannot be forgotten.

## Migrations

```bash
supabase db push          # apply
supabase db diff          # review before writing a new migration
```

Never edit a migration that has been applied to staging or production. Add a
new one.
