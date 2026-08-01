# Salone Shield

A privacy-first WhatsApp scam-protection companion for Sierra Leone.

Salone Shield helps people check a suspicious message **before** they send money,
share a security code, scan a QR code, or trust someone claiming to be a
familiar contact. Analysis runs on the phone. Nothing is uploaded.

> Never send money or share a security code until the person and the request
> have been independently verified.

## What Salone Shield is not

It is not a WhatsApp client, and it does not try to be one. It does not read
WhatsApp's database, bypass encryption, automate WhatsApp, or use Android's
Accessibility Service. It never asks for a WhatsApp verification code, a
two-step PIN, or a mobile-money PIN — and it never will, which is stated on the
dashboard so users learn to distrust anything that does ask.

It also avoids accusing anyone. Results are phrased as "potential scam",
"high-risk request" and "verify before acting", never as proof of a crime.

## Current status

This repository contains **Milestone 1 (Foundation)**, **Milestone 2 (Manual
Risk Analysis)** and **Milestone 3 (Verification and Trusted Contacts)** and **Milestone 4
(Screenshot and Link Analysis)** of the build specification, plus the
**Milestone 5 (Threat Reporting)** backend and client, which ship disabled.

| Feature | State |
|---|---|
| English UI, with every string in ARB files | Working |
| Onboarding and permission explanations | Working |
| Home dashboard | Working |
| Paste-and-analyse a message | Working |
| Share a message from WhatsApp into the app | Working |
| Deterministic, explainable risk engine | Working |
| Sierra Leone phone-number extraction | Working |
| Offline link analysis | Working (feeds the risk score) |
| Screenshot scanning with on-device OCR and an editable result | Working |
| Link checker screen | Working |
| Trusted contacts, stored encrypted on the device | Working |
| Number comparison: is this a number that person actually uses? | Working |
| Verification workflow with call/SMS actions and recorded outcomes | Working |
| Local, message-free analysis history (30-day retention) | Working |
| Settings: theme, delete local data, privacy | Working |
| Optional Supabase bootstrap | Wired, inert until configured |
| Supabase schema, RLS and Edge Function | **Verified against a live project** — all 24 checks pass; see below |
| Auth and report UI | Working; reporting stays behind a build flag — see below |
| Notification monitoring (listener, guard, interrupt filter, controls) | **Written but disabled** — see below |
| Moderation dashboard | Not built — the app says so plainly rather than hiding it |

Nothing in the table above is claimed as working unless it is covered by a test
that runs in CI.

### Notification monitoring is deliberately switched off

`ENABLE_NOTIFICATION_MONITORING` defaults to `false`. The listener, the guard
that decides what may be read, the interrupt filter, the three separate
switches and the settings screen are all written and covered by tests — Kotlin
unit tests on the JVM for the guard and filter, Dart tests for everything else,
both in CI. What has *not* happened is a single run on a physical Android
phone, and a notification listener is exactly the kind of code that behaves
differently there. `docs/ANDROID_NOTIFICATION_SERVICE.md` lists what to verify
on hardware before turning the flag on.

### The schema has now been run for real

