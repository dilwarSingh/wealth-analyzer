import 'package:flutter/material.dart';
import '../../domain/contracts/ai_portfolio_contract.dart';
import '../../domain/entities/generative_ui_payload.dart';
import '../widgets/generative_ui/gen_action_confirmation_card.dart';
import '../widgets/generative_ui/gen_allocation_chart.dart';
import '../widgets/generative_ui/gen_audit_report_view.dart';
import '../widgets/generative_ui/gen_batch_import_card.dart';
import '../widgets/generative_ui/gen_goal_rebalance_card.dart';
import '../widgets/generative_ui/gen_metric_card.dart';
import '../widgets/generative_ui/gen_monte_carlo_chart.dart';
import '../widgets/generative_ui/gen_projection_chart.dart';
import '../widgets/generative_ui/gen_scenario_slider_card.dart';
import '../widgets/generative_ui/gen_stress_test_card.dart';
import '../widgets/generative_ui/gen_swp_chart.dart';

/// Registry mapping typed GenerativeUIPayload objects to interactive Glassmorphic Flutter widgets
class GenerativeWidgetRegistry {
  static Widget buildWidget({
    required GenerativeUIPayload payload,
    required AIThemeData theme,
    AICurrencyDelegate? currencyDelegate,
    AIPortfolioActionDelegate? actionDelegate,
    VoidCallback? onStateMutated,
  }) {
    switch (payload.type) {
      case GenerativeWidgetType.kpiMetric:
        return GenMetricCard(
          payload: payload as KpiMetricPayload,
          theme: theme,
        );

      case GenerativeWidgetType.allocationChart:
        return GenAllocationChart(
          payload: payload as AllocationChartPayload,
          theme: theme,
          currencyDelegate: currencyDelegate,
        );

      case GenerativeWidgetType.goalRebalance:
        return GenGoalRebalanceCard(
          payload: payload as GoalRebalancePayload,
          theme: theme,
          currencyDelegate: currencyDelegate,
          actionDelegate: actionDelegate,
          onApplied: onStateMutated,
        );

      case GenerativeWidgetType.projectionChart:
        return GenProjectionChart(
          payload: payload as ProjectionChartPayload,
          theme: theme,
          currencyDelegate: currencyDelegate,
        );

      case GenerativeWidgetType.monteCarloCurve:
        return GenMonteCarloChart(
          payload: payload as MonteCarloCurvePayload,
          theme: theme,
          currencyDelegate: currencyDelegate,
        );

      case GenerativeWidgetType.stressTestResult:
        return GenStressTestCard(
          payload: payload as StressTestResultPayload,
          theme: theme,
          currencyDelegate: currencyDelegate,
        );

      case GenerativeWidgetType.actionConfirmation:
        return GenActionConfirmationCard(
          payload: payload as ActionConfirmationPayload,
          theme: theme,
          currencyDelegate: currencyDelegate,
          actionDelegate: actionDelegate,
          onApplied: onStateMutated,
        );

      case GenerativeWidgetType.batchAssetImport:
        return GenBatchImportCard(
          payload: payload as BatchAssetImportPayload,
          theme: theme,
          currencyDelegate: currencyDelegate,
          actionDelegate: actionDelegate,
          onImported: onStateMutated,
        );

      case GenerativeWidgetType.scenarioSimulator:
        return GenScenarioSliderCard(
          payload: payload as ScenarioSimulatorPayload,
          theme: theme,
          currencyDelegate: currencyDelegate,
        );

      case GenerativeWidgetType.swpCashFlow:
        return GenSwpChart(
          payload: payload as SwpCashFlowPayload,
          theme: theme,
          currencyDelegate: currencyDelegate,
        );

      case GenerativeWidgetType.auditReport:
        return GenAuditReportView(
          payload: payload as AuditReportPayload,
          theme: theme,
        );
    }
  }
}
