import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/fire_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';

import 'swp_viewmodel_test.dart';

void main() {
  group('FireViewModel Tests (Given - When - Then - Verify)', () {
    test('Given default setup, When initialized, Then calculates Standard FIRE at 4% SWR and auto-syncs portfolio', () async {
      final mockDs = MockInMemoryDataSource();
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(container.dispose);

      // Add asset to portfolio
      await container.read(portfolioProvider.notifier).saveAsset(
        InvestmentAsset(
          id: 'test-equity',
          name: 'Nifty ETF',
          category: AssetCategory.equities,
          type: InvestmentType.oneTime,
          investedAmount: 1000000.0,
          currentValue: 1500000.0, // 15 Lakhs
          startDate: DateTime.now(),
          expectedCAGR: 12.0,
        ),
      );

      final fireState = container.read(fireProvider);

      // Monthly expenses default 50k -> Annual 600k -> 25x = 1.5 Cr (15,000,000)
      expect(fireState.monthlyExpenses, equals(50000.0));
      expect(fireState.swrPercent, equals(4.0));
      expect(fireState.result.standardFireNumber, equals(15000000.0));
      expect(fireState.result.currentNetWorth, equals(1500000.0));
      // Readiness = 1.5M / 15M = 10%
      expect(fireState.result.fireReadinessPercent, equals(10.0));
    });

    test('Given custom overrides, When user modifies expenses and SWR, Then recalculates multi-FIRE numbers and persists', () async {
      final mockDs = MockInMemoryDataSource();
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(fireProvider.notifier);

      // Change expenses to 80,000 and SWR to 3.0% (33.33x multiplier)
      notifier.setMonthlyExpenses(80000.0);
      notifier.setSwrPercent(3.0);

      final updatedState = container.read(fireProvider);
      // Annual expenses = 80k * 12 = 960,000
      // Multiplier = 100 / 3 = 33.3333x
      // Standard FIRE Number = 960,000 * (100 / 3) = 32,000,000 (3.2 Cr)
      expect(updatedState.monthlyExpenses, equals(80000.0));
      expect(updatedState.swrPercent, equals(3.0));
      expect(updatedState.result.standardFireNumber, closeTo(32000000.0, 1.0));
      expect(updatedState.result.leanFireNumber, closeTo(32000000.0 * 0.75, 1.0));
      expect(updatedState.result.fatFireNumber, closeTo(32000000.0 * 1.35, 1.0));

      // Check persistence
      await Future.delayed(const Duration(milliseconds: 50));
      final savedSettings = await mockDs.getUserSettings();
      expect(savedSettings.fireMonthlyExpenses, equals(80000.0));
      expect(savedSettings.fireSwrPercent, equals(3.0));
    });
  });
}
