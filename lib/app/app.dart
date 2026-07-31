import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class SaloneShieldApp extends ConsumerWidget {
  const SaloneShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageControllerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeControllerProvider),
      routerConfig: ref.watch(routerProvider),
      locale: language == null ? null : Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Krio has no Flutter-provided Material translations. Without this
        // fallback the framework throws when the user selects it.
        _KrioFrameworkFallback.material,
        _KrioFrameworkFallback.widgets,
        _KrioFrameworkFallback.cupertino,
      ],
    );
  }
}

/// Serves the English framework strings (button labels, date pickers, …) for
/// locales that Flutter itself does not ship translations for.
///
/// App content is fully translated; this only covers the framework's own
/// widgets, which is better than refusing to start in Krio.
class _KrioFrameworkFallback<T> extends LocalizationsDelegate<T> {
  const _KrioFrameworkFallback(this._delegate);

  static const material = _KrioFrameworkFallback<MaterialLocalizations>(
    GlobalMaterialLocalizations.delegate,
  );
  static const widgets = _KrioFrameworkFallback<WidgetsLocalizations>(
    GlobalWidgetsLocalizations.delegate,
  );
  static const cupertino = _KrioFrameworkFallback<CupertinoLocalizations>(
    GlobalCupertinoLocalizations.delegate,
  );

  final LocalizationsDelegate<T> _delegate;

  static const Locale _fallbackLocale = Locale('en');

  @override
  bool isSupported(Locale locale) => !_delegate.isSupported(locale);

  @override
  Future<T> load(Locale locale) => _delegate.load(_fallbackLocale);

  @override
  bool shouldReload(_KrioFrameworkFallback<T> old) => false;
}
