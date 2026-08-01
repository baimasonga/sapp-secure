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

void main() {
  late FakeSecureStorage storage;
  late AppLocalizations l10n;

  setUp(() async {
    storage = FakeSecureStorage();
    l10n = await localisationsFor('en');
  });

  Future<void> saveContact(String name, List<String> numbers) =>
      TrustedContactRepository(
        storage.service,
      ).upsert(TrustedContact.create(displayName: name, rawNumbers: numbers)!);

  Future<void> pumpVerify(WidgetTester tester, String numberE164) async {
    await tester.pumpWidget(
      wrapForTest(
        VerifyPersonScreen(numberE164: numberE164),
        preferences: await createOnboardedPreferences(),
        overrides: [storage.override],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with no saved contacts it says there is nothing to compare', (
    tester,
  ) async {
    await pumpVerify(tester, '+23276123456');

    expect(find.text(l10n.verifyMatchUnknown), findsOneWidget);
    expect(find.text(l10n.verifyNoContactsYet), findsOneWidget);
  });

  testWidgets('a number the contact already uses is reported as matching', (
    tester,
  ) async {
    await saveContact('Mohamed', ['076123456']);
    await pumpVerify(tester, '+23276123456');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mohamed'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.verifyMatchMatches('Mohamed')), findsOneWidget);
    // Even a match is not treated as proof: the screen still warns about
    // stolen phones and hijacked accounts.
    expect(find.text(l10n.verifyMatchMatchesBody), findsOneWidget);
  });

  testWidgets('a number the contact has never used is flagged loudly', (
    tester,
  ) async {
    await saveContact('Mohamed', ['076123456']);
    await pumpVerify(tester, '+23288999888');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mohamed'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.verifyMatchDiffers('Mohamed')), findsOneWidget);
    expect(find.text(l10n.verifyMatchDiffersBody), findsOneWidget);
  });

  testWidgets('the saved number is offered to call, not the message number', (
    tester,
  ) async {
    await saveContact('Mohamed', ['076123456']);
    await pumpVerify(tester, '+23288999888');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mohamed'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(l10n.verifyMethodCall));

    // The dialer is offered the trusted number; the number from the message
    // appears only in the card at the top.
    expect(
      find.descendant(
        of: find.widgetWithText(Card, l10n.verifyMethodCall),
        matching: find.text('+23276123456'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('recording an outcome saves it and confirms in plain language', (
    tester,
  ) async {
    await saveContact('Mohamed', ['076123456']);
    await pumpVerify(tester, '+23288999888');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mohamed'));
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.widgetWithText(FilledButton, l10n.verifyOutcomeImpersonation),
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.verifyOutcomeImpersonation),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.verifyOutcomeImpersonationNote), findsOneWidget);

    final saved = await VerificationHistoryRepository(storage.service).load();
    expect(saved, hasLength(1));
    expect(saved.single.outcome, VerificationOutcome.confirmedImpersonation);
    expect(saved.single.numberInQuestionE164, '+23288999888');
    expect(saved.single.matchStatus, NumberMatchStatus.differsFromTrusted);
  });

  testWidgets('"could not verify" is never presented as safe', (tester) async {
    await pumpVerify(tester, '+23288999888');
    await scrollTo(
      tester,
      find.widgetWithText(OutlinedButton, l10n.verifyOutcomeUnsure),
    );
    await tester.tap(
      find.widgetWithText(OutlinedButton, l10n.verifyOutcomeUnsure),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.verifyOutcomeUnsureNote), findsOneWidget);
    expect(l10n.verifyOutcomeUnsureNote.toLowerCase(), contains('not'));
  });

  testWidgets('a number previously confirmed as an impersonator is recalled', (
    tester,
  ) async {
    await VerificationHistoryRepository(storage.service).add(
      VerificationRecord(
        id: 'past',
        claimedName: 'Mohamed',
        numberInQuestionE164: '+23288999888',
        matchStatus: NumberMatchStatus.differsFromTrusted,
        outcome: VerificationOutcome.confirmedImpersonation,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    );

    await pumpVerify(tester, '+23288999888');
    await scrollTo(tester, find.text(l10n.verifyPreviousImpersonation));

    expect(find.text(l10n.verifyPreviousImpersonation), findsOneWidget);
  });

  testWidgets('the screen is translated into Krio', (tester) async {
    final krio = await localisationsFor('kri');
    await tester.pumpWidget(
      wrapForTest(
        const VerifyPersonScreen(numberE164: '+23276123456'),
        preferences: await createOnboardedPreferences(language: 'kri'),
        locale: 'kri',
        overrides: [storage.override],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(krio.verifyIntro), findsOneWidget);
    expect(find.text(l10n.verifyIntro), findsNothing);
  });
}
