import '../contracts/ai_portfolio_contract.dart';

enum GenerativeWidgetType {
  kpiMetric,
  allocationChart,
  goalRebalance,
  projectionChart,
  swpCashFlow,
  monteCarloCurve,
  stressTestResult,
  actionConfirmation,
  batchAssetImport,
  scenarioSimulator,
  auditReport;

  static GenerativeWidgetType fromString(String val) {
    final lower = val.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
    for (final type in GenerativeWidgetType.values) {
      if (type.name.toLowerCase() == lower) return type;
    }
    if (lower.contains('kpi') || lower.contains('metric')) return GenerativeWidgetType.kpiMetric;
    if (lower.contains('alloc') || lower.contains('donut')) return GenerativeWidgetType.allocationChart;
    if (lower.contains('rebal') || lower.contains('goal')) return GenerativeWidgetType.goalRebalance;
    if (lower.contains('monte') || lower.contains('carlo')) return GenerativeWidgetType.monteCarloCurve;
    if (lower.contains('stress') || lower.contains('crash')) return GenerativeWidgetType.stressTestResult;
    if (lower.contains('action') || lower.contains('confirm')) return GenerativeWidgetType.actionConfirmation;
    if (lower.contains('batch') || lower.contains('import')) return GenerativeWidgetType.batchAssetImport;
    if (lower.contains('simulat') || lower.contains('slider')) return GenerativeWidgetType.scenarioSimulator;
    if (lower.contains('audit') || lower.contains('report')) return GenerativeWidgetType.auditReport;
    if (lower.contains('swp') || lower.contains('withdraw')) return GenerativeWidgetType.swpCashFlow;
    return GenerativeWidgetType.projectionChart;
  }
}

/// Abstract base for all structured Generative UI widgets
abstract class GenerativeUIPayload {
  final GenerativeWidgetType type;
  final String widgetId;

  const GenerativeUIPayload({required this.type, required this.widgetId});

  Map<String, dynamic> toJson();

  static GenerativeUIPayload fromJson(Map<String, dynamic> json) {
    final type = GenerativeWidgetType.fromString(json['type'] as String? ?? '');
    switch (type) {
      case GenerativeWidgetType.kpiMetric:
        return KpiMetricPayload.fromJson(json);
      case GenerativeWidgetType.allocationChart:
        return AllocationChartPayload.fromJson(json);
      case GenerativeWidgetType.goalRebalance:
        return GoalRebalancePayload.fromJson(json);
      case GenerativeWidgetType.projectionChart:
        return ProjectionChartPayload.fromJson(json);
      case GenerativeWidgetType.swpCashFlow:
        return SwpCashFlowPayload.fromJson(json);
      case GenerativeWidgetType.monteCarloCurve:
        return MonteCarloCurvePayload.fromJson(json);
      case GenerativeWidgetType.stressTestResult:
        return StressTestResultPayload.fromJson(json);
      case GenerativeWidgetType.actionConfirmation:
        return ActionConfirmationPayload.fromJson(json);
      case GenerativeWidgetType.batchAssetImport:
        return BatchAssetImportPayload.fromJson(json);
      case GenerativeWidgetType.scenarioSimulator:
        return ScenarioSimulatorPayload.fromJson(json);
      case GenerativeWidgetType.auditReport:
        return AuditReportPayload.fromJson(json);
    }
  }
}

/// 1. KPI / Stat Metric Card
class KpiMetricPayload extends GenerativeUIPayload {
  final String title;
  final String value;
  final String? subtitle;
  final double? changePercent;
  final bool isPositive;
  final String? trendLabel;

