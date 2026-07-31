/// How a number found in a message was written and what we can say about it.
class ExtractedPhoneNumber {
  const ExtractedPhoneNumber({
    required this.raw,
    required this.normalised,
    required this.isSierraLeone,
    required this.isNormalisedToE164,
  });

  /// Exactly as it appeared in the message, so the user can recognise it.
  final String raw;

  /// E.164 (`+232XXXXXXXX`) where we could determine the country, otherwise
  /// digits only. Never guess a country we are not confident about.
  final String normalised;

  final bool isSierraLeone;
  final bool isNormalisedToE164;

  /// Masked form for display in reports and shared summaries.
  String get masked {
    final digits = normalised.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '***';
    final tail = digits.substring(digits.length - 3);
    final head = normalised.startsWith('+')
        ? '+${digits.substring(0, digits.length > 6 ? 3 : 1)}'
        : '';
    return '$head ** *** $tail';
  }

  @override
  String toString() => normalised;

  @override
  bool operator ==(Object other) =>
      other is ExtractedPhoneNumber && other.normalised == normalised;

  @override
  int get hashCode => normalised.hashCode;
}

/// Finds telephone numbers in free text, with Sierra Leone formats first.
///
/// The extractor is deliberately cautious. It does not decide that a number is
/// a mobile-money number — the user does that in the verification workflow —
/// and it rejects candidates that are clearly money amounts or dates.
abstract final class PhoneNumberExtractor {
  static const String sierraLeoneCallingCode = '232';

  /// A Sierra Leone national subscriber number is 8 digits (e.g. 76 123456),
  /// written locally with a leading 0.
  static const int _slNationalDigits = 8;

  /// Candidate runs of digits, optionally with `+`, spaces, hyphens, dots or
  /// brackets between them.
  static final RegExp _candidate = RegExp(
    r'(?<![\w])(\+?\d[\d\s().\-]{6,20}\d)(?![\w])',
  );

  /// Amounts such as `Le 2,000` or `2.000,50` must not become phone numbers.
  static final RegExp _amountContext = RegExp(
    r'(?:le|nle|sll|sle|usd|\$|£|€)\s*$',
    caseSensitive: false,
  );

  static List<ExtractedPhoneNumber> extract(String text) {
    final results = <ExtractedPhoneNumber>[];
    final seen = <String>{};

    for (final match in _candidate.allMatches(text)) {
      final raw = match.group(1)!.trim();

      // A comma inside the run means it is being used as a thousands
      // separator, not a phone number.
      if (raw.contains(',')) continue;

      // `Le 2000000` is money, not a number to call.
      if (_amountContext.hasMatch(text.substring(0, match.start))) continue;

      final number = _normalise(raw);
      if (number == null) continue;
      if (seen.add(number.normalised)) results.add(number);
    }
    return results;
  }

  static ExtractedPhoneNumber? _normalise(String raw) {
    final hasPlus = raw.trimLeft().startsWith('+');
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.length < _slNationalDigits) return null;
    if (digits.length > 15) return null; // E.164 maximum.

    // +232XXXXXXXX / 232XXXXXXXX
    if (digits.startsWith(sierraLeoneCallingCode) &&
        digits.length == sierraLeoneCallingCode.length + _slNationalDigits) {
      return ExtractedPhoneNumber(
        raw: raw,
        normalised: '+$digits',
        isSierraLeone: true,
        isNormalisedToE164: true,
      );
    }

    // Any other international number written with a leading +.
    if (hasPlus) {
      return ExtractedPhoneNumber(
        raw: raw,
        normalised: '+$digits',
        isSierraLeone: false,
        isNormalisedToE164: true,
      );
    }

    // 0XXXXXXXX — local trunk format.
    if (digits.startsWith('0') && digits.length == _slNationalDigits + 1) {
      return ExtractedPhoneNumber(
        raw: raw,
        normalised: '+$sierraLeoneCallingCode${digits.substring(1)}',
        isSierraLeone: true,
        isNormalisedToE164: true,
      );
    }

    // XXXXXXXX — bare national number.
    if (digits.length == _slNationalDigits) {
      return ExtractedPhoneNumber(
        raw: raw,
        normalised: '+$sierraLeoneCallingCode$digits',
        isSierraLeone: true,
        isNormalisedToE164: true,
      );
    }

    // Anything else: keep the digits but do not invent a country code.
    return ExtractedPhoneNumber(
      raw: raw,
      normalised: digits,
      isSierraLeone: false,
      isNormalisedToE164: false,
    );
  }

  /// Normalises a single number the user typed (a trusted contact, for
  /// example) so it can be compared with a number found in a message.
  static ExtractedPhoneNumber? normaliseSingle(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return _normalise(trimmed);
  }
}
