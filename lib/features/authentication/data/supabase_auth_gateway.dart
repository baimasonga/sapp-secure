import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../domain/auth_gateway.dart';

/// [AuthGateway] backed by Supabase Auth.
///
/// Sessions are stored by supabase_flutter in the platform's secure storage.
/// Nothing in this class logs an email, a password or a token.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final supa.SupabaseClient _client;

  @override
  AppUser? get currentUser => _toAppUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() => _client.auth.onAuthStateChange.map(
    (event) => _toAppUser(event.session?.user),
  );

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      final user = _toAppUser(response.user);
      if (user == null) throw const AuthFailure(AuthFailureReason.unknown);
      return user;
    } on supa.AuthException catch (error) {
      throw AuthFailure(_reasonFor(error));
    } on Exception {
      throw const AuthFailure(AuthFailureReason.network);
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = _toAppUser(response.user);
      if (user == null) {
        throw const AuthFailure(AuthFailureReason.invalidCredentials);
      }
      return user;
    } on supa.AuthException catch (error) {
      throw AuthFailure(_reasonFor(error));
    } on Exception {
      throw const AuthFailure(AuthFailureReason.network);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on Exception {
      // A failed sign-out still clears the local session, which is what the
      // user asked for.
      return;
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on supa.AuthException catch (error) {
      throw AuthFailure(_reasonFor(error));
    } on Exception {
      throw const AuthFailure(AuthFailureReason.network);
    }
  }

  @override
  Future<void> deleteAccount() async {
    // Deletion needs privileges the app must never hold, so it goes through an
    // Edge Function that verifies the caller's own token.
    try {
      await _client.functions.invoke('delete-account');
      await _client.auth.signOut();
    } on Exception {
      throw const AuthFailure(
        AuthFailureReason.unknown,
        debugMessage: 'account deletion failed',
      );
    }
  }

  AppUser? _toAppUser(supa.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      emailConfirmed: user.emailConfirmedAt != null,
    );
  }

  /// Maps Supabase's messages onto reasons the UI can phrase helpfully. The
  /// message itself is never shown to the user.
  AuthFailureReason _reasonFor(supa.AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return AuthFailureReason.emailAlreadyRegistered;
    }
    if (message.contains('not confirmed')) {
      return AuthFailureReason.emailNotConfirmed;
    }
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return AuthFailureReason.invalidCredentials;
    }
    if (message.contains('password')) return AuthFailureReason.weakPassword;
    if (message.contains('rate limit') || error.statusCode == '429') {
      return AuthFailureReason.rateLimited;
    }
    return AuthFailureReason.unknown;
  }
}
