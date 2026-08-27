import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import '../widgets/add_investment_dialog.dart';
import '../widgets/asset_list_table.dart';
import '../widgets/donut_allocation_chart.dart';
import '../widgets/empty_onboarding_card.dart';
import '../widgets/fire_calculator_card.dart';
import '../widgets/kpi_ribbon.dart';
import '../widgets/net_worth_area_chart.dart';
import '../widgets/projection_simulator_card.dart';
import '../widgets/sankey_cash_flow_widget.dart';
import '../widgets/swp_simulator_card.dart';

class DashboardMobileView extends ConsumerWidget {
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  const DashboardMobileView({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioState = ref.watch(portfolioProvider);
    final hasAssets = portfolioState.assets.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            const KpiRibbon(),
            const SizedBox(height: 16),
            if (!hasAssets)
              const EmptyOnboardingCard()
            else ...[
              if (selectedTabIndex == 0) ...[
                const DonutAllocationChart(),
                const SizedBox(height: 16),
                const NetWorthAreaChart(),
                const SizedBox(height: 16),
                const SankeyCashFlowWidget(),
                const SizedBox(height: 16),
                const AssetListTable(),
              ] else if (selectedTabIndex == 1) ...[
                const ProjectionSimulatorCard(),
                const SizedBox(height: 16),
                const NetWorthAreaChart(),
                const SizedBox(height: 16),
                const SwpSimulatorCard(),
              ] else if (selectedTabIndex == 2) ...[
                const FireCalculatorCard(),
              ] else if (selectedTabIndex == 3) ...[
                const AssetListTable(),
                const SizedBox(height: 16),
                const DonutAllocationChart(),
              ],
            ],
            const SizedBox(height: 80), // Padding for bottom bar & FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.crimson,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Asset',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const AddInvestmentDialog(),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedTabIndex,
          onTap: onTabSelected,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded),
              label: 'Simulator',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department_rounded),
              label: 'FIRE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Holdings',
            ),
          ],
        ),
      ),
    );
  }
}
