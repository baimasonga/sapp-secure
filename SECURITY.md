# Security

## Reporting a vulnerability

Please report security issues privately rather than opening a public issue.
Include what you found, how to reproduce it, and what you think the impact is.
We will acknowledge the report, agree a disclosure timeline with you, and credit
you if you would like that.

Do not include real victims' messages, telephone numbers or screenshots in a
report. A redacted reproduction is always sufficient.

## Posture

### Implemented today

- **No sensitive permissions.** The manifest declares `INTERNET` only, and the
  app requests no runtime permissions.
- **No Accessibility Service**, no WhatsApp automation, no reading of another
  app's data. These are prohibited by design, not merely unimplemented.
- **Backups disabled.** `allowBackup=false` plus explicit data-extraction rules
  keep app data out of Google backup and device-to-device transfer.
- **Encrypted local storage** (`flutter_secure_storage`, Android Keystore) is
  the only place session material may live.
- **Secrets are build-time only**, passed via `--dart-define`, never committed.
  `.env` is git-ignored and `.env.example` holds no values.
- **Only the anon/publishable Supabase key** may reach a mobile build. The
  service-role key bypasses row-level security and must never be shipped.
- **Input is bounded.** Analysis truncates input at 20,000 characters before any
  regular expression runs, so a pasted megabyte cannot lock up a low-end phone.
  A test asserts this.
- **Suspicious links are never made tappable.** A flagged URL is rendered as
  plain selectable text, and the app does not open links it has just warned
  about. A test asserts this.
- **Failures are typed and never silent.** `AppFailure` carries whether data was
  saved and whether retry is safe. If the rule set cannot load, the user is told
  analysis is unavailable — the app never falls back to "looks fine".
- **Logging discipline.** Message content, matched excerpts, telephone numbers,
  contact names, tokens and configuration values are never logged. Caught
  backend errors are deliberately discarded rather than printed, because the
  exception text can carry a URL or key.

### Not yet implemented

Row-level security, indicator hashing with a server-side pepper, rate limiting,
moderator audit logging, private evidence storage, biometric app lock and
screenshot blocking all belong to the reporting and moderation milestones. None
of the features that need them are enabled, and none will ship before the
control does.

## Rules for contributors

1. Never collect a verification code, a two-step PIN, or a mobile-money PIN.
   There is no feature worth it.
2. Never weaken a security check to make a build pass.
3. Never broaden the permission set without an explanation screen and a review.
4. Never log message content or anything derived from it.
5. Add a regression test for every security fix.
6. Keep analysis local by default. Anything that sends data off the device needs
   an explicit, informed user action.
7. Never accuse. Output says "potential", "possible", "reported by others" —
   never that a person or number is criminal.

## Dependencies

Keep the dependency list short and prefer the platform or standard library. Each
new package is code running with the app's privileges on the phone of someone
who is already being targeted by a fraudster.
