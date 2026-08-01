import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/threat_reporting/domain/threat_report.dart';
import 'package:salone_shield/features/threat_reporting/presentation/report_scam_screen.dart';
import 'package:salone_shield/l10n/app_localizations.dart';

import '../support/fake_reporting.dart';
import '../support/test_harness.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async => l10n = await localisationsFor('en'));

  Future<FakeReportGateway> pumpReport(
    WidgetTester tester, {
    FakeReportGateway? gateway,
    FakeAuthGateway? auth,
    String? initialNumber,
  }) async {
    final reports = gateway ?? FakeReportGateway();
    await tester.pumpWidget(
      wrapForTest(
        ReportScamScreen(initialNumber: initialNumber),
        preferences: await createOnboardedPreferences(),
        overrides: reportingOverrides(
          reports: reports,
          auth: auth ?? FakeAuthGateway(user: testUser),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return reports;
  }

  Future<void> tickConsent(WidgetTester tester) async {
    await scrollTo(tester, find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await scrollTo(
      tester,
      find.widgetWithText(FilledButton, l10n.reportSubmit),
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.reportSubmit));
    await tester.pumpAndSettle();
  }

  testWidgets('a signed-out user is told why an account is needed', (
    tester,
  ) async {
    await pumpReport(tester, auth: FakeAuthGateway());

    expect(find.text(l10n.reportSignInNeeded), findsOneWidget);
    // And reassured that nothing else requires one.
    expect(find.text(l10n.authGuestNote), findsOneWidget);
  });

  testWidgets('the form lists exactly what will be sent', (tester) async {
    await pumpReport(tester, initialNumber: '+23276123456');

    await scrollTo(tester, find.text(l10n.reportWhatIsSent));
    expect(find.text(l10n.reportWhatIsSentBody), findsOneWidget);
    expect(find.text('• +23276123456'), findsOneWidget);
  });

  testWidgets('an empty report says what is missing instead of sending', (
    tester,
  ) async {
    final gateway = await pumpReport(tester);

    await tickConsent(tester);
    await send(tester);

    expect(gateway.submitted, isEmpty);
    expect(find.text(l10n.reportNothingToSend), findsWidgets);
  });

  testWidgets('a report without consent is not sent', (tester) async {
    final gateway = await pumpReport(tester, initialNumber: '076123456');

    await send(tester);

    expect(gateway.submitted, isEmpty);
    expect(find.text(l10n.reportConsentRequired), findsOneWidget);
  });

  testWidgets('a complete report is sent and acknowledged with a reference', (
    tester,
  ) async {
    final gateway = await pumpReport(tester, initialNumber: '076123456');

    await tickConsent(tester);
    await send(tester);

    expect(gateway.submitted, hasLength(1));
    expect(gateway.submitted.single.reportedNumber, '076123456');
    expect(gateway.submitted.single.consentConfirmed, isTrue);
    expect(find.text(l10n.reportSubmittedTitle), findsOneWidget);
  });

  testWidgets('only what the user entered is sent', (tester) async {
    final gateway = await pumpReport(tester, initialNumber: '076123456');

    await tickConsent(tester);
    await send(tester);

    final submission = gateway.submitted.single.toSubmission();
    // Nothing was typed into these, so they must not appear at all.
    expect(submission.containsKey('message_excerpt'), isFalse);
    expect(submission.containsKey('district'), isFalse);
    expect(submission.containsKey('payment_number'), isFalse);
  });

  testWidgets('a repeat report is explained, not treated as an error', (
    tester,
  ) async {
    await pumpReport(
      tester,
      gateway: FakeReportGateway(duplicate: true),
      initialNumber: '076123456',
    );

    await tickConsent(tester);
    await send(tester);

    expect(find.text(l10n.reportDuplicateBody), findsOneWidget);
  });

  testWidgets('rate limiting is explained in plain language', (tester) async {
    await pumpReport(
      tester,
      gateway: FakeReportGateway(failWith: ReportFailureReason.rateLimited),
      initialNumber: '076123456',
    );

    await tickConsent(tester);
    await send(tester);

    expect(find.text(l10n.reportFailedRateLimited), findsOneWidget);
  });

  testWidgets('a network failure says nothing was saved and retry is safe', (
    tester,
  ) async {
    await pumpReport(
      tester,
      gateway: FakeReportGateway(failWith: ReportFailureReason.network),
      initialNumber: '076123456',
    );

    await tickConsent(tester);
    await send(tester);

    expect(find.text(l10n.reportFailedNetwork), findsOneWidget);
    expect(l10n.reportFailedNetwork, contains('nothing was saved'));
  });

  testWidgets('a suspended reporter is told, without losing their work', (
    tester,
  ) async {
    await pumpReport(
      tester,
      gateway: FakeReportGateway(failWith: ReportFailureReason.suspended),
      initialNumber: '076123456',
    );

    await tickConsent(tester);
    await send(tester);

    expect(find.text(l10n.reportFailedSuspended), findsOneWidget);
    expect(find.text('076123456'), findsOneWidget);
  });

  testWidgets('the form states that a report is not an accusation', (
    tester,
  ) async {
    await pumpReport(tester);

    await scrollTo(tester, find.text(l10n.reportNotAccusation));
    expect(find.text(l10n.reportNotAccusation), findsOneWidget);
  });
}
