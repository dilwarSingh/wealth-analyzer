import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/currency_formatter.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/currency_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/app_header.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('AppHeader Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget({int selectedIndex = 0, ValueChanged<int>? onTabSelected}) {
      final mockDs = MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppHeader(
              selectedTabIndex: selectedIndex,
              onTabSelected: onTabSelected ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('Given AppHeader on desktop, When rendered, Then displays brand title, navigation tabs, currency toggle, and action buttons', (tester) async {
      tester.view.physicalSize = const Size(1600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given & When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('PORTFOLIO MODELING'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Simulator'), findsOneWidget);
      expect(find.text('FIRE Calculator'), findsOneWidget);
      expect(find.text('Holdings (0)'), findsOneWidget);
      expect(find.text('Sankey Flow'), findsNothing);
      expect(find.text('₹ INR'), findsOneWidget);
      expect(find.text('\$ USD'), findsOneWidget);
      expect(find.text('+ Add Investment'), findsOneWidget);
    });

    testWidgets('Given AppHeader, When a navigation tab is tapped, Then triggers onTabSelected callback with correct index', (tester) async {
      tester.view.physicalSize = const Size(1600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? tappedIndex;

      // Given
      await tester.pumpWidget(buildTestWidget(
        selectedIndex: 0,
        onTabSelected: (idx) => tappedIndex = idx,
      ));
      await tester.pumpAndSettle();

      // When: Tap Simulator tab (index 1)
      await tester.tap(find.text('Simulator'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(1));

      // When: Tap FIRE Calculator tab (index 2)
      await tester.tap(find.text('FIRE Calculator'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(2));

      // When: Tap Holdings tab (index 3)
      await tester.tap(find.text('Holdings (0)'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(3));
    });

    testWidgets('Given AppHeader, When USD currency segment is tapped, Then toggles currency provider state', (tester) async {
      tester.view.physicalSize = const Size(1600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // When: Tap USD button
      await tester.tap(find.text('\$ USD'));
      await tester.pumpAndSettle();

      // Then & Verify
      final element = tester.element(find.byType(AppHeader));
      final container = ProviderScope.containerOf(element);
      expect(container.read(currencyProvider), equals(CurrencyType.usd));
    });
  });
}
