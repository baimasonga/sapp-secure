# Localisation

Salone Shield ships in English (`en`) and Krio (`kri`). Krio is not a secondary
nicety: for many of the people most exposed to these scams it is the language
they actually read, and a warning that is not understood is not a warning.

## Where text lives

There are two places, on purpose.

| Text | Location | Why |
|---|---|---|
| UI chrome — buttons, titles, labels, errors | `lib/l10n/app_en.arb`, `lib/l10n/app_kri.arb` | Standard Flutter localisation |
| Rule explanations and advice | `assets/scam_rules/initial_rules.json` | Keeps the wording next to the rule that produced it, and lets a rule be added without touching Dart |
| Engine summaries, recommended actions, limitations | `lib/services/risk_engine/engine_strings.dart` | The engine is pure Dart with no `BuildContext` |

Never hard-code user-facing text in a widget.

## Adding or changing a string

1. Add the key to `app_en.arb` **and** `app_kri.arb`.
2. Run `flutter gen-l10n`.
3. Use `AppLocalizations.of(context).yourKey`.

Generated files under `lib/l10n/` are committed so a fresh clone analyses
cleanly.

## Fallback behaviour

Flutter ships no Material translations for Krio. `appLocalizationsDelegates`
installs a fallback that serves the English framework strings for locales the
framework does not know, so selecting Krio cannot crash the app. App content is
fully translated; only the framework's own widget strings fall back.

In the engine, a missing language falls back to English rather than showing an
empty explanation. A test covers this.

## Krio review is required before release

The Krio in this repository is a **first draft written during development and
not yet reviewed by native speakers**. It must be reviewed before any public
release. Specifically:

- Orthography is inconsistent across sources; pick one convention and apply it.
- Security vocabulary ("verification code", "linked devices", "mobile money")
  needs wording that is understood in practice, not translated literally.
- Warnings must stay calm and clear. A frightening phrase that makes someone act
  faster is a failure, because acting fast is exactly what the scammer wants.
- Read every string aloud. Much of the audience will hear these words from a
  family member reading the screen to them.

Reviewers should work from the ARB files and the rule JSON together, since the
user sees both in one screen.

## Adding a third language

1. Add `lib/l10n/app_<code>.arb`.
2. Add the language to `EngineStrings.supportedLanguages` and to each `_pick`
   map in `engine_strings.dart`.
3. Add the language key to every rule's `explanation` and `advice` in the rule
   JSON.
4. Add the option to the language screen and to Settings.
5. Run `flutter test` — the rule-integrity test will fail for any rule missing
   the new language once it is added to the checked list.
