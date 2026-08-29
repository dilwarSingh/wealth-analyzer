import 'package:flutter/material.dart';

/// Asset categories supported by the AI Module
enum AIAssetCategory {
  equities,
  mutualFunds,
  crypto,
  realEstate,
  debtAndFixedIncome,
  goldAndCommodities,
  cashAndLiquid,
  other;

  String get displayName {
    switch (this) {
      case AIAssetCategory.equities:
        return 'Equities & Stocks';
      case AIAssetCategory.mutualFunds:
        return 'Mutual Funds & ETFs';
      case AIAssetCategory.crypto:
        return 'Crypto & Digital Assets';
      case AIAssetCategory.realEstate:
        return 'Real Estate & Land';
      case AIAssetCategory.debtAndFixedIncome:
        return 'Debt, Bonds & Fixed Income';
      case AIAssetCategory.goldAndCommodities:
        return 'Gold & Precious Metals';
      case AIAssetCategory.cashAndLiquid:
        return 'Cash & Emergency Funds';
      case AIAssetCategory.other:
        return 'Other Assets';
    }
  }

  static AIAssetCategory fromString(String val) {
    final lower = val.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
    if (lower.contains('equit') || lower.contains('stock')) return AIAssetCategory.equities;
    if (lower.contains('mutual') || lower.contains('etf') || lower.contains('fund')) return AIAssetCategory.mutualFunds;
    if (lower.contains('crypto') || lower.contains('btc') || lower.contains('eth')) return AIAssetCategory.crypto;
    if (lower.contains('real') || lower.contains('estate') || lower.contains('land') || lower.contains('house')) return AIAssetCategory.realEstate;
    if (lower.contains('debt') || lower.contains('bond') || lower.contains('fd') || lower.contains('fixed') || lower.contains('ppf') || lower.contains('epf')) return AIAssetCategory.debtAndFixedIncome;
    if (lower.contains('gold') || lower.contains('silver') || lower.contains('commodity') || lower.contains('metal') || lower.contains('sgb')) return AIAssetCategory.goldAndCommodities;
    if (lower.contains('cash') || lower.contains('liquid') || lower.contains('bank') || lower.contains('savings')) return AIAssetCategory.cashAndLiquid;
    return AIAssetCategory.other;
  }
}

/// Generic Asset item representation for the AI module
class AIAssetEntry {
  final String id;
  final String name;
  final AIAssetCategory category;
  final String? subCategory;
  final double currentValue;
  final double investedAmount;
  final double expectedReturnPercent;
  final bool isLiquid;
  final bool isLocked;
  final bool isSip;
  final double monthlySipAmount;
  final String? notes;

