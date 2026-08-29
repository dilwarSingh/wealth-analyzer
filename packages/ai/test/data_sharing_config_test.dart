import 'package:ai/ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AIDataSharingConfig Tests', () {
    test('Serializes and deserializes cleanly with all granular properties', () {
      final config = AIDataSharingConfig(
        includeTotalNetWorth: true,
        includeAssetAllocation: false,
        includeCashFlows: true,
        includeFireMetrics: false,
        includedCategories: const {AIAssetCategory.equities, AIAssetCategory.debtAndFixedIncome},
        excludedSubcategories: const {'Small Cap'},
        excludedAssetIds: const {'asset_xyz'},
        includedFireMetrics: const {'targetCorpus', 'swr'},
        includedCashFlowItems: const {'sips'},
        includedSummaryItems: const {'netWorth'},
        privacyMode: ContextPrivacyMode.fullPortfolio,
        anonymizeValues: true,
        rememberForFutureSessions: true,
      );

      final json = config.toJson();
      final restored = AIDataSharingConfig.fromJson(json);

      expect(restored.includeTotalNetWorth, true);
      expect(restored.includeAssetAllocation, false);
      expect(restored.includeCashFlows, true);
      expect(restored.includeFireMetrics, false);
      expect(restored.includedCategories.contains(AIAssetCategory.equities), true);
      expect(restored.includedCategories.contains(AIAssetCategory.goldAndCommodities), false);
      expect(restored.excludedSubcategories.contains('Small Cap'), true);
      expect(restored.excludedAssetIds.contains('asset_xyz'), true);
      expect(restored.includedFireMetrics.contains('targetCorpus'), true);
      expect(restored.includedFireMetrics.contains('milestones'), false);
      expect(restored.includedCashFlowItems.contains('sips'), true);
      expect(restored.includedSummaryItems.contains('netWorth'), true);
      expect(restored.anonymizeValues, true);
      expect(restored.rememberForFutureSessions, true);
    });

    test('filterSnapshot correctly filters categories, excluded subcategories, and excludedAssetIds', () {
      final snapshot = AIPortfolioSnapshot(
        totalNetWorth: 2000000.0,
        totalInvested: 1500000.0,
        currencySymbol: '₹',
        isINR: true,
        assets: const [
          AIAssetEntry(
            id: '1',
            name: 'Nifty 50 Index',
            category: AIAssetCategory.equities,
            subCategory: 'Large Cap',
            currentValue: 800000.0,
          ),
          AIAssetEntry(
            id: '2',
            name: 'Small Cap Discovery',
            category: AIAssetCategory.equities,
            subCategory: 'Small Cap',
            currentValue: 400000.0,
          ),
          AIAssetEntry(
            id: '3',
            name: 'Bluechip Stock',
            category: AIAssetCategory.equities,
            subCategory: 'Large Cap',
            currentValue: 300000.0,
          ),
          AIAssetEntry(
            id: '4',
            name: 'Physical Gold',
            category: AIAssetCategory.goldAndCommodities,
            currentValue: 500000.0,
          ),
        ],
        cashFlows: const [
          AICashFlowNode(id: 'cf_1', name: 'Active Monthly SIPs', amount: 50000, frequency: 'monthly', isIncome: false),
          AICashFlowNode(id: 'cf_2', name: 'Monthly Living Outflows', amount: 30000, frequency: 'monthly', isIncome: false),
        ],
        fireMetrics: const AIFireMetrics(
          fireNumber: 25000000.0,
          annualExpenses: 1000000.0,
          monthlyExpenses: 83333.0,
          swrPercent: 4.0,
          fireMultiplier: 25.0,
          leanFireNumber: 18750000.0,
          preFireMilestonesCount: 2,
        ),
      );

      // Exclude Gold category, 'Small Cap' subcategory, and specific Bluechip Stock ID '3', and exclude Milestones from FIRE
      final config = AIDataSharingConfig(
        includedCategories: const {AIAssetCategory.equities},
        excludedSubcategories: const {'Small Cap'},
        excludedAssetIds: const {'3'},
        includedFireMetrics: const {'targetCorpus', 'expenses', 'swr'}, // Exclude flavors and milestones
        includedCashFlowItems: const {'sips'}, // Exclude general expenses
      );

      final filtered = config.filterSnapshot(snapshot);

      // Assets check
      expect(filtered.assets.length, 1);
      expect(filtered.assets.first.name, 'Nifty 50 Index');
      expect(filtered.totalNetWorth, 800000.0);

      // Cash Flows check
      expect(filtered.cashFlows.length, 1);
      expect(filtered.cashFlows.first.name, 'Active Monthly SIPs');

      // FIRE metrics check
      expect(filtered.fireMetrics.fireNumber, 25000000.0);
      expect(filtered.fireMetrics.preFireMilestonesCount, 0); // Excluded milestones
    });

    test('filterSnapshot applies selectedFireTarget override when provided', () {
      final snapshot = const AIPortfolioSnapshot(
        totalNetWorth: 2000000.0,
        totalInvested: 1500000.0,
        assets: [],
        currencySymbol: '₹',
        fireMetrics: AIFireMetrics(
          fireNumber: 25000000.0,
          leanFireNumber: 18750000.0,
          fatFireNumber: 33750000.0,
        ),
      );

      // User selected Lean FIRE / Custom FIRE target
      final config = const AIDataSharingConfig(
        selectedFireTarget: 18750000.0,
      );

      final filtered = config.filterSnapshot(snapshot);
      expect(filtered.fireMetrics.fireNumber, 18750000.0);
    });

    test('AIContextBuilder respects AIDataSharingConfig and masks in summary mode', () {
      final snapshot = AIPortfolioSnapshot(
        totalNetWorth: 1000000.0,
        totalInvested: 800000.0,
        currencySymbol: '₹',
        isINR: true,
        assets: const [
          AIAssetEntry(
            id: '1',
            name: 'Public Stock',
            category: AIAssetCategory.equities,
            currentValue: 600000.0,
          ),
          AIAssetEntry(
            id: '2',
            name: 'Secret Crypto',
            category: AIAssetCategory.crypto,
            currentValue: 400000.0,
          ),
        ],
      );

      final config = AIDataSharingConfig(
        includedCategories: const {AIAssetCategory.equities},
        privacyMode: ContextPrivacyMode.summaryOnly,
      );

      final prompt = AIContextBuilder.buildSystemPrompt(
        persona: AIPersona.defaultPersona,
        config: const AIConfig(),
        snapshot: snapshot,
        sharingConfig: config,
      );

      expect(prompt.contains('Secret Crypto'), false);
      expect(prompt.contains('Equities & Stocks Holding #1'), true); // Masked name in summaryOnly mode
    });
  });
}
