import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/identity_verification/data/verification_history_repository.dart';
import 'package:salone_shield/features/identity_verification/domain/verification_record.dart';
import 'package:salone_shield/features/trusted_contacts/data/trusted_contact_repository.dart';
import 'package:salone_shield/features/trusted_contacts/domain/trusted_contact.dart';

import '../support/fake_secure_storage.dart';

void main() {
  late FakeSecureStorage storage;
  late TrustedContactRepository repository;

  setUp(() {
    storage = FakeSecureStorage();
    repository = TrustedContactRepository(storage.service);
  });

  TrustedContact contact(String name, List<String> numbers) =>
      TrustedContact.create(displayName: name, rawNumbers: numbers)!;

  group('trusted contacts', () {
    test('starts empty', () async {
      expect(await repository.load(), isEmpty);
    });

    test('saves and reloads a contact', () async {
      final saved = contact('Mohamed', ['076123456']);
      expect(await repository.upsert(saved), isTrue);

      final loaded = await repository.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.displayName, 'Mohamed');
      expect(loaded.single.numbersE164, ['+23276123456']);
    });

    test('upserting the same id replaces rather than duplicates', () async {
      final original = contact('Mohamed', ['076123456']);
      await repository.upsert(original);
      await repository.upsert(original.copyWith(displayName: 'Mohamed B'));

      final loaded = await repository.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.displayName, 'Mohamed B');
    });

    test('removing leaves the others alone', () async {
      final first = contact('Mohamed', ['076123456']);
      final second = contact('Aminata', ['077000111']);
      await repository.upsert(first);
      await repository.upsert(second);

      await repository.remove(first.id);

      final loaded = await repository.load();
      expect(loaded.map((c) => c.displayName), ['Aminata']);
    });

    test('refuses to grow past the cap', () async {
      for (
        var index = 0;
        index < TrustedContactRepository.maxContacts;
        index++
      ) {
        final added = await repository.upsert(
          contact('Person $index', [
            '0761234${index.toString().padLeft(2, '0')}',
          ]),
        );
        expect(added, isTrue, reason: 'contact $index');
      }

      expect(
        await repository.upsert(contact('One too many', ['077000111'])),
        isFalse,
      );
      expect(
        await repository.load(),
        hasLength(TrustedContactRepository.maxContacts),
      );
    });

    test('collects every number for the risk engine', () async {
      await repository.upsert(contact('Mohamed', ['076123456', '077000111']));
      await repository.upsert(contact('Aminata', ['088999888']));

      expect(await repository.trustedNumbers(), {
        '+23276123456',
        '+23277000111',
        '+23288999888',
      });
    });

    test('finds the contact behind a number', () async {
      await repository.upsert(contact('Mohamed', ['076123456', '077000111']));

      expect(
        (await repository.findByNumber('+23277000111'))?.displayName,
        'Mohamed',
      );
      expect(await repository.findByNumber('+23288888888'), isNull);
    });

    test('is written to encrypted storage, not plain preferences', () async {
      await repository.upsert(contact('Mohamed', ['076123456']));
      expect(storage.values, contains(TrustedContactRepository.storageKey));
    });

    test('corrupt storage degrades to empty rather than throwing', () async {
      storage.values[TrustedContactRepository.storageKey] = 'not json';
      expect(await repository.load(), isEmpty);
    });

    test('one unreadable record does not lose the others', () async {
      storage.values[TrustedContactRepository.storageKey] =
          '[{"id":"broken"},'
          '{"id":"ok","display_name":"Aminata","numbers":["+23276123456"],'
          '"primary_number":"+23276123456"}]';

      final loaded = await repository.load();
      expect(loaded.map((c) => c.displayName), ['Aminata']);
    });

    test('clearing removes everything', () async {
      await repository.upsert(contact('Mohamed', ['076123456']));
      await repository.clear();
      expect(await repository.load(), isEmpty);
    });
  });

  group('verification history', () {
    late VerificationHistoryRepository history;

    setUp(() => history = VerificationHistoryRepository(storage.service));

    VerificationRecord record({
      required VerificationOutcome outcome,
      String number = '+23276123456',
      DateTime? at,
    }) => VerificationRecord(
      id: TrustedContact.newId(),
      claimedName: 'Mohamed',
      numberInQuestionE164: number,
      matchStatus: NumberMatchStatus.differsFromTrusted,
      outcome: outcome,
      createdAt: at ?? DateTime.now(),
    );

    test('stores and reloads an outcome', () async {
      await history.add(
        record(outcome: VerificationOutcome.confirmedImpersonation),
      );

      final loaded = await history.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.outcome, VerificationOutcome.confirmedImpersonation);
      expect(loaded.single.matchStatus, NumberMatchStatus.differsFromTrusted);
    });

    test('returns the newest first', () async {
      await history.add(
        record(
          outcome: VerificationOutcome.couldNotVerify,
          at: DateTime.now().subtract(const Duration(days: 2)),
        ),
      );
      await history.add(record(outcome: VerificationOutcome.verifiedSafe));

      final loaded = await history.load();
      expect(loaded.first.outcome, VerificationOutcome.verifiedSafe);
    });

    test('filters by number', () async {
      await history.add(record(outcome: VerificationOutcome.verifiedSafe));
      await history.add(
        record(
          outcome: VerificationOutcome.confirmedImpersonation,
          number: '+23288999888',
        ),
      );

      final forNumber = await history.forNumber('+23288999888');
      expect(forNumber, hasLength(1));
      expect(
        forNumber.single.outcome,
        VerificationOutcome.confirmedImpersonation,
      );
    });

    test('drops records past the retention window', () async {
      await history.add(
        record(
          outcome: VerificationOutcome.verifiedSafe,
          at: DateTime.now().subtract(
            VerificationHistoryRepository.retention + const Duration(days: 1),
          ),
        ),
      );
      expect(await history.load(), isEmpty);
    });

    test('caps the number of records kept', () async {
      for (
        var index = 0;
        index < VerificationHistoryRepository.maxRecords + 10;
        index++
      ) {
        await history.add(record(outcome: VerificationOutcome.couldNotVerify));
      }
      expect(
        await history.load(),
        hasLength(VerificationHistoryRepository.maxRecords),
      );
    });

    test('records hold no message content', () async {
      await history.add(record(outcome: VerificationOutcome.verifiedSafe));
      final stored = storage.values[VerificationHistoryRepository.storageKey]!;
      expect(stored, contains('+23276123456'));
      expect(stored.toLowerCase(), isNot(contains('send')));
      expect(stored.toLowerCase(), isNot(contains('message')));
    });

    test('corrupt storage degrades to empty', () async {
      storage.values[VerificationHistoryRepository.storageKey] = '{oops';
      expect(await history.load(), isEmpty);
    });
  });
}
