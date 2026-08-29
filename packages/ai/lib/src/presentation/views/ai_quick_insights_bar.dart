import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/contracts/ai_portfolio_contract.dart';
import '../widgets/ai_glass_card.dart';

class AIQuickInsightsBar extends StatelessWidget {
  final AIThemeData theme;
  final ValueChanged<String> onPromptTriggered;
  final VoidCallback? onOpenCopilot;

  const AIQuickInsightsBar({
    super.key,
    required this.theme,
    required this.onPromptTriggered,
    this.onOpenCopilot,
  });

  @override
  Widget build(BuildContext context) {
    return AIGlassCard(
      theme: theme,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isCompact = constraints.maxWidth < 600;

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryAccentColor, theme.secondaryAccentColor],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              if (!isCompact) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AI Wealth Copilot',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Instant advisory & simulations',
                      style: GoogleFonts.inter(fontSize: 10, color: theme.textSecondaryColor),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('📊 Full Health Audit', 'Run a comprehensive wealth health audit and diagnostic review.'),
                      _buildChip('🎯 Rebalance for FIRE', 'Analyze my asset allocation drift and recommend a rebalancing plan for my FIRE goal.'),
                      _buildChip('🛡️ Stress Test Crashes', 'Stress test my portfolio against a 2008-style market crash and stagflation.'),
                      _buildChip('📈 What-If Simulator', 'Open the interactive scenario simulator for my net worth compounding.'),
                    ],
                  ),
                ),
              ),
              if (onOpenCopilot != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded, color: theme.secondaryAccentColor, size: 14),
                  tooltip: 'Open AI Copilot',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onOpenCopilot,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onPromptTriggered(prompt),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.surfaceLightColor.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
