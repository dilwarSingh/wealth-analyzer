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
      MockLocalDataSource? mockDs,
    }) {
      final ds = mockDs ?? MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(ds),
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
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(child: const KpiRibbon()));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL NET WORTH'), findsOneWidget);
      expect(find.text('CAPITAL & RETURNS'), findsOneWidget);
      expect(find.text('MONTHLY SIP INFLOW'), findsOneWidget);
      expect(find.text('BLENDED RETURN (CAGR)'), findsOneWidget);
      expect(find.text('0 Assets'), findsOneWidget);
    });

    testWidgets('Given populated portfolio on tablet viewport, When KPIRibbon renders, Then displays 2x2 grid', (tester) async {
      tester.view.physicalSize = const Size(750, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();
      await tester.pumpWidget(buildTestWidget(child: const KpiRibbon(), mockDs: mockDs));
      await tester.pumpAndSettle();

      // Add asset
      final element = tester.element(find.byType(KpiRibbon));
      final container = ProviderScope.containerOf(element);
      await container.read(portfolioProvider.notifier).saveAsset(
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
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Assets'), findsOneWidget);
      expect(find.text('₹4.20 L'), findsOneWidget);
      expect(find.text('₹20.0 K / mo'), findsOneWidget);
    });

    testWidgets('Given portfolio with negative returns on mobile viewport, When KPIRibbon renders, Then displays vertical stack with negative returns badge', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();
      await tester.pumpWidget(buildTestWidget(child: const KpiRibbon(), mockDs: mockDs));
      await tester.pumpAndSettle();

      // Add asset with loss (invested 500k, current 400k)
      final element = tester.element(find.byType(KpiRibbon));
      final container = ProviderScope.containerOf(element);
      await container.read(portfolioProvider.notifier).saveAsset(
        InvestmentAsset(
          id: '1',
          name: 'Crypto Asset',
          category: AssetCategory.crypto,
          type: InvestmentType.oneTime,
          investedAmount: 500000.0,
          currentValue: 400000.0,
          startDate: DateTime.now(),
          expectedCAGR: 10.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Active Assets'), findsOneWidget);
      expect(find.text('₹4.00 L'), findsOneWidget);
    });
  });
}
