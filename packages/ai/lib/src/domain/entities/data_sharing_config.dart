import '../contracts/ai_portfolio_contract.dart';
import 'ai_config.dart';

/// Configuration specifying what financial data is shared with the AI for a chat session
class AIDataSharingConfig {
  final bool includeTotalNetWorth;
  final bool includeAssetAllocation;
  final bool includeCashFlows;
  final bool includeFireMetrics;
  final Set<AIAssetCategory> includedCategories;
  final Set<String> excludedSubcategories;
  final Set<String> excludedAssetIds;
  final Set<String> includedFireMetrics;
  final Set<String> includedCashFlowItems;
  final Set<String> includedSummaryItems;
  final double? selectedFireTarget;
  final ContextPrivacyMode privacyMode;
  final bool anonymizeValues;
  final bool rememberForFutureSessions;

  const AIDataSharingConfig({
    this.includeTotalNetWorth = true,
    this.includeAssetAllocation = true,
    this.includeCashFlows = true,
    this.includeFireMetrics = true,
    this.includedCategories = const {
      AIAssetCategory.equities,
      AIAssetCategory.mutualFunds,
      AIAssetCategory.debtAndFixedIncome,
      AIAssetCategory.goldAndCommodities,
      AIAssetCategory.realEstate,
      AIAssetCategory.crypto,
      AIAssetCategory.cashAndLiquid,
      AIAssetCategory.other,
    },
    this.excludedSubcategories = const {},
    this.excludedAssetIds = const {},
    this.includedFireMetrics = const {
      'targetCorpus',
      'expenses',
      'swr',
      'timeline',
      'milestones',
    },
    this.includedCashFlowItems = const {
      'inflow',
      'sips',
      'expenses',
      'fcf',
    },
    this.includedSummaryItems = const {
      'netWorth',
      'allocation',
      'assumptions',
    },
    this.selectedFireTarget,
    this.privacyMode = ContextPrivacyMode.fullPortfolio,
    this.anonymizeValues = false,
    this.rememberForFutureSessions = false,
  });

  /// Filter a portfolio snapshot based on this configuration
  AIPortfolioSnapshot filterSnapshot(AIPortfolioSnapshot original) {
    if (privacyMode == ContextPrivacyMode.promptOnly) {
      return AIPortfolioSnapshot(
        totalNetWorth: 0,
        totalInvested: 0,
        assets: const [],
        cashFlows: const [],
        currencySymbol: original.currencySymbol,
        isINR: original.isINR,
        fireMetrics: const AIFireMetrics(),
      );
    }

    // 1. Filter Assets based on category, subcategory, and individual asset id
    final filteredAssets = original.assets.where((asset) {
      if (!includedCategories.contains(asset.category)) return false;
      if (excludedAssetIds.contains(asset.id)) return false;
      if (asset.subCategory != null && asset.subCategory!.isNotEmpty) {
        if (excludedSubcategories.contains(asset.subCategory)) return false;
      }
      if (asset.notes != null && asset.notes!.isNotEmpty) {
        if (excludedSubcategories.contains(asset.notes)) return false;
      }
      return true;
    }).toList();

    // 2. Recalculate totals if filtering applies
    final double netWorth = includeTotalNetWorth && includedSummaryItems.contains('netWorth')
        ? (filteredAssets.length == original.assets.length
            ? original.totalNetWorth
            : filteredAssets.fold(0.0, (sum, a) => sum + a.currentValue))
        : 0.0;

    final double invested = includeTotalNetWorth && includedSummaryItems.contains('netWorth')
        ? (filteredAssets.length == original.assets.length
            ? original.totalInvested
            : filteredAssets.fold(0.0, (sum, a) => sum + a.investedAmount))
        : 0.0;

    // 3. Filter Cash Flows
    final filteredCashFlows = includeCashFlows
        ? original.cashFlows.where((cf) {
            if (cf.isIncome && !includedCashFlowItems.contains('inflow')) return false;
            if (!cf.isIncome && cf.name.toLowerCase().contains('sip') && !includedCashFlowItems.contains('sips')) return false;
            if (!cf.isIncome && !cf.name.toLowerCase().contains('sip') && !includedCashFlowItems.contains('expenses')) return false;
            return true;
          }).toList()
        : const <AICashFlowNode>[];

    // 4. Filter FIRE Metrics
    AIFireMetrics filteredFire = const AIFireMetrics();
    if (includeFireMetrics) {
      final origF = original.fireMetrics;
      final effectiveFireTarget = (selectedFireTarget != null && selectedFireTarget! > 0)
          ? selectedFireTarget!
          : origF.fireNumber;

      filteredFire = AIFireMetrics(
        fireNumber: includedFireMetrics.contains('targetCorpus') ? effectiveFireTarget : 0.0,
        monthlyExpenses: includedFireMetrics.contains('expenses') ? origF.monthlyExpenses : 0.0,
        annualExpenses: includedFireMetrics.contains('expenses') ? origF.annualExpenses : 0.0,
        swrPercent: includedFireMetrics.contains('swr') ? origF.swrPercent : 4.0,
        fireMultiplier: includedFireMetrics.contains('swr') ? origF.fireMultiplier : 25.0,
        leanFireNumber: origF.leanFireNumber,
        fatFireNumber: origF.fatFireNumber,
        coastFireNumber: origF.coastFireNumber,
        baristaFireNumber: origF.baristaFireNumber,
        yearsToFire: includedFireMetrics.contains('timeline') ? origF.yearsToFire : 0.0,
        savingsRate: includedFireMetrics.contains('timeline') ? origF.savingsRate : 0.0,
        targetAge: includedFireMetrics.contains('timeline') ? origF.targetAge : null,
        currentAge: includedFireMetrics.contains('timeline') ? origF.currentAge : null,
        expectedInflation: includedSummaryItems.contains('assumptions') ? origF.expectedInflation : 6.0,
        expectedReturn: includedSummaryItems.contains('assumptions') ? origF.expectedReturn : 12.0,
        preFireMilestonesCount: includedFireMetrics.contains('milestones') ? origF.preFireMilestonesCount : 0,
      );
    }

    return AIPortfolioSnapshot(
      totalNetWorth: netWorth,
      totalInvested: invested,
      assets: filteredAssets,
      cashFlows: filteredCashFlows,
      currencySymbol: original.currencySymbol,
      isINR: original.isINR,
      fireMetrics: filteredFire,
    );
  }

