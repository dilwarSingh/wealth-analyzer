import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/projection_scenario.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/usecases/calculate_growth_projection.dart';
import 'currency_viewmodel.dart';
import 'portfolio_viewmodel.dart';

enum ChartTimeframe {
  oneYear(1, '1Y'),
  threeYears(3, '3Y'),
  fiveYears(5, '5Y'),
  tenYears(10, '10Y'),
  retirement(0, 'Max (Retire)');

  final int years;
  final String label;

  const ChartTimeframe(this.years, this.label);
}

class ProjectionState {
  final int currentAge;
  final int targetRetirementAge;
  final double annualInflationPercent;
  final double globalStepUpPercent;
  final ChartTimeframe selectedTimeframe;
  final SimulationResult simulationResult;

  const ProjectionState({
    required this.currentAge,
    required this.targetRetirementAge,
    required this.annualInflationPercent,
    required this.globalStepUpPercent,
    required this.selectedTimeframe,
    required this.simulationResult,
  });

  factory ProjectionState.initial() {
    return ProjectionState(
      currentAge: 28,
      targetRetirementAge: 55,
      annualInflationPercent: 6.0,
      globalStepUpPercent: 10.0,
      selectedTimeframe: ChartTimeframe.tenYears,
      simulationResult: SimulationResult.empty(),
    );
  }

  ProjectionState copyWith({
    int? currentAge,
    int? targetRetirementAge,
    double? annualInflationPercent,
    double? globalStepUpPercent,
    ChartTimeframe? selectedTimeframe,
    SimulationResult? simulationResult,
  }) {
    return ProjectionState(
      currentAge: currentAge ?? this.currentAge,
      targetRetirementAge: targetRetirementAge ?? this.targetRetirementAge,
      annualInflationPercent: annualInflationPercent ?? this.annualInflationPercent,
      globalStepUpPercent: globalStepUpPercent ?? this.globalStepUpPercent,
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
      simulationResult: simulationResult ?? this.simulationResult,
    );
  }
}

final calculateProjectionUseCaseProvider =
    Provider<CalculateGrowthProjectionUseCase>((ref) {
  return CalculateGrowthProjectionUseCase();
});

final projectionProvider =
    StateNotifierProvider<ProjectionViewModel, ProjectionState>((ref) {
  final useCase = ref.watch(calculateProjectionUseCaseProvider);
  final repo = ref.watch(portfolioRepositoryProvider);
  final portfolioState = ref.read(portfolioProvider);
  final currency = ref.read(currencyProvider);
  return ProjectionViewModel(useCase, repo, ref, portfolioState, currency);
});

class ProjectionViewModel extends StateNotifier<ProjectionState> {
  final CalculateGrowthProjectionUseCase _useCase;
  final PortfolioRepository? _repository;
  final Ref _ref;
  bool _isUserModified = false;

  ProjectionViewModel(
    this._useCase,
    this._repository,
    this._ref,
    PortfolioState initialPortfolioState,
    CurrencyType initialCurrency,
  ) : super(ProjectionState.initial()) {
    // Initial calculation
    _recalculate(initialPortfolioState, initialCurrency);

    // Asynchronously load stored simulator settings
    _loadStoredSettings();

    // Reactively listen to portfolio changes
    _ref.listen<PortfolioState>(portfolioProvider, (previous, next) {
      final currency = _ref.read(currencyProvider);
      _recalculate(next, currency);
    });

    // Reactively listen to currency toggle
    _ref.listen<CurrencyType>(currencyProvider, (previous, next) {
      final portfolio = _ref.read(portfolioProvider);
      _recalculate(portfolio, next);
    });
  }

  Future<void> _loadStoredSettings() async {
    if (_repository == null) return;
    try {
      final settings = await _repository!.getUserSettings();
      if (!mounted || _isUserModified) return;
      state = state.copyWith(
        currentAge: settings.currentAge,
        targetRetirementAge: settings.targetRetirementAge,
        annualInflationPercent: settings.inflationRate,
        globalStepUpPercent: settings.globalStepUpRate,
      );
      _recalculate(_ref.read(portfolioProvider), _ref.read(currencyProvider));
    } catch (_) {}
  }

  Future<void> _persistSettings() async {
    if (_repository == null) return;
    try {
      final current = await _repository!.getUserSettings();
      final updated = current.copyWith(
        currentAge: state.currentAge,
        targetRetirementAge: state.targetRetirementAge,
        inflationRate: state.annualInflationPercent,
        globalStepUpRate: state.globalStepUpPercent,
      );
      await _repository!.saveUserSettings(updated);
    } catch (_) {}
  }

  void _recalculate(PortfolioState portfolioState, CurrencyType currency) {
    // Milestone threshold: 1 Crore (10,000,000) for INR or $1 Million (1,000,000) for USD
    final milestone1 = currency == CurrencyType.inr ? 10000000.0 : 1000000.0;

    final simResult = _useCase.execute(
      assets: portfolioState.assets,
      currentAge: state.currentAge,
      targetRetirementAge: state.targetRetirementAge,
      annualInflationPercent: state.annualInflationPercent,
      globalStepUpPercent: state.globalStepUpPercent,
      milestoneThreshold1: milestone1,
    );

    state = state.copyWith(simulationResult: simResult);
  }

  void setCurrentAge(int age) {
    if (age >= state.targetRetirementAge) return;
    _isUserModified = true;
    state = state.copyWith(currentAge: age);
    _recalculate(_ref.read(portfolioProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setTargetRetirementAge(int age) {
    if (age <= state.currentAge) return;
    _isUserModified = true;
    state = state.copyWith(targetRetirementAge: age);
    _recalculate(_ref.read(portfolioProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setAnnualInflation(double inflation) {
    _isUserModified = true;
    state = state.copyWith(annualInflationPercent: inflation);
    _recalculate(_ref.read(portfolioProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setGlobalStepUp(double stepUp) {
    _isUserModified = true;
    state = state.copyWith(globalStepUpPercent: stepUp);
    _recalculate(_ref.read(portfolioProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setTimeframe(ChartTimeframe timeframe) {
    state = state.copyWith(selectedTimeframe: timeframe);
  }
}
