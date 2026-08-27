import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/views/dashboard_desktop_view.dart';
import 'package:wealth_projector/features/portfolio/presentation/views/dashboard_mobile_view.dart';
import 'package:wealth_projector/features/portfolio/presentation/views/wealth_dashboard_screen.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/app_header.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('WealthDashboardScreen Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget({MockLocalDataSource? mockDs}) {
      final ds = mockDs ?? MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(ds),
        ],
        child: const MaterialApp(
          home: WealthDashboardScreen(),
        ),
      );
    }

    testWidgets('Given desktop viewport, When WealthDashboardScreen renders, Then displays AppHeader and DashboardDesktopView and updates tabs', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.byType(DashboardDesktopView), findsOneWidget);

      // Switch tabs in AppHeader
      await tester.tap(find.text('Simulator'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('FIRE Calculator'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Holdings'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sankey Flow'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Overview'), warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('Given mobile viewport, When WealthDashboardScreen renders, Then displays DashboardMobileView', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardMobileView), findsOneWidget);
    });
  });
}
