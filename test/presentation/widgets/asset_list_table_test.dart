import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/asset_list_table.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('AssetListTable Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget({MockLocalDataSource? mockDs}) {
      final ds = mockDs ?? MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(ds),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AssetListTable(),
            ),
          ),
        ),
      );
    }

    testWidgets('Given empty holdings, When AssetListTable renders, Then displays empty placeholder', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given & When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('HOLDINGS & ASSETS'), findsOneWidget);
      expect(find.text('0 / 0 Active'), findsOneWidget);
      expect(find.text('No investment holdings found. Click "+ Add Investment" to add your first asset.'), findsOneWidget);
    });

    testWidgets('Given active asset in holdings, When rendered on desktop, Then displays table row with checkbox, name, category, and action buttons', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();
      final widget = buildTestWidget(mockDs: mockDs);

      // Given
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // When: Save asset with subcategory
      final element = tester.element(find.byType(AssetListTable));
      final container = ProviderScope.containerOf(element);
      await container.read(portfolioProvider.notifier).saveAsset(
        InvestmentAsset(
          id: 'asset-test-row',
          name: 'Infosys Tech Equity',
          category: AssetCategory.equities,
          subCategory: 'Large Cap Bluechip',
          type: InvestmentType.oneTime,
          investedAmount: 50000.0,
          currentValue: 65000.0,
          startDate: DateTime.now(),
          expectedCAGR: 15.0,
        ),
      );
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('1 / 1 Active'), findsOneWidget);
      expect(find.text('Infosys Tech Equity'), findsOneWidget);
      expect(find.text('Stocks/Equities • Large Cap Bluechip'), findsOneWidget);

      // Checkboxes exist (Header master checkbox + Row checkbox)
      expect(find.byType(Checkbox), findsNWidgets(2));

      // Tap Row Checkbox to toggle OFF
      final rowCheckbox = find.byType(Checkbox).last;
      await tester.tap(rowCheckbox);
      await tester.pumpAndSettle();

      // Verify asset is excluded
      expect(container.read(portfolioProvider).assets.first.isIncluded, isFalse);
      expect(find.text('0 / 1 Active'), findsOneWidget);
      expect(find.textContaining('All holdings are currently unchecked'), findsOneWidget);

      // Tap Check All button in banner
      await tester.tap(find.text('Check All'));
      await tester.pumpAndSettle();
      expect(container.read(portfolioProvider).assets.first.isIncluded, isTrue);
      expect(find.text('1 / 1 Active'), findsOneWidget);
    });
  });
}
