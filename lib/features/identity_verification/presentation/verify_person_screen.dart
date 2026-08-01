import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/risk_engine/models/risk_level.dart';
import '../../trusted_contacts/domain/trusted_contact.dart';
import '../application/verification_controller.dart';
import '../domain/verification_record.dart';

/// Verify Person (specification sections 6.4 and 7.8).
///
/// The screen exists to answer one question: is the number in this message a
/// number the person it claims to be actually uses? Everything else supports
/// that comparison or records what the user concluded.
class VerifyPersonScreen extends ConsumerWidget {
  const VerifyPersonScreen({super.key, required this.numberE164});

  final String numberE164;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(verificationControllerProvider(numberE164));
    final controller = ref.read(
      verificationControllerProvider(numberE164).notifier,
    );
    final contacts = ref.watch(verificationContactsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyTitle)),
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
              l10n.verifyIntro,
              style: AppType.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DsSpace.x5),
            _NumberCard(number: numberE164),
            const SizedBox(height: DsSpace.x5),
            _ClaimedIdentitySection(
              contacts: contacts,
              state: state,
              onSelect: controller.selectContact,
              onName: controller.setClaimedName,
            ),
            const SizedBox(height: DsSpace.x5),
            _MatchSection(state: state),
            if (state.pastRecords.isNotEmpty) ...[
              const SizedBox(height: DsSpace.x4),
              _PastChecks(state: state),
            ],
            const SizedBox(height: DsSpace.x6),
            _MethodsSection(state: state, controller: controller),
            const SizedBox(height: DsSpace.x6),
            _OutcomeSection(state: state, controller: controller),
          ],
        ),
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DsCard(
      child: Row(
        children: [
          DsIconChip(
            icon: Icons.dialpad,
            background: scheme.surfaceContainerHighest,
            foreground: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: DsSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.verifyNumberInMessage,
                  style: AppType.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DsSpace.x0_5),
                Text(
                  number,
                  style: AppType.mono.copyWith(
                    fontSize: 16,
                    color: scheme.onSurface,
                    fontWeight: AppType.semibold,
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

class _ClaimedIdentitySection extends StatelessWidget {
  const _ClaimedIdentitySection({
    required this.contacts,
    required this.state,
    required this.onSelect,
    required this.onName,
  });

  final List<TrustedContact> contacts;
  final VerificationState state;
  final void Function(TrustedContact?) onSelect;
  final void Function(String) onName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsSectionLabel(l10n.verifyWhoClaims),
        if (contacts.isEmpty)
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.verifyNoContactsYet,
                  style: AppType.bodySm.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DsSpace.x3),
                OutlinedButton.icon(
                  // Contacts is a tab, so this switches tabs rather than
                  // stacking a second navigation bar on top of this screen.
                  onPressed: () =>
                      context.goNamed(AppRoute.trustedContacts.name),
                  icon: const Icon(Icons.person_add_alt, size: 20),
                  label: Text(l10n.verifyAddContactsFirst),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: DsSpace.x2,
            runSpacing: DsSpace.x2,
            children: [
              for (final contact in contacts)
                ChoiceChip(
                  label: Text(contact.displayName),
                  selected: state.claimedContact?.id == contact.id,
                  onSelected: (selected) => onSelect(selected ? contact : null),
                ),
            ],
          ),
        const SizedBox(height: DsSpace.x3),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.verifyClaimedNameHint,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          onChanged: onName,
        ),
      ],
    );
  }
}

/// The comparison itself, stated in words with an icon — never colour alone.
class _MatchSection extends StatelessWidget {
  const _MatchSection({required this.state});

  final VerificationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final name = state.effectiveClaimedName.isEmpty
        ? l10n.verifyClaimedNameHint
        : state.effectiveClaimedName;

