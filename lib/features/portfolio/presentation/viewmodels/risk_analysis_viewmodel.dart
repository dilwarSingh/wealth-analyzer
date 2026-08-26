import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/risk_analysis_models.dart';
import '../../domain/usecases/run_monte_carlo.dart';
import '../../domain/usecases/run_stress_test.dart';
import 'portfolio_viewmodel.dart';
import 'projection_viewmodel.dart';
import 'swp_viewmodel.dart';

class RiskAnalysisState {
  final double volatilityPercent;
  final bool isCustomVolatility;
  final CrisisScenario selectedCrisisScenario;
  final double customCrashPercent;
  final MonteCarloResult monteCarloResult;
  final CrisisStressTestResult crisisStressTestResult;

  const RiskAnalysisState({
    required this.volatilityPercent,
    required this.isCustomVolatility,
    required this.selectedCrisisScenario,
    required this.customCrashPercent,
    required this.monteCarloResult,
    required this.crisisStressTestResult,
  });

  factory RiskAnalysisState.initial() {
    return RiskAnalysisState(
      volatilityPercent: 15.0,
      isCustomVolatility: false,
      selectedCrisisScenario: CrisisScenario.gfc2008,
      customCrashPercent: -30.0,
      monteCarloResult: MonteCarloResult.empty(),
      crisisStressTestResult: CrisisStressTestResult.empty(CrisisScenario.gfc2008),
    );
  }

  RiskAnalysisState copyWith({
    double? volatilityPercent,
    bool? isCustomVolatility,
    CrisisScenario? selectedCrisisScenario,
    double? customCrashPercent,
    MonteCarloResult? monteCarloResult,
    CrisisStressTestResult? crisisStressTestResult,
  }) {
    return RiskAnalysisState(
      volatilityPercent: volatilityPercent ?? this.volatilityPercent,
      isCustomVolatility: isCustomVolatility ?? this.isCustomVolatility,
      selectedCrisisScenario: selectedCrisisScenario ?? this.selectedCrisisScenario,
      customCrashPercent: customCrashPercent ?? this.customCrashPercent,
      monteCarloResult: monteCarloResult ?? this.monteCarloResult,
      crisisStressTestResult: crisisStressTestResult ?? this.crisisStressTestResult,
    );
  }
}

final runMonteCarloUseCaseProvider = Provider<RunMonteCarloUseCase>((ref) {
  return RunMonteCarloUseCase();
});

final runCrisisStressTestUseCaseProvider = Provider<RunCrisisStressTestUseCase>((ref) {
  return RunCrisisStressTestUseCase();
});

final riskAnalysisProvider =
    StateNotifierProvider<RiskAnalysisViewModel, RiskAnalysisState>((ref) {
  final mcUseCase = ref.watch(runMonteCarloUseCaseProvider);
  final stressUseCase = ref.watch(runCrisisStressTestUseCaseProvider);
  final swpState = ref.read(swpProvider);
  final projState = ref.read(projectionProvider);
  final portfolioState = ref.read(portfolioProvider);
  return RiskAnalysisViewModel(mcUseCase, stressUseCase, ref, swpState, projState, portfolioState);
});

class RiskAnalysisViewModel extends StateNotifier<RiskAnalysisState> {
  final RunMonteCarloUseCase _mcUseCase;
  final RunCrisisStressTestUseCase _stressUseCase;
  final Ref _ref;

  RiskAnalysisViewModel(
    this._mcUseCase,
    this._stressUseCase,
    this._ref,
    SwpState initialSwpState,
    ProjectionState initialProjState,
    PortfolioState initialPortfolioState,
  ) : super(RiskAnalysisState.initial()) {
    // Initial volatility computation
    final blendedVol = _calculateBlendedVolatility(initialPortfolioState);
    state = state.copyWith(volatilityPercent: blendedVol);

    // Initial calculation
    _recalculate(initialSwpState, initialProjState);

    // Listen to SWP changes (monthly withdrawal, CAGR, step-up, target life age, custom corpus)
    _ref.listen<SwpState>(swpProvider, (previous, next) {
      final proj = _ref.read(projectionProvider);
      _recalculate(next, proj);
    });

    // Listen to accumulation retirement age changes
    _ref.listen<ProjectionState>(projectionProvider, (previous, next) {
      final swp = _ref.read(swpProvider);
      _recalculate(swp, next);
    });

    // Listen to portfolio asset changes to update blended volatility if not customized
    _ref.listen<PortfolioState>(portfolioProvider, (previous, next) {
      if (!state.isCustomVolatility) {
        final newVol = _calculateBlendedVolatility(next);
        state = state.copyWith(volatilityPercent: newVol);
        final swp = _ref.read(swpProvider);
        final proj = _ref.read(projectionProvider);
        _recalculate(swp, proj);
      }
    });
  }

