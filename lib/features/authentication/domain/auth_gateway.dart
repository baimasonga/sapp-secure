import '../../../core/errors/app_failure.dart';

/// The signed-in user, as much of them as the app needs.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.emailConfirmed = false,
    this.isSuspended = false,
  });

  final String id;
  final String email;
  final bool emailConfirmed;

  /// A suspended reporter can still use every local feature; they simply
  /// cannot submit reports (section 17.4).
  final bool isSuspended;
}

/// Everything the app needs from an identity provider.
///
/// An interface, so the reporting feature can be built and tested without a
/// backend, and so guest mode never depends on Supabase being reachable.
abstract interface class AuthGateway {
  /// The current user, or null when signed out.
  AppUser? get currentUser;

  /// Emits on sign-in, sign-out and token refresh.
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signUp({required String email, required String password});

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  /// Removes the account and everything attached to it (section 18).
  Future<void> deleteAccount();
}

/// Reasons a sign-in attempt can fail, in terms the UI can explain.
enum AuthFailureReason {
  invalidCredentials,
  emailNotConfirmed,
  emailAlreadyRegistered,
  weakPassword,
  rateLimited,
  network,
  unknown,
}

class AuthFailure extends AppFailure {
  const AuthFailure(this.reason, {super.debugMessage = 'authentication failed'})
    : super(dataWasSaved: false, retrySafe: true);

  final AuthFailureReason reason;
}
