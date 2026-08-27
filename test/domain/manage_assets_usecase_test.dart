import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:wealth_projector/features/portfolio/domain/usecases/manage_assets_usecase.dart';

class MockPortfolioRepository implements PortfolioRepository {
  final List<InvestmentAsset> _assets = [];
  UserSettingsModel _settings = const UserSettingsModel();

  @override
  Future<List<InvestmentAsset>> getAssets() async => List.unmodifiable(_assets);

  @override
  Future<void> saveAsset(InvestmentAsset asset) async {
    final idx = _assets.indexWhere((a) => a.id == asset.id);
    if (idx >= 0) {
      _assets[idx] = asset;
    } else {
      _assets.add(asset);
    }
  }

  @override
  Future<void> setAssets(List<InvestmentAsset> assets) async {
    _assets.clear();
    _assets.addAll(assets);
  }

  @override
  Future<void> deleteAsset(String id) async {
    _assets.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> clearAll() async {
    _assets.clear();
  }

  @override
  Future<UserSettingsModel> getUserSettings() async => _settings;

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    _settings = settings;
  }
}

void main() {
  group('ManageAssetsUseCase Tests (Given - When - Then - Verify)', () {
    late MockPortfolioRepository mockRepo;
    late ManageAssetsUseCase useCase;

    setUp(() {
      mockRepo = MockPortfolioRepository();
      useCase = ManageAssetsUseCase(mockRepo);
    });

    // -------------------------------------------------------------
    // 1. Add Asset with Empty vs Existing ID
    // -------------------------------------------------------------
    test('Given asset without an ID, When addOrUpdateAsset is called, Then assigns unique UUID and saves', () async {
      // Given
      final newAsset = InvestmentAsset(
        id: '', // Empty ID
        name: 'Sovereign Gold Bond',
        category: AssetCategory.goldPrecious,
        type: InvestmentType.oneTime,
        investedAmount: 50000.0,
        currentValue: 55000.0,
        startDate: DateTime.now(),
        expectedCAGR: 11.0,
      );

      // When
      await useCase.addOrUpdateAsset(newAsset);
      final storedAssets = await useCase.getAssets();

      // Then & Verify
      expect(storedAssets.length, equals(1));
      expect(storedAssets.first.id, isNotEmpty);
      expect(storedAssets.first.name, equals('Sovereign Gold Bond'));
    });

    // -------------------------------------------------------------
    // 2. Update Existing Asset
    // -------------------------------------------------------------
    test('Given existing asset in repository, When addOrUpdateAsset is called with matching ID, Then updates the asset in place', () async {
      // Given
      final initialAsset = InvestmentAsset(
        id: 'asset-123',
        name: 'Old Name',
        category: AssetCategory.equities,
        type: InvestmentType.oneTime,
        investedAmount: 10000.0,
        currentValue: 10000.0,
        startDate: DateTime.now(),
        expectedCAGR: 10.0,
      );
      await useCase.addOrUpdateAsset(initialAsset);

      // When
      final updatedAsset = initialAsset.copyWith(
        name: 'Updated Name ETF',
        currentValue: 15000.0,
      );
      await useCase.addOrUpdateAsset(updatedAsset);
      final storedAssets = await useCase.getAssets();

      // Then & Verify
      expect(storedAssets.length, equals(1));
      expect(storedAssets.first.name, equals('Updated Name ETF'));
      expect(storedAssets.first.currentValue, equals(15000.0));
    });

    // -------------------------------------------------------------
    // 3. Delete Asset & Clear All
    // -------------------------------------------------------------
    test('Given multiple assets, When deleteAsset or clearAll is called, Then removes specified or all assets', () async {
      // Given
      final asset1 = InvestmentAsset(
        id: '1',
        name: 'A1',
        category: AssetCategory.equities,
        type: InvestmentType.oneTime,
        investedAmount: 100,
        currentValue: 100,
        startDate: DateTime.now(),
        expectedCAGR: 10,
      );
      final asset2 = InvestmentAsset(
        id: '2',
        name: 'A2',
        category: AssetCategory.goldPrecious,
        type: InvestmentType.oneTime,
        investedAmount: 200,
        currentValue: 200,
        startDate: DateTime.now(),
        expectedCAGR: 10,
      );
      await useCase.addOrUpdateAsset(asset1);
      await useCase.addOrUpdateAsset(asset2);

      // When: Delete asset 1
      await useCase.deleteAsset('1');
      var list = await useCase.getAssets();

      // Then & Verify: Only asset 2 remains
      expect(list.length, equals(1));
      expect(list.first.id, equals('2'));

      // When: Clear all
      await useCase.clearAll();
      list = await useCase.getAssets();

      // Then & Verify: Completely empty
      expect(list, isEmpty);
    });

    // -------------------------------------------------------------
    // 4. Load Sample Portfolio Preset
    // -------------------------------------------------------------
    test('Given empty portfolio, When loadSamplePortfolio is called with balanced preset, Then loads curated starter assets', () async {
      // When
      await useCase.loadSamplePortfolio('balanced');
      final assets = await useCase.getAssets();

      // Then & Verify
      expect(assets.length, equals(5));
      expect(assets.any((a) => a.category == AssetCategory.mutualFunds), isTrue);
      expect(assets.any((a) => a.category == AssetCategory.goldPrecious), isTrue);
    });

    test('Given empty portfolio, When loadSamplePortfolio is called with aggressive preset, Then loads high growth tech and crypto assets', () async {
      // When
      await useCase.loadSamplePortfolio('aggressive');
      final assets = await useCase.getAssets();

      // Then & Verify
      expect(assets.length, equals(4));
      expect(assets.any((a) => a.category == AssetCategory.crypto), isTrue);
      expect(assets.any((a) => a.category == AssetCategory.equities), isTrue);
    });
  });
}
