import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/widgets/app_tooltip.dart';

void main() {
  group('AppTooltip Widget Tests', () {
    testWidgets('renders tooltip icon and child correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTooltip(
              message: 'Test Tooltip Description',
              child: Text('Hover Target'),
            ),
          ),
        ),
      );

      expect(find.text('Hover Target'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      final tooltipFinder = find.byType(Tooltip);
      final Tooltip tooltipWidget = tester.widget(tooltipFinder);
      expect(tooltipWidget.message, equals('Test Tooltip Description'));
    });

    testWidgets('renders icon-only when child is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTooltip(
              message: 'Icon Only Tooltip',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      final tooltipFinder = find.byType(Tooltip);
      final Tooltip tooltipWidget = tester.widget(tooltipFinder);
      expect(tooltipWidget.message, equals('Icon Only Tooltip'));
    });
  });
}
