import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/link_analysis/presentation/link_checker_screen.dart';
import 'package:salone_shield/l10n/app_localizations.dart';

import '../support/test_harness.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async => l10n = await localisationsFor('en'));

  Future<void> pumpChecker(WidgetTester tester, {String? initialUrl}) async {
    await tester.pumpWidget(
      wrapForTest(
        LinkCheckerScreen(initialUrl: initialUrl),
        preferences: await createOnboardedPreferences(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> check(WidgetTester tester, String input) async {
    await tester.enterText(find.byType(TextField), input);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.linkCheckRun));
    await tester.pumpAndSettle();
  }

  testWidgets('states up front that links are never opened', (tester) async {
    await pumpChecker(tester);

    expect(find.text(l10n.linkCheckNotOpened), findsOneWidget);
  });

  testWidgets('an empty input is refused with a reason', (tester) async {
    await pumpChecker(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.linkCheckRun));
    await tester.pumpAndSettle();

    expect(find.text(l10n.linkCheckEmptyError), findsOneWidget);
  });

  testWidgets('text with no link in it is refused', (tester) async {
    await pumpChecker(tester);
    await check(tester, 'good morning how are you');

    expect(find.text(l10n.linkCheckInvalid), findsOneWidget);
  });

  testWidgets('a brand look-alike is called out by name', (tester) async {
    await pumpChecker(tester);
    await check(tester, 'https://whatsapp-verify.tk/login');

    expect(find.text(l10n.linkCheckResultDangerTitle), findsOneWidget);
    expect(find.text(l10n.linkCheckBrandWarning('whatsapp')), findsOneWidget);
    await scrollTo(tester, find.text(l10n.linkCheckAdviceDanger));
    expect(find.text(l10n.linkCheckAdviceDanger), findsOneWidget);
  });

  testWidgets('the real domain is shown, not just the address', (tester) async {
    await pumpChecker(tester);
    await check(tester, 'https://secure.login.verify.account.example.com/x');

    await scrollTo(tester, find.text(l10n.linkCheckDomain));
    expect(
      find.text('secure.login.verify.account.example.com'),
      findsOneWidget,
    );
    expect(find.text(l10n.urlFindingSubdomains), findsOneWidget);
  });

  testWidgets('a whole pasted message is accepted, not just a bare link', (
    tester,
  ) async {
    await pumpChecker(tester);
    await check(
      tester,
      'Claim your prize now at https://claim-now.tk/win before it expires',
    );

    await scrollTo(tester, find.text(l10n.linkCheckDomain));
    expect(find.text('claim-now.tk'), findsOneWidget);
  });

  testWidgets('a clean link is not called safe, only unremarkable', (
    tester,
  ) async {
    await pumpChecker(tester);
    await check(tester, 'https://www.gov.sl/news');

    expect(find.text(l10n.linkCheckResultSafeTitle), findsOneWidget);
    // Section 9.5: never imply a guarantee.
    expect(find.text(l10n.linkCheckResultSafeBody), findsOneWidget);
    expect(l10n.linkCheckResultSafeBody, contains('not the same as safe'));
  });

  testWidgets('an http link reports the connection as not secure', (
    tester,
  ) async {
    await pumpChecker(tester);
    await check(tester, 'http://example.com/login');

    await scrollTo(tester, find.text(l10n.linkCheckHttps));
    expect(find.text(l10n.linkCheckHttpsNo), findsOneWidget);
    expect(find.text(l10n.urlFindingNoHttps), findsOneWidget);
  });

  testWidgets('an APK download link is flagged as dangerous', (tester) async {
    await pumpChecker(tester);
    await check(tester, 'https://example.com/whatsapp-update.apk');

    expect(find.text(l10n.linkCheckResultDangerTitle), findsOneWidget);
    expect(find.text(l10n.urlFindingExecutable), findsOneWidget);
  });

  testWidgets('the result offers copying but never opening', (tester) async {
    await pumpChecker(tester);
    await check(tester, 'https://whatsapp-verify.tk/login');

    await scrollTo(
      tester,
      find.widgetWithText(OutlinedButton, l10n.linkCheckCopy),
    );
    expect(
      find.widgetWithText(OutlinedButton, l10n.linkCheckCopy),
      findsOneWidget,
    );
    // No button anywhere offers to visit the link.
    for (final label in ['Open', 'Visit', 'Go to']) {
      expect(find.textContaining(label), findsNothing, reason: label);
    }
  });

  testWidgets('a link passed in from elsewhere is pre-filled', (tester) async {
    await pumpChecker(tester, initialUrl: 'https://claim-now.tk');

    expect(find.text('https://claim-now.tk'), findsOneWidget);
  });
}
