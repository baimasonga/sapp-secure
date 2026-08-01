import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/risk_engine/models/risk_level.dart';
import '../../../services/risk_engine/url_analyser.dart';
import '../application/link_check_controller.dart';

/// Link checker (specification section 7.10).
///
/// Shows what the link really is and why it looks wrong. It deliberately
/// offers no way to open the link: the app must not make it one tap easier to
/// visit something it has just warned about.
class LinkCheckerScreen extends ConsumerStatefulWidget {
  const LinkCheckerScreen({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  ConsumerState<LinkCheckerScreen> createState() => _LinkCheckerScreenState();
}

class _LinkCheckerScreenState extends ConsumerState<LinkCheckerScreen> {
  late final TextEditingController _input = TextEditingController(
    text: widget.initialUrl ?? '',
  );

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _errorText(AppLocalizations l10n, AppFailure failure) =>
      switch (failure) {
        ValidationFailure(debugMessage: 'input too long') =>
          l10n.linkCheckTooLong,
        ValidationFailure() =>
          _input.text.trim().isEmpty
              ? l10n.linkCheckEmptyError
              : l10n.linkCheckInvalid,
        _ => l10n.errorGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(linkCheckControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.linkCheckTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DsSpace.screenGutter,
            DsSpace.x4,
            DsSpace.screenGutter,
            DsSpace.x8,
          ),
          children: [
            Text(
              l10n.linkCheckIntro,
              style: AppType.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DsSpace.x4),
            TextField(
              controller: _input,
              maxLines: 3,
              minLines: 1,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: l10n.linkCheckHint,
                labelText: l10n.linkCheckTitle,
              ),
            ),
            if (state is LinkCheckFailed) ...[
              const SizedBox(height: DsSpace.x3),
              DsNotice(
                text: _errorText(l10n, state.failure),
                icon: Icons.error_outline,
                tone: DsNoticeTone.danger,
              ),
            ],
            const SizedBox(height: DsSpace.x4),
            FilledButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                ref
                    .read(linkCheckControllerProvider.notifier)
                    .check(_input.text);
              },
              icon: const Icon(Icons.travel_explore, size: 20),
              label: Text(l10n.linkCheckRun),
            ),
            if (state is LinkCheckDone) ...[
              const SizedBox(height: DsSpace.x6),
              _LinkResult(analysis: state.analysis),
            ],
            const SizedBox(height: DsSpace.x6),
            DsNotice(text: l10n.linkCheckNotOpened),
          ],
        ),
      ),
    );
  }
}

class _LinkResult extends StatelessWidget {
  const _LinkResult({required this.analysis});

  final UrlAnalysis analysis;

  static String findingLabel(AppLocalizations l10n, UrlFinding finding) =>
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

    // The verdict borrows the risk bands' palette rather than inventing its
    // own colours, so a dangerous link looks the same as a dangerous message
    // and both follow the theme into dark mode.
    final (
      RiskLevel level,
      String title,
      String advice,
    ) = analysis.isHighlySuspicious
        ? (
            RiskLevel.critical,
            l10n.linkCheckResultDangerTitle,
            l10n.linkCheckAdviceDanger,
          )
        : analysis.isSuspicious
        ? (
            RiskLevel.high,
            l10n.linkCheckResultWarnTitle,
            l10n.linkCheckAdviceWarn,
          )
        : (
            RiskLevel.low,
            l10n.linkCheckResultSafeTitle,
            l10n.linkCheckAdviceSafe,
          );
    final palette = RiskPalette.of(context, level);
    final foreground = palette.onContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DsSpace.x5),
          decoration: BoxDecoration(
            color: palette.container,
            borderRadius: DsRadius.all(DsRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(palette.icon, size: 26, color: foreground),
                  const SizedBox(width: DsSpace.x2_5),
                  Expanded(
                    child: Text(
                      title,
                      style: AppType.subtitle.copyWith(
                        color: foreground,
                        fontWeight: AppType.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (analysis.impersonatedBrand != null) ...[
                const SizedBox(height: DsSpace.x3),
                Text(
                  l10n.linkCheckBrandWarning(analysis.impersonatedBrand!),
                  style: AppType.bodySm.copyWith(
                    color: foreground,
                    fontWeight: AppType.semibold,
                  ),
                ),
              ],
              if (!analysis.isSuspicious) ...[
                const SizedBox(height: DsSpace.x3),
                Text(
                  l10n.linkCheckResultSafeBody,
                  style: AppType.bodySm.copyWith(color: foreground),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: DsSpace.x5),
        DsListGroup(
          children: [
            _Row(label: l10n.linkCheckAddress, value: analysis.original),
            _Row(label: l10n.linkCheckDomain, value: analysis.host),
            _Row(
              label: l10n.linkCheckHttps,
              value: analysis.isHttps
                  ? l10n.linkCheckHttpsYes
                  : l10n.linkCheckHttpsNo,
            ),
          ],
        ),
        if (analysis.findings.isNotEmpty) ...[
          const SizedBox(height: DsSpace.x5),
          DsSectionLabel(l10n.linkCheckFindings),
          for (final finding in analysis.findings)
            Padding(
              padding: const EdgeInsets.only(bottom: DsSpace.x1_5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: scheme.error,
                  ),
                  const SizedBox(width: DsSpace.x2),
                  Expanded(
                    child: Text(
                      findingLabel(l10n, finding),
                      style: AppType.bodySm.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: DsSpace.x5),
        DsSectionLabel(l10n.linkCheckWhatToDo),
        Text(
          advice,
          style: AppType.body.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: DsSpace.x5),
        // Copying is offered; opening is not.
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: analysis.original));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.linkCheckCopied)));
          },
          icon: const Icon(Icons.copy_all_outlined, size: 20),
          label: Text(l10n.linkCheckCopy),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(DsSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: DsSpace.x1),
          SelectableText(
            value.isEmpty ? '—' : value,
            style: AppType.mono.copyWith(
              fontSize: 13.5,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
