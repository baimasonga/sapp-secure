import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';

/// The delegate list used by the app and by widget tests.
///
/// English only for now. When Krio returns (see LOCALISATION.md) it will need
/// a fallback delegate as well, because Flutter ships no Material translations
/// for `kri` and the framework throws without one.
const List<LocalizationsDelegate<Object>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
