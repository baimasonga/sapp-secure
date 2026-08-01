import 'package:flutter/material.dart';

import '../../../../app/design/app_typography.dart';
import '../../../../app/design/design_tokens.dart';
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
///
/// The four-segment meter is deliberately banded rather than continuous. A
/// sliding bar invites the reader to compare 61 with 68; the bands say the
/// only thing the score actually means, which is which advice applies.
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
          padding: const EdgeInsets.all(DsSpace.x5),
          decoration: BoxDecoration(
            color: palette.container,
            borderRadius: DsRadius.all(DsRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(palette.icon, size: 26, color: palette.onContainer),
                  const SizedBox(width: DsSpace.x2_5),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: DsSpace.x0_5),
                      child: Text(
                        label,
                        style: AppType.subtitle.copyWith(
                          color: palette.onContainer,
                          fontWeight: AppType.bold,
                        ),
                      ),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$score',
                          style: AppType.score.copyWith(
                            color: palette.onContainer,
                          ),
                        ),
                        TextSpan(
                          text: '/100',
                          style: AppType.bodySm.copyWith(
                            color: palette.onContainer.withValues(alpha: 0.6),
                            fontWeight: AppType.semibold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsSpace.x4),
              RiskMeter(level: level),
              const SizedBox(height: DsSpace.x4),
              Text(
                summary,
                style: AppType.body.copyWith(color: palette.onContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four bars, one per band, filled up to the band the score landed in.
class RiskMeter extends StatelessWidget {
  const RiskMeter({super.key, required this.level});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reached = RiskLevel.values.indexOf(level);
    final onContainer = RiskPalette.of(context, level).onContainer;

    return Row(
      children: [
        for (final band in RiskLevel.values) ...[
          if (band != RiskLevel.low) const SizedBox(width: DsSpace.x1_5),
          Expanded(
            child: Builder(
              builder: (context) {
                final index = RiskLevel.values.indexOf(band);
                final lit = index <= reached;
                final isCurrent = index == reached;
                return Column(
                  children: [
                    AnimatedContainer(
                      duration: DsMotion.base,
                      curve: DsMotion.ease,
                      height: 7,
                      decoration: BoxDecoration(
                        color: lit
                            ? RiskPalette.of(context, band).accent
                            : onContainer.withValues(alpha: 0.14),
                        borderRadius: DsRadius.all(DsRadius.xs),
                      ),
                    ),
                    const SizedBox(height: DsSpace.x1_5),
                    Text(
                      band.shortLabel(l10n),
                      style: AppType.caption.copyWith(
                        fontSize: 11,
                        color: onContainer.withValues(
                          alpha: isCurrent ? 1 : 0.55,
                        ),
                        fontWeight: isCurrent ? AppType.bold : AppType.medium,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
