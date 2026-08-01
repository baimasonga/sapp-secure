import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/message_analysis/presentation/analyse_message_screen.dart';
import 'package:salone_shield/l10n/app_localizations.dart';

import '../support/test_harness.dart';

/// Runs an analysis through the real screen and lands on the result screen,
/// the same way a user gets there.
Future<void> analyseAndOpenResult(WidgetTester tester, String message) async {
  final preferences = await createTestPreferences();
  final l10n = await localisationsFor('en');
  await tester.pumpWidget(
    wrapForTest(const AnalyseMessageScreen(), preferences: preferences),
  );
  await tester.enterText(find.byType(TextField), message);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, l10n.analyseRun));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l10n;

  setUp(() async => l10n = await localisationsFor('en'));

  testWidgets('a critical result names the level, the score and the reasons', (
    tester,
  ) async {
    await analyseAndOpenResult(
      tester,
      'I mistakenly sent a six digit code to your phone. Send it urgently.',
    );

    expect(find.text(l10n.riskLevelCritical), findsOneWidget);
    // 35 + 12 on weights alone is only "Caution"; the account-takeover
    // escalation floor lifts it to 75.
    expect(
      find.textContaining(RegExp(r'^75/100$'), findRichText: true),
      findsOneWidget,
    );
    expect(find.text(sectionLabel(l10n.resultSignalsTitle)), findsOneWidget);
    await scrollTo(tester, find.text(sectionLabel(l10n.resultActionsTitle)));
    expect(find.text(sectionLabel(l10n.resultActionsTitle)), findsOneWidget);
  });

  testWidgets('the result never shows a score without an explanation', (
    tester,
  ) async {
    await analyseAndOpenResult(tester, 'send money urgently, do not call');

    // Section 9.5: what was detected, what to do, and what we could not check
    // must all be present.
    expect(find.text(sectionLabel(l10n.resultSignalsTitle)), findsOneWidget);
    await scrollTo(tester, find.text(sectionLabel(l10n.resultActionsTitle)));
    expect(find.text(sectionLabel(l10n.resultActionsTitle)), findsOneWidget);
    await scrollTo(tester, find.text(l10n.resultLimitationsTitle));
    expect(find.text(l10n.resultLimitationsTitle), findsOneWidget);
  });

  testWidgets('a clean message still shows limitations, not a green light', (
    tester,
  ) async {
    await analyseAndOpenResult(tester, 'Good morning, see you at church.');

    expect(find.text(l10n.riskLevelLow), findsOneWidget);
    expect(find.text(l10n.resultSignalsEmpty), findsOneWidget);
    await scrollTo(tester, find.text(l10n.resultLimitationsTitle));
    expect(find.text(l10n.resultLimitationsTitle), findsOneWidget);
  });

  testWidgets('extracted numbers are listed with a non-accusatory note', (
    tester,
  ) async {
    await analyseAndOpenResult(tester, 'Send the money to 076123456 now');

    await scrollTo(tester, find.text(sectionLabel(l10n.resultNumbersTitle)));
    expect(find.text('+23276123456'), findsOneWidget);
    expect(find.text(l10n.resultNumbersNote), findsOneWidget);
  });

  testWidgets('a suspicious link is described but not tappable', (
    tester,
  ) async {
    await analyseAndOpenResult(
      tester,
      'Verify your account at https://whatsapp-verify.tk/login',
    );

    await scrollTo(tester, find.text(sectionLabel(l10n.resultLinksTitle)));
    expect(find.text(l10n.resultLinksNote), findsOneWidget);
    expect(find.text('• ${l10n.urlFindingBrandLookalike}'), findsOneWidget);
    // The link is shown as selectable text, never as a launchable link.
    expect(
      find.byType(InkWell).evaluate().any((element) {
        final widget = element.widget as InkWell;
        return widget.onTap != null &&
            find
                .descendant(
                  of: find.byWidget(widget),
                  matching: find.textContaining('whatsapp-verify.tk'),
                )
                .evaluate()
                .isNotEmpty;
      }),
      isFalse,
    );
  });

  testWidgets('reporting is offered and explains itself without a backend', (
    tester,
  ) async {
    await analyseAndOpenResult(tester, 'send money urgently to 076123456');

    await scrollTo(
      tester,
      find.widgetWithText(OutlinedButton, l10n.resultReport),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.resultReport));
    await tester.pumpAndSettle();

    expect(find.text(l10n.reportUnavailableTitle), findsOneWidget);
  });
}
