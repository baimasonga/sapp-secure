import 'package:flutter/material.dart';

/// The Gradient type scale.
///
/// One typeface does everything. Hierarchy comes from size, weight and
/// tracking rather than from switching families, and display sizes track
/// negative. Display weight lives at 600 — the system resists heavy headlines.
///
/// One deliberate departure from the web tokens: nothing in the app goes below
/// 12px, and body text sits at 15–16px. The audience includes people reading a
/// warning on a small phone, sometimes aloud to someone else, and a 13px
/// caption that looks refined on a desktop mock is a barrier on a Tecno.
abstract final class AppType {
  static const String family = 'HankenGrotesk';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extrabold = FontWeight.w800;

  static const displayMd = TextStyle(
    fontSize: 34,
    height: 1.14,
    letterSpacing: -0.68,
    fontWeight: semibold,
  );

  static const headline = TextStyle(
    fontSize: 26,
    height: 1.22,
    letterSpacing: -0.42,
    fontWeight: semibold,
  );

  /// The hero figure on the result screen. The only extrabold in the app.
  static const score = TextStyle(
    fontSize: 34,
    height: 1.1,
    letterSpacing: -0.68,
    fontWeight: extrabold,
  );

  static const title = TextStyle(
    fontSize: 20,
    height: 1.3,
    letterSpacing: -0.22,
    fontWeight: semibold,
  );

  static const subtitle = TextStyle(
    fontSize: 17,
    height: 1.4,
    letterSpacing: -0.1,
    fontWeight: semibold,
  );

  static const bodyLg = TextStyle(fontSize: 17, height: 1.55);
  static const body = TextStyle(fontSize: 15.5, height: 1.55);
  static const bodySm = TextStyle(fontSize: 14, height: 1.5);
  static const caption = TextStyle(fontSize: 12.5, height: 1.45);

  /// The eyebrow. The only uppercase, positively-tracked style in the system.
  static const overline = TextStyle(
    fontSize: 12,
    height: 1.3,
    letterSpacing: 1.08,
    fontWeight: semibold,
  );

  static const button = TextStyle(
    fontSize: 15.5,
    height: 1.2,
    letterSpacing: -0.1,
    fontWeight: semibold,
  );

  /// Telephone numbers and references, so digits line up and cannot be
  /// misread. Falls back to the platform monospace.
  static const mono = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['RobotoMono', 'monospace'],
    fontSize: 15,
    height: 1.4,
  );

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayMedium: displayMd.copyWith(color: primary),
      headlineSmall: headline.copyWith(color: primary),
      titleLarge: title.copyWith(color: primary),
      titleMedium: subtitle.copyWith(color: primary),
      titleSmall: bodySm.copyWith(color: primary, fontWeight: semibold),
      bodyLarge: bodyLg.copyWith(color: primary),
      bodyMedium: body.copyWith(color: secondary),
      bodySmall: caption.copyWith(color: secondary),
      labelLarge: button.copyWith(color: primary),
      labelMedium: caption.copyWith(color: secondary, fontWeight: medium),
      labelSmall: overline.copyWith(color: secondary),
    ).apply(fontFamily: family);
  }
}
