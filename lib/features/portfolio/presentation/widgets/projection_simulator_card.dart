import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_tooltip.dart';
import '../../../../core/widgets/custom_slider.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/gold_badge.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/projection_viewmodel.dart';

class ProjectionSimulatorCard extends ConsumerWidget {
  const ProjectionSimulatorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projState = ref.watch(projectionProvider);
    final currency = ref.watch(currencyProvider);
    final simResult = projState.simulationResult;
    final points = simResult.points;

    final milestoneTargetName = currency == CurrencyType.inr ? '1 Crore (₹1 Cr)' : '\$1 Million (\$1M)';
    final milestoneTarget5Name = currency == CurrencyType.inr ? '5 Crore (₹5 Cr)' : '\$5 Million (\$5M)';

    return GlassContainer(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Milestone Callout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 20, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AppTooltip(
                        message: 'Simulate forward net worth compounding, real inflation purchasing power, and cash drag under various horizons.',
                        iconColor: AppColors.gold,
                        child: Text(
                          'WEALTH SIMULATOR',
                          style: AppTypography.heading3.copyWith(fontSize: 16, letterSpacing: 0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (simResult.milestoneAge1CrOr1M != null) ...[
                const SizedBox(width: 8),
                GoldBadge(
                  label: '${currency == CurrencyType.inr ? "₹1Cr" : "\$1M"} @ Age ${simResult.milestoneAge1CrOr1M!.toStringAsFixed(1)}',
                  icon: Icons.emoji_events_rounded,
                  isGlow: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dynamic multi-scenario forecasting comparing compound asset growth against real inflation-adjusted purchasing power and cash drag.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),

          // Milestone Highlight Banner
          if (simResult.milestoneAge1CrOr1M != null || simResult.milestoneAge5CrOr5M != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.15),
                    AppColors.crimson.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KEY FINANCIAL MILESTONE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.goldLight,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                            children: [
                              const TextSpan(text: 'At current trajectory, you reach '),
                              TextSpan(
                                text: milestoneTargetName,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldLight),
                              ),
                              TextSpan(
                                text: ' at Age ${simResult.milestoneAge1CrOr1M?.toStringAsFixed(1) ?? 'N/A'}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              if (simResult.milestoneAge5CrOr5M != null) ...[
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: milestoneTarget5Name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.crimsonLight),
                                ),
                                TextSpan(
                                  text: ' at Age ${simResult.milestoneAge5CrOr5M?.toStringAsFixed(1)}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Simulation Controls (Sliders Grid)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              final ageSlider = CustomFinancialSlider(
                label: 'Current Age',
                valueDisplay: '${projState.currentAge} yrs',
                valueFormatter: (val) => '${val.round()} yrs',
                value: projState.currentAge.toDouble(),
                min: 18,
                max: 70,
                divisions: 52,
                icon: Icons.person_rounded,
                activeColor: AppColors.info,
                tooltipMessage: 'Your present age; defines the starting point for compound growth projections.',
                onChanged: (val) => ref.read(projectionProvider.notifier).setCurrentAge(val.round()),
              );

              final retireSlider = CustomFinancialSlider(
                label: 'Target Retirement Age',
                valueDisplay: '${projState.targetRetirementAge} yrs',
                valueFormatter: (val) => '${val.round()} yrs',
                value: projState.targetRetirementAge.toDouble(),
                min: 30,
                max: 85,
                divisions: 55,
                icon: Icons.beach_access_rounded,
                activeColor: AppColors.gold,
                tooltipMessage: 'The age at which you plan to stop regular employment and transition into the retirement/SWP phase.',
                onChanged: (val) => ref.read(projectionProvider.notifier).setTargetRetirementAge(val.round()),
              );

              final inflationSlider = CustomFinancialSlider(
                label: 'Annual Inflation Rate',
                valueDisplay: '${projState.annualInflationPercent.toStringAsFixed(1)}%',
                valueFormatter: (val) => '${val.toStringAsFixed(1)}%',
                value: projState.annualInflationPercent,
                min: 0.0,
                max: 15.0,
                divisions: 30,
                icon: Icons.price_change_rounded,
                activeColor: AppColors.loss,
                tooltipMessage: 'Expected annual inflation rate used to calculate future real purchasing power in today\'s money terms.',
                onChanged: (val) => ref.read(projectionProvider.notifier).setAnnualInflation(val),
              );

              final stepUpSlider = CustomFinancialSlider(
                label: 'Annual SIP Step-up',
                valueDisplay: '${projState.globalStepUpPercent.toStringAsFixed(0)}%',
                valueFormatter: (val) => '${val.toStringAsFixed(0)}%',
                value: projState.globalStepUpPercent,
                min: 0.0,
                max: 25.0,
                divisions: 25,
                icon: Icons.trending_up_rounded,
                activeColor: AppColors.profit,
                tooltipMessage: 'Annual percentage increase in your monthly SIP contributions as your earnings and savings grow.',
                onChanged: (val) => ref.read(projectionProvider.notifier).setGlobalStepUp(val),
              );

              if (isWide) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: ageSlider),
                        const SizedBox(width: 24),
                        Expanded(child: retireSlider),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: inflationSlider),
                        const SizedBox(width: 24),
                        Expanded(child: stepUpSlider),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    ageSlider,
                    const SizedBox(height: 12),
                    retireSlider,
                    const SizedBox(height: 12),
                    inflationSlider,
                    const SizedBox(height: 12),
                    stepUpSlider,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // 3-Curve Comparison Chart
          if (points.isEmpty)
            Container(
              height: 260,
              alignment: Alignment.center,
              child: Text(
                'Add investments to simulate multi-scenario projections.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            )
          else ...[
            Builder(builder: (context) {
              double maxVal = 0.0;
              for (final p in points) {
                if (p.baseValue > maxVal) maxVal = p.baseValue;
                if (p.realValue > maxVal) maxVal = p.realValue;
                if (p.cashDragValue > maxVal) maxVal = p.cashDragValue;
              }
              final effectiveMaxY = maxVal > 0 ? (maxVal * 1.25) : 100000.0;
              final interval = (effectiveMaxY / 4).clamp(1.0, double.infinity);

              return RepaintBoundary(
                child: SizedBox(
                  height: 280,
                  child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: effectiveMaxY,
                    clipData: const FlClipData.none(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.border.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
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
                          reservedSize: 28,
                          interval: (points.length / 6).clamp(1.0, 10.0),
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Age ${points[idx].age}',
                                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 58,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              CurrencyFormatter.formatCompact(value, currency: currency, includeDecimals: false),
                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
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
                            if (idx < 0 || idx >= points.length) return null;
                            final p = points[idx];

                            String title;
                            Color color;
                            if (spot.barIndex == 0) {
                              title = 'Base Trajectory: ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}';
                              color = AppColors.gold;
                            } else if (spot.barIndex == 1) {
                              title = 'Inflation-Adjusted: ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}';
                              color = AppColors.info;
                            } else {
                              title = 'Cash Drag (3.5%): ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}';
                              color = AppColors.textMuted;
                            }

                            return LineTooltipItem(
                              spot.barIndex == 0 ? 'Age ${p.age} (Year ${p.year})\n$title' : title,
                              GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  lineBarsData: [
                    // Curve 1: Base Case (Gold)
                    LineChartBarData(
                      spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].baseValue)),
                      isCurved: true,
                      color: AppColors.gold,
                      barWidth: 3.5,
                      dotData: const FlDotData(show: false),
                    ),
                    // Curve 2: Inflation-Adjusted Real Wealth (Cyan)
                    LineChartBarData(
                      spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].realValue)),
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 2.5,
                      dashArray: [4, 2],
                      dotData: const FlDotData(show: false),
                    ),
                    // Curve 3: Cash Drag Benchmark (Slate / Rose)
                    LineChartBarData(
                      spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].cashDragValue)),
                      isCurved: true,
                      color: AppColors.loss.withOpacity(0.7),
                      barWidth: 2.0,
                      dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
          const SizedBox(height: 16),
            // Scenario Legend
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildScenarioLegend(
                  'Base Case (Compound CAGR + Step-up)',
                  AppColors.gold,
                  isDashed: false,
                  tooltipMessage: 'Nominal projected future wealth factoring in asset CAGRs and annual SIP step-up.',
                ),
                _buildScenarioLegend(
                  'Real Wealth (Inflation Adjusted)',
                  AppColors.info,
                  isDashed: true,
                  tooltipMessage: 'Purchasing power of your future wealth discounted by annual inflation rate.',
                ),
                _buildScenarioLegend(
                  'Cash Drag (3.5% Savings Account)',
                  AppColors.loss,
                  isDashed: true,
                  tooltipMessage: 'Opportunity cost trajectory if money were kept in a low-yield savings account (3.5%).',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Final Horizon Outcome Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFinalOutcome(
                      'AT AGE ${projState.targetRetirementAge} (BASE)',
                      simResult.finalBaseNetWorth,
                      currency,
                      AppColors.goldLight,
                      tooltipMessage: 'Projected total wealth accumulated at target retirement age under expected returns.',
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: _buildFinalOutcome(
                      'REAL PURCHASING POWER',
                      simResult.finalRealNetWorth,
                      currency,
                      AppColors.info,
                      tooltipMessage: 'Actual purchasing power of your retirement corpus in today\'s currency terms.',
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: _buildFinalOutcome(
                      'CASH DRAG LOSS',
                      simResult.finalBaseNetWorth - simResult.finalCashDragNetWorth,
                      currency,
                      AppColors.profit,
                      prefix: '+',
                      tooltipMessage: 'Additional wealth created by investing in compounding assets compared to a standard bank account.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _emptyTitleWidget(double value, TitleMeta meta) => const SizedBox.shrink();

  Widget _buildScenarioLegend(String label, Color color, {required bool isDashed, String? tooltipMessage}) {
    final legendItem = Row(
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
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (tooltipMessage != null) {
      return AppTooltip(
        message: tooltipMessage,
        iconColor: color,
        showIcon: false,
        child: legendItem,
      );
    }
    return legendItem;
  }

  Widget _buildFinalOutcome(
    String label,
    double value,
    CurrencyType currency,
    Color color, {
    String prefix = '',
    String? tooltipMessage,
  }) {
    final labelWidget = Text(
      label,
      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );

    return Column(
      children: [
        tooltipMessage != null
            ? AppTooltip(
                message: tooltipMessage,
                iconColor: color,
                child: labelWidget,
              )
            : labelWidget,
        const SizedBox(height: 4),
        Text(
          '$prefix${CurrencyFormatter.formatCompact(value, currency: currency)}',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
