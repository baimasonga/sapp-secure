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
Risk Analysis)** and **Milestone 3 (Verification and Trusted Contacts)** of the
build specification.

| Feature | State |
|---|---|
| English and Krio localisation | Working |
| Language selection, onboarding, permission explanations | Working |
| Home dashboard | Working |
| Paste-and-analyse a message | Working |
| Share a message from WhatsApp into the app | Working |
| Deterministic, explainable risk engine | Working |
| Sierra Leone phone-number extraction | Working |
| Offline link analysis | Working (feeds the risk score) |
| Trusted contacts, stored encrypted on the device | Working |
| Number comparison: is this a number that person actually uses? | Working |
| Verification workflow with call/SMS actions and recorded outcomes | Working |
| Local, message-free analysis history (30-day retention) | Working |
| Settings: language, theme, delete local history, privacy | Working |
| Optional Supabase bootstrap | Wired, inert until configured |
| Screenshot OCR, link-checker screen, reporting, moderation, notification monitoring | Not built — the dashboard says so plainly rather than hiding them |

Nothing in the table above is claimed as working unless it is covered by a test
that runs in CI.

## Architecture

Feature-first, with a pure-Dart core that has no Flutter dependency:

```
lib/
├── app/           bootstrap, router, theme, providers
├── core/          config, typed failures, localisation delegates, storage, shared widgets
├── features/      onboarding, dashboard, message_analysis, trusted_contacts,
│                  identity_verification, settings
├── l10n/          app_en.arb, app_kri.arb, generated localisations
└── services/      risk_engine (pure Dart), contacts, sharing, supabase
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
| `ENABLE_NOTIFICATION_MONITORING` | Off; the feature is not implemented yet |
| `ENABLE_EXTERNAL_URL_REPUTATION` | Off; link analysis is local-only |

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
- Android cloud backup and device-to-device transfer are disabled for app data.
- Analytics are opt-in and never include message content.

See [PRIVACY.md](PRIVACY.md) and [THREAT_MODEL.md](THREAT_MODEL.md).

## Known limitations

- The app has **not been run on a physical device or emulator**. The debug APK
  builds in CI and every screen is covered by widget tests, but nothing here
  substitutes for holding it in your hand — check the Krio layout, contrast and
  touch targets on a real low-end phone before release.
- The Krio strings are a first draft and **must be reviewed by native speakers**
  before any public release. See [LOCALISATION.md](LOCALISATION.md).
- The rules engine is keyword-based. It will miss reworded scams and can
  produce false positives; every result therefore states what could not be
  checked, and no result is presented as proof.
- Link analysis is heuristic and offline. It does not follow redirects, does not
  open pages, and its registrable-domain comparison is not a public-suffix list.
- Phone-number extraction assumes Sierra Leone for 8- and 9-digit local formats.
- The **contact picker has not been exercised on a device**. Its Kotlin compiles
  in CI and the Dart side is tested against a mocked channel, but the
  system-picker round trip needs a real phone. Typing a number always works.
- A number matching a trusted contact is reassuring, not proof: a stolen phone
  or a hijacked account still sends from the right number. The verification
  screen says so.
- Supabase tables, row-level security and reporting are not implemented yet, so
  the community-indicator rule has no data source and never fires in practice.
- No release signing configuration is committed.

## Native code

Two Kotlin files and nothing else.

`MainActivity.kt` reads `Intent.EXTRA_TEXT` from a share the user performed and
passes it to Dart over a method channel.

`ContactPickerDelegate.kt` opens the **system contact picker** with
`Intent.ACTION_PICK`. The picker runs in the system's own UI, the user chooses
exactly one person, and only that row comes back — so the app needs no
`READ_CONTACTS` permission and can never enumerate or upload the address book.

There is no notification listener and no Accessibility Service.

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
| [CONTRIBUTING.md](CONTRIBUTING.md) | Working agreements |

`DATABASE.md`, `MODERATION_POLICY.md`, `docs/SUPABASE_SETUP.md` and
`docs/ANDROID_NOTIFICATION_SERVICE.md` will be written alongside the milestones
that introduce those features.
