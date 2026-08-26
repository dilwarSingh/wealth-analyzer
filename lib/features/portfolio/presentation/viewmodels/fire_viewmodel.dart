import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/fire_models.dart';
import '../../domain/entities/swp_models.dart';
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
  final List<SwpMilestoneExpense> preFireMilestones;
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
    this.leanMultiplier = 0.75,
    this.fatMultiplier = 1.35,
    this.baristaPartTimePercent = 0.40,
    this.preFireMilestones = const [],
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
      customStartingCorpus: 5000000.0,
      useCustomMonthlySavings: false,
      customMonthlySavings: 25000.0,
      leanMultiplier: 0.75,
      fatMultiplier: 1.35,
      baristaPartTimePercent: 0.40,
      preFireMilestones: const [],
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
    List<SwpMilestoneExpense>? preFireMilestones,
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
      preFireMilestones: preFireMilestones ?? this.preFireMilestones,
      result: result ?? this.result,
    );
  }
}

final calculateFireProjectionUseCaseProvider =
    Provider<CalculateFireProjectionUseCase>((ref) {
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

    _ref.listen<PortfolioState>(portfolioProvider, (previous, next) {
      _recalculate();
    });

    _ref.listen<ProjectionState>(projectionProvider, (previous, next) {
      _recalculate();
    });

    _ref.listen<CurrencyType>(currencyProvider, (previous, next) {
      _recalculate();
    });
  }

  Future<void> _loadStoredSettings() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final settings = await repo.getUserSettings();
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
    final repo = _repository;
    if (repo == null) return;
    repo.getUserSettings().then((current) {
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
      repo.saveUserSettings(updated);
    }).catchError((_) {});
  }

  FireCalculationResult _computeResult({
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
    List<SwpMilestoneExpense>? preFireMilestones,
  }) {
    final portfolioState = _ref.read(portfolioProvider);
    final projState = _ref.read(projectionProvider);

    final useCustStart = useCustomStartingCorpus ?? state.useCustomStartingCorpus;
    final custStartVal = customStartingCorpus ?? state.customStartingCorpus;
    final startingCorpus = useCustStart ? custStartVal : portfolioState.summary.totalNetWorth;

    final useCustSav = useCustomMonthlySavings ?? state.useCustomMonthlySavings;
    final custSavVal = customMonthlySavings ?? state.customMonthlySavings;
    final monthlySavings = useCustSav ? custSavVal : portfolioState.summary.totalMonthlySipInflow;

    return _useCase.execute(
      currentNetWorth: startingCorpus,
      currentMonthlySavings: monthlySavings,
      monthlyExpenses: monthlyExpenses ?? state.monthlyExpenses,
      swrPercent: swrPercent ?? state.swrPercent,
      inflationPercent: inflationRate ?? state.inflationRate,
      annualReturnPercent: expectedReturn ?? state.expectedReturn,
      stepUpSavingsPercent: stepUpSavings ?? state.stepUpSavings,
      currentAge: projState.currentAge,
      targetRetirementAge: projState.targetRetirementAge,
      leanMultiplier: leanMultiplier ?? state.leanMultiplier,
      fatMultiplier: fatMultiplier ?? state.fatMultiplier,
      baristaPartTimePercent: baristaPartTimePercent ?? state.baristaPartTimePercent,
      preFireMilestones: preFireMilestones ?? state.preFireMilestones,
    );
  }

  void setMonthlyExpenses(double val) {
    _isUserModified = true;
    final res = _computeResult(monthlyExpenses: val);
    state = state.copyWith(monthlyExpenses: val, result: res);
    _persistSettings();
  }

  void setSwrPercent(double val) {
    _isUserModified = true;
    final res = _computeResult(swrPercent: val);
    state = state.copyWith(swrPercent: val, result: res);
    _persistSettings();
  }

  void setInflationRate(double val) {
    _isUserModified = true;
    final res = _computeResult(inflationRate: val);
    state = state.copyWith(inflationRate: val, result: res);
    _persistSettings();
  }

  void setExpectedReturn(double val) {
    _isUserModified = true;
    final res = _computeResult(expectedReturn: val);
    state = state.copyWith(expectedReturn: val, result: res);
    _persistSettings();
  }

  void setStepUpSavings(double val) {
    _isUserModified = true;
    final res = _computeResult(stepUpSavings: val);
    state = state.copyWith(stepUpSavings: val, result: res);
    _persistSettings();
  }

  void setUseCustomStartingCorpus(bool val) {
    _isUserModified = true;
    final res = _computeResult(useCustomStartingCorpus: val);
    state = state.copyWith(useCustomStartingCorpus: val, result: res);
    _persistSettings();
  }

  void setCustomStartingCorpus(double val) {
    _isUserModified = true;
    final res = _computeResult(customStartingCorpus: val);
    state = state.copyWith(customStartingCorpus: val, result: res);
    _persistSettings();
  }

  void setUseCustomMonthlySavings(bool val) {
    _isUserModified = true;
    final res = _computeResult(useCustomMonthlySavings: val);
    state = state.copyWith(useCustomMonthlySavings: val, result: res);
    _persistSettings();
  }

  void setCustomMonthlySavings(double val) {
    _isUserModified = true;
    final res = _computeResult(customMonthlySavings: val);
    state = state.copyWith(customMonthlySavings: val, result: res);
    _persistSettings();
  }

  void setLeanMultiplier(double val) {
    _isUserModified = true;
    final res = _computeResult(leanMultiplier: val);
    state = state.copyWith(leanMultiplier: val, result: res);
  }

  void setFatMultiplier(double val) {
    _isUserModified = true;
    final res = _computeResult(fatMultiplier: val);
    state = state.copyWith(fatMultiplier: val, result: res);
  }

  void setBaristaPartTimePercent(double val) {
    _isUserModified = true;
    final res = _computeResult(baristaPartTimePercent: val);
    state = state.copyWith(baristaPartTimePercent: val, result: res);
  }

  void addPreFireMilestone(SwpMilestoneExpense milestone) {
    _isUserModified = true;
    final updated = [...state.preFireMilestones, milestone];
    final res = _computeResult(preFireMilestones: updated);
    state = state.copyWith(preFireMilestones: updated, result: res);
  }

  void updatePreFireMilestone(SwpMilestoneExpense milestone) {
    _isUserModified = true;
    final updated = state.preFireMilestones.map((m) => m.id == milestone.id ? milestone : m).toList();
    final res = _computeResult(preFireMilestones: updated);
    state = state.copyWith(preFireMilestones: updated, result: res);
  }

  void removePreFireMilestone(String id) {
    _isUserModified = true;
    final updated = state.preFireMilestones.where((m) => m.id != id).toList();
    final res = _computeResult(preFireMilestones: updated);
    state = state.copyWith(preFireMilestones: updated, result: res);
  }

  void togglePreFireMilestone(String id) {
    _isUserModified = true;
    final updated = state.preFireMilestones.map((m) {
      if (m.id == id) {
        return m.copyWith(isEnabled: !m.isEnabled);
      }
      return m;
    }).toList();
    final res = _computeResult(preFireMilestones: updated);
    state = state.copyWith(preFireMilestones: updated, result: res);
  }

  void syncFromSwpMilestones(List<SwpMilestoneExpense> swpMilestones) {
    _isUserModified = true;
    final existingIds = state.preFireMilestones.map((m) => m.id).toSet();
    final updated = List<SwpMilestoneExpense>.from(state.preFireMilestones);
    for (final sm in swpMilestones) {
      if (!existingIds.contains(sm.id)) {
        updated.add(sm);
      }
    }
    final res = _computeResult(preFireMilestones: updated);
    state = state.copyWith(preFireMilestones: updated, result: res);
  }

  void _recalculate() {
    final result = _computeResult();
    state = state.copyWith(result: result);
  }
}
