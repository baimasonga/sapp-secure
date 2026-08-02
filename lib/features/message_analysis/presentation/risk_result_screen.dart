import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/router.dart';
import '../../../core/widgets/ds_components.dart';
import '../../trusted_contacts/application/trusted_contacts_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/risk_engine/models/risk_assessment.dart';
import '../../../services/risk_engine/url_analyser.dart';
import '../application/analysis_controller.dart';
import 'widgets/risk_level_banner.dart';

/// Explainable result (sections 7.7 and 9.5): what was found, why it matters,
/// what to do, and what the app could not check.
class RiskResultScreen extends ConsumerWidget {
  const RiskResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(analysisControllerProvider);

    if (state is! AnalysisSuccess) {
      // Reached by a back-navigation after the result was cleared.
      return Scaffold(
        appBar: AppBar(title: Text(l10n.resultTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.homeRecentEmpty, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final assessment = state.assessment;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resultTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DsSpace.screenGutter,
            DsSpace.x4,
            DsSpace.screenGutter,
            DsSpace.x8,
          ),
          children: [
            RiskLevelBanner(
              level: assessment.level,
              score: assessment.score,
              summary: assessment.summary,
            ),
            const SizedBox(height: DsSpace.x6),
            _SignalsSection(assessment: assessment),
            if (assessment.phoneNumbers.isNotEmpty) ...[
              const SizedBox(height: DsSpace.x6),
              _NumbersSection(assessment: assessment),
            ],
            if (assessment.urls.isNotEmpty) ...[
              const SizedBox(height: DsSpace.x6),
              _LinksSection(assessment: assessment),
            ],
            const SizedBox(height: DsSpace.x6),
            _ActionsSection(assessment: assessment),
            const SizedBox(height: DsSpace.x6),
            _LimitationsSection(assessment: assessment),
            const SizedBox(height: DsSpace.x7),
            _ResultButtons(assessment: assessment),
          ],
        ),
      ),
    );
  }
}

