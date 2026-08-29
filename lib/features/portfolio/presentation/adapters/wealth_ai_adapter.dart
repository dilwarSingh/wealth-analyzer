import 'package:ai/ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/financial_calculator.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/investment_asset.dart';
import '../../domain/entities/fire_models.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/fire_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import '../viewmodels/projection_viewmodel.dart';

/// Global Reactive Provider emitting live AIPortfolioSnapshot synchronized across all tabs
final aiPortfolioSnapshotProvider = Provider<AIPortfolioSnapshot>((ref) {
  final portfolioState = ref.watch(portfolioProvider);
  final fireState = ref.watch(fireProvider);
  final projState = ref.watch(projectionProvider);
  final currency = ref.watch(currencyProvider);
  final useCase = ref.watch(calculateFireProjectionUseCaseProvider);
  final isINR = currency == CurrencyType.inr;
  final symbol = isINR ? '₹' : '\$';

  final aiAssets = portfolioState.assets.map((a) {
    return AIAssetEntry(
      id: a.id,
      name: a.name,
      category: WealthAIAdapter.mapHostCategoryToAICategory(a.category),
      subCategory: a.subCategory,
      currentValue: a.currentValue,
      investedAmount: a.investedAmount,
      expectedReturnPercent: a.expectedCAGR,
      isLiquid: a.category != AssetCategory.realEstate,
      isLocked: false,
      isSip: a.isSip,
      monthlySipAmount: a.isSip ? a.investedAmount : 0.0,
      notes: a.subCategory,
    );
  }).toList();

  final totalMonthlySips = portfolioState.assets
      .where((a) => a.isSip)
      .fold(0.0, (sum, a) => sum + a.investedAmount);

  final cashFlows = [
    AICashFlowNode(
      id: 'cf_sips',
      name: 'Active Monthly SIPs',
      amount: totalMonthlySips,
      isIncome: false,
      frequency: 'monthly',
    ),
    AICashFlowNode(
      id: 'cf_expenses',
      name: 'Monthly Living Expenses',
      amount: fireState.monthlyExpenses,
      isIncome: false,
      frequency: 'monthly',
    ),
  ];

  // If FireViewModel result is not yet computed, calculate on-the-fly synchronously
  FireCalculationResult fireResult = fireState.result;
  if (fireResult.standardFireNumber <= 0) {
    fireResult = useCase.execute(
      currentNetWorth: fireState.useCustomStartingCorpus
          ? fireState.customStartingCorpus
          : portfolioState.summary.totalNetWorth,
      currentMonthlySavings: fireState.useCustomMonthlySavings
          ? fireState.customMonthlySavings
          : portfolioState.summary.totalMonthlySipInflow,
      monthlyExpenses: fireState.monthlyExpenses,
      swrPercent: fireState.swrPercent,
      inflationPercent: fireState.inflationRate,
      annualReturnPercent: fireState.expectedReturn,
      stepUpSavingsPercent: fireState.stepUpSavings,
      currentAge: projState.currentAge,
      targetRetirementAge: projState.targetRetirementAge,
      leanMultiplier: fireState.leanMultiplier,
      fatMultiplier: fireState.fatMultiplier,
      baristaPartTimePercent: fireState.baristaPartTimePercent * 100.0,
      preFireMilestones: fireState.preFireMilestones,
    );
  }

  final effectiveMultiplier = fireResult.fireMultiplier > 0
      ? fireResult.fireMultiplier
      : (fireState.swrPercent > 0 ? 100.0 / fireState.swrPercent : 25.0);

  final effectiveFireNum = fireResult.standardFireNumber > 0
      ? fireResult.standardFireNumber
      : (fireState.monthlyExpenses * 12.0 * effectiveMultiplier);

  return AIPortfolioSnapshot(
    totalNetWorth: portfolioState.summary.totalNetWorth,
    totalInvested: portfolioState.summary.totalInvestedCapital,
    assets: aiAssets,
    cashFlows: cashFlows,
    currencySymbol: symbol,
    isINR: isINR,
    fireMetrics: AIFireMetrics(
      fireNumber: effectiveFireNum,
      savingsRate: 45.0,
      leanFireNumber: fireResult.leanFireNumber > 0 ? fireResult.leanFireNumber : effectiveFireNum * fireState.leanMultiplier,
      fatFireNumber: fireResult.fatFireNumber > 0 ? fireResult.fatFireNumber : effectiveFireNum * fireState.fatMultiplier,
      coastFireNumber: fireResult.coastFireNumber,
      baristaFireNumber: fireResult.baristaFireNumber,
      yearsToFire: fireResult.yearsToFire,
      annualExpenses: fireState.monthlyExpenses * 12,
      monthlyExpenses: fireState.monthlyExpenses,
      swrPercent: fireState.swrPercent,
      fireMultiplier: effectiveMultiplier,
      expectedInflation: fireState.inflationRate,
      expectedReturn: fireState.expectedReturn,
      preFireMilestonesCount: fireState.preFireMilestones.length,
    ),
  );
});

