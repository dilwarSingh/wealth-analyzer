import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/currency_formatter.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/compact_amount_suffix_badge.dart';

void main() {
  group('CompactAmountLabel Widget Tests (Given - When - Then - Verify)', () {
    testWidgets('Given empty controller, When rendered, Then displays nothing', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    const Text('Label'),
                    CompactAmountLabel(
                      controller: controller,
                      currency: CurrencyType.inr,
                    ),
                  ],
                ),
                TextField(controller: controller),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompactAmountLabel), findsOneWidget);
      expect(find.textContaining('≈'), findsNothing);
      expect(find.textContaining('Cr'), findsNothing);
    });

    testWidgets('Given user typing ₹1.5 Cr (15000000), When entered, Then dynamically renders "≈ 1.5 Cr" label on the right side', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Custom Starting Corpus'),
                    CompactAmountLabel(
                      controller: controller,
                      currency: CurrencyType.inr,
                    ),
                  ],
                ),
                TextField(controller: controller),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 1.5 Crores
      await tester.enterText(find.byType(TextField), '15000000');
      await tester.pumpAndSettle();

      expect(find.text('≈ 1.5 Cr'), findsOneWidget);

      // Change to 45 Lakhs
      await tester.enterText(find.byType(TextField), '4500000');
      await tester.pumpAndSettle();

      expect(find.text('≈ 45 L'), findsOneWidget);

      // Change to 50 Thousand
      await tester.enterText(find.byType(TextField), '50000');
      await tester.pumpAndSettle();

      expect(find.text('≈ 50 K'), findsOneWidget);
    });

    testWidgets('Given USD currency and custom prefix, When user types 1500000, Then renders "Corpus: 1.5 M"', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    const Text('Custom Corpus'),
                    CompactAmountLabel(
                      controller: controller,
                      currency: CurrencyType.usd,
                      prefix: 'Corpus: ',
                    ),
                  ],
                ),
                TextField(controller: controller),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1500000');
      await tester.pumpAndSettle();

      expect(find.text('Corpus: 1.5 M'), findsOneWidget);
    });
  });
}
