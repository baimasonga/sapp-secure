import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salone_shield/features/authentication/domain/auth_gateway.dart';
import 'package:salone_shield/features/threat_reporting/application/report_controller.dart';
import 'package:salone_shield/features/threat_reporting/domain/report_gateway.dart';
import 'package:salone_shield/features/threat_reporting/domain/threat_report.dart';

/// A backend that records what it was asked to send.
///
/// [submitted] is how the tests check the privacy promise: whatever the form
/// showed the user is exactly what reaches this gateway, and nothing else.
class FakeReportGateway implements ReportGateway {
  FakeReportGateway({
    this.failWith,
    this.duplicate = false,
    List<SubmittedReport>? history,
  }) : history = history ?? [];

  ReportFailureReason? failWith;
  bool duplicate;
  final List<SubmittedReport> history;
  final List<ReportDraft> submitted = [];

  @override
  Future<ReportSubmissionResult> submit(ReportDraft draft) async {
    submitted.add(draft);
    final failure = failWith;
    if (failure != null) throw ReportFailure(failure);
    return ReportSubmissionResult(
      reportId: 'abcdef12-0000-0000-0000-000000000000',
      wasDuplicate: duplicate,
    );
  }

  @override
  Future<List<SubmittedReport>> myReports() async => history;
}

/// An identity provider with no network behind it.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.user});

  /// Mutable so sign-in and sign-out are observable in a test.
  AppUser? user;
  final List<String> signedUpEmails = [];
  AuthFailureReason? failWith;
  bool deleted = false;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(user);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final failure = failWith;
    if (failure != null) throw AuthFailure(failure);
    user = AppUser(id: 'user-1', email: email, emailConfirmed: true);
    return user!;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final failure = failWith;
    if (failure != null) throw AuthFailure(failure);
    signedUpEmails.add(email);
    return AppUser(id: 'user-1', email: email);
  }

  @override
  Future<void> signOut() async => user = null;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> deleteAccount() async {
    deleted = true;
    user = null;
  }
}

/// Wires a fake backend in and forces the reporting UI on, which the real app
/// keeps behind a build flag until row-level security has been verified.
List<Override> reportingOverrides({
  required FakeReportGateway reports,
  FakeAuthGateway? auth,
}) => [
  reportGatewayProvider.overrideWithValue(reports),
  authGatewayProvider.overrideWithValue(auth ?? FakeAuthGateway()),
  currentUserProvider.overrideWith(
    (ref) => Stream.value((auth ?? FakeAuthGateway()).currentUser),
  ),
  reportingAvailableProvider.overrideWithValue(true),
];

/// A signed-in user, for the paths that need one.
AppUser get testUser => const AppUser(
  id: 'user-1',
  email: 'user@example.com',
  emailConfirmed: true,
);
