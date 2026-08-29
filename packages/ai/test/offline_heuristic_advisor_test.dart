import 'package:ai/ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfflineHeuristicAdvisor Tests', () {
    test('Generates complete audit with all expected generative widgets for populated portfolio', () {
      final snapshot = AIPortfolioSnapshot(
        totalNetWorth: 2500000.0,
        totalInvested: 2000000.0,
        currencySymbol: '₹',
        isINR: true,
        assets: const [
          AIAssetEntry(
            id: '1',
            name: 'Flexicap Mutual Fund',
            category: AIAssetCategory.mutualFunds,
            currentValue: 1500000.0,
          ),
          AIAssetEntry(
            id: '2',
            name: 'Fixed Deposit',
            category: AIAssetCategory.debtAndFixedIncome,
            currentValue: 600000.0,
          ),
          AIAssetEntry(
            id: '3',
            name: 'Emergency Savings Account',
            category: AIAssetCategory.cashAndLiquid,
            currentValue: 400000.0,
          ),
        ],
      );

      final msg = OfflineHeuristicAdvisor.generateInstantAudit(
        sessionId: 'session_test',
        snapshot: snapshot,
      );

      expect(msg.role, MessageRole.assistant);
      expect(msg.generativeWidgets.isNotEmpty, true);

      // Verify widget types included in audit
      final types = msg.generativeWidgets.map((w) => w.type).toSet();
      expect(types.contains(GenerativeWidgetType.kpiMetric), true);
      expect(types.contains(GenerativeWidgetType.allocationChart), true);
      expect(types.contains(GenerativeWidgetType.goalRebalance), true);
      expect(types.contains(GenerativeWidgetType.stressTestResult), true);
      expect(types.contains(GenerativeWidgetType.monteCarloCurve), true);
      expect(types.contains(GenerativeWidgetType.auditReport), true);
    });
  });

  group('AIContextBuilder Tests', () {
    test('Respects promptOnly privacy mode', () {
      const config = AIConfig(privacyMode: ContextPrivacyMode.promptOnly);
      const persona = AIPersona(
        id: 'p1',
        name: 'Test',
        tagline: '',
        description: '',
        systemPrompt: 'You are an advisor.',
        icon: '💼',
      );
      final snapshot = AIPortfolioSnapshot(
        totalNetWorth: 1000000,
        totalInvested: 800000,
        assets: const [
          AIAssetEntry(id: '1', name: 'Secret Stock', category: AIAssetCategory.equities, currentValue: 1000000),
        ],
      );

      final prompt = AIContextBuilder.buildSystemPrompt(
        persona: persona,
        config: config,
        snapshot: snapshot,
      );

      expect(prompt.contains('Secret Stock'), false);
      expect(prompt.contains('[Privacy Mode Active - No financial data is shared in this prompt]'), true);
    });

    test('Anonymizes values when anonymizeValues is true', () {
      const config = AIConfig(
        privacyMode: ContextPrivacyMode.fullPortfolio,
        anonymizeValues: true,
      );
      final snapshot = AIPortfolioSnapshot(
        totalNetWorth: 10000000,
        totalInvested: 8000000,
        assets: const [
          AIAssetEntry(id: '1', name: 'Secret Asset', category: AIAssetCategory.equities, currentValue: 10000000),
        ],
      );

      final prompt = AIContextBuilder.buildSystemPrompt(
        persona: AIPersona.defaultPersona,
        config: config,
        snapshot: snapshot,
      );

      expect(prompt.contains('Secret Asset [Equities & Stocks]: 100.0%'), true);
      expect(prompt.contains('Anonymized Baseline: 100,000 Units'), true);
    });
  });
}
