import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
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

    testWidgets('Given EmptyOnboardingCard, When Load Balanced Starter Preset is tapped, Then triggers portfolio viewmodel preset load', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockLocalDataSource();

      // Given
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

      // When: Tap Load Balanced Starter Preset
      await tester.tap(find.text('Load Balanced Starter Preset'));
      await tester.pumpAndSettle();

      // Then & Verify
      final element = tester.element(find.byType(EmptyOnboardingCard));
      final container = ProviderScope.containerOf(element);
      expect(container.read(portfolioProvider).assets.length, equals(5));
    });
  });
}
