import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/asset_category.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';

class DonutAllocationChart extends ConsumerStatefulWidget {
  const DonutAllocationChart({super.key});

  @override
  ConsumerState<DonutAllocationChart> createState() => _DonutAllocationChartState();
}

class _DonutAllocationChartState extends ConsumerState<DonutAllocationChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final portfolioState = ref.watch(portfolioProvider);
    final currency = ref.watch(currencyProvider);
    final summary = portfolioState.summary;
    final categoryDist = summary.categoryDistribution;
    final categoriesWithValues = categoryDist.entries.where((e) => e.value > 0).toList();
    final totalEffective = summary.totalNetWorth > 0
        ? summary.totalNetWorth
        : categoriesWithValues.fold<double>(0.0, (sum, e) => sum + e.value);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pie_chart_outline_rounded, size: 20, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text('ASSET ALLOCATION', style: AppTypography.heading3.copyWith(fontSize: 16)),
                ],
              ),
              Text(
                '${categoriesWithValues.length} Categories',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (categoriesWithValues.isEmpty)
            Container(
              height: 220,
              alignment: Alignment.center,
              child: Text(
                'Add assets to see your category allocation breakdown.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 65,
                      sections: _generateSections(categoriesWithValues, totalEffective),
                    ),
                  ),
                  // Center Info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _touchedIndex >= 0 && _touchedIndex < categoriesWithValues.length
                            ? categoriesWithValues[_touchedIndex].key.label
                            : (summary.totalNetWorth > 0 ? 'TOTAL NET WORTH' : 'MONTHLY INFLOW'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _touchedIndex >= 0 && _touchedIndex < categoriesWithValues.length
                            ? CurrencyFormatter.formatCompact(
                                categoriesWithValues[_touchedIndex].value,
                                currency: currency,
                              )
                            : (summary.totalNetWorth > 0
                                ? CurrencyFormatter.formatCompact(
                                    summary.totalNetWorth,
                                    currency: currency,
                                  )
                                : '${CurrencyFormatter.formatCompact(totalEffective, currency: currency)} / mo'),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _touchedIndex >= 0 && _touchedIndex < categoriesWithValues.length
                              ? categoriesWithValues[_touchedIndex].key.color
                              : AppColors.goldLight,
                        ),
                      ),
                      if (_touchedIndex >= 0 &&
                          _touchedIndex < categoriesWithValues.length &&
                          totalEffective > 0)
                        Text(
                          '${((categoriesWithValues[_touchedIndex].value / totalEffective) * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Category Legend Grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(categoriesWithValues.length, (index) {
                final entry = categoriesWithValues[index];
                final percent = totalEffective > 0
                    ? (entry.value / totalEffective) * 100
                    : 0.0;
                final isSelected = _touchedIndex == index;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _touchedIndex = _touchedIndex == index ? -1 : index;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? entry.key.color.withOpacity(0.18)
                          : AppColors.surfaceLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? entry.key.color : AppColors.border,
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: entry.key.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key.label,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${percent.toStringAsFixed(1)}%',
                          style: AppTypography.bodySmall.copyWith(
                            color: entry.key.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(
    List<MapEntry<AssetCategory, double>> categories,
    double totalNetWorth,
  ) {
    return List.generate(categories.length, (i) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 28.0 : 20.0;
      final entry = categories[i];

      return PieChartSectionData(
        color: entry.key.color,
        value: entry.value,
        title: '',
        radius: radius,
        badgePositionPercentageOffset: .98,
        borderSide: isTouched
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide(color: AppColors.surface.withOpacity(0.5), width: 1),
      );
    });
  }
}
