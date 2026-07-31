import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/risk_engine/models/risk_level.dart';

/// Localised names for a risk band, kept in one place so the score, the badge
/// and the screen reader always say the same thing.
extension RiskLevelL10n on RiskLevel {
  String label(AppLocalizations l10n) => switch (this) {
    RiskLevel.low => l10n.riskLevelLow,
    RiskLevel.caution => l10n.riskLevelCaution,
    RiskLevel.high => l10n.riskLevelHigh,
    RiskLevel.critical => l10n.riskLevelCritical,
  };

  String shortLabel(AppLocalizations l10n) => switch (this) {
    RiskLevel.low => l10n.riskLevelLowShort,
    RiskLevel.caution => l10n.riskLevelCautionShort,
    RiskLevel.high => l10n.riskLevelHighShort,
    RiskLevel.critical => l10n.riskLevelCriticalShort,
  };
}

/// The headline result: icon, words, and score together — never colour alone
/// (sections 22 and 28).
class RiskLevelBanner extends StatelessWidget {
  const RiskLevelBanner({
    super.key,
    required this.level,
    required this.score,
    required this.summary,
  });

  final RiskLevel level;
  final int score;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = RiskPalette.of(context, level);
    final label = level.label(l10n);
    final scoreLabel = l10n.resultScoreLabel(score);

    return Semantics(
      container: true,
      label: '$label. $scoreLabel. $summary',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.container,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.accent, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(palette.icon, size: 40, color: palette.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: palette.onContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                scoreLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: palette.onContainer),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 10,
                  backgroundColor: palette.onContainer.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                summary,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: palette.onContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
