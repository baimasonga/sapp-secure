import 'package:flutter/material.dart';

import '../../app/design/app_typography.dart';
import '../../app/design/design_tokens.dart';
import '../../l10n/app_localizations.dart';
import 'ds_components.dart';

/// Shown for features that are specified but not yet built.
///
/// A security app must not pretend to do something it cannot do, and it must
/// not hide the roadmap either. This sheet names the feature and says plainly
/// that it is not working yet.
Future<void> showComingSoonSheet(BuildContext context, String featureName) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Scrollable and bottom-inset aware: on a short screen this sheet still
    // has to be able to show its own dismiss button.
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DsSpace.x6,
          0,
          DsSpace.x6,
          DsSpace.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const DsIconChip(icon: Icons.construction_outlined),
                const SizedBox(width: DsSpace.x3),
                Expanded(
                  child: Text(
                    featureName,
                    style: AppType.title.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpace.x5),
            Text(
              l10n.comingSoonTitle,
              style: AppType.subtitle.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: DsSpace.x2),
            Text(
              l10n.comingSoonBody,
              style: AppType.bodySm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DsSpace.x6),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionClose),
            ),
          ],
        ),
      ),
    ),
  );
}
