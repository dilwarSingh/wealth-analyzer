import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/domain/usecases/calculate_portfolio_kpis.dart';

void main() {
  group('CalculatePortfolioKPIsUseCase Tests (Given - When - Then - Verify)', () {
    final useCase = CalculatePortfolioKPIsUseCase();

    // -------------------------------------------------------------
    // 1. Empty Assets List
    // -------------------------------------------------------------
    test('Given an empty assets list, When execute is invoked, Then returns empty PortfolioSummary with 0 values', () {
      // Given
      final emptyAssets = <InvestmentAsset>[];

      // When
      final summary = useCase.execute(emptyAssets);

      // Then & Verify
      expect(summary.totalAssetCount, equals(0));
      expect(summary.totalNetWorth, equals(0.0));
      expect(summary.totalInvestedCapital, equals(0.0));
      expect(summary.totalUnrealizedGains, equals(0.0));
      expect(summary.totalGainsPercent, equals(0.0));
      expect(summary.totalMonthlySipInflow, equals(0.0));
      expect(summary.blendedExpectedCagr, equals(0.0));
      expect(summary.categoryDistribution, isEmpty);
      expect(summary.categoryMonthlySip, isEmpty);
    });

    // -------------------------------------------------------------
    // 2. Newly Started Monthly SIP (0 current valuation)
    // -------------------------------------------------------------
    test('Given freshly added SIP with 0 currentValue, When execute is invoked, Then produces neutral 0% returns and populates monthly inflow allocation', () {
      // Given: 10,000/mo SIP in Nifty 50 at 12% CAGR, current valuation 0
      final assets = [
        InvestmentAsset(
          id: 'sip-fresh',
          name: 'Nifty 50 Index',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.monthlySip,
          investedAmount: 10000.0,
          currentValue: 0.0,
          startDate: DateTime.now(),
          expectedCAGR: 12.0,
        ),
      ];

      // When
      final summary = useCase.execute(assets);

      // Then & Verify
      expect(summary.totalAssetCount, equals(1));
      expect(summary.totalNetWorth, equals(0.0));
      expect(summary.totalInvestedCapital, equals(0.0));
      expect(summary.totalUnrealizedGains, equals(0.0));
      expect(summary.totalGainsPercent, equals(0.0)); // Must NOT show false -100% loss!
      expect(summary.totalMonthlySipInflow, equals(10000.0));
      expect(summary.blendedExpectedCagr, equals(12.0)); // Blended CAGR must be 12.0%
      expect(summary.categoryDistribution[AssetCategory.mutualFunds], equals(10000.0));
    });

    // -------------------------------------------------------------
    // 3. Mixed Multi-Asset Portfolio (Lump Sum + SIP)
    // -------------------------------------------------------------
    test('Given mixed portfolio with Equities Lump Sum and Mutual Fund SIP, When execute is invoked, Then aggregates net worth, gains, and blended return', () {
      // Given:
      // Asset 1: Stocks Lump Sum: 100,000 invested, 130,000 current (+30k gain), 15% CAGR
      // Asset 2: Mutual Fund SIP: 10,000/mo, 50,000 current, 12% CAGR
      final assets = [
        InvestmentAsset(
          id: '1',
          name: 'Bluechip Stock',
          category: AssetCategory.equities,
          type: InvestmentType.oneTime,
          investedAmount: 100000.0,
          currentValue: 130000.0,
          startDate: DateTime.now(),
          expectedCAGR: 15.0,
        ),
        InvestmentAsset(
          id: '2',
          name: 'Balanced Advantage SIP',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.monthlySip,
          investedAmount: 10000.0,
          currentValue: 50000.0,
          startDate: DateTime.now(),
          expectedCAGR: 12.0,
        ),
      ];

      // When
      final summary = useCase.execute(assets);

      // Then & Verify
      // Total Net Worth = 130,000 + 50,000 = 180,000
      expect(summary.totalNetWorth, equals(180000.0));
      // Total Invested = 100,000 + 10,000 = 110,000
      expect(summary.totalInvestedCapital, equals(110000.0));
      // Unrealized Gains = 180,000 - 110,000 = 70,000
      expect(summary.totalUnrealizedGains, equals(70000.0));
      // Monthly Inflow = 10,000
      expect(summary.totalMonthlySipInflow, equals(10000.0));
      expect(summary.categoryDistribution[AssetCategory.equities], equals(130000.0));
      expect(summary.categoryDistribution[AssetCategory.mutualFunds], equals(50000.0));
      expect(summary.blendedExpectedCagr, closeTo(14.16, 0.1));
    });

    // -------------------------------------------------------------
    // 4. One-Time Lump Sum with 0 Initial Valuation
    // -------------------------------------------------------------
    test('Given One-Time Lump Sum with 0 currentValue, When execute is invoked, Then uses investedAmount as effective current valuation', () {
      // Given: 25,000 in Physical Gold with 0 currentValue entered
      final assets = [
        InvestmentAsset(
          id: 'gold-1',
          name: 'Gold Bar',
          category: AssetCategory.goldPrecious,
          type: InvestmentType.oneTime,
          investedAmount: 25000.0,
          currentValue: 0.0,
          startDate: DateTime.now(),
          expectedCAGR: 10.0,
        ),
      ];

      // When
      final summary = useCase.execute(assets);

      // Then & Verify
      expect(summary.totalNetWorth, equals(25000.0));
      expect(summary.totalInvestedCapital, equals(25000.0));
      expect(summary.totalUnrealizedGains, equals(0.0));
      expect(summary.blendedExpectedCagr, equals(10.0));
      expect(summary.categoryDistribution[AssetCategory.goldPrecious], equals(25000.0));
    });

    // -------------------------------------------------------------
    // 5. Excluded Holdings (isIncluded == false)
    // -------------------------------------------------------------
    test('Given holdings where one is included and one is excluded, When execute is invoked, Then excludes unchecked asset from all calculations', () {
      final assets = [
        InvestmentAsset(
          id: 'inc-1',
          name: 'Active Stock',
          category: AssetCategory.equities,
          type: InvestmentType.oneTime,
          investedAmount: 50000.0,
          currentValue: 60000.0,
          startDate: DateTime.now(),
          expectedCAGR: 15.0,
          isIncluded: true,
        ),
        InvestmentAsset(
          id: 'exc-1',
          name: 'Disabled Real Estate',
          category: AssetCategory.realEstate,
          type: InvestmentType.oneTime,
          investedAmount: 1000000.0,
          currentValue: 1500000.0,
          startDate: DateTime.now(),
          expectedCAGR: 9.0,
          isIncluded: false, // Disabled
        ),
      ];

      final summary = useCase.execute(assets);

      expect(summary.totalAssetCount, equals(2));
      expect(summary.totalNetWorth, equals(60000.0)); // Only active asset included
      expect(summary.totalInvestedCapital, equals(50000.0));
      expect(summary.totalUnrealizedGains, equals(10000.0));
      expect(summary.categoryDistribution.containsKey(AssetCategory.realEstate), isFalse);
    });
  });
}
