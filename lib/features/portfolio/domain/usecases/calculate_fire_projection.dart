import '../../../../core/utils/financial_calculator.dart';
import '../entities/fire_models.dart';

class CalculateFireProjectionUseCase {
  FireCalculationResult execute({
    required double currentNetWorth,
    required double currentMonthlySavings,
    required double monthlyExpenses,
    required double swrPercent,
    required double inflationPercent,
    required double annualReturnPercent,
    double stepUpSavingsPercent = 0.0,
    required int currentAge,
    required int targetRetirementAge,
    double leanMultiplier = 0.75,
    double fatMultiplier = 1.35,
    double baristaPartTimePercent = 40.0,
  }) {
    return FinancialCalculator.calculateFireTrajectory(
      currentNetWorth: currentNetWorth,
      currentMonthlySavings: currentMonthlySavings,
      monthlyExpenses: monthlyExpenses,
      swrPercent: swrPercent,
      inflationPercent: inflationPercent,
      annualReturnPercent: annualReturnPercent,
      stepUpSavingsPercent: stepUpSavingsPercent,
      currentAge: currentAge,
      targetRetirementAge: targetRetirementAge,
      leanMultiplier: leanMultiplier,
      fatMultiplier: fatMultiplier,
      baristaPartTimePercent: baristaPartTimePercent,
    );
  }
}
