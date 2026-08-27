import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/widgets/custom_slider.dart';
import 'package:wealth_projector/core/widgets/glass_container.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/fire_calculator_card.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('FireCalculatorCard Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget({MockLocalDataSource? mockDs}) {
      final ds = mockDs ?? MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(ds),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FireCalculatorCard(),
            ),
          ),
        ),
      );
    }

    testWidgets('Given FireCalculatorCard, When rendered on desktop, Then displays header, readiness banner, multi-FIRE cards, and crossover chart', (tester) async {
      tester.view.physicalSize = const Size(1400, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Header & Title
      expect(find.text('FIRE & FREEDOM CALCULATOR'), findsOneWidget);
      expect(find.text('STANDARD FIRE NUMBER'), findsOneWidget);
      expect(find.text('ANNUAL EXPENSES'), findsWidgets);

      // Multi-FIRE Cards
      expect(find.text('Standard FIRE'), findsOneWidget);
      expect(find.text('Lean FIRE'), findsOneWidget);
      expect(find.text('Fat FIRE'), findsOneWidget);
      expect(find.text('Coast FIRE'), findsOneWidget);
      expect(find.text('Barista FIRE'), findsOneWidget);

      // Sliders & Tooltip icons
      expect(find.text('Safe Withdrawal Rate (SWR)'), findsOneWidget);
      expect(find.byType(CustomFinancialSlider), findsNWidgets(4));

      // Smart SWR Recommendation Chip
      expect(find.textContaining('Rec:'), findsOneWidget);

      // Pre-Retirement Milestones Section
      expect(find.text('PRE-RETIREMENT GOALS'), findsOneWidget);
      expect(find.text('Sync from SWP'), findsOneWidget);
      expect(find.text('Add Goal'), findsOneWidget);

      // Chart & Table
      expect(find.text('NET WORTH VS FIRE TARGET CROSSOVER'), findsOneWidget);
      expect(find.text('YEAR-BY-YEAR FIRE TIMELINE SCHEDULE'), findsOneWidget);

      // Expand Guide
      expect(find.text('Understanding the FIRE Movement, 4% Rule & Flavors'), findsNothing);
      await tester.tap(find.text('📖 FIRE Guide & Rules'));
      await tester.pumpAndSettle();
      expect(find.text('Understanding the FIRE Movement, 4% Rule & Flavors'), findsOneWidget);

      // Click Rec chip
      await tester.tap(find.textContaining('Rec:'));
      await tester.pumpAndSettle();

      // Click Sync from SWP (empty)
      await tester.tap(find.text('Sync from SWP'));
      await tester.pumpAndSettle();

      // Toggle Schedule Table
      final tableToggle = find.text('Hide Table');
      if (tableToggle.evaluate().isNotEmpty) {
        await tester.tap(tableToggle);
        await tester.pumpAndSettle();
      }

      // Tap Flavor Cards
      await tester.tap(find.text('Lean FIRE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fat FIRE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coast FIRE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barista FIRE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Standard FIRE'));
      await tester.pumpAndSettle();
    });

    testWidgets('Given FireCalculatorCard, When toggling custom corpus and adding/editing/deleting milestones, Then operations succeed', (tester) async {
      tester.view.physicalSize = const Size(1400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Toggle Custom Corpus & SIP
      await tester.tap(find.text('Custom Corpus & SIP'));
      await tester.pumpAndSettle();

      // Enter custom corpus and savings in TextFields
      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(0), '10000000');
        await tester.enterText(textFields.at(1), '50000');
        await tester.pumpAndSettle();
      }

      // Toggle Auto-Sync Active Portfolio back
      await tester.tap(find.text('Auto-Sync Active Portfolio'));
      await tester.pumpAndSettle();

      // Expand Pre-Retirement Goals Section
      await tester.tap(find.text('PRE-RETIREMENT GOALS'));
      await tester.pumpAndSettle();

      // Tap Add Goal button
      await tester.tap(find.text('Add Goal'));
      await tester.pumpAndSettle();

      // Verify modal dialog opened
      expect(find.text('Add Pre-FIRE Goal'), findsOneWidget);

      // Click preset chip
      final presetChips = find.byType(ActionChip);
      if (presetChips.evaluate().isNotEmpty) {
        await tester.tap(presetChips.first);
        await tester.pumpAndSettle();
      }

      // Submit dialog
      await tester.tap(find.text('Add Goal').last);
      await tester.pumpAndSettle();

      expect(find.text('1 Active'), findsOneWidget);

      // Toggle milestone checkbox
      final checkbox = find.descendant(of: find.byType(GlassContainer), matching: find.byType(Checkbox));
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox.first);
        await tester.pumpAndSettle();
      }

      // Edit Milestone
      final editBtn = find.byTooltip('Edit Goal');
      if (editBtn.evaluate().isNotEmpty) {
        await tester.tap(editBtn.first);
        await tester.pumpAndSettle();

        expect(find.text('Edit Pre-FIRE Goal'), findsOneWidget);
        final dialogTextFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
        if (dialogTextFields.evaluate().length >= 2) {
          await tester.enterText(dialogTextFields.first, 'Updated Goal Name');
          await tester.enterText(dialogTextFields.last, '2500000');
        }
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
      }

      // Delete milestone
      final deleteBtn = find.byTooltip('Remove Goal');
      if (deleteBtn.evaluate().isNotEmpty) {
        await tester.tap(deleteBtn.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Given mobile viewport, When FireCalculatorCard renders, Then adapts to mobile layout', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('FIRE & FREEDOM CALCULATOR'), findsOneWidget);
    });
  });
}
