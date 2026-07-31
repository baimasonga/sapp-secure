import 'dart:convert';

import 'engine_strings.dart';
import 'models/risk_assessment.dart';
import 'models/risk_level.dart';
import 'models/scam_rule.dart';
import 'models/text_normaliser.dart';
import 'phone_number_extractor.dart';
import 'url_analyser.dart';

/// Extra facts the engine can use when the user has provided them.
///
/// Everything here is optional: the engine must produce a useful result for a
/// guest user who has pasted a message and nothing else.
class AnalysisContext {
  const AnalysisContext({
    this.senderNumber,
    this.trustedNumbersE164 = const {},
    this.reportedIndicators = const {},
  });

  /// The number the message came from, when the user tells us.
  final String? senderNumber;

  /// The user's trusted contacts, already normalised to E.164.
  final Set<String> trustedNumbersE164;

  /// Normalised indicators (numbers or hosts) previously reported by the
  /// community and cached on the device.
  final Set<String> reportedIndicators;

  static const AnalysisContext empty = AnalysisContext();
}

/// Deterministic, explainable scam-risk engine.
///
/// The same input always produces the same output: there is no model, no
/// randomness, and no network call. Every point in the score is attributable
/// to a named rule that the user can read and disagree with.
class RiskEngine {
  RiskEngine(List<ScamRule> rules)
    : _rules = List.unmodifiable(rules),
      _rulesById = {for (final rule in rules) rule.id: rule} {
    final ids = <String>{};
    for (final rule in rules) {
      if (!ids.add(rule.id)) {
        throw FormatException('Duplicate scam rule id: ${rule.id}');
      }
    }
  }

  final List<ScamRule> _rules;
  final Map<String, ScamRule> _rulesById;

  List<ScamRule> get rules => _rules;

  static const int maxScore = 100;

  /// Longer input is truncated before matching. A message far beyond this is
  /// not a WhatsApp message, and unbounded regex work is a denial-of-service
  /// risk on low-end devices.
  static const int maxAnalysedCharacters = 20000;

  /// Rule ids produced by analysers rather than by text matching.
  static const String ruleIdSuspiciousUrl = 'suspicious_url';
  static const String ruleIdReportedIndicator = 'reported_indicator';
  static const String ruleIdUnverifiedSender = 'unverified_sender';

