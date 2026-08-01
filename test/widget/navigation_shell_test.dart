import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/dashboard/presentation/home_screen.dart';
import 'package:salone_shield/features/message_analysis/presentation/analyse_message_screen.dart';
import 'package:salone_shield/features/settings/presentation/settings_screen.dart';
import 'package:salone_shield/features/threat_reporting/presentation/report_history_screen.dart';
import 'package:salone_shield/features/trusted_contacts/presentation/trusted_contacts_screen.dart';
import 'package:salone_shield/l10n/app_localizations.dart';

import '../support/test_harness.dart';

/// The tab bar is the one piece of navigation the user never chose to enter,
/// so these tests pin down both halves of the contract: the four tabs it
/// offers, and the screens it must stay out of the way of.
void main() {
  late AppLocalizations l10n;

  setUp(() async => l10n = await localisationsFor('en'));

  testWidgets('the shell offers home, reports, contacts and settings', (
    tester,
  ) async {
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in [
      l10n.navHome,
      l10n.navReports,
      l10n.navContacts,
      l10n.navSettings,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('each tab shows its own screen', (tester) async {
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    await tester.tap(find.text(l10n.navContacts));
    await tester.pumpAndSettle();
    expect(find.byType(TrustedContactsScreen), findsOneWidget);

    await tester.tap(find.text(l10n.navReports));
    await tester.pumpAndSettle();
    expect(find.byType(ReportHistoryScreen), findsOneWidget);

    await tester.tap(find.text(l10n.navSettings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('a task screen covers the tab bar rather than sitting under it', (
    tester,
  ) async {
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    await tester.tap(find.text(l10n.homeActionAnalyse));
    await tester.pumpAndSettle();

    // Analysing a message is a task the user is halfway through; offering a
    // one-tap exit to another tab would be an invitation to abandon it.
    expect(find.byType(AnalyseMessageScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('returning to a tab keeps where that tab was', (tester) async {
    await pumpApp(tester, preferences: await createOnboardedPreferences());

    await tester.tap(find.text(l10n.navContacts));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.navHome));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.navContacts));
    await tester.pumpAndSettle();

    expect(find.byType(TrustedContactsScreen), findsOneWidget);
  });
}
