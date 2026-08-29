import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenActionConfirmationCard extends StatelessWidget {
  final ActionConfirmationPayload payload;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;
  final AIPortfolioActionDelegate? actionDelegate;
  final VoidCallback? onApplied;

  const GenActionConfirmationCard({
    super.key,
    required this.payload,
    required this.theme,
    this.currencyDelegate,
    this.actionDelegate,
    this.onApplied,
  });

  @override
  Widget build(BuildContext context) {
    final asset = payload.assetToAdd;
    final compact = currencyDelegate != null
        ? currencyDelegate!.compactAmount
        : (double v) => '₹${v.toStringAsFixed(0)}';

    return AIGlassCard(
      theme: theme,
      margin: const EdgeInsets.symmetric(vertical: 8),
      borderColor: theme.secondaryAccentColor.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.secondaryAccentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_task_rounded, color: theme.secondaryAccentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payload.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    if (payload.description.isNotEmpty)
                      Text(
                        payload.description,
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
                        'Added ✓',
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
          if (asset != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.surfaceLightColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '${asset.category.displayName} • ${asset.expectedReturnPercent}% Return',
                          style: GoogleFonts.inter(fontSize: 11, color: theme.textMutedColor),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    compact(asset.currentValue),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.secondaryAccentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!payload.isApplied && asset != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (actionDelegate != null) {
                    final success = await actionDelegate!.onAddAsset(asset);
                    if (success && onApplied != null) {
                      onApplied!();
                    }
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Confirm & Add to Portfolio',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryAccentColor,
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
}