  /// Builds an engine from the JSON shipped in
  /// `assets/scam_rules/initial_rules.json` (or fetched later from Supabase).
  factory RiskEngine.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Scam rules must be a JSON object.');
    }
    final rawRules = decoded['rules'];
    if (rawRules is! List) {
      throw const FormatException('Scam rules must contain a "rules" array.');
    }
    return RiskEngine([
      for (final rule in rawRules)
        ScamRule.fromJson(Map<String, dynamic>.from(rule as Map)),
    ]);
  }

  RiskAssessment analyse(
    String message, {
    String languageCode = EngineStrings.defaultLanguage,
    AnalysisContext context = AnalysisContext.empty,
    DateTime? now,
  }) {
    final truncated = message.length > maxAnalysedCharacters
        ? message.substring(0, maxAnalysedCharacters)
        : message;
    final normalised = TextNormaliser.normalise(truncated);

    final signals = <RiskSignal>[];
    var escalationFloor = 0;

    // 1. Pattern rules.
    for (final rule in _rules) {
      if (!rule.enabled || rule.derived) continue;
      final matches = rule.match(normalised);
      if (matches.isEmpty) continue;
      signals.add(
        _signalFor(
          rule,
          languageCode,
          matchedText: matches.first,
          matchCount: matches.length,
        ),
      );
      if (rule.escalationFloor > escalationFloor) {
        escalationFloor = rule.escalationFloor;
      }
    }

    // 2. Links.
    final urls = UrlAnalyser.extractUrls(
      truncated,
    ).map(UrlAnalyser.analyse).toList(growable: false);
    final suspiciousUrls = urls.where((url) => url.isSuspicious).toList();
    if (suspiciousUrls.isNotEmpty) {
      final rule = _rulesById[ruleIdSuspiciousUrl];
      if (rule != null && rule.enabled) {
        signals.add(
          _signalFor(
            rule,
            languageCode,
            matchedText: suspiciousUrls.first.host.isEmpty
                ? suspiciousUrls.first.original
                : suspiciousUrls.first.host,
            confidence: suspiciousUrls.any((url) => url.isHighlySuspicious)
                ? 0.9
                : 0.7,
          ),
        );
      }
    }

    // 3. Telephone numbers.
    final phoneNumbers = PhoneNumberExtractor.extract(truncated);

    // 4. Community-reported indicators cached on the device.
    final reportedHit = _firstReportedIndicator(context, phoneNumbers, urls);
    if (reportedHit != null) {
      final rule = _rulesById[ruleIdReportedIndicator];
      if (rule != null && rule.enabled) {
        signals.add(_signalFor(rule, languageCode, confidence: 0.85));
      }
    }

    // 5. Sender identity, only when the user told us who it is from.
    final sender = context.senderNumber == null
        ? null
        : PhoneNumberExtractor.normaliseSingle(context.senderNumber!);
    if (sender != null &&
        !context.trustedNumbersE164.contains(sender.normalised)) {
      final rule = _rulesById[ruleIdUnverifiedSender];
      if (rule != null && rule.enabled) {
        signals.add(_signalFor(rule, languageCode, confidence: 1.0));
      }
    }

    final rawScore = signals.fold<int>(
      0,
      (total, signal) => total + signal.weight,
    );
    final score = rawScore < escalationFloor
        ? escalationFloor.clamp(0, maxScore)
        : rawScore.clamp(0, maxScore);
    final level = RiskLevel.fromScore(score);

    return RiskAssessment(
      score: score,
      level: level,
      signals: List.unmodifiable(signals),
      phoneNumbers: List.unmodifiable(phoneNumbers),
      urls: List.unmodifiable(urls),
      recommendedActions: _recommendedActions(
        languageCode,
        level,
        signals,
        urls,
      ),
      summary: EngineStrings.summary(languageCode, level),
      limitations: _limitations(languageCode, phoneNumbers, urls),
      analysedAt: now ?? DateTime.now(),
    );
  }

  RiskSignal _signalFor(
    ScamRule rule,
    String languageCode, {
    String? matchedText,
    int matchCount = 1,
    double? confidence,
  }) {
    return RiskSignal(
      ruleId: rule.id,
      category: rule.category,
      weight: rule.weight,
      explanation: rule.explanation(languageCode),
      advice: rule.advice(languageCode),
      matchedText: matchedText,
      // Several independent phrasings of the same idea are stronger evidence
      // than one keyword that could be innocent.
      confidence: confidence ?? (0.6 + 0.1 * (matchCount - 1)).clamp(0.0, 0.95),
    );
  }

  String? _firstReportedIndicator(
    AnalysisContext context,
    List<ExtractedPhoneNumber> phoneNumbers,
    List<UrlAnalysis> urls,
  ) {
    if (context.reportedIndicators.isEmpty) return null;
    for (final number in phoneNumbers) {
      if (context.reportedIndicators.contains(number.normalised)) {
        return number.normalised;
      }
    }
    for (final url in urls) {
      if (url.host.isNotEmpty &&
          context.reportedIndicators.contains(url.host)) {
        return url.host;
      }
    }
    return null;
  }

  List<String> _recommendedActions(
    String languageCode,
    RiskLevel level,
    List<RiskSignal> signals,
    List<UrlAnalysis> urls,
  ) {
    final categories = signals.map((signal) => signal.category).toSet();
    final ruleIds = signals.map((signal) => signal.ruleId).toSet();
    final actions = <String>[];

    void add(String action) {
      if (!actions.contains(action)) actions.add(action);
    }

    if (ruleIds.contains('verification_code_request')) {
      add(EngineStrings.actionNeverShareCode(languageCode));
    }
    if (ruleIds.contains('qr_code_request')) {
      add(EngineStrings.actionDoNotScan(languageCode));
    }
    if (categories.contains('account_takeover')) {
      add(EngineStrings.actionCheckLinkedDevices(languageCode));
    }
    if (categories.contains('payment') ||
        categories.contains('fake_opportunity') ||
        level == RiskLevel.high ||
        level == RiskLevel.critical) {
      add(EngineStrings.actionDoNotSendMoney(languageCode));
    }
    if (categories.contains('impersonation') ||
        categories.contains('payment') ||
        categories.contains('identity')) {
      add(EngineStrings.actionCallKnownNumber(languageCode));
      add(EngineStrings.actionAskPrivateQuestion(languageCode));
    }
    if (urls.any((url) => url.isSuspicious)) {
      add(EngineStrings.actionDoNotOpenLink(languageCode));
    }
    if (categories.contains('pressure') || categories.contains('coercion')) {
      add(EngineStrings.actionTellSomeone(languageCode));
    }
    if (level == RiskLevel.high || level == RiskLevel.critical) {
      add(EngineStrings.actionReport(languageCode));
    }
    if (actions.isEmpty) {
      add(EngineStrings.actionKeepNormalCaution(languageCode));
    }
    return List.unmodifiable(actions);
  }

  List<String> _limitations(
    String languageCode,
    List<ExtractedPhoneNumber> phoneNumbers,
    List<UrlAnalysis> urls,
  ) {
    return List.unmodifiable([
      EngineStrings.limitationCannotVerifyIdentity(languageCode),
      EngineStrings.limitationLocalOnly(languageCode),
      EngineStrings.limitationNewScams(languageCode),
      if (urls.isNotEmpty) EngineStrings.limitationLinkNotOpened(languageCode),
      if (phoneNumbers.isNotEmpty)
        EngineStrings.limitationNumbersUnverified(languageCode),
    ]);
  }
}