/// An eyebrow, and under it the one line of context the section needs. The
/// icon the old header carried is gone: on this screen the icons were
/// decoration, and decoration competes with the signals that matter.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsSectionLabel(title),
        if (subtitle != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpace.x2_5),
            child: Text(
              subtitle!,
              style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

class _SignalsSection extends StatelessWidget {
  const _SignalsSection({required this.assessment});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.resultSignalsTitle,
          subtitle: l10n.resultSignalCount(assessment.signals.length),
        ),
        if (assessment.signals.isEmpty)
          DsNotice(text: l10n.resultSignalsEmpty, icon: Icons.check_circle)
        else
          DsListGroup(
            children: [
              for (final signal in assessment.signals)
                _SignalRow(signal: signal),
            ],
          ),
      ],
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({required this.signal});

  final RiskSignal signal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(DsSpace.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The weight, shown because a score the user cannot take apart is a
          // score they have to take on faith.
          Container(
            constraints: const BoxConstraints(minWidth: 38),
            height: 26,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: DsSpace.x2),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: DsRadius.all(DsRadius.sm),
            ),
            child: Text(
              '+${signal.weight}',
              style: AppType.caption.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: AppType.bold,
              ),
            ),
          ),
          const SizedBox(width: DsSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.explanation,
                  style: AppType.bodySm.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppType.semibold,
                  ),
                ),
                const SizedBox(height: DsSpace.x0_5),
                Text(
                  signal.advice,
                  style: AppType.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (signal.matchedText != null) ...[
                  const SizedBox(height: DsSpace.x2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpace.x2,
                      vertical: DsSpace.x1,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: DsRadius.all(DsRadius.xs),
                    ),
                    child: Text(
                      l10n.resultMatchedText(signal.matchedText!),
                      style: AppType.mono.copyWith(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: DsSpace.x2),
                Text(
                  l10n.resultConfidence((signal.confidence * 100).round()),
                  style: AppType.caption.copyWith(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumbersSection extends ConsumerWidget {
  const _NumbersSection({required this.assessment});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.resultNumbersTitle,
          subtitle: l10n.resultNumbersNote,
        ),
        DsListGroup(
          children: [
            for (final number in assessment.phoneNumbers)
              Builder(
                builder: (context) {
                  // A number belonging to someone the user already trusts is
                  // worth saying out loud — it is the one piece of good news
                  // the app can offer honestly.
                  final contact = ref.watch(
                    contactForNumberProvider(number.normalised),
                  );
                  final scheme = Theme.of(context).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpace.x4,
                      DsSpace.x3,
                      DsSpace.x3,
                      DsSpace.x3,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          contact == null
                              ? Icons.dialpad
                              : Icons.verified_user_outlined,
                          size: 18,
                          color: contact == null
                              ? scheme.onSurfaceVariant
                              : DsColor.green500,
                        ),
                        const SizedBox(width: DsSpace.x3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                number.normalised,
                                style: AppType.mono.copyWith(
                                  fontSize: 14,
                                  color: scheme.onSurface,
                                  fontWeight: AppType.semibold,
                                ),
                              ),
                              if (contact != null)
                                Text(
                                  l10n.verifyKnownContactBadge(
                                    contact.displayName,
                                  ),
                                  style: AppType.caption.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                )
                              else if (number.raw.trim() != number.normalised)
                                Text(
                                  number.raw.trim(),
                                  style: AppType.caption.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pushNamed(
                            AppRoute.verify.name,
                            extra: number.normalised,
                          ),
                          child: Text(l10n.resultVerifyPerson),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.assessment});

  final RiskAssessment assessment;

  static String _findingLabel(AppLocalizations l10n, UrlFinding finding) =>
      switch (finding) {
        UrlFinding.noHttps => l10n.urlFindingNoHttps,
        UrlFinding.ipAddressHost => l10n.urlFindingIpAddress,
        UrlFinding.punycode => l10n.urlFindingPunycode,
        UrlFinding.excessiveSubdomains => l10n.urlFindingSubdomains,
        UrlFinding.brandLookalike => l10n.urlFindingBrandLookalike,
        UrlFinding.urlShortener => l10n.urlFindingShortener,
        UrlFinding.embeddedCredentials => l10n.urlFindingCredentials,
        UrlFinding.nonStandardPort => l10n.urlFindingPort,
        UrlFinding.encodedRedirect => l10n.urlFindingRedirect,
        UrlFinding.suspiciousTld => l10n.urlFindingTld,
        UrlFinding.executableDownload => l10n.urlFindingExecutable,
        UrlFinding.displayMismatch => l10n.urlFindingMismatch,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.resultLinksTitle,
          subtitle: l10n.resultLinksNote,
        ),
        for (final url in assessment.urls)
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpace.x3),
            child: DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shown as plain text, never as a tappable link: the app must
                  // not make it easy to open something it just flagged.
                  SelectableText(
                    url.original,
                    style: AppType.mono.copyWith(
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: DsSpace.x2),
                  Row(
                    children: [
                      Icon(
                        url.isSuspicious
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        size: 18,
                        color: url.isSuspicious
                            ? scheme.error
                            : DsColor.green500,
                      ),
                      const SizedBox(width: DsSpace.x1_5),
                      Expanded(
                        child: Text(
                          url.host.isEmpty ? '—' : url.host,
                          style: AppType.bodySm.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (final finding in url.findings) ...[
                    const SizedBox(height: DsSpace.x1_5),
                    Text(
                      '• ${_findingLabel(l10n, finding)}',
                      style: AppType.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({required this.assessment});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final actions = assessment.recommendedActions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.resultActionsTitle),
        // Numbered, because these are steps in an order, not a menu.
        for (var index = 0; index < actions.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpace.x2_5),
            child: DsCard(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpace.x4,
                vertical: DsSpace.x3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppType.caption.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: AppType.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: DsSpace.x3),
                  Expanded(
                    child: Text(
                      actions[index],
                      style: AppType.bodySm.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LimitationsSection extends StatelessWidget {
  const _LimitationsSection({required this.assessment});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DsNotice(
      icon: Icons.help_outline,
      title: l10n.resultLimitationsTitle,
      text: assessment.limitations
          .map((limitation) => '• $limitation')
          .join('\n'),
    );
  }
}

class _ResultButtons extends ConsumerWidget {
  const _ResultButtons({required this.assessment});

  final RiskAssessment assessment;

  /// Sends the user to the verification flow. With several numbers in the
  /// message the app must not guess which one matters, so it asks.
  Future<void> _startVerification(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final numbers = assessment.phoneNumbers;
    if (numbers.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.verifyMatchUnknown)));
      return;
    }
    if (numbers.length == 1) {
      context.pushNamed(AppRoute.verify.name, extra: numbers.single.normalised);
      return;
    }
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                l10n.verifyChooseNumber,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final number in numbers)
              ListTile(
                leading: const Icon(Icons.dialpad),
                title: Text(number.normalised),
                onTap: () => Navigator.of(sheetContext).pop(number.normalised),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    if (!context.mounted) return;
    context.pushNamed(AppRoute.verify.name, extra: chosen);
  }

  String _warningText(AppLocalizations l10n) => [
    '${l10n.appName}: ${assessment.level.label(l10n)}',
    l10n.resultScoreLabel(assessment.score),
    assessment.summary,
    ...assessment.recommendedActions.map((action) => '- $action'),
  ].join('\n');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Verification and reporting are specified for later milestones. They
        // are shown, and clearly labelled as not working yet, rather than
        // hidden.
        // Verifying the person is the one action that actually resolves the
        // question, so it is the only filled button here.
        FilledButton.icon(
          onPressed: () => _startVerification(context, l10n),
          icon: const Icon(Icons.person_search_outlined, size: 20),
          label: Text(l10n.resultVerifyPerson),
        ),
        const SizedBox(height: DsSpace.x3),
        OutlinedButton.icon(
          onPressed: () => context.pushNamed(
            AppRoute.report.name,
            // Only the number, the link and which rules fired — never the
            // message itself.
            extra: <String, Object?>{
              'number': assessment.phoneNumbers.isEmpty
                  ? null
                  : assessment.phoneNumbers.first.normalised,
              'link': assessment.urls.isEmpty
                  ? null
                  : assessment.urls.first.original,
              'signals': assessment.signals
                  .map((signal) => signal.ruleId)
                  .toList(),
            },
          ),
          icon: const Icon(Icons.flag_outlined, size: 20),
          label: Text(l10n.resultReport),
        ),
        const SizedBox(height: DsSpace.x3),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _warningText(l10n)));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.resultCopiedWarning)));
          },
          icon: const Icon(Icons.copy_all_outlined, size: 20),
          label: Text(l10n.resultCopyWarning),
        ),
        const SizedBox(height: DsSpace.x2),
        TextButton.icon(
          onPressed: () {
            ref.read(analysisControllerProvider.notifier).reset();
            context.pop();
          },
          icon: const Icon(Icons.refresh, size: 20),
          label: Text(l10n.resultAnalyseAnother),
        ),
      ],
    );
  }
}
