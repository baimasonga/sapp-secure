import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/coming_soon_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/risk_engine/models/risk_level.dart';
import '../../message_analysis/application/analysis_controller.dart';
import '../../message_analysis/presentation/widgets/risk_level_banner.dart';

/// Home dashboard (section 7.5).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recent = ref.watch(recentAnalysesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(AppRoute.settings.name),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const _SecurityStatusCard(),
            const SizedBox(height: 20),
            _ActionTile(
              icon: Icons.plagiarism_outlined,
              title: l10n.homeActionAnalyse,
              subtitle: l10n.homeActionAnalyseSubtitle,
              primary: true,
              onTap: () => context.pushNamed(AppRoute.analyse.name),
            ),
            _ActionTile(
              icon: Icons.image_search_outlined,
              title: l10n.homeActionScreenshot,
              subtitle: l10n.homeActionScreenshotSubtitle,
              onTap: () =>
                  showComingSoonSheet(context, l10n.homeActionScreenshot),
            ),
            _ActionTile(
              icon: Icons.link_outlined,
              title: l10n.homeActionLink,
              subtitle: l10n.homeActionLinkSubtitle,
              onTap: () => showComingSoonSheet(context, l10n.homeActionLink),
            ),
            _ActionTile(
              icon: Icons.contacts_outlined,
              title: l10n.trustedContactsTitle,
              subtitle: l10n.trustedContactsIntro,
              onTap: () => context.pushNamed(AppRoute.trustedContacts.name),
            ),
            _ActionTile(
              icon: Icons.flag_outlined,
              title: l10n.homeActionReport,
              subtitle: l10n.homeActionReportSubtitle,
              onTap: () => showComingSoonSheet(context, l10n.homeActionReport),
            ),
            _ActionTile(
              icon: Icons.checklist_outlined,
              title: l10n.homeActionChecklist,
              subtitle: l10n.homeActionChecklistSubtitle,
              onTap: () =>
                  showComingSoonSheet(context, l10n.homeActionChecklist),
            ),
            const SizedBox(height: 24),
            _RecentSection(entries: recent),
          ],
        ),
      ),
    );
  }
}

class _SecurityStatusCard extends StatelessWidget {
  const _SecurityStatusCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 32,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.homeSecurityStatusTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.homeSecurityStatusBody,
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.neverAskTitle,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: primary ? scheme.secondaryContainer : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        minVerticalPadding: 16,
        leading: Icon(icon, size: 32, color: scheme.primary),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
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
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeRecentTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (entries.isNotEmpty)
              TextButton(
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
          ],
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.homeRecentEmpty),
            ),
          )
        else
          for (final entry in entries) _RecentTile(entry: entry),
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
    final level = RiskLevel.fromId(entry['level'] as String? ?? 'caution');
    final palette = RiskPalette.of(context, level);
    final score = entry['score'] as int? ?? 0;
    final ruleCount = (entry['rule_ids'] as List?)?.length ?? 0;
    final timestamp = DateTime.tryParse(entry['analysed_at'] as String? ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(palette.icon, color: palette.accent),
        title: Text(
          '${level.shortLabel(l10n)} · ${l10n.resultScoreLabel(score)}',
        ),
        subtitle: Text(
          [
            l10n.resultSignalCount(ruleCount),
            if (timestamp != null) _formatDate(timestamp),
          ].join(' · '),
        ),
      ),
    );
  }

  /// Deliberately coarse: the exact minute a message was checked is not
  /// information this app needs to keep or display.
  static String _formatDate(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
