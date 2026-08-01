import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../identity_verification/application/verification_controller.dart';
import '../../message_analysis/application/analysis_controller.dart';
import '../../trusted_contacts/application/trusted_contacts_controller.dart';

/// Settings and privacy (section 7.15). The controls that exist here are the
/// ones that actually work in this build.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '0.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeControllerProvider);
    final preferences = ref.watch(preferencesServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DsSpace.screenGutter,
            DsSpace.x4,
            DsSpace.screenGutter,
            DsSpace.x8,
          ),
          children: [
            DsSectionLabel(l10n.settingsTheme),
            RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (mode) => _selectTheme(ref, mode),
              child: DsListGroup(
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
            const SizedBox(height: DsSpace.x6),
            DsSectionLabel(l10n.settingsPrivacyTitle),
            DsListGroup(
              children: [
                SwitchListTile(
                  value: preferences.analyticsConsent,
                  title: Text(l10n.settingsAnalytics),
                  subtitle: Text(l10n.settingsAnalyticsBody),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DsSpace.x4,
                    vertical: DsSpace.x1,
                  ),
                  onChanged: AppConfig.enableAnalytics
                      ? (value) async {
                          await preferences.setAnalyticsConsent(value);
                          ref.invalidate(preferencesServiceProvider);
                        }
                      : null,
                ),
                DsListRow(
                  leading: Icons.policy_outlined,
                  title: l10n.settingsPrivacyPolicy,
                  onTap: () => context.pushNamed(AppRoute.privacy.name),
                ),
              ],
            ),
            const SizedBox(height: DsSpace.x6),
            DsSectionLabel(l10n.settingsDataTitle),
            DsListGroup(
              children: [
                // Each of these deletes something the app is holding on this
                // phone. They are grouped so the user can see, in one place,
                // everything the app has of theirs.
                DsListRow(
                  leading: Icons.delete_outline,
                  title: l10n.settingsClearHistory,
                  subtitle: l10n.settingsClearHistoryBody,
                  onTap: () async {
                    await preferences.clearHistory();
                    ref.invalidate(recentAnalysesProvider);
                    if (!context.mounted) return;
                    _snack(context, l10n.settingsClearHistoryDone);
                  },
                ),
                DsListRow(
                  leading: Icons.person_remove_outlined,
                  title: l10n.settingsDeleteContacts,
                  subtitle: l10n.settingsDeleteContactsBody,
                  onTap: () async {
                    await ref.read(trustedContactRepositoryProvider).clear();
                    await ref
                        .read(trustedContactsControllerProvider.notifier)
                        .load();
                    if (!context.mounted) return;
                    _snack(context, l10n.settingsDeleteContactsDone);
                  },
                ),
                DsListRow(
                  leading: Icons.history_toggle_off,
                  title: l10n.settingsDeleteVerifications,
                  subtitle: l10n.settingsDeleteVerificationsBody,
                  onTap: () async {
                    await ref
                        .read(verificationHistoryRepositoryProvider)
                        .clear();
                    ref.invalidate(verificationHistoryProvider);
                    if (!context.mounted) return;
                    _snack(context, l10n.settingsDeleteVerificationsDone);
                  },
                ),
              ],
            ),
            const SizedBox(height: DsSpace.x6),
            DsCard(
              sunken: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsAbout,
                    style: AppType.bodySm.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: AppType.semibold,
                    ),
                  ),
                  const SizedBox(height: DsSpace.x1),
                  Text(
                    l10n.settingsVersion(appVersion),
                    style: AppType.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectTheme(WidgetRef ref, ThemeMode? mode) {
    if (mode == null) return;
    ref.read(themeModeControllerProvider.notifier).set(mode);
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
          padding: const EdgeInsets.fromLTRB(
            DsSpace.screenGutter,
            DsSpace.x5,
            DsSpace.screenGutter,
            DsSpace.x8,
          ),
          children: [
            Text(
              l10n.neverAskTitle,
              style: AppType.title.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: DsSpace.x4),
            Text(
              l10n.privacyBody,
              style: AppType.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
