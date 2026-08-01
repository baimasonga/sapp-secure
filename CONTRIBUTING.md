# Contributing

Thank you for helping protect people from fraud. A few working agreements.

## Before you start

Read [SECURITY.md](SECURITY.md) and [PRIVACY.md](PRIVACY.md). They contain hard
rules, not suggestions — most importantly that the app never collects a
verification code, a two-step PIN, or a mobile-money PIN, and never accuses
anyone of a crime.

## Checks

Every change must pass:

```bash
dart format .
flutter analyze     # must be clean, warnings included
flutter test
```

CI runs all three, plus a debug Android build.

## Pull requests

- Keep them focused. One feature or one fix.
- Add tests. New detection rules need a test; security fixes need a regression
  test.
- Update the documentation you invalidated, including the feature-status table
  in the README.
- Do not claim a feature works unless a test proves it. If something is partly
  done, say so in the PR and make the UI say so too.

## Style

- Null safety, immutable models, strong types.
- Keep widgets small and free of business logic.
- Comment the reasoning behind security-sensitive code, not the syntax.
- Match the surrounding code rather than introducing a new pattern.
- Do not add a dependency where the standard library will do.

## Detection rules

Rules are data: `assets/scam_rules/initial_rules.json`. Add English and Krio
patterns together, prefer specific phrases over single words, and check that the
rule does not push ordinary messages into a warning band. See
[docs/RISK_ENGINE.md](docs/RISK_ENGINE.md).

## Translations

See [LOCALISATION.md](LOCALISATION.md). Krio contributions from native speakers
are especially welcome.

## Reporting security issues

Privately, not in a public issue. See [SECURITY.md](SECURITY.md).
