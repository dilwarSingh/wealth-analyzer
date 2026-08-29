import 'package:ai/ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AIRebalancingEngine Tests', () {
    test('Calculates drift correctly and recommends inflow rebalancing', () {
      final snapshot = AIPortfolioSnapshot(
        totalNetWorth: 1000000.0,
        totalInvested: 800000.0,
        currencySymbol: '₹',
        isINR: true,
        assets: const [
          AIAssetEntry(
            id: '1',
            name: 'Nifty 50 Index',
            category: AIAssetCategory.equities,
            currentValue: 800000.0,
          ),
          AIAssetEntry(
            id: '2',
            name: 'Corporate Bond Fund',
            category: AIAssetCategory.debtAndFixedIncome,
            currentValue: 100000.0,
          ),
          AIAssetEntry(
            id: '3',
            name: 'Physical Gold',
            category: AIAssetCategory.goldAndCommodities,
            currentValue: 100000.0,
          ),
        ],
      );

      final goal = FinancialGoal(
        id: 'fire_test',
        name: 'FIRE Goal',
        targetAmount: 50000000.0,
        targetYears: 15,
        targetEquitiesPercent: 60.0,
        targetDebtPercent: 30.0,
        targetGoldPercent: 10.0,
      );

      final result = AIRebalancingEngine.calculateRebalance(
        snapshot: snapshot,
        goal: goal,
        monthlySipInflow: 50000.0,
      );

      expect(result.goalName, 'FIRE Goal');
      expect(result.deltas.isNotEmpty, true);

      // Equity is 80%, target is 60% -> Overweight
      final equityDelta = result.deltas.firstWhere((d) => d.category == AIAssetCategory.equities);
      expect(equityDelta.action, 'sell');
      expect(equityDelta.currentAllocationPercent, 80.0);
      expect(equityDelta.targetAllocationPercent, 60.0);

      // Debt is 10%, target is 30% -> Underweight
      final debtDelta = result.deltas.firstWhere((d) => d.category == AIAssetCategory.debtAndFixedIncome);
      expect(debtDelta.action, 'buy');
      expect(debtDelta.currentAllocationPercent, 10.0);
      expect(debtDelta.targetAllocationPercent, 30.0);

      // Inflow advice should mention debt fund routing
      expect(result.sipRerouteAdvice.contains('Tax-Free Inflow Rebalancing'), true);
    });
  });
}
