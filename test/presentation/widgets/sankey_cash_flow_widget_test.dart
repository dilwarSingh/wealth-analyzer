import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/sankey_cash_flow_widget.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('SankeyCashFlowWidget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget() {
      final mockDs = MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SankeyCashFlowWidget(),
            ),
          ),
        ),
      );
    }

    testWidgets('Given SankeyCashFlowWidget, When rendered, Then displays heading and interactive cash flow layout', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given & When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('CASH-FLOW SANKEY'), findsOneWidget);
    });
  });
}
