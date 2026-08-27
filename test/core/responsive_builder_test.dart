import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/widgets/responsive_builder.dart';

void main() {
  group('ResponsiveBuilder Widget Tests (Given - When - Then - Verify)', () {
    testWidgets('Given desktop viewport (width >= 1024), When ResponsiveBuilder renders, Then uses desktop layout', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              desktop: const Text('DESKTOP_WIDGET'),
              tablet: const Text('TABLET_WIDGET'),
              mobile: const Text('MOBILE_WIDGET'),
              builder: (context, type) => Text('BUILDER_${type.name}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DESKTOP_WIDGET'), findsOneWidget);
      expect(find.text('TABLET_WIDGET'), findsNothing);
      expect(find.text('MOBILE_WIDGET'), findsNothing);
    });

    testWidgets('Given tablet viewport (640 <= width < 1024), When ResponsiveBuilder renders, Then uses tablet layout', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              desktop: const Text('DESKTOP_WIDGET'),
              tablet: const Text('TABLET_WIDGET'),
              mobile: const Text('MOBILE_WIDGET'),
              builder: (context, type) => Text('BUILDER_${type.name}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TABLET_WIDGET'), findsOneWidget);
    });

    testWidgets('Given mobile viewport (width < 640), When ResponsiveBuilder renders, Then uses mobile layout', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              desktop: const Text('DESKTOP_WIDGET'),
              tablet: const Text('TABLET_WIDGET'),
              mobile: const Text('MOBILE_WIDGET'),
              builder: (context, type) => Text('BUILDER_${type.name}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MOBILE_WIDGET'), findsOneWidget);
    });

    testWidgets('Given builder fallback when specific widgets are null, When ResponsiveBuilder renders, Then calls builder with appropriate ScreenType', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              builder: (context, type) => Text('DYNAMIC_${type.name.toUpperCase()}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DYNAMIC_DESKTOP'), findsOneWidget);

      // Verify static helper methods
      final element = tester.element(find.text('DYNAMIC_DESKTOP'));
      expect(ResponsiveBuilder.isDesktop(element), isTrue);
      expect(ResponsiveBuilder.isTablet(element), isFalse);
      expect(ResponsiveBuilder.isMobile(element), isFalse);
      expect(ResponsiveBuilder.getScreenType(element), equals(ScreenType.desktop));
    });
  });
}
