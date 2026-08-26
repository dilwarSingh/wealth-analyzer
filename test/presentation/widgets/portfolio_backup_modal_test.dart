import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/portfolio_backup_modal.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('PortfolioBackupModal Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestWidget() {
      final mockDs = MockLocalDataSource();
      return ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
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

    testWidgets('Given PortfolioBackupModal, When opened, Then displays preset buttons, JSON export/import and clear all actions', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given & When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Backup Modal'));
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('Presets & Backup Management'), findsOneWidget);
      expect(find.text('Balanced Starter'), findsOneWidget);
      expect(find.text('Aggressive Tech'), findsOneWidget);
      expect(find.text('Copy Portfolio JSON to Clipboard'), findsOneWidget);
      expect(find.text('Restore Portfolio from JSON'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('Given PortfolioBackupModal, When invalid JSON is pasted and restored, Then displays error status message', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Backup Modal'));
      await tester.pumpAndSettle();

      // When: Enter invalid JSON
      await tester.enterText(find.byType(TextField), 'invalid json string');
      await tester.tap(find.text('Restore Portfolio from JSON'));
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('Invalid JSON structure.'), findsOneWidget);
    });
  });
}
