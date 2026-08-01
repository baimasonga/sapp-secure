import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../services/risk_engine/models/risk_assessment.dart';

/// Non-secret local settings and the small, message-free analysis history.
///
/// Nothing written here may contain message text, matched excerpts, contact
/// names, full telephone numbers or links (section 15.3). Secrets belong in
/// [SecureStorageService].
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyLanguage = 'settings.language';
  static const String _keyThemeMode = 'settings.theme_mode';
  static const String _keyOnboardingComplete = 'onboarding.complete';
  static const String _keyAnalyticsConsent = 'privacy.analytics_consent';
  static const String _keyRecentAnalyses = 'history.recent_analyses';

  /// Notification monitoring, read from Kotlin as well as from Dart.
  ///
  /// The listener service reads these same keys directly out of the
  /// shared-preferences file, so turning monitoring off here stops the next
  /// notification being read rather than the next time the service restarts.
  /// The names must not change without changing `MonitoringSettings.kt`.
  static const String _keyNotificationsEnabled =
      'notifications.monitoring_enabled';
  static String _keyMonitoredApp(String packageName) =>
      'notifications.app.$packageName';

  /// Retention limits from section 15.3.
  static const int maxRecentAnalyses = 20;
  static const Duration recentAnalysisRetention = Duration(days: 30);

  static Future<PreferencesService> create() async =>
      PreferencesService(await SharedPreferences.getInstance());

  String? get languageCode => _prefs.getString(_keyLanguage);
  Future<void> setLanguageCode(String code) =>
      _prefs.setString(_keyLanguage, code);

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) =>
      _prefs.setString(_keyThemeMode, mode);

  bool get onboardingComplete =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;
  Future<void> setOnboardingComplete() =>
      _prefs.setBool(_keyOnboardingComplete, true);

  /// Analytics are opt-in and off until the user says otherwise (section 26).
  bool get analyticsConsent => _prefs.getBool(_keyAnalyticsConsent) ?? false;
  Future<void> setAnalyticsConsent(bool value) =>
      _prefs.setBool(_keyAnalyticsConsent, value);

  /// The master switch for notification monitoring.
  ///
  /// Off until the user turns it on inside the app, even if Android has
  /// already granted notification access: a system grant is permission to
  /// read, not an instruction to start.
  bool get notificationMonitoringEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? false;

  Future<void> setNotificationMonitoringEnabled(bool value) =>
      _prefs.setBool(_keyNotificationsEnabled, value);

  /// Whether a particular messaging app is monitored. Off by default, so
  /// enabling monitoring alone still reads nothing until an app is chosen.
  bool isAppMonitored(String packageName) =>
      _prefs.getBool(_keyMonitoredApp(packageName)) ?? false;

  Future<void> setAppMonitored(String packageName, bool value) =>
      _prefs.setBool(_keyMonitoredApp(packageName), value);

  /// Reads the local history, dropping anything past the retention window.
  List<Map<String, Object?>> recentAnalyses() {
    final raw = _prefs.getStringList(_keyRecentAnalyses) ?? const [];
    final cutoff = DateTime.now().subtract(recentAnalysisRetention);
    final entries = <Map<String, Object?>>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is! Map) continue;
        final entry = Map<String, Object?>.from(decoded);
        final timestamp = DateTime.tryParse(
          entry['analysed_at'] as String? ?? '',
        );
        if (timestamp == null || timestamp.isBefore(cutoff)) continue;
        entries.add(entry);
      } on FormatException {
        // A corrupt entry is dropped rather than crashing the dashboard.
        continue;
      }
    }
    return entries;
  }

  /// Stores metadata only — never the analysed text.
  Future<void> addAnalysis(RiskAssessment assessment) async {
    final entries = recentAnalyses()..insert(0, assessment.toMetadataJson());
    final trimmed = entries.take(maxRecentAnalyses).toList(growable: false);
    await _prefs.setStringList(
      _keyRecentAnalyses,
      trimmed.map(jsonEncode).toList(growable: false),
    );
  }

  Future<void> clearHistory() => _prefs.remove(_keyRecentAnalyses);
}
