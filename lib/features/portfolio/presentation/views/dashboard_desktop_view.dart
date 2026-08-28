import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import '../widgets/asset_list_table.dart';
import '../widgets/donut_allocation_chart.dart';
import '../widgets/empty_onboarding_card.dart';
import '../widgets/fire_calculator_card.dart';
import '../widgets/kpi_ribbon.dart';
import '../widgets/net_worth_area_chart.dart';
import '../widgets/projection_simulator_card.dart';
import '../widgets/sankey_cash_flow_widget.dart';
import '../widgets/swp_simulator_card.dart';

class DashboardDesktopView extends ConsumerWidget {
  final int selectedTabIndex;

  const DashboardDesktopView({super.key, required this.selectedTabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioState = ref.watch(portfolioProvider);
    final hasAssets = portfolioState.assets.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top KPI Ribbon
              const KpiRibbon(),
              const SizedBox(height: 24),

              if (!hasAssets)
                const EmptyOnboardingCard()
              else ...[
                // Tab-specific or Grid Content
                if (selectedTabIndex == 0) ...[
                  // Overview Tab (3-Column Layout: Left Analytics + Right Live Projection Summary)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Column (Net worth chart + Sankey + Holdings table)
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: const [
                            NetWorthAreaChart(),
                            SizedBox(height: 20),
                            SankeyCashFlowWidget(),
                            SizedBox(height: 20),
                            AssetListTable(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right Column (Donut allocation + Live Projection Simulator)
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: const [
                            DonutAllocationChart(),
                            SizedBox(height: 20),
                            ProjectionSimulatorCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (selectedTabIndex == 1) ...[
                  // Dedicated Wealth Simulator Tab
                  const ProjectionSimulatorCard(),
                  const SizedBox(height: 20),
                  const NetWorthAreaChart(),
                  const SizedBox(height: 20),
                  const SwpSimulatorCard(),
                ] else if (selectedTabIndex == 2) ...[
                  // Dedicated FIRE Calculator Tab
                  const FireCalculatorCard(),
                ] else if (selectedTabIndex == 3) ...[
                  // Holdings Tab (75% Holdings Table, 25% Asset Allocation)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(flex: 3, child: AssetListTable()),
                      SizedBox(width: 20),
                      Expanded(flex: 1, child: DonutAllocationChart()),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
