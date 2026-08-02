import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/app/design/design_tokens.dart';
import 'package:salone_shield/app/theme.dart';
import 'package:salone_shield/services/risk_engine/models/risk_level.dart';

/// Contrast, checked rather than eyeballed.
///
/// The design system was ported from a desktop mock, and a pairing that looks
/// refined on a bright laptop can be unreadable on a cheap phone in daylight —
/// which is the situation this app is actually used in. WCAG 2.1 AA is the
/// floor: 4.5:1 for body text, 3:1 for large text and for the non-text parts
/// that carry meaning.
///
/// This runs on every push, so a future colour tweak that breaks a pair fails
/// the build instead of quietly making a warning harder to read.

/// WCAG relative luminance.
double _luminance(Color colour) {
  double channel(double value) {
    final v = value;
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(colour.r) +
      0.7152 * channel(colour.g) +
      0.0722 * channel(colour.b);
}

/// WCAG contrast ratio, 1:1 to 21:1.
double contrastRatio(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Flattens a translucent foreground over its background, because that is what
/// the eye actually sees. Several of the app's muted styles use alpha.
Color flatten(Color foreground, Color background) {
  final alpha = foreground.a;
  return Color.from(
    alpha: 1,
    red: foreground.r * alpha + background.r * (1 - alpha),
    green: foreground.g * alpha + background.g * (1 - alpha),
    blue: foreground.b * alpha + background.b * (1 - alpha),
  );
}

/// [background] may itself be translucent — several risk containers are a
/// tinted wash over the surface — so it is composited over [base] first.
/// Measuring text against an unflattened translucent container reports a
/// contrast nobody ever sees.
void expectContrast(
  String description,
  Color foreground,
  Color background, {
  double minimum = 4.5,
  Color base = const Color(0xFFFFFFFF),
}) {
  final solidBackground = flatten(background, base);
  final ratio = contrastRatio(
    flatten(foreground, solidBackground),
    solidBackground,
  );
  expect(
    ratio,
    greaterThanOrEqualTo(minimum),
    reason:
        '$description has a contrast ratio of ${ratio.toStringAsFixed(2)}:1, '
        'below the required ${minimum.toStringAsFixed(1)}:1',
  );
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    group('$name theme', () {
      final scheme = theme.colorScheme;

      test('body text on every surface it sits on', () {
        expectContrast(
          '$name onSurface on surface',
          scheme.onSurface,
          scheme.surface,
          base: scheme.surface,
        );
        expectContrast(
          '$name onSurface on the canvas',
          scheme.onSurface,
          scheme.surfaceContainerLowest,
        );
        expectContrast(
          '$name onSurface on a sunken panel',
          scheme.onSurface,
          scheme.surfaceContainerHighest,
        );
      });

      test('secondary text stays readable, not merely visible', () {
        // onSurfaceVariant carries captions, helper text and most of the
        // explanations. It is the pairing most likely to be sacrificed for
        // elegance, so it is held to the full body-text ratio.
        expectContrast(
          '$name onSurfaceVariant on surface',
          scheme.onSurfaceVariant,
          scheme.surface,
          base: scheme.surface,
        );
        expectContrast(
          '$name onSurfaceVariant on a sunken panel',
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest,
        );
      });

      test('buttons and their containers', () {
        expectContrast(
          '$name onPrimary on primary',
          scheme.onPrimary,
          scheme.primary,
        );
        expectContrast(
          '$name onPrimaryContainer on primaryContainer',
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
          base: scheme.surface,
        );
        expectContrast(
          '$name onErrorContainer on errorContainer',
          scheme.onErrorContainer,
          scheme.errorContainer,
          base: scheme.surface,
        );
      });

      testWidgets('every risk band is legible in its own colours', (
        tester,
      ) async {
        // The risk banner is the single most important thing to read in the
        // app: it is the sentence that tells someone not to send the money.
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                for (final level in RiskLevel.values) {
                  final palette = RiskPalette.of(context, level);
                  expectContrast(
                    '$name ${level.name} text on its container',
                    palette.onContainer,
                    palette.container,
                    base: scheme.surface,
                  );
                  // The accent carries the meter bars and icons — non-text
                  // meaning, so the 3:1 threshold applies.
                  expectContrast(
                    '$name ${level.name} accent on its container',
                    palette.accent,
                    palette.container,
                    minimum: 3,
                    base: scheme.surface,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('a text field can be found on the page', (tester) async {
        // WCAG 1.4.11 asks for 3:1 on the boundaries needed to *identify* a
        // component. A field the user cannot locate is the case that matters
        // here, since the whole app begins with pasting a message into one.
        //
        // The hairline between two cards is deliberately not held to this: it
        // is decoration, and a report that flagged it would be noise.
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                final border = Theme.of(
                  context,
                ).inputDecorationTheme.enabledBorder!.borderSide.color;
                expectContrast(
                  '$name text-field border on its fill',
                  border,
                  scheme.surface,
                  minimum: 3,
                  base: scheme.surface,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      test('the accent is readable as text, not just as a fill', () {
        // TextButton paints its label in the accent. On a dark canvas an
        // accent chosen for button fills is too dark to read.
        expectContrast(
          '$name accent as text on surface',
          scheme.primary,
          scheme.surface,
          base: scheme.surface,
        );
      });
    });
  }

  group('the gradient hero', () {
    // The hero is the one place the app puts text on a gradient, so it is
    // checked against the lightest stop — the worst case for white text. The
    // values come from the tokens rather than being copied here, so the test
    // cannot drift away from what the screen actually paints.
    const lightestDuskStop = DsColor.duskLightestStop;

    test('hero title on the lightest part of the sweep', () {
      expectContrast(
        'hero title on dusk',
        DsColor.onGradient,
        lightestDuskStop,
      );
    });

    test('hero body text, which is deliberately dimmed', () {
      expectContrast(
        'dimmed hero body on dusk',
        DsColor.onGradientMuted,
        lightestDuskStop,
      );
    });

    test('hero eyebrow, the dimmest text in the app', () {
      // Uppercase and small, so it must clear the body-text bar rather than
      // the large-text one.
      expectContrast(
        'hero eyebrow on dusk',
        DsColor.onGradientMuted,
        lightestDuskStop,
      );
    });

    test('hero stat labels', () {
      expectContrast(
        'hero stat label on dusk',
        DsColor.onGradientMuted,
        lightestDuskStop,
      );
    });
  });
}
