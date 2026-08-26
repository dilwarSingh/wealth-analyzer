enum CrisisScenario {
  gfc2008('2008 Financial Crisis', 'Lehman collapse & global recession: -38.5% shock in Year 1, +26.5% rebound in Year 2, +15.1% in Year 3.'),
  dotCom2000('2000 Dot-Com Crash', 'Tech bubble bust: -9.1% (Yr 1), -11.9% (Yr 2), -22.1% (Yr 3), +28.7% (Yr 4).'),
  flashCrash2020('2020 Flash Crash', 'COVID-19 shock: -19.6% drop in Year 1 followed by swift +18.0% recovery.'),
  stagflation('1970s Stagflation', 'High inflation spike (+11.0%) with market decline -14.7% (Yr 1) and -26.5% (Yr 2).'),
  custom('Custom Year 1 Shock', 'User-defined market crash percentage in Year 1 of retirement.');

  final String title;
  final String description;

  const CrisisScenario(this.title, this.description);
}

class MonteCarloYearlyPercentile {
  final int age;
  final double p10; // 10th percentile (Pessimistic / Worst-case)
  final double p50; // 50th percentile (Median expected)
  final double p90; // 90th percentile (Optimistic)

  const MonteCarloYearlyPercentile({
    required this.age,
    required this.p10,
    required this.p50,
    required this.p90,
  });
}

class MonteCarloResult {
  final double successRatePercent;
  final int totalRuns;
  final int successfulRuns;
  final double medianFinalCorpus;
  final double worstCaseFinalCorpus; // 10th percentile at end age
  final double optimisticFinalCorpus; // 90th percentile at end age
  final List<MonteCarloYearlyPercentile> percentiles;

  const MonteCarloResult({
    required this.successRatePercent,
    required this.totalRuns,
    required this.successfulRuns,
    required this.medianFinalCorpus,
    required this.worstCaseFinalCorpus,
    required this.optimisticFinalCorpus,
    required this.percentiles,
  });

  factory MonteCarloResult.empty() {
    return const MonteCarloResult(
      successRatePercent: 0.0,
      totalRuns: 0,
      successfulRuns: 0,
      medianFinalCorpus: 0.0,
      worstCaseFinalCorpus: 0.0,
      optimisticFinalCorpus: 0.0,
      percentiles: [],
    );
  }
}

class CrisisYearlyPoint {
  final int year;
  final int age;
  final double baselineCorpus;
  final double stressedCorpus;

  const CrisisYearlyPoint({
    required this.year,
    required this.age,
    required this.baselineCorpus,
    required this.stressedCorpus,
  });
}

class CrisisStressTestResult {
  final CrisisScenario scenario;
  final bool isResilient;
  final double? depletionAge;
  final double baselineFinalCorpus;
  final double stressedFinalCorpus;
  final List<CrisisYearlyPoint> yearlyPoints;

  const CrisisStressTestResult({
    required this.scenario,
    required this.isResilient,
    this.depletionAge,
    required this.baselineFinalCorpus,
    required this.stressedFinalCorpus,
    required this.yearlyPoints,
  });

  factory CrisisStressTestResult.empty(CrisisScenario scenario) {
    return CrisisStressTestResult(
      scenario: scenario,
      isResilient: false,
      depletionAge: null,
      baselineFinalCorpus: 0.0,
      stressedFinalCorpus: 0.0,
      yearlyPoints: [],
    );
  }
}
