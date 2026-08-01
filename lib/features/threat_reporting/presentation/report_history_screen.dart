import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';
import '../application/report_controller.dart';
import '../domain/threat_report.dart';
import 'report_scam_screen.dart';

/// Threat report history (specification section 7.14).
class ReportHistoryScreen extends ConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(myReportsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportHistoryTitle)),
      body: SafeArea(
        child: reports.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Padding(
            padding: const EdgeInsets.all(DsSpace.x6),
            child: DsNotice(
              text: l10n.reportFailedNetwork,
              icon: Icons.wifi_off,
              tone: DsNoticeTone.danger,
            ),
          ),
          data: (list) => list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(DsSpace.x6),
                  child: DsNotice(
                    text: l10n.reportHistoryEmpty,
                    icon: Icons.inbox_outlined,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    DsSpace.screenGutter,
                    DsSpace.x4,
                    DsSpace.screenGutter,
                    DsSpace.x8,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) =>
                      _ReportTile(report: list[index]),
                ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final SubmittedReport report;

  static IconData _iconFor(ReportStatus status) => switch (status) {
    ReportStatus.pending => Icons.schedule,
    ReportStatus.underReview => Icons.visibility_outlined,
    ReportStatus.needsMoreEvidence => Icons.help_outline,
    ReportStatus.verified => Icons.verified_outlined,
    ReportStatus.rejected => Icons.cancel_outlined,
    ReportStatus.duplicate => Icons.copy_all_outlined,
    ReportStatus.archived => Icons.inventory_2_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = report.createdAt.toLocal();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.x3),
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconFor(report.status),
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: DsSpace.x2_5),
                Expanded(
                  child: Text(
                    report.threatType.label(l10n),
                    style: AppType.bodySm.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppType.semibold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpace.x2_5,
                    vertical: DsSpace.x1,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: DsRadius.all(DsRadius.pill),
                  ),
                  child: Text(
                    report.status.label(l10n),
                    style: AppType.caption.copyWith(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                      fontWeight: AppType.semibold,
                    ),
                  ),
                ),
              ],
            ),
            if (report.maskedNumber != null) ...[
              const SizedBox(height: DsSpace.x2),
              // Masked, never the whole number, even back to the person who
              // reported it.
              Text(
                report.maskedNumber!,
                style: AppType.mono.copyWith(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (report.moderatorNote != null) ...[
              const SizedBox(height: DsSpace.x2),
              Text(
                report.moderatorNote!,
                style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: DsSpace.x2),
            Text(
              // The status is in the pill above; this line is only the date.
              '${date.year}-${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}',
              style: AppType.caption.copyWith(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
