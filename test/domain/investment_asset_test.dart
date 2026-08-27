import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_subcategories.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';

void main() {
  group('InvestmentAsset Entity Tests (Given - When - Then - Verify)', () {
    // -------------------------------------------------------------
    // 1. One-Time Lump Sum Asset Getters & Calculations
    // -------------------------------------------------------------
    group('One-Time Lump Sum Asset', () {
      test('Given one-time asset with capital 100k and current valuation 120k, When inspected, Then returns +20% gain', () {
        // Given
        final asset = InvestmentAsset(
          id: 'asset-1',
          name: 'Tech Stock',
          category: AssetCategory.equities,
          type: InvestmentType.oneTime,
          investedAmount: 100000.0,
          currentValue: 120000.0,
          startDate: DateTime.now(),
          expectedCAGR: 15.0,
        );

        // When & Then & Verify
        expect(asset.isOneTime, isTrue);
        expect(asset.isSip, isFalse);
        expect(asset.capitalInvested, equals(100000.0));
        expect(asset.unrealizedGain, equals(20000.0));
        expect(asset.returnPercentage, equals(20.0));
      });

      test('Given one-time asset with 0 current valuation, When futureValueAfterYears is called, Then falls back to invested capital', () {
        // Given
        final asset = InvestmentAsset(
          id: 'asset-lump-0',
          name: 'Gold Ingot',
          category: AssetCategory.goldPrecious,
          type: InvestmentType.oneTime,
          investedAmount: 50000.0,
          currentValue: 0.0,
          startDate: DateTime.now(),
          expectedCAGR: 10.0,
        );

        // When
        final fv5 = asset.futureValueAfterYears(5.0);

        // Then & Verify: 50,000 * (1.10)^5 ≈ 80,525.50
        expect(fv5, closeTo(80525.50, 1.0));
      });
    });

    // -------------------------------------------------------------
    // 2. Monthly SIP Asset Getters & Calculations
    // -------------------------------------------------------------
    group('Monthly SIP Asset', () {
      test('Given freshly added SIP with 0 currentValue, When inspected, Then unrealized gains and return percentage are 0.0%', () {
        // Given
        final sipAsset = InvestmentAsset(
          id: 'sip-fresh',
          name: 'Nifty 50 Index Fund',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.monthlySip,
          investedAmount: 10000.0,
          currentValue: 0.0,
          startDate: DateTime.now(),
          expectedCAGR: 12.0,
          stepUpRate: 10.0,
        );

        // When & Then & Verify
        expect(sipAsset.isSip, isTrue);
        expect(sipAsset.capitalInvested, equals(0.0));
        expect(sipAsset.unrealizedGain, equals(0.0));
        expect(sipAsset.returnPercentage, equals(0.0));
      });

      test('Given seasoned SIP with 50,000 accumulated valuation and 10,000 monthly commitment, When inspected, Then calculates gains properly', () {
        // Given
        final sipAsset = InvestmentAsset(
          id: 'sip-seasoned',
          name: 'Smallcap SIP',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.monthlySip,
          investedAmount: 10000.0,
          currentValue: 50000.0,
          startDate: DateTime.now(),
          expectedCAGR: 15.0,
        );

        // When & Then & Verify
        expect(sipAsset.capitalInvested, equals(50000.0));
        expect(sipAsset.unrealizedGain, equals(40000.0));
      });

      test('Given monthly SIP, When futureValueAfterYears is evaluated with step-up override, Then applies override step-up rate', () {
        // Given
        final sipAsset = InvestmentAsset(
          id: 'sip-stepup',
          name: 'Flexicap SIP',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.monthlySip,
          investedAmount: 10000.0,
          currentValue: 0.0,
          startDate: DateTime.now(),
          expectedCAGR: 12.0,
          stepUpRate: 0.0, // Default 0%
        );

        // When: Call with 10% override step-up
        final fvWithStepUp = sipAsset.futureValueAfterYears(10.0, overrideStepUpRate: 10.0);
        final fvNoStepUp = sipAsset.futureValueAfterYears(10.0, overrideStepUpRate: 0.0);

        // Then & Verify
        expect(fvWithStepUp, greaterThan(fvNoStepUp));
      });
    });

    // -------------------------------------------------------------
    // 3. copyWith Immutability Test
    // -------------------------------------------------------------
    group('copyWith', () {
      test('Given existing asset, When copyWith is invoked with updated fields, Then produces updated clone preserving other fields', () {
        // Given
        final original = InvestmentAsset(
          id: 'asset-copy',
          name: 'Real Estate Fund',
          category: AssetCategory.realEstate,
          type: InvestmentType.oneTime,
          investedAmount: 500000.0,
          currentValue: 600000.0,
          startDate: DateTime(2025, 1, 1),
          expectedCAGR: 9.0,
        );

        // When
        final modified = original.copyWith(
          currentValue: 650000.0,
          expectedCAGR: 10.5,
        );

        // Then & Verify
        expect(modified.id, equals(original.id));
        expect(modified.name, equals(original.name));
        expect(modified.currentValue, equals(650000.0));
        expect(modified.expectedCAGR, equals(10.5));
      });

      test('Given asset with subCategory, When cloned with copyWith, Then preserves and updates subCategory', () {
        final original = InvestmentAsset(
          id: 'asset-sub',
          name: 'Parag Parikh Flexi Cap',
          category: AssetCategory.mutualFunds,
          subCategory: 'Equity: Flexi Cap',
          type: InvestmentType.monthlySip,
          investedAmount: 10000.0,
          currentValue: 15000.0,
          startDate: DateTime(2025, 1, 1),
          expectedCAGR: 14.0,
        );

        expect(original.subCategory, equals('Equity: Flexi Cap'));

        final updated = original.copyWith(subCategory: 'Equity: Large & Mid Cap');
        expect(updated.subCategory, equals('Equity: Large & Mid Cap'));
        expect(updated.name, equals('Parag Parikh Flexi Cap'));
      });
    });

    // -------------------------------------------------------------
    // 4. AssetSubcategories Presets & Formatting
    // -------------------------------------------------------------
    group('AssetSubcategories', () {
      test('Given various categories, When getPresetsForCategory is called, Then returns correct presets', () {
        expect(AssetSubcategories.getPresetsForCategory(AssetCategory.equities), contains('Large Cap Bluechip'));
        expect(AssetSubcategories.getPresetsForCategory(AssetCategory.realEstate), contains('Residential Flat / Apartment'));
        expect(AssetSubcategories.getPresetsForCategory(AssetCategory.goldPrecious), contains('Physical Gold (Coins / Bars)'));
        expect(AssetSubcategories.getPresetsForCategory(AssetCategory.fixedDeposit), contains('Bank Fixed Deposit (FD)'));
        expect(AssetSubcategories.getPresetsForCategory(AssetCategory.cashSavings), contains('Savings Bank Account'));
        expect(AssetSubcategories.getPresetsForCategory(AssetCategory.crypto), contains('Layer 1 (BTC, ETH, SOL)'));
        expect(AssetSubcategories.getPresetsForCategory(AssetCategory.other), contains('Venture / Angel Investment'));
      });

      test('Given Mutual Fund selections, When formatMutualFundSubcategory is called, Then formats uniformly', () {
        // Standard Level 1 + Level 2
        expect(AssetSubcategories.formatMutualFundSubcategory('Equity', 'Flexi Cap'), equals('Equity: Flexi Cap'));

        // Level 2 is null or empty
        expect(AssetSubcategories.formatMutualFundSubcategory('Debt', null), equals('Debt'));
        expect(AssetSubcategories.formatMutualFundSubcategory('Debt', ''), equals('Debt'));

        // Group is Other
        expect(AssetSubcategories.formatMutualFundSubcategory('Other', null, customText: 'Special Fund'), equals('Special Fund'));
        expect(AssetSubcategories.formatMutualFundSubcategory('Other', null, customText: '   '), equals('Other'));
        expect(AssetSubcategories.formatMutualFundSubcategory('Other', null), equals('Other'));

        // SubSub is Other
        expect(AssetSubcategories.formatMutualFundSubcategory('Equity', 'Other', customText: 'Custom Momentum'), equals('Equity: Custom Momentum'));
        expect(AssetSubcategories.formatMutualFundSubcategory('Equity', 'Other', customText: '   '), equals('Equity: Other'));
        expect(AssetSubcategories.formatMutualFundSubcategory('Equity', 'Other'), equals('Equity: Other'));
      });
    });
  });
}
