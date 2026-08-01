# Architecture

## Shape

Feature-first, with a pure-Dart core.

```
lib/
├── app/
│   ├── bootstrap.dart      single startup path
│   ├── app.dart            MaterialApp.router, locale, theme
│   ├── router.dart         named routes (go_router)
│   ├── providers.dart      cross-feature providers
│   └── theme.dart          theme and the risk palette
├── core/
│   ├── config/             build-time configuration
│   ├── errors/             sealed AppFailure hierarchy
│   ├── localization/       localisation delegates incl. the Krio fallback
│   ├── storage/            shared preferences and encrypted storage
│   └── widgets/            shared UI
├── features/
│   ├── onboarding/         language, onboarding, permission explanations
│   ├── dashboard/          home
│   ├── message_analysis/   application/ (state) + presentation/ (screens)
│   └── settings/           settings and the in-app privacy summary
├── l10n/                   ARB sources and generated localisations
└── services/
    ├── risk_engine/        detection — no Flutter imports
    └── supabase/           optional backend bootstrap
```

Each feature owns `application/` (state, use cases) and `presentation/`
(widgets). Cross-feature state lives in `app/providers.dart`.

## Layer rules

1. `services/risk_engine/` must not import `package:flutter`. Only
   `rule_repository.dart` does, and only to read the bundled asset.
2. Widgets contain no business logic and never call Supabase.
3. Failures cross layers as `AppFailure`, never as raw exceptions or strings.
4. User-facing text comes from ARB files, except engine output, which is
   localised inside the engine (see below).

## Decisions

### The engine is pure Dart and carries its own strings

The engine must be testable without a widget tree and must eventually be able
to run in an isolate. Reaching into `AppLocalizations` would tie it to a
`BuildContext`. Instead, rule explanations and advice are localised **in the
rule JSON**, and the engine's own sentences live in `engine_strings.dart`. UI
chrome is localised normally through ARB files.

The cost is two places to translate; the benefit is that scoring, explanations
and advice stay together with the rule that produced them.

### Rules are data, not code

Detection lives in `assets/scam_rules/initial_rules.json`. Adding a scam
pattern is a data change, reviewable by someone who does not write Dart, and
the same file can later be delivered as a signed update from Supabase without
touching the engine.

### Escalation floors instead of inflated weights

Weights alone put a lone verification-code request at 35 — "Caution" — which is
wrong: a single request for your code is decisive. Rather than distort the
additive model by inflating the weight to 75, account-takeover rules declare an
`escalation_floor` that raises the final score to at least that value. The
scoring stays explainable ("35 from this rule, raised to 75 because a code
request alone is critical").

### Deterministic, not probabilistic

The first version is a rules engine, so every point of the score is
attributable and arguable. On-device machine learning is a later milestone, and
it will have to explain itself just as clearly before it ships.

### The app must be fully usable with no backend

Guest analysis is the primary path. `SupabaseBootstrap.initialise()` returns
`false` and the app continues if Supabase is unconfigured or unreachable. A
backend outage must never stop someone from checking a message.

### Failures are never silent, and never "safe"

If the rules cannot load, the user is told the app cannot check messages right
now. A security tool that fails towards "looks fine" is worse than no tool.

## State management

Riverpod. `preferencesServiceProvider` is overridden at startup with the loaded
instance (and in tests with an in-memory one), so no provider does async I/O at
first read. `riskEngineProvider` is a `FutureProvider` that builds the engine
once from the bundled rules.

## Navigation

`go_router` with a named-route enum (`AppRoute`), so a typo is a compile error.
The root route redirects on launch: unfinished onboarding goes to language
selection, everything else to the dashboard.

## Testing

- `test/risk_engine/` — pure unit tests, including every message from section
  36 of the specification.
- `test/services/` — storage retention and rule loading, including malformed
  and missing rule assets.
- `test/widget/` — screens and the real navigation flow, in both languages.

Widget tests inject the engine from disk (`engineOverride`) because
`rootBundle` asset I/O does not complete under the test framework's fake async
clock; the real bundle path is covered separately in
`test/services/rule_repository_test.dart`.
