import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenAuditReportView extends StatelessWidget {
  final AuditReportPayload payload;
  final AIThemeData theme;

  const GenAuditReportView({
    super.key,
    required this.payload,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final score = payload.healthScore;
    final scoreColor = score >= 80
        ? theme.successColor
        : (score >= 60 ? theme.secondaryAccentColor : theme.primaryAccentColor);

    return AIGlassCard(
      theme: theme,
      margin: const EdgeInsets.symmetric(vertical: 8),
      borderColor: theme.secondaryAccentColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.assessment_rounded, color: scoreColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comprehensive Wealth Diagnostic',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Financial Health & Allocation Audit',
                      style: GoogleFonts.inter(fontSize: 11, color: theme.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scoreColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '/100',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Summary
          Text(
            payload.summary,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 14),

          // Strengths
          if (payload.strengths.isNotEmpty) ...[
            Text(
              'Key Strengths:',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: theme.successColor),
            ),
            const SizedBox(height: 4),
            ...payload.strengths.map((s) => _buildBullet(s, Icons.check_circle_outline_rounded, theme.successColor)),
            const SizedBox(height: 10),
          ],

          // Risks
          if (payload.risks.isNotEmpty) ...[
            Text(
              'Vulnerabilities & Drift:',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: theme.primaryAccentColor),
            ),
            const SizedBox(height: 4),
            ...payload.risks.map((r) => _buildBullet(r, Icons.warning_amber_rounded, theme.primaryAccentColor)),
            const SizedBox(height: 10),
          ],

          // Action Plan
          if (payload.actionPlan.isNotEmpty) ...[
            Text(
              'Actionable Next Steps:',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: theme.secondaryAccentColor),
            ),
            const SizedBox(height: 4),
            ...payload.actionPlan.map((a) => _buildBullet(a, Icons.arrow_right_alt_rounded, theme.secondaryAccentColor)),
            const SizedBox(height: 14),
          ],

          // Copy Markdown Button
          if (payload.rawMarkdown.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 34,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payload.rawMarkdown));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Audit Report copied to clipboard as Markdown!'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: theme.surfaceLightColor,
                    ),
                  );
                },
                icon: Icon(Icons.copy_rounded, size: 14, color: theme.textSecondaryColor),
                label: Text(
                  'Copy Report as Markdown',
                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.borderColor.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 11.5, color: theme.textSecondaryColor, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
