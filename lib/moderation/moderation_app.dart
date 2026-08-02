import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../features/authentication/domain/auth_gateway.dart';
import 'application/moderation_controllers.dart';
import 'presentation/moderation_shell.dart';
import 'presentation/moderation_strings.dart';
import 'presentation/moderator_sign_in_page.dart';

/// The dashboard's identity provider. Overridden in tests.
final moderationAuthProvider = Provider<AuthGateway>(
  (ref) => throw UnimplementedError('moderationAuthProvider not overridden'),
);

/// The signed-in moderator, or null.
final moderationUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(moderationAuthProvider).authStateChanges(),
);

/// The moderation dashboard.
///
/// Shares the phone app's design system deliberately: the same risk
/// vocabulary, the same colours for the same meanings. A moderator who has
/// used the app should not have to learn a second visual language to decide
/// what it tells people.
class ModerationApp extends ConsumerWidget {
  const ModerationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: Mod.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(moderationAuthProvider);
    final user = ref.watch(moderationUserProvider);

    return user.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => ModeratorSignInPage(auth: auth),
      data: (value) {
        if (value == null) return ModeratorSignInPage(auth: auth);
        return ModerationShell(
          onSignOut: () async {
            await auth.signOut();
            // The role is per-account, so it must not survive a sign-out.
            ref.invalidate(currentRoleProvider);
          },
        );
      },
    );
  }
}
