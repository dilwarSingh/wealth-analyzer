import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/domain/usecases/calculate_portfolio_kpis.dart';
import 'package:wealth_projector/features/portfolio/domain/usecases/calculate_growth_projection.dart';

void main() {
  group('Portfolio Use Cases Tests', () {
    final kpiUseCase = CalculatePortfolioKPIsUseCase();
    final projUseCase = CalculateGrowthProjectionUseCase();

    final testAssets = [
      InvestmentAsset(
        id: '1',
        name: 'Tech ETF',
        category: AssetCategory.equities,
        type: InvestmentType.oneTime,
        investedAmount: 100000,
        currentValue: 120000,
        startDate: DateTime.now(),
        expectedCAGR: 15.0,
      ),
      InvestmentAsset(
        id: '2',
        name: 'Bluechip SIP',
        category: AssetCategory.mutualFunds,
        type: InvestmentType.monthlySip,
        investedAmount: 10000,
        currentValue: 50000,
        startDate: DateTime.now(),
        expectedCAGR: 12.0,
        stepUpRate: 10.0,
      ),
    ];

    test('CalculatePortfolioKPIsUseCase calculates totals and gains correctly', () {
      final summary = kpiUseCase.execute(testAssets);

      expect(summary.totalNetWorth, equals(170000));
      expect(summary.totalInvestedCapital, equals(110000));
      expect(summary.totalUnrealizedGains, equals(60000));
      expect(summary.totalMonthlySipInflow, equals(10000));
      expect(summary.totalAssetCount, equals(2));
      expect(summary.categoryDistribution[AssetCategory.equities], equals(120000));
      expect(summary.categoryDistribution[AssetCategory.mutualFunds], equals(50000));
    });

    test('CalculateGrowthProjectionUseCase creates valid 3-curve simulation points', () {
      final result = projUseCase.execute(
        assets: testAssets,
        currentAge: 25,
        targetRetirementAge: 50,
        annualInflationPercent: 6.0,
        globalStepUpPercent: 10.0,
        milestoneThreshold1: 10000000, // 1 Cr
      );

      expect(result.points.length, equals(26)); // Years 0..25
      expect(result.points.first.age, equals(25));
      expect(result.points.last.age, equals(50));

      // Base net worth must be strictly greater than inflation-adjusted real value
      expect(result.points.last.baseValue, greaterThan(result.points.last.realValue));
      // Base net worth should exceed cash drag
      expect(result.points.last.baseValue, greaterThan(result.points.last.cashDragValue));
    });
  });
}
