import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/usecases/calculate_fire_projection.dart';

void main() {
  group('CalculateFireProjectionUseCase Tests (Given - When - Then - Verify)', () {
    final useCase = CalculateFireProjectionUseCase();

    test('Given living expenses of 40k/mo at 3.5% SWR, When execute is invoked, Then computes correct Multi-FIRE milestones', () {
      final result = useCase.execute(
        currentNetWorth: 2000000.0, // 20 Lakhs
        currentMonthlySavings: 30000.0,
        monthlyExpenses: 40000.0,
        swrPercent: 3.5,
        inflationPercent: 6.0,
        annualReturnPercent: 12.0,
        stepUpSavingsPercent: 5.0,
        currentAge: 28,
        targetRetirementAge: 50,
      );

      // Annual expenses = 480,000
      expect(result.annualExpensesToday, equals(480000.0));
      // Multiplier = 100 / 3.5 = 28.5714
      expect(result.fireMultiplier, closeTo(28.57, 0.05));
      // Standard FIRE Number = 480k * (100 / 3.5) = 13,714,285.71
      expect(result.standardFireNumber, closeTo(13714285.71, 1.0));
      expect(result.leanFireNumber, closeTo(13714285.71 * 0.75, 1.0));
      expect(result.fatFireNumber, closeTo(13714285.71 * 1.35, 1.0));
      expect(result.baristaFireNumber, closeTo(13714285.71 * 0.60, 1.0));
      expect(result.fireReadinessPercent, greaterThan(0.0));
      expect(result.yearlyPoints.length, greaterThanOrEqualTo(35));
    });
  });
}
