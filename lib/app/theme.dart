import 'package:flutter/material.dart';

import '../services/risk_engine/models/risk_level.dart';
import 'design/app_typography.dart';
import 'design/design_tokens.dart';

/// The app theme, built from the Gradient design tokens.
///
/// Design character (specification section 22): trustworthy, calm, clear, and
/// non-alarming unless the risk is high. The design system supplies the calm;
/// the risk palette supplies the alarm, and only when it is earned.
abstract final class AppTheme {
  /// Above the 48dp platform guidance, because the audience includes people
  /// tapping in a hurry on a cheap screen.
  static const double minTouchTarget = 54;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final canvas = isDark ? DsColor.gray1000 : DsColor.gray25;
    final surface = isDark ? DsColor.gray950 : DsColor.gray0;
    final surfaceSunken = isDark ? const Color(0xFF0A0A0F) : DsColor.gray100;
    final textPrimary = isDark ? DsColor.gray50 : DsColor.gray900;
    final textSecondary = isDark ? DsColor.gray300 : DsColor.gray700;
    final borderSubtle = isDark ? const Color(0x12FFFFFF) : DsColor.gray150;

    // The accent differs by brightness for a contrast reason, not a taste one.
    // In light mode iris600 carries white text at 5.8:1. On a near-black
    // canvas that same iris600 is too dark to read *as* text (4.1:1), so dark
    // mode uses iris400, which reaches 5.6:1 as text — and then takes dark
    // text on top of it when it is used as a button fill.
    final accent = isDark ? DsColor.iris400 : DsColor.iris600;
    final onAccent = isDark ? DsColor.gray1000 : Colors.white;

