import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';

/// The delegate list used by the app and by widget tests.
///
/// Kept in one place because getting it wrong only shows up when a user
/// switches to Krio, which is exactly the path that must not break.
const List<LocalizationsDelegate<Object>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  FrameworkLocalizationsFallback.material,
  FrameworkLocalizationsFallback.widgets,
  FrameworkLocalizationsFallback.cupertino,
];

/// Serves the English framework strings (button labels, date pickers, …) for
/// locales Flutter itself does not ship translations for.
///
/// Krio is one of those locales. App content is fully translated; this only
/// covers the framework's own widgets, which is better than refusing to run
/// in Krio at all.
class FrameworkLocalizationsFallback<T> extends LocalizationsDelegate<T> {
  const FrameworkLocalizationsFallback(this._delegate);

  static const material = FrameworkLocalizationsFallback<MaterialLocalizations>(
    GlobalMaterialLocalizations.delegate,
  );
  static const widgets = FrameworkLocalizationsFallback<WidgetsLocalizations>(
    GlobalWidgetsLocalizations.delegate,
  );
  static const cupertino =
      FrameworkLocalizationsFallback<CupertinoLocalizations>(
        GlobalCupertinoLocalizations.delegate,
      );

  final LocalizationsDelegate<T> _delegate;

  static const Locale _fallbackLocale = Locale('en');

  /// Only steps in where the real delegate cannot help.
  @override
  bool isSupported(Locale locale) => !_delegate.isSupported(locale);

  @override
  Future<T> load(Locale locale) => _delegate.load(_fallbackLocale);

  @override
  bool shouldReload(FrameworkLocalizationsFallback<T> old) => false;
}
