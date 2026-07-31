import 'package:flutter/material.dart';

import '../services/risk_engine/models/risk_level.dart';

/// Visual language: calm, high contrast, and never alarming until the risk is
/// genuinely high (section 22).
abstract final class AppTheme {
  /// Deep teal — trustworthy without borrowing any messaging app's identity.
  static const Color seed = Color(0xFF00695C);

  /// Minimum touch target, above the 48dp platform guidance.
  static const double minTouchTarget = 56;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    );
  }
}

/// Colour, icon and label for each risk band.
///
/// Colour is never the only carrier of meaning (section 22 and section 28):
/// every use of a risk colour is paired with this icon and a text label.
class RiskPalette {
  const RiskPalette._({
    required this.container,
    required this.onContainer,
    required this.accent,
    required this.icon,
  });

  final Color container;
  final Color onContainer;
  final Color accent;
  final IconData icon;

  static RiskPalette of(BuildContext context, RiskLevel level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (level) {
      RiskLevel.low => RiskPalette._(
        container: isDark ? const Color(0xFF10281B) : const Color(0xFFE3F3E8),
        onContainer: isDark ? const Color(0xFFB8E6C6) : const Color(0xFF11492A),
        accent: const Color(0xFF1B7A44),
        icon: Icons.verified_user_outlined,
      ),
      RiskLevel.caution => RiskPalette._(
        container: isDark ? const Color(0xFF2E2410) : const Color(0xFFFDF2DC),
        onContainer: isDark ? const Color(0xFFF3D9A4) : const Color(0xFF5C4209),
        accent: const Color(0xFF9A6B00),
        icon: Icons.info_outline,
      ),
      RiskLevel.high => RiskPalette._(
        container: isDark ? const Color(0xFF3A2010) : const Color(0xFFFDE8DB),
        onContainer: isDark ? const Color(0xFFF7C6A6) : const Color(0xFF6B2F0A),
        accent: const Color(0xFFB4470F),
        icon: Icons.warning_amber_rounded,
      ),
      RiskLevel.critical => RiskPalette._(
        container: isDark ? const Color(0xFF3D1418) : const Color(0xFFFCE4E6),
        onContainer: isDark ? const Color(0xFFF6B7BC) : const Color(0xFF7A1721),
        accent: const Color(0xFFB3261E),
        icon: Icons.dangerous_outlined,
      ),
    };
  }
}
