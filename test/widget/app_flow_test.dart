import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/app/providers.dart';
import 'package:salone_shield/features/dashboard/presentation/home_screen.dart';
import 'package:salone_shield/features/onboarding/presentation/onboarding_screen.dart';
import 'package:salone_shield/features/onboarding/presentation/permissions_screen.dart';
import 'package:salone_shield/features/settings/presentation/settings_screen.dart';
import 'package:salone_shield/services/sharing/shared_text_service.dart';

import '../support/test_harness.dart';

void main() {
  testWidgets('a first-time user starts at onboarding', (tester) async {
    await pumpApp(tester, preferences: await createTestPreferences());

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('a returning user goes straight to the dashboard', (
    tester,
  ) async {
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('onboarding and permissions lead to the dashboard', (
    tester,
  ) async {
    final l10n = await localisationsFor('en');
    await pumpApp(tester, preferences: await createTestPreferences());

    expect(find.text(l10n.onboardingTitle1), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, l10n.actionSkip));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionsScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, l10n.actionContinue));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('onboarding completion survives a restart', (tester) async {
    final preferences = await createTestPreferences();
    await pumpApp(tester, preferences: preferences);
    final l10n = await localisationsFor('en');

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

  testWidgets('a message shared from another app opens the analyser', (
    tester,
  ) async {
    const channel = MethodChannel('test/shared_text');
    const shared = 'This is my new number, send money urgently';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => shared);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final l10n = await localisationsFor('en');
    await pumpApp(
      tester,
      preferences: await createOnboardedPreferences(),
      overrides: [
        sharedTextServiceProvider.overrideWithValue(
          const SharedTextService(channel: channel),
        ),
      ],
    );
    await tester.pumpAndSettle();

    // The analyser opens with the shared message already in the field, so the
    // user only has to press Analyse.
    expect(find.text(l10n.analyseInstruction), findsOneWidget);
    expect(find.text(shared), findsOneWidget);
  });
}
