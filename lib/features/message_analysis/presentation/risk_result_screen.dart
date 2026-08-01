import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/coming_soon_sheet.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            RiskLevelBanner(
              level: assessment.level,
              score: assessment.score,
              summary: assessment.summary,
            ),
            const SizedBox(height: 24),
            _SignalsSection(assessment: assessment),
            if (assessment.phoneNumbers.isNotEmpty) ...[
              const SizedBox(height: 24),
              _NumbersSection(assessment: assessment),
            ],
            if (assessment.urls.isNotEmpty) ...[
              const SizedBox(height: 24),
              _LinksSection(assessment: assessment),
            ],
            const SizedBox(height: 24),
            _ActionsSection(assessment: assessment),
            const SizedBox(height: 24),
            _LimitationsSection(assessment: assessment),
            const SizedBox(height: 28),
            _ResultButtons(assessment: assessment),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
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
          icon: Icons.search,
        ),
        if (assessment.signals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.resultSignalsEmpty),
            ),
          )
        else
          for (final signal in assessment.signals)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.explanation,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(signal.advice),
                    if (signal.matchedText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        l10n.resultMatchedText(signal.matchedText!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _Chip(text: '+${signal.weight}'),
                        _Chip(
                          text: l10n.resultConfidence(
                            (signal.confidence * 100).round(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
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
          icon: Icons.phone_outlined,
        ),
        Card(
          child: Column(
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
                    return ListTile(
                      leading: Icon(
                        contact == null
                            ? Icons.dialpad
                            : Icons.verified_user_outlined,
                      ),
                      title: Text(number.normalised),
                      subtitle: contact != null
                          ? Text(
                              l10n.verifyKnownContactBadge(contact.displayName),
                            )
                          : (number.raw.trim() == number.normalised
                                ? null
                                : Text(number.raw.trim())),
                      trailing: TextButton(
                        onPressed: () => context.pushNamed(
                          AppRoute.verify.name,
                          extra: number.normalised,
                        ),
                        child: Text(l10n.resultVerifyPerson),
                      ),
                    );
                  },
                ),
            ],
          ),
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
          icon: Icons.link,
        ),
        for (final url in assessment.urls)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shown as plain text, never as a tappable link: the app must
                  // not make it easy to open something it just flagged.
                  SelectableText(
                    url.original,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        url.isSuspicious
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        size: 18,
                        color: url.isSuspicious ? scheme.error : scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(url.host.isEmpty ? '—' : url.host)),
                    ],
                  ),
                  for (final finding in url.findings) ...[
                    const SizedBox(height: 6),
                    Text(
                      '• ${_findingLabel(l10n, finding)}',
                      style: Theme.of(context).textTheme.bodySmall,
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
    final palette = RiskPalette.of(context, assessment.level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.resultActionsTitle,
          icon: Icons.checklist_rtl,
        ),
        for (final action in assessment.recommendedActions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_forward, size: 20, color: palette.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.resultLimitationsTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final limitation in assessment.limitations)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $limitation',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
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
        OutlinedButton.icon(
          onPressed: () => _startVerification(context, l10n),
          icon: const Icon(Icons.person_search_outlined),
          label: Text(l10n.resultVerifyPerson),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showComingSoonSheet(context, l10n.resultReport),
          icon: const Icon(Icons.flag_outlined),
          label: Text(l10n.resultReport),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _warningText(l10n)));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.resultCopiedWarning)));
          },
          icon: const Icon(Icons.copy_all_outlined),
          label: Text(l10n.resultCopyWarning),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            ref.read(analysisControllerProvider.notifier).reset();
            context.pop();
          },
          icon: const Icon(Icons.refresh),
          label: Text(l10n.resultAnalyseAnother),
        ),
      ],
    );
  }
}
