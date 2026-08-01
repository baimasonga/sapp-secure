import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/trusted_contact_repository.dart';
import '../domain/trusted_contact.dart';

/// The user's trusted contacts, loaded from encrypted storage.
class TrustedContactsController
    extends StateNotifier<AsyncValue<List<TrustedContact>>> {
  TrustedContactsController(this._repository)
    : super(const AsyncValue.loading()) {
    load();
  }

  final TrustedContactRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.load());
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Returns false when the list is full, so the UI can say so.
  Future<bool> save(TrustedContact contact) async {
    final saved = await _repository.upsert(contact);
    await load();
    return saved;
  }

  Future<void> remove(String id) async {
    await _repository.remove(id);
    await load();
  }

  /// Nothing else in the app may reorder a contact's numbers, so promoting one
  /// to primary lives here.
  Future<void> setPrimaryNumber(
    TrustedContact contact,
    String numberE164,
  ) async {
    if (!contact.usesNumber(numberE164)) return;
    await save(contact.copyWith(primaryNumberE164: numberE164));
  }
}

final trustedContactRepositoryProvider = Provider<TrustedContactRepository>(
  (ref) => TrustedContactRepository(ref.watch(secureStorageProvider)),
);

final trustedContactsControllerProvider =
    StateNotifierProvider<
      TrustedContactsController,
      AsyncValue<List<TrustedContact>>
    >(
      (ref) => TrustedContactsController(
        ref.watch(trustedContactRepositoryProvider),
      ),
    );

/// Trusted numbers in E.164, for the risk engine's sender check. Empty while
/// contacts are still loading, which only ever means "no bonus signal".
final trustedNumbersProvider = Provider<Set<String>>((ref) {
  final contacts = ref.watch(trustedContactsControllerProvider).valueOrNull;
  if (contacts == null) return const {};
  return {for (final contact in contacts) ...contact.numbersE164};
});

/// Looks up which trusted contact, if any, uses a number found in a message.
final contactForNumberProvider = Provider.family<TrustedContact?, String>((
  ref,
  numberE164,
) {
  final contacts = ref.watch(trustedContactsControllerProvider).valueOrNull;
  if (contacts == null) return null;
  for (final contact in contacts) {
    if (contact.usesNumber(numberE164)) return contact;
  }
  return null;
});
