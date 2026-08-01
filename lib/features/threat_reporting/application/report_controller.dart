import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/config/app_config.dart';
import '../../authentication/data/supabase_auth_gateway.dart';
import '../../authentication/domain/auth_gateway.dart';
import '../data/supabase_report_gateway.dart';
import '../domain/report_gateway.dart';
import '../domain/threat_report.dart';

sealed class ReportSubmissionState {
  const ReportSubmissionState();
}

class ReportIdle extends ReportSubmissionState {
  const ReportIdle();
}

class ReportSubmitting extends ReportSubmissionState {
  const ReportSubmitting();
}

class ReportSubmitted extends ReportSubmissionState {
  const ReportSubmitted(this.result);

  final ReportSubmissionResult result;
}

class ReportRejected extends ReportSubmissionState {
  const ReportRejected(this.failure);

  final ReportFailure failure;
}

/// Drives the report form.
class ReportController extends StateNotifier<ReportSubmissionState> {
  ReportController(this._gateway) : super(const ReportIdle());

  final ReportGateway _gateway;

  Future<void> submit(ReportDraft draft) async {
    // Validated again here rather than trusting the form, because the same
    // checks run server-side and a mismatch would be a confusing failure.
    final errors = draft.validate();
    if (errors.isNotEmpty) {
      state = ReportRejected(
        ReportFailure(
          errors.contains(ReportValidationError.consentRequired)
              ? ReportFailureReason.consentMissing
              : ReportFailureReason.nothingToReport,
        ),
      );
      return;
    }

    state = const ReportSubmitting();
    try {
      state = ReportSubmitted(await _gateway.submit(draft));
    } on ReportFailure catch (failure) {
      state = ReportRejected(failure);
    } on Exception {
      state = const ReportRejected(ReportFailure(ReportFailureReason.unknown));
    }
  }

  void reset() => state = const ReportIdle();
}

/// The Supabase client, or null when the app is in local-only mode.
final supabaseClientProvider = Provider<supa.SupabaseClient?>((ref) {
  if (!AppConfig.isSupabaseConfigured) return null;
  try {
    return supa.Supabase.instance.client;
  } on Exception {
    // Not initialised: the app keeps working locally.
    return null;
  }
});

/// Null when the app has no backend, which is what keeps guest mode working.
final authGatewayProvider = Provider<AuthGateway?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseAuthGateway(client);
});

final reportGatewayProvider = Provider<ReportGateway?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseReportGateway(client);
});

/// Whether the reporting UI should be offered at all.
final reportingAvailableProvider = Provider<bool>(
  (ref) =>
      AppConfig.isReportingAvailable &&
      ref.watch(reportGatewayProvider) != null,
);

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authGatewayProvider);
  if (auth == null) return const Stream<AppUser?>.empty();
  return auth.authStateChanges();
});

final reportControllerProvider =
    StateNotifierProvider<ReportController, ReportSubmissionState>((ref) {
      final gateway = ref.watch(reportGatewayProvider);
      if (gateway == null) {
        throw StateError(
          'The report controller was read with no backend configured. '
          'Guard the UI with reportingAvailableProvider.',
        );
      }
      return ReportController(gateway);
    });

/// The signed-in user's own reports.
final myReportsProvider = FutureProvider<List<SubmittedReport>>((ref) async {
  final gateway = ref.watch(reportGatewayProvider);
  if (gateway == null) return const [];
  return gateway.myReports();
});
