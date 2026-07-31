import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                children: [
                  Text(
                    l10n.permissionsSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  for (final item in items)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.icon,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.body),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.permissionNoneRequestedNote,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
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
