import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:wealth_projector/features/portfolio/domain/usecases/calculate_portfolio_kpis.dart';
import 'package:wealth_projector/features/portfolio/domain/usecases/manage_assets_usecase.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';

class InMemoryPortfolioRepository implements PortfolioRepository {
  final List<InvestmentAsset> _assets = [];
  UserSettingsModel _settings = const UserSettingsModel();

  @override
  Future<List<InvestmentAsset>> getAssets() async => List.from(_assets);

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
  group('PortfolioViewModel Tests (Given - When - Then - Verify)', () {
    late InMemoryPortfolioRepository repository;
    late ManageAssetsUseCase manageUseCase;
    late CalculatePortfolioKPIsUseCase kpiUseCase;
    late PortfolioViewModel viewModel;

    setUp(() {
      repository = InMemoryPortfolioRepository();
      manageUseCase = ManageAssetsUseCase(repository);
      kpiUseCase = CalculatePortfolioKPIsUseCase();
      viewModel = PortfolioViewModel(manageUseCase, kpiUseCase);
    });

    test('Given initial setup, When loadPortfolio executes, Then updates state with empty portfolio and stops loading', () async {
      // When: Wait for initial load
      await viewModel.loadPortfolio();

      // Then & Verify
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.assets, isEmpty);
      expect(viewModel.state.summary.totalNetWorth, equals(0.0));
      expect(viewModel.state.errorMessage, isNull);
    });

    test('Given new asset, When saveAsset is called, Then updates repository and notifies state with new asset and recalculated KPIs', () async {
      // Given
      final asset = InvestmentAsset(
        id: 'vm-asset-1',
        name: 'Nifty 50 Index',
        category: AssetCategory.mutualFunds,
        type: InvestmentType.monthlySip,
        investedAmount: 10000.0,
        currentValue: 0.0,
        startDate: DateTime.now(),
        expectedCAGR: 12.0,
      );

      // When
      final success = await viewModel.saveAsset(asset);

      // Then & Verify
      expect(success, isTrue);
      expect(viewModel.state.assets.length, equals(1));
      expect(viewModel.state.summary.totalMonthlySipInflow, equals(10000.0));
      expect(viewModel.state.summary.blendedExpectedCagr, equals(12.0));
      expect(viewModel.state.sankeyData.links, isNotEmpty);
    });

    test('Given preset request, When loadSamplePreset is called, Then loads preset starter holdings', () async {
      // When
      final success = await viewModel.loadSamplePreset('balanced');

      // Then & Verify
      expect(success, isTrue);
      expect(viewModel.state.assets.length, equals(5));
      expect(viewModel.state.summary.totalNetWorth, greaterThan(0.0));
    });

    test('Given active holdings, When clearAll is called, Then empties asset state', () async {
      // Given: Load sample holdings first
      await viewModel.loadSamplePreset('balanced');
      expect(viewModel.state.assets.isNotEmpty, isTrue);

      // When: Clear all
      final success = await viewModel.clearAll();

      // Then & Verify
      expect(success, isTrue);
      expect(viewModel.state.assets, isEmpty);
      expect(viewModel.state.summary.totalNetWorth, equals(0.0));
    });

    test('Given active portfolio, When exportPortfolioAsJson and importPortfolioFromJson are called, Then exports and restores state accurately', () async {
      // Given: Load balanced preset
      await viewModel.loadSamplePreset('balanced');
      final originalCount = viewModel.state.assets.length;
      final originalNetWorth = viewModel.state.summary.totalNetWorth;

      // When: Export to JSON string
      final jsonExport = viewModel.exportPortfolioAsJson();
      expect(jsonExport, isNotEmpty);

      // When: Clear all
      await viewModel.clearAll();
      expect(viewModel.state.assets, isEmpty);

      // When: Import JSON back
      final importSuccess = await viewModel.importPortfolioFromJson(jsonExport);

      // Then & Verify
      expect(importSuccess, isTrue);
      expect(viewModel.state.assets.length, equals(originalCount));
      expect(viewModel.state.summary.totalNetWorth, equals(originalNetWorth));
    });

    test('Given invalid JSON string, When importPortfolioFromJson is called, Then fails safely and records error message', () async {
      // When: Attempt importing corrupt JSON
      final success = await viewModel.importPortfolioFromJson('not-valid-json');

      // Then & Verify
      expect(success, isFalse);
      expect(viewModel.state.errorMessage, isNotNull);
    });

    test('Given active holdings, When toggleAssetInclusion is called, Then updates asset inclusion and recalculates KPIs', () async {
      await viewModel.loadSamplePreset('balanced');
      final originalNetWorth = viewModel.state.summary.totalNetWorth;
      final targetAsset = viewModel.state.assets.first;

      // Toggle asset OFF
      final success = await viewModel.toggleAssetInclusion(targetAsset.id, false);
      expect(success, isTrue);
      expect(viewModel.state.assets.first.isIncluded, isFalse);
      expect(viewModel.state.summary.totalNetWorth, lessThan(originalNetWorth));

      // Toggle asset back ON
      await viewModel.toggleAssetInclusion(targetAsset.id, true);
      expect(viewModel.state.assets.first.isIncluded, isTrue);
      expect(viewModel.state.summary.totalNetWorth, equals(originalNetWorth));
    });

    test('Given active holdings, When toggleAllAssetsInclusion(false) is called, Then unchecks all assets and zeroes net worth', () async {
      await viewModel.loadSamplePreset('balanced');
      expect(viewModel.state.summary.totalNetWorth, greaterThan(0.0));

      // Deselect all
      final success = await viewModel.toggleAllAssetsInclusion(false);
      expect(success, isTrue);
      expect(viewModel.state.assets.every((a) => !a.isIncluded), isTrue);
      expect(viewModel.state.summary.totalNetWorth, equals(0.0));

      // Select all
      await viewModel.toggleAllAssetsInclusion(true);
      expect(viewModel.state.assets.every((a) => a.isIncluded), isTrue);
      expect(viewModel.state.summary.totalNetWorth, greaterThan(0.0));
    });
  });
}
