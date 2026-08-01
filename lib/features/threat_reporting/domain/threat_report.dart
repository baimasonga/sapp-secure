import '../../../core/errors/app_failure.dart';

/// What the user is reporting (specification section 17.1).
enum ThreatType {
  impersonation('impersonation'),
  hijackedAccount('hijacked_account'),
  financialHelpScam('financial_help_scam'),
  verificationCodeTheft('verification_code_theft'),
  qrCodeScam('qr_code_scam'),
  mobileMoneyScam('mobile_money_scam'),
  maliciousLink('malicious_link'),
  fakeJob('fake_job'),
  fakeLoan('fake_loan'),
  fakeInvestment('fake_investment'),
  fakePrize('fake_prize'),
  blackmail('blackmail'),
  other('other');

  const ThreatType(this.id);

  final String id;

  static ThreatType? fromId(String? id) {
    for (final type in ThreatType.values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

/// Where a report has got to (section 17.2).
enum ReportStatus {
  pending('pending'),
  underReview('under_review'),
  needsMoreEvidence('needs_more_evidence'),
  verified('verified'),
  rejected('rejected'),
  duplicate('duplicate'),
  archived('archived');

  const ReportStatus(this.id);

  final String id;

  static ReportStatus fromId(String? id) {
    for (final status in ReportStatus.values) {
      if (status.id == id) return status;
    }
    return ReportStatus.pending;
  }
}

/// A report the user is composing.
///
/// Numbers are held in the clear only in memory and only until submission:
/// the server hashes them with a pepper the app never sees, and stores the
/// hash. The app never writes a draft containing a number to disk.
class ReportDraft {
  const ReportDraft({
    required this.threatType,
    this.reportedNumber,
    this.paymentNumber,
    this.reportedLink,
    this.messageExcerpt,
    this.district,
    this.riskSignals = const [],
    this.consentConfirmed = false,
  });

  final ThreatType threatType;
  final String? reportedNumber;
  final String? paymentNumber;
  final String? reportedLink;

  /// A short excerpt the user chose, never a whole conversation.
  final String? messageExcerpt;

  final String? district;

  /// Which rules fired, by id. Rule ids only — no message text.
  final List<String> riskSignals;

  final bool consentConfirmed;

  static const int maxExcerptLength = 1000;

  /// Everything wrong with this draft, in the order the form shows it.
  ///
  /// Validation lives here rather than in the widget so the same rules apply
  /// to any future entry point, and so they can be tested without a UI.
  List<ReportValidationError> validate() {
    final errors = <ReportValidationError>[];
    if (!consentConfirmed) errors.add(ReportValidationError.consentRequired);
    if ((reportedNumber?.trim().isEmpty ?? true) &&
        (paymentNumber?.trim().isEmpty ?? true) &&
        (reportedLink?.trim().isEmpty ?? true)) {
      errors.add(ReportValidationError.nothingToReport);
    }
    if ((messageExcerpt?.length ?? 0) > maxExcerptLength) {
      errors.add(ReportValidationError.excerptTooLong);
    }
    return errors;
  }

  bool get isValid => validate().isEmpty;

  ReportDraft copyWith({
    ThreatType? threatType,
    String? reportedNumber,
    String? paymentNumber,
    String? reportedLink,
    String? messageExcerpt,
    String? district,
    List<String>? riskSignals,
    bool? consentConfirmed,
  }) {
    return ReportDraft(
      threatType: threatType ?? this.threatType,
      reportedNumber: reportedNumber ?? this.reportedNumber,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      reportedLink: reportedLink ?? this.reportedLink,
      messageExcerpt: messageExcerpt ?? this.messageExcerpt,
      district: district ?? this.district,
      riskSignals: riskSignals ?? this.riskSignals,
      consentConfirmed: consentConfirmed ?? this.consentConfirmed,
    );
  }

  /// Exactly what will be sent, so the consent screen can show it and the
  /// user is never surprised by what left their phone.
  Map<String, Object?> toSubmission() => {
    'threat_type': threatType.id,
    if (_clean(reportedNumber) != null)
      'reported_number': _clean(reportedNumber),
    if (_clean(paymentNumber) != null) 'payment_number': _clean(paymentNumber),
    if (_clean(reportedLink) != null) 'reported_link': _clean(reportedLink),
    if (_clean(messageExcerpt) != null)
      'message_excerpt': _clean(messageExcerpt),
    if (_clean(district) != null) 'district': _clean(district),
    'risk_signals': riskSignals,
    'consent_confirmed': consentConfirmed,
  };

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

enum ReportValidationError { consentRequired, nothingToReport, excerptTooLong }

/// A report as it comes back from the server. Numbers are masked; the app
/// never receives the hash or the original.
class SubmittedReport {
  const SubmittedReport({
    required this.id,
    required this.threatType,
    required this.status,
    required this.createdAt,
    this.maskedNumber,
    this.moderatorNote,
    this.reviewedAt,
  });

  final String id;
  final ThreatType threatType;
  final ReportStatus status;
  final DateTime createdAt;
  final String? maskedNumber;

  /// What a moderator chose to tell the reporter, if anything.
  final String? moderatorNote;

  final DateTime? reviewedAt;

  static SubmittedReport? tryFromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final type = ThreatType.fromId(json['threat_type'] as String?);
    if (id == null || type == null) return null;
    return SubmittedReport(
      id: id,
      threatType: type,
      status: ReportStatus.fromId(json['status'] as String?),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      maskedNumber: json['display_value_masked'] as String?,
      moderatorNote: json['moderator_note'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
    );
  }
}

/// Why a submission did not go through.
enum ReportFailureReason {
  notSignedIn,
  suspended,
  rateLimited,
  consentMissing,
  nothingToReport,
  network,
  unknown,
}

class ReportFailure extends AppFailure {
  const ReportFailure(this.reason, {super.debugMessage = 'report failed'})
    : super(dataWasSaved: false, retrySafe: true);

  final ReportFailureReason reason;
}
