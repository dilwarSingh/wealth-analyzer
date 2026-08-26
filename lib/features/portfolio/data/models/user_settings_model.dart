import '../../domain/entities/swp_models.dart';

class UserSettingsModel {
  final int currentAge;
  final int targetRetirementAge;
  final double inflationRate;
  final double globalStepUpRate;
  final String currencyCode;
  final bool hasSeenOnboarding;

  // SWP Decumulation Simulator fields
  final double swpMonthlyWithdrawal;
  final double swpPostRetirementCagr;
  final double swpInflationStepUp;
  final int swpTargetLifeAge;
  final bool swpUseCustomCorpus;
  final double swpCustomCorpusAmount;
  final bool swpWithdrawalInTodayTerms;
  final List<SwpMilestoneExpense> swpMilestoneExpenses;

  // FIRE Calculator fields
  final double fireMonthlyExpenses;
  final double fireSwrPercent;
  final double fireInflationRate;
  final double fireExpectedReturn;
  final double fireStepUpSavings;
  final bool fireUseCustomStarting;
  final double fireCustomStartingCorpus;
  final bool fireUseCustomSavings;
  final double fireCustomMonthlySavings;

  const UserSettingsModel({
    this.currentAge = 28,
    this.targetRetirementAge = 55,
    this.inflationRate = 6.0,
    this.globalStepUpRate = 10.0,
    this.currencyCode = 'INR',
    this.hasSeenOnboarding = false,
    this.swpMonthlyWithdrawal = 50000.0,
    this.swpPostRetirementCagr = 8.0,
    this.swpInflationStepUp = 6.0,
    this.swpTargetLifeAge = 85,
    this.swpUseCustomCorpus = false,
    this.swpCustomCorpusAmount = 10000000.0,
    this.swpWithdrawalInTodayTerms = true,
    this.swpMilestoneExpenses = const [],
    this.fireMonthlyExpenses = 50000.0,
    this.fireSwrPercent = 4.0,
    this.fireInflationRate = 6.0,
    this.fireExpectedReturn = 12.0,
    this.fireStepUpSavings = 10.0,
    this.fireUseCustomStarting = false,
    this.fireCustomStartingCorpus = 1000000.0,
    this.fireUseCustomSavings = false,
    this.fireCustomMonthlySavings = 25000.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentAge': currentAge,
      'targetRetirementAge': targetRetirementAge,
      'inflationRate': inflationRate,
      'globalStepUpRate': globalStepUpRate,
      'currencyCode': currencyCode,
      'hasSeenOnboarding': hasSeenOnboarding,
      'swpMonthlyWithdrawal': swpMonthlyWithdrawal,
      'swpPostRetirementCagr': swpPostRetirementCagr,
      'swpInflationStepUp': swpInflationStepUp,
      'swpTargetLifeAge': swpTargetLifeAge,
      'swpUseCustomCorpus': swpUseCustomCorpus,
      'swpCustomCorpusAmount': swpCustomCorpusAmount,
      'swpWithdrawalInTodayTerms': swpWithdrawalInTodayTerms,
      'swpMilestoneExpenses': swpMilestoneExpenses.map((m) => m.toJson()).toList(),
      'fireMonthlyExpenses': fireMonthlyExpenses,
      'fireSwrPercent': fireSwrPercent,
      'fireInflationRate': fireInflationRate,
      'fireExpectedReturn': fireExpectedReturn,
      'fireStepUpSavings': fireStepUpSavings,
      'fireUseCustomStarting': fireUseCustomStarting,
      'fireCustomStartingCorpus': fireCustomStartingCorpus,
      'fireUseCustomSavings': fireUseCustomSavings,
      'fireCustomMonthlySavings': fireCustomMonthlySavings,
    };
  }

