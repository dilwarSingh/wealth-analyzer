import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/fire_models.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/usecases/calculate_fire_projection.dart';
import 'currency_viewmodel.dart';
import 'portfolio_viewmodel.dart';
import 'projection_viewmodel.dart';

class FireState {
  final double monthlyExpenses;
  final double swrPercent;
  final double inflationRate;
  final double expectedReturn;
  final double stepUpSavings;
  final bool useCustomStartingCorpus;
  final double customStartingCorpus;
  final bool useCustomMonthlySavings;
  final double customMonthlySavings;
  final double leanMultiplier;
  final double fatMultiplier;
  final double baristaPartTimePercent;
  final FireCalculationResult result;

  const FireState({
    required this.monthlyExpenses,
    required this.swrPercent,
    required this.inflationRate,
    required this.expectedReturn,
    required this.stepUpSavings,
    required this.useCustomStartingCorpus,
    required this.customStartingCorpus,
    required this.useCustomMonthlySavings,
    required this.customMonthlySavings,
    required this.leanMultiplier,
    required this.fatMultiplier,
    required this.baristaPartTimePercent,
    required this.result,
  });

  factory FireState.initial() {
    return FireState(
      monthlyExpenses: 50000.0,
      swrPercent: 4.0,
      inflationRate: 6.0,
      expectedReturn: 12.0,
      stepUpSavings: 10.0,
      useCustomStartingCorpus: false,
      customStartingCorpus: 1000000.0,
      useCustomMonthlySavings: false,
      customMonthlySavings: 25000.0,
      leanMultiplier: 0.75,
      fatMultiplier: 1.35,
      baristaPartTimePercent: 40.0,
      result: FireCalculationResult.empty(),
    );
  }

  FireState copyWith({
    double? monthlyExpenses,
    double? swrPercent,
    double? inflationRate,
    double? expectedReturn,
    double? stepUpSavings,
    bool? useCustomStartingCorpus,
    double? customStartingCorpus,
    bool? useCustomMonthlySavings,
    double? customMonthlySavings,
    double? leanMultiplier,
    double? fatMultiplier,
    double? baristaPartTimePercent,
    FireCalculationResult? result,
  }) {
    return FireState(
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      swrPercent: swrPercent ?? this.swrPercent,
      inflationRate: inflationRate ?? this.inflationRate,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      stepUpSavings: stepUpSavings ?? this.stepUpSavings,
      useCustomStartingCorpus: useCustomStartingCorpus ?? this.useCustomStartingCorpus,
      customStartingCorpus: customStartingCorpus ?? this.customStartingCorpus,
      useCustomMonthlySavings: useCustomMonthlySavings ?? this.useCustomMonthlySavings,
      customMonthlySavings: customMonthlySavings ?? this.customMonthlySavings,
      leanMultiplier: leanMultiplier ?? this.leanMultiplier,
      fatMultiplier: fatMultiplier ?? this.fatMultiplier,
      baristaPartTimePercent: baristaPartTimePercent ?? this.baristaPartTimePercent,
      result: result ?? this.result,
    );
  }
}

final calculateFireProjectionUseCaseProvider = Provider<CalculateFireProjectionUseCase>((ref) {
  return CalculateFireProjectionUseCase();
});

final fireProvider = StateNotifierProvider<FireViewModel, FireState>((ref) {
  final useCase = ref.watch(calculateFireProjectionUseCaseProvider);
  final repo = ref.watch(portfolioRepositoryProvider);
  return FireViewModel(useCase, repo, ref);
});

class FireViewModel extends StateNotifier<FireState> {
  final CalculateFireProjectionUseCase _useCase;
  final PortfolioRepository? _repository;
  final Ref _ref;
  bool _isUserModified = false;

  FireViewModel(
    this._useCase,
    this._repository,
    this._ref,
  ) : super(FireState.initial()) {
    _loadStoredSettings();
    _recalculate();

    // Listen to portfolio updates (current net worth, monthly SIP, blended CAGR)
    _ref.listen<PortfolioState>(portfolioProvider, (previous, next) {
      _recalculate();
    });

    // Listen to projection timeline updates (current age, retirement age)
    _ref.listen<ProjectionState>(projectionProvider, (previous, next) {
      _recalculate();
    });

    // Listen to currency changes
    _ref.listen<CurrencyType>(currencyProvider, (previous, next) {
      _recalculate();
    });
  }

