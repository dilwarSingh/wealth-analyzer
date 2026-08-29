enum GoalType {
  fire,
  housePurchase,
  higherEducation,
  wealthAccumulation,
  emergencyFund,
  custom;

  String get displayName {
    switch (this) {
      case GoalType.fire:
        return 'Early Retirement / FIRE';
      case GoalType.housePurchase:
        return 'Home Purchase';
      case GoalType.higherEducation:
        return 'Higher Education';
      case GoalType.wealthAccumulation:
        return 'Wealth Accumulation';
      case GoalType.emergencyFund:
        return 'Emergency / Stability Fund';
      case GoalType.custom:
        return 'Custom Financial Goal';
    }
  }
}

enum RiskProfile {
  conservative,
  moderate,
  aggressive;

  String get displayName {
    switch (this) {
      case RiskProfile.conservative:
        return 'Conservative (Capital Preservation)';
      case RiskProfile.moderate:
        return 'Moderate (Balanced Growth)';
      case RiskProfile.aggressive:
        return 'Aggressive (Maximum CAGR)';
    }
  }
}

/// Represents a financial target with glidepath asset allocation benchmarks
class FinancialGoal {
  final String id;
  final String name;
  final GoalType type;
  final double targetAmount;
  final double currentAccumulatedAmount;
  final int targetYears;
  final RiskProfile riskProfile;
  final double targetEquitiesPercent;
  final double targetDebtPercent;
  final double targetGoldPercent;
  final double targetCashPercent;
  final double targetCryptoPercent;
  final double targetRealEstatePercent;

  const FinancialGoal({
    required this.id,
    required this.name,
    this.type = GoalType.fire,
    required this.targetAmount,
    this.currentAccumulatedAmount = 0.0,
    required this.targetYears,
    this.riskProfile = RiskProfile.moderate,
    this.targetEquitiesPercent = 60.0,
    this.targetDebtPercent = 25.0,
    this.targetGoldPercent = 10.0,
    this.targetCashPercent = 5.0,
    this.targetCryptoPercent = 0.0,
    this.targetRealEstatePercent = 0.0,
  });

  /// Factory producing standard benchmarks based on goal horizon and risk
  factory FinancialGoal.defaultForType(GoalType type, {double targetAmount = 50000000, int years = 10}) {
    switch (type) {
      case GoalType.fire:
        return FinancialGoal(
          id: 'goal_fire',
          name: 'FIRE / Early Retirement',
          type: type,
          targetAmount: targetAmount,
          targetYears: years,
          riskProfile: RiskProfile.moderate,
          targetEquitiesPercent: 60.0,
          targetDebtPercent: 25.0,
          targetGoldPercent: 10.0,
          targetCashPercent: 5.0,
        );
      case GoalType.housePurchase:
        return FinancialGoal(
          id: 'goal_house',
          name: 'Home Down Payment',
          type: type,
          targetAmount: targetAmount,
          targetYears: years > 5 ? 5 : years,
          riskProfile: RiskProfile.conservative,
          targetEquitiesPercent: 30.0,
          targetDebtPercent: 50.0,
          targetGoldPercent: 10.0,
          targetCashPercent: 10.0,
        );
      case GoalType.higherEducation:
        return FinancialGoal(
          id: 'goal_education',
          name: 'Higher Education Fund',
          type: type,
          targetAmount: targetAmount,
          targetYears: years,
          riskProfile: RiskProfile.moderate,
          targetEquitiesPercent: 50.0,
          targetDebtPercent: 35.0,
          targetGoldPercent: 10.0,
          targetCashPercent: 5.0,
        );
      case GoalType.emergencyFund:
        return FinancialGoal(
          id: 'goal_emergency',
          name: 'Emergency Fund (12 Months)',
          type: type,
          targetAmount: targetAmount,
          targetYears: 1,
          riskProfile: RiskProfile.conservative,
          targetEquitiesPercent: 0.0,
          targetDebtPercent: 50.0,
          targetGoldPercent: 0.0,
          targetCashPercent: 50.0,
        );
      case GoalType.wealthAccumulation:
      case GoalType.custom:
        return FinancialGoal(
          id: 'goal_wealth',
          name: 'Long-term Wealth Compounding',
          type: type,
          targetAmount: targetAmount,
          targetYears: years,
          riskProfile: RiskProfile.aggressive,
          targetEquitiesPercent: 70.0,
          targetDebtPercent: 15.0,
          targetGoldPercent: 10.0,
          targetCashPercent: 5.0,
        );
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'targetAmount': targetAmount,
    'currentAccumulatedAmount': currentAccumulatedAmount,
    'targetYears': targetYears,
    'riskProfile': riskProfile.name,
    'targetEquitiesPercent': targetEquitiesPercent,
    'targetDebtPercent': targetDebtPercent,
    'targetGoldPercent': targetGoldPercent,
    'targetCashPercent': targetCashPercent,
    'targetCryptoPercent': targetCryptoPercent,
    'targetRealEstatePercent': targetRealEstatePercent,
  };

  factory FinancialGoal.fromJson(Map<String, dynamic> json) => FinancialGoal(
    id: json['id'] as String? ?? 'goal_1',
    name: json['name'] as String? ?? 'Financial Goal',
    type: GoalType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => GoalType.fire,
    ),
    targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 50000000.0,
    currentAccumulatedAmount: (json['currentAccumulatedAmount'] as num?)?.toDouble() ?? 0.0,
    targetYears: json['targetYears'] as int? ?? 10,
    riskProfile: RiskProfile.values.firstWhere(
      (e) => e.name == json['riskProfile'],
      orElse: () => RiskProfile.moderate,
    ),
    targetEquitiesPercent: (json['targetEquitiesPercent'] as num?)?.toDouble() ?? 60.0,
    targetDebtPercent: (json['targetDebtPercent'] as num?)?.toDouble() ?? 25.0,
    targetGoldPercent: (json['targetGoldPercent'] as num?)?.toDouble() ?? 10.0,
    targetCashPercent: (json['targetCashPercent'] as num?)?.toDouble() ?? 5.0,
    targetCryptoPercent: (json['targetCryptoPercent'] as num?)?.toDouble() ?? 0.0,
    targetRealEstatePercent: (json['targetRealEstatePercent'] as num?)?.toDouble() ?? 0.0,
  );
}
