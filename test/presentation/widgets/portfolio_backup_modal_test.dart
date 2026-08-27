import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/portfolio_backup_modal.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('PortfolioBackupModal Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget({MockLocalDataSource? mockDs}) {
      final ds = mockDs ?? MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(ds),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PortfolioBackupModal(),
                  );
                },
                child: const Text('Open Backup Modal'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Given PortfolioBackupModal, When loading Balanced and Aggressive presets, Then loads assets into portfolio', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Backup Modal'));
      await tester.pumpAndSettle();

      // Tap Balanced Starter
      await tester.tap(find.text('Balanced Starter'));
      await tester.pumpAndSettle();
      expect(find.text('Loaded Balanced Starter Portfolio!'), findsOneWidget);

      // Tap Aggressive Tech
      await tester.tap(find.text('Aggressive Tech'));
      await tester.pumpAndSettle();
      expect(find.text('Loaded Aggressive Growth Portfolio!'), findsOneWidget);

      // Copy JSON to clipboard
      await tester.tap(find.text('Copy Portfolio JSON to Clipboard'));
      await tester.pumpAndSettle();
      expect(find.text('Portfolio JSON copied to clipboard!'), findsOneWidget);

      // Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();
      expect(find.byType(PortfolioBackupModal), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Given PortfolioBackupModal, When valid and invalid JSON is restored, Then updates state appropriately', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Backup Modal'));
      await tester.pumpAndSettle();

      // Invalid JSON
      await tester.enterText(find.byType(TextField), 'invalid json string');
      await tester.tap(find.text('Restore Portfolio from JSON'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid JSON structure.'), findsOneWidget);

      // Valid JSON
      const validJson = '[{"id":"1","name":"Test Stock","category":"equities","type":"oneTime","investedAmount":1000.0,"currentValue":1200.0,"expectedCAGR":12.0,"stepUpRate":0.0,"startDate":"2025-01-01T00:00:00.000","isIncluded":true}]';
      await tester.enterText(find.byType(TextField), validJson);
      await tester.tap(find.text('Restore Portfolio from JSON'));
      await tester.pumpAndSettle();
      expect(find.text('Portfolio successfully imported!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
