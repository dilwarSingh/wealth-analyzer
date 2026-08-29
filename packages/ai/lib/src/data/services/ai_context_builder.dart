import 'dart:convert';
import '../../domain/contracts/ai_portfolio_contract.dart';
import '../../domain/entities/ai_config.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/data_sharing_config.dart';
import '../../domain/tools/ai_financial_tools.dart';

/// Context Builder for serializing portfolio data, persona guidelines, and privacy filtering into LLM prompts
class AIContextBuilder {
  /// Build full system prompt including persona instructions, currency conventions, and filtered portfolio context
  static String buildSystemPrompt({
    required AIPersona persona,
    required AIConfig config,
    required AIPortfolioSnapshot snapshot,
    AIDataSharingConfig? sharingConfig,
    AICurrencyDelegate? currencyDelegate,
  }) {
    final effectiveSnapshot = sharingConfig != null
        ? sharingConfig.filterSnapshot(snapshot)
        : snapshot;

    final currencySymbol = effectiveSnapshot.currencySymbol;
    final isINR = effectiveSnapshot.isINR;

    final currencyInstruction = isINR
        ? 'CURRENCY NOTATION: The user is in India (INR / ₹). Express large monetary values using standard Indian notation (e.g. ₹1 Lakh = 100,000, ₹1 Crore = 10,000,000, e.g. ₹1.25 Cr, ₹50 L, ₹25,000) rather than Millions/Billions.'
        : 'CURRENCY NOTATION: Express monetary values using standard USD international notation (e.g. \$1.25M, \$250K, \$15,000).';

    final portfolioContext = _serializePortfolioContext(
      effectiveSnapshot,
      config,
      sharingConfig,
      currencyDelegate,
    );

    final thinkingGuidance = '''
THINKING & REASONING GUIDANCE:
- You must always think step-by-step before answering or executing tools.
- When thinking, formulate clear mathematical, risk-adjusted, and strategic deductions.
- If your model supports outputting thinking blocks, wrap your internal reasoning in `<think>...</think>` tags before providing the final user response.
''';

    final toolGuidance = '''
TOOL USE INSTRUCTIONS:
- You have access to mathematical and Generative UI tools:
  * ${AIFinancialToolDefinitions.toolRunMonteCarlo}: for stochastic probability curves and goal success rates.
  * ${AIFinancialToolDefinitions.toolRunStressTest}: for market crash drawdowns (2008 GFC, Covid, Stagflation).
  * ${AIFinancialToolDefinitions.toolCalculateFire}: for exact FIRE numbers, savings rate, and retirement timelines.
  * ${AIFinancialToolDefinitions.toolCalculateSwp}: for retirement Systematic Withdrawal Plan longevity.
  * ${AIFinancialToolDefinitions.toolRecommendGoalRebalance}: for goal drift analysis, rebalancing deltas, and tax-efficient SIP inflow routing.
  * ${AIFinancialToolDefinitions.toolProposeAddAsset}: when the user mentions purchasing or wanting to add an asset/investment.
  * ${AIFinancialToolDefinitions.toolProposeBatchImport}: when parsing multiple assets from a pasted statement, CSV, or screenshot.
  * ${AIFinancialToolDefinitions.toolRenderKpiCard}, ${AIFinancialToolDefinitions.toolRenderAllocationChart}, ${AIFinancialToolDefinitions.toolRenderScenarioSimulator}: for rendering interactive glassmorphic chart widgets in response.
  * ${AIFinancialToolDefinitions.toolGenerateAuditReport}: for comprehensive multi-section wealth health reviews.

- ALWAYS call these tools when relevant rather than hallucinating estimates or outputting unformatted walls of numbers.
- If the model environment does not execute tools natively, you may output tool calls formatted as a valid markdown JSON block: ```json\n{"tool": "tool_name", "parameters": {...}}\n```.
''';

    return '''${persona.systemPrompt}

$currencyInstruction

$thinkingGuidance

$toolGuidance

$portfolioContext
''';
  }

