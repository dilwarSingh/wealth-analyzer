class ProjectionPoint {
  final int year;
  final int age;
  final double baseValue;
  final double realValue;
  final double cashDragValue;
  final double totalInvested;

  const ProjectionPoint({
    required this.year,
    required this.age,
    required this.baseValue,
    required this.realValue,
    required this.cashDragValue,
    required this.totalInvested,
  });
}

class SimulationResult {
  final List<ProjectionPoint> points;
  final double? milestoneAge1CrOr1M;
  final double? milestoneAge5CrOr5M;
  final double? milestoneAge10CrOr10M;
  final double finalBaseNetWorth;
  final double finalRealNetWorth;
  final double finalCashDragNetWorth;
  final double finalInvestedCapital;

  const SimulationResult({
    required this.points,
    this.milestoneAge1CrOr1M,
    this.milestoneAge5CrOr5M,
    this.milestoneAge10CrOr10M,
    required this.finalBaseNetWorth,
    required this.finalRealNetWorth,
    required this.finalCashDragNetWorth,
    required this.finalInvestedCapital,
  });

  factory SimulationResult.empty() {
    return const SimulationResult(
      points: [],
      milestoneAge1CrOr1M: null,
      milestoneAge5CrOr5M: null,
      milestoneAge10CrOr10M: null,
      finalBaseNetWorth: 0.0,
      finalRealNetWorth: 0.0,
      finalCashDragNetWorth: 0.0,
      finalInvestedCapital: 0.0,
    );
  }
}
