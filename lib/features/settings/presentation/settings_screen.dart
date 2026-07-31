import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../message_analysis/application/analysis_controller.dart';

/// Settings and privacy (section 7.15). The controls that exist here are the
/// ones that actually work in this build.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '0.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageControllerProvider) ?? 'en';
    final themeMode = ref.watch(themeModeControllerProvider);
    final preferences = ref.watch(preferencesServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            _SectionLabel(text: l10n.settingsLanguage),
            RadioGroup<String>(
              groupValue: language,
              onChanged: (value) => _selectLanguage(ref, value),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'en',
                    title: Text(l10n.languageEnglish),
                  ),
                  RadioListTile<String>(
                    value: 'kri',
                    title: Text(l10n.languageKrio),
                  ),
                ],
              ),
            ),
            const Divider(),
            _SectionLabel(text: l10n.settingsTheme),
            RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (mode) => _selectTheme(ref, mode),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    title: Text(l10n.settingsThemeSystem),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    title: Text(l10n.settingsThemeLight),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    title: Text(l10n.settingsThemeDark),
                  ),
                ],
              ),
            ),
            const Divider(),
            _SectionLabel(text: l10n.settingsPrivacyTitle),
            SwitchListTile(
              value: preferences.analyticsConsent,
              title: Text(l10n.settingsAnalytics),
              subtitle: Text(l10n.settingsAnalyticsBody),
              onChanged: AppConfig.enableAnalytics
                  ? (value) async {
                      await preferences.setAnalyticsConsent(value);
                      ref.invalidate(preferencesServiceProvider);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.settingsClearHistory),
              subtitle: Text(l10n.settingsClearHistoryBody),
              onTap: () async {
                await preferences.clearHistory();
                ref.invalidate(recentAnalysesProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(l10n.settingsClearHistoryDone)),
                  );
              },
            ),
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: Text(l10n.settingsPrivacyPolicy),
              onTap: () => context.pushNamed(AppRoute.privacy.name),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAbout),
              subtitle: Text(l10n.settingsVersion(appVersion)),
            ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(WidgetRef ref, String? value) {
    if (value == null) return;
    ref.read(languageControllerProvider.notifier).select(value);
  }

  void _selectTheme(WidgetRef ref, ThemeMode? mode) {
    if (mode == null) return;
    ref.read(themeModeControllerProvider.notifier).set(mode);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Plain-language privacy summary (section 7.15). The full policy lives in
/// `PRIVACY.md`; this is what the user reads in the app.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.neverAskTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacyBody,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
