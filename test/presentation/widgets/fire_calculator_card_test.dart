import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      tester.view.physicalSize = const Size(1400, 1000);
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

      // Chart & Table
      expect(find.text('NET WORTH VS FIRE TARGET CROSSOVER'), findsOneWidget);
      expect(find.text('YEAR-BY-YEAR FIRE TIMELINE SCHEDULE'), findsOneWidget);

      // Expand Guide
      expect(find.text('Understanding the FIRE Movement, 4% Rule & Flavors'), findsNothing);
      await tester.tap(find.text('📖 FIRE Guide & Rules'));
      await tester.pumpAndSettle();
      expect(find.text('Understanding the FIRE Movement, 4% Rule & Flavors'), findsOneWidget);
    });
  });
}
