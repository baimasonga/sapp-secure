import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';
import '../application/analysis_controller.dart';

/// Paste-and-analyse (section 7.6). Deliberately one screen, one field, one
/// primary button.
class AnalyseMessageScreen extends ConsumerStatefulWidget {
  const AnalyseMessageScreen({super.key, this.initialText});

  /// Text handed over by the Android share sheet.
  final String? initialText;

  @override
  ConsumerState<AnalyseMessageScreen> createState() =>
      _AnalyseMessageScreenState();
}

class _AnalyseMessageScreenState extends ConsumerState<AnalyseMessageScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText ?? '',
  );

  @override
  void dispose() {
    // Clearing before disposal keeps the pasted message out of any retained
    // text-editing buffer for longer than necessary.
    _controller.clear();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (text == null || text.trim().isEmpty) {
      _showMessage(l10n.analyseNothingToPaste);
      return;
    }
    setState(() => _controller.text = text);
  }

  Future<void> _analyse() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(analysisControllerProvider.notifier)
        .analyse(_controller.text);
    if (!mounted) return;
    final state = ref.read(analysisControllerProvider);
    if (state is AnalysisSuccess) {
      context.pushNamed(AppRoute.analysisResult.name);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _errorText(AppLocalizations l10n, AppFailure failure) =>
      switch (failure) {
        ValidationFailure(debugMessage: 'input too long') =>
          l10n.analyseTooLongError,
        ValidationFailure() => l10n.analyseEmptyError,
        AnalysisFailure() => l10n.errorRulesFailed,
        _ => l10n.errorGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(analysisControllerProvider);
    final isRunning = state is AnalysisRunning;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyseTitle)),
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
              l10n.analyseInstruction,
              style: AppType.subtitle.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: DsSpace.x3),
            TextField(
              controller: _controller,
              maxLines: 10,
              minLines: 6,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.multiline,
              maxLength: AnalysisController.maxInputLength,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              decoration: InputDecoration(
                hintText: l10n.analyseHint,
                labelText: l10n.analyseTitle,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DsSpace.x2),
            Text(
              l10n.analyseCharacterCount(
                _controller.text.length,
                AnalysisController.maxInputLength,
              ),
              style: AppType.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (state is AnalysisFailed) ...[
              const SizedBox(height: DsSpace.x3),
              DsNotice(
                text: _errorText(l10n, state.failure),
                icon: Icons.error_outline,
                tone: DsNoticeTone.danger,
              ),
            ],
            const SizedBox(height: DsSpace.x4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRunning ? null : _paste,
                    icon: const Icon(Icons.content_paste, size: 20),
                    label: Text(l10n.analysePaste),
                  ),
                ),
                const SizedBox(width: DsSpace.x3),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRunning || _controller.text.isEmpty
                        ? null
                        : () => setState(_controller.clear),
                    icon: const Icon(Icons.backspace_outlined, size: 20),
                    label: Text(l10n.analyseClear),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpace.x3),
            FilledButton.icon(
              onPressed: isRunning ? null : _analyse,
              icon: isRunning
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shield_outlined, size: 20),
              label: Text(l10n.analyseRun),
            ),
            const SizedBox(height: DsSpace.x5),
            DsNotice(text: l10n.analysePrivacyNote),
          ],
        ),
      ),
    );
  }
}
