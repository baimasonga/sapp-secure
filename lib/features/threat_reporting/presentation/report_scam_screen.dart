import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../authentication/presentation/sign_in_screen.dart';
import '../application/report_controller.dart';
import '../domain/threat_report.dart';

/// Localised names for the threat types (section 17.1), phrased as things
/// that happened to the user rather than as categories.
extension ThreatTypeL10n on ThreatType {
  String label(AppLocalizations l10n) => switch (this) {
    ThreatType.impersonation => l10n.threatTypeImpersonation,
    ThreatType.hijackedAccount => l10n.threatTypeHijackedAccount,
    ThreatType.financialHelpScam => l10n.threatTypeFinancialHelpScam,
    ThreatType.verificationCodeTheft => l10n.threatTypeVerificationCodeTheft,
    ThreatType.qrCodeScam => l10n.threatTypeQrCodeScam,
    ThreatType.mobileMoneyScam => l10n.threatTypeMobileMoneyScam,
    ThreatType.maliciousLink => l10n.threatTypeMaliciousLink,
    ThreatType.fakeJob => l10n.threatTypeFakeJob,
    ThreatType.fakeLoan => l10n.threatTypeFakeLoan,
    ThreatType.fakeInvestment => l10n.threatTypeFakeInvestment,
    ThreatType.fakePrize => l10n.threatTypeFakePrize,
    ThreatType.blackmail => l10n.threatTypeBlackmail,
    ThreatType.other => l10n.threatTypeOther,
  };
}

extension ReportStatusL10n on ReportStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ReportStatus.pending => l10n.reportStatusPending,
    ReportStatus.underReview => l10n.reportStatusUnderReview,
    ReportStatus.needsMoreEvidence => l10n.reportStatusNeedsEvidence,
    ReportStatus.verified => l10n.reportStatusVerified,
    ReportStatus.rejected => l10n.reportStatusRejected,
    ReportStatus.duplicate => l10n.reportStatusDuplicate,
    ReportStatus.archived => l10n.reportStatusArchived,
  };
}

/// Report a scam (specification sections 6.5 and 7.11).
class ReportScamScreen extends ConsumerStatefulWidget {
  const ReportScamScreen({
    super.key,
    this.initialNumber,
    this.initialLink,
    this.riskSignals = const [],
  });

  /// Pre-filled when the user arrives from a risk result.
  final String? initialNumber;
  final String? initialLink;
  final List<String> riskSignals;

  @override
  ConsumerState<ReportScamScreen> createState() => _ReportScamScreenState();
}

class _ReportScamScreenState extends ConsumerState<ReportScamScreen> {
  late final TextEditingController _number = TextEditingController(
    text: widget.initialNumber ?? '',
  );
  late final TextEditingController _link = TextEditingController(
    text: widget.initialLink ?? '',
  );
  final TextEditingController _paymentNumber = TextEditingController();
  final TextEditingController _excerpt = TextEditingController();
  final TextEditingController _district = TextEditingController();

  ThreatType _threatType = ThreatType.impersonation;
  bool _consent = false;

  @override
  void dispose() {
    for (final controller in [
      _number,
      _link,
      _paymentNumber,
      _excerpt,
      _district,
    ]) {
      // Cleared before disposal: these hold a telephone number and part of a
      // message, neither of which should linger.
      controller.clear();
      controller.dispose();
    }
    super.dispose();
  }

  ReportDraft get _draft => ReportDraft(
    threatType: _threatType,
    reportedNumber: _number.text,
    paymentNumber: _paymentNumber.text,
    reportedLink: _link.text,
    messageExcerpt: _excerpt.text,
    district: _district.text,
    riskSignals: widget.riskSignals,
    consentConfirmed: _consent,
  );

