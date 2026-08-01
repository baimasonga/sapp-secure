import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                l10n.trustedContactsIntro,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _PrivacyNote(text: l10n.trustedContactsPrivacyNote),
              const SizedBox(height: 20),
              if (list.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.trustedContactsEmpty),
                  ),
                )
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (contact.relationshipLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact.relationshipLabel!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(contact.primaryNumberE164),
                  if (contact.numbersE164.length > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.trustedContactNumberCount(
                        contact.numbersE164.length,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
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

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
