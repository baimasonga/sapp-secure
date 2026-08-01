import '../../trusted_contacts/domain/trusted_contact.dart';

/// What the user concluded after trying to check who really sent a message
/// (specification section 6.4).
enum VerificationOutcome {
  /// Reached the real person; the request was genuine.
  verifiedSafe,

  /// Could not reach them, or is still unsure. Deliberately distinct from
  /// "safe" — an unanswered call is not reassurance.
  couldNotVerify,

  /// Reached the real person and they did not send it.
  confirmedImpersonation;

  String get id => name;

  static VerificationOutcome? fromId(String? id) {
    for (final outcome in VerificationOutcome.values) {
      if (outcome.name == id) return outcome;
    }
    return null;
  }
}

/// How the user tried to check.
enum VerificationMethod {
  callSavedNumber,
  sendSms,
  askPrivateQuestion,
  askRelative,
  other;

  String get id => name;

  static VerificationMethod? fromId(String? id) {
    for (final method in VerificationMethod.values) {
      if (method.name == id) return method;
    }
    return null;
  }
}

/// A local record of one verification attempt.
///
/// Holds no message text. It keeps the number that was in question because
/// that is the point of the record, and it stays in encrypted local storage.
class VerificationRecord {
  VerificationRecord({
    required this.id,
    required this.claimedName,
    required this.numberInQuestionE164,
    required this.matchStatus,
    required this.outcome,
    required this.createdAt,
    this.contactId,
    this.method,
  });

  final String id;

  /// Who the message claimed to be from, as the user described them.
  final String claimedName;

  final String numberInQuestionE164;
  final NumberMatchStatus matchStatus;
  final VerificationOutcome outcome;
  final VerificationMethod? method;

  /// The trusted contact this was checked against, when there was one.
  final String? contactId;

  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'claimed_name': claimedName,
    'number': numberInQuestionE164,
    'match_status': matchStatus.name,
    'outcome': outcome.id,
    'method': method?.id,
    'contact_id': contactId,
    'created_at': createdAt.toIso8601String(),
  };

  static VerificationRecord? tryFromJson(Map<String, Object?> json) {
    final outcome = VerificationOutcome.fromId(json['outcome'] as String?);
    final number = json['number'] as String?;
    if (outcome == null || number == null) return null;
    return VerificationRecord(
      id: json['id'] as String? ?? TrustedContact.newId(),
      claimedName: json['claimed_name'] as String? ?? '',
      numberInQuestionE164: number,
      matchStatus: NumberMatchStatus.values.firstWhere(
        (status) => status.name == json['match_status'],
        orElse: () => NumberMatchStatus.noTrustedContact,
      ),
      outcome: outcome,
      method: VerificationMethod.fromId(json['method'] as String?),
      contactId: json['contact_id'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
