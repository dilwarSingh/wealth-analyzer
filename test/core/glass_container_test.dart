import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/widgets/glass_container.dart';

void main() {
  group('GlassContainer Widget Tests (Given - When - Then - Verify)', () {
    testWidgets('Given default GlassContainer, When rendered, Then displays child with blur decoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassContainer(
              child: Text('GLASS_CONTENT'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GLASS_CONTENT'), findsOneWidget);
    });

    testWidgets('Given GlassContainer with onTap, margin, and custom gradient, When tapped, Then triggers callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassContainer(
              margin: const EdgeInsets.all(12),
              borderRadius: 20,
              blur: 16,
              backgroundGradient: const LinearGradient(
                colors: [Colors.red, Colors.blue],
              ),
              glowShadow: const BoxShadow(
                color: Colors.amber,
                blurRadius: 10,
              ),
              onTap: () => tapped = true,
              child: const Text('CLICKABLE_GLASS'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CLICKABLE_GLASS'), findsOneWidget);
      await tester.tap(find.text('CLICKABLE_GLASS'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