    // The verdict uses the risk bands' palette so a mismatch here looks
    // exactly as serious as a critical message elsewhere in the app.
    final (
      IconData icon,
      String title,
      String body,
      Color bg,
      Color fg,
    ) = switch (state.matchStatus) {
      NumberMatchStatus.matchesTrusted => (
        Icons.verified_user_outlined,
        l10n.verifyMatchMatches(name),
        l10n.verifyMatchMatchesBody,
        RiskPalette.of(context, RiskLevel.low).container,
        RiskPalette.of(context, RiskLevel.low).onContainer,
      ),
      NumberMatchStatus.differsFromTrusted => (
        Icons.dangerous_outlined,
        l10n.verifyMatchDiffers(name),
        l10n.verifyMatchDiffersBody,
        RiskPalette.of(context, RiskLevel.critical).container,
        RiskPalette.of(context, RiskLevel.critical).onContainer,
      ),
      NumberMatchStatus.noTrustedContact => (
        Icons.help_outline,
        l10n.verifyMatchUnknown,
        l10n.verifyMatchUnknownBody,
        scheme.surfaceContainerHighest,
        scheme.onSurface,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DsSpace.x5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DsRadius.all(DsRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 26, color: fg),
              const SizedBox(width: DsSpace.x2_5),
              Expanded(
                child: Text(
                  title,
                  style: AppType.subtitle.copyWith(
                    color: fg,
                    fontWeight: AppType.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpace.x3),
          Text(body, style: AppType.bodySm.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _PastChecks extends StatelessWidget {
  const _PastChecks({required this.state});

  final VerificationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isImpersonator = state.wasPreviouslyImpersonation;

    return DsNotice(
      icon: isImpersonator ? Icons.history_toggle_off : Icons.history,
      tone: isImpersonator ? DsNoticeTone.danger : DsNoticeTone.neutral,
      text: isImpersonator
          ? l10n.verifyPreviousImpersonation
          : l10n.verifyPreviousChecks(state.pastRecords.length),
    );
  }
}

class _MethodsSection extends StatelessWidget {
  const _MethodsSection({required this.state, required this.controller});

  final VerificationState state;
  final VerificationController controller;

  /// Opens the dialer or the SMS composer. Both are pre-filled intents the
  /// user must still confirm: the app never places a call or sends a message
  /// on its own.
  Future<void> _launch(BuildContext context, Uri uri) async {
    final l10n = AppLocalizations.of(context);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.verifyDialFailed)));
  }

  void _requireContact(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.verifyNoSavedNumber)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final savedNumber = state.claimedContact?.primaryNumberE164;
    final question = state.claimedContact?.verificationQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsSectionLabel(l10n.verifyHowTitle),
        _MethodTile(
          icon: Icons.call_outlined,
          title: l10n.verifyMethodCall,
          // The saved number is shown so the user can see it is not the
          // number from the message.
          subtitle: savedNumber ?? l10n.verifyMethodCallBody,
          onTap: () {
            if (savedNumber == null) {
              _requireContact(context);
              return;
            }
            controller.selectMethod(VerificationMethod.callSavedNumber);
            _launch(context, Uri(scheme: 'tel', path: savedNumber));
          },
        ),
        _MethodTile(
          icon: Icons.sms_outlined,
          title: l10n.verifyMethodSms,
          subtitle: l10n.verifyMethodSmsBody,
          onTap: () {
            if (savedNumber == null) {
              _requireContact(context);
              return;
            }
            controller.selectMethod(VerificationMethod.sendSms);
            _launch(context, Uri(scheme: 'sms', path: savedNumber));
          },
        ),
        _MethodTile(
          icon: Icons.quiz_outlined,
          title: l10n.verifyMethodQuestion,
          subtitle: question ?? l10n.verifyMethodQuestionBody,
          onTap: () =>
              controller.selectMethod(VerificationMethod.askPrivateQuestion),
        ),
        _MethodTile(
          icon: Icons.groups_outlined,
          title: l10n.verifyMethodRelative,
          subtitle: l10n.verifyMethodRelativeBody,
          onTap: () => controller.selectMethod(VerificationMethod.askRelative),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.x2_5),
      child: DsCard(
        onTap: onTap,
        padding: const EdgeInsets.all(DsSpace.x3),
        child: Row(
          children: [
            DsIconChip(icon: icon),
            const SizedBox(width: DsSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.bodySm.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppType.semibold,
                    ),
                  ),
                  const SizedBox(height: DsSpace.x0_5),
                  Text(
                    subtitle,
                    style: AppType.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _OutcomeSection extends StatelessWidget {
  const _OutcomeSection({required this.state, required this.controller});

  final VerificationState state;
  final VerificationController controller;

  String _note(AppLocalizations l10n, VerificationOutcome outcome) =>
      switch (outcome) {
        VerificationOutcome.verifiedSafe => l10n.verifyOutcomeSafeNote,
        VerificationOutcome.couldNotVerify => l10n.verifyOutcomeUnsureNote,
        VerificationOutcome.confirmedImpersonation =>
          l10n.verifyOutcomeImpersonationNote,
      };

  Future<void> _record(
    BuildContext context,
    VerificationOutcome outcome,
  ) async {
    final l10n = AppLocalizations.of(context);
    await controller.recordOutcome(outcome);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_note(l10n, outcome)),
          duration: const Duration(seconds: 6),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsSectionLabel(l10n.verifyOutcomeTitle),
        OutlinedButton.icon(
          onPressed: () => _record(context, VerificationOutcome.verifiedSafe),
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: Text(l10n.verifyOutcomeSafe),
        ),
        const SizedBox(height: DsSpace.x2_5),
        OutlinedButton.icon(
          onPressed: () => _record(context, VerificationOutcome.couldNotVerify),
          icon: const Icon(Icons.help_outline, size: 20),
          label: Text(l10n.verifyOutcomeUnsure),
        ),
        const SizedBox(height: DsSpace.x2_5),
        FilledButton.icon(
          onPressed: () =>
              _record(context, VerificationOutcome.confirmedImpersonation),
          icon: const Icon(Icons.report_gmailerrorred_outlined, size: 20),
          label: Text(l10n.verifyOutcomeImpersonation),
        ),
      ],
    );
  }
}
