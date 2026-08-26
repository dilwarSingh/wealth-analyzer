import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/data/datasources/local_portfolio_datasource.dart';
import 'package:wealth_projector/features/portfolio/data/models/investment_asset_model.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/risk_analysis_models.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/risk_analysis_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/swp_viewmodel.dart';

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
  group('RiskAnalysisViewModel Tests (Given - When - Then - Verify)', () {
    test('Given default setup, When initialized, Then starts with GFC 2008 scenario and default volatility', () {
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockInMemoryDataSource()),
        ],
      );
      addTearDown(() => container.dispose());

      final state = container.read(riskAnalysisProvider);
      expect(state.selectedCrisisScenario, equals(CrisisScenario.gfc2008));
      expect(state.volatilityPercent, greaterThan(0.0));
      expect(state.isCustomVolatility, isFalse);
    });

    test('Given active custom corpus in SWP, When RiskAnalysis is read, Then runs Monte Carlo and Crisis Stress Test', () {
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockInMemoryDataSource()),
        ],
      );
      addTearDown(() => container.dispose());

      final swpNotifier = container.read(swpProvider.notifier);
      swpNotifier.setUseCustomCorpus(true);
      swpNotifier.setCustomCorpusAmount(80000000.0); // ₹8 Cr
      swpNotifier.setMonthlyWithdrawal(50000.0);

      final riskState = container.read(riskAnalysisProvider);
      expect(riskState.monteCarloResult.totalRuns, equals(1000));
      expect(riskState.monteCarloResult.percentiles.isNotEmpty, isTrue);
      expect(riskState.monteCarloResult.successRatePercent, greaterThan(0.0));
      expect(riskState.crisisStressTestResult.yearlyPoints.isNotEmpty, isTrue);
    });

    test('Given scenario switch to 2020 Flash Crash or Custom, When selected, Then updates stress-test results', () {
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockInMemoryDataSource()),
        ],
      );
      addTearDown(() => container.dispose());

      final swpNotifier = container.read(swpProvider.notifier);
      swpNotifier.setUseCustomCorpus(true);
      swpNotifier.setCustomCorpusAmount(15000000.0);

      final riskNotifier = container.read(riskAnalysisProvider.notifier);
      riskNotifier.selectCrisisScenario(CrisisScenario.flashCrash2020);

      expect(container.read(riskAnalysisProvider).selectedCrisisScenario, equals(CrisisScenario.flashCrash2020));
      expect(container.read(riskAnalysisProvider).crisisStressTestResult.scenario, equals(CrisisScenario.flashCrash2020));

      riskNotifier.setVolatilityPercent(18.5);
      expect(container.read(riskAnalysisProvider).volatilityPercent, equals(18.5));
      expect(container.read(riskAnalysisProvider).isCustomVolatility, isTrue);
    });
  });
}
