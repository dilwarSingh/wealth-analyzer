import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wealth_projector/features/portfolio/data/datasources/local_portfolio_datasource.dart';
import 'package:wealth_projector/features/portfolio/data/models/investment_asset_model.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';

void main() {
  group('HiveLocalPortfolioDataSource Tests (Given - When - Then - Verify)', () {
    late Directory tempDir;
    late HiveLocalPortfolioDataSource dataSource;

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('hive_test_ds_');
      Hive.init(tempDir.path);
    });

    tearDownAll(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    setUp(() {
      dataSource = HiveLocalPortfolioDataSource();
    });

    test('Given fresh datasource, When operations are executed in-memory fallback, Then save, get, delete, clearAll work reliably', () async {
      // Given: Asset model
      const model1 = InvestmentAssetModel(
        id: 'ds-1',
        name: 'Index Fund',
        category: 'mutualFunds',
        type: 'MONTHLY_SIP',
        investedAmount: 10000.0,
        currentValue: 20000.0,
        startDate: '2025-01-01',
        expectedCAGR: 12.0,
        stepUpRate: 10.0,
      );

      // When: Save asset
      await dataSource.saveAsset(model1);
      var assets = await dataSource.getStoredAssets();

      // Then & Verify
      expect(assets.length, equals(1));
      expect(assets.first.name, equals('Index Fund'));

      // When: Delete asset
      await dataSource.deleteAsset('ds-1');
      assets = await dataSource.getStoredAssets();

      // Then & Verify
      expect(assets, isEmpty);

      // When: Save all
      await dataSource.saveAllAssets([model1]);
      assets = await dataSource.getStoredAssets();
      expect(assets.length, equals(1));

      // When: Clear all
      await dataSource.clearAll();
      assets = await dataSource.getStoredAssets();
      expect(assets, isEmpty);
    });

    test('Given UserSettingsModel, When saved and retrieved from datasource, Then persists settings', () async {
      // Given
      const customSettings = UserSettingsModel(
        currentAge: 35,
        targetRetirementAge: 60,
        currencyCode: 'USD',
      );

      // When
      await dataSource.saveUserSettings(customSettings);
      final retrieved = await dataSource.getUserSettings();

      // Then & Verify
      expect(retrieved.currentAge, equals(35));
      expect(retrieved.targetRetirementAge, equals(60));
      expect(retrieved.currencyCode, equals('USD'));
    });
  });
}
