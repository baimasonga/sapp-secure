# Development setup

## Requirements

- Flutter SDK 3.44 or newer (Dart 3.12+)
- JDK 17 or newer
- Android SDK with platform tools, and an emulator or a device
- `git`

Check the toolchain with `flutter doctor`.

## First run

```bash
git clone <repository-url>
cd salone-shield
flutter pub get
flutter run
```

The app is fully usable with no backend: message analysis is local, and guest
mode is the default path.

## Environment configuration

Configuration is passed at build time and never committed.

```bash
cp .env.example .env      # .env is git-ignored
flutter run --dart-define-from-file=.env
```

Use a separate Supabase project per environment (`development`, `staging`,
`production`). Only the anon/publishable key belongs in a mobile build — the
service-role key bypasses row-level security and must stay on the server.

## Turning the features on

Everything that leaves the device is behind a flag, and all of them default to
off. There is no runtime switch: a flag is compiled in, which is what makes
"this build cannot report anything" a fact rather than a setting.

| Flag | What it turns on | Safe to enable when |
|---|---|---|
| `ENABLE_REPORTING` | Accounts, report submission, the moderation queue | The RLS plan in `docs/SUPABASE_SETUP.md` has been run against that project, **and** moderators exist to work the queue |
| `ENABLE_NOTIFICATION_MONITORING` | The notification listener | The nine hardware checks in `docs/ANDROID_NOTIFICATION_SERVICE.md` are done |
| `ENABLE_ANALYTICS` | *Offers* the analytics opt-in in settings | Any time — it is off until the user agrees |
| `ENABLE_EXTERNAL_URL_REPUTATION` | Nothing yet | — see below |

`ENABLE_EXTERNAL_URL_REPUTATION` is **declared but unimplemented**. Link
checking is entirely on-device today and no reputation service is called, so
setting the flag changes no behaviour. It stays in the list so that the day
someone wires a service up, the switch is already where it belongs.

### A build with everything on

For testing on a real phone:

```bash
flutter build apk --debug \
  --dart-define=APP_ENV=staging \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY \
  --dart-define=ENABLE_REPORTING=true \
  --dart-define=ENABLE_NOTIFICATION_MONITORING=true \
  --dart-define=ENABLE_ANALYTICS=true
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Or put the same values in `.env` and use `--dart-define-from-file=.env`.

Without a local Android toolchain, run the **Test build (all features on)**
workflow from the Actions tab; it builds the same APK and attaches it. It
reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from repository secrets, refuses
to build if reporting was asked for and they are missing, and refuses outright
if the anon secret turns out to hold a service-role key.

**Reporting writes to a real database.** Enabling it against the production
project means test submissions become real rows that a moderator has to deal
with. Point a testing build at a separate Supabase project, or expect to clean
up afterwards.

## Everyday commands

```bash
dart format .                 # formatting (CI enforces this)
flutter analyze               # static analysis, must be clean
flutter test                  # unit and widget tests
flutter gen-l10n              # after editing any .arb file
flutter build apk --debug
flutter build appbundle --release --dart-define-from-file=.env
```

## Editing translations

Edit `lib/l10n/app_en.arb` and `lib/l10n/app_kri.arb`, then run
`flutter gen-l10n`. The generated files in `lib/l10n/` are committed so that a
fresh clone analyses without a code-generation step. See
[LOCALISATION.md](../LOCALISATION.md).

## Editing scam rules

Edit `assets/scam_rules/initial_rules.json` and run `flutter test`. No Dart
changes are needed to add a pattern. See [RISK_ENGINE.md](RISK_ENGINE.md).

## Project layout

See [ARCHITECTURE.md](../ARCHITECTURE.md).

## Troubleshooting

**`AppLocalizations` not found** — run `flutter gen-l10n`.

**Rules fail to load in the app** — the JSON is invalid, or a rule has a
duplicate id or an out-of-range weight. `flutter test` reports which.

**A widget test hangs on `pumpAndSettle`** — the test framework's fake clock
does not complete `rootBundle` asset I/O. Use the test harness, which injects
the engine from disk; the real bundle path is covered in
`test/services/rule_repository_test.dart`.
