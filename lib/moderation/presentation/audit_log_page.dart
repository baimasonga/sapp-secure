import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design/app_typography.dart';
import '../../app/design/design_tokens.dart';
import '../../core/widgets/ds_components.dart';
import '../application/moderation_controllers.dart';
import '../domain/moderation_models.dart';
import 'moderation_strings.dart';

/// The record of every decision.
///
/// Read-only, because the table is: there is no update or delete policy on
/// `moderation_actions` for anyone, administrators included. This page has no
/// edit affordance not because it was left out but because there is nothing
/// for it to call.
class AuditLogPage extends ConsumerWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(auditLogProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpace.x6,
            DsSpace.x6,
            DsSpace.x6,
            DsSpace.x2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Mod.auditTitle,
                style: AppType.headline.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: DsSpace.x1),
              Text(
                Mod.auditBody,
                style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(DsSpace.x6),
              child: DsNotice(
                icon: Icons.cloud_off_outlined,
                tone: DsNoticeTone.danger,
                text: Mod.queueLoadFailed,
              ),
            ),
            data: (log) => log.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(DsSpace.x6),
                    child: DsNotice(icon: Icons.history, text: Mod.auditEmpty),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpace.x6,
                      DsSpace.x2,
                      DsSpace.x6,
                      DsSpace.x8,
                    ),
                    itemCount: log.length,
                    itemBuilder: (context, index) =>
                        _EntryRow(entry: log[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final ModerationEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.x2_5),
      child: DsCard(
        padding: const EdgeInsets.all(DsSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.action.replaceAll('_', ' '),
                    style: AppType.bodySm.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppType.semibold,
                    ),
                  ),
                ),
                Text(
                  entry.createdAt.toUtc().toIso8601String(),
                  style: AppType.caption.copyWith(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpace.x1),
            Text(
              '${entry.previousStatus ?? '—'} → ${entry.newStatus ?? '—'}',
              style: AppType.mono.copyWith(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (entry.notes != null) ...[
              const SizedBox(height: DsSpace.x2),
              Text(
                entry.notes!,
                style: AppType.bodySm.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
