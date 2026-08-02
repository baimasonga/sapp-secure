import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design/app_typography.dart';
import '../../app/design/design_tokens.dart';
import '../../core/widgets/ds_components.dart';
import '../application/moderation_controllers.dart';
import '../domain/moderation_models.dart';
import 'moderation_strings.dart';

/// One report, everything known about it, and the decision.
///
/// The screen is arranged so the evidence is read before the buttons are
/// reachable: what the reporter said, then how many independent people said
/// it, then the verdict. A moderator who scrolls straight to the bottom has at
/// least scrolled past the thing that should have changed their mind.
class ReportDetailPage extends ConsumerStatefulWidget {
  const ReportDetailPage({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  final TextEditingController _note = TextEditingController();
  final TextEditingController _duplicateOf = TextEditingController();
  Verdict? _chosen;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    _duplicateOf.dispose();
    super.dispose();
  }

  Future<void> _record(QueuedReport report) async {
    final verdict = _chosen;
    if (verdict == null) return;

    if (verdict.requiresNote && _note.text.trim().isEmpty) {
      setState(() => _error = Mod.noteRequired);
      return;
    }
    setState(() => _error = null);

    final saved = await ref
        .read(verdictControllerProvider.notifier)
        .submit(
          report: report,
          verdict: verdict,
          note: _note.text,
          duplicateOf: verdict == Verdict.markDuplicate
              ? _duplicateOf.text.trim()
              : null,
        );

    if (!mounted) return;
    if (saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(Mod.verdictRecorded)));
      Navigator.of(context).maybePop();
    } else {
      setState(() => _error = Mod.verdictFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportProvider(widget.reportId));
    final saving = ref.watch(verdictControllerProvider) is VerdictSaving;

    return Scaffold(
      appBar: AppBar(title: const Text(Mod.reportTitle)),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Padding(
          padding: EdgeInsets.all(DsSpace.x6),
          child: DsNotice(
            icon: Icons.cloud_off_outlined,
            tone: DsNoticeTone.danger,
            text: Mod.queueLoadFailed,
          ),
        ),
        data: (value) {
          if (value == null) {
            return const Padding(
              padding: EdgeInsets.all(DsSpace.x6),
              child: DsNotice(icon: Icons.search_off, text: Mod.queueEmpty),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(DsSpace.x6),
                children: [
                  _Evidence(report: value),
                  const SizedBox(height: DsSpace.x6),
                  _Standing(report: value),
                  const SizedBox(height: DsSpace.x6),
                  if (value.isDecided)
                    DsNotice(
                      icon: Icons.gavel_outlined,
                      title: Mod.alreadyDecided,
                      text:
                          '${value.status.id.replaceAll('_', ' ')}'
                          '${value.moderatorNote == null ? '' : ' — ${value.moderatorNote}'}',
                    )
                  else
                    _VerdictForm(
                      chosen: _chosen,
                      note: _note,
                      duplicateOf: _duplicateOf,
                      error: _error,
                      saving: saving,
                      onChoose: (verdict) => setState(() {
                        _chosen = verdict;
                        _error = null;
                      }),
                      onSubmit: () => _record(value),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Evidence extends StatelessWidget {
  const _Evidence({required this.report});

  final QueuedReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final indicator = report.indicator;

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.threatType.id.replaceAll('_', ' '),
            style: AppType.title.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: DsSpace.x4),
          _Field(
            label: Mod.reportedNumber,
            value: indicator?.maskedValue ?? '—',
            mono: true,
          ),
          if (report.reportedLink != null)
            _Field(label: Mod.reportedLink, value: report.reportedLink!),
          if (report.district != null)
            _Field(label: Mod.district, value: report.district!),
          _Field(
            label: Mod.submitted,
            value: report.createdAt.toUtc().toIso8601String(),
          ),
          const SizedBox(height: DsSpace.x2),
          const DsNotice(icon: Icons.lock_outline, text: Mod.hashOnlyNote),
          const SizedBox(height: DsSpace.x4),
          DsSectionLabel(Mod.excerpt),
          Text(
            report.messageExcerpt ?? Mod.noExcerpt,
            style: AppType.body.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: DsSpace.x4),
          DsSectionLabel(Mod.signals),
          if (report.riskSignals.isEmpty)
            Text(
              Mod.noSignals,
              style: AppType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: DsSpace.x2,
              runSpacing: DsSpace.x2,
              children: [
                for (final signal in report.riskSignals)
                  Chip(label: Text(signal)),
              ],
            ),
          if (report.reporterGone) ...[
            const SizedBox(height: DsSpace.x4),
            const DsNotice(
              icon: Icons.person_off_outlined,
              text: Mod.reporterDeleted,
            ),
          ],
        ],
      ),
    );
  }
}

class _Standing extends StatelessWidget {
  const _Standing({required this.report});

  final QueuedReport report;

  @override
  Widget build(BuildContext context) {
    final indicator = report.indicator;
    final scheme = Theme.of(context).colorScheme;

    if (indicator == null) {
      return const DsNotice(
        icon: Icons.help_outline,
        title: Mod.indicatorTitle,
        text: Mod.indicatorNone,
      );
    }

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsSectionLabel(Mod.indicatorTitle),
          Row(
            children: [
              _Metric(
                label: Mod.indicatorReports,
                value: '${indicator.reportCount}',
              ),
              _Metric(
                label: Mod.indicatorReporters,
                value: '${indicator.distinctReporterCount}',
              ),
              _Metric(
                label: Mod.indicatorVerified,
                value: '${indicator.verifiedReportCount}',
              ),
            ],
          ),
          const SizedBox(height: DsSpace.x4),
          Row(
            children: [
              Icon(
                indicator.isPublic ? Icons.visibility : Icons.visibility_off,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: DsSpace.x2),
              Text(
                indicator.isPublic ? Mod.indicatorVisible : Mod.indicatorHidden,
                style: AppType.bodySm.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          if (indicator.isSingleReporter) ...[
            const SizedBox(height: DsSpace.x4),
            const DsNotice(
              icon: Icons.groups_outlined,
              text: Mod.indicatorSingleReporter,
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppType.title.copyWith(
              color: scheme.onSurface,
              fontWeight: AppType.bold,
            ),
          ),
          Text(
            label,
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: DsSpace.x0_5),
          SelectableText(
            value,
            style: mono
                ? AppType.mono.copyWith(fontSize: 14, color: scheme.onSurface)
                : AppType.body.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _VerdictForm extends StatelessWidget {
  const _VerdictForm({
    required this.chosen,
    required this.note,
    required this.duplicateOf,
    required this.error,
    required this.saving,
    required this.onChoose,
    required this.onSubmit,
  });

  final Verdict? chosen;
  final TextEditingController note;
  final TextEditingController duplicateOf;
  final String? error;
  final bool saving;
  final ValueChanged<Verdict> onChoose;
  final VoidCallback onSubmit;

  static const _labels = {
    Verdict.verify: Mod.verdictVerify,
    Verdict.reject: Mod.verdictReject,
    Verdict.needsEvidence: Mod.verdictNeedsEvidence,
    Verdict.markDuplicate: Mod.verdictDuplicate,
    Verdict.archive: Mod.verdictArchive,
  };

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsSectionLabel(Mod.verdictTitle),
          Wrap(
            spacing: DsSpace.x2,
            runSpacing: DsSpace.x2,
            children: [
              for (final entry in _labels.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: chosen == entry.key,
                  onSelected: saving ? null : (_) => onChoose(entry.key),
                ),
            ],
          ),
          if (chosen == Verdict.verify) ...[
            const SizedBox(height: DsSpace.x4),
            const DsNotice(
              icon: Icons.public,
              tone: DsNoticeTone.danger,
              text: Mod.verifyWarning,
            ),
          ],
          if (chosen == Verdict.markDuplicate) ...[
            const SizedBox(height: DsSpace.x4),
            TextField(
              controller: duplicateOf,
              decoration: const InputDecoration(
                labelText: Mod.duplicateOfLabel,
              ),
            ),
          ],
          const SizedBox(height: DsSpace.x4),
          TextField(
            controller: note,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: Mod.noteLabel,
              helperText: Mod.noteHelp,
              helperMaxLines: 3,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: DsSpace.x2),
            DsNotice(
              icon: Icons.error_outline,
              tone: DsNoticeTone.danger,
              text: error!,
            ),
          ],
          const SizedBox(height: DsSpace.x4),
          FilledButton.icon(
            onPressed: (chosen == null || saving) ? null : onSubmit,
            icon: saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.gavel, size: 20),
            label: const Text(Mod.verdictTitle),
          ),
        ],
      ),
    );
  }
}
