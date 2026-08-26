import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_slider.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/fire_models.dart';
import '../../domain/entities/swp_models.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/fire_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import '../viewmodels/projection_viewmodel.dart';
import '../viewmodels/swp_viewmodel.dart';
import 'compact_amount_suffix_badge.dart';

class FireCalculatorCard extends ConsumerStatefulWidget {
  const FireCalculatorCard({super.key});

  @override
  ConsumerState<FireCalculatorCard> createState() => _FireCalculatorCardState();
}

class _FireCalculatorCardState extends ConsumerState<FireCalculatorCard> {
  late final TextEditingController _expenseController;
  late final TextEditingController _customCorpusController;
  late final TextEditingController _customSavingsController;
  bool _isGuideExpanded = false;
  bool _isTableExpanded = true;
  bool _isMilestonesExpanded = false;

  @override
  void initState() {
    super.initState();
    final fireState = ref.read(fireProvider);
    _expenseController = TextEditingController(text: fireState.monthlyExpenses.toStringAsFixed(0));
    _customCorpusController = TextEditingController(text: fireState.customStartingCorpus.toStringAsFixed(0));
    _customSavingsController = TextEditingController(text: fireState.customMonthlySavings.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _expenseController.dispose();
    _customCorpusController.dispose();
    _customSavingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fireState = ref.watch(fireProvider);
    final portfolioState = ref.watch(portfolioProvider);
    final projState = ref.watch(projectionProvider);
    final currency = ref.watch(currencyProvider);
    final result = fireState.result;

    final currentNetWorth = fireState.useCustomStartingCorpus
        ? fireState.customStartingCorpus
        : portfolioState.summary.totalNetWorth;

    final currentMonthlySavings = fireState.useCustomMonthlySavings
        ? fireState.customMonthlySavings
        : portfolioState.summary.totalMonthlySipInflow;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.catEquities, AppColors.gold],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FIRE & FREEDOM CALCULATOR',
                                style: AppTypography.heading3.copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Financial Independence, Retire Early: Target Numbers, Coast & Barista Milestones.',
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isWide)
                    TextButton.icon(
                      onPressed: () => setState(() => _isGuideExpanded = !_isGuideExpanded),
                      icon: Icon(_isGuideExpanded ? Icons.expand_less : Icons.school_rounded, size: 16, color: AppColors.goldLight),
                      label: Text(
                        _isGuideExpanded ? 'Hide Guide' : '📖 FIRE Guide & Rules',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Collapsible Educational Guide Card
          if (_isGuideExpanded) _buildFireGuideCard(),
          const SizedBox(height: 16),

          // Top Freedom Readiness & Countdown Banner
          _buildFreedomCountdownBanner(result, currentNetWorth, currency),
          const SizedBox(height: 24),

          // Controls & Inputs Section
          _buildInputsSection(fireState, currentNetWorth, currentMonthlySavings, currency, projState),
          const SizedBox(height: 20),

          // Pre-Retirement Capital Milestones Section
          _buildPreFireMilestonesSection(fireState, currency, projState),
          const SizedBox(height: 24),

          // Multi-FIRE Comparison Cards (Standard, Lean, Fat, Coast, Barista)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text('MULTI-FIRE TARGET MILESTONES', style: AppTypography.heading3.copyWith(fontSize: 14)),
                ],
              ),
              Text(
                '${result.fireMultiplier.toStringAsFixed(1)}x Annual Expenses Multiplier',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMultiFireCardsGrid(result, currentNetWorth, currency),
          const SizedBox(height: 28),

          // Net Worth vs FIRE Target Crossover Line Chart
          _buildCrossoverChart(result, currency, projState.currentAge),
          const SizedBox(height: 28),

          // Year-by-Year Schedule Table
          _buildYearlyTable(result, currency),
        ],
      ),
    );
  }

  // =========================================================================
  // TOP FREEDOM READINESS BANNER
  // =========================================================================
  Widget _buildFreedomCountdownBanner(FireCalculationResult result, double currentNetWorth, CurrencyType currency) {
    final isAchieved = result.isFireAchieved && currentNetWorth >= result.standardFireNumber;
    final readinessClamped = result.fireReadinessPercent.clamp(0.0, 100.0);

    Color statusColor;
    String statusTitle;
    String statusSubtitle;

    if (isAchieved) {
      statusColor = AppColors.profit;
      statusTitle = 'FINANCIAL INDEPENDENCE ACHIEVED! 🎉';
      statusSubtitle = 'Your current net worth covers 100% of your annual living expenses in perpetuity at your chosen SWR.';
    } else if (result.isFireAchieved) {
      statusColor = AppColors.gold;
      statusTitle = 'ON TRACK FOR FREEDOM IN ${result.yearsToFire.toStringAsFixed(1)} YEARS';
      statusSubtitle = 'Projected FIRE Age: ${result.fireAge.toStringAsFixed(0)} (Year ${result.fireYear}) under ongoing savings & compounding.';
    } else {
      statusColor = AppColors.loss;
      statusTitle = 'ACCELERATE SAVINGS TO REACH FIRE';
      statusSubtitle = 'Increase monthly contributions or adjust expected returns to achieve crossover within your lifetime.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAchieved ? Icons.verified_rounded : Icons.timer_rounded,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: statusColor == AppColors.profit ? AppColors.profitLight : statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusSubtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Readiness Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FIRE READINESS: ${result.fireReadinessPercent.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
              ),
              Text(
                '${CurrencyFormatter.formatCompact(currentNetWorth, currency: currency)} / ${CurrencyFormatter.formatCompact(result.standardFireNumber, currency: currency)}',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (readinessClamped / 100.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 16),

          // 4 Metric Pillars
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricPill(
                        'STANDARD FIRE NUMBER',
                        CurrencyFormatter.formatCompact(result.standardFireNumber, currency: currency),
                        AppColors.gold,
                        'Target corpus in today\'s money to sustain 100% of living expenses indefinitely.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricPill(
                        'ANNUAL EXPENSES',
                        CurrencyFormatter.formatCompact(result.annualExpensesToday, currency: currency),
                        AppColors.textSecondary,
                        'Total living expenses per year (Monthly Expenses × 12).',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricPill(
                        'PROJECTED FIRE AGE',
                        result.isFireAchieved ? 'Age ${result.fireAge.toStringAsFixed(0)}' : 'N/A',
                        AppColors.profit,
                        'Estimated age when Net Worth crosses your inflation-adjusted FIRE number.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricPill(
                        'PASSIVE MONTHLY INFLOW',
                        CurrencyFormatter.formatCompact((currentNetWorth * (result.fireMultiplier > 0 ? (100.0 / result.fireMultiplier) : 4.0) / 100.0) / 12.0, currency: currency),
                        AppColors.info,
                        'Monthly safe withdrawal income generated by current net worth.',
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricPill(
                            'STANDARD FIRE NUMBER',
                            CurrencyFormatter.formatCompact(result.standardFireNumber, currency: currency),
                            AppColors.gold,
                            'Target corpus in today\'s money.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricPill(
                            'ANNUAL EXPENSES',
                            CurrencyFormatter.formatCompact(result.annualExpensesToday, currency: currency),
                            AppColors.textSecondary,
                            'Annual living expenses today.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricPill(
                            'PROJECTED FIRE AGE',
                            result.isFireAchieved ? 'Age ${result.fireAge.toStringAsFixed(0)}' : 'N/A',
                            AppColors.profit,
                            'Estimated age to cross FIRE target.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricPill(
                            'PASSIVE MONTHLY INFLOW',
                            CurrencyFormatter.formatCompact((currentNetWorth * (result.fireMultiplier > 0 ? (100.0 / result.fireMultiplier) : 4.0) / 100.0) / 12.0, currency: currency),
                            AppColors.info,
                            'Monthly income from current net worth.',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color, String tooltip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              _buildTooltipIcon(tooltip),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CONTROLS & INPUTS SECTION
  // =========================================================================
  Widget _buildInputsSection(
    FireState fireState,
    double currentNetWorth,
    double currentMonthlySavings,
    CurrencyType currency,
    ProjectionState projState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sourcing Mode Selector (Auto-Sync vs Custom Override)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    ref.read(fireProvider.notifier).setUseCustomStartingCorpus(false);
                    ref.read(fireProvider.notifier).setUseCustomMonthlySavings(false);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: (!fireState.useCustomStartingCorpus && !fireState.useCustomMonthlySavings)
                          ? AppColors.surfaceCard
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: (!fireState.useCustomStartingCorpus && !fireState.useCustomMonthlySavings)
                          ? Border.all(color: AppColors.gold, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (!fireState.useCustomStartingCorpus && !fireState.useCustomMonthlySavings)
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 16,
                              color: (!fireState.useCustomStartingCorpus && !fireState.useCustomMonthlySavings)
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Auto-Sync Active Portfolio',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: (!fireState.useCustomStartingCorpus && !fireState.useCustomMonthlySavings)
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: (!fireState.useCustomStartingCorpus && !fireState.useCustomMonthlySavings)
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            '${CurrencyFormatter.formatCompact(currentNetWorth, currency: currency)} Net Worth • ${CurrencyFormatter.formatCompact(currentMonthlySavings, currency: currency)}/mo SIP',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: (!fireState.useCustomStartingCorpus && !fireState.useCustomMonthlySavings)
                                  ? AppColors.goldLight
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    ref.read(fireProvider.notifier).setUseCustomStartingCorpus(true);
                    ref.read(fireProvider.notifier).setUseCustomMonthlySavings(true);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: (fireState.useCustomStartingCorpus || fireState.useCustomMonthlySavings)
                          ? AppColors.surfaceCard
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: (fireState.useCustomStartingCorpus || fireState.useCustomMonthlySavings)
                          ? Border.all(color: AppColors.gold, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (fireState.useCustomStartingCorpus || fireState.useCustomMonthlySavings)
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 16,
                              color: (fireState.useCustomStartingCorpus || fireState.useCustomMonthlySavings)
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Custom Starting Corpus & SIP',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: (fireState.useCustomStartingCorpus || fireState.useCustomMonthlySavings)
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: (fireState.useCustomStartingCorpus || fireState.useCustomMonthlySavings)
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            CompactAmountLabel(
                              controller: _customCorpusController,
                              currency: currency,
                              prefix: 'Corpus: ',
                              accentColor: AppColors.goldLight,
                            ),
                            const SizedBox(width: 4),
                            CompactAmountLabel(
                              controller: _customSavingsController,
                              currency: currency,
                              prefix: 'SIP: ',
                              accentColor: AppColors.goldLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 34,
                                child: TextField(
                                  controller: _customCorpusController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldLight),
                                  decoration: InputDecoration(
                                    prefixText: '${currency.symbol} ',
                                    hintText: 'Corpus',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    filled: true,
                                    fillColor: AppColors.surfaceLight,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val.replaceAll(',', '').trim());
                                    if (parsed != null && parsed >= 0) {
                                      ref.read(fireProvider.notifier).setCustomStartingCorpus(parsed);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 34,
                                child: TextField(
                                  controller: _customSavingsController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldLight),
                                  decoration: InputDecoration(
                                    prefixText: '${currency.symbol} ',
                                    hintText: 'SIP/mo',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    filled: true,
                                    fillColor: AppColors.surfaceLight,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val.replaceAll(',', '').trim());
                                    if (parsed != null && parsed >= 0) {
                                      ref.read(fireProvider.notifier).setCustomMonthlySavings(parsed);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sliders Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            final expenseSlider = CustomFinancialSlider(
              label: 'Monthly Living Expenses',
              valueDisplay: '${CurrencyFormatter.formatCompact(fireState.monthlyExpenses, currency: currency)} / mo',
              value: fireState.monthlyExpenses.clamp(5000.0, 1000000.0),
              min: 5000,
              max: 1000000,
              divisions: 199,
              icon: Icons.receipt_long_rounded,
              activeColor: AppColors.crimsonLight,
              tooltipMessage: 'Baseline monthly living costs today. Standard FIRE multiplies this by your SWR factor (e.g. 25x–33x) to calculate your total target freedom number.',
              onChanged: (val) {
                ref.read(fireProvider.notifier).setMonthlyExpenses(val);
                _expenseController.text = val.toStringAsFixed(0);
              },
            );

            final swrSlider = CustomFinancialSlider(
              label: 'Safe Withdrawal Rate (SWR)',
              valueDisplay: '${fireState.swrPercent.toStringAsFixed(1)}% SWR (${(100.0 / fireState.swrPercent).toStringAsFixed(1)}x)',
              value: fireState.swrPercent.clamp(2.0, 6.0),
              min: 2.0,
              max: 6.0,
              divisions: 40,
              icon: Icons.shield_rounded,
              activeColor: AppColors.gold,
              tooltipMessage: 'Annual percentage withdrawn from your corpus. Classic 4% rule (25x) was designed for 30-year retirements. For longer horizons (40–50+ years), 2.75%–3.50% (28x–36x) is significantly safer.',
              headerAction: _buildSmartSwrRecommendationChip(fireState.result, fireState.swrPercent),
              onChanged: (val) => ref.read(fireProvider.notifier).setSwrPercent(val),
            );

            final returnSlider = CustomFinancialSlider(
              label: 'Expected Investment CAGR',
              valueDisplay: '${fireState.expectedReturn.toStringAsFixed(1)}% CAGR',
              value: fireState.expectedReturn.clamp(5.0, 20.0),
              min: 5.0,
              max: 20.0,
              divisions: 30,
              icon: Icons.trending_up_rounded,
              activeColor: AppColors.profit,
              tooltipMessage: 'Compounded annual growth rate of your investment portfolio during accumulation. Typical diversified equity funds deliver 10–14% over long horizons.',
              onChanged: (val) => ref.read(fireProvider.notifier).setExpectedReturn(val),
            );

            final inflationSlider = CustomFinancialSlider(
              label: 'Annual Inflation Rate',
              valueDisplay: '${fireState.inflationRate.toStringAsFixed(1)}% / yr',
              value: fireState.inflationRate.clamp(2.0, 12.0),
              min: 2.0,
              max: 12.0,
              divisions: 20,
              icon: Icons.price_change_rounded,
              activeColor: AppColors.loss,
              tooltipMessage: 'Expected annual rise in living costs. In India/emerging markets, CPI typically averages 5–7% per year, compounding long-term expense requirements.',
              onChanged: (val) => ref.read(fireProvider.notifier).setInflationRate(val),
            );

            if (isWide) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: expenseSlider),
                      const SizedBox(width: 24),
                      Expanded(child: swrSlider),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: returnSlider),
                      const SizedBox(width: 24),
                      Expanded(child: inflationSlider),
                    ],
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  expenseSlider,
                  const SizedBox(height: 12),
                  swrSlider,
                  const SizedBox(height: 12),
                  returnSlider,
                  const SizedBox(height: 12),
                  inflationSlider,
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // =========================================================================
  // SMART SWR RECOMMENDATION CHIP
  // =========================================================================
  Widget _buildSmartSwrRecommendationChip(FireCalculationResult result, double currentSwr) {
    final recommended = result.recommendedSwr;
    final isAlreadyMatching = (currentSwr - recommended).abs() < 0.05;

    return InkWell(
      onTap: isAlreadyMatching
          ? null
          : () => ref.read(fireProvider.notifier).setSwrPercent(recommended),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isAlreadyMatching
              ? AppColors.profit.withOpacity(0.12)
              : AppColors.gold.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isAlreadyMatching
                ? AppColors.profit.withOpacity(0.4)
                : AppColors.gold.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAlreadyMatching ? Icons.verified_rounded : Icons.lightbulb_rounded,
              size: 13,
              color: isAlreadyMatching ? AppColors.profit : AppColors.gold,
            ),
            const SizedBox(width: 4),
            Text(
              '💡 Rec: ${recommended.toStringAsFixed(2)}% (${result.retirementHorizonYears}y)',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isAlreadyMatching ? AppColors.profit : AppColors.goldLight,
              ),
            ),
            if (!isAlreadyMatching) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Apply',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // PRE-RETIREMENT CAPITAL MILESTONES SECTION
  // =========================================================================
  Widget _buildPreFireMilestonesSection(
    FireState fireState,
    CurrencyType currency,
    ProjectionState projState,
  ) {
    final milestones = fireState.preFireMilestones;
    final activeMilestones = milestones.where((m) => m.isEnabled).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 14,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isMilestonesExpanded = !_isMilestonesExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flag_rounded, size: 16, color: AppColors.gold),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'PRE-RETIREMENT GOALS & CAPITAL OUTFLOWS',
                                    style: AppTypography.heading3.copyWith(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: activeMilestones.isNotEmpty
                                        ? AppColors.gold.withOpacity(0.15)
                                        : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: activeMilestones.isNotEmpty
                                          ? AppColors.gold.withOpacity(0.4)
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    '${activeMilestones.length} Active',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: activeMilestones.isNotEmpty ? AppColors.goldLight : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Major one-off expenses (Home purchase, Child Education) deducted from your net worth before FIRE.',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.goldLight,
                      side: const BorderSide(color: AppColors.borderGold),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 14),
                    label: Text(
                      'Sync from SWP',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      final swpMilestones = ref.read(swpProvider).milestoneExpenses;
                      if (swpMilestones.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No milestones found in SWP Simulator to sync.')),
                        );
                      } else {
                        ref.read(fireProvider.notifier).syncFromSwpMilestones(swpMilestones);
                        setState(() => _isMilestonesExpanded = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Synced ${swpMilestones.length} milestones from SWP!')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: Text(
                      'Add Goal',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showMilestoneFormDialog(
                      context,
                      currentAge: projState.currentAge,
                      targetRetirementAge: projState.targetRetirementAge,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      _isMilestonesExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _isMilestonesExpanded = !_isMilestonesExpanded),
                  ),
                ],
              ),
            ],
          ),
          if (_isMilestonesExpanded) ...[
            const SizedBox(height: 14),
            if (milestones.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No pre-retirement capital goals added yet. Add big expenses (like Home Downpayment or Child Education) to see how they impact your exact FIRE age.',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: milestones.map((milestone) {
                  final inflatedCost = (milestone.inTodayTerms && milestone.targetAge > projState.currentAge)
                      ? milestone.amount * math.pow(1.0 + fireState.inflationRate / 100.0, (milestone.targetAge - projState.currentAge).toDouble())
                      : milestone.amount;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: milestone.isEnabled ? AppColors.gold.withOpacity(0.4) : AppColors.border,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: milestone.isEnabled,
                            activeColor: AppColors.gold,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (_) => ref.read(fireProvider.notifier).togglePreFireMilestone(milestone.id),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        milestone.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: milestone.isEnabled ? AppColors.textPrimary : AppColors.textMuted,
                                          decoration: milestone.isEnabled ? null : TextDecoration.lineThrough,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Age ${milestone.targetAge}',
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  milestone.inTodayTerms
                                      ? '${CurrencyFormatter.formatCompact(milestone.amount, currency: currency)} in today\'s value → ${CurrencyFormatter.formatCompact(inflatedCost, currency: currency)} at Age ${milestone.targetAge}'
                                      : CurrencyFormatter.formatCompact(milestone.amount, currency: currency),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: milestone.isEnabled ? AppColors.goldLight : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.goldLight),
                            tooltip: 'Edit Goal',
                            onPressed: () => _showMilestoneFormDialog(
                              context,
                              existingMilestone: milestone,
                              currentAge: projState.currentAge,
                              targetRetirementAge: projState.targetRetirementAge,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                            tooltip: 'Remove Goal',
                            onPressed: () => ref.read(fireProvider.notifier).removePreFireMilestone(milestone.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  void _showMilestoneFormDialog(
    BuildContext context, {
    SwpMilestoneExpense? existingMilestone,
    required int currentAge,
    required int targetRetirementAge,
  }) {
    final isEditing = existingMilestone != null;
    final nameController = TextEditingController(
      text: isEditing ? existingMilestone.name : 'Pre-FIRE Goal',
    );
    final amountController = TextEditingController(
      text: isEditing
          ? (existingMilestone.amount % 1 == 0
              ? existingMilestone.amount.toInt().toString()
              : existingMilestone.amount.toString())
          : '1000000',
    );
    int targetAge = isEditing
        ? existingMilestone.targetAge.clamp(currentAge + 1, targetRetirementAge + 10)
        : (currentAge + 5).clamp(currentAge + 1, targetRetirementAge + 10);
    bool inTodayTerms = isEditing ? existingMilestone.inTodayTerms : true;
    final currency = ref.read(currencyProvider);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.flag_circle_rounded,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit Pre-FIRE Goal' : 'Add Pre-FIRE Goal',
                    style: AppTypography.heading3.copyWith(fontSize: 16),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Goal / Outflow Name', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'e.g. Home Downpayment, Child Education',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        CompactAmountLabel(
                          controller: amountController,
                          currency: currency,
                          accentColor: AppColors.goldLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: '${currency.symbol} ',
                        prefixStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Age', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        Text('Age $targetAge', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldLight)),
                      ],
                    ),
                    Slider(
                      value: targetAge.toDouble().clamp((currentAge + 1).toDouble(), (targetRetirementAge + 15).toDouble()),
                      min: (currentAge + 1).toDouble(),
                      max: (targetRetirementAge + 15).toDouble(),
                      divisions: ((targetRetirementAge + 15) - (currentAge + 1)).clamp(1, 100),
                      activeColor: AppColors.gold,
                      onChanged: (v) => setDialogState(() => targetAge = v.round()),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: inTodayTerms,
                          activeColor: AppColors.gold,
                          onChanged: (v) => setDialogState(() => inTodayTerms = v ?? true),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Amount is in today\'s purchasing power',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final amount = double.tryParse(amountController.text.replaceAll(',', '').trim()) ?? 0.0;
                    if (amount > 0) {
                      final name = nameController.text.trim().isEmpty ? 'Pre-FIRE Goal' : nameController.text.trim();
                      if (isEditing) {
                        ref.read(fireProvider.notifier).updatePreFireMilestone(
                          existingMilestone.copyWith(
                            name: name,
                            targetAge: targetAge,
                            amount: amount,
                            inTodayTerms: inTodayTerms,
                          ),
                        );
                      } else {
                        final id = DateTime.now().millisecondsSinceEpoch.toString();
                        ref.read(fireProvider.notifier).addPreFireMilestone(
                          SwpMilestoneExpense(
                            id: id,
                            name: name,
                            targetAge: targetAge,
                            amount: amount,
                            inTodayTerms: inTodayTerms,
                            isEnabled: true,
                          ),
                        );
                      }
                      Navigator.pop(dialogCtx);
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Goal', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // MULTI-FIRE COMPARISON CARDS
  // =========================================================================
  Widget _buildMultiFireCardsGrid(FireCalculationResult result, double currentNetWorth, CurrencyType currency) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final standardCard = _buildFireFlavorCard(
          flavor: FireFlavor.standard,
          targetAmount: result.standardFireNumber,
          currentAmount: currentNetWorth,
          color: AppColors.gold,
          icon: Icons.check_circle_outline_rounded,
          currency: currency,
          badge: '100% Expenses',
        );

        final leanCard = _buildFireFlavorCard(
          flavor: FireFlavor.lean,
          targetAmount: result.leanFireNumber,
          currentAmount: currentNetWorth,
          color: AppColors.catFixedDeposit,
          icon: Icons.eco_rounded,
          currency: currency,
          badge: '75% Frugal',
        );

        final fatCard = _buildFireFlavorCard(
          flavor: FireFlavor.fat,
          targetAmount: result.fatFireNumber,
          currentAmount: currentNetWorth,
          color: AppColors.catEquities,
          icon: Icons.diamond_rounded,
          currency: currency,
          badge: '135% Luxury',
        );

        final coastCard = _buildFireFlavorCard(
          flavor: FireFlavor.coast,
          targetAmount: result.coastFireNumber,
          currentAmount: currentNetWorth,
          color: AppColors.catMutualFunds,
          icon: Icons.sailing_rounded,
          currency: currency,
          badge: 'Compounding Only',
        );

        final baristaCard = _buildFireFlavorCard(
          flavor: FireFlavor.barista,
          targetAmount: result.baristaFireNumber,
          currentAmount: currentNetWorth,
          color: AppColors.catRealEstate,
          icon: Icons.coffee_rounded,
          currency: currency,
          badge: '40% Part-Time',
        );

        if (constraints.maxWidth >= 1150) {
          return Row(
            children: [
              Expanded(child: standardCard),
              const SizedBox(width: 10),
              Expanded(child: leanCard),
              const SizedBox(width: 10),
              Expanded(child: fatCard),
              const SizedBox(width: 10),
              Expanded(child: coastCard),
              const SizedBox(width: 10),
              Expanded(child: baristaCard),
            ],
          );
        } else if (constraints.maxWidth >= 650) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: standardCard),
                  const SizedBox(width: 10),
                  Expanded(child: leanCard),
                  const SizedBox(width: 10),
                  Expanded(child: fatCard),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: coastCard),
                  const SizedBox(width: 10),
                  Expanded(child: baristaCard),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              standardCard,
              const SizedBox(height: 10),
              leanCard,
              const SizedBox(height: 10),
              fatCard,
              const SizedBox(height: 10),
              coastCard,
              const SizedBox(height: 10),
              baristaCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildFireFlavorCard({
    required FireFlavor flavor,
    required double targetAmount,
    required double currentAmount,
    required Color color,
    required IconData icon,
    required CurrencyType currency,
    required String badge,
  }) {
    final progress = targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.5) : 0.0;
    final isAchieved = currentAmount >= targetAmount && targetAmount > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAchieved ? color : AppColors.border, width: isAchieved ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 15, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        flavor.title,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCompact(targetAmount, currency: currency),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            flavor.description,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAchieved ? 'ACHIEVED 🎉' : '${(progress * 100).toStringAsFixed(0)}% FUNDED',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: isAchieved ? AppColors.profitLight : AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(isAchieved ? AppColors.profit : color),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // NET WORTH VS FIRE TARGET CROSSOVER LINE CHART
  // =========================================================================
  Widget _buildCrossoverChart(FireCalculationResult result, CurrencyType currency, int currentAge) {
    final points = result.yearlyPoints;
    if (points.isEmpty) return const SizedBox.shrink();

    double maxVal = 10000.0;
    for (final p in points) {
      if (p.netWorth > maxVal) maxVal = p.netWorth;
      if (p.inflationAdjustedFireTarget > maxVal) maxVal = p.inflationAdjustedFireTarget;
    }
    final maxY = (maxVal * 1.2).clamp(10000.0, double.infinity);
    final interval = (maxY / 4).clamp(1.0, double.infinity);

    final netWorthSpots = <FlSpot>[
      FlSpot(currentAge.toDouble(), result.currentNetWorth),
      ...points.map((p) => FlSpot(p.age.toDouble(), p.netWorth)),
    ];

    final fireTargetSpots = <FlSpot>[
      FlSpot(currentAge.toDouble(), result.standardFireNumber),
      ...points.map((p) => FlSpot(p.age.toDouble(), p.inflationAdjustedFireTarget)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('NET WORTH VS FIRE TARGET CROSSOVER', style: AppTypography.heading3.copyWith(fontSize: 14)),
                const SizedBox(width: 6),
                _buildTooltipIcon('Visualizes your projected Net Worth growth curve crossing over the inflation-adjusted FIRE Target Line. When Net Worth climbs above the line, Financial Independence is unlocked.'),
              ],
            ),
            Row(
              children: [
                _buildLegendIndicator(AppColors.profit, 'Projected Net Worth'),
                const SizedBox(width: 12),
                _buildLegendIndicator(AppColors.crimsonLight, 'Inflation-Adjusted FIRE Target'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              clipData: const FlClipData.none(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (val) => FlLine(color: AppColors.border.withOpacity(0.5), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 64,
                    interval: interval,
                    getTitlesWidget: (val, meta) {
                      if (val == meta.max || val == meta.min) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          CurrencyFormatter.formatCompact(val, currency: currency),
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: 5,
                    getTitlesWidget: (val, meta) {
                      final intAge = val.toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Age $intAge',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    final color = barData.color ?? AppColors.profit;
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: AppColors.border.withOpacity(0.8),
                        strokeWidth: 1.2,
                        dashArray: [4, 4],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  maxContentWidth: 280,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  getTooltipColor: (_) => AppColors.surfaceCard.withOpacity(0.96),
                  tooltipBorder: BorderSide(color: AppColors.profit.withOpacity(0.7), width: 1.2),
                  tooltipBorderRadius: const BorderRadius.all(Radius.circular(10)),
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    final intAge = touchedSpots.first.x.toInt();
                    double netWorthVal = 0.0;
                    double fireTargetVal = 0.0;

                    for (final s in touchedSpots) {
                      if (s.barIndex == 0) netWorthVal = s.y;
                      if (s.barIndex == 1) fireTargetVal = s.y;
                    }

                    final isAchieved = netWorthVal >= fireTargetVal && fireTargetVal > 0;
                    final coveragePct = fireTargetVal > 0 ? (netWorthVal / fireTargetVal * 100).clamp(0.0, 999.0) : 0.0;

                    return touchedSpots.map((spot) {
                      String title;
                      Color color;
                      if (spot.barIndex == 0) {
                        title = 'Projected Net Worth: ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}';
                        color = AppColors.profitLight;
                      } else {
                        final statusText = isAchieved ? ' • FIRE Unlocked 🚀' : ' • ${coveragePct.toStringAsFixed(0)}% Funded';
                        title = 'FIRE Target: ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}$statusText';
                        color = AppColors.crimsonLight;
                      }

                      return LineTooltipItem(
                        spot.barIndex == 0 ? 'Age $intAge\n$title' : title,
                        GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color, height: 1.35),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                // Net Worth Curve (Profit Green)
                LineChartBarData(
                  spots: netWorthSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.profit,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.profit.withOpacity(0.18),
                        AppColors.profit.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                // FIRE Target Line (Crimson/Loss dashed)
                LineChartBarData(
                  spots: fireTargetSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.crimsonLight,
                  barWidth: 2,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // YEARLY FIRE SCHEDULE TABLE
  // =========================================================================
  Widget _buildYearlyTable(FireCalculationResult result, CurrencyType currency) {
    final points = result.yearlyPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('YEAR-BY-YEAR FIRE TIMELINE SCHEDULE', style: AppTypography.heading3.copyWith(fontSize: 14)),
            TextButton.icon(
              onPressed: () => setState(() => _isTableExpanded = !_isTableExpanded),
              icon: Icon(_isTableExpanded ? Icons.expand_less : Icons.expand_more, size: 18),
              label: Text(_isTableExpanded ? 'Hide Table' : 'Show Table'),
            ),
          ],
        ),
        if (_isTableExpanded) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 42,
                horizontalMargin: 16,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('YEAR / AGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('PROJECTED NET WORTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('FIRE TARGET (ADJ.)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('ANNUAL EXPENSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('PASSIVE INCOME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('COVERAGE %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                ],
                rows: points.map((p) {
                  final isAchieved = p.isFireAchieved;
                  final statusColor = isAchieved ? AppColors.profit : (p.coverageRatioPercent >= 75.0 ? AppColors.gold : AppColors.loss);

                  return DataRow(
                    cells: [
                      DataCell(Text('Yr ${p.year} (Age ${p.age})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                      DataCell(Text(CurrencyFormatter.formatCompact(p.netWorth, currency: currency), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.profitLight))),
                      DataCell(Text(CurrencyFormatter.formatCompact(p.inflationAdjustedFireTarget, currency: currency), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
                      DataCell(Text(CurrencyFormatter.formatCompact(p.annualExpenses, currency: currency), style: GoogleFonts.inter(fontSize: 12, color: AppColors.crimsonLight))),
                      DataCell(Text('+${CurrencyFormatter.formatCompact(p.passiveIncome, currency: currency)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600))),
                      DataCell(Text('${p.coverageRatioPercent.toStringAsFixed(1)}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            isAchieved ? 'FIRE UNLOCKED' : (p.coverageRatioPercent >= 75.0 ? 'NEAR FIRE' : 'ACCUMULATING'),
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // EDUCATIONAL GUIDE CARD
  // =========================================================================
  Widget _buildFireGuideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                'Understanding the FIRE Movement, 4% Rule & Flavors',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.goldLight),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• What is FIRE? FIRE stands for Financial Independence, Retire Early. The goal is to accumulate invested assets until your passive investment income permanently covers your living expenses.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            '• The 4% Rule & Multipliers: Derived from the landmark Trinity Study. At a 4% Safe Withdrawal Rate (SWR), your target FIRE Number is 25× your Annual Living Expenses. At a conservative 3% SWR, it is 33.3× annual expenses.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.goldLight, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            '• Lean FIRE: Covering ~75% of expenses for a frugal, minimalist lifestyle without luxuries.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.catFixedDeposit, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            '• Fat FIRE: 125%–150% of expenses for abundant lifestyle, travel, and high healthcare buffers.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.catEquities, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            '• Coast FIRE: The amount you need invested TODAY so that compound interest alone will grow to your full FIRE number by retirement age without adding another dollar of savings.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.catMutualFunds, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            '• Barista FIRE: Partial financial independence where part-time work or freelance passion covers ~40% of living expenses and investments cover the rest.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.catRealEstate, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipIcon(String message) {
    return Tooltip(
      message: message,
      preferBelow: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGold),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      textStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary, height: 1.3),
      child: const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
    );
  }

  Widget _buildLegendIndicator(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