  double _calculateBlendedVolatility(PortfolioState portfolioState) {
    final totalVal = portfolioState.assets.fold<double>(0.0, (sum, a) => sum + a.currentValue);
    if (portfolioState.assets.isEmpty || totalVal <= 0) {
      return 15.0; // Default benchmark volatility
    }

    double weightedVolSum = 0.0;
    for (final asset in portfolioState.assets) {
      final weight = asset.currentValue / totalVal;
      double catVol = 15.0;
      switch (asset.category) {
        case AssetCategory.equities:
          catVol = 18.0;
          break;
        case AssetCategory.mutualFunds:
          catVol = 13.0;
          break;
        case AssetCategory.fixedDeposit:
          catVol = 4.0;
          break;
        case AssetCategory.crypto:
          catVol = 45.0;
          break;
        case AssetCategory.goldPrecious:
          catVol = 9.0;
          break;
        case AssetCategory.realEstate:
          catVol = 8.0;
          break;
        case AssetCategory.cashSavings:
          catVol = 1.0;
          break;
        case AssetCategory.other:
          catVol = 15.0;
          break;
      }
      weightedVolSum += weight * catVol;
    }

    return weightedVolSum.clamp(5.0, 35.0);
  }

  void _recalculate(SwpState swpState, ProjectionState projState) {
    final startAge = projState.targetRetirementAge;
    final currentAge = projState.currentAge;
    final inflationRate = projState.annualInflationPercent;
    final endAge = swpState.targetLifeAge > startAge ? swpState.targetLifeAge : (startAge + 30);
    final double initialCorpus = swpState.useCustomCorpus
        ? swpState.customCorpusAmount
        : projState.simulationResult.finalBaseNetWorth;

    if (initialCorpus <= 0) {
      state = state.copyWith(
        monteCarloResult: MonteCarloResult.empty(),
        crisisStressTestResult: CrisisStressTestResult.empty(state.selectedCrisisScenario),
      );
      return;
    }

    // Run 1,000 Monte Carlo stochastic runs
    final mcResult = _mcUseCase.execute(
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: swpState.monthlyWithdrawal,
      meanAnnualReturnPercent: swpState.postRetirementCagr,
      annualVolatilityPercent: state.volatilityPercent,
      annualWithdrawalStepUpPercent: swpState.inflationStepUp,
      startAge: startAge,
      targetEndAge: endAge,
      trials: 1000,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: swpState.isWithdrawalInTodayTerms,
      annualInflationPercent: inflationRate,
      milestoneExpenses: swpState.milestoneExpenses,
    );

    // Run Crisis Stress Test
    final stressResult = _stressUseCase.execute(
      scenario: state.selectedCrisisScenario,
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: swpState.monthlyWithdrawal,
      baselineAnnualReturnPercent: swpState.postRetirementCagr,
      annualWithdrawalStepUpPercent: swpState.inflationStepUp,
      startAge: startAge,
      targetEndAge: endAge,
      customYear1CrashPercent: state.customCrashPercent,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: swpState.isWithdrawalInTodayTerms,
      annualInflationPercent: inflationRate,
      milestoneExpenses: swpState.milestoneExpenses,
    );

    state = state.copyWith(
      monteCarloResult: mcResult,
      crisisStressTestResult: stressResult,
    );
  }

  void setVolatilityPercent(double vol) {
    state = state.copyWith(
      volatilityPercent: vol,
      isCustomVolatility: true,
    );
    _recalculate(_ref.read(swpProvider), _ref.read(projectionProvider));
  }

  void selectCrisisScenario(CrisisScenario scenario) {
    state = state.copyWith(selectedCrisisScenario: scenario);
    _recalculate(_ref.read(swpProvider), _ref.read(projectionProvider));
  }

  void setCustomCrashPercent(double crashPercent) {
    state = state.copyWith(customCrashPercent: crashPercent);
    if (state.selectedCrisisScenario == CrisisScenario.custom) {
      _recalculate(_ref.read(swpProvider), _ref.read(projectionProvider));
    }
  }
}
