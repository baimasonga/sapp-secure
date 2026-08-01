import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/trusted_contacts/domain/trusted_contact.dart';

void main() {
  group('creating a contact', () {
    test('normalises every number to E.164', () {
      final contact = TrustedContact.create(
        displayName: 'Mohamed',
        rawNumbers: ['076 123 456', '+232 77 000 111'],
      )!;

      expect(contact.numbersE164, ['+23276123456', '+23277000111']);
      expect(contact.primaryNumberE164, '+23276123456');
    });

    test('the same number written two ways is stored once', () {
      final contact = TrustedContact.create(
        displayName: 'Aminata',
        rawNumbers: ['076123456', '+232 76 123 456', '76123456'],
      )!;

      expect(contact.numbersE164, ['+23276123456']);
    });

    test('trims the name and drops blank optional fields', () {
      final contact = TrustedContact.create(
        displayName: '  Fatmata  ',
        rawNumbers: ['076123456'],
        relationshipLabel: '   ',
        verificationQuestion: '',
      )!;

      expect(contact.displayName, 'Fatmata');
      expect(contact.relationshipLabel, isNull);
      expect(contact.verificationQuestion, isNull);
    });

    test('rejects a blank name', () {
      expect(
        TrustedContact.create(displayName: '  ', rawNumbers: ['076123456']),
        isNull,
      );
    });

    test('rejects a contact with no readable number', () {
      expect(
        TrustedContact.create(displayName: 'Sorie', rawNumbers: ['abc', '12']),
        isNull,
      );
    });

    test('ignores unreadable numbers but keeps the good ones', () {
      final contact = TrustedContact.create(
        displayName: 'Sorie',
        rawNumbers: ['not a number', '076123456'],
      )!;

      expect(contact.numbersE164, ['+23276123456']);
    });

    test('identifiers are unique', () {
      final ids = {for (var i = 0; i < 200; i++) TrustedContact.newId()};
      expect(ids, hasLength(200));
    });
  });

  group('number matching', () {
    final contact = TrustedContact.create(
      displayName: 'Mohamed',
      rawNumbers: ['076123456', '077000111'],
    )!;

    test('recognises a number the contact uses', () {
      expect(contact.match('+23276123456'), NumberMatchStatus.matchesTrusted);
      expect(contact.match('+23277000111'), NumberMatchStatus.matchesTrusted);
    });

    test('flags a number the contact has never used', () {
      // The impersonation case the whole feature exists for.
      expect(
        contact.match('+23288999999'),
        NumberMatchStatus.differsFromTrusted,
      );
    });
  });

  group('serialisation', () {
    test('round-trips through JSON', () {
      final original = TrustedContact.create(
        displayName: 'Mohamed',
        rawNumbers: ['076123456', '077000111'],
        relationshipLabel: 'Brother',
        verificationQuestion: 'Where did we meet?',
      )!;

      final restored = TrustedContact.tryFromJson(original.toJson())!;

      expect(restored.id, original.id);
      expect(restored.displayName, original.displayName);
      expect(restored.numbersE164, original.numbersE164);
      expect(restored.primaryNumberE164, original.primaryNumberE164);
      expect(restored.relationshipLabel, 'Brother');
      expect(restored.verificationQuestion, 'Where did we meet?');
    });

    test('a record with no numbers is rejected rather than half-loaded', () {
      expect(
        TrustedContact.tryFromJson({
          'id': 'x',
          'display_name': 'Broken',
          'numbers': <String>[],
          'primary_number': '+23276123456',
        }),
        isNull,
      );
    });

    test('a record whose primary number is missing is rejected', () {
      expect(
        TrustedContact.tryFromJson({
          'id': 'x',
          'display_name': 'Broken',
          'numbers': ['+23276123456'],
        }),
        isNull,
      );
    });
  });

  test('copyWith can promote another number to primary', () {
    final contact = TrustedContact.create(
      displayName: 'Mohamed',
      rawNumbers: ['076123456', '077000111'],
    )!;

    final updated = contact.copyWith(primaryNumberE164: '+23277000111');

    expect(updated.primaryNumberE164, '+23277000111');
    expect(updated.id, contact.id);
  });

  test('a primary number outside the list is refused', () {
    expect(
      () => TrustedContact(
        id: 'x',
        displayName: 'Mohamed',
        numbersE164: const ['+23276123456'],
        primaryNumberE164: '+23288888888',
        createdAt: DateTime.now(),
      ),
      throwsArgumentError,
    );
  });
}
