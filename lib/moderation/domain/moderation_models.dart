import '../../features/threat_reporting/domain/threat_report.dart';

/// A report as a moderator sees it.
///
/// Deliberately not the same shape as [SubmittedReport], which is what a
/// reporter sees of their own submission. A moderator sees more — the status
/// history, the indicator standing, who else reported the same thing — and
/// still never sees a telephone number. The database holds a peppered hash
/// and a mask; the raw number exists nowhere the dashboard can reach it.
class QueuedReport {
  const QueuedReport({
    required this.id,
    required this.threatType,
    required this.status,
    required this.createdAt,
    this.reporterId,
    this.reportedNumberHash,
    this.paymentNumberHash,
    this.reportedLink,
    this.messageExcerpt,
    this.district,
    this.riskSignals = const [],
    this.moderatorNote,
    this.reviewedAt,
    this.duplicateOf,
    this.indicator,
  });

  final String id;
  final ThreatType threatType;
  final ReportStatus status;
  final DateTime createdAt;

  /// Null once the reporter has deleted their account. The report survives
  /// detached, which is what erasure looks like from this side.
  final String? reporterId;

  final String? reportedNumberHash;
  final String? paymentNumberHash;
  final String? reportedLink;

  /// A short excerpt the reporter chose to include. Never a conversation.
  final String? messageExcerpt;

  final String? district;

  /// Which detection rules fired, by id. Rule ids only, never message text.
  final List<String> riskSignals;

  /// What the reporter will be told. Not the moderator's working notes.
  final String? moderatorNote;

  final DateTime? reviewedAt;
  final String? duplicateOf;

  /// The standing of the number this report names, if it names one.
  final IndicatorStanding? indicator;

  bool get isDecided =>
      status == ReportStatus.verified ||
      status == ReportStatus.rejected ||
      status == ReportStatus.duplicate ||
      status == ReportStatus.archived;

  /// True when the reporter has deleted their account.
  bool get reporterGone => reporterId == null;

  static QueuedReport? tryFromJson(
    Map<String, Object?> json, {
    IndicatorStanding? indicator,
  }) {
    final id = json['id'] as String?;
    final type = ThreatType.fromId(json['threat_type'] as String?);
    if (id == null || type == null) return null;
    return QueuedReport(
      id: id,
      threatType: type,
      status: ReportStatus.fromId(json['status'] as String?),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      reporterId: json['reporter_id'] as String?,
      reportedNumberHash: json['reported_number_hash'] as String?,
      paymentNumberHash: json['payment_number_hash'] as String?,
      reportedLink: json['reported_link'] as String?,
      messageExcerpt: json['message_excerpt'] as String?,
      district: json['district'] as String?,
      riskSignals:
          (json['risk_signals'] as List?)
              ?.map((signal) => signal.toString())
              .toList(growable: false) ??
          const [],
      moderatorNote: json['moderator_note'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
      duplicateOf: json['duplicate_of'] as String?,
      indicator: indicator,
    );
  }
}

/// How an indicator currently stands, and how it got there.
///
/// [verifiedReportCount] is the figure that decides whether anyone outside
/// moderation can see this at all: the read policy requires it to be above
/// zero, so nothing becomes visible without a moderator's decision.
class IndicatorStanding {
  const IndicatorStanding({
    required this.hash,
    required this.maskedValue,
    required this.riskLevel,
    required this.reportCount,
    required this.verifiedReportCount,
    required this.distinctReporterCount,
    required this.status,
  });

  final String hash;

  /// '+232 ** *** 456'. Never fuller than this, on any screen.
  final String? maskedValue;

  final String riskLevel;
  final int reportCount;
  final int verifiedReportCount;
  final int distinctReporterCount;
  final String status;

  /// Whether users can currently see this indicator.
  bool get isPublic => status == 'active' && verifiedReportCount > 0;

  /// Reports from one person are not corroboration, however many there are.
  bool get isSingleReporter => distinctReporterCount <= 1;

  static IndicatorStanding? tryFromJson(Map<String, Object?> json) {
    final hash = json['indicator_hash'] as String?;
    if (hash == null) return null;
    return IndicatorStanding(
      hash: hash,
      maskedValue: json['display_value_masked'] as String?,
      riskLevel: json['risk_level'] as String? ?? 'caution',
      reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
      verifiedReportCount:
          (json['verified_report_count'] as num?)?.toInt() ?? 0,
      distinctReporterCount:
          (json['distinct_reporter_count'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }
}

/// One entry in the append-only audit log.
class ModerationEntry {
  const ModerationEntry({
    required this.id,
    required this.moderatorId,
    required this.action,
    required this.createdAt,
    this.reportId,
    this.notes,
    this.previousStatus,
    this.newStatus,
  });

  final String id;
  final String moderatorId;
  final String action;
  final DateTime createdAt;
  final String? reportId;
  final String? notes;
  final String? previousStatus;
  final String? newStatus;

  static ModerationEntry? tryFromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final moderatorId = json['moderator_id'] as String?;
    if (id == null || moderatorId == null) return null;
    return ModerationEntry(
      id: id,
      moderatorId: moderatorId,
      action: json['action'] as String? ?? 'unknown',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      reportId: json['report_id'] as String?,
      notes: json['notes'] as String?,
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String?,
    );
  }
}

/// A detection rule, as the dashboard edits it.
class RemoteRule {
  const RemoteRule({
    required this.id,
    required this.ruleCode,
    required this.category,
    required this.weight,
    required this.escalationFloor,
    required this.enabled,
    required this.patternCount,
    required this.version,
  });

  final String id;
  final String ruleCode;
  final String category;
  final int weight;
  final int escalationFloor;
  final bool enabled;
  final int patternCount;
  final int version;

  static RemoteRule? tryFromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final code = json['rule_code'] as String?;
    if (id == null || code == null) return null;
    return RemoteRule(
      id: id,
      ruleCode: code,
      category: json['category'] as String? ?? 'other',
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      escalationFloor: (json['escalation_floor'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] != false,
      patternCount: (json['patterns'] as List?)?.length ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Who is signed in to the dashboard.
enum ModeratorRole {
  user,
  moderator,
  admin;

  static ModeratorRole fromId(String? id) => switch (id) {
    'admin' => ModeratorRole.admin,
    'moderator' => ModeratorRole.moderator,
    _ => ModeratorRole.user,
  };

  /// Only these two may see anything. An ordinary account signing in gets a
  /// refusal, not an empty queue — an empty queue looks like "no work today".
  bool get canModerate =>
      this == ModeratorRole.moderator || this == ModeratorRole.admin;

  /// Rule changes affect every user's detection, so they are admin-only.
  bool get canManageRules => this == ModeratorRole.admin;
}

/// The verdicts a moderator can record, and what each one means.
enum Verdict {
  verify(ReportStatus.verified, 'verify'),
  reject(ReportStatus.rejected, 'reject'),
  needsEvidence(ReportStatus.needsMoreEvidence, 'request_evidence'),
  markDuplicate(ReportStatus.duplicate, 'mark_duplicate'),
  archive(ReportStatus.archived, 'archive');

  const Verdict(this.status, this.action);

  final ReportStatus status;

  /// Recorded in the audit log verbatim.
  final String action;

  /// Verifying is what makes an indicator visible to users, so it is the one
  /// verdict that requires the moderator to say why.
  bool get requiresNote => this == Verdict.verify || this == Verdict.reject;
}
