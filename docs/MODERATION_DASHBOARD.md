# Moderation dashboard

Specification milestone 6. A Flutter web application in this repository,
sharing the phone app's domain models, design system and risk vocabulary.

```bash
flutter run -d chrome -t lib/moderation_main.dart \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

flutter build web -t lib/moderation_main.dart --release \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## The anon key, and nothing stronger

The dashboard authenticates as the moderator and carries **only the anon
key** — the same key the phone app ships. It has no service-role key and must
never be given one. A web bundle is public: anyone who loads the page can read
every byte of it, so a service-role key in the build would hand every report in
the database to anyone who opened the developer console.

This means the dashboard can do exactly what row-level security permits the
signed-in moderator to do, and nothing more. That is the point. If a policy is
wrong, the dashboard cannot paper over it — and CI fails the build if a JWT of
any kind appears in the compiled output.

## What it shows

| Page | Contents |
|---|---|
| Queue | Reports awaiting review, **oldest first**. A newest-first queue buries the reports nobody has got to, which are the ones that need attention. |
| Report | The excerpt the reporter chose, the rules that fired on their phone, and the standing of the number — how many reports, from how many *distinct* people. |
| Audit log | Every decision, in order. Read-only, because the table is. |
| Rules | Remote detection rules. Administrator-only. |

## What it cannot show

**A telephone number.** The database holds a peppered hash and a mask
(`+232 ** *** 456`); the raw number was never stored. This is not a limitation
of the dashboard, and no amount of UI work would change it — the number is
genuinely not there. The screen says so, so a moderator does not go looking.

## Decisions

Five verdicts: verify, reject, needs more evidence, mark duplicate, archive.

Two rules are enforced in the UI, and both are about the person on the other
end of the decision:

- **Verifying or rejecting requires a written reason.** It is shown to the
  reporter, so the field is labelled as writing *to them*. A verdict with no
  explanation is a verdict nobody can learn from or contest.
- **Verifying warns first.** It is the one action whose result a stranger will
  see: verification is what makes an indicator visible to every user of the
  app.

Every decision writes an audit entry, and the gateway writes the entry
**before** the status change. If the update then fails, the log holds an
attempt that did not take effect — visible and recoverable. The other order can
leave a decision with no record of who made it, which is not.

`moderation_dashboard_test.dart` pins this down: there is no path through the
interface that records a verdict without an audit entry, and a server refusal
leaves both unwritten.

## Roles

| Role | May |
|---|---|
| `user` | Nothing. Refused at the door, explicitly — an empty queue would read as "no work today", which is the wrong thing to tell somebody who should not be here. |
| `moderator` | Work the queue, record verdicts, read the audit log and the rules. |
| `admin` | The above, plus enabling and disabling rules. |

Roles come from `profiles.role`, and a suspended moderator is not a moderator.

### Creating the first one

There is a chicken-and-egg problem the schema originally could not solve:
changing a role requires an existing administrator. `0003_moderation_fixes.sql`
adds a documented operator path.

```sql
select public.bootstrap_grant_role('<user-uuid>', 'admin');
```

Run it from the SQL editor or with the service role. It refuses to run from a
user session, so it cannot be reached from the dashboard or the app.

## What is not built

- **Evidence review.** The `evidence` storage bucket exists with owner-only
  policies, but the app has no upload path yet, so there is nothing to review.
  The page will follow the upload flow, not precede it.
- **Indicator merge across reports.** A report can be marked as a duplicate of
  another by id; merging the indicators behind them is not automated.
- **Confidence scoring as an input.** Confidence is computed by
  `refresh_indicator_confidence` from verified reports and distinct reporters.
  The dashboard shows the result and cannot override it, which is deliberate:
  a number that a moderator can type is not a measurement.
- **Rule editing beyond enable/disable.** Weights and patterns are read-only
  here. The phone app ships its own rules and does not read the remote table
  yet, so a change would affect nothing — the page says so rather than
  implying detection just improved.

## Deployment

The bundle is static. Serve `build/web` from any host, behind whatever access
control the deployment warrants — the dashboard's own auth is the last line,
not the only one. `web/index.html` carries `noindex, nofollow`; a moderation
queue must never be indexed, and CI checks that tag is still there.
