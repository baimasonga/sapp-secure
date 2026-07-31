import '../phone_number_extractor.dart';
import '../url_analyser.dart';
import 'risk_level.dart';

/// One triggered rule, with everything the user needs to judge it themselves.
class RiskSignal {
  const RiskSignal({
    required this.ruleId,
    required this.category,
    required this.weight,
    required this.explanation,
    required this.advice,
    required this.confidence,
    this.matchedText,
  });

  final String ruleId;
  final String category;
  final int weight;

  /// Why this matters, in the user's language.
  final String explanation;

  /// What to do about it, in the user's language.
  final String advice;

  /// The exact words that triggered the rule, so the user can disagree with
  /// the app. Null for signals not derived from message text.
  final String? matchedText;

  /// 0.0–1.0. Multiple independent matches raise confidence; a single generic
  /// keyword does not.
  final double confidence;
}

/// The complete, explainable result of analysing one message.
class RiskAssessment {
  const RiskAssessment({
    required this.score,
    required this.level,
    required this.signals,
    required this.phoneNumbers,
    required this.urls,
    required this.recommendedActions,
    required this.summary,
    required this.limitations,
    required this.analysedAt,
  });

  final int score;
  final RiskLevel level;
  final List<RiskSignal> signals;
  final List<ExtractedPhoneNumber> phoneNumbers;
  final List<UrlAnalysis> urls;
  final List<String> recommendedActions;

  /// Plain-language sentence shown above the detail.
  final String summary;

  /// What the app could *not* check. Section 9.5 requires this to be shown so
  /// a Low result is never mistaken for a guarantee of safety.
  final List<String> limitations;

  final DateTime analysedAt;

  bool get hasSignals => signals.isNotEmpty;

  /// Metadata-only view, safe to persist locally. Deliberately excludes the
  /// message text, matched excerpts, and full numbers or links.
  Map<String, Object?> toMetadataJson() => {
    'score': score,
    'level': level.id,
    'rule_ids': signals.map((signal) => signal.ruleId).toList(),
    'phone_number_count': phoneNumbers.length,
    'url_count': urls.length,
    'analysed_at': analysedAt.toIso8601String(),
  };
}
