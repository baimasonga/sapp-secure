import 'dart:convert';

import '../../../core/storage/secure_storage_service.dart';
import '../domain/trusted_contact.dart';

/// Trusted contacts, held in encrypted local storage only.
///
/// Nothing here is uploaded. There is no server copy, which is deliberate:
/// a breach of Salone Shield must not reveal who anyone's family is.
class TrustedContactRepository {
  const TrustedContactRepository(this._storage);

  final SecureStorageService _storage;

  static const String storageKey = 'contacts.trusted';

  /// A generous cap. Trusted contacts are the handful of people who might
  /// plausibly ask you for money, not an address book.
  static const int maxContacts = 50;

  Future<List<TrustedContact>> load() async {
    final raw = await _storage.read(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final entry in decoded)
          if (entry is Map)
            ?TrustedContact.tryFromJson(Map<String, Object?>.from(entry)),
      ];
    } on FormatException {
      // Unreadable storage must not lock the user out of the feature.
      return const [];
    }
  }

  Future<void> _save(List<TrustedContact> contacts) => _storage.write(
    storageKey,
    jsonEncode(contacts.map((contact) => contact.toJson()).toList()),
  );

  /// Adds or replaces a contact. Returns false when the list is already full.
  Future<bool> upsert(TrustedContact contact) async {
    final contacts = [...await load()];
    final index = contacts.indexWhere((existing) => existing.id == contact.id);
    if (index >= 0) {
      contacts[index] = contact;
    } else {
      if (contacts.length >= maxContacts) return false;
      contacts.add(contact);
    }
    await _save(contacts);
    return true;
  }

  Future<void> remove(String id) async {
    final contacts = await load();
    await _save(contacts.where((contact) => contact.id != id).toList());
  }

  Future<void> clear() => _storage.delete(storageKey);

  /// Every trusted number, for the risk engine's sender check.
  Future<Set<String>> trustedNumbers() async {
    final contacts = await load();
    return {for (final contact in contacts) ...contact.numbersE164};
  }

  /// The contact using a given number, or null when nobody does.
  Future<TrustedContact?> findByNumber(String numberE164) async {
    for (final contact in await load()) {
      if (contact.usesNumber(numberE164)) return contact;
    }
    return null;
  }
}
