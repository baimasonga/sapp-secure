/// Build-time configuration.
///
/// Values arrive through `--dart-define` (or `--dart-define-from-file`), never
/// from a file committed to the repository. See `.env.example` and
/// `docs/SETUP.md`. Only the Supabase *anon* key belongs here; the service-role
/// key must never reach a mobile build.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromName(String value) =>
      AppEnvironment.values.firstWhere(
        (env) => env.name == value,
        orElse: () => AppEnvironment.development,
      );
}

abstract final class AppConfig {
  static final AppEnvironment environment = AppEnvironment.fromName(
    const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );
  static const bool enableNotificationMonitoring = bool.fromEnvironment(
    'ENABLE_NOTIFICATION_MONITORING',
    defaultValue: false,
  );
  static const bool enableExternalUrlReputation = bool.fromEnvironment(
    'ENABLE_EXTERNAL_URL_REPUTATION',
    defaultValue: false,
  );

  /// The app is fully usable without Supabase: guest analysis is the default
  /// path, so a missing backend configuration must never block startup.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isProduction => environment == AppEnvironment.production;
}
