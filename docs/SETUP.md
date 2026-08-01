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
