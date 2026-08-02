# Accessibility

Specification section 28 and milestone 8.

The reason this matters more here than in most apps: the thing a user has to
read is a warning, and the moment they read it is the moment they are being
pressured to send money. Text they have to squint at is a control that has
failed.

## What is enforced, on every push

`test/accessibility/` runs in CI. These are not a report from one afternoon —
they fail the build when a future change breaks them.

| Check | Standard | Where |
|---|---|---|
| Body and secondary text on every surface | WCAG AA, 4.5:1 | `contrast_test.dart` |
| Every risk band's text on its own container | 4.5:1 | `contrast_test.dart` |
| Risk meter bars and status icons | 3:1 (non-text) | `contrast_test.dart` |
| Text-field borders | 3:1 (component boundary) | `contrast_test.dart` |
| The accent used *as text* | 4.5:1 | `contrast_test.dart` |
| Text on the hero gradient, against its lightest stop | 4.5:1 | `contrast_test.dart` |
| Six screens at 130% and 200% text | no overflow | `large_text_test.dart` |
| Primary action height | ≥48dp, and the app's own 54 | `large_text_test.dart` |
| Icon buttons | ≥48×48 | `large_text_test.dart` |
| Risk result announces as one sentence | — | `large_text_test.dart` |
| The settings control has a name | — | `large_text_test.dart` |

Contrast is computed with the WCAG relative-luminance formula, compositing
translucent foregrounds *and* translucent backgrounds before measuring — a
tinted container over a surface is what the eye sees, and measuring against
the unflattened colour reports a ratio nobody experiences. The helper is
self-checked against the known 21:1 of black on white.

## What the audit found and changed

Every item below was a real defect in the shipped design, found by running the
checks rather than by looking.

| Found | Was | Now |
|---|---|---|
| Amber "be careful" text on its container | 3.85:1 — the warning band was the least readable text in the app | 5.0:1 |
| Amber meter bar and icon | 2.1:1 | 3.3:1 |
| Green "low risk" meter bar and icon | 2.7:1 | 3.6:1 |
| The accent as text on a dark background | 4.1:1 | 5.6:1 — dark mode now uses iris400, and takes dark text when the accent is a button fill |
| White on the dark-mode button | 4.49:1 | dark text on iris400, comfortably clear |
| Text-field borders | 1.5:1 light, 1.7:1 dark — a field you could not find | 3.4:1 both |
| Hero stat labels | 4.2:1 | 5.4:1 |
| Hero stat row at 200% text | overflowed by 28px, cutting off the wording | each stat takes half the width and wraps |
| The settings icon | announced as "button" | announced by name |

Two of these are worth dwelling on. **The amber band was the worst offender**,
and amber is the colour of the "be careful" verdict — the most common
non-trivial result the app produces. And **the text-field border** at 1.5:1
meant the single most important control in the app, the box you paste a
message into, was nearly invisible against its own background.

## Deliberate departures from the design system

The Gradient system was drawn for a desktop mock. Three departures are
recorded in code where they are made:

1. **Nothing below 12px, body at 15.5–17px** (`app_typography.dart`). A 13px
   caption that looks refined on a laptop is a barrier on a small phone.
2. **54dp minimum touch target**, above the 48dp guidance (`theme.dart`).
3. **Darker semantic colours than the tokens** for the amber and green bands
   (`theme.dart`), because the token values do not clear WCAG on their own
   containers.

## Not yet verified

These need a real device and are not claimed:

- [ ] TalkBack end to end: can a screen-reader user paste a message, run a
      check, and hear the verdict and the advice in a sensible order?
- [ ] Focus order and traversal with a keyboard or switch device.
- [ ] The app under Android's "display size" setting, which scales layout
      rather than text and is a different failure mode from the font scale
      tested here.
- [ ] Colour-blind review. Colour is never the only carrier of meaning — every
      risk level pairs its colour with an icon and a word — but that reasoning
      has not been checked with anyone who has a colour vision deficiency.
- [ ] Readability of the advice text with someone who reads English as a
      second or third language. This is the largest untested assumption in the
      app, and no automated check can stand in for it.
