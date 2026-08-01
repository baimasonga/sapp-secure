import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.reportFailedNetwork,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (list) => list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.reportHistoryEmpty,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(report.status)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.threatType.label(l10n),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${l10n.reportHistoryStatus}: ${report.status.label(l10n)}'),
            const SizedBox(height: 4),
            Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (report.maskedNumber != null) ...[
              const SizedBox(height: 4),
              // Masked, never the whole number, even back to the person who
              // reported it.
              Text(
                report.maskedNumber!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (report.moderatorNote != null) ...[
              const SizedBox(height: 8),
              Text(report.moderatorNote!),
            ],
          ],
        ),
      ),
    );
  }
}
