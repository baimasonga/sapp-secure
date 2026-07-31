import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              l10n.analyseInstruction,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 4),
            Text(
              l10n.analyseCharacterCount(
                _controller.text.length,
                AnalysisController.maxInputLength,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (state is AnalysisFailed) ...[
              const SizedBox(height: 12),
              _InlineError(message: _errorText(l10n, state.failure)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRunning ? null : _paste,
                    icon: const Icon(Icons.content_paste),
                    label: Text(l10n.analysePaste),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRunning || _controller.text.isEmpty
                        ? null
                        : () => setState(_controller.clear),
                    icon: const Icon(Icons.backspace_outlined),
                    label: Text(l10n.analyseClear),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isRunning ? null : _analyse,
              icon: isRunning
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shield_outlined),
              label: Text(l10n.analyseRun),
            ),
            const SizedBox(height: 20),
            _PrivacyNote(text: l10n.analysePrivacyNote),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

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
