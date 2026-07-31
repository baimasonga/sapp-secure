import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/preferences_service.dart';
import '../services/supabase/supabase_bootstrap.dart';
import 'app.dart';
import 'providers.dart';

/// Single startup path for every environment.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final preferences = await PreferencesService.create();

  // Backend access is optional; a failure here leaves the app in local-only
  // mode rather than blocking startup.
  await SupabaseBootstrap.initialise();

  runApp(
    ProviderScope(
      overrides: [preferencesServiceProvider.overrideWithValue(preferences)],
      child: const SaloneShieldApp(),
    ),
  );
}
