import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';
import '../application/trusted_contacts_controller.dart';
import '../data/trusted_contact_repository.dart';
import '../domain/trusted_contact.dart';

/// Adds or edits one trusted contact.
///
/// Numbers can be typed, or chosen through the system contact picker — which
/// hands back only the single person the user tapped, so the app needs no
/// contacts permission and never sees the rest of the address book.
class EditTrustedContactScreen extends ConsumerStatefulWidget {
  const EditTrustedContactScreen({super.key, this.existing});

  final TrustedContact? existing;

  @override
  ConsumerState<EditTrustedContactScreen> createState() =>
      _EditTrustedContactScreenState();
}

class _EditTrustedContactScreenState
    extends ConsumerState<EditTrustedContactScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.displayName ?? '',
  );
  late final TextEditingController _relationship = TextEditingController(
    text: widget.existing?.relationshipLabel ?? '',
  );
  late final TextEditingController _question = TextEditingController(
    text: widget.existing?.verificationQuestion ?? '',
  );
  late final List<TextEditingController> _numbers = [
    for (final number in widget.existing?.numbersE164 ?? const [''])
      TextEditingController(text: number),
  ];

  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _question.dispose();
    for (final controller in _numbers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFromContacts() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ref.read(contactPickerServiceProvider).pick();
    if (!mounted) return;
    if (picked == null) {
      // Cancelling is normal; only say something if there is nothing to show.
      _snack(l10n.trustedContactPickerUnavailable);
      return;
    }
    setState(() {
      if (_name.text.trim().isEmpty) _name.text = picked.name;
      final firstEmpty = _numbers.indexWhere(
        (controller) => controller.text.trim().isEmpty,
      );
      if (firstEmpty >= 0) {
        _numbers[firstEmpty].text = picked.rawNumber;
      } else {
        _numbers.add(TextEditingController(text: picked.rawNumber));
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final contact = TrustedContact.create(
      id: widget.existing?.id,
      createdAt: widget.existing?.createdAt,
      displayName: _name.text,
      rawNumbers: _numbers.map((controller) => controller.text).toList(),
      relationshipLabel: _relationship.text,
      verificationQuestion: _question.text,
    );

    if (contact == null) {
      setState(() => _error = l10n.trustedContactInvalid);
      return;
    }

    final saved = await ref
        .read(trustedContactsControllerProvider.notifier)
        .save(contact);
    if (!mounted) return;
    if (!saved) {
      setState(
        () => _error = l10n.trustedContactsFull(
          TrustedContactRepository.maxContacts,
        ),
      );
      return;
    }
    _snack(l10n.trustedContactSaved);
    Navigator.of(context).pop();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trustedContactAdd)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DsSpace.screenGutter,
            DsSpace.x4,
            DsSpace.screenGutter,
            DsSpace.x8,
          ),
          children: [
            OutlinedButton.icon(
              onPressed: _pickFromContacts,
              icon: const Icon(Icons.contacts_outlined, size: 20),
              label: Text(l10n.trustedContactFromPhone),
            ),
            const SizedBox(height: DsSpace.x5),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.trustedContactName,
                hintText: l10n.trustedContactNameHint,
              ),
            ),
            const SizedBox(height: DsSpace.x4),
            for (var index = 0; index < _numbers.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: DsSpace.x3),
                child: TextField(
                  controller: _numbers[index],
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.trustedContactNumber,
                    hintText: l10n.trustedContactNumberHint,
                    suffixIcon: _numbers.length > 1
                        ? IconButton(
                            tooltip: l10n.actionClose,
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => setState(() {
                              _numbers.removeAt(index).dispose();
                            }),
                          )
                        : null,
                  ),
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _numbers.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: Text(l10n.trustedContactAddNumber),
              ),
            ),
            const SizedBox(height: DsSpace.x2),
            TextField(
              controller: _relationship,
              decoration: InputDecoration(
                labelText: l10n.trustedContactRelationship,
                hintText: l10n.trustedContactRelationshipHint,
              ),
            ),
            const SizedBox(height: DsSpace.x4),
            TextField(
              controller: _question,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.trustedContactQuestion,
                hintText: l10n.trustedContactQuestionHint,
              ),
            ),
            const SizedBox(height: DsSpace.x2),
            Text(
              l10n.trustedContactQuestionNote,
              style: AppType.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: DsSpace.x4),
              DsNotice(
                icon: Icons.error_outline,
                tone: DsNoticeTone.danger,
                text: _error!,
              ),
            ],
            const SizedBox(height: DsSpace.x6),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: Text(l10n.trustedContactSave),
            ),
          ],
        ),
      ),
    );
  }
}
