import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenSwpChart extends StatelessWidget {
  final SwpCashFlowPayload payload;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;

  const GenSwpChart({
    super.key,
    required this.payload,
    required this.theme,
    this.currencyDelegate,
  });

  @override
  Widget build(BuildContext context) {
    final compact = currencyDelegate != null
        ? currencyDelegate!.compactAmount
        : (double v) => '${payload.currencySymbol}${v.toStringAsFixed(0)}';

    final curve = payload.remainingCorpusOverTime;
    final spots = List.generate(curve.length, (i) => FlSpot(i.toDouble(), curve[i]));

    return AIGlassCard(
      theme: theme,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: theme.secondaryAccentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'SWP Retirement Cash Flow Longevity',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (payload.isPerpetual ? theme.successColor : theme.primaryAccentColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (payload.isPerpetual ? theme.successColor : theme.primaryAccentColor).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  payload.isPerpetual ? 'Perpetual Runway ✓' : 'Depletion in Y${payload.depletionYear ?? 25}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: payload.isPerpetual ? theme.successColor : theme.primaryAccentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.borderColor.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, meta) => Text(
                        compact(val),
                        style: GoogleFonts.inter(fontSize: 9, color: theme.textMutedColor),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) => Text(
                        'Y${val.toInt()}',
                        style: GoogleFonts.inter(fontSize: 10, color: theme.textSecondaryColor),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: payload.isPerpetual ? theme.successColor : theme.primaryAccentColor,
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: (payload.isPerpetual ? theme.successColor : theme.primaryAccentColor).withOpacity(0.15),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
