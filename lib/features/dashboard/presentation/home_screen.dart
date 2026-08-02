import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/coming_soon_sheet.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/risk_engine/models/risk_level.dart';
import '../../message_analysis/application/analysis_controller.dart';
import '../../message_analysis/presentation/widgets/risk_level_banner.dart';
import '../../notification_monitoring/application/notification_monitor_controller.dart';
import '../../trusted_contacts/application/trusted_contacts_controller.dart';

/// Home dashboard (specification section 7.5).
///
/// Follows the Gradient layout: brand header, one gradient hero, a single
/// primary action, a quiet grid of secondary actions, then recent activity.
/// The hero is the app's one gradient moment — nothing else on this screen
/// uses one.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recent = ref.watch(recentAnalysesProvider);
    final contacts =
        ref.watch(trustedContactsControllerProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: DsSpace.x8),
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DsSpace.screenGutter,
                DsSpace.x3,
                DsSpace.screenGutter,
                0,
              ),
              child: _HeroCard(
                checkCount: recent.length,
                contactCount: contacts.length,
              ),
            ),
            const _WaitingMessagesBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DsSpace.screenGutter,
                DsSpace.x4,
                DsSpace.screenGutter,
                0,
              ),
              child: FilledButton.icon(
                onPressed: () => context.pushNamed(AppRoute.analyse.name),
                icon: const Icon(Icons.search, size: 20),
                label: Text(l10n.homeActionAnalyse),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DsSpace.screenGutter,
                DsSpace.x3,
                DsSpace.screenGutter,
                0,
              ),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: DsSpace.x3,
                crossAxisSpacing: DsSpace.x3,
                childAspectRatio: 1.42,
                children: [
                  DsActionTile(
                    icon: Icons.image_search_outlined,
                    title: l10n.homeActionScreenshot,
                    subtitle: l10n.homeActionScreenshotSubtitle,
                    onTap: () => context.pushNamed(AppRoute.screenshot.name),
                  ),
                  DsActionTile(
                    icon: Icons.link,
                    title: l10n.homeActionLink,
                    subtitle: l10n.homeActionLinkSubtitle,
                    onTap: () => context.pushNamed(AppRoute.linkCheck.name),
                  ),
                  DsActionTile(
                    icon: Icons.flag_outlined,
                    title: l10n.homeActionReport,
                    subtitle: l10n.homeActionReportSubtitle,
                    onTap: () => context.pushNamed(AppRoute.report.name),
                  ),
                  DsActionTile(
                    icon: Icons.checklist_outlined,
                    title: l10n.homeActionChecklist,
                    subtitle: l10n.homeActionChecklistSubtitle,
                    onTap: () =>
                        showComingSoonSheet(context, l10n.homeActionChecklist),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DsSpace.screenGutter,
                DsSpace.x7,
                DsSpace.screenGutter,
                0,
              ),
              child: _RecentSection(entries: recent),
            ),
          ],
        ),
      ),
    );
  }
}

