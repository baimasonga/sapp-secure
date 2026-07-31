/// Risk bands used across the application.
///
/// Thresholds are defined once here so the UI, the engine and the tests can
/// never disagree about what a score means.
enum RiskLevel {
  low,
  caution,
  high,
  critical;

  /// Inclusive lower bound of the band.
  int get minScore => switch (this) {
    RiskLevel.low => 0,
    RiskLevel.caution => 25,
    RiskLevel.high => 50,
    RiskLevel.critical => 75,
  };

  /// Stable identifier for storage, analytics and localisation keys.
  String get id => name;

  /// Maps a clamped 0–100 score onto a band.
  static RiskLevel fromScore(int score) {
    if (score >= RiskLevel.critical.minScore) return RiskLevel.critical;
    if (score >= RiskLevel.high.minScore) return RiskLevel.high;
    if (score >= RiskLevel.caution.minScore) return RiskLevel.caution;
    return RiskLevel.low;
  }

  static RiskLevel fromId(String id) => RiskLevel.values.firstWhere(
    (level) => level.name == id,
    orElse: () => RiskLevel.caution,
  );
}
