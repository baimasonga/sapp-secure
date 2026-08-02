import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'features/authentication/data/supabase_auth_gateway.dart';
import 'moderation/application/moderation_controllers.dart';
import 'moderation/data/supabase_moderation_gateway.dart';
import 'moderation/moderation_app.dart';
import 'services/supabase/supabase_bootstrap.dart';

/// Entry point for the moderation dashboard.
///
///     flutter build web -t lib/moderation_main.dart \
///       --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// The **anon key only**, exactly as on the phone. A web bundle is public;
/// anyone can read it. The dashboard's authority comes from the moderator's
/// own session and the row-level security behind it, never from a key baked
/// into the build. If a service-role key ever appears in this file, every
/// report in the database is public.
///
/// Unlike the phone app, this one cannot run without a backend — a moderation
/// queue with no database is not a degraded experience, it is nothing at all —
/// so it says so plainly rather than starting into an empty shell.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ready = await SupabaseBootstrap.initialise();
  if (!ready) {
    runApp(const _NotConfigured());
    return;
  }

  final client = Supabase.instance.client;

  runApp(
    ProviderScope(
      overrides: [
        moderationAuthProvider.overrideWithValue(SupabaseAuthGateway(client)),
        moderationGatewayProvider.overrideWithValue(
          SupabaseModerationGateway(client),
        ),
      ],
      child: const ModerationApp(),
    ),
  );
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'This build has no Supabase configuration. Rebuild with '
              'SUPABASE_URL and SUPABASE_ANON_KEY set.\n\n'
              'Environment: ${AppConfig.environment.name}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
