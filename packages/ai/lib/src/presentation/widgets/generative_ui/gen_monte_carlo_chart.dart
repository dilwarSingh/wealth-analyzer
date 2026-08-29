import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenMonteCarloChart extends StatelessWidget {
  final MonteCarloCurvePayload payload;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;

  const GenMonteCarloChart({
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

    final years = payload.years;
    final spotsP10 = List.generate(
      payload.p10Curve.length,
      (i) => FlSpot(i < years.length ? years[i].toDouble() : i.toDouble(), payload.p10Curve[i]),
    );
    final spotsP50 = List.generate(
      payload.p50Curve.length,
      (i) => FlSpot(i < years.length ? years[i].toDouble() : i.toDouble(), payload.p50Curve[i]),
    );
    final spotsP90 = List.generate(
      payload.p90Curve.length,
      (i) => FlSpot(i < years.length ? years[i].toDouble() : i.toDouble(), payload.p90Curve[i]),
    );

    return AIGlassCard(
      theme: theme,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.casino_rounded, color: theme.secondaryAccentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Monte Carlo Simulation (${payload.simulationsCount} Trials)',
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
                  color: theme.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.successColor.withOpacity(0.4)),
                ),
                child: Text(
                  '${payload.probabilityOfSuccess.toStringAsFixed(1)}% Success',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
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
                    spots: spotsP90,
                    isCurved: true,
                    color: theme.successColor.withOpacity(0.5),
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: spotsP50,
                    isCurved: true,
                    color: theme.secondaryAccentColor,
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.secondaryAccentColor.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: spotsP10,
                    isCurved: true,
                    color: theme.primaryAccentColor.withOpacity(0.6),
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(theme.successColor, '90th Pct (Optimistic)'),
              const SizedBox(width: 14),
              _legendDot(theme.secondaryAccentColor, '50th Pct (Median)'),
              const SizedBox(width: 14),
              _legendDot(theme.primaryAccentColor, '10th Pct (Conservative)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: theme.textSecondaryColor),
        ),
      ],
    );
  }
}
