enum SwpHealthStatus {
  healthy,  // Corpus growing or comfortably sustaining (> 50% initial remaining)
  moderate, // Corpus declining slowly (15% to 50% initial remaining)
  critical, // Less than 15% remaining or near depletion
  depleted; // Fully depleted to 0

  String get label {
    switch (this) {
      case SwpHealthStatus.healthy:
        return 'Healthy / Sustainable';
      case SwpHealthStatus.moderate:
        return 'Moderate Depletion';
      case SwpHealthStatus.critical:
        return 'Critical';
      case SwpHealthStatus.depleted:
        return 'Depleted';
    }
  }
}

class SwpMilestoneExpense {
  final String id;
  final String name;
  final int targetAge;
  final double amount;
  final bool inTodayTerms;
  final bool isEnabled;

  const SwpMilestoneExpense({
    required this.id,
    required this.name,
    required this.targetAge,
    required this.amount,
    this.inTodayTerms = true,
    this.isEnabled = true,
  });

  SwpMilestoneExpense copyWith({
    String? id,
    String? name,
    int? targetAge,
    double? amount,
    bool? inTodayTerms,
    bool? isEnabled,
  }) {
    return SwpMilestoneExpense(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAge: targetAge ?? this.targetAge,
      amount: amount ?? this.amount,
      inTodayTerms: inTodayTerms ?? this.inTodayTerms,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAge': targetAge,
      'amount': amount,
      'inTodayTerms': inTodayTerms,
      'isEnabled': isEnabled,
    };
  }

  factory SwpMilestoneExpense.fromJson(Map<String, dynamic> json) {
    return SwpMilestoneExpense(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Milestone Outflow',
      targetAge: (json['targetAge'] as num?)?.toInt() ?? 65,
      amount: (json['amount'] as num?)?.toDouble() ?? 1000000.0,
      inTodayTerms: json['inTodayTerms'] as bool? ?? true,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }
}

class SwpYearlyPoint {
  final int year;
  final int age;
  final double openingBalance;
  final double returnsEarned;
  final double totalWithdrawn;
  final double oneTimeExpenses;
  final double closingBalance;
  final SwpHealthStatus status;

  const SwpYearlyPoint({
    required this.year,
    required this.age,
    required this.openingBalance,
    required this.returnsEarned,
    required this.totalWithdrawn,
    this.oneTimeExpenses = 0.0,
    required this.closingBalance,
    required this.status,
  });
}

class SwpResult {
  final List<SwpYearlyPoint> yearlyPoints;
  final double initialCorpus;
  final double totalWithdrawn;
  final double totalReturnsEarned;
  final double totalOneTimeExpenses;
  final double finalCorpus;
  final double? depletionAge;
  final bool isSustainable;
  final double effectiveMonthlyWithdrawalAtRetirement;
  final SwpSolvencyRecommendation? recommendation;

  const SwpResult({
    required this.yearlyPoints,
    required this.initialCorpus,
    required this.totalWithdrawn,
    required this.totalReturnsEarned,
    this.totalOneTimeExpenses = 0.0,
    required this.finalCorpus,
    this.depletionAge,
    required this.isSustainable,
    this.effectiveMonthlyWithdrawalAtRetirement = 0.0,
    this.recommendation,
  });

  factory SwpResult.empty() {
    return const SwpResult(
      yearlyPoints: [],
      initialCorpus: 0.0,
      totalWithdrawn: 0.0,
      totalReturnsEarned: 0.0,
      totalOneTimeExpenses: 0.0,
      finalCorpus: 0.0,
      depletionAge: null,
      isSustainable: false,
      effectiveMonthlyWithdrawalAtRetirement: 0.0,
      recommendation: null,
    );
  }
}

class SwpSolvencyRecommendation {
  final double requiredStandardCorpus;
  final double standardShortfall;
  final double requiredMonteCarlo80Corpus;
  final double mc80Shortfall;
  final double requiredMonteCarlo95Corpus;
  final double mc95Shortfall;
  
  // Crisis Scenario Targets & Shortfalls
  final double requiredGfc2008Corpus;
  final double gfc2008Shortfall;
  final double? gfc2008DepletionAge;

  final double requiredDotComCorpus;
  final double dotComShortfall;
  final double? dotComDepletionAge;

  final double requiredCovid2020Corpus;
  final double covid2020Shortfall;
  final double? covid2020DepletionAge;

  final double requiredStagflationCorpus;
  final double stagflationShortfall;
  final double? stagflationDepletionAge;

  final double requiredCustomCrisisCorpus;
  final double customCrisisShortfall;
  final double? customCrisisDepletionAge;

  // General Worst-Case / Active Crisis fallback
  final double requiredCrisisCorpus;
  final double crisisShortfall;
  final bool isAtRisk;

  const SwpSolvencyRecommendation({
    required this.requiredStandardCorpus,
    required this.standardShortfall,
    required this.requiredMonteCarlo80Corpus,
    required this.mc80Shortfall,
    required this.requiredMonteCarlo95Corpus,
    required this.mc95Shortfall,
    required this.requiredGfc2008Corpus,
    required this.gfc2008Shortfall,
    this.gfc2008DepletionAge,
    required this.requiredDotComCorpus,
    required this.dotComShortfall,
    this.dotComDepletionAge,
    required this.requiredCovid2020Corpus,
    required this.covid2020Shortfall,
    this.covid2020DepletionAge,
    required this.requiredStagflationCorpus,
    required this.stagflationShortfall,
    this.stagflationDepletionAge,
    this.requiredCustomCrisisCorpus = 0.0,
    this.customCrisisShortfall = 0.0,
    this.customCrisisDepletionAge,
    required this.requiredCrisisCorpus,
    required this.crisisShortfall,
    required this.isAtRisk,
  });

  bool get isStandardAtRisk => standardShortfall > 0;
  bool get isMonteCarloAtRisk => mc80Shortfall > 0;
  bool get isAnyCrisisAtRisk =>
      gfc2008Shortfall > 0 ||
      dotComShortfall > 0 ||
      covid2020Shortfall > 0 ||
      stagflationShortfall > 0 ||
      customCrisisShortfall > 0;

  factory SwpSolvencyRecommendation.empty() {
    return const SwpSolvencyRecommendation(
      requiredStandardCorpus: 0.0,
      standardShortfall: 0.0,
      requiredMonteCarlo80Corpus: 0.0,
      mc80Shortfall: 0.0,
      requiredMonteCarlo95Corpus: 0.0,
      mc95Shortfall: 0.0,
      requiredGfc2008Corpus: 0.0,
      gfc2008Shortfall: 0.0,
      gfc2008DepletionAge: null,
      requiredDotComCorpus: 0.0,
      dotComShortfall: 0.0,
      dotComDepletionAge: null,
      requiredCovid2020Corpus: 0.0,
      covid2020Shortfall: 0.0,
      covid2020DepletionAge: null,
      requiredStagflationCorpus: 0.0,
      stagflationShortfall: 0.0,
      stagflationDepletionAge: null,
      requiredCustomCrisisCorpus: 0.0,
      customCrisisShortfall: 0.0,
      customCrisisDepletionAge: null,
      requiredCrisisCorpus: 0.0,
      crisisShortfall: 0.0,
      isAtRisk: false,
    );
  }
}

