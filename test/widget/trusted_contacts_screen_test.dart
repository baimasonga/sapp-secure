import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/app/providers.dart';
import 'package:salone_shield/features/trusted_contacts/data/trusted_contact_repository.dart';
import 'package:salone_shield/features/trusted_contacts/domain/trusted_contact.dart';
import 'package:salone_shield/features/trusted_contacts/presentation/trusted_contacts_screen.dart';
import 'package:salone_shield/l10n/app_localizations.dart';
import 'package:salone_shield/services/contacts/contact_picker_service.dart';

import '../support/fake_secure_storage.dart';
import '../support/test_harness.dart';

void main() {
  late FakeSecureStorage storage;
  late AppLocalizations l10n;

  setUp(() async {
    storage = FakeSecureStorage();
    l10n = await localisationsFor('en');
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Object? pickerReply,
    bool withPicker = false,
  }) async {
    const channel = MethodChannel('test/contacts');
    if (withPicker) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => pickerReply);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
    }

    await tester.pumpWidget(
      wrapForTest(
        const TrustedContactsScreen(),
        preferences: await createOnboardedPreferences(),
        overrides: [
          storage.override,
          if (withPicker)
            contactPickerServiceProvider.overrideWithValue(
              const ContactPickerService(channel: channel),
            ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> saveContact(String name, List<String> numbers) =>
      TrustedContactRepository(
        storage.service,
      ).upsert(TrustedContact.create(displayName: name, rawNumbers: numbers)!);

  testWidgets('an empty list explains what to do and promises privacy', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text(l10n.trustedContactsEmpty), findsOneWidget);
    expect(find.text(l10n.trustedContactsPrivacyNote), findsOneWidget);
  });

  testWidgets('saved contacts are listed with their main number', (
    tester,
  ) async {
    await saveContact('Mohamed', ['076123456']);
    await pumpScreen(tester);

    expect(find.text('Mohamed'), findsOneWidget);
    expect(find.text('+23276123456'), findsOneWidget);
  });

  testWidgets('adding a contact by typing stores it normalised', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.trustedContactAdd));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, l10n.trustedContactName),
      'Aminata',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.trustedContactNumber),
      '076 123 456',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.trustedContactSave),
    );
    await tester.pumpAndSettle();

    final saved = await TrustedContactRepository(storage.service).load();
    expect(saved, hasLength(1));
    expect(saved.single.displayName, 'Aminata');
    expect(saved.single.numbersE164, ['+23276123456']);
  });

  testWidgets('a contact with no readable number is refused with a reason', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.trustedContactAdd));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.trustedContactName),
      'Aminata',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.trustedContactSave),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.trustedContactInvalid), findsOneWidget);
    expect(await TrustedContactRepository(storage.service).load(), isEmpty);
  });

  testWidgets('the system picker fills in the name and number', (tester) async {
    await pumpScreen(
      tester,
      withPicker: true,
      pickerReply: {'name': 'Sorie', 'number': '+232 77 000 111'},
    );

    await tester.tap(find.text(l10n.trustedContactAdd));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(OutlinedButton, l10n.trustedContactFromPhone),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sorie'), findsOneWidget);
    expect(find.text('+232 77 000 111'), findsOneWidget);
  });

  testWidgets('cancelling the picker leaves the form usable', (tester) async {
    await pumpScreen(tester, withPicker: true, pickerReply: null);

    await tester.tap(find.text(l10n.trustedContactAdd));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(OutlinedButton, l10n.trustedContactFromPhone),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.trustedContactPickerUnavailable), findsOneWidget);
    expect(
      find.widgetWithText(TextField, l10n.trustedContactName),
      findsOneWidget,
    );
  });

  testWidgets('removing asks first and then removes', (tester) async {
    await saveContact('Mohamed', ['076123456']);
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.trustedContactRemoveConfirm('Mohamed')),
      findsOneWidget,
    );

    await tester.tap(
      find.widgetWithText(FilledButton, l10n.trustedContactRemove),
    );
    await tester.pumpAndSettle();

    expect(await TrustedContactRepository(storage.service).load(), isEmpty);
  });

  testWidgets('cancelling removal keeps the contact', (tester) async {
    await saveContact('Mohamed', ['076123456']);
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n.actionCancel));
    await tester.pumpAndSettle();

    expect(
      await TrustedContactRepository(storage.service).load(),
      hasLength(1),
    );
  });
}
