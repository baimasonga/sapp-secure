import 'dart:math';

import '../../../services/risk_engine/phone_number_extractor.dart';

/// How a number found in a message relates to a person the user trusts.
///
/// [differsFromTrusted] is the dangerous case and the whole reason this
/// feature exists: someone claiming to be a known person, writing from a
/// number that person has never used.
enum NumberMatchStatus {
  /// The number is one this contact is already known to use.
  matchesTrusted,

  /// The contact is known, but this is not one of their numbers.
  differsFromTrusted,

  /// The user has not saved this person, so there is nothing to compare.
  noTrustedContact,
}

/// A person the user has deliberately saved so their real number can be
/// compared against numbers appearing in messages.
///
/// Only people the user explicitly adds are stored. The device contact list is
/// never read wholesale and never leaves the phone.
class TrustedContact {
  TrustedContact({
    required this.id,
    required this.displayName,
    required List<String> numbersE164,
    required this.primaryNumberE164,
    required this.createdAt,
    this.relationshipLabel,
    this.verificationQuestion,
  }) : numbersE164 = List.unmodifiable(numbersE164) {
    if (displayName.trim().isEmpty) {
      throw ArgumentError('A trusted contact needs a name.');
    }
    if (numbersE164.isEmpty) {
      throw ArgumentError('A trusted contact needs at least one number.');
    }
    if (!numbersE164.contains(primaryNumberE164)) {
      throw ArgumentError('The primary number must be one of the numbers.');
    }
  }

  final String id;

  /// A name the user chose. Local only.
  final String displayName;

  /// Every number this person is known to use, normalised.
  final List<String> numbersE164;

  /// The number the app suggests calling to verify.
  final String primaryNumberE164;

  /// "Brother", "Boss", "Susu group" — free text, optional.
  final String? relationshipLabel;

  /// Something only the real person could answer. Never a password, a PIN or
  /// anything reusable as a credential.
  final String? verificationQuestion;

  final DateTime createdAt;

  bool usesNumber(String candidateE164) => numbersE164.contains(candidateE164);

  /// Compares a number seen in a message against this contact's numbers.
  NumberMatchStatus match(String candidateE164) => usesNumber(candidateE164)
      ? NumberMatchStatus.matchesTrusted
      : NumberMatchStatus.differsFromTrusted;

  TrustedContact copyWith({
    String? displayName,
    List<String>? numbersE164,
    String? primaryNumberE164,
    String? relationshipLabel,
    String? verificationQuestion,
  }) {
    return TrustedContact(
      id: id,
      displayName: displayName ?? this.displayName,
      numbersE164: numbersE164 ?? this.numbersE164,
      primaryNumberE164: primaryNumberE164 ?? this.primaryNumberE164,
      relationshipLabel: relationshipLabel ?? this.relationshipLabel,
      verificationQuestion: verificationQuestion ?? this.verificationQuestion,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'display_name': displayName,
    'numbers': numbersE164,
    'primary_number': primaryNumberE164,
    'relationship_label': relationshipLabel,
    'verification_question': verificationQuestion,
    'created_at': createdAt.toIso8601String(),
  };

  /// Returns null for an entry that cannot be read, so one corrupt record
  /// never costs the user the rest of their contacts.
  static TrustedContact? tryFromJson(Map<String, Object?> json) {
    try {
      final numbers = <String>[
        for (final number in (json['numbers'] as List<dynamic>? ?? const []))
          if (number is String) number,
      ];
      final primary = json['primary_number'] as String?;
      if (numbers.isEmpty || primary == null) return null;
      return TrustedContact(
        id: json['id'] as String? ?? newId(),
        displayName: json['display_name'] as String? ?? '',
        numbersE164: numbers,
        primaryNumberE164: primary,
        relationshipLabel: json['relationship_label'] as String?,
        verificationQuestion: json['verification_question'] as String?,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    } on ArgumentError {
      return null;
    }
  }

  /// Builds a contact from user input, normalising every number first so that
  /// `076123456` and `+232 76 123 456` are recognised as the same person.
  ///
  /// Returns null when the name is blank or no number could be understood.
  static TrustedContact? create({
    required String displayName,
    required List<String> rawNumbers,
    String? relationshipLabel,
    String? verificationQuestion,
    String? id,
    DateTime? createdAt,
  }) {
    final normalised = <String>[];
    for (final raw in rawNumbers) {
      final number = PhoneNumberExtractor.normaliseSingle(raw);
      if (number == null) continue;
      if (!normalised.contains(number.normalised)) {
        normalised.add(number.normalised);
      }
    }
    if (displayName.trim().isEmpty || normalised.isEmpty) return null;

    return TrustedContact(
      id: id ?? newId(),
      displayName: displayName.trim(),
      numbersE164: normalised,
      primaryNumberE164: normalised.first,
      relationshipLabel: _blankToNull(relationshipLabel),
      verificationQuestion: _blankToNull(verificationQuestion),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Local identifier. Not a cryptographic value and never sent anywhere.
  static String newId() {
    final random = Random();
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = random.nextInt(1 << 32).toRadixString(36);
    return '$time-$salt';
  }

  @override
  bool operator ==(Object other) => other is TrustedContact && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
