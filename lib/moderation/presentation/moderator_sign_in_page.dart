import 'package:flutter/material.dart';

import '../../app/design/app_typography.dart';
import '../../app/design/design_tokens.dart';
import '../../core/widgets/ds_components.dart';
import '../../features/authentication/domain/auth_gateway.dart';
import 'moderation_strings.dart';

/// Moderator sign-in.
///
/// No sign-up and no password reset by design: moderator accounts are created
/// deliberately by an administrator, not self-served. A public sign-up form on
/// a moderation dashboard is an invitation.
class ModeratorSignInPage extends StatefulWidget {
  const ModeratorSignInPage({super.key, required this.auth});

  final AuthGateway auth;

  @override
  State<ModeratorSignInPage> createState() => _ModeratorSignInPageState();
}

class _ModeratorSignInPageState extends State<ModeratorSignInPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    // Cleared before disposal so the password does not sit in a retained
    // editing buffer.
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.signIn(email: _email.text, password: _password.text);
    } on AuthFailure {
      // One message for every failure. Distinguishing "no such account" from
      // "wrong password" would tell an attacker which moderator emails exist.
      if (mounted) setState(() => _error = Mod.signInFailed);
    } on Exception {
      if (mounted) setState(() => _error = Mod.signInFailed);
    } finally {
      _password.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(DsSpace.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: DsBrandMark(size: 56)),
                  const SizedBox(height: DsSpace.x6),
                  Text(
                    Mod.signInTitle,
                    style: AppType.headline.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: DsSpace.x2),
                  Text(
                    Mod.signInBody,
                    style: AppType.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DsSpace.x6),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: Mod.email),
                  ),
                  const SizedBox(height: DsSpace.x4),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: const InputDecoration(labelText: Mod.password),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: DsSpace.x4),
                    DsNotice(
                      icon: Icons.error_outline,
                      tone: DsNoticeTone.danger,
                      text: _error!,
                    ),
                  ],
                  const SizedBox(height: DsSpace.x6),
                  FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login, size: 20),
                    label: const Text(Mod.signIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
