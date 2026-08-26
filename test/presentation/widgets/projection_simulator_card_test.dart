import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/projection_simulator_card.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('ProjectionSimulatorCard Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget() {
      final mockDs = MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectionSimulatorCard(),
            ),
          ),
        ),
      );
    }

    testWidgets('Given ProjectionSimulatorCard, When rendered, Then displays simulator sliders and simulation comparison legends', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given & When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('WEALTH SIMULATOR'), findsOneWidget);
      expect(find.text('Current Age'), findsOneWidget);
      expect(find.text('Target Retirement Age'), findsOneWidget);
      expect(find.text('Annual Inflation Rate'), findsOneWidget);
      expect(find.text('Annual SIP Step-up'), findsOneWidget);
      expect(find.text('Add investments to simulate multi-scenario projections.'), findsOneWidget);
    });
  });
}
