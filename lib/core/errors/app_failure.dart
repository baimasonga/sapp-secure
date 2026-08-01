/// Typed failures (section 25).
///
/// Every failure states what went wrong, whether anything was saved, and
/// whether retrying is safe — so the UI never has to guess and never has to
/// show a stack trace or a database error to the user.
///
/// Abstract rather than sealed: features define their own failures with the
/// detail their screens need (a sign-in screen must distinguish "wrong
/// password" from "email not confirmed"), and a sealed hierarchy would force
/// that vocabulary into core. Nothing switches exhaustively over failures —
/// every handler has a default branch, because an unrecognised failure must
/// still produce a sensible message rather than a crash.
abstract class AppFailure implements Exception {
  const AppFailure({
    required this.debugMessage,
    required this.dataWasSaved,
    required this.retrySafe,
  });

  /// For logs only. Must never contain message content, contact names,
  /// tokens, codes or PINs.
  final String debugMessage;

  final bool dataWasSaved;
  final bool retrySafe;

  @override
  String toString() => '$runtimeType($debugMessage)';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({super.debugMessage = 'network unavailable'})
    : super(dataWasSaved: false, retrySafe: true);
}

class PermissionFailure extends AppFailure {
  const PermissionFailure({required this.permission})
    : super(
        debugMessage: 'permission denied',
        dataWasSaved: false,
        retrySafe: true,
      );

  final String permission;
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required this.field,
    super.debugMessage = 'invalid input',
  }) : super(dataWasSaved: false, retrySafe: true);

  final String field;
}

class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure({super.debugMessage = 'authentication failed'})
    : super(dataWasSaved: false, retrySafe: true);
}

class StorageFailure extends AppFailure {
  const StorageFailure({
    super.debugMessage = 'local storage unavailable',
    super.dataWasSaved = false,
  }) : super(retrySafe: true);
}

class AnalysisFailure extends AppFailure {
  const AnalysisFailure({super.debugMessage = 'analysis could not run'})
    : super(dataWasSaved: false, retrySafe: true);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({super.debugMessage = 'unexpected error'})
    : super(dataWasSaved: false, retrySafe: true);
}
