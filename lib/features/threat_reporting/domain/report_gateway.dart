import 'threat_report.dart';

/// The outcome of a submission.
class ReportSubmissionResult {
  const ReportSubmissionResult({
    required this.reportId,
    required this.wasDuplicate,
  });

  final String reportId;

  /// The server recognised this as something the same reporter already sent.
  /// Not an error: the user is told their earlier report still stands.
  final bool wasDuplicate;
}

/// Sends reports and reads back the user's own history.
///
/// An interface so the report flow can be built and tested without a backend.
abstract interface class ReportGateway {
  Future<ReportSubmissionResult> submit(ReportDraft draft);

  /// The signed-in user's own reports, newest first.
  Future<List<SubmittedReport>> myReports();
}
