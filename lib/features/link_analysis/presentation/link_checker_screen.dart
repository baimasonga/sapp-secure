import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../l10n/app_localizations.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              l10n.linkCheckIntro,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
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
              const SizedBox(height: 12),
              _ErrorBanner(message: _errorText(l10n, state.failure)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                ref
                    .read(linkCheckControllerProvider.notifier)
                    .check(_input.text);
              },
              icon: const Icon(Icons.travel_explore),
              label: Text(l10n.linkCheckRun),
            ),
            if (state is LinkCheckDone) ...[
              const SizedBox(height: 24),
              _LinkResult(analysis: state.analysis),
            ],
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.linkCheckNotOpened,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
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

    final (
      IconData icon,
      String title,
      String advice,
      Color background,
      Color foreground,
    ) = analysis.isHighlySuspicious
        ? (
            Icons.dangerous_outlined,
            l10n.linkCheckResultDangerTitle,
            l10n.linkCheckAdviceDanger,
            const Color(0xFFFCE4E6),
            const Color(0xFF7A1721),
          )
        : analysis.isSuspicious
        ? (
            Icons.warning_amber_rounded,
            l10n.linkCheckResultWarnTitle,
            l10n.linkCheckAdviceWarn,
            const Color(0xFFFDE8DB),
            const Color(0xFF6B2F0A),
          )
        : (
            Icons.verified_user_outlined,
            l10n.linkCheckResultSafeTitle,
            l10n.linkCheckAdviceSafe,
            const Color(0xFFE3F3E8),
            const Color(0xFF11492A),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: foreground.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 32, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (analysis.impersonatedBrand != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.linkCheckBrandWarning(analysis.impersonatedBrand!),
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (!analysis.isSuspicious) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.linkCheckResultSafeBody,
                  style: TextStyle(color: foreground),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
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
        ),
        if (analysis.findings.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l10n.linkCheckFindings,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final finding in analysis.findings)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(findingLabel(l10n, finding))),
                ],
              ),
            ),
        ],
        const SizedBox(height: 20),
        Text(
          l10n.linkCheckWhatToDo,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(advice, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        // Copying is offered; opening is not.
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: analysis.original));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.linkCheckCopied)));
          },
          icon: const Icon(Icons.copy_all_outlined),
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
    return ListTile(
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: SelectableText(
        value.isEmpty ? '—' : value,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