    // A text field has to be findable. Its border is a component boundary
    // rather than decoration, so it clears 3:1 where the hairline between two
    // cards deliberately does not.
    final borderField = isDark ? DsColor.gray600 : DsColor.gray500;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: isDark ? const Color(0x297263E9) : DsColor.iris50,
      onPrimaryContainer: isDark ? DsColor.iris300 : DsColor.iris700,
      secondary: accent,
      onSecondary: onAccent,
      secondaryContainer: isDark ? const Color(0x297263E9) : DsColor.iris50,
      onSecondaryContainer: isDark ? DsColor.iris300 : DsColor.iris700,
      error: DsColor.red500,
      onError: Colors.white,
      errorContainer: isDark ? const Color(0x29E5484D) : DsColor.red50,
      onErrorContainer: isDark ? const Color(0xFFF4888C) : DsColor.red700,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: isDark ? DsColor.gray400 : DsColor.gray600,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: isDark ? DsColor.gray950 : DsColor.gray50,
      surfaceContainer: surface,
      surfaceContainerHigh: isDark ? DsColor.gray900 : DsColor.gray50,
      surfaceContainerHighest: surfaceSunken,
      outline: isDark ? const Color(0x2EFFFFFF) : DsColor.gray300,
      outlineVariant: borderSubtle,
      shadow: DsColor.gray950,
      scrim: isDark ? const Color(0xA3000000) : const Color(0x7014141B),
      inverseSurface: isDark ? DsColor.gray50 : DsColor.gray900,
      onInverseSurface: isDark ? DsColor.gray900 : DsColor.gray50,
      inversePrimary: isDark ? DsColor.iris700 : DsColor.iris300,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: AppType.family,
      textTheme: AppType.textTheme(textPrimary, textSecondary),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.subtitle.copyWith(
          color: textPrimary,
          fontFamily: AppType.family,
        ),
        shape: Border(bottom: BorderSide(color: borderSubtle)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: isDark ? DsColor.gray800 : DsColor.gray200,
          disabledForegroundColor: isDark ? DsColor.gray600 : DsColor.gray400,
          elevation: 0,
          textStyle: AppType.button.copyWith(fontFamily: AppType.family),
          shape: RoundedRectangleBorder(
            borderRadius: DsRadius.all(DsRadius.lg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          foregroundColor: textPrimary,
          backgroundColor: surface,
          side: BorderSide(color: borderSubtle),
          textStyle: AppType.button.copyWith(fontFamily: AppType.family),
          shape: RoundedRectangleBorder(
            borderRadius: DsRadius.all(DsRadius.lg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: AppType.button.copyWith(fontFamily: AppType.family),
          shape: RoundedRectangleBorder(
            borderRadius: DsRadius.all(DsRadius.sm),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: DsRadius.all(DsRadius.lg),
          side: BorderSide(color: borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? DsColor.gray950 : DsColor.gray0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DsSpace.x4,
          vertical: DsSpace.x4,
        ),
        hintStyle: AppType.body.copyWith(
          color: isDark ? DsColor.gray500 : DsColor.gray400,
        ),
        labelStyle: AppType.bodySm.copyWith(color: textSecondary),
        helperStyle: AppType.caption.copyWith(color: textSecondary),
        helperMaxLines: 3,
        border: OutlineInputBorder(
          borderRadius: DsRadius.all(DsRadius.lg),
          borderSide: BorderSide(color: borderField),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DsRadius.all(DsRadius.lg),
          borderSide: BorderSide(color: borderField),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DsRadius.all(DsRadius.lg),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DsRadius.all(DsRadius.lg),
          borderSide: const BorderSide(color: DsColor.red500),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: DsSpace.x3,
        iconColor: isDark ? DsColor.gray400 : DsColor.gray600,
        titleTextStyle: AppType.body.copyWith(
          color: textPrimary,
          fontFamily: AppType.family,
        ),
        subtitleTextStyle: AppType.caption.copyWith(
          color: textSecondary,
          fontFamily: AppType.family,
        ),
        shape: RoundedRectangleBorder(borderRadius: DsRadius.all(DsRadius.md)),
      ),
      dividerTheme: DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? DsColor.gray100 : DsColor.gray900,
        contentTextStyle: AppType.bodySm.copyWith(
          color: isDark ? DsColor.gray900 : DsColor.gray50,
          fontFamily: AppType.family,
        ),
        shape: RoundedRectangleBorder(borderRadius: DsRadius.all(DsRadius.md)),
        insetPadding: const EdgeInsets.all(DsSpace.x4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DsRadius.x2xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.all(DsRadius.xl)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSunken,
        selectedColor: isDark ? const Color(0x297263E9) : DsColor.iris50,
        side: BorderSide(color: borderSubtle),
        labelStyle: AppType.bodySm.copyWith(
          color: textPrimary,
          fontFamily: AppType.family,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: DsRadius.all(DsRadius.pill),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark ? const Color(0x297263E9) : DsColor.iris50,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppType.caption.copyWith(
            fontFamily: AppType.family,
            fontWeight: AppType.semibold,
            color: states.contains(WidgetState.selected)
                ? accent
                : (isDark ? DsColor.gray400 : DsColor.gray600),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: surfaceSunken,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (isDark ? DsColor.gray400 : DsColor.gray0),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : (isDark ? DsColor.gray800 : DsColor.gray200),
        ),
      ),
    );
  }
}

/// Colour, icon and label treatment for each risk band.
///
/// Colour is never the only carrier of meaning (sections 22 and 28): every use
/// is paired with this icon and a text label. The hues are the design system's
/// muted semantic set, not the loud red/amber/green of a typical alert UI —
/// alarm is reserved for the two bands that have earned it.
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
        container: isDark ? const Color(0x292FA96B) : DsColor.green50,
        onContainer: isDark ? const Color(0xFF6FD6A0) : DsColor.green700,
        // A darker green than the token in light mode: green500 on green50 is
        // 2.7:1, and this accent draws the meter bar and the icon, which carry
        // meaning and so need 3:1.
        accent: isDark ? DsColor.green500 : const Color(0xFF249160),
        icon: Icons.verified_user_outlined,
      ),
      RiskLevel.caution => RiskPalette._(
        container: isDark ? const Color(0x29E29A2B) : DsColor.amber50,
        // Amber is the hardest band to keep legible: the token amber700 on
        // amber50 is 3.9:1, and this is the text of a warning. Darkened until
        // it clears 4.5:1, with the accent following it to clear 3:1.
        onContainer: isDark ? const Color(0xFFF0BD6A) : const Color(0xFF8F5E10),
        accent: isDark ? DsColor.amber500 : const Color(0xFFB5791B),
        icon: Icons.info_outline,
      ),
      RiskLevel.high => RiskPalette._(
        container: isDark ? const Color(0x33FF8A6B) : const Color(0xFFFDEEE7),
        onContainer: isDark ? const Color(0xFFFFB399) : const Color(0xFF8C3A18),
        accent: const Color(0xFFD9622F),
        icon: Icons.warning_amber_rounded,
      ),
      RiskLevel.critical => RiskPalette._(
        container: isDark ? const Color(0x29E5484D) : DsColor.red50,
        onContainer: isDark ? const Color(0xFFF4888C) : DsColor.red700,
        accent: DsColor.red500,
        icon: Icons.dangerous_outlined,
      ),
    };
  }
}
