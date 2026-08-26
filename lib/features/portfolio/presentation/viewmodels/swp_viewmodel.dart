import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/swp_models.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/usecases/calculate_swp.dart';
import 'currency_viewmodel.dart';
import 'portfolio_viewmodel.dart';
import 'projection_viewmodel.dart';

class SwpState {
  final double monthlyWithdrawal;
  final double postRetirementCagr;
  final double inflationStepUp;
  final int targetLifeAge;
  final bool useCustomCorpus;
  final double customCorpusAmount;
  final bool isWithdrawalInTodayTerms;
  final List<SwpMilestoneExpense> milestoneExpenses;
  final SwpResult swpResult;

  const SwpState({
    required this.monthlyWithdrawal,
    required this.postRetirementCagr,
    required this.inflationStepUp,
    required this.targetLifeAge,
    required this.useCustomCorpus,
    required this.customCorpusAmount,
    required this.isWithdrawalInTodayTerms,
    required this.milestoneExpenses,
    required this.swpResult,
  });

  factory SwpState.initial() {
    return SwpState(
      monthlyWithdrawal: 50000.0,
      postRetirementCagr: 8.0,
      inflationStepUp: 6.0,
      targetLifeAge: 85,
      useCustomCorpus: false,
      customCorpusAmount: 10000000.0,
      isWithdrawalInTodayTerms: true,
      milestoneExpenses: const [],
      swpResult: SwpResult.empty(),
    );
  }

  SwpState copyWith({
    double? monthlyWithdrawal,
    double? postRetirementCagr,
    double? inflationStepUp,
    int? targetLifeAge,
    bool? useCustomCorpus,
    double? customCorpusAmount,
    bool? isWithdrawalInTodayTerms,
    List<SwpMilestoneExpense>? milestoneExpenses,
    SwpResult? swpResult,
  }) {
    return SwpState(
      monthlyWithdrawal: monthlyWithdrawal ?? this.monthlyWithdrawal,
      postRetirementCagr: postRetirementCagr ?? this.postRetirementCagr,
      inflationStepUp: inflationStepUp ?? this.inflationStepUp,
      targetLifeAge: targetLifeAge ?? this.targetLifeAge,
      useCustomCorpus: useCustomCorpus ?? this.useCustomCorpus,
      customCorpusAmount: customCorpusAmount ?? this.customCorpusAmount,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms ?? this.isWithdrawalInTodayTerms,
      milestoneExpenses: milestoneExpenses ?? this.milestoneExpenses,
      swpResult: swpResult ?? this.swpResult,
    );
  }
}

final calculateSwpUseCaseProvider = Provider<CalculateSwpUseCase>((ref) {
  return CalculateSwpUseCase();
});

final swpProvider = StateNotifierProvider<SwpViewModel, SwpState>((ref) {
  final useCase = ref.watch(calculateSwpUseCaseProvider);
  final repo = ref.watch(portfolioRepositoryProvider);
  final projState = ref.read(projectionProvider);
  final currency = ref.read(currencyProvider);
  return SwpViewModel(useCase, repo, ref, projState, currency);
});

class SwpViewModel extends StateNotifier<SwpState> {
  final CalculateSwpUseCase _useCase;
  final PortfolioRepository? _repository;
  final Ref _ref;
  bool _isUserModified = false;
  Timer? _persistDebounceTimer;
  Timer? _solvencyDebounceTimer;

  SwpViewModel(
    this._useCase,
    this._repository,
    this._ref,
    ProjectionState initialProjState,
    CurrencyType initialCurrency,
  ) : super(SwpState.initial()) {
    _recalculate(initialProjState, initialCurrency, immediateRecommendation: true);
    _loadStoredSettings();

    // Listen to accumulation simulator changes (retirement age, current age, inflation rate & final net worth)
    _ref.listen<ProjectionState>(projectionProvider, (previous, next) {
      final currency = _ref.read(currencyProvider);
      _recalculate(next, currency, immediateRecommendation: false);
    });

    // Listen to currency changes
    _ref.listen<CurrencyType>(currencyProvider, (previous, next) {
      final proj = _ref.read(projectionProvider);
      _recalculate(proj, next, immediateRecommendation: false);
    });
  }

