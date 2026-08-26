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

  SwpViewModel(
    this._useCase,
    this._repository,
    this._ref,
    ProjectionState initialProjState,
    CurrencyType initialCurrency,
  ) : super(SwpState.initial()) {
    _recalculate(initialProjState, initialCurrency);
    _loadStoredSettings();

    // Listen to accumulation simulator changes (retirement age, current age, inflation rate & final net worth)
    _ref.listen<ProjectionState>(projectionProvider, (previous, next) {
      final currency = _ref.read(currencyProvider);
      _recalculate(next, currency);
    });

    // Listen to currency changes
    _ref.listen<CurrencyType>(currencyProvider, (previous, next) {
      final proj = _ref.read(projectionProvider);
      _recalculate(proj, next);
    });
  }

  Future<void> _loadStoredSettings() async {
    if (_repository == null) return;
    try {
      final settings = await _repository!.getUserSettings();
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
      _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    } catch (_) {}
  }

  Future<void> _persistSettings() async {
    if (_repository == null) return;
    try {
      final current = await _repository!.getUserSettings();
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
      await _repository!.saveUserSettings(updated);
    } catch (_) {}
  }

  void _recalculate(ProjectionState projState, CurrencyType currency) {
    final startAge = projState.targetRetirementAge;
    final currentAge = projState.currentAge;
    final inflationRate = projState.annualInflationPercent;
    final int endAge = state.targetLifeAge > startAge ? state.targetLifeAge : (startAge + 30);

    // Initial corpus: either custom override or final accumulation net worth
    final double initialCorpus = state.useCustomCorpus
        ? state.customCorpusAmount
        : projState.simulationResult.finalBaseNetWorth;

    final result = _useCase.execute(
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: state.monthlyWithdrawal,
      annualReturnPercent: state.postRetirementCagr,
      annualWithdrawalStepUpPercent: state.inflationStepUp,
      startAge: startAge,
      targetEndAge: endAge,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: state.isWithdrawalInTodayTerms,
      annualInflationPercent: inflationRate,
      milestoneExpenses: state.milestoneExpenses,
    );

    state = state.copyWith(swpResult: result);
  }

  void setMonthlyWithdrawal(double amount) {
    if (amount <= 0) return;
    _isUserModified = true;
    state = state.copyWith(monthlyWithdrawal: amount);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setWithdrawalInTodayTerms(bool inToday) {
    _isUserModified = true;
    state = state.copyWith(isWithdrawalInTodayTerms: inToday);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setPostRetirementCagr(double cagr) {
    _isUserModified = true;
    state = state.copyWith(postRetirementCagr: cagr);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setInflationStepUp(double stepUp) {
    _isUserModified = true;
    state = state.copyWith(inflationStepUp: stepUp);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setTargetLifeAge(int age) {
    final startAge = _ref.read(projectionProvider).targetRetirementAge;
    if (age <= startAge) return;
    _isUserModified = true;
    state = state.copyWith(targetLifeAge: age);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setUseCustomCorpus(bool useCustom) {
    _isUserModified = true;
    state = state.copyWith(useCustomCorpus: useCustom);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void setCustomCorpusAmount(double amount) {
    if (amount <= 0) return;
    _isUserModified = true;
    state = state.copyWith(customCorpusAmount: amount);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void addMilestoneExpense(SwpMilestoneExpense expense) {
    _isUserModified = true;
    final updatedList = [...state.milestoneExpenses, expense];
    state = state.copyWith(milestoneExpenses: updatedList);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void updateMilestoneExpense(SwpMilestoneExpense updated) {
    _isUserModified = true;
    final updatedList = state.milestoneExpenses.map((m) => m.id == updated.id ? updated : m).toList();
    state = state.copyWith(milestoneExpenses: updatedList);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void removeMilestoneExpense(String id) {
    _isUserModified = true;
    final updatedList = state.milestoneExpenses.where((m) => m.id != id).toList();
    state = state.copyWith(milestoneExpenses: updatedList);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
  }

  void toggleMilestoneExpense(String id) {
    _isUserModified = true;
    final updatedList = state.milestoneExpenses.map((m) {
      if (m.id == id) {
        return m.copyWith(isEnabled: !m.isEnabled);
      }
      return m;
    }).toList();
    state = state.copyWith(milestoneExpenses: updatedList);
    _recalculate(_ref.read(projectionProvider), _ref.read(currencyProvider));
    _persistSettings();
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
