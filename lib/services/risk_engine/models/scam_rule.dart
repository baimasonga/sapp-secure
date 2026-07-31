import 'text_normaliser.dart';

/// A single, editable detection rule.
///
/// Rules are data, not code: they are loaded from
/// `assets/scam_rules/initial_rules.json` and may later be refreshed from
/// Supabase. Every field that reaches the user is localised at rule level so a
/// mixed English/Krio message is scored once and explained in the user's
/// chosen language.
class ScamRule {
  ScamRule({
    required this.id,
    required this.category,
    required this.weight,
    required this.enabled,
    required this.patterns,
    required Map<String, String> explanations,
    required Map<String, String> advice,
    this.escalationFloor = 0,
    this.derived = false,
  }) : _explanations = Map.unmodifiable(explanations),
       _advice = Map.unmodifiable(advice),
       _matchers = List.unmodifiable(
         patterns.map(PatternMatcher.new).toList(growable: false),
       );

  final String id;
  final String category;
  final int weight;
  final bool enabled;
  final List<String> patterns;

  /// When this rule fires, the total score is raised to at least this value.
  ///
  /// Used for account-takeover rules where a single signal is decisive: a
  /// verification-code request is critical even when nothing else matches.
  final int escalationFloor;

  /// Derived rules are produced by dedicated analysers (links, community
  /// indicators, sender identity) rather than by text pattern matching.
  final bool derived;

  final Map<String, String> _explanations;
  final Map<String, String> _advice;
  final List<PatternMatcher> _matchers;

  static const String fallbackLanguage = 'en';

  String explanation(String languageCode) =>
      _explanations[languageCode] ?? _explanations[fallbackLanguage] ?? id;

  String advice(String languageCode) =>
      _advice[languageCode] ?? _advice[fallbackLanguage] ?? '';

  /// Returns every pattern that matched, in rule order, against
  /// already-normalised text.
  List<String> match(String normalisedText) {
    if (!enabled || derived) return const [];
    final matches = <String>[];
    for (final matcher in _matchers) {
      final matched = matcher.firstMatch(normalisedText);
      if (matched != null) matches.add(matched);
    }
    return matches;
  }

  factory ScamRule.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Scam rule is missing a string "id".');
    }
    final weight = json['weight'];
    if (weight is! int || weight < 0 || weight > 100) {
      throw FormatException('Rule "$id" has an invalid weight: $weight');
    }
    return ScamRule(
      id: id,
      category: json['category'] as String? ?? 'other',
      weight: weight,
      enabled: json['enabled'] as bool? ?? true,
      derived: json['derived'] as bool? ?? false,
      escalationFloor: json['escalation_floor'] as int? ?? 0,
      patterns: <String>[
        for (final pattern in (json['patterns'] as List<dynamic>? ?? const []))
          if (pattern is String && pattern.trim().isNotEmpty)
            TextNormaliser.normalise(pattern),
      ],
      explanations: _localisedMap(json['explanation']),
      advice: _localisedMap(json['advice']),
    );
  }

  static Map<String, String> _localisedMap(Object? raw) {
    if (raw is String) return {fallbackLanguage: raw};
    if (raw is Map) {
      return {
        for (final entry in raw.entries)
          if (entry.value is String)
            entry.key.toString(): entry.value as String,
      };
    }
    return const {};
  }
}

/// Matches one pattern against normalised text using word-ish boundaries.
///
/// Plain substring matching produces embarrassing false positives ("urgent"
/// inside "insurgent", "otp" inside a random token), so a pattern only matches
/// when it is not glued to another letter or digit.
class PatternMatcher {
  PatternMatcher(this.pattern) : _regExp = _build(pattern);

  final String pattern;
  final RegExp _regExp;

  static RegExp _build(String pattern) {
    final escaped = RegExp.escape(pattern);
    final prefix = _startsWithWordChar(pattern) ? r'(?<![\w])' : '';
    final suffix = _endsWithWordChar(pattern) ? r'(?![\w])' : '';
    return RegExp('$prefix$escaped$suffix', caseSensitive: false);
  }

  static bool _startsWithWordChar(String value) =>
      value.isNotEmpty && RegExp(r'\w').hasMatch(value[0]);

  static bool _endsWithWordChar(String value) =>
      value.isNotEmpty && RegExp(r'\w').hasMatch(value[value.length - 1]);

  /// Returns the matched text, or null when the pattern is absent.
  String? firstMatch(String normalisedText) =>
      _regExp.firstMatch(normalisedText)?.group(0);
}
