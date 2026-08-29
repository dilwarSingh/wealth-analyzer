import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenGoalRebalanceCard extends StatelessWidget {
  final GoalRebalancePayload payload;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;
  final AIPortfolioActionDelegate? actionDelegate;
  final VoidCallback? onApplied;

  const GenGoalRebalanceCard({
    super.key,
    required this.payload,
    required this.theme,
    this.currencyDelegate,
    this.actionDelegate,
    this.onApplied,
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.secondaryAccentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.balance_rounded, color: theme.secondaryAccentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal Rebalancing Plan: ${payload.goalName}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    if (payload.targetAmount > 0)
                      Text(
                        'Target: ${compact(payload.targetAmount)} in ${payload.targetYears} Years',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (payload.isApplied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.successColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: theme.successColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Applied ✓',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Rebalancing Action Deltas
          if (payload.deltas.isNotEmpty) ...[
            Text(
              'Required Adjustments (Asset Drift):',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...payload.deltas.map((d) => _buildDeltaItem(d, compact)),
            const SizedBox(height: 12),
          ],

          // SIP Inflow Rebalance Advice Box
          if (payload.sipRerouteAdvice.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surfaceLightColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.secondaryAccentColor.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_rounded, color: theme.secondaryAccentColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payload.sipRerouteAdvice,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        height: 1.4,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 1-Tap Action Button
          if (payload.deltas.isNotEmpty && !payload.isApplied) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (actionDelegate != null) {
                    final success = await actionDelegate!.onRebalance(payload.deltas);
                    if (success && onApplied != null) {
                      onApplied!();
                    }
                  }
                },
                icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.black),
                label: Text(
                  'Apply Rebalancing Strategy',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.secondaryAccentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeltaItem(AIAssetRebalanceDelta delta, String Function(double) compact) {
    final isBuy = delta.action == 'buy';
    final badgeColor = isBuy ? theme.successColor : theme.primaryAccentColor;

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: badgeColor.withOpacity(0.4)),
              ),
              child: Text(
                delta.action.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delta.assetName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${delta.currentAllocationPercent}% → ${delta.targetAllocationPercent}% Target',
                    style: GoogleFonts.inter(fontSize: 10, color: theme.textMutedColor),
                  ),
                ],
              ),
            ),
            Text(
              '${isBuy ? '+' : '-'}${compact(delta.recommendedAmountDelta)}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
