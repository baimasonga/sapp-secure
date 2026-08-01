import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/dashboard/presentation/home_screen.dart';
import 'package:salone_shield/features/onboarding/presentation/language_screen.dart';
import 'package:salone_shield/features/onboarding/presentation/onboarding_screen.dart';
import 'package:salone_shield/features/onboarding/presentation/permissions_screen.dart';
import 'package:salone_shield/features/settings/presentation/settings_screen.dart';

import '../support/test_harness.dart';

void main() {
  testWidgets('a first-time user starts at language selection', (tester) async {
    await pumpApp(tester, preferences: await createTestPreferences());

    expect(find.byType(LanguageScreen), findsOneWidget);
  });

  testWidgets('a returning user goes straight to the dashboard', (
    tester,
  ) async {
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('language, onboarding and permissions lead to the dashboard', (
    tester,
  ) async {
    final l10n = await localisationsFor('en');
    await pumpApp(tester, preferences: await createTestPreferences());

    await tester.tap(find.text('Krio'));
    await tester.pumpAndSettle();
    final krio = await localisationsFor('kri');

    await tester.tap(find.widgetWithText(FilledButton, krio.actionContinue));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Onboarding is now in Krio, which is the point of asking first.
    expect(find.text(krio.onboardingTitle1), findsOneWidget);
    expect(find.text(l10n.onboardingTitle1), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, krio.actionSkip));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionsScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, krio.actionContinue));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('onboarding completion survives a restart', (tester) async {
    final preferences = await createTestPreferences();
    await pumpApp(tester, preferences: preferences);
    final l10n = await localisationsFor('en');

    await tester.tap(find.widgetWithText(FilledButton, l10n.actionContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n.actionSkip));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionContinue));
    await tester.pumpAndSettle();

    expect(preferences.onboardingComplete, isTrue);

    // A fresh launch with the same stored preferences skips onboarding.
    await pumpApp(tester, preferences: preferences);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the dashboard leads to the analyser and back', (tester) async {
    final l10n = await localisationsFor('en');
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    await tester.tap(find.text(l10n.homeActionAnalyse));
    await tester.pumpAndSettle();
    expect(find.text(l10n.analyseInstruction), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('unbuilt dashboard features say so instead of doing nothing', (
    tester,
  ) async {
    final l10n = await localisationsFor('en');
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    await tester.tap(find.text(l10n.homeActionScreenshot));
    await tester.pumpAndSettle();

    expect(find.text(l10n.comingSoonTitle), findsOneWidget);
  });

  testWidgets('settings can switch the whole app to Krio', (tester) async {
    final english = await localisationsFor('en');
    final krio = await localisationsFor('kri');
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text(english.languageKrio));
    await tester.pumpAndSettle();

    expect(find.text(krio.settingsTitle), findsOneWidget);
    expect(find.text(english.settingsTitle), findsNothing);
  });

  testWidgets('the privacy screen states that codes are never requested', (
    tester,
  ) async {
    final l10n = await localisationsFor('en');
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(l10n.settingsPrivacyPolicy));
    await tester.tap(find.text(l10n.settingsPrivacyPolicy));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.text(l10n.neverAskTitle), findsOneWidget);
  });
}
