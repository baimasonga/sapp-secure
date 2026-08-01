import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../domain/report_gateway.dart';
import '../domain/threat_report.dart';

/// Sends reports through the `submit-report` Edge Function.
///
/// The app deliberately does not insert into `threat_reports` directly, even
/// though row-level security would allow it. Hashing needs a pepper the device
/// must never hold, and rate limiting and duplicate detection are worthless
/// if the client can skip them.
class SupabaseReportGateway implements ReportGateway {
  const SupabaseReportGateway(this._client);

  final supa.SupabaseClient _client;

  static const String submitFunction = 'submit-report';

  @override
  Future<ReportSubmissionResult> submit(ReportDraft draft) async {
    if (_client.auth.currentUser == null) {
      throw const ReportFailure(ReportFailureReason.notSignedIn);
    }
    final errors = draft.validate();
    if (errors.contains(ReportValidationError.consentRequired)) {
      throw const ReportFailure(ReportFailureReason.consentMissing);
    }
    if (errors.contains(ReportValidationError.nothingToReport)) {
      throw const ReportFailure(ReportFailureReason.nothingToReport);
    }

    try {
      final response = await _client.functions.invoke(
        submitFunction,
        body: draft.toSubmission(),
      );

      final status = response.status;
      final data = response.data;

      // Each status the server can return maps to something the user can act
      // on, rather than to a generic error.
      final failure = switch (status) {
        429 => ReportFailureReason.rateLimited,
        403 => ReportFailureReason.suspended,
        401 => ReportFailureReason.notSignedIn,
        _ when status >= 400 => ReportFailureReason.unknown,
        _ => null,
      };
      if (failure != null) throw ReportFailure(failure);
      if (data is! Map) {
        throw const ReportFailure(ReportFailureReason.unknown);
      }

      final reportId = data['report_id'] as String?;
      if (reportId == null) {
        throw const ReportFailure(ReportFailureReason.unknown);
      }
      return ReportSubmissionResult(
        reportId: reportId,
        wasDuplicate: data['status'] == 'duplicate',
      );
    } on ReportFailure {
      rethrow;
    } on supa.FunctionException catch (error) {
      throw ReportFailure(
        error.status == 429
            ? ReportFailureReason.rateLimited
            : ReportFailureReason.unknown,
      );
    } on Exception {
      // No detail is logged: the payload contains a telephone number.
      throw const ReportFailure(ReportFailureReason.network);
    }
  }

  @override
  Future<List<SubmittedReport>> myReports() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ReportFailure(ReportFailureReason.notSignedIn);
    }
    try {
      // Row-level security limits this to the caller's own rows; the filter is
      // here so a policy mistake shows up as missing data rather than as
      // somebody else's reports appearing on screen.
      final rows = await _client
          .from('threat_reports')
          .select('id, threat_type, status, created_at, reviewed_at')
          .eq('reporter_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);

      return [
        for (final row in rows)
          ?SubmittedReport.tryFromJson(Map<String, Object?>.from(row)),
      ];
    } on Exception {
      throw const ReportFailure(ReportFailureReason.network);
    }
  }
}
