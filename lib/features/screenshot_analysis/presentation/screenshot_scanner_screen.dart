import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/ds_components.dart';
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
          padding: const EdgeInsets.fromLTRB(
            DsSpace.screenGutter,
            DsSpace.x4,
            DsSpace.screenGutter,
            DsSpace.x8,
          ),
          children: [
            Text(
              l10n.screenshotIntro,
              style: AppType.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DsSpace.x5),
            FilledButton.icon(
              onPressed: isReading ? null : _pick,
              icon: isReading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined, size: 20),
              label: Text(
                state is ScreenshotRecognised
                    ? l10n.screenshotChooseAnother
                    : l10n.screenshotChoose,
              ),
            ),
            if (isReading) ...[
              const SizedBox(height: DsSpace.x4),
              Text(
                l10n.screenshotReading,
                textAlign: TextAlign.center,
                style: AppType.bodySm.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (state is ScreenshotFailed) ...[
              const SizedBox(height: DsSpace.x4),
              DsNotice(
                icon: Icons.error_outline,
                tone: DsNoticeTone.danger,
                text: _errorText(l10n, state.failure),
              ),
            ],
            if (state is ScreenshotRecognised) ...[
              const SizedBox(height: DsSpace.x6),
              if (state.wasEmpty)
                DsNotice(icon: Icons.search_off, text: l10n.screenshotEmpty)
              else ...[
                DsSectionLabel(l10n.screenshotReviewTitle),
                Text(
                  l10n.screenshotReviewBody,
                  style: AppType.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: DsSpace.x3),
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
              const SizedBox(height: DsSpace.x4),
              FilledButton.icon(
                onPressed: _text.text.trim().isEmpty ? null : _analyse,
                icon: const Icon(Icons.shield_outlined, size: 20),
                label: Text(l10n.screenshotAnalyse),
              ),
            ],
            const SizedBox(height: DsSpace.x6),
            DsNotice(text: l10n.screenshotPrivacyNote),
          ],
        ),
      ),
    );
  }
}
