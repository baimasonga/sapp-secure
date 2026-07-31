import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

/// Optional Supabase initialisation.
///
/// Guest analysis is the default path, so the app must start and work
/// perfectly with no backend configured. Only the anon key is ever used here;
/// the service-role key must never be shipped in a mobile build (section 16.3).
abstract final class SupabaseBootstrap {
  static bool _initialised = false;

  static bool get isInitialised => _initialised;

  /// Returns true when a client is available, false when the app should stay
  /// in local-only mode. Never throws: a backend problem must not stop a user
  /// from checking a message.
  static Future<bool> initialise() async {
    if (_initialised) return true;
    if (!AppConfig.isSupabaseConfigured) return false;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // Supabase renamed this parameter; the environment variable keeps the
        // familiar SUPABASE_ANON_KEY name.
        publishableKey: AppConfig.supabaseAnonKey,
        debug: !AppConfig.isProduction,
      );
      _initialised = true;
      return true;
    } on Exception {
      // Deliberately not logged with detail: connection strings and tokens
      // must never reach the log (section 23).
      return false;
    }
  }
}
