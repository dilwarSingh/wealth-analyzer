import 'asset_category.dart';

class PortfolioSummary {
  final double totalNetWorth;
  final double totalInvestedCapital;
  final double totalUnrealizedGains;
  final double totalGainsPercent;
  final double totalMonthlySipInflow;
  final double blendedExpectedCagr;
  final int totalAssetCount;
  final Map<AssetCategory, double> categoryDistribution;
  final Map<AssetCategory, double> categoryMonthlySip;

  const PortfolioSummary({
    required this.totalNetWorth,
    required this.totalInvestedCapital,
    required this.totalUnrealizedGains,
    required this.totalGainsPercent,
    required this.totalMonthlySipInflow,
    required this.blendedExpectedCagr,
    required this.totalAssetCount,
    required this.categoryDistribution,
    required this.categoryMonthlySip,
  });

  factory PortfolioSummary.empty() {
    return const PortfolioSummary(
      totalNetWorth: 0.0,
      totalInvestedCapital: 0.0,
      totalUnrealizedGains: 0.0,
      totalGainsPercent: 0.0,
      totalMonthlySipInflow: 0.0,
      blendedExpectedCagr: 0.0,
      totalAssetCount: 0,
      categoryDistribution: {},
      categoryMonthlySip: {},
    );
  }

  PortfolioSummary copyWith({
    double? totalNetWorth,
    double? totalInvestedCapital,
    double? totalUnrealizedGains,
    double? totalGainsPercent,
    double? totalMonthlySipInflow,
    double? blendedExpectedCagr,
    int? totalAssetCount,
    Map<AssetCategory, double>? categoryDistribution,
    Map<AssetCategory, double>? categoryMonthlySip,
  }) {
    return PortfolioSummary(
      totalNetWorth: totalNetWorth ?? this.totalNetWorth,
      totalInvestedCapital: totalInvestedCapital ?? this.totalInvestedCapital,
      totalUnrealizedGains: totalUnrealizedGains ?? this.totalUnrealizedGains,
      totalGainsPercent: totalGainsPercent ?? this.totalGainsPercent,
      totalMonthlySipInflow: totalMonthlySipInflow ?? this.totalMonthlySipInflow,
      blendedExpectedCagr: blendedExpectedCagr ?? this.blendedExpectedCagr,
      totalAssetCount: totalAssetCount ?? this.totalAssetCount,
      categoryDistribution: categoryDistribution ?? this.categoryDistribution,
      categoryMonthlySip: categoryMonthlySip ?? this.categoryMonthlySip,
    );
  }
}
