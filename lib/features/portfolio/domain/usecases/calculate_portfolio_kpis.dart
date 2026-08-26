import '../../../../core/utils/financial_calculator.dart';
import '../entities/asset_category.dart';
import '../entities/investment_asset.dart';
import '../entities/portfolio_summary.dart';

class CalculatePortfolioKPIsUseCase {
  PortfolioSummary execute(List<InvestmentAsset> assets) {
    final activeAssets = assets.where((a) => a.isIncluded).toList();
    if (activeAssets.isEmpty) {
      return PortfolioSummary.empty().copyWith(totalAssetCount: assets.length);
    }

    double totalNetWorth = 0.0;
    double totalInvestedCapital = 0.0;
    double totalMonthlySip = 0.0;

    final Map<AssetCategory, double> categoryDistribution = {};
    final Map<AssetCategory, double> categoryMonthlySip = {};
    final List<({double value, double cagr})> cagrWeights = [];

    for (final asset in activeAssets) {
      final effectiveCurrent = asset.isOneTime
          ? (asset.currentValue > 0 ? asset.currentValue : asset.investedAmount)
          : asset.currentValue;

      totalNetWorth += effectiveCurrent;

      // For lump sum, invested capital is the lump sum amount.
      // For SIP: if currentValue == 0 (new SIP), invested capital is 0.
      // If currentValue > 0 (existing SIP), invested capital is min(investedAmount, currentValue).
      final effectiveInvested = asset.isSip
          ? (asset.currentValue > 0 ? (asset.investedAmount <= asset.currentValue ? asset.investedAmount : asset.currentValue) : 0.0)
          : asset.investedAmount;
      totalInvestedCapital += effectiveInvested;

      if (asset.isSip) {
        totalMonthlySip += asset.investedAmount;
        categoryMonthlySip[asset.category] =
            (categoryMonthlySip[asset.category] ?? 0.0) + asset.investedAmount;
      }

      // Weight for category allocation & blended CAGR:
      final weight = effectiveCurrent > 0 ? effectiveCurrent : asset.investedAmount;
      categoryDistribution[asset.category] =
          (categoryDistribution[asset.category] ?? 0.0) + weight;

      cagrWeights.add((value: weight, cagr: asset.expectedCAGR));
    }

    final totalUnrealizedGains = totalNetWorth - totalInvestedCapital;
    final totalGainsPercent = totalInvestedCapital > 0
        ? (totalUnrealizedGains / totalInvestedCapital) * 100.0
        : 0.0;

    final blendedExpectedCagr =
        FinancialCalculator.calculateBlendedCagr(assetWeights: cagrWeights);

    return PortfolioSummary(
      totalNetWorth: totalNetWorth,
      totalInvestedCapital: totalInvestedCapital,
      totalUnrealizedGains: totalUnrealizedGains,
      totalGainsPercent: totalGainsPercent,
      totalMonthlySipInflow: totalMonthlySip,
      blendedExpectedCagr: blendedExpectedCagr,
      totalAssetCount: assets.length,
      categoryDistribution: categoryDistribution,
      categoryMonthlySip: categoryMonthlySip,
    );
  }
}
