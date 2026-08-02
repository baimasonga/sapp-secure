import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salone_shield/features/threat_reporting/domain/threat_report.dart';
import 'package:salone_shield/moderation/application/moderation_controllers.dart';
import 'package:salone_shield/moderation/data/moderation_gateway.dart';
import 'package:salone_shield/moderation/domain/moderation_models.dart';

/// A moderation backend with no database behind it.
///
/// [verdicts] and [auditEntries] are how the tests check the property that
/// matters most: a decision and its audit entry are written together, or
/// neither is.
class FakeModerationGateway implements ModerationGateway {
  FakeModerationGateway({
    this.role = ModeratorRole.moderator,
    List<QueuedReport>? reports,
    List<ModerationEntry>? log,
    List<RemoteRule>? ruleList,
    this.failWith,
  }) : reports = reports ?? [],
       log = log ?? [],
       ruleList = ruleList ?? [];

  ModeratorRole role;
  final List<QueuedReport> reports;
  final List<ModerationEntry> log;
  final List<RemoteRule> ruleList;
  ModerationFailureReason? failWith;

  /// Every verdict the dashboard asked for.
  final List<({QueuedReport report, Verdict verdict, String note})> verdicts =
      [];

  /// Audit entries the dashboard caused to be written.
  final List<ModerationEntry> auditEntries = [];

  final Map<String, bool> ruleToggles = {};

  @override
  Future<ModeratorRole> currentRole() async => role;

  @override
  Future<List<QueuedReport>> queue({Set<ReportStatus>? statuses}) async {
    final failure = failWith;
    if (failure != null) throw ModerationFailure(failure);
    if (statuses == null) return reports;
    return reports
        .where((report) => statuses.contains(report.status))
        .toList(growable: false);
  }

  @override
  Future<QueuedReport?> reportById(String id) async {
    for (final report in reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  @override
  Future<void> recordVerdict({
    required QueuedReport report,
    required Verdict verdict,
    required String note,
    String? duplicateOf,
  }) async {
    final failure = failWith;
    if (failure != null) throw ModerationFailure(failure);

    // The real gateway writes the audit entry and the status change together.
    // The fake mirrors that so a test can assert both, or neither.
    auditEntries.add(
      ModerationEntry(
        id: 'entry-${auditEntries.length + 1}',
        moderatorId: 'moderator-1',
        action: verdict.action,
        createdAt: DateTime(2026),
        reportId: report.id,
        notes: note.trim().isEmpty ? null : note.trim(),
        previousStatus: report.status.id,
        newStatus: verdict.status.id,
      ),
    );
    verdicts.add((report: report, verdict: verdict, note: note));
  }

  @override
  Future<List<ModerationEntry>> auditLog({int limit = 100}) async => [
    ...log,
    ...auditEntries,
  ];

  @override
  Future<List<RemoteRule>> rules() async => ruleList;

  @override
  Future<void> setRuleEnabled({
    required String ruleId,
    required bool enabled,
  }) async {
    ruleToggles[ruleId] = enabled;
  }
}

QueuedReport fakeReport({
  String id = 'report-1',
  ReportStatus status = ReportStatus.pending,
  ThreatType type = ThreatType.impersonation,
  String? excerpt = 'They asked me to send the code',
  IndicatorStanding? indicator,
  String? reporterId = 'reporter-1',
}) => QueuedReport(
  id: id,
  threatType: type,
  status: status,
  createdAt: DateTime(2026, 7, 30),
  reporterId: reporterId,
  reportedNumberHash: 'hash-1',
  messageExcerpt: excerpt,
  district: 'Western Area',
  riskSignals: const ['verification_code_request'],
  indicator: indicator,
);

IndicatorStanding fakeIndicator({
  int reportCount = 3,
  int verifiedReportCount = 0,
  int distinctReporterCount = 3,
  String status = 'active',
}) => IndicatorStanding(
  hash: 'hash-1',
  maskedValue: '+232 ** *** 456',
  riskLevel: 'caution',
  reportCount: reportCount,
  verifiedReportCount: verifiedReportCount,
  distinctReporterCount: distinctReporterCount,
  status: status,
);

List<Override> moderationOverrides(FakeModerationGateway gateway) => [
  moderationGatewayProvider.overrideWithValue(gateway),
];
