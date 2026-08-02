import '../../features/threat_reporting/domain/threat_report.dart';
import '../domain/moderation_models.dart';

/// Everything the dashboard needs from the backend.
///
/// An interface, so the queue and the verdict flow can be built and tested
/// without a database — and so the tests can prove the dashboard writes an
/// audit entry for every decision, which is the property that matters most
/// and the one hardest to check by looking.
abstract interface class ModerationGateway {
  /// The signed-in moderator's role, read from their own profile.
  Future<ModeratorRole> currentRole();

  /// Reports awaiting or under review, oldest first — a queue, not a feed.
  /// The oldest report is the one someone has been waiting on longest.
  Future<List<QueuedReport>> queue({Set<ReportStatus> statuses});

  Future<QueuedReport?> reportById(String id);

  /// Records a decision **and** its audit entry. One call, because a verdict
  /// without an audit entry is exactly the thing the log exists to prevent,
  /// and two calls from the UI is two chances to write only the first.
  Future<void> recordVerdict({
    required QueuedReport report,
    required Verdict verdict,
    required String note,
    String? duplicateOf,
  });

  Future<List<ModerationEntry>> auditLog({int limit});

  Future<List<RemoteRule>> rules();

  Future<void> setRuleEnabled({required String ruleId, required bool enabled});
}

/// Why a dashboard operation failed, in terms the UI can explain.
enum ModerationFailureReason {
  notSignedIn,
  notAModerator,
  network,
  rejectedByServer,
  unknown,
}

class ModerationFailure implements Exception {
  const ModerationFailure(this.reason, {this.debugMessage});

  final ModerationFailureReason reason;
  final String? debugMessage;

  @override
  String toString() => 'ModerationFailure($reason)';
}
