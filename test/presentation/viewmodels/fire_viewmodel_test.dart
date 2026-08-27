import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/swp_models.dart';
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
      notifier.setInflationRate(7.0);
      notifier.setExpectedReturn(14.0);
      notifier.setStepUpSavings(12.0);
      notifier.setUseCustomStartingCorpus(true);
      notifier.setCustomStartingCorpus(2000000.0);
      notifier.setUseCustomMonthlySavings(true);
      notifier.setCustomMonthlySavings(40000.0);
      notifier.setLeanMultiplier(0.70);
      notifier.setFatMultiplier(1.40);
      notifier.setBaristaPartTimePercent(0.50);

      final updatedState = container.read(fireProvider);
      expect(updatedState.monthlyExpenses, equals(80000.0));
      expect(updatedState.swrPercent, equals(3.0));
      expect(updatedState.inflationRate, equals(7.0));
      expect(updatedState.expectedReturn, equals(14.0));
      expect(updatedState.stepUpSavings, equals(12.0));
      expect(updatedState.useCustomStartingCorpus, isTrue);
      expect(updatedState.customStartingCorpus, equals(2000000.0));
      expect(updatedState.useCustomMonthlySavings, isTrue);
      expect(updatedState.customMonthlySavings, equals(40000.0));
      expect(updatedState.leanMultiplier, equals(0.70));
      expect(updatedState.fatMultiplier, equals(1.40));
      expect(updatedState.baristaPartTimePercent, equals(0.50));

      // Check persistence
      await Future.delayed(const Duration(milliseconds: 50));
      final savedSettings = await mockDs.getUserSettings();
      expect(savedSettings.fireMonthlyExpenses, equals(80000.0));
      expect(savedSettings.fireSwrPercent, equals(3.0));
    });

    test('Given Pre-FIRE milestones, When managing milestones, Then adds, updates, toggles, syncs, and removes correctly', () {
      final mockDs = MockInMemoryDataSource();
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(fireProvider.notifier);

      const m1 = SwpMilestoneExpense(
        id: 'm1',
        name: 'Higher Studies',
        targetAge: 35,
        amount: 1000000.0,
      );

      // Add
      notifier.addPreFireMilestone(m1);
      expect(container.read(fireProvider).preFireMilestones.length, equals(1));

      // Update
      notifier.updatePreFireMilestone(m1.copyWith(amount: 1500000.0));
      expect(container.read(fireProvider).preFireMilestones.first.amount, equals(1500000.0));

      // Toggle
      notifier.togglePreFireMilestone('m1');
      expect(container.read(fireProvider).preFireMilestones.first.isEnabled, isFalse);

      // Sync from SWP
      notifier.syncFromSwpMilestones([
        const SwpMilestoneExpense(
          id: 'swp-m2',
          name: 'World Tour',
          targetAge: 55,
          amount: 500000.0,
        ),
      ]);
      expect(container.read(fireProvider).preFireMilestones.length, equals(2));

      // Remove
      notifier.removePreFireMilestone('m1');
      expect(container.read(fireProvider).preFireMilestones.length, equals(1));
      expect(container.read(fireProvider).preFireMilestones.first.id, equals('swp-m2'));
    });
  });
}