  const KpiMetricPayload({
    required String widgetId,
    required this.title,
    required this.value,
    this.subtitle,
    this.changePercent,
    this.isPositive = true,
    this.trendLabel,
  }) : super(type: GenerativeWidgetType.kpiMetric, widgetId: widgetId);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'title': title,
    'value': value,
    'subtitle': subtitle,
    'changePercent': changePercent,
    'isPositive': isPositive,
    'trendLabel': trendLabel,
  };

  factory KpiMetricPayload.fromJson(Map<String, dynamic> json) => KpiMetricPayload(
    widgetId: json['widgetId'] as String? ?? 'kpi_1',
    title: json['title'] as String? ?? 'KPI Metric',
    value: json['value'] as String? ?? '0',
    subtitle: json['subtitle'] as String?,
    changePercent: (json['changePercent'] as num?)?.toDouble(),
    isPositive: json['isPositive'] as bool? ?? true,
    trendLabel: json['trendLabel'] as String?,
  );
}

/// 2. Donut Asset Allocation Chart
class AllocationSliceData {
  final String category;
  final double percentage;
  final double amount;

  const AllocationSliceData({
    required this.category,
    required this.percentage,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'percentage': percentage,
    'amount': amount,
  };

  factory AllocationSliceData.fromJson(Map<String, dynamic> json) => AllocationSliceData(
    category: json['category'] as String? ?? 'Other',
    percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
  );
}

class AllocationChartPayload extends GenerativeUIPayload {
  final List<AllocationSliceData> slices;
  final double totalAmount;
  final String currencySymbol;

  const AllocationChartPayload({
    required String widgetId,
    required this.slices,
    required this.totalAmount,
    this.currencySymbol = '₹',
  }) : super(type: GenerativeWidgetType.allocationChart, widgetId: widgetId);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'slices': slices.map((s) => s.toJson()).toList(),
    'totalAmount': totalAmount,
    'currencySymbol': currencySymbol,
  };

  factory AllocationChartPayload.fromJson(Map<String, dynamic> json) => AllocationChartPayload(
    widgetId: json['widgetId'] as String? ?? 'alloc_1',
    slices: (json['slices'] as List<dynamic>? ?? [])
        .map((s) => AllocationSliceData.fromJson(s as Map<String, dynamic>))
        .toList(),
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    currencySymbol: json['currencySymbol'] as String? ?? '₹',
  );
}

/// 3. Goal Rebalance Card with Inflow / Direct Action
class GoalRebalancePayload extends GenerativeUIPayload {
  final String goalName;
  final double targetAmount;
  final int targetYears;
  final Map<String, double> currentAllocation;
  final Map<String, double> targetAllocation;
  final List<AIAssetRebalanceDelta> deltas;
  final String sipRerouteAdvice;
  final String taxTips;
  final bool isApplied;
  final String? appliedTimestamp;

  const GoalRebalancePayload({
    required String widgetId,
    required this.goalName,
    this.targetAmount = 0.0,
    this.targetYears = 10,
    required this.currentAllocation,
    required this.targetAllocation,
    required this.deltas,
    this.sipRerouteAdvice = '',
    this.taxTips = '',
    this.isApplied = false,
    this.appliedTimestamp,
  }) : super(type: GenerativeWidgetType.goalRebalance, widgetId: widgetId);

  GoalRebalancePayload copyWithApplied() => GoalRebalancePayload(
    widgetId: widgetId,
    goalName: goalName,
    targetAmount: targetAmount,
    targetYears: targetYears,
    currentAllocation: currentAllocation,
    targetAllocation: targetAllocation,
    deltas: deltas,
    sipRerouteAdvice: sipRerouteAdvice,
    taxTips: taxTips,
    isApplied: true,
    appliedTimestamp: DateTime.now().toIso8601String(),
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'goalName': goalName,
    'targetAmount': targetAmount,
    'targetYears': targetYears,
    'currentAllocation': currentAllocation,
    'targetAllocation': targetAllocation,
    'deltas': deltas.map((d) => d.toJson()).toList(),
    'sipRerouteAdvice': sipRerouteAdvice,
    'taxTips': taxTips,
    'isApplied': isApplied,
    'appliedTimestamp': appliedTimestamp,
  };

