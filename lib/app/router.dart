import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/home_screen.dart';
import '../features/message_analysis/presentation/analyse_message_screen.dart';
import '../features/message_analysis/presentation/risk_result_screen.dart';
import '../features/onboarding/presentation/language_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/permissions_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'providers.dart';

/// Named routes, so navigation cannot be broken by a typo in a path string.
enum AppRoute {
  splash('/'),
  language('/language'),
  onboarding('/onboarding'),
  permissions('/permissions'),
  home('/home'),
  analyse('/analyse'),
  analysisResult('/analysis-result'),
  settings('/settings'),
  privacy('/privacy');

  const AppRoute(this.path);

  final String path;
}

final routerProvider = Provider<GoRouter>((ref) {
  final preferences = ref.watch(preferencesServiceProvider);

  return GoRouter(
    initialLocation: AppRoute.splash.path,
    routes: [
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        redirect: (context, state) {
          // First launch goes through language selection; afterwards straight
          // to the dashboard.
          if (preferences.onboardingComplete) return AppRoute.home.path;
          if (preferences.languageCode == null) return AppRoute.language.path;
          return AppRoute.onboarding.path;
        },
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoute.language.path,
        name: AppRoute.language.name,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.name,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoute.permissions.path,
        name: AppRoute.permissions.name,
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.analyse.path,
        name: AppRoute.analyse.name,
        builder: (context, state) => AnalyseMessageScreen(
          // Populated when the user shares a message into the app.
          initialText: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoute.analysisResult.path,
        name: AppRoute.analysisResult.name,
        builder: (context, state) => const RiskResultScreen(),
      ),
      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.name,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoute.privacy.path,
        name: AppRoute.privacy.name,
        builder: (context, state) => const PrivacyScreen(),
      ),
    ],
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
  );
});

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 48),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.goNamed(AppRoute.home.name),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
