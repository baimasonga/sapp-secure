import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';

/// Language selection (section 7.2). Shown before anything else so the rest of
/// onboarding is already in the user's language.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  static const List<({String code, String english, String native})> _languages =
      [
        (code: 'en', english: 'English', native: 'English'),
        (code: 'kri', english: 'Krio', native: 'Krio'),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(languageControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.shield_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.languageTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.languageSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              for (final language in _languages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LanguageTile(
                    label: language.native,
                    selected: selected == language.code,
                    onTap: () => ref
                        .read(languageControllerProvider.notifier)
                        .select(language.code),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  if (selected == null) {
                    await ref
                        .read(languageControllerProvider.notifier)
                        .select('en');
                  }
                  if (!context.mounted) return;
                  context.goNamed(AppRoute.onboarding.name);
                },
                child: Text(l10n.actionContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surface,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? scheme.onPrimaryContainer : null,
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
                ),
              ),
              // Selection is marked with a tick as well as colour.
              if (selected) Icon(Icons.check_circle, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
