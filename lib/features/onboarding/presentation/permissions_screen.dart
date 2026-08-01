import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';

/// Permission explanation (section 7.4).
///
/// Each permission is explained separately, before it is ever requested. This
/// build requests none of them: the paste-and-analyse flow needs nothing but
/// the clipboard the user pastes from.
class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = <({IconData icon, String title, String body})>[
      (
        icon: Icons.wifi_outlined,
        title: l10n.permissionInternetTitle,
        body: l10n.permissionInternetBody,
      ),
      (
        icon: Icons.photo_outlined,
        title: l10n.permissionPhotosTitle,
        body: l10n.permissionPhotosBody,
      ),
      (
        icon: Icons.contacts_outlined,
        title: l10n.permissionContactsTitle,
        body: l10n.permissionContactsBody,
      ),
      (
        icon: Icons.notifications_none,
        title: l10n.permissionNotificationsTitle,
        body: l10n.permissionNotificationsBody,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.permissionsTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  DsSpace.screenGutter,
                  DsSpace.x2,
                  DsSpace.screenGutter,
                  DsSpace.x2,
                ),
                children: [
                  Text(
                    l10n.permissionsSubtitle,
                    style: AppType.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DsSpace.x5),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: DsSpace.x3),
                      child: DsCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DsIconChip(icon: item.icon),
                            const SizedBox(width: DsSpace.x3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppType.subtitle.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: DsSpace.x1),
                                  Text(
                                    item.body,
                                    style: AppType.bodySm.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: DsSpace.x2),
                  DsNotice(
                    icon: Icons.check_circle_outline,
                    text: l10n.permissionNoneRequestedNote,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DsSpace.x5),
              child: FilledButton(
                onPressed: () async {
                  await ref
                      .read(preferencesServiceProvider)
                      .setOnboardingComplete();
                  if (!context.mounted) return;
                  context.goNamed(AppRoute.home.name);
                },
                child: Text(l10n.actionContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