  String _failureText(AppLocalizations l10n, ReportFailure failure) =>
      switch (failure.reason) {
        ReportFailureReason.rateLimited => l10n.reportFailedRateLimited,
        ReportFailureReason.suspended => l10n.reportFailedSuspended,
        ReportFailureReason.network => l10n.reportFailedNetwork,
        ReportFailureReason.consentMissing => l10n.reportConsentRequired,
        ReportFailureReason.nothingToReport => l10n.reportNothingToSend,
        ReportFailureReason.notSignedIn => l10n.reportSignInNeeded,
        ReportFailureReason.unknown => l10n.reportFailedUnknown,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Three gates, each with a different honest answer.
    if (!ref.watch(reportingAvailableProvider)) {
      return _Shell(
        title: l10n.reportTitle,
        child: _Notice(
          icon: Icons.cloud_off_outlined,
          title: l10n.reportUnavailableTitle,
          body: l10n.reportUnavailableBody,
        ),
      );
    }
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return _Shell(
        title: l10n.reportTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Notice(
              icon: Icons.account_circle_outlined,
              title: l10n.authSignInTitle,
              body: l10n.reportSignInNeeded,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              ),
              icon: const Icon(Icons.login),
              label: Text(l10n.authSignIn),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.authGuestNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    final state = ref.watch(reportControllerProvider);
    if (state is ReportSubmitted) {
      return _Shell(
        title: l10n.reportTitle,
        child: _Notice(
          icon: Icons.check_circle_outline,
          title: l10n.reportSubmittedTitle,
          body: state.result.wasDuplicate
              ? l10n.reportDuplicateBody
              : l10n.reportSubmittedBody(state.result.reportId.substring(0, 8)),
        ),
      );
    }

    final submitting = state is ReportSubmitting;
    return _Shell(
      title: l10n.reportTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reportIntro, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          Text(
            l10n.reportThreatType,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ThreatType>(
            initialValue: _threatType,
            isExpanded: true,
            items: [
              for (final type in ThreatType.values)
                DropdownMenuItem(value: type, child: Text(type.label(l10n))),
            ],
            onChanged: submitting
                ? null
                : (value) => setState(
                    () => _threatType = value ?? ThreatType.impersonation,
                  ),
          ),
          const SizedBox(height: 20),
          _Field(controller: _number, label: l10n.reportNumber, phone: true),
          _Field(
            controller: _paymentNumber,
            label: l10n.reportPaymentNumber,
            phone: true,
          ),
          _Field(controller: _link, label: l10n.reportLink),
          const SizedBox(height: 4),
          TextField(
            controller: _excerpt,
            maxLines: 4,
            minLines: 2,
            maxLength: ReportDraft.maxExcerptLength,
            decoration: InputDecoration(
              labelText: l10n.reportExcerpt,
              helperText: l10n.reportExcerptHelp,
              helperMaxLines: 3,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _district,
            decoration: InputDecoration(
              labelText: l10n.reportDistrict,
              helperText: l10n.reportDistrictHelp,
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 24),
          _WhatIsSent(draft: _draft),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _consent,
            onChanged: submitting
                ? null
                : (value) => setState(() => _consent = value ?? false),
            title: Text(l10n.reportConsent),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (state is ReportRejected) ...[
            const SizedBox(height: 8),
            _Notice(
              icon: Icons.error_outline,
              title:
                  l10n.reportFailedUnknown == _failureText(l10n, state.failure)
                  ? l10n.reportFailedUnknown
                  : _failureText(l10n, state.failure),
              body: '',
              isError: true,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: submitting
                ? null
                : () => ref
                      .read(reportControllerProvider.notifier)
                      .submit(_draft),
            icon: submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(submitting ? l10n.reportSubmitting : l10n.reportSubmit),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.reportNotAccusation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [child],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.phone = false,
  });

  final TextEditingController controller;
  final String label;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: phone ? TextInputType.phone : TextInputType.url,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

/// Shows exactly what will leave the phone, before the consent box.
///
/// Section 6.5 requires the user to confirm what is submitted. Listing it from
/// the same method that builds the request means the two cannot drift apart.
class _WhatIsSent extends StatelessWidget {
  const _WhatIsSent({required this.draft});

  final ReportDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final submission = draft.toSubmission()
      ..remove('consent_confirmed')
      ..remove('risk_signals');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_outlined, size: 20, color: scheme.onSurface),
              const SizedBox(width: 8),
              Text(
                l10n.reportWhatIsSent,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.reportWhatIsSentBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (submission.length <= 1)
            Text(
              l10n.reportNothingToSend,
              style: TextStyle(color: scheme.error),
            )
          else
            for (final entry in submission.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${entry.value}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.body,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError
        ? scheme.errorContainer
        : scheme.surfaceContainerHighest;
    final foreground = isError ? scheme.onErrorContainer : scheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(body, style: TextStyle(color: foreground)),
          ],
        ],
      ),
    );
  }
}
