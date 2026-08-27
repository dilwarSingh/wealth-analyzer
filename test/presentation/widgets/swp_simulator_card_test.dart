import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/swp_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/swp_simulator_card.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('SwpSimulatorCard Widget Tests (Given - When - Then - Verify)', () {
    testWidgets('Given empty initial corpus, When rendered, Then displays header, today terms chip, and empty prompt', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataSourceProvider.overrideWithValue(mockDs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SwpSimulatorCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('SWP DECUMULATION SIMULATOR'), findsOneWidget);
      expect(find.text('In Today\'s Terms'), findsOneWidget);
      expect(find.text('Post-Retirement Return'), findsOneWidget);
      expect(find.text('RETIREMENT MILESTONES & LUMPSUM OUTFLOWS'), findsOneWidget);
      expect(find.text('Add investments or set a custom starting corpus to simulate your SWP plan.'), findsOneWidget);
    });

    testWidgets('Given active assets, When SwpSimulatorCard renders, Then displays sustainability banner, LineChart, and Schedule DataTable', (tester) async {
      tester.view.physicalSize = const Size(1400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataSourceProvider.overrideWithValue(mockDs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SwpSimulatorCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add asset to generate accumulation corpus
      final element = tester.element(find.byType(SwpSimulatorCard));
      final container = ProviderScope.containerOf(element);
      final asset = InvestmentAsset(
        id: 'widget-asset-swp',
        name: 'Equity SIP',
        category: AssetCategory.equities,
        type: InvestmentType.monthlySip,
        investedAmount: 20000.0,
        currentValue: 0.0,
        startDate: DateTime.now(),
        expectedCAGR: 14.0,
      );
      await container.read(portfolioProvider.notifier).saveAsset(asset);
      await tester.pumpAndSettle();

      // Verify Sustainability Banner Metrics
      expect(find.text('TOTAL WITHDRAWN'), findsOneWidget);
      expect(find.text('RETURNS GENERATED'), findsOneWidget);

      // Verify Trajectory LineChart
      expect(find.text('RETIREMENT CORPUS TRAJECTORY'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      // Verify Schedule Table
      expect(find.text('YEAR-BY-YEAR SWP SCHEDULE'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('YEAR / AGE'), findsOneWidget);
      expect(find.text('OPENING CORPUS'), findsOneWidget);
      expect(find.text('CLOSING CORPUS'), findsOneWidget);

      // Test Table Collapse Toggle
      await tester.tap(find.text('Hide Table'));
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsNothing);

      await tester.tap(find.text('Show Table'));
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('Given SwpSimulatorCard, When custom corpus is entered, milestones expanded, and rules selected, Then updates simulation', (tester) async {
      tester.view.physicalSize = const Size(1400, 3500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataSourceProvider.overrideWithValue(mockDs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SwpSimulatorCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Custom Starting Corpus
      await tester.tap(find.text('Custom Starting Corpus'));
      await tester.pumpAndSettle();

      // Enter Custom Corpus Value
      final corpusField = find.byType(TextField).first;
      await tester.enterText(corpusField, '50000000');
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(SwpSimulatorCard));
      final container = ProviderScope.containerOf(element);
      expect(container.read(swpProvider).useCustomCorpus, isTrue);
      expect(container.read(swpProvider).customCorpusAmount, equals(50000000.0));

      // Expand Milestones Section
      await tester.tap(find.text('RETIREMENT MILESTONES & LUMPSUM OUTFLOWS'));
      await tester.pumpAndSettle();

      // Add a New Milestone
      await tester.tap(find.text('Add Outflow'));
      await tester.pumpAndSettle();

      expect(find.text('Add Retirement Outflow'), findsOneWidget);
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      await tester.enterText(textFields.at(1), 'World Cruise Travel');
      await tester.enterText(textFields.at(2), '1500000');
      await tester.tap(find.text('Add Outflow').last);
      await tester.pumpAndSettle();

      expect(find.text('World Cruise Travel'), findsOneWidget);
      expect(container.read(swpProvider).milestoneExpenses.length, equals(1));

      // Edit Milestone
      await tester.tap(find.byTooltip('Edit Outflow'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Retirement Outflow'), findsOneWidget);
      final editFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      expect(editFields, findsNWidgets(2));
      await tester.enterText(editFields.first, 'Special Health Fund');
      await tester.enterText(editFields.last, '2000000');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Special Health Fund'), findsOneWidget);
      expect(container.read(swpProvider).milestoneExpenses.first.name, equals('Special Health Fund'));
      expect(container.read(swpProvider).milestoneExpenses.first.amount, equals(2000000.0));

      // =========================================================================
      // Test Sub-Tab 1: Monte Carlo (1,000 Runs)
      // =========================================================================
      await tester.tap(find.text('Monte Carlo (1,000 Runs)'));
      await tester.pumpAndSettle();

      expect(find.text('1,000-TRIAL PERCENTILE FAN CONE'), findsOneWidget);
      expect(find.text('P50 MEDIAN BALANCE'), findsOneWidget);
      expect(find.text('P90 OPTIMISTIC BALANCE'), findsOneWidget);
      expect(find.text('P10 WORST-CASE (10% VaR)'), findsOneWidget);
      expect(find.text('Market Annual Volatility (Standard Deviation σ)'), findsOneWidget);
      expect(find.byType(Tooltip), findsWidgets);

      // Expand Monte Carlo Educational Guide
      expect(find.text('Understanding Monte Carlo Simulation & Percentiles'), findsNothing);
      await tester.tap(find.text('📖 Guide & Methodology'));
      await tester.pumpAndSettle();
      expect(find.text('Understanding Monte Carlo Simulation & Percentiles'), findsOneWidget);

      // =========================================================================
      // Test Sub-Tab 2: Crisis Stress-Test (SORR)
      // =========================================================================
      await tester.tap(find.text('Crisis Stress-Test (SORR)'));
      await tester.pumpAndSettle();

      expect(find.text('SELECT HISTORICAL CRISIS IN YEAR 1 OF RETIREMENT:'), findsOneWidget);
      expect(find.text('2008 Financial Crisis'), findsWidgets);
      expect(find.text('2020 Flash Crash'), findsWidgets);
      expect(find.text('BASELINE ENDING CORPUS'), findsOneWidget);
      expect(find.text('STRESSED ENDING CORPUS'), findsOneWidget);
      expect(find.text('EROSION IMPACT'), findsOneWidget);
      expect(find.text('BASELINE VS PARALLEL CRISIS TRAJECTORIES'), findsOneWidget);

      // Expand Crisis Stress-Test Educational Guide
      expect(find.text('Understanding Sequence-of-Returns Risk (SORR)'), findsNothing);
      await tester.tap(find.text('📖 Guide & Methodology'));
      await tester.pumpAndSettle();
      expect(find.text('Understanding Sequence-of-Returns Risk (SORR)'), findsOneWidget);

      // Switch to 2020 Flash Crash chip
      await tester.tap(find.descendant(of: find.byType(ChoiceChip), matching: find.text('2020 Flash Crash')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('COVID-19 shock'), findsOneWidget);
    });

    testWidgets('Given underfunded SWP corpus, When rendered, Then displays Solvency & Minimum Recommended Starting Corpus Card with benchmarks', (tester) async {
      tester.view.physicalSize = const Size(1400, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataSourceProvider.overrideWithValue(mockDs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SwpSimulatorCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter underfunded custom starting corpus (e.g. ₹5 Lakhs with ₹80k/mo withdrawal)
      await tester.tap(find.text('Custom Starting Corpus'));
      await tester.pumpAndSettle();

      final customField = find.descendant(of: find.byType(SwpSimulatorCard), matching: find.byType(TextField)).first;
      await tester.enterText(customField, '500000');
      await tester.pumpAndSettle();

      // Verify Tab 0 (Standard Schedule): ONLY Standard SWP Solvency card is visible
      expect(find.text('RECOMMENDED MINIMUM STARTING CORPUS FOR SOLVENCY'), findsOneWidget);
      expect(find.text('Standard SWP (100% Horizon)'), findsOneWidget);
      expect(find.text('MONTE CARLO PROBABILISTIC SOLVENCY RECOMMENDATION'), findsNothing);
      expect(find.text('CRISIS STRESS-TEST (SORR) SOLVENCY BENCHMARKS'), findsNothing);
      expect(find.textContaining('-₹'), findsWidgets);

      // Verify Tab 1 (Monte Carlo): ONLY Monte Carlo 80% & 95% Solvency card is visible
      await tester.tap(find.text('Monte Carlo (1,000 Runs)'));
      await tester.pumpAndSettle();

      expect(find.text('MONTE CARLO PROBABILISTIC SOLVENCY RECOMMENDATION'), findsOneWidget);
      expect(find.text('80% Moderate Confidence'), findsOneWidget);
      expect(find.text('95% Bulletproof Confidence'), findsOneWidget);
      expect(find.text('Standard SWP (100% Horizon)'), findsNothing);
      expect(find.text('CRISIS STRESS-TEST (SORR) SOLVENCY BENCHMARKS'), findsNothing);

      // Verify Tab 2 (Crisis Stress-Test SORR): Displays all 4 historical crises simultaneously with active selection
      await tester.tap(find.text('Crisis Stress-Test (SORR)'));
      await tester.pumpAndSettle();

      expect(find.text('CRISIS STRESS-TEST (SORR) SOLVENCY BENCHMARKS'), findsOneWidget);
      expect(find.text('2008 Financial Crisis'), findsWidgets);
      expect(find.text('2000 Dot-Com Bubble'), findsOneWidget);
      expect(find.text('2020 Flash Crash'), findsWidgets);
      expect(find.text('1970s Stagflation'), findsWidgets);
      expect(find.text('ACTIVE SELECTION'), findsOneWidget);
      expect(find.textContaining('Depletes at Age'), findsWidgets);
      expect(find.text('Standard SWP (100% Horizon)'), findsNothing);
    });
  });
}

