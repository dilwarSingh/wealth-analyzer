import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/currency_formatter.dart';
import 'package:wealth_projector/core/widgets/crimson_button.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/currency_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/projection_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/views/wealth_dashboard_screen.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/add_investment_dialog.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/donut_allocation_chart.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/empty_onboarding_card.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/kpi_ribbon.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/net_worth_area_chart.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/portfolio_backup_modal.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/sankey_cash_flow_widget.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/swp_simulator_card.dart';

import '../data/portfolio_repository_impl_test.dart';

void main() {
  group('Inter-Component Portfolio Workflow Integration Tests (Given - When - Then - Verify)', () {
    testWidgets('Complete End-to-End User Journey: Onboarding -> Preset -> Reactive Components -> Add Asset -> Currency Switch -> Backup & Restore', (tester) async {
      // Set desktop HD resolution
      tester.view.physicalSize = const Size(1400, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();

      // =========================================================================
      // GIVEN: Fresh application launch
      // =========================================================================
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataSourceProvider.overrideWithValue(mockDs),
          ],
          child: const MaterialApp(
            home: WealthDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // THEN & VERIFY (Initial Empty State):
      expect(find.byType(EmptyOnboardingCard), findsOneWidget);
      expect(find.text('0 Assets'), findsOneWidget);
      expect(find.text('₹0'), findsWidgets);

      // =========================================================================
      // WHEN: User taps "Load Balanced Starter Preset"
      // =========================================================================
      await tester.tap(find.text('Load Balanced Starter Preset'));
      await tester.pumpAndSettle();

      // THEN & VERIFY (Reactive Cascade across all widgets):
      // 1. Empty card disappears
      expect(find.byType(EmptyOnboardingCard), findsNothing);
      // 2. KPI Ribbon updates
      expect(find.text('5 Assets'), findsOneWidget);
      expect(find.byType(KpiRibbon), findsOneWidget);
      // 3. Donut chart renders
      expect(find.byType(DonutAllocationChart), findsOneWidget);
      // 4. Net worth chart renders
      expect(find.byType(NetWorthAreaChart), findsOneWidget);
      // 5. Sankey cash flow widget renders
      expect(find.byType(SankeyCashFlowWidget), findsOneWidget);

      // =========================================================================
      // WHEN: User adds a new One-Time Stock Investment via dialog
      // =========================================================================
      await tester.tap(find.text('+ Add Investment').first);
      await tester.pumpAndSettle();

      expect(find.byType(AddInvestmentDialog), findsOneWidget);

      // Switch to One-Time
      await tester.tap(find.text('One-Time Lump Sum'));
      await tester.pumpAndSettle();

      // Enter details
      await tester.enterText(find.byType(TextFormField).at(0), 'Reliance Industries');
      await tester.enterText(find.byType(TextFormField).at(1), '100000');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.widgetWithText(CrimsonButton, 'Add Investment'));
      await tester.pumpAndSettle();

      // THEN & VERIFY: Asset count increases to 6
      expect(find.text('6 Assets'), findsOneWidget);
      expect(find.text('Reliance Industries'), findsOneWidget);

      // =========================================================================
      // WHEN: User toggles currency from INR to USD in header
      // =========================================================================
      await tester.tap(find.text('\$ USD'));
      await tester.pumpAndSettle();

      // THEN & VERIFY: Currency symbol across dashboard switches to '$'
      expect(find.textContaining('\$'), findsWidgets);

      // Switch back to INR for backup test
      await tester.tap(find.text('₹ INR'));
      await tester.pumpAndSettle();

      // =========================================================================
      // WHEN: User switches to Simulator Tab
      // =========================================================================
      await tester.tap(find.text('Simulator'));
      await tester.pumpAndSettle();

      // THEN & VERIFY: Simulator tab displays SWP decumulation simulator card
      expect(find.byType(SwpSimulatorCard), findsOneWidget);
      expect(find.text('SWP DECUMULATION SIMULATOR'), findsOneWidget);
      expect(find.text('RETIREMENT CORPUS TRAJECTORY'), findsOneWidget);

      // =========================================================================
      // WHEN: User switches to FIRE Calculator Tab
      // =========================================================================
      await tester.tap(find.text('FIRE Calculator'));
      await tester.pumpAndSettle();

      // THEN & VERIFY: FIRE tab displays FIRE Calculator card & multi-FIRE milestones
      expect(find.text('FIRE & FREEDOM CALCULATOR'), findsOneWidget);
      expect(find.text('STANDARD FIRE NUMBER'), findsOneWidget);
      expect(find.text('Standard FIRE'), findsOneWidget);
      expect(find.text('Coast FIRE'), findsOneWidget);

      // Switch back to Overview tab
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      // =========================================================================
      // WHEN: User opens Backup modal, clears data, and restores
      // =========================================================================
      final backupButtonFinder = find.byTooltip('Presets & Backup');
      if (backupButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(backupButtonFinder);
      } else {
        await tester.tap(find.byIcon(Icons.backup_rounded));
      }
      await tester.pumpAndSettle();

      expect(find.byType(PortfolioBackupModal), findsOneWidget);

      // Read current JSON export
      final element = tester.element(find.byType(PortfolioBackupModal));
      final container = ProviderScope.containerOf(element);
      final exportedJson = container.read(portfolioProvider.notifier).exportPortfolioAsJson();
      expect(exportedJson, isNotEmpty);

      // Tap Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Verify returned to empty onboarding card
      expect(find.byType(EmptyOnboardingCard), findsOneWidget);
      expect(find.text('0 Assets'), findsOneWidget);

      // Open Backup modal again to restore
      await tester.tap(find.byTooltip('Presets & Backup'));
      await tester.pumpAndSettle();

      // Paste exported JSON and restore
      await tester.enterText(find.byType(TextField), exportedJson);
      await tester.tap(find.text('Restore Portfolio from JSON'));
      await tester.pumpAndSettle();

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // THEN & VERIFY: Full 6 assets restored seamlessly
      expect(find.byType(EmptyOnboardingCard), findsNothing);
      expect(find.text('6 Assets'), findsOneWidget);
      expect(find.text('Reliance Industries'), findsOneWidget);
    });

    testWidgets('Given modified simulator parameters and USD currency, When app restarts (fresh ProviderScope), Then restores all simulator settings and currency preference', (tester) async {
      tester.view.physicalSize = const Size(1400, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final persistentDs = MockLocalDataSource();

      // Launch session 1
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataSourceProvider.overrideWithValue(persistentDs),
          ],
          child: const MaterialApp(
            home: WealthDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Modify currency to USD
      await tester.tap(find.text('\$ USD'));
      await tester.pumpAndSettle();

      // Modify simulator sliders via provider notifier
      final element = tester.element(find.byType(WealthDashboardScreen));
      final container = ProviderScope.containerOf(element);
      container.read(projectionProvider.notifier).setCurrentAge(33);
      container.read(projectionProvider.notifier).setTargetRetirementAge(63);
      container.read(projectionProvider.notifier).setAnnualInflation(7.5);
      container.read(projectionProvider.notifier).setGlobalStepUp(12.0);
      await Future.delayed(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();

      // SIMULATE APP RESTART: Launch session 2 with fresh ProviderScope and widgets
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataSourceProvider.overrideWithValue(persistentDs),
          ],
          child: const MaterialApp(
            home: WealthDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();

      // Verify Session 2 restored USD currency
      final element2 = tester.element(find.byType(WealthDashboardScreen));
      final container2 = ProviderScope.containerOf(element2);
      expect(container2.read(currencyProvider), equals(CurrencyType.usd));

      // Verify Session 2 restored simulator settings
      final projState2 = container2.read(projectionProvider);
      expect(projState2.currentAge, equals(33));
      expect(projState2.targetRetirementAge, equals(63));
      expect(projState2.annualInflationPercent, equals(7.5));
      expect(projState2.globalStepUpPercent, equals(12.0));
    });
  });
}
