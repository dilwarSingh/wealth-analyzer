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
import '../../domain/entities/risk_analysis_models.dart';
import '../../domain/entities/swp_models.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/projection_viewmodel.dart';
import '../viewmodels/risk_analysis_viewmodel.dart';
import '../viewmodels/swp_viewmodel.dart';

class SwpSimulatorCard extends ConsumerStatefulWidget {
  const SwpSimulatorCard({super.key});

  @override
  ConsumerState<SwpSimulatorCard> createState() => _SwpSimulatorCardState();
}

class _SwpSimulatorCardState extends ConsumerState<SwpSimulatorCard> {
  late final TextEditingController _customCorpusController;
  bool _isTableExpanded = true;
  bool _isMonteCarloGuideExpanded = false;
  bool _isCrisisGuideExpanded = false;
  bool _isMilestonesExpanded = false;
  int _selectedSubTab = 0; // 0: Schedule, 1: Monte Carlo, 2: Stress-Test

  @override
  void initState() {
    super.initState();
    final customAmount = ref.read(swpProvider).customCorpusAmount;
    _customCorpusController = TextEditingController(
      text: customAmount > 0 ? customAmount.toStringAsFixed(0) : '10000000',
    );
  }

  @override
  void dispose() {
    _customCorpusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swpState = ref.watch(swpProvider);
    final projState = ref.watch(projectionProvider);
    final riskState = ref.watch(riskAnalysisProvider);
    final currency = ref.watch(currencyProvider);
    final swpResult = swpState.swpResult;

    final retirementAge = projState.targetRetirementAge;
    final accumulatedCorpus = projState.simulationResult.finalBaseNetWorth;

    final effectiveStartingCorpus = swpState.useCustomCorpus
        ? swpState.customCorpusAmount
        : accumulatedCorpus;

    final hasData = effectiveStartingCorpus > 0 && swpResult.yearlyPoints.isNotEmpty;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title & Safe Withdrawal Rules Dropdown
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
                              colors: [AppColors.catMutualFunds, AppColors.catEquities],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.savings_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SWP DECUMULATION SIMULATOR',
                                style: AppTypography.heading3.copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Model retirement withdrawals, stochastic Monte Carlo trials, and crisis sequence risk.',
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
                    PopupMenuButton<double>(
                      tooltip: 'Safe Withdrawal Rules (2%, 3%, 4%, 5%)',
                      color: AppColors.surfaceCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onSelected: (percentage) {
                        ref.read(swpProvider.notifier).applyWithdrawalRule(percentage);
                      },
                      itemBuilder: (context) => [
                        _buildRuleMenuItem(2.0, '2% Rule (Ultra-Safe / Early FIRE)', effectiveStartingCorpus, currency),
                        _buildRuleMenuItem(3.0, '3% Rule (Conservative)', effectiveStartingCorpus, currency),
                        _buildRuleMenuItem(4.0, '4% Rule (Standard Trinity)', effectiveStartingCorpus, currency),
                        _buildRuleMenuItem(5.0, '5% Rule (Aggressive)', effectiveStartingCorpus, currency),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.shield_rounded, size: 16, color: AppColors.gold),
                            SizedBox(width: 6),
                            Text(
                              'Withdrawal Rules',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.gold),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Corpus Source Selector (Auto vs Custom)
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
                    onTap: () => ref.read(swpProvider.notifier).setUseCustomCorpus(false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: !swpState.useCustomCorpus ? AppColors.surfaceCard : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: !swpState.useCustomCorpus ? Border.all(color: AppColors.gold, width: 1.5) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                !swpState.useCustomCorpus ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 16,
                                color: !swpState.useCustomCorpus ? AppColors.gold : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Accumulated Corpus at Age $retirementAge',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: !swpState.useCustomCorpus ? FontWeight.w700 : FontWeight.w500,
                                    color: !swpState.useCustomCorpus ? AppColors.textPrimary : AppColors.textMuted,
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
                              CurrencyFormatter.formatCompact(accumulatedCorpus, currency: currency),
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: !swpState.useCustomCorpus ? AppColors.goldLight : AppColors.textMuted,
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
                    onTap: () => ref.read(swpProvider.notifier).setUseCustomCorpus(true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: swpState.useCustomCorpus ? AppColors.surfaceCard : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: swpState.useCustomCorpus ? Border.all(color: AppColors.gold, width: 1.5) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                swpState.useCustomCorpus ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 16,
                                color: swpState.useCustomCorpus ? AppColors.gold : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Custom Starting Corpus',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: swpState.useCustomCorpus ? FontWeight.w700 : FontWeight.w500,
                                    color: swpState.useCustomCorpus ? AppColors.textPrimary : AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _customCorpusController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldLight,
                              ),
                              decoration: InputDecoration(
                                prefixText: '${currency.symbol} ',
                                prefixStyle: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                                hintText: 'e.g. 10000000',
                                hintStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: AppColors.gold),
                                ),
                              ),
                              onTap: () {
                                if (!swpState.useCustomCorpus) {
                                  ref.read(swpProvider.notifier).setUseCustomCorpus(true);
                                }
                              },
                              onChanged: (val) {
                                final parsed = double.tryParse(val.replaceAll(',', '').trim());
                                if (parsed != null && parsed > 0) {
                                  ref.read(swpProvider.notifier).setCustomCorpusAmount(parsed);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Controls Grid (Sliders)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final inTodayTerms = swpState.isWithdrawalInTodayTerms;
              final currentAge = projState.currentAge;
              final inflationRate = projState.annualInflationPercent;
              final yearsToRetirement = (retirementAge - currentAge).clamp(0, 100);

              final withdrawalSlider = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.payments_rounded, size: 15, color: AppColors.crimsonLight),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                inTodayTerms ? 'Monthly Living Expenses' : 'Monthly Withdrawal',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => ref.read(swpProvider.notifier).setWithdrawalInTodayTerms(!inTodayTerms),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: inTodayTerms ? AppColors.gold.withOpacity(0.18) : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: inTodayTerms ? AppColors.gold : AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                inTodayTerms ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 12,
                                color: inTodayTerms ? AppColors.gold : AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'In Today\'s Terms',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: inTodayTerms ? AppColors.goldLight : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  CustomFinancialSlider(
                    label: '',
                    valueDisplay: '${CurrencyFormatter.formatCompact(swpState.monthlyWithdrawal, currency: currency)} / mo',
                    value: swpState.monthlyWithdrawal.clamp(1000.0, 500000.0),
                    min: 1000,
                    max: 500000,
                    divisions: 500,
                    icon: Icons.payments_rounded,
                    activeColor: AppColors.crimsonLight,
                    onChanged: (val) => ref.read(swpProvider.notifier).setMonthlyWithdrawal(val),
                  ),
                  if (inTodayTerms && yearsToRetirement > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border.withOpacity(0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_graph_rounded, size: 14, color: AppColors.gold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Inflated at Age $retirementAge ($yearsToRetirement yrs @ ${inflationRate.toStringAsFixed(1)}%): ',
                                    style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted),
                                  ),
                                  TextSpan(
                                    text: '${CurrencyFormatter.formatCompact(swpResult.effectiveMonthlyWithdrawalAtRetirement, currency: currency)} / mo',
                                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.goldLight),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );

              final cagrSlider = CustomFinancialSlider(
                label: 'Post-Retirement Return',
                valueDisplay: '${swpState.postRetirementCagr.toStringAsFixed(1)}% CAGR',
                value: swpState.postRetirementCagr.clamp(3.0, 15.0),
                min: 3.0,
                max: 15.0,
                divisions: 24,
                icon: Icons.trending_up_rounded,
                activeColor: AppColors.profit,
                onChanged: (val) => ref.read(swpProvider.notifier).setPostRetirementCagr(val),
              );

              final stepUpSlider = CustomFinancialSlider(
                label: 'Withdrawal Inflation Increase',
                valueDisplay: '${swpState.inflationStepUp.toStringAsFixed(1)}% / yr',
                value: swpState.inflationStepUp.clamp(0.0, 12.0),
                min: 0.0,
                max: 12.0,
                divisions: 24,
                icon: Icons.price_change_rounded,
                activeColor: AppColors.loss,
                onChanged: (val) => ref.read(swpProvider.notifier).setInflationStepUp(val),
              );

              final lifeAgeSlider = CustomFinancialSlider(
                label: 'Target Lifespan Age',
                valueDisplay: '${swpState.targetLifeAge} yrs',
                value: swpState.targetLifeAge.toDouble().clamp((retirementAge + 5).toDouble(), 100.0),
                min: (retirementAge + 5).toDouble(),
                max: 100.0,
                divisions: (100 - (retirementAge + 5)).clamp(1, 100),
                icon: Icons.favorite_rounded,
                activeColor: AppColors.info,
                onChanged: (val) => ref.read(swpProvider.notifier).setTargetLifeAge(val.round()),
              );

              if (isWide) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: withdrawalSlider),
                        const SizedBox(width: 24),
                        Expanded(child: cagrSlider),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: stepUpSlider),
                        const SizedBox(width: 24),
                        Expanded(child: lifeAgeSlider),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    withdrawalSlider,
                    const SizedBox(height: 12),
                    cagrSlider,
                    const SizedBox(height: 12),
                    stepUpSlider,
                    const SizedBox(height: 12),
                    lifeAgeSlider,
                  ],
                );
              }
            },
          ),

          // Major Retirement Milestones Outflow Section
          _buildMilestonesCard(
            swpState,
            currency,
            retirementAge,
            swpState.targetLifeAge,
            projState.currentAge,
            projState.annualInflationPercent,
          ),
          const SizedBox(height: 24),

          // Inner Sub-Tabs Navigation Bar (Schedule | Monte Carlo | Crisis Stress-Test)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildSubTabButton(0, 'Standard Schedule', Icons.table_chart_rounded),
                const SizedBox(width: 4),
                _buildSubTabButton(1, 'Monte Carlo (1,000 Runs)', Icons.casino_rounded),
                const SizedBox(width: 4),
                _buildSubTabButton(2, 'Crisis Stress-Test (SORR)', Icons.bolt_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Sub-Tab View Content
          if (!hasData)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text(
                'Add investments or set a custom starting corpus to simulate your SWP plan.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            if (_selectedSubTab == 0) ...[
              // Sub-Tab 0: Deterministic SWP Schedule & Chart
              _buildSustainabilityBanner(swpResult, currency, swpState.targetLifeAge),
              if (swpResult.recommendation != null && (!swpResult.isSustainable || swpResult.recommendation!.isStandardAtRisk)) ...[
                _buildStandardSolvencyCard(
                  swpResult.recommendation!,
                  swpResult.initialCorpus,
                  currency,
                  swpState.targetLifeAge,
                ),
              ],
              const SizedBox(height: 24),
              _buildSwpChart(swpResult, currency, retirementAge, swpState.targetLifeAge),
              const SizedBox(height: 24),
              _buildScheduleTable(swpResult, currency),
            ] else if (_selectedSubTab == 1) ...[
              // Sub-Tab 1: Monte Carlo Simulation View
              _buildMonteCarloView(
                riskState.monteCarloResult,
                riskState.volatilityPercent,
                currency,
                retirementAge,
                swpState.targetLifeAge,
                swpResult.recommendation,
                swpResult.initialCorpus,
              ),
            ] else if (_selectedSubTab == 2) ...[
              // Sub-Tab 2: Crisis Stress-Testing (SORR) View
              _buildCrisisStressTestView(
                riskState,
                currency,
                retirementAge,
                swpState.targetLifeAge,
                swpResult.recommendation,
                swpResult.initialCorpus,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedSubTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSubTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceCard : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: AppColors.gold, width: 1.2) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.gold : AppColors.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SUB-TAB 1: MONTE CARLO VIEW
  // =========================================================================
  Widget _buildMonteCarloView(
    MonteCarloResult mcResult,
    double volatility,
    CurrencyType currency,
    int startAge,
    int endAge,
    SwpSolvencyRecommendation? recommendation,
    double currentCorpus,
  ) {
    final successRate = mcResult.successRatePercent;
    Color confidenceColor;
    String confidenceLabel;

    if (successRate >= 90.0) {
      confidenceColor = AppColors.profit;
      confidenceLabel = 'VERY HIGH CONFIDENCE (${successRate.toStringAsFixed(1)}%)';
    } else if (successRate >= 75.0) {
      confidenceColor = AppColors.gold;
      confidenceLabel = 'MODERATE SUCCESS PROBABILITY (${successRate.toStringAsFixed(1)}%)';
    } else {
      confidenceColor = AppColors.loss;
      confidenceLabel = 'HIGH DEPLETION RISK (${successRate.toStringAsFixed(1)}%)';
    }

    final percentiles = mcResult.percentiles;

    double maxVal = 10000.0;
    for (final p in percentiles) {
      if (p.p90 > maxVal) maxVal = p.p90;
    }
    final maxY = (maxVal * 1.2).clamp(10000.0, double.infinity);
    final interval = (maxY / 4).clamp(1.0, double.infinity);

    final spotsP90 = <FlSpot>[...percentiles.map((p) => FlSpot(p.age.toDouble(), p.p90))];
    final spotsP50 = <FlSpot>[...percentiles.map((p) => FlSpot(p.age.toDouble(), p.p50))];
    final spotsP10 = <FlSpot>[...percentiles.map((p) => FlSpot(p.age.toDouble(), p.p10))];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Educational Guide Toggle Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.casino_rounded, color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'MONTE CARLO PROBABILISTIC SIMULATION',
                      style: AppTypography.heading3.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => setState(() => _isMonteCarloGuideExpanded = !_isMonteCarloGuideExpanded),
              icon: Icon(_isMonteCarloGuideExpanded ? Icons.expand_less : Icons.school_rounded, size: 16, color: AppColors.goldLight),
              label: Text(
                _isMonteCarloGuideExpanded ? 'Hide Guide' : '📖 Guide & Methodology',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight),
              ),
            ),
          ],
        ),

        // Collapsible Educational Guide Card
        if (_isMonteCarloGuideExpanded) _buildMonteCarloGuideCard(),
        const SizedBox(height: 12),

        // Confidence Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: confidenceColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: confidenceColor.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    successRate >= 75.0 ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: confidenceColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            confidenceLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: confidenceColor == AppColors.profit ? AppColors.profitLight : confidenceColor,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildTooltipIcon('Probability of Success: Percentage of 1,000 randomized stochastic market simulations where your retirement capital lasted until target age without premature depletion.'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricColWithTooltip(
                      label: 'P90 OPTIMISTIC BALANCE',
                      value: CurrencyFormatter.formatCompact(mcResult.optimisticFinalCorpus, currency: currency),
                      color: AppColors.profit,
                      tooltip: '90th Percentile (Top 10% Outcome): Represents a strong prolonged bull market scenario where only 10% of simulations performed better than this.',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricColWithTooltip(
                      label: 'P50 MEDIAN BALANCE',
                      value: CurrencyFormatter.formatCompact(mcResult.medianFinalCorpus, currency: currency),
                      color: AppColors.gold,
                      tooltip: '50th Percentile (Median Expected Outcome): The middle-case scenario where half of the simulations performed better and half performed worse.',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricColWithTooltip(
                      label: 'P10 WORST-CASE (10% VaR)',
                      value: CurrencyFormatter.formatCompact(mcResult.worstCaseFinalCorpus, currency: currency),
                      color: mcResult.worstCaseFinalCorpus > 0 ? AppColors.info : AppColors.loss,
                      tooltip: '10th Percentile (Pessimistic / 10% Value-at-Risk): Represents severe prolonged bear markets. 90% of market simulations performed better than this. If P10 stays positive, your portfolio has institutional-grade resilience.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Solvency Recommendation when success rate < 80%
        if (recommendation != null && (successRate < 80.0 || recommendation.isMonteCarloAtRisk)) ...[
          _buildMonteCarloSolvencyCard(
            recommendation,
            currentCorpus,
            currency,
            endAge,
          ),
        ],
        const SizedBox(height: 20),

        // Volatility Slider
        CustomFinancialSlider(
          label: 'Market Annual Volatility (Standard Deviation σ)',
          valueDisplay: '±${volatility.toStringAsFixed(1)}% σ',
          value: volatility.clamp(5.0, 25.0),
          min: 5.0,
          max: 25.0,
          divisions: 20,
          icon: Icons.tune_rounded,
          activeColor: AppColors.catEquities,
          onChanged: (val) => ref.read(riskAnalysisProvider.notifier).setVolatilityPercent(val),
        ),
        const SizedBox(height: 20),

        // Monte Carlo Percentile Fan Chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('1,000-TRIAL PERCENTILE FAN CONE', style: AppTypography.heading3.copyWith(fontSize: 14)),
                const SizedBox(width: 6),
                _buildTooltipIcon('Visualizes the cone of statistical outcomes over time: Green line (90th percentile), Gold line (Median), and Red line (10th percentile worst-case).'),
              ],
            ),
            Row(
              children: [
                _buildLegendIndicator(AppColors.profit, '90th %ile (Top 10%)'),
                const SizedBox(width: 12),
                _buildLegendIndicator(AppColors.gold, '50th %ile (Median)'),
                const SizedBox(width: 12),
                _buildLegendIndicator(AppColors.loss, '10th %ile (Worst 10%)'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
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
                    interval: (endAge - startAge) > 15 ? 5 : 2,
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
                    final color = barData.color ?? AppColors.gold;
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
                  tooltipBorder: BorderSide(color: AppColors.gold.withOpacity(0.7), width: 1.2),
                  tooltipBorderRadius: const BorderRadius.all(Radius.circular(10)),
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final intAge = spot.x.toInt();
                      String title;
                      Color color;
                      if (spot.barIndex == 0) {
                        title = 'P90 (Top 10% / Optimistic): ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}';
                        color = AppColors.profitLight;
                      } else if (spot.barIndex == 1) {
                        title = 'P50 (Median Expected): ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}';
                        color = AppColors.goldLight;
                      } else {
                        title = 'P10 (Worst 10% / Severe Bear): ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}';
                        color = AppColors.lossLight;
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
                // P90 Line
                LineChartBarData(
                  spots: spotsP90,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.profit,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                // P50 Line
                LineChartBarData(
                  spots: spotsP50,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.gold,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.gold.withOpacity(0.08),
                  ),
                ),
                // P10 Line
                LineChartBarData(
                  spots: spotsP10,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.loss,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonteCarloGuideCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
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
              const Icon(Icons.lightbulb_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                'Understanding Monte Carlo Simulation & Percentiles',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.goldLight),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• What is Monte Carlo? Real-world financial markets do not return a steady CAGR each year. Market returns fluctuate unpredictably. A Monte Carlo simulation models 1,000 independent stochastic lifetime trajectories with randomized market volatility (Box-Muller Gaussian normal returns) to test how reliably your retirement corpus withstands severe down years.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            '• P90 (Optimistic / 90th %ile): Represents a strong bull market scenario where only 10% of simulations performed better than this.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.profitLight, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            '• P50 (Median Expected): The middle-case scenario where 50% of market trials were higher and 50% were lower.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.goldLight, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            '• P10 (Pessimistic / 10% VaR): Represents severe prolonged bear markets. 90% of market trials performed better than this. If your P10 line stays above zero until your target age, your plan has institutional-grade safety.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.lossLight, height: 1.4),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SUB-TAB 2: CRISIS STRESS-TEST VIEW
  // =========================================================================
  Widget _buildCrisisStressTestView(
    RiskAnalysisState riskState,
    CurrencyType currency,
    int startAge,
    int endAge,
    SwpSolvencyRecommendation? recommendation,
    double currentCorpus,
  ) {
    final stressResult = riskState.crisisStressTestResult;
    final isResilient = stressResult.isResilient;
    final depletionAge = stressResult.depletionAge;

    final badgeColor = isResilient ? AppColors.profit : AppColors.loss;
    final statusText = isResilient
        ? 'PORTFOLIO RESILIENT: Survives ${stressResult.scenario.title} to Age $endAge'
        : 'CORPUS FAILS EARLY: Depletes at Age ${depletionAge?.toStringAsFixed(1) ?? 'N/A'} under ${stressResult.scenario.title}';

    final points = stressResult.yearlyPoints;
    double maxVal = 10000.0;
    for (final p in points) {
      if (p.baselineCorpus > maxVal) maxVal = p.baselineCorpus;
      if (p.stressedCorpus > maxVal) maxVal = p.stressedCorpus;
    }
    final maxY = (maxVal * 1.2).clamp(10000.0, double.infinity);
    final interval = (maxY / 4).clamp(1.0, double.infinity);

    final baselineSpots = <FlSpot>[...points.map((p) => FlSpot(p.age.toDouble(), p.baselineCorpus))];
    final stressedSpots = <FlSpot>[...points.map((p) => FlSpot(p.age.toDouble(), p.stressedCorpus))];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Educational Guide Toggle Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.loss, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'SEQUENCE-OF-RETURNS RISK (SORR)',
                      style: AppTypography.heading3.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => setState(() => _isCrisisGuideExpanded = !_isCrisisGuideExpanded),
              icon: Icon(_isCrisisGuideExpanded ? Icons.expand_less : Icons.school_rounded, size: 16, color: AppColors.lossLight),
              label: Text(
                _isCrisisGuideExpanded ? 'Hide Guide' : '📖 Guide & Methodology',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lossLight),
              ),
            ),
          ],
        ),

        // Collapsible Educational Guide Card
        if (_isCrisisGuideExpanded) _buildCrisisStressTestGuideCard(),
        const SizedBox(height: 12),

        // Scenario Selection Chips
        Text('SELECT HISTORICAL CRISIS IN YEAR 1 OF RETIREMENT:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CrisisScenario.values.map((s) {
            final isSelected = riskState.selectedCrisisScenario == s;
            return ChoiceChip(
              label: Text(s.title),
              selected: isSelected,
              selectedColor: AppColors.gold.withOpacity(0.2),
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide(color: isSelected ? AppColors.gold : AppColors.border),
              labelStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.goldLight : AppColors.textSecondary,
              ),
              onSelected: (_) => ref.read(riskAnalysisProvider.notifier).selectCrisisScenario(s),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Text(
          stressResult.scenario.description,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),

        if (riskState.selectedCrisisScenario == CrisisScenario.custom) ...[
          CustomFinancialSlider(
            label: 'Custom Year 1 Crash Percentage',
            valueDisplay: '${riskState.customCrashPercent.toStringAsFixed(0)}%',
            value: riskState.customCrashPercent.clamp(-50.0, -10.0),
            min: -50.0,
            max: -10.0,
            divisions: 40,
            icon: Icons.trending_down_rounded,
            activeColor: AppColors.loss,
            onChanged: (val) => ref.read(riskAnalysisProvider.notifier).setCustomCrashPercent(val),
          ),
          const SizedBox(height: 16),
        ],

        // Resilience Status Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isResilient ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
                    color: badgeColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            statusText,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isResilient ? AppColors.profitLight : AppColors.lossLight,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildTooltipIcon('Resilience Status: Tests whether your retirement portfolio survives the selected crisis crash in Year 1 of retirement or indicates the exact premature Depletion Age.'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricColWithTooltip(
                      label: 'BASELINE ENDING CORPUS',
                      value: CurrencyFormatter.formatCompact(stressResult.baselineFinalCorpus, currency: currency),
                      color: AppColors.gold,
                      tooltip: 'Baseline Ending Corpus: Your projected terminal wealth under normal expected returns without any early retirement crash shocks.',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricColWithTooltip(
                      label: 'STRESSED ENDING CORPUS',
                      value: CurrencyFormatter.formatCompact(stressResult.stressedFinalCorpus, currency: currency),
                      color: isResilient ? AppColors.profit : AppColors.loss,
                      tooltip: 'Stressed Ending Corpus: Your projected terminal wealth after suffering the historical market crash in the very first years of retirement.',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricColWithTooltip(
                      label: 'EROSION IMPACT',
                      value: CurrencyFormatter.formatCompact(
                        (stressResult.baselineFinalCorpus - stressResult.stressedFinalCorpus).clamp(0.0, double.infinity),
                        currency: currency,
                      ),
                      color: AppColors.loss,
                      tooltip: 'Erosion Impact: The net reduction in final retirement wealth caused by the early crash combined with mandatory living expense withdrawals.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Solvency Recommendation for all crisis scenarios
        if (recommendation != null && (!isResilient || recommendation.isAnyCrisisAtRisk)) ...[
          _buildCrisisSolvencyGrid(
            recommendation,
            riskState.selectedCrisisScenario,
            currentCorpus,
            currency,
            endAge,
          ),
        ],
        const SizedBox(height: 20),

        // Comparative Overlay Line Chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('BASELINE VS CRISIS OVERLAY TRAJECTORY', style: AppTypography.heading3.copyWith(fontSize: 14)),
                const SizedBox(width: 6),
                _buildTooltipIcon('Directly overlays your normal baseline trajectory against the stressed crisis trajectory to visualize the drawdown and recovery timeline.'),
              ],
            ),
            Row(
              children: [
                _buildLegendIndicator(AppColors.gold, 'Normal Baseline'),
                const SizedBox(width: 12),
                _buildLegendIndicator(AppColors.loss, 'Crisis Trajectory (Yr 1 Crash)'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
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
                    interval: (endAge - startAge) > 15 ? 5 : 2,
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
                    final color = barData.color ?? AppColors.loss;
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
                  maxContentWidth: 290,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  getTooltipColor: (_) => AppColors.surfaceCard.withOpacity(0.96),
                  tooltipBorder: BorderSide(color: AppColors.loss.withOpacity(0.7), width: 1.2),
                  tooltipBorderRadius: const BorderRadius.all(Radius.circular(10)),
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    final intAge = touchedSpots.first.x.toInt();
                    double baselineVal = 0.0;
                    double stressedVal = 0.0;

                    for (final s in touchedSpots) {
                      if (s.barIndex == 0) baselineVal = s.y;
                      if (s.barIndex == 1) stressedVal = s.y;
                    }

                    final erosionVal = (baselineVal - stressedVal).clamp(0.0, double.infinity);

                    return touchedSpots.map((spot) {
                      String title;
                      Color color;
                      if (spot.barIndex == 0) {
                        title = 'Normal Baseline: ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}';
                        color = AppColors.goldLight;
                      } else {
                        final erosionText = erosionVal > 0 ? '\nDrawdown Impact: -${CurrencyFormatter.formatCompact(erosionVal, currency: currency)}' : '';
                        title = '${stressResult.scenario.title}: ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}$erosionText';
                        color = AppColors.lossLight;
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
                // Baseline curve (Gold dashed)
                LineChartBarData(
                  spots: baselineSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.gold.withOpacity(0.6),
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                // Stressed curve (Crimson/Loss bold)
                LineChartBarData(
                  spots: stressedSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.loss,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.loss.withOpacity(0.2),
                        AppColors.loss.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrisisStressTestGuideCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.loss.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.loss, size: 18),
              const SizedBox(width: 8),
              Text(
                'Understanding Sequence-of-Returns Risk (SORR)',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lossLight),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• What is Sequence-of-Returns Risk? In the wealth accumulation phase, an early market crash is harmless because you can buy cheaper assets. But in retirement (decumulation), a crash in Year 1 or 2 is devastating because you must sell devalued units to fund living expenses. This permanently shrinks your portfolio base, eliminating future compound recovery.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            '• Baseline vs Stressed: The Baseline curve shows normal decumulation without early shocks. The Stressed curve simulates the exact drawdown sequence of historical crises hitting the day you retire.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            '• Erosion Impact: Measures the total capital lost due to the unfortunate timing of the crash combined with ongoing mandatory withdrawals.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.lossLight, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColWithTooltip({
    required String label,
    required String value,
    required Color color,
    required String tooltip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
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
            Tooltip(
              message: tooltip,
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
              child: const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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

  PopupMenuItem<double> _buildRuleMenuItem(
    double percent,
    String title,
    double corpus,
    CurrencyType currency,
  ) {
    final monthly = corpus > 0 ? (corpus * (percent / 100.0)) / 12.0 : 0.0;
    return PopupMenuItem<double>(
      value: percent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          if (corpus > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${CurrencyFormatter.formatCompact(monthly, currency: currency)} / month',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.goldLight, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSustainabilityBanner(SwpResult result, CurrencyType currency, int targetAge) {
    final isSustainable = result.isSustainable;
    final depletionAge = result.depletionAge;

    final badgeColor = isSustainable ? AppColors.profit : AppColors.loss;
    final statusText = isSustainable
        ? 'PERPETUITY / SUSTAINABLE UP TO AGE $targetAge'
        : 'CORPUS DEPLETES AT AGE ${depletionAge?.toStringAsFixed(1) ?? 'N/A'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isSustainable ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: badgeColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSustainable ? AppColors.profitLight : AppColors.lossLight,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCol(
                  'TOTAL WITHDRAWN',
                  CurrencyFormatter.formatCompact(result.totalWithdrawn, currency: currency),
                  AppColors.gold,
                ),
              ),
              Expanded(
                child: _buildMetricCol(
                  'RETURNS GENERATED',
                  CurrencyFormatter.formatCompact(result.totalReturnsEarned, currency: currency),
                  AppColors.profit,
                ),
              ),
              Expanded(
                child: _buildMetricCol(
                  'FINAL CORPUS (AGE $targetAge)',
                  CurrencyFormatter.formatCompact(result.finalCorpus, currency: currency),
                  isSustainable ? AppColors.info : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStandardSolvencyCard(
    SwpSolvencyRecommendation rec,
    double currentCorpus,
    CurrencyType currency,
    int targetAge,
  ) {
    if (rec.standardShortfall <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECOMMENDED MINIMUM STARTING CORPUS FOR SOLVENCY',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Current starting corpus (${CurrencyFormatter.formatCompact(currentCorpus, currency: currency)}) depletes prematurely. Solvency recommendation to sustain until Age $targetAge:',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSolvencyTargetItem(
            title: 'Standard SWP (100% Horizon)',
            description: 'Guarantees 0% premature depletion until Age $targetAge under expected baseline return',
            targetCorpus: rec.requiredStandardCorpus,
            shortfall: rec.standardShortfall,
            currency: currency,
            accentColor: AppColors.gold,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMonteCarloSolvencyCard(
    SwpSolvencyRecommendation rec,
    double currentCorpus,
    CurrencyType currency,
    int targetAge,
  ) {
    if (rec.mc80Shortfall <= 0 && rec.mc95Shortfall <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.casino_rounded, color: AppColors.info, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTE CARLO PROBABILISTIC SOLVENCY RECOMMENDATION',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.info,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'To achieve high stochastic confidence until Age $targetAge across 1,000 market simulations, target the starting corpus benchmarks below:',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final moderateCard = _buildSolvencyTargetItem(
                title: '80% Moderate Confidence',
                description: 'Survives 8 out of 10 market volatility paths without early exhaustion',
                targetCorpus: rec.requiredMonteCarlo80Corpus,
                shortfall: rec.mc80Shortfall,
                currency: currency,
                accentColor: AppColors.gold,
                icon: Icons.shield_outlined,
              );
              final bulletproofCard = _buildSolvencyTargetItem(
                title: '95% Bulletproof Confidence',
                description: 'Institutional-grade safety surviving 950 out of 1,000 stochastic volatility trials',
                targetCorpus: rec.requiredMonteCarlo95Corpus,
                shortfall: rec.mc95Shortfall,
                currency: currency,
                accentColor: AppColors.info,
                icon: Icons.verified_user_rounded,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    moderateCard,
                    const SizedBox(height: 8),
                    bulletproofCard,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: moderateCard),
                  const SizedBox(width: 10),
                  Expanded(child: bulletproofCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisSolvencyGrid(
    SwpSolvencyRecommendation rec,
    CrisisScenario selectedScenario,
    double currentCorpus,
    CurrencyType currency,
    int targetAge,
  ) {
    if (!rec.isAnyCrisisAtRisk) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.loss.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.loss.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.loss, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRISIS STRESS-TEST (SORR) SOLVENCY BENCHMARKS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lossLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Minimum starting corpus required to survive each historical crisis in Year 1 of retirement until Age $targetAge:',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;
              final gfcCard = _buildCrisisSolvencyItem(
                title: '2008 Financial Crisis',
                description: '-38.5% crash in Year 1',
                targetCorpus: rec.requiredGfc2008Corpus,
                shortfall: rec.gfc2008Shortfall,
                depletionAge: rec.gfc2008DepletionAge,
                targetAge: targetAge,
                currency: currency,
                icon: Icons.trending_down_rounded,
                isActive: selectedScenario == CrisisScenario.gfc2008,
              );
              final dotComCard = _buildCrisisSolvencyItem(
                title: '2000 Dot-Com Bubble',
                description: '-43.1% cumulative 3-yr drawdown',
                targetCorpus: rec.requiredDotComCorpus,
                shortfall: rec.dotComShortfall,
                depletionAge: rec.dotComDepletionAge,
                targetAge: targetAge,
                currency: currency,
                icon: Icons.computer_rounded,
                isActive: selectedScenario == CrisisScenario.dotCom2000,
              );
              final covidCard = _buildCrisisSolvencyItem(
                title: '2020 Flash Crash',
                description: '-19.6% quick shock & V-recovery',
                targetCorpus: rec.requiredCovid2020Corpus,
                shortfall: rec.covid2020Shortfall,
                depletionAge: rec.covid2020DepletionAge,
                targetAge: targetAge,
                currency: currency,
                icon: Icons.flash_on_rounded,
                isActive: selectedScenario == CrisisScenario.flashCrash2020,
              );
              final stagflationCard = _buildCrisisSolvencyItem(
                title: '1970s Stagflation',
                description: '-14.7% crash + 11% inflation surge',
                targetCorpus: rec.requiredStagflationCorpus,
                shortfall: rec.stagflationShortfall,
                depletionAge: rec.stagflationDepletionAge,
                targetAge: targetAge,
                currency: currency,
                icon: Icons.local_fire_department_rounded,
                isActive: selectedScenario == CrisisScenario.stagflation,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    gfcCard,
                    const SizedBox(height: 8),
                    dotComCard,
                    const SizedBox(height: 8),
                    covidCard,
                    const SizedBox(height: 8),
                    stagflationCard,
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: gfcCard),
                      const SizedBox(width: 10),
                      Expanded(child: dotComCard),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: covidCard),
                      const SizedBox(width: 10),
                      Expanded(child: stagflationCard),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisSolvencyItem({
    required String title,
    required String description,
    required double targetCorpus,
    required double shortfall,
    required double? depletionAge,
    required int targetAge,
    required CurrencyType currency,
    required IconData icon,
    required bool isActive,
  }) {
    final accentColor = isActive ? AppColors.gold : AppColors.loss;
    final isDepleted = depletionAge != null && depletionAge < targetAge;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.gold.withOpacity(0.08) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.gold : accentColor.withOpacity(0.35),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.goldLight : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text(
                    'ACTIVE SELECTION',
                    style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.goldLight),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, height: 1.25),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Prominent Status Badge (Depletion Age or Survives)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: isDepleted ? AppColors.loss.withOpacity(0.15) : AppColors.profit.withOpacity(0.15),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isDepleted ? AppColors.loss.withOpacity(0.4) : AppColors.profit.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDepleted ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  size: 12,
                  color: isDepleted ? AppColors.lossLight : AppColors.profitLight,
                ),
                const SizedBox(width: 4),
                Text(
                  isDepleted
                      ? 'Depletes at Age ${depletionAge.toStringAsFixed(1)}'
                      : 'Survives to Age $targetAge',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDepleted ? AppColors.lossLight : AppColors.profitLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Survival Starting Corpus & Shortfall
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Survival Starting Corpus',
                      style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      CurrencyFormatter.formatCompact(targetCorpus, currency: currency),
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: accentColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (shortfall > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.loss.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.loss.withOpacity(0.5)),
                  ),
                  child: Text(
                    '-${CurrencyFormatter.formatCompact(shortfall, currency: currency)}',
                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.lossLight),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSolvencyTargetItem({
    required String title,
    required String description,
    required double targetCorpus,
    required double shortfall,
    required CurrencyType currency,
    required Color accentColor,
    required IconData icon,
    double? secondaryTarget,
    double? secondaryShortfall,
    String? primaryLabel,
    String? secondaryLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, height: 1.25),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Primary Required Corpus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryLabel ?? 'Required Corpus',
                      style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      CurrencyFormatter.formatCompact(targetCorpus, currency: currency),
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: accentColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (shortfall > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.loss.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.loss.withOpacity(0.5)),
                  ),
                  child: Text(
                    '-${CurrencyFormatter.formatCompact(shortfall, currency: currency)}',
                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.lossLight),
                  ),
                ),
            ],
          ),

          // Optional Secondary Target (e.g. Monte Carlo 80% vs 95%)
          if (secondaryTarget != null) ...[
            const Divider(height: 14, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        secondaryLabel ?? 'Moderate (80%)',
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        CurrencyFormatter.formatCompact(secondaryTarget, currency: currency),
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if ((secondaryShortfall ?? 0) > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                    ),
                    child: Text(
                      '-${CurrencyFormatter.formatCompact(secondaryShortfall!, currency: currency)}',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.goldLight),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwpChart(SwpResult result, CurrencyType currency, int startAge, int endAge) {
    final points = result.yearlyPoints;
    if (points.isEmpty) return const SizedBox.shrink();

    double maxVal = result.initialCorpus;
    for (final p in points) {
      if (p.closingBalance > maxVal) maxVal = p.closingBalance;
    }
    final maxY = maxVal > 0 ? (maxVal * 1.2) : 100000.0;
    final interval = (maxY / 4).clamp(1.0, double.infinity);

    final spots = <FlSpot>[
      FlSpot(startAge.toDouble(), result.initialCorpus),
      ...points.map((p) => FlSpot(p.age.toDouble(), p.closingBalance)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RETIREMENT CORPUS TRAJECTORY', style: AppTypography.heading3.copyWith(fontSize: 14)),
            Row(
              children: [
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Corpus Balance', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
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
                    interval: (endAge - startAge) > 15 ? 5 : 2,
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
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: AppColors.border.withOpacity(0.8),
                        strokeWidth: 1.2,
                        dashArray: [4, 4],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 5.5,
                          color: AppColors.gold,
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
                  maxContentWidth: 260,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  getTooltipColor: (_) => AppColors.surfaceCard.withOpacity(0.96),
                  tooltipBorder: BorderSide(color: AppColors.gold.withOpacity(0.7), width: 1.2),
                  tooltipBorderRadius: const BorderRadius.all(Radius.circular(10)),
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final intAge = spot.x.toInt();
                      final yearIndex = intAge - startAge;
                      final point = (yearIndex > 0 && (yearIndex - 1) < points.length) ? points[yearIndex - 1] : null;

                      final balanceText = 'Corpus Balance: ${CurrencyFormatter.formatCompact(spot.y, currency: currency)}';
                      final withdrawnText = point != null
                          ? '\nAnnual Withdrawal: ${CurrencyFormatter.formatCompact(point.totalWithdrawn, currency: currency)}'
                          : '';
                      final milestoneText = (point != null && point.oneTimeExpenses > 0)
                          ? '\nMilestone Outflow: -${CurrencyFormatter.formatCompact(point.oneTimeExpenses, currency: currency)}'
                          : '';
                      final statusText = point != null
                          ? '\nStatus: ${point.status.label}'
                          : '';

                      return LineTooltipItem(
                        'Age $intAge (Year $yearIndex)\n$balanceText$withdrawnText$milestoneText$statusText',
                        GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldLight,
                          height: 1.35,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.gold,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.gold.withOpacity(0.25),
                        AppColors.gold.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTable(SwpResult result, CurrencyType currency) {
    final points = result.yearlyPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('YEAR-BY-YEAR SWP SCHEDULE', style: AppTypography.heading3.copyWith(fontSize: 14)),
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
                  DataColumn(label: Text('OPENING CORPUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('RETURNS EARNED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('WITHDRAWN / OUTFLOWS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('CLOSING CORPUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                  DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight))),
                ],
                rows: points.map((p) {
                  Color statusColor;
                  switch (p.status) {
                    case SwpHealthStatus.healthy:
                      statusColor = AppColors.profit;
                      break;
                    case SwpHealthStatus.moderate:
                      statusColor = AppColors.gold;
                      break;
                    case SwpHealthStatus.critical:
                    case SwpHealthStatus.depleted:
                      statusColor = AppColors.loss;
                      break;
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text('Yr ${p.year} (Age ${p.age})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                      DataCell(Text(CurrencyFormatter.formatCompact(p.openingBalance, currency: currency), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
                      DataCell(Text('+${CurrencyFormatter.formatCompact(p.returnsEarned, currency: currency)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.profit, fontWeight: FontWeight.w600))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '-${CurrencyFormatter.formatCompact(p.totalWithdrawn, currency: currency)}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.crimsonLight, fontWeight: FontWeight.w600),
                            ),
                            if (p.oneTimeExpenses > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '🎯 Outflow',
                                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.goldLight),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(Text(CurrencyFormatter.formatCompact(p.closingBalance, currency: currency), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: p.closingBalance > 0 ? AppColors.textPrimary : AppColors.loss))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            p.status.label,
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

  Widget _buildMilestonesCard(
    SwpState swpState,
    CurrencyType currency,
    int retirementAge,
    int targetLifeAge,
    int currentAge,
    double inflationRate,
  ) {
    final milestones = swpState.milestoneExpenses;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isMilestonesExpanded = !_isMilestonesExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.flag_circle_rounded, color: AppColors.gold, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'RETIREMENT MILESTONES & LUMPSUM OUTFLOWS',
                            style: AppTypography.heading3.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (milestones.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${milestones.where((m) => m.isEnabled).length} Active',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.goldLight),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showMilestoneFormDialog(
                          context,
                          retirementAge: retirementAge,
                          targetLifeAge: targetLifeAge,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 15, color: AppColors.goldLight),
                        label: Text('Add Outflow', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLight)),
                      ),
                      Icon(_isMilestonesExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textMuted, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isMilestonesExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan for major one-time expenses during retirement (e.g. medical reserves, child wedding, world travel). Outflows are auto-inflated to target age and deducted from the SWP corpus.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 10),

                  // Quick Presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetMilestoneChip(
                        name: 'Medical Reserve',
                        age: (retirementAge + 10).clamp(retirementAge + 1, targetLifeAge),
                        amount: currency == CurrencyType.inr ? 1500000.0 : 50000.0,
                        label: '+ 🏥 Medical Reserve (${CurrencyFormatter.formatCompact(currency == CurrencyType.inr ? 1500000.0 : 50000.0, currency: currency)} @ Age ${(retirementAge + 10).clamp(retirementAge + 1, targetLifeAge)})',
                      ),
                      _buildPresetMilestoneChip(
                        name: 'Child Wedding',
                        age: (retirementAge + 5).clamp(retirementAge + 1, targetLifeAge),
                        amount: currency == CurrencyType.inr ? 2500000.0 : 75000.0,
                        label: '+ 💍 Child Wedding (${CurrencyFormatter.formatCompact(currency == CurrencyType.inr ? 2500000.0 : 75000.0, currency: currency)} @ Age ${(retirementAge + 5).clamp(retirementAge + 1, targetLifeAge)})',
                      ),
                      _buildPresetMilestoneChip(
                        name: 'World Tour',
                        age: (retirementAge + 3).clamp(retirementAge + 1, targetLifeAge),
                        amount: currency == CurrencyType.inr ? 1000000.0 : 30000.0,
                        label: '+ ✈️ World Tour (${CurrencyFormatter.formatCompact(currency == CurrencyType.inr ? 1000000.0 : 30000.0, currency: currency)} @ Age ${(retirementAge + 3).clamp(retirementAge + 1, targetLifeAge)})',
                      ),
                    ],
                  ),

                  if (milestones.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...milestones.map((m) => _buildMilestoneItemRow(
                          m,
                          currency,
                          currentAge,
                          inflationRate,
                          retirementAge,
                          targetLifeAge,
                        )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetMilestoneChip({
    required String name,
    required int age,
    required double amount,
    required String label,
  }) {
    return ActionChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.goldLight)),
      backgroundColor: AppColors.surfaceCard,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onPressed: () {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        ref.read(swpProvider.notifier).addMilestoneExpense(
          SwpMilestoneExpense(
            id: id,
            name: name,
            targetAge: age,
            amount: amount,
            inTodayTerms: true,
            isEnabled: true,
          ),
        );
      },
    );
  }

  Widget _buildMilestoneItemRow(
    SwpMilestoneExpense milestone,
    CurrencyType currency,
    int currentAge,
    double inflationRate,
    int retirementAge,
    int targetLifeAge,
  ) {
    final double inflatedCost = (milestone.inTodayTerms && milestone.targetAge > currentAge)
        ? milestone.amount * math.pow(1.0 + inflationRate / 100.0, (milestone.targetAge - currentAge).toDouble())
        : milestone.amount;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: milestone.isEnabled ? AppColors.gold.withOpacity(0.5) : AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showMilestoneFormDialog(
            context,
            existingMilestone: milestone,
            retirementAge: retirementAge,
            targetLifeAge: targetLifeAge,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: milestone.isEnabled,
                  activeColor: AppColors.gold,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) => ref.read(swpProvider.notifier).toggleMilestoneExpense(milestone.id),
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
                        style: GoogleFonts.inter(fontSize: 11, color: milestone.isEnabled ? AppColors.goldLight : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.goldLight),
                  tooltip: 'Edit Outflow',
                  onPressed: () => _showMilestoneFormDialog(
                    context,
                    existingMilestone: milestone,
                    retirementAge: retirementAge,
                    targetLifeAge: targetLifeAge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                  tooltip: 'Remove Outflow',
                  onPressed: () => ref.read(swpProvider.notifier).removeMilestoneExpense(milestone.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMilestoneFormDialog(
    BuildContext context, {
    SwpMilestoneExpense? existingMilestone,
    required int retirementAge,
    required int targetLifeAge,
  }) {
    final isEditing = existingMilestone != null;
    final nameController = TextEditingController(
      text: isEditing ? existingMilestone.name : 'Major Outflow',
    );
    final amountController = TextEditingController(
      text: isEditing
          ? (existingMilestone.amount % 1 == 0
              ? existingMilestone.amount.toInt().toString()
              : existingMilestone.amount.toString())
          : '1000000',
    );
    int targetAge = isEditing
        ? existingMilestone.targetAge.clamp(retirementAge + 1, targetLifeAge)
        : (retirementAge + 5).clamp(retirementAge + 1, targetLifeAge);
    bool inTodayTerms = isEditing ? existingMilestone.inTodayTerms : true;

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
                    isEditing ? 'Edit Retirement Outflow' : 'Add Retirement Outflow',
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
                    Text('Outflow Name', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Amount', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
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
                      value: targetAge.toDouble().clamp((retirementAge + 1).toDouble(), targetLifeAge.toDouble()),
                      min: (retirementAge + 1).toDouble(),
                      max: targetLifeAge.toDouble(),
                      divisions: (targetLifeAge - (retirementAge + 1)).clamp(1, 100),
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
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount > 0) {
                      final name = nameController.text.trim().isEmpty ? 'Milestone Outflow' : nameController.text.trim();
                      if (isEditing) {
                        ref.read(swpProvider.notifier).updateMilestoneExpense(
                          existingMilestone.copyWith(
                            name: name,
                            targetAge: targetAge,
                            amount: amount,
                            inTodayTerms: inTodayTerms,
                          ),
                        );
                      } else {
                        final id = DateTime.now().millisecondsSinceEpoch.toString();
                        ref.read(swpProvider.notifier).addMilestoneExpense(
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
                  child: Text(isEditing ? 'Save Changes' : 'Add Outflow', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
