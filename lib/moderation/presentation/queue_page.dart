import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design/app_typography.dart';
import '../../app/design/design_tokens.dart';
import '../../core/widgets/ds_components.dart';
import '../../features/threat_reporting/domain/threat_report.dart';
import '../application/moderation_controllers.dart';
import '../domain/moderation_models.dart';
import 'moderation_strings.dart';
import 'report_detail_page.dart';

/// The work list.
///
/// Oldest first, always. A newest-first queue quietly buries the reports
/// nobody has got to, which are exactly the ones that need attention.
class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider);
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
                Mod.queueTitle,
                style: AppType.headline.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: DsSpace.x1),
              Text(
                Mod.queueOldestFirst,
                style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const _Filters(),
        Expanded(
          child: queue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(DsSpace.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DsNotice(
                    icon: Icons.cloud_off_outlined,
                    tone: DsNoticeTone.danger,
                    text: Mod.queueLoadFailed,
                  ),
                  const SizedBox(height: DsSpace.x4),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(queueProvider),
                    child: const Text(Mod.retry),
                  ),
                ],
              ),
            ),
            data: (reports) => reports.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(DsSpace.x6),
                    child: DsNotice(
                      icon: Icons.inbox_outlined,
                      text: Mod.queueEmpty,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpace.x6,
                      DsSpace.x2,
                      DsSpace.x6,
                      DsSpace.x8,
                    ),
                    itemCount: reports.length,
                    itemBuilder: (context, index) =>
                        _QueueRow(report: reports[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  static const _options = <String, Set<ReportStatus>>{
    Mod.filterAll: {
      ReportStatus.pending,
      ReportStatus.underReview,
      ReportStatus.needsMoreEvidence,
    },
    Mod.filterPending: {ReportStatus.pending},
    Mod.filterUnderReview: {ReportStatus.underReview},
    Mod.filterNeedsEvidence: {ReportStatus.needsMoreEvidence},
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(queueFilterProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DsSpace.x6),
      child: Wrap(
        spacing: DsSpace.x2,
        children: [
          for (final entry in _options.entries)
            ChoiceChip(
              label: Text(entry.key),
              selected: _sameSet(selected, entry.value),
              onSelected: (_) =>
                  ref.read(queueFilterProvider.notifier).state = entry.value,
            ),
        ],
      ),
    );
  }

  static bool _sameSet(Set<ReportStatus> a, Set<ReportStatus> b) =>
      a.length == b.length && a.containsAll(b);
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.report});

  final QueuedReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final indicator = report.indicator;
    final waited = DateTime.now().difference(report.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.x3),
      child: DsCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReportDetailPage(reportId: report.id),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsIconChip(
              icon: Icons.flag_outlined,
              background: scheme.surfaceContainerHighest,
              foreground: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: DsSpace.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.threatType.id.replaceAll('_', ' '),
                          style: AppType.subtitle.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      _StatusPill(status: report.status),
                    ],
                  ),
                  const SizedBox(height: DsSpace.x2),
                  Text(
                    indicator?.maskedValue ??
                        report.reportedLink ??
                        Mod.indicatorNone,
                    style: AppType.mono.copyWith(
                      fontSize: 13.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DsSpace.x2),
                  Wrap(
                    spacing: DsSpace.x4,
                    runSpacing: DsSpace.x1,
                    children: [
                      _Fact(label: Mod.submitted, value: _describeWait(waited)),
                      if (indicator != null) ...[
                        _Fact(
                          label: Mod.indicatorReporters,
                          value: '${indicator.distinctReporterCount}',
                        ),
                        _Fact(
                          label: Mod.indicatorReports,
                          value: '${indicator.reportCount}',
                        ),
                      ],
                      if (report.reporterGone)
                        _Fact(label: Mod.reporter, value: 'deleted'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Coarse on purpose: what matters is "days", not "3 days 4 hours".
  static String _describeWait(Duration waited) {
    if (waited.inDays >= 1) return '${waited.inDays}d ago';
    if (waited.inHours >= 1) return '${waited.inHours}h ago';
    return '${waited.inMinutes}m ago';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
          ),
          TextSpan(
            text: value,
            style: AppType.caption.copyWith(
              color: scheme.onSurface,
              fontWeight: AppType.semibold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpace.x2_5,
        vertical: DsSpace.x1,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: DsRadius.all(DsRadius.pill),
      ),
      child: Text(
        status.id.replaceAll('_', ' '),
        style: AppType.caption.copyWith(
          fontSize: 11,
          color: scheme.onSurfaceVariant,
          fontWeight: AppType.semibold,
        ),
      ),
    );
  }
}
