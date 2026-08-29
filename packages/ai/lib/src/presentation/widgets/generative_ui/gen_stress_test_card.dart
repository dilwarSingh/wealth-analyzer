import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenStressTestCard extends StatelessWidget {
  final StressTestResultPayload payload;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;

  const GenStressTestCard({
    super.key,
    required this.payload,
    required this.theme,
    this.currencyDelegate,
  });

  @override
  Widget build(BuildContext context) {
    final compact = currencyDelegate != null
        ? currencyDelegate!.compactAmount
        : (double v) => '₹${v.toStringAsFixed(0)}';

    return AIGlassCard(
      theme: theme,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.primaryAccentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield_rounded, color: theme.primaryAccentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Historical Market Crash Stress Test',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.secondaryAccentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.secondaryAccentColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Score: ${payload.overallResilienceScore.toStringAsFixed(0)}/100',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.secondaryAccentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...payload.scenarios.map((s) => _buildScenarioRow(s, compact)),
          if (payload.commentary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              payload.commentary,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: theme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScenarioRow(StressTestScenarioItem scenario, String Function(double) compact) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.surfaceLightColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.borderColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    'Market: ${scenario.marketDropPercent.toStringAsFixed(0)}% | Recovery: ${scenario.recoveryMonths}',
                    style: GoogleFonts.inter(fontSize: 10, color: theme.textMutedColor),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${scenario.portfolioImpactPercent.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: theme.primaryAccentColor,
                  ),
                ),
                if (scenario.projectedLossAmount > 0)
                  Text(
                    '-${compact(scenario.projectedLossAmount)}',
                    style: GoogleFonts.inter(fontSize: 10, color: theme.textMutedColor),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
