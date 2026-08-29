import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/presentation/adapters/wealth_ai_adapter.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/fire_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';

import '../viewmodels/swp_viewmodel_test.dart';

void main() {
  group('WealthAIAdapter and aiPortfolioSnapshotProvider Tests', () {
    test('Computes accurate FIRE target metrics on cold boot even if FireViewModel result is not pre-calculated', () {
      final mockDs = MockInMemoryDataSource();
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = container.read(aiPortfolioSnapshotProvider);

      // Verify that FIRE target is positive and accurately calculated
      // Monthly expenses default = 50,000, SWR default = 4.0% -> multiplier = 25.0 -> target = 1.5 Cr (15,000,000)
      expect(snapshot.fireMetrics.fireNumber, equals(15000000.0));
      expect(snapshot.fireMetrics.fireMultiplier, equals(25.0));
      expect(snapshot.fireMetrics.monthlyExpenses, equals(50000.0));
      expect(snapshot.fireMetrics.annualExpenses, equals(600000.0));
      expect(snapshot.fireMetrics.leanFireNumber, equals(15000000.0 * 0.75));
      expect(snapshot.fireMetrics.fatFireNumber, equals(15000000.0 * 1.35));
    });

    test('Reactively updates snapshot when portfolio or FIRE parameters change', () {
      final mockDs = MockInMemoryDataSource();
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(container.dispose);

      // Initial read
      final initialSnapshot = container.read(aiPortfolioSnapshotProvider);
      expect(initialSnapshot.fireMetrics.fireNumber, equals(15000000.0));

      // Modify FIRE expenses to 100,000 / month
      container.read(fireProvider.notifier).setMonthlyExpenses(100000.0);

      // Read updated snapshot
      final updatedSnapshot = container.read(aiPortfolioSnapshotProvider);
      expect(updatedSnapshot.fireMetrics.monthlyExpenses, equals(100000.0));
      expect(updatedSnapshot.fireMetrics.annualExpenses, equals(1200000.0));
      expect(updatedSnapshot.fireMetrics.fireNumber, equals(30000000.0)); // 1.2M * 25 = 3.0 Cr
    });
  });
}