  factory GoalRebalancePayload.fromJson(Map<String, dynamic> json) => GoalRebalancePayload(
    widgetId: json['widgetId'] as String? ?? 'rebal_1',
    goalName: json['goalName'] as String? ?? 'Goal Rebalancing',
    targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
    targetYears: json['targetYears'] as int? ?? 10,
    currentAllocation: (json['currentAllocation'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
    targetAllocation: (json['targetAllocation'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
    deltas: (json['deltas'] as List<dynamic>? ?? [])
        .map((d) => AIAssetRebalanceDelta.fromJson(d as Map<String, dynamic>))
        .toList(),
    sipRerouteAdvice: json['sipRerouteAdvice'] as String? ?? '',
    taxTips: json['taxTips'] as String? ?? '',
    isApplied: json['isApplied'] as bool? ?? false,
    appliedTimestamp: json['appliedTimestamp'] as String?,
  );
}

/// 4. Wealth Trajectory Projection Chart
class ProjectionChartPayload extends GenerativeUIPayload {
  final List<int> years;
  final List<double> baselineCurve;
  final List<double>? optimisticCurve;
  final List<double>? pessimisticCurve;
  final String currencySymbol;

  const ProjectionChartPayload({
    required String widgetId,
    required this.years,
    required this.baselineCurve,
    this.optimisticCurve,
    this.pessimisticCurve,
    this.currencySymbol = '₹',
  }) : super(type: GenerativeWidgetType.projectionChart, widgetId: widgetId);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'years': years,
    'baselineCurve': baselineCurve,
    'optimisticCurve': optimisticCurve,
    'pessimisticCurve': pessimisticCurve,
    'currencySymbol': currencySymbol,
  };

  factory ProjectionChartPayload.fromJson(Map<String, dynamic> json) => ProjectionChartPayload(
    widgetId: json['widgetId'] as String? ?? 'proj_1',
    years: (json['years'] as List<dynamic>? ?? [0, 5, 10, 15, 20, 25, 30]).map((e) => (e as num).toInt()).toList(),
    baselineCurve: (json['baselineCurve'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList(),
    optimisticCurve: (json['optimisticCurve'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
    pessimisticCurve: (json['pessimisticCurve'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
    currencySymbol: json['currencySymbol'] as String? ?? '₹',
  );
}

/// 5. Monte Carlo Simulation Fan Chart
class MonteCarloCurvePayload extends GenerativeUIPayload {
  final double probabilityOfSuccess; // e.g. 94.2%
  final List<int> years;
  final List<double> p10Curve; // 10th percentile (unfavorable)
  final List<double> p50Curve; // 50th percentile (median)
  final List<double> p90Curve; // 90th percentile (favorable)
  final int simulationsCount;
  final String currencySymbol;

  const MonteCarloCurvePayload({
    required String widgetId,
    required this.probabilityOfSuccess,
    required this.years,
    required this.p10Curve,
    required this.p50Curve,
    required this.p90Curve,
    this.simulationsCount = 1000,
    this.currencySymbol = '₹',
  }) : super(type: GenerativeWidgetType.monteCarloCurve, widgetId: widgetId);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'probabilityOfSuccess': probabilityOfSuccess,
    'years': years,
    'p10Curve': p10Curve,
    'p50Curve': p50Curve,
    'p90Curve': p90Curve,
    'simulationsCount': simulationsCount,
    'currencySymbol': currencySymbol,
  };

  factory MonteCarloCurvePayload.fromJson(Map<String, dynamic> json) => MonteCarloCurvePayload(
    widgetId: json['widgetId'] as String? ?? 'monte_1',
    probabilityOfSuccess: (json['probabilityOfSuccess'] as num?)?.toDouble() ?? 85.0,
    years: (json['years'] as List<dynamic>? ?? [0, 5, 10, 15, 20, 25, 30]).map((e) => (e as num).toInt()).toList(),
    p10Curve: (json['p10Curve'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList(),
    p50Curve: (json['p50Curve'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList(),
    p90Curve: (json['p90Curve'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList(),
    simulationsCount: json['simulationsCount'] as int? ?? 1000,
    currencySymbol: json['currencySymbol'] as String? ?? '₹',
  );
}

/// 6. Stress Test Crash Scenarios
class StressTestScenarioItem {
  final String name; // e.g. '2008 GFC', '2020 Covid Crash', 'High Inflation Stagflation'
  final double marketDropPercent; // e.g. -50%
  final double portfolioImpactPercent; // e.g. -28.5%
  final double projectedLossAmount;
  final String recoveryMonths;

  const StressTestScenarioItem({
    required this.name,
    required this.marketDropPercent,
    required this.portfolioImpactPercent,
    required this.projectedLossAmount,
    required this.recoveryMonths,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'marketDropPercent': marketDropPercent,
    'portfolioImpactPercent': portfolioImpactPercent,
    'projectedLossAmount': projectedLossAmount,
    'recoveryMonths': recoveryMonths,
  };

  factory StressTestScenarioItem.fromJson(Map<String, dynamic> json) => StressTestScenarioItem(
    name: json['name'] as String? ?? 'Market Crash',
    marketDropPercent: (json['marketDropPercent'] as num?)?.toDouble() ?? -30.0,
    portfolioImpactPercent: (json['portfolioImpactPercent'] as num?)?.toDouble() ?? -18.0,
    projectedLossAmount: (json['projectedLossAmount'] as num?)?.toDouble() ?? 0.0,
    recoveryMonths: json['recoveryMonths'] as String? ?? '18 Months',
  );
}

class StressTestResultPayload extends GenerativeUIPayload {
  final List<StressTestScenarioItem> scenarios;
  final double overallResilienceScore; // 0 - 100
  final String commentary;

  const StressTestResultPayload({
    required String widgetId,
    required this.scenarios,
    required this.overallResilienceScore,
    this.commentary = '',
  }) : super(type: GenerativeWidgetType.stressTestResult, widgetId: widgetId);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'scenarios': scenarios.map((s) => s.toJson()).toList(),
    'overallResilienceScore': overallResilienceScore,
    'commentary': commentary,
  };

  factory StressTestResultPayload.fromJson(Map<String, dynamic> json) => StressTestResultPayload(
    widgetId: json['widgetId'] as String? ?? 'stress_1',
    scenarios: (json['scenarios'] as List<dynamic>? ?? [])
        .map((s) => StressTestScenarioItem.fromJson(s as Map<String, dynamic>))
        .toList(),
    overallResilienceScore: (json['overallResilienceScore'] as num?)?.toDouble() ?? 75.0,
    commentary: json['commentary'] as String? ?? '',
  );
}

/// 7. Action Confirmation Card (Idempotent 1-Tap Mutation)
class ActionConfirmationPayload extends GenerativeUIPayload {
  final String actionId;
  final String actionType; // 'addAsset', 'rebalance', 'updateSip'
  final String title;
  final String description;
  final AIAssetEntry? assetToAdd;
  final List<AIAssetRebalanceDelta>? rebalanceDeltas;
  final bool isApplied;
  final String? appliedTimestamp;

  const ActionConfirmationPayload({
    required String widgetId,
    required this.actionId,
    required this.actionType,
    required this.title,
    required this.description,
    this.assetToAdd,
    this.rebalanceDeltas,
    this.isApplied = false,
    this.appliedTimestamp,
  }) : super(type: GenerativeWidgetType.actionConfirmation, widgetId: widgetId);

  ActionConfirmationPayload copyWithApplied() => ActionConfirmationPayload(
    widgetId: widgetId,
    actionId: actionId,
    actionType: actionType,
    title: title,
    description: description,
    assetToAdd: assetToAdd,
    rebalanceDeltas: rebalanceDeltas,
    isApplied: true,
    appliedTimestamp: DateTime.now().toIso8601String(),
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'actionId': actionId,
    'actionType': actionType,
    'title': title,
    'description': description,
    'assetToAdd': assetToAdd?.toJson(),
    'rebalanceDeltas': rebalanceDeltas?.map((d) => d.toJson()).toList(),
    'isApplied': isApplied,
    'appliedTimestamp': appliedTimestamp,
  };

  factory ActionConfirmationPayload.fromJson(Map<String, dynamic> json) => ActionConfirmationPayload(
    widgetId: json['widgetId'] as String? ?? 'action_1',
    actionId: json['actionId'] as String? ?? 'act_1',
    actionType: json['actionType'] as String? ?? 'addAsset',
    title: json['title'] as String? ?? 'Proposed Action',
    description: json['description'] as String? ?? '',
    assetToAdd: json['assetToAdd'] != null
        ? AIAssetEntry.fromJson(json['assetToAdd'] as Map<String, dynamic>)
        : null,
    rebalanceDeltas: (json['rebalanceDeltas'] as List<dynamic>?)
        ?.map((d) => AIAssetRebalanceDelta.fromJson(d as Map<String, dynamic>))
        .toList(),
    isApplied: json['isApplied'] as bool? ?? false,
    appliedTimestamp: json['appliedTimestamp'] as String?,
  );
}

/// 8. Batch Asset Import Card (From Statement or Screenshot)
class BatchAssetImportPayload extends GenerativeUIPayload {
  final String importId;
  final String sourceDescription; // e.g. 'Parsed Zerodha Statement (12 Holdings)'
  final List<AIAssetEntry> extractedAssets;
  final bool isImported;
  final String? importedTimestamp;

  const BatchAssetImportPayload({
    required String widgetId,
    required this.importId,
    required this.sourceDescription,
    required this.extractedAssets,
    this.isImported = false,
    this.importedTimestamp,
  }) : super(type: GenerativeWidgetType.batchAssetImport, widgetId: widgetId);

  BatchAssetImportPayload copyWithImported() => BatchAssetImportPayload(
    widgetId: widgetId,
    importId: importId,
    sourceDescription: sourceDescription,
    extractedAssets: extractedAssets,
    isImported: true,
    importedTimestamp: DateTime.now().toIso8601String(),
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'importId': importId,
    'sourceDescription': sourceDescription,
    'extractedAssets': extractedAssets.map((a) => a.toJson()).toList(),
    'isImported': isImported,
    'importedTimestamp': importedTimestamp,
  };

  factory BatchAssetImportPayload.fromJson(Map<String, dynamic> json) => BatchAssetImportPayload(
    widgetId: json['widgetId'] as String? ?? 'batch_1',
    importId: json['importId'] as String? ?? 'imp_1',
    sourceDescription: json['sourceDescription'] as String? ?? 'Parsed Statement',
    extractedAssets: (json['extractedAssets'] as List<dynamic>? ?? [])
        .map((a) => AIAssetEntry.fromJson(a as Map<String, dynamic>))
        .toList(),
    isImported: json['isImported'] as bool? ?? false,
    importedTimestamp: json['importedTimestamp'] as String?,
  );
}

/// 9. Interactive What-If Scenario Simulator Card (With on-device live slider math)
class ScenarioSimulatorPayload extends GenerativeUIPayload {
  final double initialNetWorth;
  final double defaultAnnualSavings;
  final double defaultExpectedReturn;
  final double defaultInflationRate;
  final int defaultYears;
  final String currencySymbol;

  const ScenarioSimulatorPayload({
    required String widgetId,
    required this.initialNetWorth,
    required this.defaultAnnualSavings,
    this.defaultExpectedReturn = 12.0,
    this.defaultInflationRate = 6.0,
    this.defaultYears = 15,
    this.currencySymbol = '₹',
  }) : super(type: GenerativeWidgetType.scenarioSimulator, widgetId: widgetId);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'initialNetWorth': initialNetWorth,
    'defaultAnnualSavings': defaultAnnualSavings,
    'defaultExpectedReturn': defaultExpectedReturn,
    'defaultInflationRate': defaultInflationRate,
    'defaultYears': defaultYears,
    'currencySymbol': currencySymbol,
  };

  factory ScenarioSimulatorPayload.fromJson(Map<String, dynamic> json) => ScenarioSimulatorPayload(
    widgetId: json['widgetId'] as String? ?? 'sim_1',
    initialNetWorth: (json['initialNetWorth'] as num?)?.toDouble() ?? 1000000.0,
    defaultAnnualSavings: (json['defaultAnnualSavings'] as num?)?.toDouble() ?? 240000.0,
    defaultExpectedReturn: (json['defaultExpectedReturn'] as num?)?.toDouble() ?? 12.0,
    defaultInflationRate: (json['defaultInflationRate'] as num?)?.toDouble() ?? 6.0,
    defaultYears: json['defaultYears'] as int? ?? 15,
    currencySymbol: json['currencySymbol'] as String? ?? '₹',
  );
}

/// 10. SWP Sustainability Cash Flow Card
class SwpCashFlowPayload extends GenerativeUIPayload {
  final double initialCorpus;
  final double annualWithdrawal;
  final int? depletionYear;
  final bool isPerpetual;
  final List<double> remainingCorpusOverTime;
  final String currencySymbol;

  const SwpCashFlowPayload({
    required String widgetId,
    required this.initialCorpus,
    required this.annualWithdrawal,
    this.depletionYear,
    this.isPerpetual = true,
    required this.remainingCorpusOverTime,
    this.currencySymbol = '₹',
  }) : super(type: GenerativeWidgetType.swpCashFlow, widgetId: widgetId);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'initialCorpus': initialCorpus,
    'annualWithdrawal': annualWithdrawal,
    'depletionYear': depletionYear,
    'isPerpetual': isPerpetual,
    'remainingCorpusOverTime': remainingCorpusOverTime,
    'currencySymbol': currencySymbol,
  };

  factory SwpCashFlowPayload.fromJson(Map<String, dynamic> json) => SwpCashFlowPayload(
    widgetId: json['widgetId'] as String? ?? 'swp_1',
    initialCorpus: (json['initialCorpus'] as num?)?.toDouble() ?? 10000000.0,
    annualWithdrawal: (json['annualWithdrawal'] as num?)?.toDouble() ?? 400000.0,
    depletionYear: json['depletionYear'] as int?,
    isPerpetual: json['isPerpetual'] as bool? ?? true,
    remainingCorpusOverTime: (json['remainingCorpusOverTime'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList(),
    currencySymbol: json['currencySymbol'] as String? ?? '₹',
  );
}

/// 11. Comprehensive Wealth Health Audit Report
class AuditReportPayload extends GenerativeUIPayload {
  final double healthScore; // 0 - 100
  final String summary;
  final List<String> strengths;
  final List<String> risks;
  final List<String> actionPlan;
  final String rawMarkdown;

  const AuditReportPayload({
    required String widgetId,
    required this.healthScore,
    required this.summary,
    required this.strengths,
    required this.risks,
    required this.actionPlan,
    required this.rawMarkdown,
  }) : super(type: GenerativeWidgetType.auditReport, widgetId: widgetId);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'widgetId': widgetId,
    'healthScore': healthScore,
    'summary': summary,
    'strengths': strengths,
    'risks': risks,
    'actionPlan': actionPlan,
    'rawMarkdown': rawMarkdown,
  };

  factory AuditReportPayload.fromJson(Map<String, dynamic> json) => AuditReportPayload(
    widgetId: json['widgetId'] as String? ?? 'audit_1',
    healthScore: (json['healthScore'] as num?)?.toDouble() ?? 82.0,
    summary: json['summary'] as String? ?? 'Portfolio Health Summary',
    strengths: (json['strengths'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    risks: (json['risks'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    actionPlan: (json['actionPlan'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    rawMarkdown: json['rawMarkdown'] as String? ?? '',
  );
}
