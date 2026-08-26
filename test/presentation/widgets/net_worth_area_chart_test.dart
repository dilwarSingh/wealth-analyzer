import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/projection_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/net_worth_area_chart.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('NetWorthAreaChart Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget({MockLocalDataSource? mockDs}) {
      final ds = mockDs ?? MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(ds),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NetWorthAreaChart(),
            ),
          ),
        ),
      );
    }

    testWidgets('Given NetWorthAreaChart, When rendered, Then displays chart title and timeframe switch buttons', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given & When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('NET WORTH TRAJECTORY'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);
      expect(find.text('3Y'), findsOneWidget);
      expect(find.text('5Y'), findsOneWidget);
      expect(find.text('10Y'), findsOneWidget);
    });

    testWidgets('Given timeframe buttons, When a button is tapped (e.g. 5Y), Then updates selected timeframe in ProjectionViewModel', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // When: Tap 5Y button
      await tester.tap(find.text('5Y'));
      await tester.pumpAndSettle();

      // Then & Verify
      final element = tester.element(find.byType(NetWorthAreaChart));
      final container = ProviderScope.containerOf(element);
      expect(container.read(projectionProvider).selectedTimeframe, equals(ChartTimeframe.fiveYears));
    });
  });
}