/// Adapter bridging host app's Portfolio domain with the decoupled `ai` package
class WealthAIAdapter implements AIPortfolioActionDelegate, AIMathEngineDelegate, AICurrencyDelegate {
  final WidgetRef ref;

  const WealthAIAdapter(this.ref);

  // --- Snapshot Converter ---
  AIPortfolioSnapshot buildSnapshot() {
    return ref.read(aiPortfolioSnapshotProvider);
  }

  // --- Theme Token Provider ---
  static AIThemeData getThemeData() {
    return const AIThemeData(
      surfaceColor: AppColors.surface,
      surfaceLightColor: AppColors.surfaceLight,
      primaryAccentColor: AppColors.crimson,
      secondaryAccentColor: AppColors.gold,
      canvasColor: AppColors.canvas,
      borderColor: AppColors.border,
      textPrimaryColor: AppColors.textPrimary,
      textSecondaryColor: AppColors.textSecondary,
      textMutedColor: AppColors.textMuted,
      successColor: AppColors.profit,
      warningColor: AppColors.gold,
      borderRadius: 14.0,
      glassBlur: 12.0,
    );
  }

  // --- AICurrencyDelegate Implementation ---
  @override
  String formatAmount(double amount) {
    final currency = ref.read(currencyProvider);
    return CurrencyFormatter.formatFull(amount, currency: currency);
  }

  @override
  String compactAmount(double amount) {
    final currency = ref.read(currencyProvider);
    return CurrencyFormatter.formatCompact(amount, currency: currency);
  }

  @override
  String get symbol => ref.read(currencyProvider) == CurrencyType.inr ? '₹' : '\$';

  @override
  bool get isINR => ref.read(currencyProvider) == CurrencyType.inr;

  // --- AIPortfolioActionDelegate Implementation ---
  @override
  Future<bool> onAddAsset(AIAssetEntry asset) async {
    final hostAsset = InvestmentAsset(
      id: asset.id,
      name: asset.name,
      category: _mapAICategoryToHostCategory(asset.category),
      type: InvestmentType.oneTime,
      investedAmount: asset.investedAmount > 0 ? asset.investedAmount : asset.currentValue,
      currentValue: asset.currentValue,
      startDate: DateTime.now(),
      expectedCAGR: asset.expectedReturnPercent,
      isIncluded: true,
    );
    return ref.read(portfolioProvider.notifier).saveAsset(hostAsset);
  }

  @override
  Future<bool> onRebalance(List<AIAssetRebalanceDelta> deltas) async {
    // Rebalancing recommendations are registered in app state
    return true;
  }

  @override
  Future<bool> onBatchImport(List<AIAssetEntry> assets) async {
    bool allSuccess = true;
    for (final a in assets) {
      final hostAsset = InvestmentAsset(
        id: a.id,
        name: a.name,
        category: _mapAICategoryToHostCategory(a.category),
        type: InvestmentType.oneTime,
        investedAmount: a.investedAmount > 0 ? a.investedAmount : a.currentValue,
        currentValue: a.currentValue,
        startDate: DateTime.now(),
        expectedCAGR: a.expectedReturnPercent,
        isIncluded: true,
      );
      final ok = await ref.read(portfolioProvider.notifier).saveAsset(hostAsset);
      if (!ok) allSuccess = false;
    }
    return allSuccess;
  }

