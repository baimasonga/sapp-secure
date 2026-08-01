import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localization_delegates.dart';
import '../l10n/app_localizations.dart';
import '../services/sharing/shared_text_service.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class SaloneShieldApp extends ConsumerStatefulWidget {
  const SaloneShieldApp({super.key});

  @override
  ConsumerState<SaloneShieldApp> createState() => _SaloneShieldAppState();
}

class _SaloneShieldAppState extends ConsumerState<SaloneShieldApp> {
  /// Held directly rather than read from `ref` in dispose, which is not
  /// allowed once the widget is gone.
  SharedTextService? _sharedTextService;

  @override
  void initState() {
    super.initState();
    // A share can arrive before the first frame, so the initial value is read
    // once the router exists, and later shares arrive through the listener.
    WidgetsBinding.instance.addPostFrameCallback((_) => _wireSharedText());
  }

  Future<void> _wireSharedText() async {
    if (!mounted) return;
    final service = ref.read(sharedTextServiceProvider);
    _sharedTextService = service;
    service.listen(_openAnalyser);
    final initial = await service.initialSharedText();
    if (initial != null) _openAnalyser(initial);
  }

  /// Opens the analyser with the shared message already filled in. The text is
  /// passed in memory only; it is never written to storage.
  void _openAnalyser(String text) {
    if (!mounted) return;
    ref.read(routerProvider).pushNamed(AppRoute.analyse.name, extra: text);
  }

  @override
  void dispose() {
    _sharedTextService?.dispose();
    _sharedTextService = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeControllerProvider),
      routerConfig: ref.watch(routerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
    );
  }
}
