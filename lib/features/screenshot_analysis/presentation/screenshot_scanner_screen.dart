import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../message_analysis/application/analysis_controller.dart';
import '../application/screenshot_controller.dart';

/// Screenshot scanner (specification sections 6.3 and 7.9).
///
/// Pick an image, read it on the device, correct what OCR got wrong, then
/// analyse. The image copy is deleted as soon as the text is out of it.
class ScreenshotScannerScreen extends ConsumerStatefulWidget {
  const ScreenshotScannerScreen({super.key});

  @override
  ConsumerState<ScreenshotScannerScreen> createState() =>
      _ScreenshotScannerScreenState();
}

class _ScreenshotScannerScreenState
    extends ConsumerState<ScreenshotScannerScreen> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.clear();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    await ref.read(screenshotControllerProvider.notifier).pickAndRead();
    if (!mounted) return;
    final state = ref.read(screenshotControllerProvider);
    if (state is ScreenshotRecognised) {
      setState(() => _text.text = state.text);
    }
  }

  Future<void> _analyse() async {
    FocusScope.of(context).unfocus();
    await ref.read(analysisControllerProvider.notifier).analyse(_text.text);
    if (!mounted) return;
    if (ref.read(analysisControllerProvider) is AnalysisSuccess) {
      context.pushNamed(AppRoute.analysisResult.name);
    }
  }

  String _errorText(AppLocalizations l10n, AppFailure failure) =>
      switch (failure) {
        PermissionFailure() => l10n.screenshotUnsupported,
        _ => l10n.screenshotFailed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(screenshotControllerProvider);
    final isReading = state is ScreenshotReading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenshotTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              l10n.screenshotIntro,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isReading ? null : _pick,
              icon: isReading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              label: Text(
                state is ScreenshotRecognised
                    ? l10n.screenshotChooseAnother
                    : l10n.screenshotChoose,
              ),
            ),
            if (isReading) ...[
              const SizedBox(height: 16),
              Text(
                l10n.screenshotReading,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (state is ScreenshotFailed) ...[
              const SizedBox(height: 16),
              _Banner(
                icon: Icons.error_outline,
                message: _errorText(l10n, state.failure),
                isError: true,
              ),
            ],
            if (state is ScreenshotRecognised) ...[
              const SizedBox(height: 24),
              if (state.wasEmpty)
                _Banner(
                  icon: Icons.search_off,
                  message: l10n.screenshotEmpty,
                  isError: false,
                )
              else ...[
                Text(
                  l10n.screenshotReviewTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.screenshotReviewBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              // Always editable: OCR gets Krio spellings and phone numbers
              // wrong often enough that the user must have the last word.
              TextField(
                controller: _text,
                maxLines: 10,
                minLines: 5,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.screenshotReviewTitle,
                ),
                onChanged: (value) => ref
                    .read(screenshotControllerProvider.notifier)
                    .updateText(value),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _text.text.trim().isEmpty ? null : _analyse,
                icon: const Icon(Icons.shield_outlined),
                label: Text(l10n.screenshotAnalyse),
              ),
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
                    l10n.screenshotPrivacyNote,
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

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.message,
    required this.isError,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError
        ? scheme.errorContainer
        : scheme.surfaceContainerHighest;
    final foreground = isError ? scheme.onErrorContainer : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}
