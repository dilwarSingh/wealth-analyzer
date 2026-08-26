import '../../../../core/utils/financial_calculator.dart';
import '../entities/risk_analysis_models.dart';
import '../entities/swp_models.dart';

class RunMonteCarloUseCase {
  MonteCarloResult execute({
    required double initialCorpus,
    required double initialMonthlyWithdrawal,
    required double meanAnnualReturnPercent,
    required double annualVolatilityPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    int trials = 1000,
    int? randomSeed,
    int currentAge = 30,
    bool isWithdrawalInTodayTerms = true,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
  }) {
    return FinancialCalculator.runMonteCarloSimulation(
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      meanAnnualReturnPercent: meanAnnualReturnPercent,
      annualVolatilityPercent: annualVolatilityPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      trials: trials,
      randomSeed: randomSeed,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );
  }
}
