import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/financial_calculator.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';

void main() {
  group('FinancialCalculator Unit Tests', () {
    test('calculateLumpSumFutureValue with standard compound interest', () {
      // 100,000 at 10% CAGR for 1 year = 110,000
      final fv1 = FinancialCalculator.calculateLumpSumFutureValue(
        currentValue: 100000,
        annualCagrPercent: 10.0,
        years: 1.0,
      );
      expect(fv1, closeTo(110000, 0.01));

      // 100,000 at 12% CAGR for 10 years = 100,000 * (1.12)^10 ≈ 310584.82 (Groww lumpsum match)
      final fv10 = FinancialCalculator.calculateLumpSumFutureValue(
        currentValue: 100000,
        annualCagrPercent: 12.0,
        years: 10.0,
      );
      expect(fv10, closeTo(310584.82, 1.0));
    });

    test('calculateSipFutureValue matching Groww benchmark exactly', () {
      // 10,000/month at 12% CAGR for 10 years:
      // Invested = 12,00,000 | Est Returns = 10,40,359 | Total = 22,40,359.85
      final sipFv10Yr = FinancialCalculator.calculateSipFutureValue(
        monthlyAmount: 10000,
        annualCagrPercent: 12.0,
        years: 10.0,
        stepUpPercent: 0.0,
      );
      expect(sipFv10Yr, closeTo(2240359.85, 1.0));

      // 10,000/month at 12% CAGR for 1 year
      final sipFv1Yr = FinancialCalculator.calculateSipFutureValue(
        monthlyAmount: 10000,
        annualCagrPercent: 12.0,
        years: 1.0,
        stepUpPercent: 0.0,
      );
      // 10,000/month at 12% CAGR for 1 year = 127664.98 (Groww exact match)
      expect(sipFv1Yr, closeTo(127664.98, 1.0));
    });

    test('calculateInflationAdjustedValue discounts correctly', () {
      // 100,000 after 1 year with 6% inflation = 100,000 / 1.06 ≈ 94339.62
      final realVal = FinancialCalculator.calculateInflationAdjustedValue(
        nominalFutureValue: 100000,
        inflationRatePercent: 6.0,
        years: 1.0,
      );
      expect(realVal, closeTo(94339.62, 1.0));
    });

    test('calculateBlendedCagr calculates weighted CAGR properly', () {
      final weights = [
        (value: 100000.0, cagr: 10.0), // 100k * 10 = 1,000,000
        (value: 200000.0, cagr: 15.0), // 200k * 15 = 3,000,000
      ];
      // Total value = 300,000. Sum = 4,000,000. Blended = 4,000,000 / 300,000 ≈ 13.33%
      final blended = FinancialCalculator.calculateBlendedCagr(assetWeights: weights);
      expect(blended, closeTo(13.333, 0.01));
    });

    test('findMilestoneAge calculates crossing age', () {
      double mockGrowth(double y) => 50000 + y * 10000;

      final age = FinancialCalculator.findMilestoneAge(
        currentAge: 30,
        maxAge: 60,
        milestoneTarget: 100000,
        getPortfolioValueAtYear: mockGrowth,
      );

      expect(age, isNotNull);
      expect(age!, closeTo(35.0, 0.1));
    });

    test('InvestmentAsset calculates one-time future value falling back to investedAmount when currentValue is 0', () {
      final asset = InvestmentAsset(
        id: 'one-time-test',
        name: 'Nifty 50 Lumpsum',
        category: AssetCategory.mutualFunds,
        type: InvestmentType.oneTime,
        investedAmount: 10000,
        currentValue: 0,
        startDate: DateTime.now(),
        expectedCAGR: 10.0,
      );

      final fv10 = asset.tenYearProjectedValue;
      // 10,000 * (1.10)^10 ≈ 25937.42
      expect(fv10, closeTo(25937.42, 1.0));
    });
  });
}
