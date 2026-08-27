import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/add_investment_dialog.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/empty_onboarding_card.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('EmptyOnboardingCard Widget Tests (Given - When - Then - Verify)', () {
    testWidgets('Given empty state, When EmptyOnboardingCard renders, Then displays buttons to add investment or load presets', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();

      // Given & When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataSourceProvider.overrideWithValue(mockDs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EmptyOnboardingCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('Welcome to Wealth Analyzer'), findsOneWidget);
      expect(find.text('+ Add Your First Investment'), findsOneWidget);
      expect(find.text('Load Balanced Starter Preset'), findsOneWidget);
      expect(find.text('Load Aggressive Growth Preset'), findsOneWidget);
    });

    testWidgets('Given EmptyOnboardingCard, When Load Balanced Starter Preset and Aggressive Preset are tapped, Then triggers portfolio viewmodel preset load', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
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
              body: EmptyOnboardingCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Balanced
      await tester.tap(find.text('Load Balanced Starter Preset'));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(EmptyOnboardingCard));
      final container = ProviderScope.containerOf(element);
      expect(container.read(portfolioProvider).assets.length, equals(5));

      // Tap Aggressive
      await tester.tap(find.text('Load Aggressive Growth Preset'));
      await tester.pumpAndSettle();
      expect(container.read(portfolioProvider).assets.length, equals(4));

      // Tap Add First Investment
      await tester.tap(find.text('+ Add Your First Investment'));
      await tester.pumpAndSettle();
      expect(find.byType(AddInvestmentDialog), findsOneWidget);
    });
  });
}
