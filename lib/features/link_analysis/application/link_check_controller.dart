import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../services/risk_engine/url_analyser.dart';

sealed class LinkCheckState {
  const LinkCheckState();
}

class LinkCheckIdle extends LinkCheckState {
  const LinkCheckIdle();
}

class LinkCheckDone extends LinkCheckState {
  const LinkCheckDone(this.analysis);

  final UrlAnalysis analysis;
}

class LinkCheckFailed extends LinkCheckState {
  const LinkCheckFailed(this.failure);

  final AppFailure failure;
}

/// Checks a single link, entirely on the device.
///
/// Nothing is sent to a reputation service: that stays optional and off
/// (section 12), and the message the link came from is never involved.
class LinkCheckController extends StateNotifier<LinkCheckState> {
  LinkCheckController() : super(const LinkCheckIdle());

  /// A URL far longer than this is not something a person is going to read.
  static const int maxLength = 2000;

  void check(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      state = const LinkCheckFailed(ValidationFailure(field: 'url'));
      return;
    }
    if (trimmed.length > maxLength) {
      state = const LinkCheckFailed(
        ValidationFailure(field: 'url', debugMessage: 'input too long'),
      );
      return;
    }

    // Accept a whole message pasted in, not just a bare URL: people paste what
    // they have. The first link found is the one checked.
    final extracted = UrlAnalyser.extractUrls(trimmed);
    final candidate = extracted.isNotEmpty ? extracted.first : trimmed;

    // With nothing link-shaped to work with, say so rather than analysing a
    // sentence and reporting confident nonsense about it.
    if (extracted.isEmpty && !_looksLikeUrl(candidate)) {
      state = const LinkCheckFailed(ValidationFailure(field: 'url'));
      return;
    }

    final analysis = UrlAnalyser.analyse(candidate);
    if (analysis.host.isEmpty || !analysis.host.contains('.')) {
      state = const LinkCheckFailed(ValidationFailure(field: 'url'));
      return;
    }
    state = LinkCheckDone(analysis);
  }

  /// A bare host or an unusual scheme the extractor does not recognise still
  /// deserves a check; a sentence does not.
  static bool _looksLikeUrl(String value) =>
      !value.contains(RegExp(r'\s')) && value.contains('.');

  void reset() => state = const LinkCheckIdle();
}

final linkCheckControllerProvider =
    StateNotifierProvider<LinkCheckController, LinkCheckState>(
      (ref) => LinkCheckController(),
    );