  Future<void> _loadStoredSettings() async {
    if (_repository == null) return;
    try {
      final settings = await _repository.getUserSettings();
      if (!_isUserModified) {
        state = state.copyWith(
          monthlyExpenses: settings.fireMonthlyExpenses,
          swrPercent: settings.fireSwrPercent,
          inflationRate: settings.fireInflationRate,
          expectedReturn: settings.fireExpectedReturn,
          stepUpSavings: settings.fireStepUpSavings,
          useCustomStartingCorpus: settings.fireUseCustomStarting,
          customStartingCorpus: settings.fireCustomStartingCorpus,
          useCustomMonthlySavings: settings.fireUseCustomSavings,
          customMonthlySavings: settings.fireCustomMonthlySavings,
        );
        _recalculate();
      }
    } catch (_) {}
  }

  void _persistSettings() {
    if (_repository == null) return;
    _repository.getUserSettings().then((current) {
      final updated = current.copyWith(
        fireMonthlyExpenses: state.monthlyExpenses,
        fireSwrPercent: state.swrPercent,
        fireInflationRate: state.inflationRate,
        fireExpectedReturn: state.expectedReturn,
        fireStepUpSavings: state.stepUpSavings,
        fireUseCustomStarting: state.useCustomStartingCorpus,
        fireCustomStartingCorpus: state.customStartingCorpus,
        fireUseCustomSavings: state.useCustomMonthlySavings,
        fireCustomMonthlySavings: state.customMonthlySavings,
      );
      _repository.saveUserSettings(updated);
    }).catchError((_) {});
  }

  void setMonthlyExpenses(double val) {
    _isUserModified = true;
    state = state.copyWith(monthlyExpenses: val);
    _recalculate();
    _persistSettings();
  }

  void setSwrPercent(double val) {
    _isUserModified = true;
    state = state.copyWith(swrPercent: val);
    _recalculate();
    _persistSettings();
  }

  void setInflationRate(double val) {
    _isUserModified = true;
    state = state.copyWith(inflationRate: val);
    _recalculate();
    _persistSettings();
  }

  void setExpectedReturn(double val) {
    _isUserModified = true;
    state = state.copyWith(expectedReturn: val);
    _recalculate();
    _persistSettings();
  }

  void setStepUpSavings(double val) {
    _isUserModified = true;
    state = state.copyWith(stepUpSavings: val);
    _recalculate();
    _persistSettings();
  }

  void setUseCustomStartingCorpus(bool val) {
    _isUserModified = true;
    state = state.copyWith(useCustomStartingCorpus: val);
    _recalculate();
    _persistSettings();
  }

  void setCustomStartingCorpus(double val) {
    _isUserModified = true;
    state = state.copyWith(customStartingCorpus: val);
    _recalculate();
    _persistSettings();
  }

  void setUseCustomMonthlySavings(bool val) {
    _isUserModified = true;
    state = state.copyWith(useCustomMonthlySavings: val);
    _recalculate();
    _persistSettings();
  }

  void setCustomMonthlySavings(double val) {
    _isUserModified = true;
    state = state.copyWith(customMonthlySavings: val);
    _recalculate();
    _persistSettings();
  }

  void setLeanMultiplier(double val) {
    _isUserModified = true;
    state = state.copyWith(leanMultiplier: val);
    _recalculate();
  }

  void setFatMultiplier(double val) {
    _isUserModified = true;
    state = state.copyWith(fatMultiplier: val);
    _recalculate();
  }

  void setBaristaPartTimePercent(double val) {
    _isUserModified = true;
    state = state.copyWith(baristaPartTimePercent: val);
    _recalculate();
  }

  void _recalculate() {
    final portfolioState = _ref.read(portfolioProvider);
    final projState = _ref.read(projectionProvider);

    final startingCorpus = state.useCustomStartingCorpus
        ? state.customStartingCorpus
        : portfolioState.summary.totalNetWorth;

    final monthlySavings = state.useCustomMonthlySavings
        ? state.customMonthlySavings
        : portfolioState.summary.totalMonthlySipInflow;

    final result = _useCase.execute(
      currentNetWorth: startingCorpus,
      currentMonthlySavings: monthlySavings,
      monthlyExpenses: state.monthlyExpenses,
      swrPercent: state.swrPercent,
      inflationPercent: state.inflationRate,
      annualReturnPercent: state.expectedReturn,
      stepUpSavingsPercent: state.stepUpSavings,
      currentAge: projState.currentAge,
      targetRetirementAge: projState.targetRetirementAge,
      leanMultiplier: state.leanMultiplier,
      fatMultiplier: state.fatMultiplier,
      baristaPartTimePercent: state.baristaPartTimePercent,
    );

    state = state.copyWith(result: result);
  }
}
