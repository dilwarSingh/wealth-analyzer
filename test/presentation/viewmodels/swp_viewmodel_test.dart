import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/data/datasources/local_portfolio_datasource.dart';
import 'package:wealth_projector/features/portfolio/data/models/investment_asset_model.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/swp_models.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/portfolio_viewmodel.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/projection_viewmodel.dart';
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
  group('SwpViewModel Tests (Given - When - Then - Verify)', () {
    test('Given default setup, When initialized, Then defaults to 50k monthly in today\'s terms, 8% CAGR, 6% step-up, 85 life age', () {
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockInMemoryDataSource()),
        ],
      );
      addTearDown(() => container.dispose());

      final state = container.read(swpProvider);
      expect(state.monthlyWithdrawal, equals(50000.0));
      expect(state.isWithdrawalInTodayTerms, isTrue);
      expect(state.postRetirementCagr, equals(8.0));
      expect(state.inflationStepUp, equals(6.0));
      expect(state.targetLifeAge, equals(85));
      expect(state.useCustomCorpus, isFalse);
      expect(state.milestoneExpenses, isEmpty);
    });

    test('Given accumulation portfolio with final net worth, When SWP is calculated, Then automatically links retirement corpus and generates schedule', () async {
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockInMemoryDataSource()),
        ],
      );
      addTearDown(() => container.dispose());

      // Add high-growth asset
      final asset = InvestmentAsset(
        id: 'swp-test-1',
        name: 'Index Fund',
        category: AssetCategory.mutualFunds,
        type: InvestmentType.monthlySip,
        investedAmount: 25000.0,
        currentValue: 0.0,
        startDate: DateTime.now(),
        expectedCAGR: 12.0,
      );
      await container.read(portfolioProvider.notifier).saveAsset(asset);

      final projState = container.read(projectionProvider);
      expect(projState.simulationResult.finalBaseNetWorth, greaterThan(0));

      final swpState = container.read(swpProvider);
      expect(swpState.swpResult.initialCorpus, equals(projState.simulationResult.finalBaseNetWorth));
      expect(swpState.swpResult.yearlyPoints.isNotEmpty, isTrue);
    });

    test('Given custom corpus toggle, When user sets custom corpus, Then recalculates SWP on custom amount and persists setting', () async {
      final mockDs = MockInMemoryDataSource();
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(() => container.dispose());

      final notifier = container.read(swpProvider.notifier);
      notifier.setUseCustomCorpus(true);
      notifier.setCustomCorpusAmount(15000000.0); // ₹1.5 Cr
      notifier.setMonthlyWithdrawal(60000.0);
      notifier.setWithdrawalInTodayTerms(true);
      notifier.setPostRetirementCagr(9.0);
      notifier.setInflationStepUp(5.0);
      notifier.setTargetLifeAge(90);

      await Future.delayed(const Duration(milliseconds: 20));

      final state = container.read(swpProvider);
      expect(state.useCustomCorpus, isTrue);
      expect(state.customCorpusAmount, equals(15000000.0));
      expect(state.monthlyWithdrawal, equals(60000.0));
      expect(state.isWithdrawalInTodayTerms, isTrue);
      expect(state.postRetirementCagr, equals(9.0));
      expect(state.inflationStepUp, equals(5.0));
      expect(state.targetLifeAge, equals(90));
      expect(state.swpResult.initialCorpus, equals(15000000.0));

      // Verify persistence in datasource
      expect(mockDs.settings.swpUseCustomCorpus, isTrue);
      expect(mockDs.settings.swpCustomCorpusAmount, equals(15000000.0));
      expect(mockDs.settings.swpMonthlyWithdrawal, equals(60000.0));
      expect(mockDs.settings.swpWithdrawalInTodayTerms, isTrue);
    });

    test('Given milestone expenses, When added, updated, toggled, and removed, Then updates state and recalculates schedule', () async {
      final mockDs = MockInMemoryDataSource();
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(mockDs),
        ],
      );
      addTearDown(() => container.dispose());

      final notifier = container.read(swpProvider.notifier);
      const milestone = SwpMilestoneExpense(
        id: 'milestone-1',
        name: 'Medical Reserve',
        targetAge: 65,
        amount: 1500000.0,
        inTodayTerms: true,
        isEnabled: true,
      );

      // Add
      notifier.addMilestoneExpense(milestone);
      expect(container.read(swpProvider).milestoneExpenses.length, equals(1));

      // Toggle
      notifier.toggleMilestoneExpense('milestone-1');
      expect(container.read(swpProvider).milestoneExpenses.first.isEnabled, isFalse);

      // Update
      notifier.updateMilestoneExpense(milestone.copyWith(amount: 2000000.0, isEnabled: true));
      expect(container.read(swpProvider).milestoneExpenses.first.amount, equals(2000000.0));

      // Remove
      notifier.removeMilestoneExpense('milestone-1');
      expect(container.read(swpProvider).milestoneExpenses, isEmpty);
    });

    test('Given direct withdrawal mode, When applyWithdrawalRule is called for 2%, 3%, 4%, and 5%, Then sets correct nominal monthly withdrawal', () {
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockInMemoryDataSource()),
        ],
      );
      addTearDown(() => container.dispose());

      final notifier = container.read(swpProvider.notifier);
      notifier.setWithdrawalInTodayTerms(false);
      notifier.setUseCustomCorpus(true);
      notifier.setCustomCorpusAmount(12000000.0); // ₹1.2 Cr

      // When: Apply 2% Rule -> (12,000,000 * 0.02) / 12 = 20,000 / month
      notifier.applyWithdrawalRule(2.0);
      expect(container.read(swpProvider).monthlyWithdrawal, equals(20000.0));

      // When: Apply 3% Rule -> (12,000,000 * 0.03) / 12 = 30,000 / month
      notifier.applyWithdrawalRule(3.0);
      expect(container.read(swpProvider).monthlyWithdrawal, equals(30000.0));

      // When: Apply 4% Rule -> (12,000,000 * 0.04) / 12 = 40,000 / month
      notifier.applySafeFourPercentRule();
      expect(container.read(swpProvider).monthlyWithdrawal, equals(40000.0));

      // When: Apply 5% Rule -> (12,000,000 * 0.05) / 12 = 50,000 / month
      notifier.applyWithdrawalRule(5.0);
      expect(container.read(swpProvider).monthlyWithdrawal, equals(50000.0));
    });

    test('Given depleted SWP plan, When evaluated, Then populates solvency recommendation with required targets and shortfalls', () {
      final container = ProviderContainer(
        overrides: [
          localDataSourceProvider.overrideWithValue(MockInMemoryDataSource()),
        ],
      );
      addTearDown(() => container.dispose());

      final notifier = container.read(swpProvider.notifier);
      notifier.setUseCustomCorpus(true);
      notifier.setCustomCorpusAmount(1000000.0); // Only ₹10 Lakhs
      notifier.setMonthlyWithdrawal(100000.0); // High withdrawal ₹1 Lakh/mo

      final state = container.read(swpProvider);
      expect(state.swpResult.isSustainable, isFalse);
      expect(state.swpResult.recommendation, isNotNull);
      expect(state.swpResult.recommendation!.isAtRisk, isTrue);
      expect(state.swpResult.recommendation!.requiredStandardCorpus, greaterThan(1000000.0));
      expect(state.swpResult.recommendation!.standardShortfall, greaterThan(0.0));
      expect(state.swpResult.recommendation!.requiredMonteCarlo95Corpus, greaterThan(1000000.0));
      expect(state.swpResult.recommendation!.requiredCrisisCorpus, greaterThan(1000000.0));
    });
  });
}