  factory UserSettingsModel.fromJson(Map<dynamic, dynamic> json) {
    final rawMilestones = json['swpMilestoneExpenses'];
    List<SwpMilestoneExpense> parsedMilestones = [];
    if (rawMilestones is List) {
      parsedMilestones = rawMilestones
          .whereType<Map>()
          .map((m) => SwpMilestoneExpense.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return UserSettingsModel(
      currentAge: (json['currentAge'] as num?)?.toInt() ?? 28,
      targetRetirementAge: (json['targetRetirementAge'] as num?)?.toInt() ?? 55,
      inflationRate: (json['inflationRate'] as num?)?.toDouble() ?? 6.0,
      globalStepUpRate: (json['globalStepUpRate'] as num?)?.toDouble() ?? 10.0,
      currencyCode: json['currencyCode'] as String? ?? 'INR',
      hasSeenOnboarding: json['hasSeenOnboarding'] as bool? ?? false,
      swpMonthlyWithdrawal: (json['swpMonthlyWithdrawal'] as num?)?.toDouble() ?? 50000.0,
      swpPostRetirementCagr: (json['swpPostRetirementCagr'] as num?)?.toDouble() ?? 8.0,
      swpInflationStepUp: (json['swpInflationStepUp'] as num?)?.toDouble() ?? 6.0,
      swpTargetLifeAge: (json['swpTargetLifeAge'] as num?)?.toInt() ?? 85,
      swpUseCustomCorpus: json['swpUseCustomCorpus'] as bool? ?? false,
      swpCustomCorpusAmount: (json['swpCustomCorpusAmount'] as num?)?.toDouble() ?? 10000000.0,
      swpWithdrawalInTodayTerms: json['swpWithdrawalInTodayTerms'] as bool? ?? true,
      swpMilestoneExpenses: parsedMilestones,
      fireMonthlyExpenses: (json['fireMonthlyExpenses'] as num?)?.toDouble() ?? 50000.0,
      fireSwrPercent: (json['fireSwrPercent'] as num?)?.toDouble() ?? 4.0,
      fireInflationRate: (json['fireInflationRate'] as num?)?.toDouble() ?? 6.0,
      fireExpectedReturn: (json['fireExpectedReturn'] as num?)?.toDouble() ?? 12.0,
      fireStepUpSavings: (json['fireStepUpSavings'] as num?)?.toDouble() ?? 10.0,
      fireUseCustomStarting: json['fireUseCustomStarting'] as bool? ?? false,
      fireCustomStartingCorpus: (json['fireCustomStartingCorpus'] as num?)?.toDouble() ?? 1000000.0,
      fireUseCustomSavings: json['fireUseCustomSavings'] as bool? ?? false,
      fireCustomMonthlySavings: (json['fireCustomMonthlySavings'] as num?)?.toDouble() ?? 25000.0,
    );
  }

  UserSettingsModel copyWith({
    int? currentAge,
    int? targetRetirementAge,
    double? inflationRate,
    double? globalStepUpRate,
    String? currencyCode,
    bool? hasSeenOnboarding,
    double? swpMonthlyWithdrawal,
    double? swpPostRetirementCagr,
    double? swpInflationStepUp,
    int? swpTargetLifeAge,
    bool? swpUseCustomCorpus,
    double? swpCustomCorpusAmount,
    bool? swpWithdrawalInTodayTerms,
    List<SwpMilestoneExpense>? swpMilestoneExpenses,
    double? fireMonthlyExpenses,
    double? fireSwrPercent,
    double? fireInflationRate,
    double? fireExpectedReturn,
    double? fireStepUpSavings,
    bool? fireUseCustomStarting,
    double? fireCustomStartingCorpus,
    bool? fireUseCustomSavings,
    double? fireCustomMonthlySavings,
  }) {
    return UserSettingsModel(
      currentAge: currentAge ?? this.currentAge,
      targetRetirementAge: targetRetirementAge ?? this.targetRetirementAge,
      inflationRate: inflationRate ?? this.inflationRate,
      globalStepUpRate: globalStepUpRate ?? this.globalStepUpRate,
      currencyCode: currencyCode ?? this.currencyCode,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      swpMonthlyWithdrawal: swpMonthlyWithdrawal ?? this.swpMonthlyWithdrawal,
      swpPostRetirementCagr: swpPostRetirementCagr ?? this.swpPostRetirementCagr,
      swpInflationStepUp: swpInflationStepUp ?? this.swpInflationStepUp,
      swpTargetLifeAge: swpTargetLifeAge ?? this.swpTargetLifeAge,
      swpUseCustomCorpus: swpUseCustomCorpus ?? this.swpUseCustomCorpus,
      swpCustomCorpusAmount: swpCustomCorpusAmount ?? this.swpCustomCorpusAmount,
      swpWithdrawalInTodayTerms: swpWithdrawalInTodayTerms ?? this.swpWithdrawalInTodayTerms,
      swpMilestoneExpenses: swpMilestoneExpenses ?? this.swpMilestoneExpenses,
      fireMonthlyExpenses: fireMonthlyExpenses ?? this.fireMonthlyExpenses,
      fireSwrPercent: fireSwrPercent ?? this.fireSwrPercent,
      fireInflationRate: fireInflationRate ?? this.fireInflationRate,
      fireExpectedReturn: fireExpectedReturn ?? this.fireExpectedReturn,
      fireStepUpSavings: fireStepUpSavings ?? this.fireStepUpSavings,
      fireUseCustomStarting: fireUseCustomStarting ?? this.fireUseCustomStarting,
      fireCustomStartingCorpus: fireCustomStartingCorpus ?? this.fireCustomStartingCorpus,
      fireUseCustomSavings: fireUseCustomSavings ?? this.fireUseCustomSavings,
      fireCustomMonthlySavings: fireCustomMonthlySavings ?? this.fireCustomMonthlySavings,
    );
  }
}
