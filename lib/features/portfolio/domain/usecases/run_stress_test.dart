import '../../../../core/utils/financial_calculator.dart';
import '../entities/risk_analysis_models.dart';
import '../entities/swp_models.dart';

class RunCrisisStressTestUseCase {
  CrisisStressTestResult execute({
    required CrisisScenario scenario,
    required double initialCorpus,
    required double initialMonthlyWithdrawal,
    required double baselineAnnualReturnPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    double customYear1CrashPercent = -30.0,
    int currentAge = 30,
    bool isWithdrawalInTodayTerms = true,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
  }) {
    return FinancialCalculator.runCrisisStressTest(
      scenario: scenario,
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      baselineAnnualReturnPercent: baselineAnnualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      customYear1CrashPercent: customYear1CrashPercent,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );
  }
}