/// Messages the notification listener queued while the app was closed.
///
/// Shown on the dashboard rather than only in settings: a warning the user has
/// to go looking for is not a warning. Nothing is rendered at all when the
/// build has monitoring switched off, so the provider is not even read.
class _WaitingMessagesBanner extends ConsumerWidget {
  const _WaitingMessagesBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(notificationMonitoringAvailableProvider)) {
      return const SizedBox.shrink();
    }

    final waiting = ref.watch(notificationMonitorControllerProvider).pending;
    if (waiting.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final urgent = waiting.any((message) => message.interrupt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpace.screenGutter,
        DsSpace.x4,
        DsSpace.screenGutter,
        0,
      ),
      child: DsCard(
        onTap: () => context.pushNamed(AppRoute.notifications.name),
        background: urgent ? scheme.errorContainer : scheme.primaryContainer,
        borderColor: Colors.transparent,
        child: Row(
          children: [
            Icon(
              urgent
                  ? Icons.warning_amber_rounded
                  : Icons.mark_email_unread_outlined,
              size: 20,
              color: urgent
                  ? scheme.onErrorContainer
                  : scheme.onPrimaryContainer,
            ),
            const SizedBox(width: DsSpace.x3),
            Expanded(
              child: Text(
                l10n.notificationsWaitingBanner(waiting.length),
                style: AppType.bodySm.copyWith(
                  color: urgent
                      ? scheme.onErrorContainer
                      : scheme.onPrimaryContainer,
                  fontWeight: AppType.semibold,
                ),
              ),
            ),
            Text(
              l10n.notificationsWaitingAction,
              style: AppType.caption.copyWith(
                color: urgent
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
                fontWeight: AppType.semibold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpace.screenGutter,
        DsSpace.x3,
        DsSpace.x2,
        0,
      ),
      child: Row(
        children: [
          const DsBrandMark(),
          const SizedBox(width: DsSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appName,
                  style: AppType.subtitle.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppType.bold,
                  ),
                ),
                Text(
                  l10n.appTagline,
                  style: AppType.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            // Both a tooltip and a semantic label: a tooltip is a hover
            // affordance and there is no hover on a phone, so on its own it
            // leaves a screen reader announcing only "button".
            tooltip: l10n.settingsTitle,
            icon: Icon(
              Icons.settings_outlined,
              semanticLabel: l10n.settingsTitle,
            ),
            onPressed: () => context.goNamed(AppRoute.settings.name),
          ),
        ],
      ),
    );
  }
}

/// The hero. Deliberately does not claim to be watching anything: the app
/// checks what you bring it, and saying otherwise would teach false comfort.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.checkCount, required this.contactCount});

  final int checkCount;
  final int contactCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: DsGradient.dusk,
        borderRadius: DsRadius.all(DsRadius.xl),
        boxShadow: DsShadow.lg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // The mesh wash sits over the dusk sweep and reads as light.
          for (final gradient in DsGradient.mesh)
            Positioned.fill(
              child: Opacity(
                opacity: 0.55,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: gradient),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(DsSpace.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 15,
                      color: DsColor.onGradientMuted,
                    ),
                    const SizedBox(width: DsSpace.x1_5),
                    Text(
                      l10n.homeHeroEyebrow.toUpperCase(),
                      style: AppType.overline.copyWith(
                        color: DsColor.onGradientMuted,
                        fontFamily: AppType.family,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpace.x3),
                Text(
                  l10n.homeHeroTitle,
                  style: AppType.headline.copyWith(color: DsColor.onGradient),
                ),
                const SizedBox(height: DsSpace.x1_5),
                Text(
                  l10n.homeHeroBody,
                  style: AppType.bodySm.copyWith(
                    color: DsColor.onGradientMuted,
                  ),
                ),
                const SizedBox(height: DsSpace.x5),
                // Each stat takes half the width rather than its natural
                // size: at 200% text the two labels together are wider than
                // the phone, and the half that overflowed was the wording.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _HeroStat(
                        value: '$checkCount',
                        label: l10n.homeStatChecks(checkCount),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      margin: const EdgeInsets.symmetric(
                        horizontal: DsSpace.x4,
                      ),
                      color: const Color(0x29FFFFFF),
                    ),
                    Expanded(
                      child: _HeroStat(
                        value: '$contactCount',
                        label: l10n.homeStatContacts(contactCount),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppType.title.copyWith(
            color: DsColor.onGradient,
            fontWeight: AppType.bold,
          ),
        ),
        Text(
          label,
          style: AppType.caption.copyWith(color: DsColor.onGradientMuted),
        ),
      ],
    );
  }
}

class _RecentSection extends ConsumerWidget {
  const _RecentSection({required this.entries});

  final List<Map<String, Object?>> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsSectionLabel(
          l10n.homeSectionRecent,
          trailing: entries.isEmpty
              ? null
              : TextButton(
                  onPressed: () async {
                    await ref.read(preferencesServiceProvider).clearHistory();
                    ref.invalidate(recentAnalysesProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.homeRecentCleared)),
                      );
                  },
                  child: Text(l10n.homeClearRecent),
                ),
        ),
        if (entries.isEmpty)
          DsCard(
            sunken: true,
            child: Text(
              l10n.homeRecentEmpty,
              style: AppType.bodySm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: DsSpace.x2_5),
              child: _RecentTile(entry: entry),
            ),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.entry});

  final Map<String, Object?> entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final level = RiskLevel.fromId(entry['level'] as String? ?? 'caution');
    final palette = RiskPalette.of(context, level);
    final score = entry['score'] as int? ?? 0;
    final ruleCount = (entry['rule_ids'] as List?)?.length ?? 0;
    final timestamp = DateTime.tryParse(entry['analysed_at'] as String? ?? '');

    return DsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpace.x3,
        vertical: DsSpace.x3,
      ),
      child: Row(
        children: [
          DsIconChip(
            icon: palette.icon,
            size: 38,
            background: palette.container,
            foreground: palette.onContainer,
          ),
          const SizedBox(width: DsSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${level.shortLabel(l10n)} · ${l10n.resultScoreLabel(score)}',
                  style: AppType.bodySm.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppType.semibold,
                  ),
                ),
                const SizedBox(height: DsSpace.x0_5),
                Text(
                  [
                    l10n.resultSignalCount(ruleCount),
                    if (timestamp != null) _formatDate(timestamp),
                  ].join(' · '),
                  style: AppType.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Deliberately coarse: the exact minute a message was checked is not
  /// information this app needs to keep or show.
  static String _formatDate(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
