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
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/fire_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import '../viewmodels/projection_viewmodel.dart';
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
