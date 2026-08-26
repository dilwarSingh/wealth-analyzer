import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/currency_formatter.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/currency_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/kpi_ribbon.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('KPIRibbon Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget({
      required Widget child,
      List<InvestmentAsset>? initialAssets,
      CurrencyType currency = CurrencyType.inr,
    }) {
      final mockDs = MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
          currencyProvider.overrideWith((ref) => CurrencyViewModel()..setCurrency(currency)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets('Given empty portfolio state, When KPIRibbon renders, Then displays default zero KPI cards', (tester) async {
      // Set desktop window size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given & When
      await tester.pumpWidget(buildTestWidget(child: const KpiRibbon()));
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('TOTAL NET WORTH'), findsOneWidget);
      expect(find.text('CAPITAL & RETURNS'), findsOneWidget);
      expect(find.text('MONTHLY SIP INFLOW'), findsOneWidget);
      expect(find.text('BLENDED RETURN (CAGR)'), findsOneWidget);
      expect(find.text('0 Assets'), findsOneWidget);
    });

    testWidgets('Given populated portfolio with mutual funds and stocks, When KPIRibbon renders, Then displays formatted net worth, gains, and monthly inflow', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();
      final assets = [
        InvestmentAsset(
          id: '1',
          name: 'Nifty 50 Index Fund',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.monthlySip,
          investedAmount: 20000.0,
          currentValue: 420000.0,
          startDate: DateTime.now(),
          expectedCAGR: 13.0,
        ),
      ];

      // Given
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataSourceProvider.overrideWithValue(mockDs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return const KpiRibbon();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: Save asset into provider
      final element = tester.element(find.byType(KpiRibbon));
      final container = ProviderScope.containerOf(element);
      await container.read(portfolioProvider.notifier).saveAsset(assets.first);
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('1 Assets'), findsOneWidget);
      expect(find.text('₹4.20 L'), findsOneWidget); // Net Worth
      expect(find.text('₹20.0 K / mo'), findsOneWidget); // Monthly SIP
    });
  });
}
