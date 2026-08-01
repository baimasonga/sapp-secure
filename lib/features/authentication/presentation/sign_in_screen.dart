import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../threat_reporting/application/report_controller.dart';
import '../domain/auth_gateway.dart';

/// Sign in or create an account (specification section 18).
///
/// Only reporting needs this. Every protective feature works signed out, and
/// the screen says so, because a security app that nags for an account teaches
/// exactly the habit scammers exploit.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _isSignUp = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  static const int minPasswordLength = 8;

  @override
  void dispose() {
    _email.dispose();
    // Cleared before disposal so the password does not sit in a retained
    // editing buffer.
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  String _messageFor(AppLocalizations l10n, AuthFailureReason reason) =>
      switch (reason) {
        AuthFailureReason.invalidCredentials => l10n.authErrorInvalid,
        AuthFailureReason.emailNotConfirmed => l10n.authErrorNotConfirmed,
        AuthFailureReason.emailAlreadyRegistered =>
          l10n.authErrorAlreadyRegistered,
        AuthFailureReason.weakPassword => l10n.authErrorWeakPassword,
        AuthFailureReason.rateLimited => l10n.authErrorRateLimited,
        AuthFailureReason.network => l10n.authErrorNetwork,
        AuthFailureReason.unknown => l10n.authErrorUnknown,
      };

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authGatewayProvider);
    if (auth == null) return;

    if (_password.text.length < minPasswordLength) {
      setState(() => _error = l10n.authErrorWeakPassword);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      if (_isSignUp) {
        await auth.signUp(email: _email.text, password: _password.text);
        if (!mounted) return;
        setState(() {
          _notice = l10n.authCheckEmail;
          _isSignUp = false;
        });
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = _messageFor(l10n, failure.reason));
    } on Exception {
      if (!mounted) return;
      setState(() => _error = l10n.authErrorUnknown);
    } finally {
      // The password is not kept around after an attempt.
      _password.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authGatewayProvider);
    if (auth == null || _email.text.trim().isEmpty) {
      setState(() => _error = l10n.authErrorInvalid);
      return;
    }
    try {
      await auth.sendPasswordReset(_email.text);
    } on AuthFailure {
      // Deliberately not surfaced: whether an address has an account is not
      // something this screen should reveal.
    }
    if (!mounted) return;
    setState(() => _notice = l10n.authResetSent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _isSignUp ? l10n.authSignUpTitle : l10n.authSignInTitle;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _NeverAsksBanner(text: l10n.authNeverAsksCode),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: l10n.authEmail),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l10n.authPassword,
                helperText: _isSignUp ? l10n.authPasswordHelp : null,
                helperMaxLines: 2,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _Banner(message: _error!, isError: true),
            ],
            if (_notice != null) ...[
              const SizedBox(height: 16),
              _Banner(message: _notice!, isError: false),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isSignUp ? l10n.authSignUp : l10n.authSignIn),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _isSignUp = !_isSignUp;
                      _error = null;
                      _notice = null;
                    }),
              child: Text(
                _isSignUp ? l10n.authSwitchToSignIn : l10n.authSwitchToSignUp,
              ),
            ),
            if (!_isSignUp)
              TextButton(
                onPressed: _busy ? null : _resetPassword,
                child: Text(l10n.authForgotPassword),
              ),
            const SizedBox(height: 24),
            Text(
              l10n.authGuestNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// The one thing this screen must say, given that a fake sign-in page is
/// exactly how these accounts get stolen.
class _NeverAsksBanner extends StatelessWidget {
  const _NeverAsksBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError
        ? scheme.errorContainer
        : scheme.surfaceContainerHighest;
    final foreground = isError ? scheme.onErrorContainer : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}
