import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/router.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/notifications/notification_access_service.dart';
import '../../message_analysis/application/analysis_controller.dart';
import '../application/notification_monitor_controller.dart';
import '../domain/monitored_app.dart';

/// Notification monitoring (specification section 14).
///
/// The screen explains what the feature reads, where the text goes and what
/// the user will see, all of it before offering the switch — because the
/// honest version of "may I read your notifications?" is a paragraph, not a
/// toggle. Android's own grant is a separate step the app cannot take for the
/// user, and the screen says so rather than implying otherwise.
class NotificationMonitoringScreen extends ConsumerStatefulWidget {
  const NotificationMonitoringScreen({super.key});

  @override
  ConsumerState<NotificationMonitoringScreen> createState() =>
      _NotificationMonitoringScreenState();
}

class _NotificationMonitoringScreenState
    extends ConsumerState<NotificationMonitoringScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The grant is made in Android's settings, so the only way to know it
    // happened is to look again when the user comes back.
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationMonitorControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final available = ref.watch(notificationMonitoringAvailableProvider);

    if (!available) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notificationsTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DsSpace.screenGutter,
              DsSpace.x4,
              DsSpace.screenGutter,
              DsSpace.x8,
            ),
            children: [
              DsNotice(
                icon: Icons.notifications_off_outlined,
                title: l10n.notificationsUnavailableTitle,
                text: l10n.notificationsUnavailableBody,
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(notificationMonitorControllerProvider);
    final controller = ref.read(notificationMonitorControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DsSpace.screenGutter,
            DsSpace.x4,
            DsSpace.screenGutter,
            DsSpace.x8,
          ),
          children: [
            Text(
              l10n.notificationsIntro,
              style: AppType.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DsSpace.x5),
            _Explainer(
              title: l10n.notificationsWhatItReads,
              body: l10n.notificationsWhatItReadsBody,
              icon: Icons.visibility_outlined,
            ),
            _Explainer(
              title: l10n.notificationsWhereItGoes,
              body: l10n.notificationsWhereItGoesBody,
              icon: Icons.lock_outline,
            ),
            _Explainer(
              title: l10n.notificationsWhatYouSee,
              body: l10n.notificationsWhatYouSeeBody,
              icon: Icons.campaign_outlined,
            ),
            const SizedBox(height: DsSpace.x2),
            DsNotice(
              icon: Icons.shield_outlined,
              text: l10n.notificationsNotAccessibility,
            ),
            const SizedBox(height: DsSpace.x6),
            DsSectionLabel(l10n.notificationsAccessTitle),
            _AccessCard(granted: state.accessGranted, controller: controller),
            const SizedBox(height: DsSpace.x6),
            DsSectionLabel(l10n.notificationsSwitchTitle),
            DsListGroup(
              children: [
                SwitchListTile(
                  value: state.enabled,
                  title: Text(l10n.notificationsSwitchTitle),
                  subtitle: Text(l10n.notificationsSwitchBody),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DsSpace.x4,
                    vertical: DsSpace.x1,
                  ),
                  onChanged: controller.setEnabled,
                ),
              ],
            ),
            const SizedBox(height: DsSpace.x6),
            DsSectionLabel(l10n.notificationsAppsTitle),
            Padding(
              padding: const EdgeInsets.only(bottom: DsSpace.x2_5),
              child: Text(
                l10n.notificationsAppsBody,
                style: AppType.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            DsListGroup(
              children: [
                for (final app in MonitoredApp.values)
                  SwitchListTile(
                    value: state.monitoredApps.contains(app.packageName),
                    title: Text(app.displayName),
                    subtitle: Text(app.packageName, style: AppType.mono),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DsSpace.x4,
                      vertical: DsSpace.x1,
                    ),
                    onChanged: state.enabled
                        ? (value) => controller.setAppMonitored(app, value)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: DsSpace.x6),
            _PendingSection(state: state, controller: controller),
          ],
        ),
      ),
    );
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.x3),
      child: DsCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsIconChip(icon: icon),
            const SizedBox(width: DsSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.subtitle.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: DsSpace.x1),
                  Text(
                    body,
                    style: AppType.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
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
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.granted, required this.controller});

  final bool granted;
  final NotificationMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                granted ? Icons.check_circle_outline : Icons.info_outline,
                size: 20,
                color: granted ? DsColor.green500 : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: DsSpace.x2_5),
              Expanded(
                child: Text(
                  granted
                      ? l10n.notificationsAccessGranted
                      : l10n.notificationsAccessMissing,
                  style: AppType.bodySm.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppType.semibold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpace.x2),
          Text(
            l10n.notificationsAccessRevokeNote,
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: DsSpace.x4),
          OutlinedButton.icon(
            onPressed: () async {
              final opened = await controller.openAccessSettings();
              if (opened || !context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l10n.notificationsAccessUnavailable)),
                );
            },
            icon: const Icon(Icons.open_in_new, size: 20),
            label: Text(l10n.notificationsAccessAction),
          ),
        ],
      ),
    );
  }
}

class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.state, required this.controller});

  final NotificationMonitorState state;
  final NotificationMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsSectionLabel(
          l10n.notificationsPendingTitle,
          trailing: state.pending.isEmpty
              ? null
              : TextButton(
                  onPressed: () async {
                    await controller.clearPending();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.notificationsForgotten)),
                      );
                  },
                  child: Text(l10n.notificationsForgetAll),
                ),
        ),
        if (state.pending.isEmpty)
          DsCard(
            sunken: true,
            child: Text(
              l10n.notificationsPendingEmpty,
              style: AppType.bodySm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final message in state.pending)
            _PendingTile(message: message, controller: controller),
      ],
    );
  }
}

class _PendingTile extends ConsumerWidget {
  const _PendingTile({required this.message, required this.controller});

  final MonitoredMessage message;
  final NotificationMonitorController controller;

  /// Runs the message through the same engine the paste flow uses and goes
  /// straight to the explanation. The user already asked for this by tapping;
  /// making them press Analyse on a pre-filled field would be a tap that
  /// exists only because of how the code is arranged.
  Future<void> _check(BuildContext context, WidgetRef ref) async {
    controller.dismiss(message.id);
    await ref.read(analysisControllerProvider.notifier).analyse(message.text);
    if (!context.mounted) return;
    if (ref.read(analysisControllerProvider) is AnalysisSuccess) {
      context.pushNamed(AppRoute.analysisResult.name);
    } else {
      // The engine could not load, or the text was rejected. The analyser
      // screen states the reason rather than this tile guessing at it.
      context.pushNamed(AppRoute.analyse.name, extra: message.text);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.x3),
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // The full text is shown here and nowhere else: this is the one
              // screen the user opened deliberately to look at it.
              message.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppType.bodySm.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: DsSpace.x3),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _check(context, ref),
                    child: Text(l10n.notificationsCheckNow),
                  ),
                ),
                const SizedBox(width: DsSpace.x3),
                TextButton(
                  onPressed: () => controller.dismiss(message.id),
                  child: Text(l10n.notificationsDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
