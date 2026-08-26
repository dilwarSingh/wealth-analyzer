import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/domain/usecases/calculate_growth_projection.dart';

void main() {
  group('CalculateGrowthProjectionUseCase Tests (Given - When - Then - Verify)', () {
    final useCase = CalculateGrowthProjectionUseCase();

    // -------------------------------------------------------------
    // 1. Multi-Curve Simulation Generation
    // -------------------------------------------------------------
    test('Given portfolio assets, When execute is invoked, Then produces continuous 3-curve simulation points from currentAge to targetRetirementAge', () {
      // Given
      final assets = [
        InvestmentAsset(
          id: '1',
          name: 'Nifty 50 SIP',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.monthlySip,
          investedAmount: 10000.0,
          currentValue: 0.0,
          startDate: DateTime.now(),
          expectedCAGR: 12.0,
        ),
      ];

      // When: 25 to 55 (30 years -> 31 projection points including Year 0)
      final result = useCase.execute(
        assets: assets,
        currentAge: 25,
        targetRetirementAge: 55,
        annualInflationPercent: 6.0,
        globalStepUpPercent: 0.0,
        milestoneThreshold1: 10000000.0, // 1 Crore
      );

      // Then & Verify
      expect(result.points.length, equals(31));
      expect(result.points.first.year, equals(0));
      expect(result.points.first.age, equals(25));
      expect(result.points.last.year, equals(30));
      expect(result.points.last.age, equals(55));

      // Final Horizon Values
      expect(result.finalBaseNetWorth, greaterThan(result.finalRealNetWorth));
      expect(result.finalBaseNetWorth, greaterThan(result.finalCashDragNetWorth));
      expect(result.finalInvestedCapital, equals(10000.0 * 12 * 30)); // 36 Lakhs invested
    });

    // -------------------------------------------------------------
    // 2. Global vs Asset-Specific Step-Up Overrides
    // -------------------------------------------------------------
    test('Given asset with custom step-up rate, When calculated, Then asset-specific step up takes precedence over global default', () {
      // Given: Asset with 15% custom step-up vs global 5%
      final assetCustomStepUp = InvestmentAsset(
        id: 'stepup-asset',
        name: 'High Step-up SIP',
        category: AssetCategory.mutualFunds,
        type: InvestmentType.monthlySip,
        investedAmount: 10000.0,
        currentValue: 0.0,
        startDate: DateTime.now(),
        expectedCAGR: 12.0,
        stepUpRate: 15.0,
      );

      // When
      final result = useCase.execute(
        assets: [assetCustomStepUp],
        currentAge: 30,
        targetRetirementAge: 40,
        annualInflationPercent: 6.0,
        globalStepUpPercent: 5.0,
        milestoneThreshold1: 10000000.0,
      );

      // Then & Verify: Year 1 total invested should reflect 15% step-up in year 2 (120k + 138k = 258k)
      expect(result.points[2].totalInvested, equals(258000.0));
    });

    // -------------------------------------------------------------
    // 3. Milestone Age Solver Resolution
    // -------------------------------------------------------------
    test('Given high-growth compounding portfolio, When target milestone is crossed, Then milestone age is accurately resolved', () {
      // Given: Large lump sum of 50 Lakhs at 15% CAGR
      final assets = [
        InvestmentAsset(
          id: 'lump-large',
          name: 'Tech Growth Fund',
          category: AssetCategory.equities,
          type: InvestmentType.oneTime,
          investedAmount: 5000000.0,
          currentValue: 5000000.0,
          startDate: DateTime.now(),
          expectedCAGR: 15.0,
        ),
      ];

      // When: Target 1 Crore (doubling at 15% takes ~5 years -> Age 30 to 35)
      final result = useCase.execute(
        assets: assets,
        currentAge: 30,
        targetRetirementAge: 60,
        annualInflationPercent: 6.0,
        globalStepUpPercent: 0.0,
        milestoneThreshold1: 10000000.0, // 1 Cr
      );

      // Then & Verify: 50L * (1.15)^t = 100L -> t = ln(2)/ln(1.15) ≈ 4.95 years -> Age ~34.95
      expect(result.milestoneAge1CrOr1M, isNotNull);
      expect(result.milestoneAge1CrOr1M!, closeTo(35.0, 0.5));
    });

    // -------------------------------------------------------------
    // 4. Invalid Horizon Parameters Edge Case
    // -------------------------------------------------------------
    test('Given target retirement age <= current age or empty assets, When execute is invoked, Then returns empty SimulationResult', () {
      // When
      final emptyResult = useCase.execute(
        assets: [],
        currentAge: 30,
        targetRetirementAge: 50,
        annualInflationPercent: 6.0,
        globalStepUpPercent: 0.0,
        milestoneThreshold1: 10000000.0,
      );
      final invalidAgeResult = useCase.execute(
        assets: [
          InvestmentAsset(
            id: '1',
            name: 'Test',
            category: AssetCategory.equities,
            type: InvestmentType.oneTime,
            investedAmount: 1000,
            currentValue: 1000,
            startDate: DateTime.now(),
            expectedCAGR: 10,
          )
        ],
        currentAge: 55,
        targetRetirementAge: 50, // Retirement age earlier than current age
        annualInflationPercent: 6.0,
        globalStepUpPercent: 0.0,
        milestoneThreshold1: 10000000.0,
      );

      // Then & Verify
      expect(emptyResult.points, isEmpty);
      expect(invalidAgeResult.points, isEmpty);
    });
  });
}
