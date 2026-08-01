import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:salone_shield/app/app.dart';
import 'package:salone_shield/app/providers.dart';
import 'package:salone_shield/app/router.dart';
import 'package:salone_shield/app/theme.dart';
import 'package:salone_shield/core/localization/app_localization_delegates.dart';
import 'package:salone_shield/core/storage/preferences_service.dart';
import 'package:salone_shield/features/message_analysis/presentation/risk_result_screen.dart';
import 'package:salone_shield/features/settings/presentation/settings_screen.dart';
import 'package:salone_shield/l10n/app_localizations.dart';
import 'package:salone_shield/services/risk_engine/risk_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the real engine from the shipped rules so widget tests exercise the
/// same detection logic as the app.
RiskEngine loadShippedEngine() => RiskEngine.fromJsonString(
  File('assets/scam_rules/initial_rules.json').readAsStringSync(),
);

/// Widget tests read the rules from disk rather than through `rootBundle`,
/// whose asset I/O does not complete inside the test framework's fake async
/// clock. `RuleRepository` covers the real bundle path in its own test.
final Override engineOverride = riskEngineProvider.overrideWith(
  (ref) => loadShippedEngine(),
);

/// Creates a [PreferencesService] backed by in-memory shared preferences.
Future<PreferencesService> createTestPreferences([
  Map<String, Object> initialValues = const {},
]) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return PreferencesService.create();
}

/// Preferences for a user who has already finished onboarding.
Future<PreferencesService> createOnboardedPreferences({
  String language = 'en',
}) => createTestPreferences({
  'flutter.onboarding.complete': true,
  'flutter.settings.language': language,
});

/// Wraps a single screen with the providers, localisations and theme it
/// expects, plus a router carrying the app's real route names so screens that
/// navigate behave as they do in the app. Use [pumpApp] when the test needs
/// the whole application including startup redirects.
Widget wrapForTest(
  Widget child, {
  required PreferencesService preferences,
  String locale = 'en',
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: AppRoute.analysisResult.path,
        name: AppRoute.analysisResult.name,
        builder: (context, state) => const RiskResultScreen(),
      ),
      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.name,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoute.privacy.path,
        name: AppRoute.privacy.name,
        builder: (context, state) => const PrivacyScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(preferences),
      engineOverride,
      ...overrides,
    ],
    child: MaterialApp.router(
      locale: Locale(locale),
      theme: AppTheme.light(),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

/// Pumps the whole application, including its router, so a test can walk the
/// same path a user walks.
Future<void> pumpApp(
  WidgetTester tester, {
  required PreferencesService preferences,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferences),
        engineOverride,
        ...overrides,
      ],
      child: const SaloneShieldApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Reads the localisations for a locale without needing a widget tree.
Future<AppLocalizations> localisationsFor(String locale) =>
    AppLocalizations.delegate.load(Locale(locale));

/// Reads a provider from a pumped widget tree.
ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(Router<Object>).first),
);

/// Scrolls the first scrollable until [finder] is visible.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
