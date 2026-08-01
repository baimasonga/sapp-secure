import 'package:flutter/material.dart';

/// The Gradient design system, expressed as Dart.
///
/// Ported from the supplied token CSS. Values are literal on purpose — they
/// are not snapped to a round grid, and changing one here changes it
/// everywhere, which is the point of having this layer at all.
///
/// The system's own rule, worth repeating because it is easy to break:
/// **95% neutral, 5% gradient.** One gradient per view, at a brand moment.
/// If two things on a screen use a gradient, one of them is wrong.
abstract final class DsColor {
  // Neutral — very slightly cool slate (hue ~260, low chroma).
  static const gray0 = Color(0xFFFFFFFF);
  static const gray25 = Color(0xFFFCFCFE);
  static const gray50 = Color(0xFFF8F8FB);
  static const gray100 = Color(0xFFF1F1F6);
  static const gray150 = Color(0xFFE9E9F1);
  static const gray200 = Color(0xFFE0E0EA);
  static const gray300 = Color(0xFFCFCFDC);
  static const gray400 = Color(0xFFADADBF);
  static const gray500 = Color(0xFF8A8A9C);
  static const gray600 = Color(0xFF68687A);
  static const gray700 = Color(0xFF4D4D5C);
  static const gray800 = Color(0xFF333340);
  static const gray900 = Color(0xFF20202B);
  static const gray950 = Color(0xFF14141B);
  static const gray1000 = Color(0xFF0C0C11);

  // Iris — the single chromatic voltage.
  static const iris50 = Color(0xFFEEEDFE);
  static const iris100 = Color(0xFFE1DEFC);
  static const iris200 = Color(0xFFC9C4F9);
  static const iris300 = Color(0xFFABA3F4);
  static const iris400 = Color(0xFF8B7FEE);
  static const iris500 = Color(0xFF7263E9);
  static const iris600 = Color(0xFF5D4EE0);
  static const iris700 = Color(0xFF4B3CCB);
  static const iris800 = Color(0xFF3E33A6);
  static const iris900 = Color(0xFF342C81);

  // Spectrum — composes the gradients only. Never a UI fill.
  static const spectrumIris = Color(0xFF5D4EE0);
  static const spectrumViolet = Color(0xFF8F5BE8);
  static const spectrumOrchid = Color(0xFFB458DF);
  static const spectrumRose = Color(0xFFEF6AA0);
  static const spectrumCoral = Color(0xFFFF8A6B);

  // Semantic — muted and refined, for status only.
  static const green500 = Color(0xFF2FA96B);
  static const green50 = Color(0xFFE6F6EE);
  static const green700 = Color(0xFF1F7A4C);
  static const amber500 = Color(0xFFE29A2B);
  static const amber50 = Color(0xFFFCF3E0);
  static const amber700 = Color(0xFFA86F14);
  static const red500 = Color(0xFFE5484D);
  static const red50 = Color(0xFFFDEAEA);
  static const red700 = Color(0xFFB42A2F);
  static const blue500 = Color(0xFF4A8CEA);
  static const blue50 = Color(0xFFE9F1FD);
  static const blue700 = Color(0xFF2C66BF);
}

/// 4px base grid. Whitespace is the medium — be generous.
abstract final class DsSpace {
  static const double x0_5 = 2;
  static const double x1 = 4;
  static const double x1_5 = 6;
  static const double x2 = 8;
  static const double x2_5 = 10;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 28;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;

  /// The horizontal margin every screen uses, so nothing sits at a different
  /// distance from the edge than anything else.
  static const double screenGutter = 16;
}

/// Soft-modern radii, never bubbly.
abstract final class DsRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double x2xl = 28;
  static const double pill = 9999;

  static BorderRadius all(double value) => BorderRadius.circular(value);
}

/// Elevation: soft, cool-tinted, low-opacity, layered. A single soft light
/// from high above — never harsh.
abstract final class DsShadow {
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0A14142B), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D14142B), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0D14142B), offset: Offset(0, 2), blurRadius: 6),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0A14142B), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(
      color: Color(0x1414142B),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x0D14142B),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x1A14142B),
      offset: Offset(0, 12),
      blurRadius: 28,
      spreadRadius: -4,
    ),
  ];

  /// Chromatic glow. Brand and primary CTA only, used sparingly.
  static const List<BoxShadow> glowIris = [
    BoxShadow(
      color: Color(0x665D4EE0),
      offset: Offset(0, 6),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];
}

/// The signature gradients. One per view.
abstract final class DsGradient {
  /// The hero sweep: cool iris resolving into warm coral.
  static const aurora = LinearGradient(
    begin: Alignment(-0.9, -0.6),
    end: Alignment(0.9, 0.6),
    colors: [
      DsColor.spectrumIris,
      DsColor.spectrumViolet,
      DsColor.spectrumRose,
      DsColor.spectrumCoral,
    ],
    stops: [0.0, 0.34, 0.70, 1.0],
  );

  /// The dark-canvas hero: deep indigo into plum.
  static const dusk = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF14141B),
      Color(0xFF241F52),
      Color(0xFF4A2F6E),
      Color(0xFF6E3A63),
    ],
    stops: [0.0, 0.48, 0.82, 1.0],
  );

  /// A mono-hue gradient for primary brand surfaces.
  static const iris = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7263E9), Color(0xFF5D4EE0), Color(0xFF4B3CCB)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Atmospheric wash layered over the dusk hero. Reads as light, not colour.
  static const List<RadialGradient> mesh = [
    RadialGradient(
      center: Alignment(-0.64, -0.56),
      radius: 0.9,
      colors: [Color(0x805D4EE0), Color(0x005D4EE0)],
    ),
    RadialGradient(
      center: Alignment(0.64, -0.64),
      radius: 0.8,
      colors: [Color(0x6BB458DF), Color(0x00B458DF)],
    ),
    RadialGradient(
      center: Alignment(0.4, 0.64),
      radius: 0.95,
      colors: [Color(0x66EF6AA0), Color(0x00EF6AA0)],
    ),
  ];
}

/// Subtle and quick. Nothing moves that does not need to.
abstract final class DsMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 240);
  static const Curve ease = Cubic(0.2, 0.9, 0.3, 1);
}
