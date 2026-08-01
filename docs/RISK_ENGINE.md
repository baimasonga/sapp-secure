# The risk engine

Deterministic, explainable and offline. The same message always produces the
same score, and every point of that score is attributable to a named rule the
user can read and disagree with.

## Pipeline

```
message text
  → truncate at 20,000 characters
  → normalise (lowercase, strip zero-width, fold quotes and dashes)
  → match pattern rules
  → extract and analyse links      → suspicious_url signal
  → extract telephone numbers
  → check cached community indicators → reported_indicator signal
  → compare sender against trusted contacts → unverified_sender signal
  → sum weights, apply escalation floors, clamp to 0–100
  → band the score, build actions, list limitations
```

Normalisation is used for matching only. The user always sees their own text.

## Scoring

The score is the sum of the weights of every rule that fired, clamped to
0–100. Weights follow section 9.1 of the specification:

| Rule | Weight |
|---|---|
| `verification_code_request` | 35 |
| `qr_code_request` | 30 |
| `reported_indicator` | 30 |
| `suspicious_url` | 25 |
| `loan_advance_fee` | 25 |
| `investment_return` | 25 |
| `financial_request` | 20 |
| `new_number_claim` | 18 |
| `refusal_to_call` | 20 |
| `third_party_payment` | 20 |
| `account_recovery` | 20 |
| `prize_lottery` | 20 |
| `threat_intimidation` | 20 |
| `urgency` | 12 |
| `secrecy` | 12 |
| `unverified_sender` | 10 |

## Bands

```
 0–24   Low
25–49   Caution
50–74   High
75–100  Critical
```

## Escalation floors

Some signals are decisive on their own. A lone verification-code request scores
35, which would band as "Caution" — plainly wrong, because there is no innocent
reason for someone to want the code that arrived on your phone.

Rather than distorting the additive model by inflating the weight, those rules
declare an `escalation_floor`: when the rule fires, the **final score is raised
to at least that value**. Both account-takeover rules use a floor of 75.

The explanation stays honest: the rule contributed 35 points, and the result was
raised to Critical because a code request alone is critical.

## Confidence

Each signal carries a confidence between 0 and 1. Pattern rules start at 0.6 and
gain 0.1 for each additional distinct phrase that matched, capped at 0.95 —
several independent phrasings of the same idea are stronger evidence than one
keyword that might be innocent. Derived signals set their own value (an unknown
sender is a fact, so it is 1.0).

Confidence is displayed. It does not scale the score, because a weight that
silently shrinks is a weight nobody can audit.

## Matching

Patterns are literal strings, matched case-insensitively with word boundaries so
"urgent" does not match inside "insurgent" and "otp" does not match inside a
random token. No user-supplied regular expressions are compiled, which keeps
catastrophic backtracking out of reach.

## Explainability

Every result carries four things (section 9.5), and the UI shows all of them:

1. **What was detected** — the rule's explanation and the exact matched words.
2. **Why it matters** — the rule's advice.
3. **What to do** — ordered recommended actions.
4. **What could not be checked** — always present, including on a Low result,
   so a clean score is never mistaken for a guarantee of safety.

## Editing the rules

Rules live in `assets/scam_rules/initial_rules.json`. Adding a scam pattern is a
data change; no Dart is involved.

```json
{
  "id": "financial_request",
  "category": "payment",
  "weight": 20,
  "enabled": true,
  "escalation_floor": 0,
  "derived": false,
  "explanation": { "en": "…", "kri": "…" },
  "advice":      { "en": "…", "kri": "…" },
  "patterns": ["send me money", "orange money", "sen mi money"]
}
```

| Field | Meaning |
|---|---|
| `id` | Unique. Duplicates are rejected at load time |
| `category` | Groups rules for the recommended-action logic |
| `weight` | 0–100. Anything outside that range is rejected |
| `enabled` | A disabled rule never fires |
| `escalation_floor` | Minimum final score when this rule fires; 0 for most |
| `derived` | True for rules produced by an analyser rather than by text matching. Derived rules must ship no patterns |
| `explanation` / `advice` | Per-language. Missing languages fall back to English |
| `patterns` | Normalised at load, so write them in lower case |

Both English and Krio patterns belong in the same rule, so a message that mixes
the two is scored once.

### Rules for writing rules

- Prefer specific phrases. `"send money"` is a rule; `"money"` is a false-positive
  generator.
- Add the Krio variant at the same time, or the rule only protects half the users.
- Add a test. `test/risk_engine/risk_engine_test.dart` asserts that every shipped
  rule has a weight, an explanation and advice in both languages.
- Check the combined effect: rules stack, so three cheap rules can push an
  ordinary message into "Caution".

## Deliberate non-goals

- No probability model, no network call, no telemetry.
- No claim that a message is definitely fraudulent.
- No labelling of a telephone number as criminal.
- Never failing towards "safe": if the rules cannot load, the app says analysis
  is unavailable.

## Testing

`test/risk_engine/` covers the rule set's integrity, all five specification test
messages from section 36, band thresholds, escalation, localisation and
fallback, determinism, context signals, oversized input, obfuscation, and the
guarantee that stored metadata contains no message content.