  /// Serializes portfolio data based on Privacy Mode and Anonymization settings
  static String _serializePortfolioContext(
    AIPortfolioSnapshot snapshot,
    AIConfig config,
    AIDataSharingConfig? sharingConfig,
    AICurrencyDelegate? currencyDelegate,
  ) {
    final effectivePrivacyMode = sharingConfig?.privacyMode ?? config.privacyMode;
    final isAnonymized = sharingConfig?.anonymizeValues ?? config.anonymizeValues;
    final includeNetWorth = (sharingConfig?.includeTotalNetWorth ?? true) &&
        (sharingConfig?.includedSummaryItems.contains('netWorth') ?? true);
    final includeAllocation = (sharingConfig?.includeAssetAllocation ?? true) &&
        (sharingConfig?.includedSummaryItems.contains('allocation') ?? true);
    final includeAssumptions = sharingConfig?.includedSummaryItems.contains('assumptions') ?? true;
    final includeCashFlows = sharingConfig?.includeCashFlows ?? true;
    final includeFire = sharingConfig?.includeFireMetrics ?? true;

    if (effectivePrivacyMode == ContextPrivacyMode.promptOnly) {
      return 'PORTFOLIO CONTEXT: [Privacy Mode Active - No financial data is shared in this prompt].';
    }

    final totalNetWorth = snapshot.totalNetWorth;
    final totalInvested = snapshot.totalInvested;
    final symbol = snapshot.currencySymbol;

    final format = currencyDelegate != null
        ? currencyDelegate.formatAmount
        : (double v) => '$symbol${v.toStringAsFixed(0)}';

    if (totalNetWorth <= 0 && snapshot.assets.isEmpty && !includeFire) {
      return 'PORTFOLIO CONTEXT: [Portfolio has no assets recorded or all financial data filtered by user].';
    }

    final buffer = StringBuffer();
    buffer.writeln('CURRENT PORTFOLIO STATE:');

    // 1. High-level Net Worth & Capital
    if (includeNetWorth) {
      if (isAnonymized) {
        buffer.writeln('- Net Worth: [Anonymized Baseline: 100,000 Units (Scaled 100%)]');
      } else {
        buffer.writeln('- Total Net Worth: ${format(totalNetWorth)}');
        buffer.writeln('- Total Invested Capital: ${format(totalInvested)}');
      }
    }

    // 2. Portfolio Assumptions
    if (includeAssumptions) {
      final infl = snapshot.fireMetrics.expectedInflation;
      final ret = snapshot.fireMetrics.expectedReturn;
      buffer.writeln('- Planning Assumptions: Expected Return: ${ret.toStringAsFixed(1)}% CAGR, Inflation: ${infl.toStringAsFixed(1)}%');
    }

    // 3. Category Breakdown
    if (includeAllocation && snapshot.categoryBreakdown.isNotEmpty) {
      buffer.writeln('- Asset Allocation Breakdown:');
      final catBreakdown = snapshot.categoryBreakdown;
      for (final entry in catBreakdown.entries) {
        final pct = totalNetWorth > 0 ? (entry.value / totalNetWorth) * 100 : 0.0;
        final valStr = isAnonymized ? '${pct.toStringAsFixed(1)}%' : format(entry.value);
        buffer.writeln('  * ${entry.key.displayName}: $valStr (${pct.toStringAsFixed(1)}%)');
      }
    }

    // 4. Holdings & Assets
    if (snapshot.assets.isNotEmpty) {
      buffer.writeln('- Asset Holdings:');
      var holdingIdx = 1;
      for (final a in snapshot.assets) {
        final pct = totalNetWorth > 0 ? (a.currentValue / totalNetWorth) * 100 : 0.0;
        final valStr = isAnonymized ? '${pct.toStringAsFixed(1)}%' : format(a.currentValue);
        final sipStr = a.isSip
            ? (isAnonymized ? ', SIP Active' : ', Monthly SIP: ${format(a.monthlySipAmount)}')
            : '';
        final subCatStr = a.subCategory != null && a.subCategory!.isNotEmpty
            ? ' (${a.subCategory})'
            : (a.notes != null && a.notes!.isNotEmpty ? ' (${a.notes})' : '');

        // Mask asset name in summaryOnly mode
        final displayName = effectivePrivacyMode == ContextPrivacyMode.summaryOnly
            ? '${a.category.displayName} Holding #$holdingIdx'
            : a.name;

        buffer.writeln('  * $displayName$subCatStr [${a.category.displayName}]: $valStr (Weight: ${pct.toStringAsFixed(1)}%$sipStr, CAGR: ${a.expectedReturnPercent}%, Liquid: ${a.isLiquid})');
        holdingIdx++;
      }
    }

    // 5. Cash Flows
    if (includeCashFlows && snapshot.cashFlows.isNotEmpty) {
      buffer.writeln('- Cash Flows & Recurring Commitments:');
      for (final cf in snapshot.cashFlows) {
        final type = cf.isIncome ? 'Income' : 'Expense';
        final valStr = isAnonymized ? '[Normalized Ratio]' : format(cf.amount);
        buffer.writeln('  * ${cf.name} ($type): $valStr / ${cf.frequency}');
      }
    }

    // 6. FIRE Status & Metrics
    if (includeFire) {
      final fire = snapshot.fireMetrics;
      final fireItems = sharingConfig?.includedFireMetrics ??
          const {'targetCorpus', 'expenses', 'swr', 'timeline', 'milestones'};

      buffer.writeln('- FIRE (Financial Independence) Metrics:');
      if (fireItems.contains('targetCorpus') && fire.fireNumber > 0) {
        final targetStr = isAnonymized ? '${fire.fireMultiplier.toStringAsFixed(1)}x Annual Expenses' : format(fire.fireNumber);
        buffer.writeln('  * Target FIRE Corpus: $targetStr');
      }
      if (fireItems.contains('expenses') && (fire.monthlyExpenses > 0 || fire.annualExpenses > 0)) {
        final expStr = isAnonymized
            ? (totalNetWorth > 0 ? '${((fire.annualExpenses / totalNetWorth) * 100).toStringAsFixed(1)}% of Net Worth/yr' : 'Standard Living Expenses')
            : '${format(fire.monthlyExpenses)}/mo (${format(fire.annualExpenses)}/yr)';
        buffer.writeln('  * Living Expenses: $expStr');
      }
      if (fireItems.contains('swr')) {
        buffer.writeln('  * Safe Withdrawal Rate (SWR): ${fire.swrPercent.toStringAsFixed(1)}% (Multiplier: ${fire.fireMultiplier.toStringAsFixed(1)}x)');
      }
      if (fireItems.contains('timeline')) {
        if (fire.savingsRate > 0) buffer.writeln('  * Current Savings Rate: ${fire.savingsRate.toStringAsFixed(1)}%');
        if (fire.yearsToFire > 0) buffer.writeln('  * Projected Timeline to Independence: ${fire.yearsToFire.toStringAsFixed(1)} years');
      }
      if (fireItems.contains('milestones') && fire.preFireMilestonesCount > 0) {
        buffer.writeln('  * Pre-FIRE Major Outflow Milestones: ${fire.preFireMilestonesCount} scheduled events');
      }
    }

    return buffer.toString();
  }

  /// Compacts and windows chat history for LLM message lists
  static List<Map<String, dynamic>> compactMessagesForLLM(List<ChatMessage> messages, {int maxRecentMessages = 10}) {
    final recent = messages.length > maxRecentMessages
        ? messages.sublist(messages.length - maxRecentMessages)
        : messages;

    return recent.map((m) {
      final role = m.role == MessageRole.user ? 'user' : 'assistant';
      return {
        'role': role,
        'content': m.content,
      };
    }).toList();
  }
}
