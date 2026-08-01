# Localisation

Salone Shield currently ships in **English only**.

Krio is drafted but **parked**, because a security warning that has not been
checked by native speakers is not a warning — it is a guess with a shield icon
on it. Shipping a half-reviewed Krio UI would be worse than shipping none:
users would trust wording nobody had validated.

## Where the Krio draft lives

| File | Contents |
|---|---|
| `l10n_drafts/app_kri.arb` | Every UI string, drafted |
| `l10n_drafts/engine_strings_with_krio.dart.txt` | The engine's own sentences, before Krio was stripped |
| `assets/scam_rules/initial_rules.json` | Still ships Krio **patterns, explanations and advice** |

The rule set deliberately keeps its Krio content. Detection is not the same as
presentation: a scam written in Krio must still be caught today, and it is —
`test 5` in the engine tests covers exactly that. The rule-integrity test also
asserts the Krio explanations are present, so the draft cannot rot while it
waits for review.

## Bringing Krio back

1. Have native speakers review `l10n_drafts/app_kri.arb`, the Krio entries in
   the rule JSON, and the engine sentences in the `.dart.txt` reference.
2. Move the reviewed ARB back to `lib/l10n/app_kri.arb`.
3. Restore the Krio entries in `lib/services/risk_engine/engine_strings.dart`
   and add `'kri'` to `EngineStrings.supportedLanguages`.
4. Re-add the framework fallback delegate in
   `lib/core/localization/app_localization_delegates.dart`. Flutter ships no
   Material translations for `kri`, and without a fallback the framework throws
   the moment a user selects it. The implementation is in git history.
5. Restore the language picker: a first-launch screen and a Settings section.
6. Run `flutter gen-l10n`, then `flutter test`.

## What reviewers should look for

- **One orthography, applied consistently.** The draft mixes conventions.
- **Security vocabulary that people actually use** for "verification code",
  "linked devices" and "mobile money" — not literal translations.
- **Calm wording.** A frightening phrase that makes someone act faster is a
  failure: acting fast is what the scammer wants.
- **Read every string aloud.** Much of the audience will hear these words from
  a family member reading the screen to them.

## Adding strings while the app is English-only

1. Add the key to `lib/l10n/app_en.arb`.
2. Run `flutter gen-l10n`.
3. Use `AppLocalizations.of(context).yourKey`.

Never hard-code user-facing text in a widget. Keeping everything in the ARB is
what makes the eventual Krio release a translation job rather than a rewrite.

Generated files under `lib/l10n/` are committed so a fresh clone analyses
cleanly, and CI fails if they are stale.
