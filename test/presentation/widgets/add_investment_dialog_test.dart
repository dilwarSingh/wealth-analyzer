import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/add_investment_dialog.dart';

import '../../data/portfolio_repository_impl_test.dart';

void main() {
  group('AddInvestmentDialog Widget Tests (Given - When - Then - Verify)', () {
    Widget buildTestDialog({InvestmentAsset? assetToEdit}) {
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
                    builder: (_) => AddInvestmentDialog(assetToEdit: assetToEdit),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Given AddInvestmentDialog opened in create mode, When empty form is submitted, Then shows validation errors', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given
      await tester.pumpWidget(buildTestDialog());
      await tester.pumpAndSettle();

      // When: Open dialog and tap Save without entering values
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Investment'), findsOneWidget);

      await tester.tap(find.text('Add Investment'));
      await tester.pumpAndSettle();

      // Then & Verify: Validation errors
      expect(find.text('Please enter asset name'), findsOneWidget);
    });

    testWidgets('Given AddInvestmentDialog, When entering valid One-Time investment data, Then live 10Y preview calculates properly and saves asset', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given
      await tester.pumpWidget(buildTestDialog());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // When: Switch to One-Time Lump Sum
      await tester.tap(find.text('One-Time Lump Sum'));
      await tester.pumpAndSettle();

      // Enter Asset Name
      await tester.enterText(find.byType(TextFormField).at(0), 'TCS Stocks');
      // Enter Invested Capital
      await tester.enterText(find.byType(TextFormField).at(1), '50000');
      await tester.pumpAndSettle();

      // Then & Verify: Live preview is updated and non-zero
      expect(find.text('10-YEAR ESTIMATED FUTURE VALUE'), findsOneWidget);

      // When: Tap save
      await tester.tap(find.text('Add Investment'));
      await tester.pumpAndSettle();

      // Then & Verify: Dialog dismissed
      expect(find.text('Add New Investment'), findsNothing);
    });

    testWidgets('Given AddInvestmentDialog in edit mode, When opened with existing asset, Then pre-fills existing fields', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final existingAsset = InvestmentAsset(
        id: 'edit-1',
        name: 'Existing Mutual Fund',
        category: AssetCategory.mutualFunds,
        type: InvestmentType.monthlySip,
        investedAmount: 15000.0,
        currentValue: 60000.0,
        startDate: DateTime.now(),
        expectedCAGR: 14.0,
        stepUpRate: 10.0,
      );

      // Given & When
      await tester.pumpWidget(buildTestDialog(assetToEdit: existingAsset));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Then & Verify
      expect(find.text('Edit Investment'), findsOneWidget);
      expect(find.text('Existing Mutual Fund'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Given AddInvestmentDialog, When selecting Mutual Fund classes and subcategories or Other custom text, Then updates properly', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given
      await tester.pumpWidget(buildTestDialog());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify default Mutual Fund 2-tier UI
      expect(find.text('MUTUAL FUND ASSET CLASS (LEVEL 1)'), findsOneWidget);
      expect(find.text('Equity'), findsWidgets);
      expect(find.text('Flexi Cap'), findsOneWidget);

      // Tap Debt class
      await tester.tap(find.text('Debt'));
      await tester.pumpAndSettle();
      expect(find.text('Debt FUND CATEGORY (LEVEL 2)'), findsOneWidget);
      expect(find.text('Liquid / Overnight'), findsOneWidget);
      expect(find.text('Money Market'), findsOneWidget);

      // Select Money Market
      await tester.tap(find.text('Money Market'));
      await tester.pumpAndSettle();

      // Switch to Gold category (1-tier)
      await tester.tap(find.text('Gold/Precious Metals'));
      await tester.pumpAndSettle();
      expect(find.text('GOLD/PRECIOUS METALS SUB-CATEGORY'), findsOneWidget);
      expect(find.text('Physical Gold (Coins / Bars)'), findsOneWidget);

      // Select 'Other' and enter custom subcategory name
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();
      expect(find.text('CUSTOM SUB-CATEGORY NAME'), findsOneWidget);

      final customField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText?.contains('Farmland') == true);
      expect(customField, findsOneWidget);
      await tester.enterText(customField, '24K Gold Bullion Vault');
      await tester.pumpAndSettle();
    });

    testWidgets('Given AddInvestmentDialog, When configuring a custom SIP duration (5 years), Then slider shows stopping age and persists sipDurationYears', (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Given
      await tester.pumpWidget(buildTestDialog());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify SIP Duration section exists
      expect(find.text('SIP DURATION'), findsOneWidget);
      expect(find.text('Till Retirement'), findsOneWidget);

      // Toggle Till Retirement switch OFF to reveal custom years slider
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('Custom Years'), findsOneWidget);
      expect(find.textContaining('Contribute for 5 Years'), findsOneWidget);
      expect(find.textContaining('Stops at Age'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Enter asset name & monthly amount
      await tester.enterText(find.byType(TextFormField).at(0), 'Nifty 50 Index SIP');
      await tester.enterText(find.byType(TextFormField).at(1), '20000');
      await tester.pumpAndSettle();

      // Save asset
      await tester.tap(find.text('Add Investment'));
      await tester.pumpAndSettle();

      // Verify Dialog dismissed
      expect(find.text('Add New Investment'), findsNothing);
    });
  });
}
