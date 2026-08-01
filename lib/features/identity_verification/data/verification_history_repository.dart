import 'dart:convert';

import '../../../core/storage/secure_storage_service.dart';
import '../domain/verification_record.dart';

/// Verification outcomes, in encrypted local storage (section 15.3).
///
/// Kept because "I already checked this number last month and it was an
/// impersonator" is worth remembering. Never uploaded.
class VerificationHistoryRepository {
  const VerificationHistoryRepository(this._storage);

  final SecureStorageService _storage;

  static const String storageKey = 'history.verifications';

  static const int maxRecords = 100;
  static const Duration retention = Duration(days: 180);

  Future<List<VerificationRecord>> load() async {
    final raw = await _storage.read(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final cutoff = DateTime.now().subtract(retention);
      final records = <VerificationRecord>[
        for (final entry in decoded)
          if (entry is Map)
            ?VerificationRecord.tryFromJson(Map<String, Object?>.from(entry)),
      ]..removeWhere((record) => record.createdAt.isBefore(cutoff));
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } on FormatException {
      return const [];
    }
  }

  Future<void> add(VerificationRecord record) async {
    final records = [record, ...await load()].take(maxRecords).toList();
    await _storage.write(
      storageKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  /// Past outcomes for a number, newest first. Drives the "you checked this
  /// number before" warning.
  Future<List<VerificationRecord>> forNumber(String numberE164) async {
    final records = await load();
    return records
        .where((record) => record.numberInQuestionE164 == numberE164)
        .toList();
  }

  Future<void> clear() => _storage.delete(storageKey);
}