  const AIAssetEntry({
    required this.id,
    required this.name,
    required this.category,
    this.subCategory,
    required this.currentValue,
    this.investedAmount = 0.0,
    this.expectedReturnPercent = 12.0,
    this.isLiquid = true,
    this.isLocked = false,
    this.isSip = false,
    this.monthlySipAmount = 0.0,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    if (subCategory != null) 'subCategory': subCategory,
    'currentValue': currentValue,
    'investedAmount': investedAmount,
    'expectedReturnPercent': expectedReturnPercent,
    'isLiquid': isLiquid,
    'isLocked': isLocked,
    'isSip': isSip,
    'monthlySipAmount': monthlySipAmount,
    if (notes != null) 'notes': notes,
  };

  factory AIAssetEntry.fromJson(Map<String, dynamic> json) => AIAssetEntry(
    id: json['id'] as String? ?? UniqueKey().toString(),
    name: json['name'] as String? ?? 'Asset',
    category: AIAssetCategory.fromString(json['category'] as String? ?? 'other'),
    subCategory: json['subCategory'] as String?,
    currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
    investedAmount: (json['investedAmount'] as num?)?.toDouble() ?? 0.0,
    expectedReturnPercent: (json['expectedReturnPercent'] as num?)?.toDouble() ?? 12.0,
    isLiquid: json['isLiquid'] as bool? ?? true,
    isLocked: json['isLocked'] as bool? ?? false,
    isSip: json['isSip'] as bool? ?? false,
    monthlySipAmount: (json['monthlySipAmount'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes'] as String?,
  );
}

/// Generic Cash Flow Node representation
class AICashFlowNode {
  final String id;
  final String name;
  final double amount;
  final bool isIncome;
  final String frequency; // monthly, annual, etc.

  const AICashFlowNode({
    required this.id,
    required this.name,
    required this.amount,
    required this.isIncome,
    this.frequency = 'monthly',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'isIncome': isIncome,
    'frequency': frequency,
  };
}

/// Generic FIRE metrics snapshot
class AIFireMetrics {
  final double fireNumber;
  final double savingsRate;
  final double leanFireNumber;
  final double fatFireNumber;
  final double coastFireNumber;
  final double baristaFireNumber;
  final double yearsToFire;
  final double annualExpenses;
  final double monthlyExpenses;
  final double swrPercent;
  final double fireMultiplier;
  final int? targetAge;
  final int? currentAge;
  final double expectedInflation;
  final double expectedReturn;
  final int preFireMilestonesCount;

  const AIFireMetrics({
    this.fireNumber = 0.0,
    this.savingsRate = 0.0,
    this.leanFireNumber = 0.0,
    this.fatFireNumber = 0.0,
    this.coastFireNumber = 0.0,
    this.baristaFireNumber = 0.0,
    this.yearsToFire = 0.0,
    this.annualExpenses = 0.0,
    this.monthlyExpenses = 0.0,
    this.swrPercent = 4.0,
    this.fireMultiplier = 25.0,
    this.targetAge,
    this.currentAge,
    this.expectedInflation = 6.0,
    this.expectedReturn = 12.0,
    this.preFireMilestonesCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'fireNumber': fireNumber,
    'savingsRate': savingsRate,
    'leanFireNumber': leanFireNumber,
    'fatFireNumber': fatFireNumber,
    'coastFireNumber': coastFireNumber,
    'baristaFireNumber': baristaFireNumber,
    'yearsToFire': yearsToFire,
    'annualExpenses': annualExpenses,
    'monthlyExpenses': monthlyExpenses,
    'swrPercent': swrPercent,
    'fireMultiplier': fireMultiplier,
    if (targetAge != null) 'targetAge': targetAge,
    if (currentAge != null) 'currentAge': currentAge,
    'expectedInflation': expectedInflation,
    'expectedReturn': expectedReturn,
    'preFireMilestonesCount': preFireMilestonesCount,
  };

  factory AIFireMetrics.fromJson(Map<String, dynamic> json) => AIFireMetrics(
    fireNumber: (json['fireNumber'] as num?)?.toDouble() ?? 0.0,
    savingsRate: (json['savingsRate'] as num?)?.toDouble() ?? 0.0,
    leanFireNumber: (json['leanFireNumber'] as num?)?.toDouble() ?? 0.0,
    fatFireNumber: (json['fatFireNumber'] as num?)?.toDouble() ?? 0.0,
    coastFireNumber: (json['coastFireNumber'] as num?)?.toDouble() ?? 0.0,
    baristaFireNumber: (json['baristaFireNumber'] as num?)?.toDouble() ?? 0.0,
    yearsToFire: (json['yearsToFire'] as num?)?.toDouble() ?? 0.0,
    annualExpenses: (json['annualExpenses'] as num?)?.toDouble() ?? 0.0,
    monthlyExpenses: (json['monthlyExpenses'] as num?)?.toDouble() ?? 0.0,
    swrPercent: (json['swrPercent'] as num?)?.toDouble() ?? 4.0,
    fireMultiplier: (json['fireMultiplier'] as num?)?.toDouble() ?? 25.0,
    targetAge: json['targetAge'] as int?,
    currentAge: json['currentAge'] as int?,
    expectedInflation: (json['expectedInflation'] as num?)?.toDouble() ?? 6.0,
    expectedReturn: (json['expectedReturn'] as num?)?.toDouble() ?? 12.0,
    preFireMilestonesCount: json['preFireMilestonesCount'] as int? ?? 0,
  );
}

/// Complete portfolio snapshot passed into the AI module
class AIPortfolioSnapshot {
  final double totalNetWorth;
  final double totalInvested;
  final List<AIAssetEntry> assets;
  final List<AICashFlowNode> cashFlows;
  final AIFireMetrics fireMetrics;
  final String currencySymbol;
  final bool isINR;
  final bool isAnonymized;

  const AIPortfolioSnapshot({
    required this.totalNetWorth,
    required this.totalInvested,
    required this.assets,
    this.cashFlows = const [],
    this.fireMetrics = const AIFireMetrics(),
    this.currencySymbol = '₹',
    this.isINR = true,
    this.isAnonymized = false,
  });

  Map<AIAssetCategory, double> get categoryBreakdown {
    final map = <AIAssetCategory, double>{};
    for (final asset in assets) {
      map[asset.category] = (map[asset.category] ?? 0.0) + asset.currentValue;
    }
    return map;
  }

  Map<AIAssetCategory, double> get categoryPercentages {
    if (totalNetWorth <= 0) return {};
    final breakdown = categoryBreakdown;
    return breakdown.map((k, v) => MapEntry(k, (v / totalNetWorth) * 100));
  }
}

/// Rebalance action delta representation
class AIAssetRebalanceDelta {
  final String assetId;
  final String assetName;
  final AIAssetCategory category;
  final double currentAllocationPercent;
  final double targetAllocationPercent;
  final String action; // 'buy', 'sell', 'hold', 'sipRoute'
  final double recommendedAmountDelta;
  final String rationale;

  const AIAssetRebalanceDelta({
    required this.assetId,
    required this.assetName,
    required this.category,
    required this.currentAllocationPercent,
    required this.targetAllocationPercent,
    required this.action,
    required this.recommendedAmountDelta,
    required this.rationale,
  });

  Map<String, dynamic> toJson() => {
    'assetId': assetId,
    'assetName': assetName,
    'category': category.name,
    'currentAllocationPercent': currentAllocationPercent,
    'targetAllocationPercent': targetAllocationPercent,
    'action': action,
    'recommendedAmountDelta': recommendedAmountDelta,
    'rationale': rationale,
  };

  factory AIAssetRebalanceDelta.fromJson(Map<String, dynamic> json) => AIAssetRebalanceDelta(
    assetId: json['assetId'] as String? ?? '',
    assetName: json['assetName'] as String? ?? 'Asset',
    category: AIAssetCategory.fromString(json['category'] as String? ?? 'other'),
    currentAllocationPercent: (json['currentAllocationPercent'] as num?)?.toDouble() ?? 0.0,
    targetAllocationPercent: (json['targetAllocationPercent'] as num?)?.toDouble() ?? 0.0,
    action: json['action'] as String? ?? 'hold',
    recommendedAmountDelta: (json['recommendedAmountDelta'] as num?)?.toDouble() ?? 0.0,
    rationale: json['rationale'] as String? ?? '',
  );
}

/// Delegate interface for host app to receive AI-suggested mutations
abstract class AIPortfolioActionDelegate {
  Future<bool> onAddAsset(AIAssetEntry asset);
  Future<bool> onRebalance(List<AIAssetRebalanceDelta> deltas);
  Future<bool> onBatchImport(List<AIAssetEntry> assets);
}

/// Delegate interface for host app to execute exact native math use cases
abstract class AIMathEngineDelegate {
  Future<Map<String, dynamic>> runMonteCarlo({
    required double currentPortfolio,
    required double annualSavings,
    required double expectedReturn,
    required double volatility,
    required int years,
    required int simulations,
  });

  Future<Map<String, dynamic>> runStressTest({
    required double totalEquity,
    required double totalDebt,
    required double totalGold,
    required double totalCrypto,
  });

  Future<Map<String, dynamic>> calculateFire({
    required double annualExpenses,
    required double currentNetWorth,
    required double annualSavings,
    required double expectedReturn,
    required double inflationRate,
    required double safeWithdrawalRate,
  });

  Future<Map<String, dynamic>> calculateSwp({
    required double corpus,
    required double initialMonthlyWithdrawal,
    required double inflationRate,
    required double expectedReturn,
    required int years,
  });
}

/// Delegate interface for currency formatting
abstract class AICurrencyDelegate {
  String formatAmount(double amount);
  String compactAmount(double amount);
  String get symbol;
  bool get isINR;
}

/// Design tokens for glassmorphism styling injected by the host app
class AIThemeData {
  final Color surfaceColor;
  final Color surfaceLightColor;
  final Color primaryAccentColor; // e.g. Crimson #E63946
  final Color secondaryAccentColor; // e.g. Gold #FFD166
  final Color canvasColor;
  final Color borderColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color textMutedColor;
  final Color successColor;
  final Color warningColor;
  final double borderRadius;
  final double glassBlur;

  const AIThemeData({
    this.surfaceColor = const Color(0xFF141923),
    this.surfaceLightColor = const Color(0xFF1E2638),
    this.primaryAccentColor = const Color(0xFFE63946),
    this.secondaryAccentColor = const Color(0xFFFFD166),
    this.canvasColor = const Color(0xFF0B0E14),
    this.borderColor = const Color(0x33FFFFFF),
    this.textPrimaryColor = const Color(0xFFFFFFFF),
    this.textSecondaryColor = const Color(0xFF94A3B8),
    this.textMutedColor = const Color(0xFF64748B),
    this.successColor = const Color(0xFF06D6A0),
    this.warningColor = const Color(0xFFFFB703),
    this.borderRadius = 14.0,
    this.glassBlur = 10.0,
  });
}
