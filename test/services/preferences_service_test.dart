import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/core/storage/preferences_service.dart';
import 'package:salone_shield/services/risk_engine/models/risk_assessment.dart';

import '../support/test_harness.dart';

void main() {
  test('settings round-trip', () async {
    final preferences = await createTestPreferences();

    expect(preferences.languageCode, isNull);
    expect(preferences.onboardingComplete, isFalse);
    expect(preferences.analyticsConsent, isFalse, reason: 'must be opt-in');

    await preferences.setLanguageCode('kri');
    await preferences.setThemeMode('dark');
    await preferences.setOnboardingComplete();
    await preferences.setAnalyticsConsent(true);

    expect(preferences.languageCode, 'kri');
    expect(preferences.themeMode, 'dark');
    expect(preferences.onboardingComplete, isTrue);
    expect(preferences.analyticsConsent, isTrue);
  });

  group('analysis history', () {
    late PreferencesService preferences;

    setUp(() async => preferences = await createTestPreferences());

    RiskAssessment analyse(String message, {DateTime? at}) =>
        loadShippedEngine().analyse(message, now: at);

    test('stores metadata and never the message', () async {
      await preferences.addAnalysis(
        analyse('send me money to 076123456 urgently'),
      );

      final stored = preferences.recentAnalyses().single.toString();
      expect(stored, contains('financial_request'));
      expect(stored, isNot(contains('076123456')));
      expect(stored, isNot(contains('send me money')));
    });

    test('keeps the newest entries first and caps the list', () async {
      for (
        var index = 0;
        index < PreferencesService.maxRecentAnalyses + 5;
        index++
      ) {
        await preferences.addAnalysis(analyse('send money urgently'));
      }

      expect(
        preferences.recentAnalyses(),
        hasLength(PreferencesService.maxRecentAnalyses),
      );
    });

    test('drops entries past the retention window', () async {
      final old = DateTime.now().subtract(
        PreferencesService.recentAnalysisRetention + const Duration(days: 1),
      );
      await preferences.addAnalysis(analyse('send money urgently', at: old));
      await preferences.addAnalysis(analyse('send money urgently'));

      expect(preferences.recentAnalyses(), hasLength(1));
    });

    test('clearing removes everything', () async {
      await preferences.addAnalysis(analyse('send money urgently'));
      await preferences.clearHistory();

      expect(preferences.recentAnalyses(), isEmpty);
    });

    test(
      'a corrupt entry is skipped rather than crashing the dashboard',
      () async {
        final withJunk = await createTestPreferences({
          'flutter.history.recent_analyses': <String>['not json at all'],
        });

        expect(withJunk.recentAnalyses(), isEmpty);
      },
    );
  });
}
