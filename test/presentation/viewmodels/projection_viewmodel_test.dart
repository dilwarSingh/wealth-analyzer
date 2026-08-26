import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/data/datasources/local_portfolio_datasource.dart';
import 'package:wealth_projector/features/portfolio/data/models/investment_asset_model.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/projection_viewmodel.dart';

class MockInMemoryDataSource implements LocalPortfolioDataSource {
  final List<InvestmentAssetModel> _storage = [];
  UserSettingsModel settings;

  MockInMemoryDataSource({this.settings = const UserSettingsModel()});

  @override
  Future<List<InvestmentAssetModel>> getStoredAssets() async => List.from(_storage);

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
  Future<UserSettingsModel> getUserSettings() async => settings;

  @override
  Future<void> saveUserSettings(UserSettingsModel s) async {
    settings = s;
  }
}

void main() {
  group('ProjectionViewModel Tests (Given - When - Then - Verify)', () {
    test('Given default setup, When initialized, Then defaults to 28 current age, 55 retirement age, 6% inflation, 10% step-up', () {
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockInMemoryDataSource()),
        ],
      );
      addTearDown(() => container.dispose());

      // When
      final projState = container.read(projectionProvider);

      // Then & Verify
      expect(projState.currentAge, equals(28));
      expect(projState.targetRetirementAge, equals(55));
      expect(projState.annualInflationPercent, equals(6.0));
      expect(projState.globalStepUpPercent, equals(10.0));
      expect(projState.selectedTimeframe, equals(ChartTimeframe.tenYears));
    });

    test('Given pre-saved user settings in datasource, When ProjectionViewModel is initialized, Then restores saved simulator settings', () async {
      final customSettings = const UserSettingsModel(
        currentAge: 32,
        targetRetirementAge: 62,
        inflationRate: 7.5,
        globalStepUpRate: 12.0,
      );
      final mockDs = MockInMemoryDataSource(settings: customSettings);

      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(() => container.dispose());

      // Read to trigger init and wait for async _loadStoredSettings
      container.read(projectionProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Then & Verify
      final state = container.read(projectionProvider);
      expect(state.currentAge, equals(32));
      expect(state.targetRetirementAge, equals(62));
      expect(state.annualInflationPercent, equals(7.5));
      expect(state.globalStepUpPercent, equals(12.0));
    });

    test('Given active portfolio assets, When current age or retirement age is changed, Then updates points and persists settings', () async {
      final mockDs = MockInMemoryDataSource();
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(() => container.dispose());

      // Given: Add an asset to portfolio
      final asset = InvestmentAsset(
        id: 'proj-asset-1',
        name: 'Equity SIP',
        category: AssetCategory.equities,
        type: InvestmentType.monthlySip,
        investedAmount: 10000.0,
        currentValue: 0.0,
        startDate: DateTime.now(),
        expectedCAGR: 12.0,
      );
      await container.read(portfolioProvider.notifier).saveAsset(asset);

      // When: Update current age to 30 and retirement age to 60
      final notifier = container.read(projectionProvider.notifier);
      notifier.setCurrentAge(30);
      notifier.setTargetRetirementAge(60);

      // Allow async persist
      await Future.delayed(const Duration(milliseconds: 20));

      // Then & Verify: In-memory simulation result
      final state = container.read(projectionProvider);
      expect(state.currentAge, equals(30));
      expect(state.targetRetirementAge, equals(60));
      expect(state.simulationResult.points.length, equals(31)); // 0..30
      expect(state.simulationResult.points.first.age, equals(30));
      expect(state.simulationResult.points.last.age, equals(60));

      // Verify persisted in datasource
      expect(mockDs.settings.currentAge, equals(30));
      expect(mockDs.settings.targetRetirementAge, equals(60));
    });

    test('Given simulation parameters, When setting inflation and step-up rates, Then updates projection state and persists settings', () async {
      final mockDs = MockInMemoryDataSource();
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(() => container.dispose());

      // When
      final notifier = container.read(projectionProvider.notifier);
      notifier.setAnnualInflation(7.5);
      notifier.setGlobalStepUp(15.0);
      notifier.setTimeframe(ChartTimeframe.fiveYears);

      await Future.delayed(const Duration(milliseconds: 20));

      // Then & Verify
      final state = container.read(projectionProvider);
      expect(state.annualInflationPercent, equals(7.5));
      expect(state.globalStepUpPercent, equals(15.0));
      expect(state.selectedTimeframe, equals(ChartTimeframe.fiveYears));

      expect(mockDs.settings.inflationRate, equals(7.5));
      expect(mockDs.settings.globalStepUpRate, equals(15.0));
    });

    test('Given invalid age constraints (current >= retirement or retirement <= current), When set, Then ignores invalid values', () {
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockInMemoryDataSource()),
        ],
      );
      addTearDown(() => container.dispose());

      final notifier = container.read(projectionProvider.notifier);

      // When: Attempt setting current age to 60 while retirement age is 55
      notifier.setCurrentAge(60);
      expect(container.read(projectionProvider).currentAge, equals(28)); // unchanged

      // When: Attempt setting retirement age to 20 while current age is 28
      notifier.setTargetRetirementAge(20);
      expect(container.read(projectionProvider).targetRetirementAge, equals(55)); // unchanged
    });
  });
}