The migrations were applied to a live Supabase project on 1 August 2026 and
the row-level security plan was executed against it. Doing so found four
defects that review had missed, including two that would have made the feature
useless in production: **moderation was entirely dead** — no report could ever
be verified or rejected, because two individually-correct triggers fought each
other — and **deleting an account failed outright**, removing a control the
specification requires. Both are fixed in `0003_moderation_fixes.sql`, and the
whole run is recorded in
[docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md#verification-record).

All twenty-four checks now pass, the Edge Function ones included: a report
submitted with someone else's `reporter_id` in the body is stored against the
sender, the eleventh report in an hour is refused, a repeat of the same number
is folded into the first, and the stored row holds a SHA-256 with the raw
number nowhere in it.

### Reporting is deliberately switched off

`ENABLE_REPORTING` defaults to `false`, and the app says so on the report
screen rather than hiding it. The schema, row-level security, Edge Function,
sign-in and report form are all written and unit-tested against fakes — but
**none of the SQL has been run against a live Supabase project**, so the RLS
policies are reviewed, not verified.

The anon key ships inside the APK and must be assumed public. The only thing
protecting reports from anyone holding it is RLS. Until the verification plan
in [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) passes against a real
project, that flag stays off.

## Architecture

Feature-first, with a pure-Dart core that has no Flutter dependency:

```
lib/
├── app/           bootstrap, router, theme, providers
├── core/          config, typed failures, localisation delegates, storage, shared widgets
├── features/      onboarding, authentication, dashboard, message_analysis,
│                  screenshot_analysis, link_analysis, trusted_contacts,
│                  identity_verification, threat_reporting, settings
├── l10n/          app_en.arb, generated localisations
└── services/      risk_engine (pure Dart), contacts, images, ocr, sharing,
                   supabase
```

`lib/services/risk_engine/` imports nothing from Flutter, so the scoring logic
is fast to test and can later be moved into an isolate. See
[ARCHITECTURE.md](ARCHITECTURE.md) and [docs/RISK_ENGINE.md](docs/RISK_ENGINE.md).

State management is Riverpod; navigation is `go_router`; no business logic
lives in widgets and no widget talks to Supabase directly.

## Local setup

Requires the Flutter SDK (3.44+, Dart 3.12+) and an Android SDK with JDK 17+.

```bash
flutter pub get
flutter gen-l10n          # after editing any .arb file
flutter run
```

## Environment variables

Configuration is passed at build time, never committed. Copy `.env.example` to
`.env` and use it:

```bash
flutter run --dart-define-from-file=.env
```

| Variable | Purpose |
|---|---|
| `APP_ENV` | `development`, `staging` or `production` |
| `SUPABASE_URL` | Supabase project URL. Empty means local-only mode |
| `SUPABASE_ANON_KEY` | Supabase anon/publishable key. **Never** the service-role key |
| `ENABLE_ANALYTICS` | Off by default; analytics also require in-app consent |
| `ENABLE_NOTIFICATION_MONITORING` | Off. Do not enable until the hardware checks in docs/ANDROID_NOTIFICATION_SERVICE.md are done |
| `ENABLE_EXTERNAL_URL_REPUTATION` | Off; link analysis is local-only |
| `ENABLE_REPORTING` | Off. The verification plan passes; what remains is named moderators, not code |

## Commands

```bash
dart format .                 # formatting
flutter analyze               # static analysis (must be clean)
flutter test                  # unit and widget tests
flutter build apk --debug     # debug build
flutter build appbundle --release --dart-define-from-file=.env
```

## Privacy principles

- Analysis is local-first; message text never leaves the device.
- Message text is not retained after the result screen is closed.
- Only message-free metadata (risk level, which rules matched, a timestamp) is
  stored locally, capped at 20 entries and 30 days, deletable at any time.
- The app declares only `INTERNET`, and requests no runtime permissions at all —
  including for contacts, which uses the system picker instead.
- Trusted contacts and verification outcomes live in encrypted storage
  (Android Keystore) and are never uploaded.
- Screenshots are read on the device by ML Kit; the app's copy of the image is
  deleted as soon as the text is out of it, and the original stays in the
  gallery untouched.
- Android cloud backup and device-to-device transfer are disabled for app data.
- Analytics are opt-in and never include message content.

See [PRIVACY.md](PRIVACY.md) and [THREAT_MODEL.md](THREAT_MODEL.md).

## Known limitations

- The app has **not been run on a physical device or emulator**. The debug APK
  builds in CI and every screen is covered by widget tests, but nothing here
  substitutes for holding it in your hand — check layout, contrast and touch
  targets on a real low-end phone before release.
- **English only.** Krio is drafted but parked until native speakers review it;
  the draft is in `l10n_drafts/`. Krio scam *patterns* are still detected — only
  the interface language is English. See [LOCALISATION.md](LOCALISATION.md).
- The rules engine is keyword-based. It will miss reworded scams and can
  produce false positives; every result therefore states what could not be
  checked, and no result is presented as proof.
- Link analysis is heuristic and offline. It does not follow redirects, does not
  open pages, and its registrable-domain comparison is not a public-suffix list.
- Phone-number extraction assumes Sierra Leone for 8- and 9-digit local formats.
- The **contact picker and OCR have not been exercised on a device**. They
  compile in CI and the Dart around them is tested against fakes, but the
  system-picker round trip and ML Kit's actual recognition quality need a real
  phone. Typing a number and pasting text always work.
- **OCR accuracy is unmeasured.** Recognised text is always shown for
  correction before analysis, which is the mitigation, but nobody has yet
  checked how it copes with WhatsApp screenshots on a small screen.
- ML Kit adds meaningfully to the APK size. Measure it against typical data
  costs before release; the model can be made downloadable if needed.
- A number matching a trusted contact is reassuring, not proof: a stolen phone
  or a hijacked account still sends from the right number. The verification
  screen says so.
- **The row-level security policies have never been executed.** They are the
  single most security-critical code in the project and they are unverified.
- Reporting needs moderators. Enabling it without people to work the queue
  would collect accusations nobody reads.
- The community-indicator rule still has no data source, so it never fires.
- No release signing configuration is committed.

## Native code

Two Kotlin files and nothing else.

`MainActivity.kt` reads `Intent.EXTRA_TEXT` from a share the user performed and
passes it to Dart over a method channel.

`ContactPickerDelegate.kt` opens the **system contact picker** with
`Intent.ACTION_PICK`. The picker runs in the system's own UI, the user chooses
exactly one person, and only that row comes back — so the app needs no
`READ_CONTACTS` permission and can never enumerate or upload the address book.

`NotificationSecurityService.kt` is a `NotificationListenerService`. It reads
notifications only from the messaging apps the user ticked, holds the text in
memory for at most fifteen minutes, never writes or uploads it, and never
repeats it in a notification of its own. It is guarded by
`BIND_NOTIFICATION_LISTENER_SERVICE`, which only the system holds. The whole
feature is off unless the build enables it — see
[docs/ANDROID_NOTIFICATION_SERVICE.md](docs/ANDROID_NOTIFICATION_SERVICE.md).

There is no Accessibility Service, and CI fails the build if one appears.

## Documentation

| Document | Contents |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layers, dependencies, decisions |
| [docs/RISK_ENGINE.md](docs/RISK_ENGINE.md) | Rules, weights, escalation, editing rules |
| [PRIVACY.md](PRIVACY.md) | What is and is not collected |
| [SECURITY.md](SECURITY.md) | Security posture and reporting a vulnerability |
| [THREAT_MODEL.md](THREAT_MODEL.md) | Threats, mitigations, residual risk |
| [LOCALISATION.md](LOCALISATION.md) | Adding and reviewing translations |
| [docs/SETUP.md](docs/SETUP.md) | Full development setup |
| [DATABASE.md](DATABASE.md) | Schema, what is deliberately absent, what the database enforces |
| [MODERATION_POLICY.md](MODERATION_POLICY.md) | How reports are judged, and by whom |
| [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) | Backend setup and the RLS verification plan |
| [docs/ANDROID_NOTIFICATION_SERVICE.md](docs/ANDROID_NOTIFICATION_SERVICE.md) | The notification listener, what it refuses to do, and what to verify on hardware |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Working agreements |
