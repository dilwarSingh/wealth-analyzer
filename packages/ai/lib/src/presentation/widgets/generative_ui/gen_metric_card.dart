import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenMetricCard extends StatelessWidget {
  final KpiMetricPayload payload;
  final AIThemeData theme;

  const GenMetricCard({
    super.key,
    required this.payload,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AIGlassCard(
      theme: theme,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryAccentColor.withOpacity(0.2),
                  theme.secondaryAccentColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.secondaryAccentColor.withOpacity(0.3)),
            ),
            child: Icon(Icons.auto_graph_rounded, color: theme.secondaryAccentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  payload.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payload.value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.textPrimaryColor,
                  ),
                ),
                if (payload.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    payload.subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.textMutedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (payload.trendLabel != null || payload.changePercent != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (payload.isPositive ? theme.successColor : theme.primaryAccentColor).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (payload.isPositive ? theme.successColor : theme.primaryAccentColor).withOpacity(0.3),
                ),
              ),
              child: Text(
                payload.trendLabel ?? '${payload.changePercent! > 0 ? '+' : ''}${payload.changePercent!.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: payload.isPositive ? theme.successColor : theme.primaryAccentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
