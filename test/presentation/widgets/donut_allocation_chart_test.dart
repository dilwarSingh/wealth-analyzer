import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/donut_allocation_chart.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('DonutAllocationChart Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget({MockLocalDataSource? mockDs}) {
      final ds = mockDs ?? MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(ds),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DonutAllocationChart(),
            ),
          ),
        ),
      );
    }

    testWidgets('Given empty portfolio, When DonutAllocationChart renders, Then displays empty placeholder state', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ASSET ALLOCATION'), findsOneWidget);
      expect(find.text('0 Categories'), findsOneWidget);
      expect(find.text('Add assets to see your category allocation breakdown.'), findsOneWidget);
    });

    testWidgets('Given portfolio with multiple assets, When DonutAllocationChart renders, Then displays category legend items and responds to taps', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();
      final widget = buildTestWidget(mockDs: mockDs);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Add 2 assets across different categories
      final element = tester.element(find.byType(DonutAllocationChart));
      final container = ProviderScope.containerOf(element);
      await container.read(portfolioProvider.notifier).saveAsset(
        InvestmentAsset(
          id: '1',
          name: 'Bluechip Fund',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.oneTime,
          investedAmount: 100000.0,
          currentValue: 100000.0,
          startDate: DateTime.now(),
          expectedCAGR: 12.0,
        ),
      );
      await container.read(portfolioProvider.notifier).saveAsset(
        InvestmentAsset(
          id: '2',
          name: 'Physical Gold',
          category: AssetCategory.goldPrecious,
          type: InvestmentType.oneTime,
          investedAmount: 50000.0,
          currentValue: 50000.0,
          startDate: DateTime.now(),
          expectedCAGR: 10.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 Categories'), findsOneWidget);
      expect(find.text('Mutual Funds/ETFs'), findsOneWidget);
      expect(find.text('Gold/Precious Metals'), findsOneWidget);

      // Tap on legend item
      await tester.tap(find.text('Mutual Funds/ETFs'));
      await tester.pumpAndSettle();
    });

    testWidgets('Given monthly SIP assets with zero currentValue, When DonutAllocationChart renders, Then uses monthly inflow fallback for center text', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();
      await tester.pumpWidget(buildTestWidget(mockDs: mockDs));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(DonutAllocationChart));
      final container = ProviderScope.containerOf(element);
      await container.read(portfolioProvider.notifier).saveAsset(
        InvestmentAsset(
          id: '1',
          name: 'SIP Only',
          category: AssetCategory.equities,
          type: InvestmentType.monthlySip,
          investedAmount: 10000.0,
          currentValue: 0.0,
          startDate: DateTime.now(),
          expectedCAGR: 12.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Categories'), findsOneWidget);
      expect(find.text('MONTHLY INFLOW'), findsOneWidget);
    });
  });
}
