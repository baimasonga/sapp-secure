import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/threat_reporting/domain/threat_report.dart';
import '../data/moderation_gateway.dart';
import '../domain/moderation_models.dart';

/// Overridden at start-up with a Supabase-backed gateway, and in tests with a
/// fake. Nothing else in the dashboard talks to the backend.
final moderationGatewayProvider = Provider<ModerationGateway>(
  (ref) => throw UnimplementedError('moderationGatewayProvider not overridden'),
);

/// The signed-in moderator's role. Everything the dashboard shows hangs off
/// this, and it is re-read rather than cached across sign-ins.
final currentRoleProvider = FutureProvider<ModeratorRole>(
  (ref) => ref.watch(moderationGatewayProvider).currentRole(),
);

/// Which statuses the queue is showing.
final queueFilterProvider = StateProvider<Set<ReportStatus>>(
  (ref) => const {
    ReportStatus.pending,
    ReportStatus.underReview,
    ReportStatus.needsMoreEvidence,
  },
);

final queueProvider = FutureProvider<List<QueuedReport>>((ref) {
  final statuses = ref.watch(queueFilterProvider);
  return ref.watch(moderationGatewayProvider).queue(statuses: statuses);
});

final reportProvider = FutureProvider.family<QueuedReport?, String>(
  (ref, id) => ref.watch(moderationGatewayProvider).reportById(id),
);

final auditLogProvider = FutureProvider<List<ModerationEntry>>(
  (ref) => ref.watch(moderationGatewayProvider).auditLog(limit: 100),
);

final rulesProvider = FutureProvider<List<RemoteRule>>(
  (ref) => ref.watch(moderationGatewayProvider).rules(),
);

/// What the verdict form is doing.
sealed class VerdictState {
  const VerdictState();
}

class VerdictIdle extends VerdictState {
  const VerdictIdle();
}

class VerdictSaving extends VerdictState {
  const VerdictSaving();
}

class VerdictSaved extends VerdictState {
  const VerdictSaved();
}

class VerdictRefused extends VerdictState {
  const VerdictRefused(this.reason);

  final ModerationFailureReason reason;
}

/// Records a decision, then makes every view of that report reload.
class VerdictController extends StateNotifier<VerdictState> {
  VerdictController(this._ref) : super(const VerdictIdle());

  final Ref _ref;

  Future<bool> submit({
    required QueuedReport report,
    required Verdict verdict,
    required String note,
    String? duplicateOf,
  }) async {
    state = const VerdictSaving();
    try {
      await _ref
          .read(moderationGatewayProvider)
          .recordVerdict(
            report: report,
            verdict: verdict,
            note: note,
            duplicateOf: duplicateOf,
          );
    } on ModerationFailure catch (failure) {
      state = VerdictRefused(failure.reason);
      return false;
    } on Exception {
      state = const VerdictRefused(ModerationFailureReason.unknown);
      return false;
    }

    // The queue, the report and the log all changed. Invalidating rather than
    // patching local state means the dashboard shows what the database
    // actually holds, including anything a policy quietly refused.
    _ref.invalidate(queueProvider);
    _ref.invalidate(reportProvider(report.id));
    _ref.invalidate(auditLogProvider);
    state = const VerdictSaved();
    return true;
  }
}

final verdictControllerProvider =
    StateNotifierProvider<VerdictController, VerdictState>(
      (ref) => VerdictController(ref),
    );