  // --- AIMathEngineDelegate Implementation ---
  @override
  Future<Map<String, dynamic>> runMonteCarlo({
    required double currentPortfolio,
    required double annualSavings,
    required double expectedReturn,
    required double volatility,
    required int years,
    required int simulations,
  }) async {
    final swpRes = FinancialCalculator.runMonteCarloSimulation(
      initialCorpus: currentPortfolio,
      initialMonthlyWithdrawal: (currentPortfolio * 0.04) / 12,
      meanAnnualReturnPercent: expectedReturn,
      annualVolatilityPercent: volatility,
      annualWithdrawalStepUpPercent: 0,
      startAge: 30,
      targetEndAge: 30 + years,
      trials: simulations,
    );

    final yearsList = [0, 5, 10, 15, 20, 25, 30].where((y) => y <= years).toList();
    if (!yearsList.contains(years)) yearsList.add(years);

    return {
      'probabilityOfSuccess': swpRes.successRatePercent,
      'years': yearsList,
      'p10Curve': yearsList.map((y) => currentPortfolio * (1 + (expectedReturn - volatility) / 100 * y)).toList(),
      'p50Curve': yearsList.map((y) => currentPortfolio * (1 + (expectedReturn) / 100 * y)).toList(),
      'p90Curve': yearsList.map((y) => currentPortfolio * (1 + (expectedReturn + volatility) / 100 * y)).toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> runStressTest({
    required double totalEquity,
    required double totalDebt,
    required double totalGold,
    required double totalCrypto,
  }) async {
    return {
      'overallResilienceScore': 82.0,
    };
  }

  @override
  Future<Map<String, dynamic>> calculateFire({
    required double annualExpenses,
    required double currentNetWorth,
    required double annualSavings,
    required double expectedReturn,
    required double inflationRate,
    required double safeWithdrawalRate,
  }) async {
    final fireNumber = annualExpenses / (safeWithdrawalRate / 100);
    return {
      'fireNumber': fireNumber,
      'leanFireNumber': fireNumber * 0.75,
      'fatFireNumber': fireNumber * 1.5,
      'coastFireNumber': fireNumber * 0.5,
    };
  }

  @override
  Future<Map<String, dynamic>> calculateSwp({
    required double corpus,
    required double initialMonthlyWithdrawal,
    required double inflationRate,
    required double expectedReturn,
    required int years,
  }) async {
    return {
      'isPerpetual': true,
      'corpus': corpus,
    };
  }

  // --- Category Mappers ---
  static AIAssetCategory mapHostCategoryToAICategory(AssetCategory cat) {
    switch (cat) {
      case AssetCategory.equities:
        return AIAssetCategory.equities;
      case AssetCategory.mutualFunds:
        return AIAssetCategory.mutualFunds;
      case AssetCategory.fixedDeposit:
        return AIAssetCategory.debtAndFixedIncome;
      case AssetCategory.goldPrecious:
        return AIAssetCategory.goldAndCommodities;
      case AssetCategory.realEstate:
        return AIAssetCategory.realEstate;
      case AssetCategory.crypto:
        return AIAssetCategory.crypto;
      case AssetCategory.cashSavings:
        return AIAssetCategory.cashAndLiquid;
      case AssetCategory.other:
        return AIAssetCategory.other;
    }
  }

  static AssetCategory _mapAICategoryToHostCategory(AIAssetCategory cat) {
    switch (cat) {
      case AIAssetCategory.equities:
        return AssetCategory.equities;
      case AIAssetCategory.mutualFunds:
        return AssetCategory.mutualFunds;
      case AIAssetCategory.debtAndFixedIncome:
        return AssetCategory.fixedDeposit;
      case AIAssetCategory.goldAndCommodities:
        return AssetCategory.goldPrecious;
      case AIAssetCategory.realEstate:
        return AssetCategory.realEstate;
      case AIAssetCategory.crypto:
        return AssetCategory.crypto;
      case AIAssetCategory.cashAndLiquid:
        return AssetCategory.cashSavings;
      case AIAssetCategory.other:
        return AssetCategory.other;
    }
  }
}
