import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealth_projector/core/theme/glassmorphism_theme.dart';
import 'package:wealth_projector/features/portfolio/data/datasources/local_portfolio_datasource.dart';
import 'package:wealth_projector/features/portfolio/data/models/investment_asset_model.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/views/wealth_dashboard_screen.dart';
import 'package:wealth_projector/features/portfolio/presentation/widgets/add_investment_dialog.dart';
import 'package:flutter/material.dart';

class MockLocalPortfolioDataSource implements LocalPortfolioDataSource {
  final List<InvestmentAssetModel> _assets = [];
  UserSettingsModel _settings = const UserSettingsModel();

  @override
  Future<void> clearAll() async => _assets.clear();

  @override
  Future<void> deleteAsset(String id) async => _assets.removeWhere((a) => a.id == id);

  @override
  Future<List<InvestmentAssetModel>> getStoredAssets() async => List.from(_assets);

  @override
  Future<UserSettingsModel> getUserSettings() async => _settings;

  @override
  Future<void> saveAllAssets(List<InvestmentAssetModel> assets) async {
    _assets.clear();
    _assets.addAll(assets);
  }

  @override
  Future<void> saveAsset(InvestmentAssetModel asset) async {
    _assets.removeWhere((a) => a.id == asset.id);
    _assets.add(asset);
  }

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async => _settings = settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Wealth Analyzer App renders dashboard and branding', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockLocalPortfolioDataSource()),
        ],
        child: MaterialApp(
          theme: GlassmorphismTheme.darkTheme,
          home: const WealthDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TOTAL NET WORTH'), findsWidgets);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Simulator'), findsWidgets);
    expect(find.text('Welcome to Wealth Analyzer'), findsOneWidget);
  });

  testWidgets('Add Investment button opens dialog and successfully saves asset', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockLocalPortfolioDataSource()),
        ],
        child: MaterialApp(
          theme: GlassmorphismTheme.darkTheme,
          home: const WealthDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap + Add Investment in AppHeader
    final addHeaderBtn = find.text('+ Add Investment');
    expect(addHeaderBtn, findsOneWidget);
    await tester.tap(addHeaderBtn);
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.byType(AddInvestmentDialog), findsOneWidget);
    expect(find.text('Add New Investment'), findsOneWidget);

    // Enter Asset Name
    final nameField = find.widgetWithText(TextFormField, 'e.g. Nifty 50 Index Fund, Physical Gold, Tech ETF');
    await tester.enterText(nameField, 'Test Nifty Fund');

    // Enter Monthly SIP Amount
    final amountFields = find.byType(TextFormField);
    // Amount field is index 1
    await tester.enterText(amountFields.at(1), '25000');

    await tester.pumpAndSettle();

    // Tap 'Add Investment' submit button inside dialog
    final submitBtn = find.text('Add Investment');
    await tester.tap(submitBtn.last);
    await tester.pumpAndSettle();

    // Verify dialog closed and asset appears in table
    expect(find.byType(AddInvestmentDialog), findsNothing);
    expect(find.text('Test Nifty Fund'), findsOneWidget);
  });
}
