import 'package:equatable/equatable.dart';

enum FireFlavor {
  standard('Standard FIRE', '100% of current annual expenses covered forever.'),
  lean('Lean FIRE', '75% of expenses — minimalist / frugal baseline independence.'),
  fat('Fat FIRE', '135% of expenses — luxury, travel buffer & abundant lifestyle.'),
  coast('Coast FIRE', 'Compounding alone hits FIRE target at retirement without added savings.'),
  barista('Barista FIRE', 'Part-time / passion income covers 40% of living expenses.');

  final String title;
  final String description;
  const FireFlavor(this.title, this.description);
}

class FireYearlyPoint extends Equatable {
  final int year;
  final int age;
  final double netWorth;
  final double inflationAdjustedFireTarget;
  final double annualExpenses;
  final double passiveIncome;
  final double coverageRatioPercent;
  final bool isFireAchieved;

  const FireYearlyPoint({
    required this.year,
    required this.age,
    required this.netWorth,
    required this.inflationAdjustedFireTarget,
    required this.annualExpenses,
    required this.passiveIncome,
    required this.coverageRatioPercent,
    required this.isFireAchieved,
  });

  @override
  List<Object?> get props => [
        year,
        age,
        netWorth,
        inflationAdjustedFireTarget,
        annualExpenses,
        passiveIncome,
        coverageRatioPercent,
        isFireAchieved,
      ];
}

class FireCalculationResult extends Equatable {
  final double standardFireNumber;
  final double leanFireNumber;
  final double fatFireNumber;
  final double coastFireNumber;
  final double baristaFireNumber;
  final double annualExpensesToday;
  final double fireMultiplier; // e.g. 25x for 4% SWR, 33.3x for 3%
  final double currentNetWorth;
  final double fireReadinessPercent;
  final bool isFireAchieved;
  final double yearsToFire;
  final double fireAge;
  final int fireYear;
  final List<FireYearlyPoint> yearlyPoints;

  const FireCalculationResult({
    required this.standardFireNumber,
    required this.leanFireNumber,
    required this.fatFireNumber,
    required this.coastFireNumber,
    required this.baristaFireNumber,
    required this.annualExpensesToday,
    required this.fireMultiplier,
    required this.currentNetWorth,
    required this.fireReadinessPercent,
    required this.isFireAchieved,
    required this.yearsToFire,
    required this.fireAge,
    required this.fireYear,
    required this.yearlyPoints,
  });

  factory FireCalculationResult.empty() {
    return const FireCalculationResult(
      standardFireNumber: 0.0,
      leanFireNumber: 0.0,
      fatFireNumber: 0.0,
      coastFireNumber: 0.0,
      baristaFireNumber: 0.0,
      annualExpensesToday: 0.0,
      fireMultiplier: 25.0,
      currentNetWorth: 0.0,
      fireReadinessPercent: 0.0,
      isFireAchieved: false,
      yearsToFire: 0.0,
      fireAge: 0.0,
      fireYear: 0,
      yearlyPoints: [],
    );
  }

  @override
  List<Object?> get props => [
        standardFireNumber,
        leanFireNumber,
        fatFireNumber,
        coastFireNumber,
        baristaFireNumber,
        annualExpensesToday,
        fireMultiplier,
        currentNetWorth,
        fireReadinessPercent,
        isFireAchieved,
        yearsToFire,
        fireAge,
        fireYear,
        yearlyPoints,
      ];
}
