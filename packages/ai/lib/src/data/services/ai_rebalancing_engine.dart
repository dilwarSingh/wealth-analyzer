import '../../domain/contracts/ai_portfolio_contract.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/generative_ui_payload.dart';

/// Pure Dart deterministic calculation engine for goal-based portfolio drift and rebalancing
class AIRebalancingEngine {
  /// Calculate drift and produce comprehensive rebalancing payload
  static GoalRebalancePayload calculateRebalance({
    required AIPortfolioSnapshot snapshot,
    required FinancialGoal goal,
    double monthlySipInflow = 0.0,
  }) {
    final totalNetWorth = snapshot.totalNetWorth;
    if (totalNetWorth <= 0) {
      return GoalRebalancePayload(
        widgetId: 'rebal_${DateTime.now().millisecondsSinceEpoch}',
        goalName: goal.name,
        targetAmount: goal.targetAmount,
        targetYears: goal.targetYears,
        currentAllocation: {},
        targetAllocation: _targetAllocationMap(goal),
        deltas: [],
        sipRerouteAdvice: 'Add assets to your portfolio to begin goal-based rebalancing analysis.',
        taxTips: 'Maintain 6 months of living expenses in liquid debt funds before aggressive equity investing.',
      );
    }

    // 1. Current category allocations
    final currentCatValues = <AIAssetCategory, double>{};
    for (final asset in snapshot.assets) {
      currentCatValues[asset.category] = (currentCatValues[asset.category] ?? 0.0) + asset.currentValue;
    }

    final currentPercents = <String, double>{};
    for (final cat in AIAssetCategory.values) {
      final val = currentCatValues[cat] ?? 0.0;
      if (val > 0) {
        currentPercents[cat.displayName] = double.parse(((val / totalNetWorth) * 100).toStringAsFixed(1));
      }
    }

    // 2. Target allocation map
    final targetPercents = _targetAllocationMap(goal);

    // 3. Category level drift and amounts
    final deltas = <AIAssetRebalanceDelta>[];
    final categoryTargets = <AIAssetCategory, double>{
      AIAssetCategory.equities: goal.targetEquitiesPercent,
      AIAssetCategory.debtAndFixedIncome: goal.targetDebtPercent,
      AIAssetCategory.goldAndCommodities: goal.targetGoldPercent,
      AIAssetCategory.cashAndLiquid: goal.targetCashPercent,
      AIAssetCategory.crypto: goal.targetCryptoPercent,
      AIAssetCategory.realEstate: goal.targetRealEstatePercent,
    };

    final underweightCategories = <AIAssetCategory, double>{};
    final overweightCategories = <AIAssetCategory, double>{};

    for (final entry in categoryTargets.entries) {
      final cat = entry.key;
      final targetPct = entry.value;
      if (targetPct <= 0) continue;

      final currentVal = currentCatValues[cat] ?? 0.0;
      final currentPct = (currentVal / totalNetWorth) * 100;
      final driftPct = targetPct - currentPct;
      final targetVal = (targetPct / 100) * totalNetWorth;
      final deltaVal = targetVal - currentVal;

      if (driftPct.abs() > 0.5) {
        if (deltaVal > 0) {
          underweightCategories[cat] = deltaVal;
        } else {
          overweightCategories[cat] = deltaVal.abs();
        }

        final action = deltaVal > 0 ? 'buy' : 'sell';
        final rationale = deltaVal > 0
            ? 'Underweight by ${driftPct.abs().toStringAsFixed(1)}%. Add funds to reach target ${targetPct.toStringAsFixed(0)}% allocation.'
            : 'Overweight by ${driftPct.abs().toStringAsFixed(1)}%. Trim or route future SIPs away to preserve balance.';

        deltas.add(
          AIAssetRebalanceDelta(
            assetId: 'cat_${cat.name}',
            assetName: cat.displayName,
            category: cat,
            currentAllocationPercent: double.parse(currentPct.toStringAsFixed(1)),
            targetAllocationPercent: double.parse(targetPct.toStringAsFixed(1)),
            action: action,
            recommendedAmountDelta: deltaVal.abs(),
            rationale: rationale,
          ),
        );
      }
    }

    // 4. Inflow Rebalancing Strategy (SIP Re-routing to avoid Capital Gains Tax)
    String sipAdvice = '';
    if (underweightCategories.isNotEmpty) {
      final totalUnderweight = underweightCategories.values.fold(0.0, (a, b) => a + b);
      if (monthlySipInflow > 0) {
        final monthsToFix = (totalUnderweight / monthlySipInflow).ceil();
        final items = underweightCategories.entries.map((e) {
          final share = ((e.value / totalUnderweight) * monthlySipInflow).round();
          return '${e.key.displayName}: ${snapshot.currencySymbol}$share/mo';
        }).join(', ');
        sipAdvice = 'Tax-Free Inflow Rebalancing: Route your monthly SIP ($items) for the next $monthsToFix months to achieve target equilibrium without selling existing holdings or incurring capital gains tax.';
      } else {
        final items = underweightCategories.keys.map((k) => k.displayName).join(', ');
        sipAdvice = 'Direct your next fresh investments or bonus deposits into $items to close allocation gaps without triggering taxable sales.';
      }
    } else {
      sipAdvice = 'Your portfolio is perfectly aligned with your ${goal.name} target allocation! Continue your automated recurring SIPs.';
    }

    // 5. Tax & Liquidity Tips
    final taxTips = 'Tax Optimization Tip: Before selling equity holdings, verify whether gains qualify for Long-Term Capital Gains (LTCG) with preferential tax rates. Avoid attempting to liquidate locked assets like PPF or ELSS funds.';

    return GoalRebalancePayload(
      widgetId: 'rebal_${DateTime.now().millisecondsSinceEpoch}',
      goalName: goal.name,
      targetAmount: goal.targetAmount,
      targetYears: goal.targetYears,
      currentAllocation: currentPercents,
      targetAllocation: targetPercents,
      deltas: deltas,
      sipRerouteAdvice: sipAdvice,
      taxTips: taxTips,
    );
  }

  static Map<String, double> _targetAllocationMap(FinancialGoal goal) {
    final map = <String, double>{};
    if (goal.targetEquitiesPercent > 0) map['Equities & Stocks'] = goal.targetEquitiesPercent;
    if (goal.targetDebtPercent > 0) map['Debt, Bonds & Fixed Income'] = goal.targetDebtPercent;
    if (goal.targetGoldPercent > 0) map['Gold & Precious Metals'] = goal.targetGoldPercent;
    if (goal.targetCashPercent > 0) map['Cash & Emergency Funds'] = goal.targetCashPercent;
    if (goal.targetCryptoPercent > 0) map['Crypto & Digital Assets'] = goal.targetCryptoPercent;
    if (goal.targetRealEstatePercent > 0) map['Real Estate & Land'] = goal.targetRealEstatePercent;
    return map;
  }
}
