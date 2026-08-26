import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/financial_calculator.dart';

void main() {
  group('FinancialCalculator Monte Carlo Tests (Given - When - Then - Verify)', () {
    test('Given zero initial corpus or invalid parameters, When runMonteCarloSimulation is called, Then returns empty result safely', () {
      final res = FinancialCalculator.runMonteCarloSimulation(
        initialCorpus: 0.0,
        initialMonthlyWithdrawal: 50000.0,
        meanAnnualReturnPercent: 8.0,
        annualVolatilityPercent: 15.0,
        annualWithdrawalStepUpPercent: 6.0,
        startAge: 60,
        targetEndAge: 85,
      );

      expect(res.totalRuns, equals(0));
      expect(res.successRatePercent, equals(0.0));
      expect(res.percentiles, isEmpty);
    });

    test('Given large sustainable corpus (₹3 Cr, ₹40k/mo, 8% return, 12% volatility), When 1,000 runs executed with fixed seed, Then yields high success rate (> 90%) and valid percentiles', () {
      final result = FinancialCalculator.runMonteCarloSimulation(
        initialCorpus: 30000000.0, // ₹3 Cr
        initialMonthlyWithdrawal: 40000.0,
        meanAnnualReturnPercent: 8.0,
        annualVolatilityPercent: 12.0,
        annualWithdrawalStepUpPercent: 5.0,
        startAge: 60,
        targetEndAge: 85,
        trials: 1000,
        randomSeed: 42,
      );

      // Then & Verify
      expect(result.totalRuns, equals(1000));
      expect(result.successRatePercent, greaterThanOrEqualTo(90.0));
      expect(result.percentiles.length, equals(25)); // 85 - 60
      expect(result.medianFinalCorpus, greaterThan(0.0));
      expect(result.optimisticFinalCorpus, greaterThan(result.medianFinalCorpus));
      expect(result.medianFinalCorpus, greaterThanOrEqualTo(result.worstCaseFinalCorpus));
    });

    test('Given small underfunded corpus (₹20 Lakh, ₹1 Lakh/mo withdrawal), When simulated, Then produces low success rate (< 20%)', () {
      final result = FinancialCalculator.runMonteCarloSimulation(
        initialCorpus: 2000000.0,
        initialMonthlyWithdrawal: 100000.0,
        meanAnnualReturnPercent: 8.0,
        annualVolatilityPercent: 15.0,
        annualWithdrawalStepUpPercent: 5.0,
        startAge: 60,
        targetEndAge: 85,
        trials: 1000,
        randomSeed: 42,
      );

      // Then & Verify
      expect(result.successRatePercent, lessThan(20.0));
      expect(result.worstCaseFinalCorpus, equals(0.0));
    });
  });
}
