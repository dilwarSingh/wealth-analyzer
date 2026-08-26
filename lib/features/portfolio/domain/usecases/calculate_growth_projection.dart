import '../../../../core/utils/financial_calculator.dart';
import '../entities/investment_asset.dart';
import '../entities/projection_scenario.dart';

class CalculateGrowthProjectionUseCase {
  SimulationResult execute({
    required List<InvestmentAsset> assets,
    required int currentAge,
    required int targetRetirementAge,
    required double annualInflationPercent,
    required double globalStepUpPercent,
    required double milestoneThreshold1, // e.g. 10000000 (1 Cr) or 1000000 ($1M)
  }) {
    final activeAssets = assets.where((a) => a.isIncluded).toList();
    if (activeAssets.isEmpty || targetRetirementAge <= currentAge) {
      return SimulationResult.empty();
    }

    final totalYears = targetRetirementAge - currentAge;
    final List<ProjectionPoint> points = [];

    // Calculate baseline year 0
    double initialNetWorth = 0.0;
    double initialCapital = 0.0;
    for (final asset in activeAssets) {
      final effectiveCurrent = asset.isOneTime
          ? (asset.currentValue > 0 ? asset.currentValue : asset.investedAmount)
          : asset.currentValue;
      initialNetWorth += effectiveCurrent;

      final effectiveInvested = asset.isSip
          ? (asset.currentValue > 0 ? (asset.investedAmount <= asset.currentValue ? asset.investedAmount : asset.currentValue) : 0.0)
          : asset.investedAmount;
      initialCapital += effectiveInvested;
    }

    points.add(ProjectionPoint(
      year: 0,
      age: currentAge,
      baseValue: initialNetWorth,
      realValue: initialNetWorth,
      cashDragValue: initialNetWorth,
      totalInvested: initialCapital,
    ));

    for (int y = 1; y <= totalYears; y++) {
      double yearBaseValue = 0.0;
      double yearTotalInvested = initialCapital;
      double yearCashDragValue = 0.0;

      for (final asset in activeAssets) {
        // Individual asset growth with global or asset-specific step up
        final stepUp = asset.stepUpRate > 0 ? asset.stepUpRate : globalStepUpPercent;
        final assetFv = asset.futureValueAfterYears(y.toDouble(), overrideStepUpRate: stepUp);
        yearBaseValue += assetFv;

        // Track capital invested over time
        if (asset.isSip) {
          final addedSipCapital = FinancialCalculator.calculateTotalSipCapitalInvested(
            monthlyAmount: asset.investedAmount,
            years: y.toDouble(),
            stepUpPercent: stepUp,
          );
          yearTotalInvested += addedSipCapital;

          // Cash Drag: SIP invested in 3.5% basic savings account
          final cashDragSip = FinancialCalculator.calculateSipFutureValue(
            monthlyAmount: asset.investedAmount,
            annualCagrPercent: 3.5,
            years: y.toDouble(),
            stepUpPercent: stepUp,
          );
          yearCashDragValue += cashDragSip;
        }

        // Cash drag for existing asset lump sum (compounding at 3.5%)
        final lumpSumPrincipal = asset.isOneTime
            ? (asset.currentValue > 0 ? asset.currentValue : asset.investedAmount)
            : asset.currentValue;
        if (lumpSumPrincipal > 0) {
          final cashDragExisting = FinancialCalculator.calculateLumpSumFutureValue(
            currentValue: lumpSumPrincipal,
            annualCagrPercent: 3.5,
            years: y.toDouble(),
          );
          yearCashDragValue += cashDragExisting;
        }
      }

      // Inflation-adjusted real purchasing power
      final yearRealValue = FinancialCalculator.calculateInflationAdjustedValue(
        nominalFutureValue: yearBaseValue,
        inflationRatePercent: annualInflationPercent,
        years: y.toDouble(),
      );

      points.add(ProjectionPoint(
        year: y,
        age: currentAge + y,
        baseValue: yearBaseValue,
        realValue: yearRealValue,
        cashDragValue: yearCashDragValue,
        totalInvested: yearTotalInvested,
      ));
    }

    // Milestone solver function
    double getBaseValueAtYear(double years) {
      if (years <= 0) return initialNetWorth;
      double total = 0.0;
      for (final asset in activeAssets) {
        final stepUp = asset.stepUpRate > 0 ? asset.stepUpRate : globalStepUpPercent;
        total += asset.futureValueAfterYears(years, overrideStepUpRate: stepUp);
      }
      return total;
    }

    final milestone1 = FinancialCalculator.findMilestoneAge(
      currentAge: currentAge,
      maxAge: targetRetirementAge,
      milestoneTarget: milestoneThreshold1,
      getPortfolioValueAtYear: getBaseValueAtYear,
    );

    final milestone5 = FinancialCalculator.findMilestoneAge(
      currentAge: currentAge,
      maxAge: targetRetirementAge,
      milestoneTarget: milestoneThreshold1 * 5,
      getPortfolioValueAtYear: getBaseValueAtYear,
    );

    final milestone10 = FinancialCalculator.findMilestoneAge(
      currentAge: currentAge,
      maxAge: targetRetirementAge,
      milestoneTarget: milestoneThreshold1 * 10,
      getPortfolioValueAtYear: getBaseValueAtYear,
    );

    final lastPoint = points.isNotEmpty ? points.last : null;

    return SimulationResult(
      points: points,
      milestoneAge1CrOr1M: milestone1,
      milestoneAge5CrOr5M: milestone5,
      milestoneAge10CrOr10M: milestone10,
      finalBaseNetWorth: lastPoint?.baseValue ?? 0.0,
      finalRealNetWorth: lastPoint?.realValue ?? 0.0,
      finalCashDragNetWorth: lastPoint?.cashDragValue ?? 0.0,
      finalInvestedCapital: lastPoint?.totalInvested ?? 0.0,
    );
  }
}
