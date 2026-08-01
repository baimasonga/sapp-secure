import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/preferences_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../services/risk_engine/engine_strings.dart';
import '../services/risk_engine/risk_engine.dart';
import '../services/contacts/contact_picker_service.dart';
import '../services/risk_engine/rule_repository.dart';
import '../services/sharing/shared_text_service.dart';

/// Overridden in `bootstrap.dart` once shared preferences have loaded, and in
/// tests with an in-memory instance.
final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) =>
      throw UnimplementedError('preferencesServiceProvider not overridden'),
);

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService.create(),
);

/// Opens the system contact picker. Overridden in tests.
final contactPickerServiceProvider = Provider<ContactPickerService>(
  (ref) => const ContactPickerService(),
);

/// Receives messages shared into the app from WhatsApp. Overridden in tests.
final sharedTextServiceProvider = Provider<SharedTextService>(
  (ref) => const SharedTextService(),
);

final ruleRepositoryProvider = Provider<RuleRepository>(
  (ref) => const RuleRepository(),
);

/// The engine is built once from the bundled rules and reused for every
/// analysis. A failure here surfaces as an error state, never as a "safe"
/// result.
final riskEngineProvider = FutureProvider<RiskEngine>(
  (ref) => ref.watch(ruleRepositoryProvider).loadEngine(),
);

/// The language the engine explains results in. Fixed while the app ships in
/// English only; becomes a user setting again when Krio returns
/// (see LOCALISATION.md).
final engineLanguageProvider = Provider<String>(
  (ref) => EngineStrings.defaultLanguage,
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._preferences)
    : super(_parse(_preferences.themeMode));

  final PreferencesService _preferences;

  static ThemeMode _parse(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> set(ThemeMode mode) async {
    await _preferences.setThemeMode(mode.name);
    state = mode;
  }
}

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
      (ref) => ThemeModeController(ref.watch(preferencesServiceProvider)),
    );