  AIDataSharingConfig copyWith({
    bool? includeTotalNetWorth,
    bool? includeAssetAllocation,
    bool? includeCashFlows,
    bool? includeFireMetrics,
    Set<AIAssetCategory>? includedCategories,
    Set<String>? excludedSubcategories,
    Set<String>? excludedAssetIds,
    Set<String>? includedFireMetrics,
    Set<String>? includedCashFlowItems,
    Set<String>? includedSummaryItems,
    double? selectedFireTarget,
    ContextPrivacyMode? privacyMode,
    bool? anonymizeValues,
    bool? rememberForFutureSessions,
  }) {
    return AIDataSharingConfig(
      includeTotalNetWorth: includeTotalNetWorth ?? this.includeTotalNetWorth,
      includeAssetAllocation: includeAssetAllocation ?? this.includeAssetAllocation,
      includeCashFlows: includeCashFlows ?? this.includeCashFlows,
      includeFireMetrics: includeFireMetrics ?? this.includeFireMetrics,
      includedCategories: includedCategories ?? this.includedCategories,
      excludedSubcategories: excludedSubcategories ?? this.excludedSubcategories,
      excludedAssetIds: excludedAssetIds ?? this.excludedAssetIds,
      includedFireMetrics: includedFireMetrics ?? this.includedFireMetrics,
      includedCashFlowItems: includedCashFlowItems ?? this.includedCashFlowItems,
      includedSummaryItems: includedSummaryItems ?? this.includedSummaryItems,
      selectedFireTarget: selectedFireTarget ?? this.selectedFireTarget,
      privacyMode: privacyMode ?? this.privacyMode,
      anonymizeValues: anonymizeValues ?? this.anonymizeValues,
      rememberForFutureSessions: rememberForFutureSessions ?? this.rememberForFutureSessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeTotalNetWorth': includeTotalNetWorth,
      'includeAssetAllocation': includeAssetAllocation,
      'includeCashFlows': includeCashFlows,
      'includeFireMetrics': includeFireMetrics,
      'includedCategories': includedCategories.map((c) => c.name).toList(),
      'excludedSubcategories': excludedSubcategories.toList(),
      'excludedAssetIds': excludedAssetIds.toList(),
      'includedFireMetrics': includedFireMetrics.toList(),
      'includedCashFlowItems': includedCashFlowItems.toList(),
      'includedSummaryItems': includedSummaryItems.toList(),
      'selectedFireTarget': selectedFireTarget,
      'privacyMode': privacyMode.name,
      'anonymizeValues': anonymizeValues,
      'rememberForFutureSessions': rememberForFutureSessions,
    };
  }

  factory AIDataSharingConfig.fromJson(Map<String, dynamic> json) {
    return AIDataSharingConfig(
      includeTotalNetWorth: json['includeTotalNetWorth'] as bool? ?? true,
      includeAssetAllocation: json['includeAssetAllocation'] as bool? ?? true,
      includeCashFlows: json['includeCashFlows'] as bool? ?? true,
      includeFireMetrics: json['includeFireMetrics'] as bool? ?? true,
      includedCategories: (json['includedCategories'] as List<dynamic>?)
              ?.map((c) => AIAssetCategory.values.firstWhere(
                    (cat) => cat.name == c,
                    orElse: () => AIAssetCategory.other,
                  ))
              .toSet() ??
          const {
            AIAssetCategory.equities,
            AIAssetCategory.mutualFunds,
            AIAssetCategory.debtAndFixedIncome,
            AIAssetCategory.goldAndCommodities,
            AIAssetCategory.realEstate,
            AIAssetCategory.crypto,
            AIAssetCategory.cashAndLiquid,
            AIAssetCategory.other,
          },
      excludedSubcategories: (json['excludedSubcategories'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toSet() ??
          const {},
      excludedAssetIds: (json['excludedAssetIds'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toSet() ??
          const {},
      includedFireMetrics: (json['includedFireMetrics'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toSet() ??
          const {
            'targetCorpus',
            'expenses',
            'swr',
            'timeline',
            'milestones',
          },
      includedCashFlowItems: (json['includedCashFlowItems'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toSet() ??
          const {
            'inflow',
            'sips',
            'expenses',
            'fcf',
          },
      includedSummaryItems: (json['includedSummaryItems'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toSet() ??
          const {
            'netWorth',
            'allocation',
            'assumptions',
          },
      selectedFireTarget: (json['selectedFireTarget'] as num?)?.toDouble(),
      privacyMode: ContextPrivacyMode.values.firstWhere(
        (m) => m.name == json['privacyMode'],
        orElse: () => ContextPrivacyMode.fullPortfolio,
      ),
      anonymizeValues: json['anonymizeValues'] as bool? ?? false,
      rememberForFutureSessions: json['rememberForFutureSessions'] as bool? ?? false,
    );
  }
}
