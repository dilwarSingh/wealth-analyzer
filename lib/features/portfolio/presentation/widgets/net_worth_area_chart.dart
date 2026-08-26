import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_container.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/projection_viewmodel.dart';

class NetWorthAreaChart extends ConsumerWidget {
  const NetWorthAreaChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projState = ref.watch(projectionProvider);
    final currency = ref.watch(currencyProvider);
    final points = projState.simulationResult.points;

    // Filter points according to selected timeframe
    final int limitYears = projState.selectedTimeframe.years;
    final List pointsToDisplay = (limitYears > 0 && points.length > limitYears + 1)
        ? points.sublist(0, limitYears + 1)
        : points;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Timeframe Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.show_chart_rounded, size: 20, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'NET WORTH TRAJECTORY',
                        style: AppTypography.heading3.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Timeframe Buttons
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ChartTimeframe.values.map((tf) {
                    final isSelected = projState.selectedTimeframe == tf;
                    return InkWell(
                      onTap: () => ref.read(projectionProvider.notifier).setTimeframe(tf),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.gold : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          tf.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.black : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Compound portfolio growth forecast based on individual asset CAGRs and SIP step-up.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),
          if (pointsToDisplay.isEmpty)
            Container(
              height: 240,
              alignment: Alignment.center,
              child: Text(
                'Add investments to plot your net worth trajectory.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            )
          else ...[
            Builder(builder: (context) {
              double maxVal = 0.0;
              for (final p in pointsToDisplay) {
                if (p.baseValue > maxVal) maxVal = p.baseValue;
                if (p.totalInvested > maxVal) maxVal = p.totalInvested;
              }
              final effectiveMaxY = maxVal > 0 ? (maxVal * 1.25) : 100000.0;
              final interval = (effectiveMaxY / 4).clamp(1.0, double.infinity);

              return SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: effectiveMaxY,
                    clipData: const FlClipData.none(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppColors.border.withOpacity(0.6),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 16,
                          getTitlesWidget: _emptyTitleWidget,
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: (pointsToDisplay.length / 5).clamp(1.0, 10.0),
                          getTitlesWidget: (value, meta) {
                            final int idx = value.toInt();
                            if (idx < 0 || idx >= pointsToDisplay.length) {
                              return const SizedBox.shrink();
                            }
                            final p = pointsToDisplay[idx];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Age ${p.age}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 56,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              CurrencyFormatter.formatCompact(value, currency: currency, includeDecimals: false),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        maxContentWidth: 260,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        getTooltipColor: (_) => AppColors.surfaceCard.withOpacity(0.95),
                        tooltipBorder: const BorderSide(color: AppColors.gold, width: 1),
                        tooltipBorderRadius: const BorderRadius.all(Radius.circular(8)),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            if (idx < 0 || idx >= pointsToDisplay.length) return null;
                            final p = pointsToDisplay[idx];
                            final isBase = spot.barIndex == 0;
                            return LineTooltipItem(
                              isBase
                                  ? 'Age ${p.age} (Yr ${p.year})\nNet Worth: ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}'
                                  : 'Capital Invested: ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}',
                              GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isBase ? AppColors.goldLight : AppColors.textSecondary,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Line 1: Gold Gradient Base Net Worth Area
                      LineChartBarData(
                        spots: List.generate(pointsToDisplay.length, (i) {
                          return FlSpot(i.toDouble(), pointsToDisplay[i].baseValue);
                        }),
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: AppColors.gold,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.gold.withOpacity(0.35),
                              AppColors.gold.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      // Line 2: Invested Capital Baseline (Dashed Slate)
                      LineChartBarData(
                        spots: List.generate(pointsToDisplay.length, (i) {
                          return FlSpot(i.toDouble(), pointsToDisplay[i].totalInvested);
                        }),
                        isCurved: true,
                        curveSmoothness: 0.2,
                        color: AppColors.textSecondary.withOpacity(0.7),
                        barWidth: 2,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendPill('Projected Net Worth', AppColors.gold, isSolid: true),
              const SizedBox(width: 20),
              _buildLegendPill('Cumulative Capital Invested', AppColors.textSecondary, isSolid: false),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _emptyTitleWidget(double value, TitleMeta meta) => const SizedBox.shrink();

  Widget _buildLegendPill(String label, Color color, {required bool isSolid}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
