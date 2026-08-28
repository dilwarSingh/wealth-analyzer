import '../../../../core/utils/financial_calculator.dart';
import 'asset_category.dart';

enum InvestmentType {
  oneTime('ONE_TIME', 'One-Time Lump Sum'),
  monthlySip('MONTHLY_SIP', 'Monthly SIP');

  final String code;
  final String label;

  const InvestmentType(this.code, this.label);

  static InvestmentType fromString(String val) {
    if (val.toUpperCase() == 'MONTHLY_SIP' || val.toLowerCase().contains('sip')) {
      return InvestmentType.monthlySip;
    }
    return InvestmentType.oneTime;
  }
}

class InvestmentAsset {
  final String id;
  final String name;
  final AssetCategory category;
  final String? subCategory;
  final InvestmentType type;
  final double investedAmount;
  final double currentValue;
  final DateTime startDate;
  final double expectedCAGR;
  final double stepUpRate;
  final int? sipDurationYears;
  final bool isIncluded;

  const InvestmentAsset({
    required this.id,
    required this.name,
    required this.category,
    this.subCategory,
    required this.type,
    required this.investedAmount,
    required this.currentValue,
    required this.startDate,
    required this.expectedCAGR,
    this.stepUpRate = 0.0,
    this.sipDurationYears,
    this.isIncluded = true,
  });

  bool get isSip => type == InvestmentType.monthlySip;
  bool get isOneTime => type == InvestmentType.oneTime;

  /// Total capital currently invested
  double get capitalInvested => isSip
      ? (currentValue > 0 ? currentValue : 0.0)
      : investedAmount;

  /// Absolute gain/loss (Current valuation - Capital invested)
  double get unrealizedGain => isSip
      ? (currentValue > 0 ? (currentValue - investedAmount) : 0.0)
      : (currentValue - investedAmount);

  /// Return percentage
  double get returnPercentage {
    if (isSip && currentValue == 0) return 0.0;
    if (investedAmount <= 0) return 0.0;
    return ((currentValue - investedAmount) / investedAmount) * 100.0;
  }

  /// Calculates future value of this asset after [years]
  double futureValueAfterYears(double years, {double overrideStepUpRate = -1}) {
    final effectiveStepUp = overrideStepUpRate >= 0 ? overrideStepUpRate : stepUpRate;

    if (isOneTime) {
      final basePrincipal = currentValue > 0 ? currentValue : investedAmount;
      return FinancialCalculator.calculateLumpSumFutureValue(
        currentValue: basePrincipal,
        annualCagrPercent: expectedCAGR,
        years: years,
      );
    } else {
      // Monthly SIP starting with current valuation as baseline + ongoing SIP
      final maxDuration = (sipDurationYears != null && sipDurationYears! > 0)
          ? sipDurationYears!.toDouble()
          : null;
      final ongoingSipFv = FinancialCalculator.calculateSipFutureValue(
        monthlyAmount: investedAmount,
        annualCagrPercent: expectedCAGR,
        years: years,
        stepUpPercent: effectiveStepUp,
        maxDurationYears: maxDuration,
      );
      final existingCapitalGrowth = currentValue > 0
          ? FinancialCalculator.calculateLumpSumFutureValue(
              currentValue: currentValue,
              annualCagrPercent: expectedCAGR,
              years: years,
            )
          : 0.0;
      return existingCapitalGrowth + ongoingSipFv;
    }
  }

  /// 10-year projected value for live mini-preview inside modal
  double get tenYearProjectedValue => futureValueAfterYears(10.0);

  InvestmentAsset copyWith({
    String? id,
    String? name,
    AssetCategory? category,
    String? subCategory,
    InvestmentType? type,
    double? investedAmount,
    double? currentValue,
    DateTime? startDate,
    double? expectedCAGR,
    double? stepUpRate,
    int? sipDurationYears,
    bool clearSipDuration = false,
    bool? isIncluded,
  }) {
    return InvestmentAsset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      type: type ?? this.type,
      investedAmount: investedAmount ?? this.investedAmount,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      expectedCAGR: expectedCAGR ?? this.expectedCAGR,
      stepUpRate: stepUpRate ?? this.stepUpRate,
      sipDurationYears: clearSipDuration ? null : (sipDurationYears ?? this.sipDurationYears),
      isIncluded: isIncluded ?? this.isIncluded,
    );
  }
}
