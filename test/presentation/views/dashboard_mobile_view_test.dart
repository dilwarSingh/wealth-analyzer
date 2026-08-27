import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/views/dashboard_mobile_view.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/add_investment_dialog.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/asset_list_table.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/donut_allocation_chart.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/empty_onboarding_card.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/fire_calculator_card.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/kpi_ribbon.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/net_worth_area_chart.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/projection_simulator_card.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/sankey_cash_flow_widget.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/swp_simulator_card.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('DashboardMobileView Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget({
      required int selectedTabIndex,
      required ValueChanged<int> onTabSelected,
      MockLocalDataSource? mockDs,
    }) {
      final ds = mockDs ?? MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(ds),
        ],
        child: MaterialApp(
          home: DashboardMobileView(
            selectedTabIndex: selectedTabIndex,
            onTabSelected: onTabSelected,
          ),
        ),
      );
    }

    testWidgets('Given empty portfolio, When DashboardMobileView renders, Then displays KpiRibbon and EmptyOnboardingCard', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int selectedTab = 0;
      await tester.pumpWidget(
        buildTestWidget(
          selectedTabIndex: selectedTab,
          onTabSelected: (idx) => selectedTab = idx,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KpiRibbon), findsOneWidget);
      expect(find.byType(EmptyOnboardingCard), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Given populated portfolio, When switching tabs 0 to 4, Then renders corresponding widgets and triggers onTabSelected', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();
      int selectedTab = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return ProviderScope(
              overrides: [
                localDataSourceProvider.overrideWithValue(mockDs),
              ],
              child: MaterialApp(
                home: DashboardMobileView(
                  selectedTabIndex: selectedTab,
                  onTabSelected: (idx) => setState(() => selectedTab = idx),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Add asset to portfolio
      final element = tester.element(find.byType(DashboardMobileView));
      final container = ProviderScope.containerOf(element);
      await container.read(portfolioProvider.notifier).saveAsset(
        InvestmentAsset(
          id: '1',
          name: 'Nifty Index Fund',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.oneTime,
          investedAmount: 500000.0,
          currentValue: 600000.0,
          startDate: DateTime.now(),
          expectedCAGR: 12.0,
        ),
      );
      await tester.pumpAndSettle();

      // Tab 0: Overview (Donut, NetWorth, Sankey, AssetList)
      expect(find.byType(DonutAllocationChart), findsOneWidget);
      expect(find.byType(NetWorthAreaChart), findsOneWidget);
      expect(find.byType(SankeyCashFlowWidget), findsOneWidget);

      // Tap Tab 1: Simulator
      await tester.tap(find.text('Simulator'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals(1));
      expect(find.byType(ProjectionSimulatorCard), findsOneWidget);
      expect(find.byType(SwpSimulatorCard), findsOneWidget);

      // Tap Tab 2: FIRE
      await tester.tap(find.text('FIRE'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals(2));
      expect(find.byType(FireCalculatorCard), findsOneWidget);

      // Tap Tab 3: Holdings
      await tester.tap(find.text('Holdings'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals(3));
      expect(find.byType(AssetListTable), findsOneWidget);

      // Tap FAB to open AddInvestmentDialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(AddInvestmentDialog), findsOneWidget);
    });
  });
}
