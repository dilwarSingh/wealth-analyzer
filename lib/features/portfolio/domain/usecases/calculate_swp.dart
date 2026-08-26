import '../../../../core/utils/financial_calculator.dart';
import '../entities/swp_models.dart';

class CalculateSwpUseCase {
  SwpResult execute({
    required double initialCorpus,
    required double initialMonthlyWithdrawal,
    required double annualReturnPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    int currentAge = 30,
    bool isWithdrawalInTodayTerms = true,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
    bool computeRecommendation = true,
  }) {
    return FinancialCalculator.calculateSwp(
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      annualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
      computeRecommendation: computeRecommendation,
    );
  }
}
