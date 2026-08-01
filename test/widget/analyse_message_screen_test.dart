import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/message_analysis/application/analysis_controller.dart';
import 'package:salone_shield/features/message_analysis/presentation/analyse_message_screen.dart';
import 'package:salone_shield/services/risk_engine/models/risk_level.dart';

import '../support/test_harness.dart';

void main() {
  testWidgets('shows the privacy note before anything is typed', (
    tester,
  ) async {
    final preferences = await createTestPreferences();
    final l10n = await localisationsFor('en');

    await tester.pumpWidget(
      wrapForTest(const AnalyseMessageScreen(), preferences: preferences),
    );

    expect(find.text(l10n.analysePrivacyNote), findsOneWidget);
  });

  testWidgets('refuses to analyse an empty message and says why', (
    tester,
  ) async {
    final preferences = await createTestPreferences();
    final l10n = await localisationsFor('en');

    await tester.pumpWidget(
      wrapForTest(const AnalyseMessageScreen(), preferences: preferences),
    );

    await tester.tap(find.widgetWithText(FilledButton, l10n.analyseRun));
    await tester.pumpAndSettle();

    expect(find.text(l10n.analyseEmptyError), findsOneWidget);
    expect(
      containerOf(tester).read(analysisControllerProvider),
      isA<AnalysisFailed>(),
    );
  });

  testWidgets('analysing a scam message produces a critical assessment', (
    tester,
  ) async {
    final preferences = await createTestPreferences();
    final l10n = await localisationsFor('en');

    await tester.pumpWidget(
      wrapForTest(const AnalyseMessageScreen(), preferences: preferences),
    );

    await tester.enterText(
      find.byType(TextField),
      'Please send me the verification code urgently.',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.analyseRun));
    await tester.pumpAndSettle();

    final state = containerOf(tester).read(analysisControllerProvider);
    expect(state, isA<AnalysisSuccess>());
    expect((state as AnalysisSuccess).assessment.level, RiskLevel.critical);
  });

  testWidgets('the analysis is recorded without the message text', (
    tester,
  ) async {
    final preferences = await createTestPreferences();
    final l10n = await localisationsFor('en');

    await tester.pumpWidget(
      wrapForTest(const AnalyseMessageScreen(), preferences: preferences),
    );

    await tester.enterText(
      find.byType(TextField),
      'send me money to 076123456 urgently',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.analyseRun));
    await tester.pumpAndSettle();

    final history = preferences.recentAnalyses();
    expect(history, hasLength(1));
    expect(history.single.toString(), isNot(contains('076123456')));
    expect(history.single.toString(), isNot(contains('send me money')));
    expect(history.single['level'], isNotNull);
  });

  testWidgets('the screen is fully translated into Krio', (tester) async {
    final preferences = await createTestPreferences();
    final english = await localisationsFor('en');
    final krio = await localisationsFor('kri');

    await tester.pumpWidget(
      wrapForTest(
        const AnalyseMessageScreen(),
        preferences: preferences,
        locale: 'kri',
      ),
    );

    expect(krio.analyseRun, isNot(english.analyseRun));
    expect(find.text(krio.analyseRun), findsOneWidget);
    expect(find.text(english.analyseRun), findsNothing);
  });

  testWidgets('text shared into the app is pre-filled', (tester) async {
    final preferences = await createTestPreferences();

    await tester.pumpWidget(
      wrapForTest(
        const AnalyseMessageScreen(initialText: 'this is my new number'),
        preferences: preferences,
      ),
    );

    expect(find.text('this is my new number'), findsOneWidget);
  });
}