  @override
  void dispose() {
    _persistDebounceTimer?.cancel();
    _solvencyDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStoredSettings() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final settings = await repo.getUserSettings();
      if (!mounted || _isUserModified) return;
      state = state.copyWith(
        monthlyWithdrawal: settings.swpMonthlyWithdrawal,
        postRetirementCagr: settings.swpPostRetirementCagr,
        inflationStepUp: settings.swpInflationStepUp,
        targetLifeAge: settings.swpTargetLifeAge,
        useCustomCorpus: settings.swpUseCustomCorpus,
        customCorpusAmount: settings.swpCustomCorpusAmount,
        isWithdrawalInTodayTerms: settings.swpWithdrawalInTodayTerms,
        milestoneExpenses: settings.swpMilestoneExpenses,
      );
      _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider), immediateRecommendation: true);
    } catch (_) {}
  }

  Future<void> _persistSettings() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final current = await repo.getUserSettings();
      final updated = current.copyWith(
        swpMonthlyWithdrawal: state.monthlyWithdrawal,
        swpPostRetirementCagr: state.postRetirementCagr,
        swpInflationStepUp: state.inflationStepUp,
        swpTargetLifeAge: state.targetLifeAge,
        swpUseCustomCorpus: state.useCustomCorpus,
        swpCustomCorpusAmount: state.customCorpusAmount,
        swpWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
        swpMilestoneExpenses: state.milestoneExpenses,
      );
      await repo.saveUserSettings(updated);
    } catch (_) {}
  }

  void _debounceSolvencyRecommendation() {
    _solvencyDebounceTimer?.cancel();
    _solvencyDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _computeAndApplySolvencyRecommendation();
    });
  }

  void _computeAndApplySolvencyRecommendation() {
    final proj = _ref.read(projectionProvider);
    final fullResult = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: state.milestoneExpenses,
      projState: proj,
      computeRecommendation: true,
    );
    state = state.copyWith(swpResult: fullResult);
  }

  SwpResult _calculateSwpResult({
    required double monthlyWithdrawal,
    required double postRetirementCagr,
    required double inflationStepUp,
    required int targetLifeAge,
    required bool useCustomCorpus,
    required double customCorpusAmount,
    required bool isWithdrawalInTodayTerms,
    required List<SwpMilestoneExpense> milestoneExpenses,
    required ProjectionState projState,
    bool computeRecommendation = false,
  }) {
    final startAge = projState.targetRetirementAge;
    final currentAge = projState.currentAge;
    final inflationRate = projState.annualInflationPercent;
    final int endAge = targetLifeAge > startAge ? targetLifeAge : (startAge + 30);

    final double initialCorpus = useCustomCorpus
        ? customCorpusAmount
        : projState.simulationResult.finalBaseNetWorth;

    return _useCase.execute(
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: monthlyWithdrawal,
      annualReturnPercent: postRetirementCagr,
      annualWithdrawalStepUpPercent: inflationStepUp,
      startAge: startAge,
      targetEndAge: endAge,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: inflationRate,
      milestoneExpenses: milestoneExpenses,
      computeRecommendation: computeRecommendation,
    );
  }

  void _recalculate(ProjectionState projState, CurrencyType currency, {bool immediateRecommendation = false}) {
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: state.milestoneExpenses,
      projState: projState,
      computeRecommendation: immediateRecommendation,
    );

    state = state.copyWith(
      swpResult: immediateRecommendation
          ? result
          : result.copyWith(recommendation: state.swpResult.recommendation),
    );

    if (!immediateRecommendation) {
      _debounceSolvencyRecommendation();
    }
  }

  void setMonthlyWithdrawal(double amount) {
    if (amount <= 0) return;
    _isUserModified = true;
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: amount,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: state.milestoneExpenses,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      monthlyWithdrawal: amount,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void setWithdrawalInTodayTerms(bool inToday) {
    _isUserModified = true;
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: inToday,
      milestoneExpenses: state.milestoneExpenses,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      isWithdrawalInTodayTerms: inToday,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void setPostRetirementCagr(double cagr) {
    _isUserModified = true;
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: cagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: state.milestoneExpenses,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      postRetirementCagr: cagr,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void setInflationStepUp(double stepUp) {
    _isUserModified = true;
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: stepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: state.milestoneExpenses,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      inflationStepUp: stepUp,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void setTargetLifeAge(int age) {
    final startAge = _ref.read(projectionProvider).targetRetirementAge;
    if (age <= startAge) return;
    _isUserModified = true;
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: age,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: state.milestoneExpenses,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      targetLifeAge: age,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void setUseCustomCorpus(bool useCustom) {
    _isUserModified = true;
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: useCustom,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: state.milestoneExpenses,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      useCustomCorpus: useCustom,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void setCustomCorpusAmount(double amount) {
    if (amount <= 0) return;
    _isUserModified = true;
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: amount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: state.milestoneExpenses,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      customCorpusAmount: amount,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void addMilestoneExpense(SwpMilestoneExpense expense) {
    _isUserModified = true;
    final updatedList = [...state.milestoneExpenses, expense];
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: updatedList,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      milestoneExpenses: updatedList,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void updateMilestoneExpense(SwpMilestoneExpense updated) {
    _isUserModified = true;
    final updatedList = state.milestoneExpenses.map((m) => m.id == updated.id ? updated : m).toList();
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: updatedList,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      milestoneExpenses: updatedList,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void removeMilestoneExpense(String id) {
    _isUserModified = true;
    final updatedList = state.milestoneExpenses.where((m) => m.id != id).toList();
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: updatedList,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      milestoneExpenses: updatedList,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  void toggleMilestoneExpense(String id) {
    _isUserModified = true;
    final updatedList = state.milestoneExpenses.map((m) {
      if (m.id == id) {
        return m.copyWith(isEnabled: !m.isEnabled);
      }
      return m;
    }).toList();
    final proj = _ref.read(projectionProvider);
    final result = _calculateSwpResult(
      monthlyWithdrawal: state.monthlyWithdrawal,
      postRetirementCagr: state.postRetirementCagr,
      inflationStepUp: state.inflationStepUp,
      targetLifeAge: state.targetLifeAge,
      useCustomCorpus: state.useCustomCorpus,
      customCorpusAmount: state.customCorpusAmount,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      milestoneExpenses: updatedList,
      projState: proj,
      computeRecommendation: false,
    );
    state = state.copyWith(
      milestoneExpenses: updatedList,
      swpResult: result.copyWith(recommendation: state.swpResult.recommendation),
    );
    _persistSettings();
    _debounceSolvencyRecommendation();
  }

  /// Apply a Safe Withdrawal Rule (e.g. 2%, 3%, 4%, 5%): Initial monthly withdrawal = (Corpus * (percentage / 100)) / 12
  void applyWithdrawalRule(double percentage) {
    if (percentage <= 0) return;
    final projState = _ref.read(projectionProvider);
    final corpus = state.useCustomCorpus
        ? state.customCorpusAmount
        : projState.simulationResult.finalBaseNetWorth;
    if (corpus > 0) {
      final monthly = (corpus * (percentage / 100.0)) / 12.0;
      // If currently in today's terms, discount monthly to today's purchasing power
      if (state.isWithdrawalInTodayTerms && projState.targetRetirementAge > projState.currentAge) {
        final double discountFactor = (1.0 + projState.annualInflationPercent / 100.0);
        final int years = projState.targetRetirementAge - projState.currentAge;
        final discountedMonthly = monthly / math.pow(discountFactor, years.toDouble());
        setMonthlyWithdrawal(discountedMonthly);
      } else {
        setMonthlyWithdrawal(monthly);
      }
    }
  }

  /// Convenience method for standard 4% Trinity rule
  void applySafeFourPercentRule() {
    applyWithdrawalRule(4.0);
  }
}
