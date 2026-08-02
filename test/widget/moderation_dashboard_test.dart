import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/app/theme.dart';
import 'package:salone_shield/features/threat_reporting/domain/threat_report.dart';
import 'package:salone_shield/moderation/data/moderation_gateway.dart';
import 'package:salone_shield/moderation/domain/moderation_models.dart';
import 'package:salone_shield/moderation/presentation/audit_log_page.dart';
import 'package:salone_shield/moderation/presentation/moderation_shell.dart';
import 'package:salone_shield/moderation/presentation/moderation_strings.dart';
import 'package:salone_shield/moderation/presentation/queue_page.dart';
import 'package:salone_shield/moderation/presentation/report_detail_page.dart';
import 'package:salone_shield/moderation/presentation/rules_page.dart';

import '../support/fake_moderation.dart';

/// The dashboard decides what the app tells people about a phone number, so
/// these tests are about who may decide, what they must say when they do, and
/// whether the record of it can go missing.
///
/// The Scaffold mirrors the shell: the pages are designed to live inside it
/// and do not carry one of their own.
Widget wrapModeration(Widget child, FakeModerationGateway gateway) =>
    ProviderScope(
      overrides: moderationOverrides(gateway),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );

/// The detail page puts the evidence above the verdict on purpose, so the
/// buttons start below the fold and the tests have to scroll past the
/// evidence too.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> chooseVerdict(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(ChoiceChip, label);
  await scrollTo(tester, chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Future<void> confirmVerdict(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, Mod.verdictTitle);
  await scrollTo(tester, button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('access', () {
    testWidgets('an ordinary account is refused, not shown an empty queue', (
      tester,
    ) async {
      final gateway = FakeModerationGateway(
        role: ModeratorRole.user,
        reports: [fakeReport()],
      );
      await tester.pumpWidget(
        wrapModeration(ModerationShell(onSignOut: () async {}), gateway),
      );
      await tester.pumpAndSettle();

      expect(find.text(Mod.notAModeratorTitle), findsOneWidget);
      // An empty queue would read as "no work today", which is the wrong
      // thing to tell somebody who should not be here.
      expect(find.byType(QueuePage), findsNothing);
      expect(find.text(Mod.queueEmpty), findsNothing);
    });

    testWidgets('a moderator gets the queue', (tester) async {
      final gateway = FakeModerationGateway(reports: [fakeReport()]);
      await tester.pumpWidget(
        wrapModeration(ModerationShell(onSignOut: () async {}), gateway),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QueuePage), findsOneWidget);
      expect(find.text(Mod.notAModeratorTitle), findsNothing);
    });

    testWidgets('rule editing is closed to a moderator, open to an admin', (
      tester,
    ) async {
      final rule = RemoteRule(
        id: 'rule-1',
        ruleCode: 'financial_request',
        category: 'payment',
        weight: 20,
        escalationFloor: 0,
        enabled: true,
        patternCount: 36,
        version: 1,
      );

      final asModerator = FakeModerationGateway(ruleList: [rule]);
      await tester.pumpWidget(wrapModeration(const RulesPage(), asModerator));
      await tester.pumpAndSettle();
      expect(find.text(Mod.rulesAdminOnly), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );

      final asAdmin = FakeModerationGateway(
        role: ModeratorRole.admin,
        ruleList: [rule],
      );
      await tester.pumpWidget(wrapModeration(const RulesPage(), asAdmin));
      await tester.pumpAndSettle();
      expect(find.text(Mod.rulesAdminOnly), findsNothing);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNotNull,
      );
    });
  });

  group('the queue', () {
    testWidgets('says so when there is nothing waiting', (tester) async {
      final gateway = FakeModerationGateway();
      await tester.pumpWidget(wrapModeration(const QueuePage(), gateway));
      await tester.pumpAndSettle();

      expect(find.text(Mod.queueEmpty), findsOneWidget);
    });

    testWidgets('shows the masked number and never a fuller one', (
      tester,
    ) async {
      final gateway = FakeModerationGateway(
        reports: [fakeReport(indicator: fakeIndicator())],
      );
      await tester.pumpWidget(wrapModeration(const QueuePage(), gateway));
      await tester.pumpAndSettle();

      expect(find.text('+232 ** *** 456'), findsOneWidget);
      expect(find.textContaining('123456'), findsNothing);
    });

    testWidgets('a load failure is stated, not shown as an empty queue', (
      tester,
    ) async {
      final gateway = FakeModerationGateway(
        failWith: ModerationFailureReasonForTest.network,
      );
      await tester.pumpWidget(wrapModeration(const QueuePage(), gateway));
      await tester.pumpAndSettle();

      expect(find.text(Mod.queueLoadFailed), findsOneWidget);
      expect(find.text(Mod.queueEmpty), findsNothing);
    });
  });

  group('a decision', () {
    Future<FakeModerationGateway> openDetail(
      WidgetTester tester, {
      QueuedReport? report,
    }) async {
      final gateway = FakeModerationGateway(
        reports: [report ?? fakeReport(indicator: fakeIndicator())],
      );
      await tester.pumpWidget(
        wrapModeration(const ReportDetailPage(reportId: 'report-1'), gateway),
      );
      await tester.pumpAndSettle();
      return gateway;
    }

    testWidgets('verifying without a reason is refused', (tester) async {
      final gateway = await openDetail(tester);

      await chooseVerdict(tester, Mod.verdictVerify);
      await confirmVerdict(tester);

      expect(find.text(Mod.noteRequired), findsOneWidget);
      expect(gateway.verdicts, isEmpty);
      expect(gateway.auditEntries, isEmpty);
    });

    testWidgets('verifying warns that users will see the result', (
      tester,
    ) async {
      await openDetail(tester);

      await chooseVerdict(tester, Mod.verdictVerify);

      expect(find.text(Mod.verifyWarning), findsOneWidget);
    });

    testWidgets('a recorded verdict always writes an audit entry', (
      tester,
    ) async {
      final gateway = await openDetail(tester);

      await chooseVerdict(tester, Mod.verdictVerify);
      final noteField = find.widgetWithText(TextField, Mod.noteLabel);
      await scrollTo(tester, noteField);
      await tester.enterText(
        noteField,
        'Three people reported this number independently.',
      );
      await confirmVerdict(tester);

      expect(gateway.verdicts, hasLength(1));
      expect(gateway.verdicts.single.verdict, Verdict.verify);

      // The property that matters: the decision and its record travel
      // together. There is no path through the UI that writes one alone.
      expect(gateway.auditEntries, hasLength(1));
      final entry = gateway.auditEntries.single;
      expect(entry.action, 'verify');
      expect(entry.previousStatus, 'pending');
      expect(entry.newStatus, 'verified');
      expect(entry.notes, contains('independently'));
    });

    testWidgets('asking for more evidence needs no reason', (tester) async {
      final gateway = await openDetail(tester);

      await chooseVerdict(tester, Mod.verdictNeedsEvidence);
      await confirmVerdict(tester);

      expect(gateway.verdicts, hasLength(1));
      expect(gateway.auditEntries, hasLength(1));
    });

    testWidgets('a server refusal leaves the decision unmade', (tester) async {
      final gateway = FakeModerationGateway(
        reports: [fakeReport(indicator: fakeIndicator())],
      );
      await tester.pumpWidget(
        wrapModeration(const ReportDetailPage(reportId: 'report-1'), gateway),
      );
      await tester.pumpAndSettle();

      gateway.failWith = ModerationFailureReasonForTest.rejectedByServer;
      await chooseVerdict(tester, Mod.verdictNeedsEvidence);
      await confirmVerdict(tester);

      expect(find.text(Mod.verdictFailed), findsOneWidget);
      expect(gateway.verdicts, isEmpty);
    });

    testWidgets('one reporter is flagged as not being corroboration', (
      tester,
    ) async {
      await openDetail(
        tester,
        report: fakeReport(
          indicator: fakeIndicator(reportCount: 4, distinctReporterCount: 1),
        ),
      );

      await scrollTo(tester, find.text(Mod.indicatorSingleReporter));
      expect(find.text(Mod.indicatorSingleReporter), findsOneWidget);
    });

    testWidgets('a decided report offers no second verdict', (tester) async {
      await openDetail(
        tester,
        report: fakeReport(status: ReportStatus.verified),
      );

      await scrollTo(tester, find.text(Mod.alreadyDecided));
      expect(find.text(Mod.alreadyDecided), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('a deleted reporter is stated on the report', (tester) async {
      await openDetail(tester, report: fakeReport(reporterId: null));

      await scrollTo(tester, find.text(Mod.reporterDeleted));
      expect(find.text(Mod.reporterDeleted), findsOneWidget);
    });
  });

  group('the audit log', () {
    testWidgets('offers no way to change an entry', (tester) async {
      final gateway = FakeModerationGateway(
        log: [
          ModerationEntry(
            id: 'entry-1',
            moderatorId: 'moderator-1',
            action: 'verify',
            createdAt: DateTime(2026, 7, 31),
            reportId: 'report-1',
            notes: 'Corroborated by three reporters.',
            previousStatus: 'pending',
            newStatus: 'verified',
          ),
        ],
      );
      await tester.pumpWidget(wrapModeration(const AuditLogPage(), gateway));
      await tester.pumpAndSettle();

      expect(find.text('verify'), findsOneWidget);
      expect(find.textContaining('Corroborated'), findsOneWidget);
      // The table has no update or delete policy for anyone, so the page has
      // nothing to offer beyond reading.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}

/// Re-exported so the test file reads without importing the gateway module
/// purely for an enum.
typedef ModerationFailureReasonForTest = ModerationFailureReason;
