import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/data/datasources/local_portfolio_datasource.dart';
import 'package:wealth_projector/features/portfolio/data/models/investment_asset_model.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';
import 'package:wealth_projector/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';

class MockLocalDataSource implements LocalPortfolioDataSource {
  final List<InvestmentAssetModel> _storage = [];
  UserSettingsModel _settings = const UserSettingsModel();

  @override
  Future<List<InvestmentAssetModel>> getStoredAssets() async => List.unmodifiable(_storage);

  @override
  Future<void> saveAsset(InvestmentAssetModel asset) async {
    final idx = _storage.indexWhere((a) => a.id == asset.id);
    if (idx >= 0) {
      _storage[idx] = asset;
    } else {
      _storage.add(asset);
    }
  }

  @override
  Future<void> deleteAsset(String id) async {
    _storage.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> saveAllAssets(List<InvestmentAssetModel> assets) async {
    _storage.clear();
    _storage.addAll(assets);
  }

  @override
  Future<void> clearAll() async {
    _storage.clear();
  }

  @override
  Future<UserSettingsModel> getUserSettings() async => _settings;

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    _settings = settings;
  }
}

void main() {
  group('PortfolioRepositoryImpl Tests (Given - When - Then - Verify)', () {
    late MockLocalDataSource mockDataSource;
    late PortfolioRepositoryImpl repository;

    setUp(() {
      mockDataSource = MockLocalDataSource();
      repository = PortfolioRepositoryImpl(localDataSource: mockDataSource);
    });

    test('Given domain InvestmentAsset, When saveAsset and getAssets are called on repository, Then maps between entity and model seamlessly', () async {
      // Given
      final entity = InvestmentAsset(
        id: 'repo-1',
        name: 'Govt Bonds',
        category: AssetCategory.fixedDeposit,
        type: InvestmentType.oneTime,
        investedAmount: 50000.0,
        currentValue: 55000.0,
        startDate: DateTime.now(),
        expectedCAGR: 7.5,
      );

      // When
      await repository.saveAsset(entity);
      final retrievedEntities = await repository.getAssets();

      // Then & Verify
      expect(retrievedEntities.length, equals(1));
      expect(retrievedEntities.first.id, equals('repo-1'));
      expect(retrievedEntities.first.name, equals('Govt Bonds'));
      expect(retrievedEntities.first.category, equals(AssetCategory.fixedDeposit));

      // When: Delete asset
      await repository.deleteAsset('repo-1');
      final afterDelete = await repository.getAssets();

      // Then & Verify
      expect(afterDelete, isEmpty);
    });

    test('Given list of assets, When setAssets and clearAll are called, Then replaces and cleans all storage', () async {
      // Given
      final assets = [
        InvestmentAsset(
          id: '1',
          name: 'A1',
          category: AssetCategory.crypto,
          type: InvestmentType.oneTime,
          investedAmount: 1000,
          currentValue: 1200,
          startDate: DateTime.now(),
          expectedCAGR: 15,
        ),
      ];

      // When: Set assets
      await repository.setAssets(assets);
      var result = await repository.getAssets();

      // Then & Verify
      expect(result.length, equals(1));

      // When: Clear all
      await repository.clearAll();
      result = await repository.getAssets();

      // Then & Verify
      expect(result, isEmpty);
    });

    test('Given user settings, When saveUserSettings and getUserSettings are called, Then persists and retrieves settings correctly', () async {
      // Given
      final customSettings = const UserSettingsModel(
        currentAge: 35,
        targetRetirementAge: 60,
        inflationRate: 7.0,
        globalStepUpRate: 15.0,
        currencyCode: 'USD',
      );

      // When
      await repository.saveUserSettings(customSettings);
      final retrieved = await repository.getUserSettings();

      // Then & Verify
      expect(retrieved.currentAge, equals(35));
      expect(retrieved.targetRetirementAge, equals(60));
      expect(retrieved.inflationRate, equals(7.0));
      expect(retrieved.globalStepUpRate, equals(15.0));
      expect(retrieved.currencyCode, equals('USD'));
    });
  });
}
