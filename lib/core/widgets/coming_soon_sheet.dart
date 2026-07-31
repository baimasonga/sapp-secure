import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

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
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.construction_outlined, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  featureName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.comingSoonTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(l10n.comingSoonBody),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionClose),
          ),
        ],
      ),
    ),
  );
}
