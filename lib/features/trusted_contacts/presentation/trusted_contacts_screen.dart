import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';
import '../application/trusted_contacts_controller.dart';
import '../data/trusted_contact_repository.dart';
import '../domain/trusted_contact.dart';
import 'edit_trusted_contact_screen.dart';

/// Trusted contacts (specification section 7.12).
class TrustedContactsScreen extends ConsumerWidget {
  const TrustedContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final contacts = ref.watch(trustedContactsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trustedContactsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addContact(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.trustedContactAdd),
      ),
      body: SafeArea(
        child: contacts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.errorGeneric, textAlign: TextAlign.center),
            ),
          ),
          data: (list) => ListView(
            padding: const EdgeInsets.fromLTRB(
              DsSpace.screenGutter,
              DsSpace.x4,
              DsSpace.screenGutter,
              96,
            ),
            children: [
              Text(
                l10n.trustedContactsIntro,
                style: AppType.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DsSpace.x4),
              DsNotice(text: l10n.trustedContactsPrivacyNote),
              const SizedBox(height: DsSpace.x5),
              if (list.isEmpty)
                DsCard(sunken: true, child: Text(l10n.trustedContactsEmpty))
              else
                for (final contact in list)
                  _ContactCard(
                    contact: contact,
                    onEdit: () => _editContact(context, ref, contact),
                    onRemove: () => _confirmRemove(context, ref, contact),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addContact(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final contacts =
        ref.read(trustedContactsControllerProvider).valueOrNull ?? const [];
    if (contacts.length >= TrustedContactRepository.maxContacts) {
      _snack(
        context,
        l10n.trustedContactsFull(TrustedContactRepository.maxContacts),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const EditTrustedContactScreen()),
    );
  }

  Future<void> _editContact(
    BuildContext context,
    WidgetRef ref,
    TrustedContact contact,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditTrustedContactScreen(existing: contact),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    TrustedContact contact,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.trustedContactRemoveConfirm(contact.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trustedContactRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(trustedContactsControllerProvider.notifier)
        .remove(contact.id);
    if (!context.mounted) return;
    _snack(context, l10n.trustedContactRemoved);
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onRemove,
  });

  final TrustedContact contact;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.x3),
      child: DsCard(
        padding: const EdgeInsets.fromLTRB(
          DsSpace.x4,
          DsSpace.x3,
          DsSpace.x2,
          DsSpace.x3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsIconChip(
              icon: Icons.person_outline,
              background: scheme.surfaceContainerHighest,
              foreground: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: DsSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: AppType.subtitle.copyWith(color: scheme.onSurface),
                  ),
                  if (contact.relationshipLabel != null) ...[
                    const SizedBox(height: DsSpace.x0_5),
                    Text(
                      contact.relationshipLabel!,
                      style: AppType.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: DsSpace.x2),
                  Text(
                    contact.primaryNumberE164,
                    style: AppType.mono.copyWith(
                      fontSize: 14,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (contact.numbersE164.length > 1) ...[
                    const SizedBox(height: DsSpace.x0_5),
                    Text(
                      l10n.trustedContactNumberCount(
                        contact.numbersE164.length,
                      ),
                      style: AppType.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(
                context,
              ).modalBarrierDismissLabel,
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: l10n.trustedContactRemove,
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
