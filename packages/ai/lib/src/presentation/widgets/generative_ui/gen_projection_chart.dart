import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenProjectionChart extends StatelessWidget {
  final ProjectionChartPayload payload;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;

  const GenProjectionChart({
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
    final baseline = payload.baselineCurve;
    final optimistic = payload.optimisticCurve;
    final pessimistic = payload.pessimisticCurve;

    final spotsBaseline = List.generate(
      baseline.length,
      (i) => FlSpot(i < years.length ? years[i].toDouble() : i.toDouble(), baseline[i]),
    );

    final spotsOptimistic = optimistic != null
        ? List.generate(
            optimistic.length,
            (i) => FlSpot(i < years.length ? years[i].toDouble() : i.toDouble(), optimistic[i]),
          )
        : null;

    final spotsPessimistic = pessimistic != null
        ? List.generate(
            pessimistic.length,
            (i) => FlSpot(i < years.length ? years[i].toDouble() : i.toDouble(), pessimistic[i]),
          )
        : null;

    return AIGlassCard(
      theme: theme,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: theme.secondaryAccentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Wealth Trajectory Projection',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              if (baseline.isNotEmpty)
                Text(
                  'End: ${compact(baseline.last)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.secondaryAccentColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
                  if (spotsOptimistic != null)
                    LineChartBarData(
                      spots: spotsOptimistic,
                      isCurved: true,
                      color: theme.successColor.withOpacity(0.6),
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    ),
                  LineChartBarData(
                    spots: spotsBaseline,
                    isCurved: true,
                    color: theme.secondaryAccentColor,
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.secondaryAccentColor.withOpacity(0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                  if (spotsPessimistic != null)
                    LineChartBarData(
                      spots: spotsPessimistic,
                      isCurved: true,
                      color: theme.primaryAccentColor.withOpacity(0.6),
                      barWidth: 1.5,
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
