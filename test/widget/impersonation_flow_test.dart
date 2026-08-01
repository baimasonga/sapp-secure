import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/identity_verification/data/verification_history_repository.dart';
import 'package:salone_shield/features/identity_verification/domain/verification_record.dart';
import 'package:salone_shield/features/identity_verification/presentation/verify_person_screen.dart';
import 'package:salone_shield/features/trusted_contacts/data/trusted_contact_repository.dart';
import 'package:salone_shield/features/trusted_contacts/domain/trusted_contact.dart';
import 'package:salone_shield/l10n/app_localizations.dart';

import '../support/fake_secure_storage.dart';
import '../support/test_harness.dart';

/// The journey the whole milestone exists for (specification section 6.4):
/// a message claims to be someone you know, from a number they have never
/// used, and asks for money.
void main() {
  late FakeSecureStorage storage;
  late AppLocalizations l10n;

  const scamMessage =
      'Hello, this is Mohamed. I lost my old phone. Save this new number '
      '077 000 111. I need you to send money urgently to this Orange Money '
      'number.';

  setUp(() async {
    storage = FakeSecureStorage();
    l10n = await localisationsFor('en');
    // Mohamed's real number, saved earlier by the user.
    await TrustedContactRepository(storage.service).upsert(
      TrustedContact.create(
        displayName: 'Mohamed',
        rawNumbers: ['076123456'],
        relationshipLabel: 'Brother',
      )!,
    );
  });

  testWidgets('analysing the message flags it and offers verification', (
    tester,
  ) async {
    await pumpApp(
      tester,
      preferences: await createOnboardedPreferences(),
      overrides: [storage.override],
    );

    await tester.tap(find.text(l10n.homeActionAnalyse));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), scamMessage);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.analyseRun));
    await tester.pumpAndSettle();

    // High risk, and the number from the message was extracted.
    expect(find.text(l10n.riskLevelHigh), findsOneWidget);
    await scrollTo(tester, find.text(sectionLabel(l10n.resultNumbersTitle)));
    expect(find.text('+23277000111'), findsOneWidget);

    // Verification is offered right next to the number.
    expect(find.text(l10n.resultVerifyPerson), findsWidgets);
  });

  testWidgets('the scam number is not shown as a known contact', (
    tester,
  ) async {
    await pumpApp(
      tester,
      preferences: await createOnboardedPreferences(),
      overrides: [storage.override],
    );

    await tester.tap(find.text(l10n.homeActionAnalyse));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), scamMessage);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.analyseRun));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(sectionLabel(l10n.resultNumbersTitle)));

    // The badge belongs to Mohamed's real number, not the one in the message.
    expect(find.text(l10n.verifyKnownContactBadge('Mohamed')), findsNothing);
  });

  testWidgets("a message from Mohamed's real number is marked as known", (
    tester,
  ) async {
    await pumpApp(
      tester,
      preferences: await createOnboardedPreferences(),
      overrides: [storage.override],
    );

    await tester.tap(find.text(l10n.homeActionAnalyse));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Please call me back on 076123456 when you are free.',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.analyseRun));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(sectionLabel(l10n.resultNumbersTitle)));

    expect(find.text(l10n.verifyKnownContactBadge('Mohamed')), findsOneWidget);
  });

  testWidgets('verifying the number reveals the mismatch and records it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        const VerifyPersonScreen(numberE164: '+23277000111'),
        preferences: await createOnboardedPreferences(),
        overrides: [storage.override],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mohamed'));
    await tester.pumpAndSettle();

    // The point of the whole milestone.
    expect(find.text(l10n.verifyMatchDiffers('Mohamed')), findsOneWidget);

    await scrollTo(
      tester,
      find.widgetWithText(FilledButton, l10n.verifyOutcomeImpersonation),
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.verifyOutcomeImpersonation),
    );
    await tester.pumpAndSettle();

    final history = await VerificationHistoryRepository(storage.service).load();
    expect(history.single.outcome, VerificationOutcome.confirmedImpersonation);
    expect(history.single.claimedName, 'Mohamed');
  });

  testWidgets('checking the same number again recalls the earlier verdict', (
    tester,
  ) async {
    await VerificationHistoryRepository(storage.service).add(
      VerificationRecord(
        id: 'earlier',
        claimedName: 'Mohamed',
        numberInQuestionE164: '+23277000111',
        matchStatus: NumberMatchStatus.differsFromTrusted,
        outcome: VerificationOutcome.confirmedImpersonation,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    );

    await tester.pumpWidget(
      wrapForTest(
        const VerifyPersonScreen(numberE164: '+23277000111'),
        preferences: await createOnboardedPreferences(),
        overrides: [storage.override],
      ),
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(l10n.verifyPreviousImpersonation));

    expect(find.text(l10n.verifyPreviousImpersonation), findsOneWidget);
  });
}
