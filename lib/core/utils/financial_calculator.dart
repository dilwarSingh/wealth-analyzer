import 'dart:math' as math;
import '../../features/portfolio/domain/entities/fire_models.dart';
import '../../features/portfolio/domain/entities/risk_analysis_models.dart';
import '../../features/portfolio/domain/entities/swp_models.dart';

/// Core Financial Calculation Engine providing compound interest,
/// step-up SIP projections, weighted portfolio blended CAGR, 3-curve simulation,
/// and milestone solver.
class FinancialCalculator {
  /// Calculate future value of a single lump sum investment after [years] years.
  /// [currentValue]: Current market value
  /// [annualCagrPercent]: Expected annual CAGR (e.g., 12.0 for 12%)
  static double calculateLumpSumFutureValue({
    required double currentValue,
    required double annualCagrPercent,
    required double years,
  }) {
    if (years <= 0 || currentValue <= 0) return currentValue;
    final r = annualCagrPercent / 100.0;
    return currentValue * math.pow(1.0 + r, years);
  }

  /// Calculate future value of a monthly SIP over [years] with optional annual [stepUpPercent].
  /// Uses effective monthly rate i = (1 + r)^(1/12) - 1 matching standard financial platforms (e.g. Groww).
  /// [monthlyAmount]: Initial monthly installment
  /// [annualCagrPercent]: Expected annual CAGR (e.g. 12.0)
  /// [stepUpPercent]: Annual increase in monthly installment (e.g. 10.0 for 10%)
  static double calculateSipFutureValue({
    required double monthlyAmount,
    required double annualCagrPercent,
    required double years,
    double stepUpPercent = 0.0,
  }) {
    if (years <= 0 || monthlyAmount <= 0) return 0.0;

    final totalMonths = (years * 12).round();
    final r = annualCagrPercent / 100.0;
    // Effective monthly rate derived from annual CAGR
    final monthlyRate = r > 0 ? (math.pow(1.0 + r, 1.0 / 12.0) - 1.0) : 0.0;
    final annualStepUp = stepUpPercent / 100.0;

    double totalFutureValue = 0.0;

    for (int month = 0; month < totalMonths; month++) {
      final currentYear = month ~/ 12;
      // Step-up increases monthly amount each full year
      final currentMonthlyAmount = monthlyAmount * math.pow(1.0 + annualStepUp, currentYear);
      // Months remaining to compound until end of period
      final remainingMonths = totalMonths - month;
      
      if (monthlyRate > 0) {
        totalFutureValue += currentMonthlyAmount * math.pow(1.0 + monthlyRate, remainingMonths);
      } else {
        totalFutureValue += currentMonthlyAmount;
      }
    }

    return totalFutureValue;
  }

  /// Total capital invested into a monthly SIP over [years] with [stepUpPercent].
  static double calculateTotalSipCapitalInvested({
    required double monthlyAmount,
    required double years,
    double stepUpPercent = 0.0,
  }) {
    if (years <= 0 || monthlyAmount <= 0) return 0.0;
    final totalMonths = (years * 12).round();
    final annualStepUp = stepUpPercent / 100.0;
    double totalInvested = 0.0;

    for (int month = 0; month < totalMonths; month++) {
      final currentYear = month ~/ 12;
      final currentMonthlyAmount = monthlyAmount * math.pow(1.0 + annualStepUp, currentYear);
      totalInvested += currentMonthlyAmount;
    }

    return totalInvested;
  }

  /// Calculate real purchasing power (inflation-adjusted value).
  /// [nominalFutureValue]: Future value before inflation
  /// [inflationRatePercent]: Annual inflation percentage (e.g. 6.0)
  /// [years]: Horizon in years
  static double calculateInflationAdjustedValue({
    required double nominalFutureValue,
    required double inflationRatePercent,
    required double years,
  }) {
    if (years <= 0 || nominalFutureValue <= 0) return nominalFutureValue;
    final inflation = inflationRatePercent / 100.0;
    return nominalFutureValue / math.pow(1.0 + inflation, years);
  }

  /// Calculate blended portfolio-wide weighted CAGR across active assets.
  /// Assets with 0 value or negative weights are handled safely.
  static double calculateBlendedCagr({
    required List<({double value, double cagr})> assetWeights,
  }) {
    double totalValue = 0.0;
    double weightedSum = 0.0;

    for (final item in assetWeights) {
      if (item.value > 0) {
        totalValue += item.value;
        weightedSum += item.value * item.cagr;
      }
    }

    if (totalValue <= 0) return 0.0;
    return weightedSum / totalValue;
  }

  /// Finds the first age at which portfolio value crosses [milestoneTarget].
  /// Returns null if milestone is not reached within projection horizon.
  static double? findMilestoneAge({
    required int currentAge,
    required int maxAge,
    required double milestoneTarget,
    required double Function(double yearsFromNow) getPortfolioValueAtYear,
  }) {
    final totalYears = maxAge - currentAge;
    if (totalYears <= 0) return null;

    // Check if already reached at year 0
    if (getPortfolioValueAtYear(0) >= milestoneTarget) {
      return currentAge.toDouble();
    }

    // Step through years to find interval
    for (int y = 1; y <= totalYears; y++) {
      final val = getPortfolioValueAtYear(y.toDouble());
      if (val >= milestoneTarget) {
        // Fine interpolation between y-1 and y
        final prevVal = getPortfolioValueAtYear((y - 1).toDouble());
        final fraction = (milestoneTarget - prevVal) / (val - prevVal);
        final preciseYear = (y - 1) + fraction.clamp(0.0, 1.0);
        return currentAge + preciseYear;
      }
    }

    return null;
  }

  /// Calculates a month-by-month and year-by-year Systematic Withdrawal Plan (SWP) decumulation schedule.
  /// [initialCorpus]: Starting capital at retirement age
  /// [initialMonthlyWithdrawal]: Desired monthly living withdrawal (in today's terms or nominal)
  /// [annualReturnPercent]: Expected post-retirement annual return / CAGR (e.g. 8.0%)
  /// [annualWithdrawalStepUpPercent]: Annual percentage increase in withdrawal during retirement (e.g. 6.0%)
  /// [startAge]: Age when SWP begins (e.g. 55 or 60)
  /// [targetEndAge]: Lifespan horizon age (e.g. 85 or 90)
  /// [currentAge]: Current age today (to compound inflation from today to retirement)
  /// [isWithdrawalInTodayTerms]: When true, auto-inflates monthly withdrawal from today to retirement age
  /// [annualInflationPercent]: Inflation rate used to project living expenses
  /// [milestoneExpenses]: List of one-time lump-sum outflows during retirement
  static SwpResult calculateSwp({
    required double initialCorpus,
    required double initialMonthlyWithdrawal,
    required double annualReturnPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    int? currentAge,
    bool isWithdrawalInTodayTerms = false,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
    bool computeRecommendation = false,
  }) {
    if (initialCorpus <= 0 || targetEndAge <= startAge) {
      return SwpResult.empty();
    }

    // Auto-inflate monthly withdrawal from current age to retirement age if in today's terms
    final double effectiveStartingMonthlyWithdrawal =
        (isWithdrawalInTodayTerms && currentAge != null && startAge > currentAge)
            ? initialMonthlyWithdrawal * math.pow(1.0 + (annualInflationPercent / 100.0), (startAge - currentAge).toDouble())
            : initialMonthlyWithdrawal;

    final totalYears = targetEndAge - startAge;
    final List<SwpYearlyPoint> yearlyPoints = [];

    double currentCorpus = initialCorpus;
    double totalWithdrawn = 0.0;
    double totalReturnsEarned = 0.0;
    double totalOneTimeExpenses = 0.0;
    double? depletionAge;

    final r = annualReturnPercent / 100.0;
    final monthlyRate = r > 0 ? (math.pow(1.0 + r, 1.0 / 12.0) - 1.0) : 0.0;
    final annualStepUp = annualWithdrawalStepUpPercent / 100.0;
    final inflationRate = annualInflationPercent / 100.0;

    for (int y = 1; y <= totalYears; y++) {
      final int yearAge = startAge + y;
      final double yearOpening = currentCorpus;
      double yearWithdrawn = 0.0;
      double yearReturns = 0.0;
      double yearOneTimeExpenses = 0.0;

      // Check for one-time milestone expenses occurring at this age
      for (final milestone in milestoneExpenses) {
        if (milestone.isEnabled && milestone.targetAge == yearAge) {
          final double milestoneCost = (milestone.inTodayTerms && currentAge != null && yearAge > currentAge)
              ? milestone.amount * math.pow(1.0 + inflationRate, (yearAge - currentAge).toDouble())
              : milestone.amount;
          yearOneTimeExpenses += milestoneCost;
        }
      }

      // Deduct one-time milestone expense at start of year if applicable
      if (yearOneTimeExpenses > 0 && currentCorpus > 0) {
        final double actualMilestoneOutflow = math.min(currentCorpus, yearOneTimeExpenses);
        currentCorpus -= actualMilestoneOutflow;
        yearWithdrawn += actualMilestoneOutflow;
        totalWithdrawn += actualMilestoneOutflow;
        totalOneTimeExpenses += actualMilestoneOutflow;

        if (currentCorpus <= 0 && depletionAge == null) {
          depletionAge = (yearAge - 1).toDouble();
          currentCorpus = 0.0;
        }
      }

      final double monthlyWithdrawalForYear =
          effectiveStartingMonthlyWithdrawal * math.pow(1.0 + annualStepUp, y - 1);

      for (int m = 1; m <= 12; m++) {
        if (currentCorpus <= 0) {
          if (depletionAge == null) {
            depletionAge = startAge + (y - 1) + ((m - 1) / 12.0);
          }
          currentCorpus = 0.0;
          continue;
        }

        // Monthly return generated
        final double monthlyInterest = currentCorpus * monthlyRate;
        currentCorpus += monthlyInterest;
        yearReturns += monthlyInterest;
        totalReturnsEarned += monthlyInterest;

        // Monthly withdrawal deducted
        final double actualWithdrawal =
            math.min(currentCorpus, monthlyWithdrawalForYear);
        currentCorpus -= actualWithdrawal;
        yearWithdrawn += actualWithdrawal;
        totalWithdrawn += actualWithdrawal;

        if (currentCorpus <= 0 && depletionAge == null) {
          depletionAge = startAge + (y - 1) + (m / 12.0);
          currentCorpus = 0.0;
        }
      }

      SwpHealthStatus status;
      if (currentCorpus <= 0) {
        status = SwpHealthStatus.depleted;
      } else if (currentCorpus >= initialCorpus * 0.5) {
        status = SwpHealthStatus.healthy;
      } else if (currentCorpus >= initialCorpus * 0.15) {
        status = SwpHealthStatus.moderate;
      } else {
        status = SwpHealthStatus.critical;
      }

      yearlyPoints.add(SwpYearlyPoint(
        year: y,
        age: yearAge,
        openingBalance: yearOpening,
        returnsEarned: yearReturns,
        totalWithdrawn: yearWithdrawn,
        oneTimeExpenses: yearOneTimeExpenses,
        closingBalance: currentCorpus,
        status: status,
      ));
    }

    final isSustainable = depletionAge == null || depletionAge >= targetEndAge;

    SwpSolvencyRecommendation? solvencyRecommendation;
    if (computeRecommendation && initialMonthlyWithdrawal > 0) {
      solvencyRecommendation = calculateSolvencyRecommendation(
        initialCorpus: initialCorpus,
        initialMonthlyWithdrawal: initialMonthlyWithdrawal,
        annualReturnPercent: annualReturnPercent,
        annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
        startAge: startAge,
        targetEndAge: targetEndAge,
        currentAge: currentAge,
        isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
        annualInflationPercent: annualInflationPercent,
        milestoneExpenses: milestoneExpenses,
      );
    }

    return SwpResult(
      yearlyPoints: yearlyPoints,
      initialCorpus: initialCorpus,
      totalWithdrawn: totalWithdrawn,
      totalReturnsEarned: totalReturnsEarned,
      totalOneTimeExpenses: totalOneTimeExpenses,
      finalCorpus: currentCorpus,
      depletionAge: depletionAge,
      isSustainable: isSustainable,
      effectiveMonthlyWithdrawalAtRetirement: effectiveStartingMonthlyWithdrawal,
      recommendation: solvencyRecommendation,
    );
  }

  /// Generates a standard normal random variable Z ~ N(0, 1) using Box-Muller transform.
  static double generateStandardNormal(math.Random random) {
    double u1 = random.nextDouble();
    while (u1 <= 1e-15) {
      u1 = random.nextDouble();
    }
    final double u2 = random.nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }

  /// Simulates 1,000 randomized Monte Carlo trials over retirement horizon.
  static MonteCarloResult runMonteCarloSimulation({
    required double initialCorpus,
    required double initialMonthlyWithdrawal,
    required double meanAnnualReturnPercent,
    required double annualVolatilityPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    int trials = 1000,
    int? randomSeed,
    int? currentAge,
    bool isWithdrawalInTodayTerms = false,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
  }) {
    if (initialCorpus <= 0 || targetEndAge <= startAge) {
      return MonteCarloResult.empty();
    }

    final double effectiveStartingMonthlyWithdrawal =
        (isWithdrawalInTodayTerms && currentAge != null && startAge > currentAge)
            ? initialMonthlyWithdrawal * math.pow(1.0 + (annualInflationPercent / 100.0), (startAge - currentAge).toDouble())
            : initialMonthlyWithdrawal;

    final totalYears = targetEndAge - startAge;
    final random = math.Random(randomSeed);
    final annualStepUp = annualWithdrawalStepUpPercent / 100.0;
    final inflationRate = annualInflationPercent / 100.0;
    final mu = meanAnnualReturnPercent / 100.0;
    final sigma = annualVolatilityPercent / 100.0;

    // Pre-calculate one-time milestone expenses by age
    final Map<int, double> milestoneCostByAge = {};
    for (final m in milestoneExpenses) {
      if (m.isEnabled) {
        final double cost = (m.inTodayTerms && currentAge != null && m.targetAge > currentAge)
            ? m.amount * math.pow(1.0 + inflationRate, (m.targetAge - currentAge).toDouble())
            : m.amount;
        milestoneCostByAge[m.targetAge] = (milestoneCostByAge[m.targetAge] ?? 0.0) + cost;
      }
    }

    // Store corpus trajectories across all trials: [year 0..totalYears][trial 0..trials-1]
    final List<List<double>> yearlyTrialBalances =
        List.generate(totalYears + 1, (_) => List<double>.filled(trials, 0.0));

    int successfulRuns = 0;

    for (int t = 0; t < trials; t++) {
      double currentCorpus = initialCorpus;
      yearlyTrialBalances[0][t] = currentCorpus;

      for (int y = 1; y <= totalYears; y++) {
        final int yearAge = startAge + y;
        final double milestoneCost = milestoneCostByAge[yearAge] ?? 0.0;

        if (milestoneCost > 0 && currentCorpus > 0) {
          currentCorpus = math.max(0.0, currentCorpus - milestoneCost);
        }

        final double monthlyWithdrawalForYear =
            effectiveStartingMonthlyWithdrawal * math.pow(1.0 + annualStepUp, y - 1);

        if (currentCorpus <= 0) {
          yearlyTrialBalances[y][t] = 0.0;
          continue;
        }

        // Draw annual stochastic return: R ~ N(mu, sigma) clamped between -90% and +150%
        final double z = generateStandardNormal(random);
        final double stochasticAnnualReturn = (mu + sigma * z).clamp(-0.90, 1.50);
        final double monthlyRate = stochasticAnnualReturn > -1.0
            ? (math.pow(1.0 + stochasticAnnualReturn, 1.0 / 12.0) - 1.0)
            : -0.99;

        for (int m = 1; m <= 12; m++) {
          if (currentCorpus <= 0) {
            currentCorpus = 0.0;
            break;
          }
          final double monthlyInterest = currentCorpus * monthlyRate;
          currentCorpus += monthlyInterest;
          final double actualWithdrawal =
              math.min(currentCorpus, monthlyWithdrawalForYear);
          currentCorpus -= actualWithdrawal;
          if (currentCorpus < 0) currentCorpus = 0.0;
        }

        yearlyTrialBalances[y][t] = currentCorpus;
      }

      if (yearlyTrialBalances[totalYears][t] > 0) {
        successfulRuns++;
      }
    }

    final double successRatePercent = (successfulRuns / trials) * 100.0;

    // Calculate percentiles for each year
    final List<MonteCarloYearlyPercentile> percentiles = [];
    for (int y = 1; y <= totalYears; y++) {
      final List<double> yearValues = List<double>.from(yearlyTrialBalances[y])..sort();
      final p10Index = (trials * 0.10).floor().clamp(0, trials - 1);
      final p50Index = (trials * 0.50).floor().clamp(0, trials - 1);
      final p90Index = (trials * 0.90).floor().clamp(0, trials - 1);

      percentiles.add(MonteCarloYearlyPercentile(
        age: startAge + y,
        p10: yearValues[p10Index],
        p50: yearValues[p50Index],
        p90: yearValues[p90Index],
      ));
    }

    final finalYearSorted = List<double>.from(yearlyTrialBalances[totalYears])..sort();
    final p10Final = finalYearSorted[(trials * 0.10).floor().clamp(0, trials - 1)];
    final p50Final = finalYearSorted[(trials * 0.50).floor().clamp(0, trials - 1)];
    final p90Final = finalYearSorted[(trials * 0.90).floor().clamp(0, trials - 1)];

    return MonteCarloResult(
      successRatePercent: successRatePercent,
      totalRuns: trials,
      successfulRuns: successfulRuns,
      medianFinalCorpus: p50Final,
      worstCaseFinalCorpus: p10Final,
      optimisticFinalCorpus: p90Final,
      percentiles: percentiles,
    );
  }

  /// Runs Sequence-of-Returns Risk (SORR) stress-test under historical market crash scenarios.
  static CrisisStressTestResult runCrisisStressTest({
    required CrisisScenario scenario,
    required double initialCorpus,
    required double initialMonthlyWithdrawal,
    required double baselineAnnualReturnPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    double customYear1CrashPercent = -30.0,
    int? currentAge,
    bool isWithdrawalInTodayTerms = false,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
  }) {
    if (initialCorpus <= 0 || targetEndAge <= startAge) {
      return CrisisStressTestResult.empty(scenario);
    }

    final double effectiveStartingMonthlyWithdrawal =
        (isWithdrawalInTodayTerms && currentAge != null && startAge > currentAge)
            ? initialMonthlyWithdrawal * math.pow(1.0 + (annualInflationPercent / 100.0), (startAge - currentAge).toDouble())
            : initialMonthlyWithdrawal;

    final totalYears = targetEndAge - startAge;
    final List<CrisisYearlyPoint> yearlyPoints = [];
    final inflationRate = annualInflationPercent / 100.0;

    // Pre-calculate one-time milestone expenses by age
    final Map<int, double> milestoneCostByAge = {};
    for (final m in milestoneExpenses) {
      if (m.isEnabled) {
        final double cost = (m.inTodayTerms && currentAge != null && m.targetAge > currentAge)
            ? m.amount * math.pow(1.0 + inflationRate, (m.targetAge - currentAge).toDouble())
            : m.amount;
        milestoneCostByAge[m.targetAge] = (milestoneCostByAge[m.targetAge] ?? 0.0) + cost;
      }
    }

    // Run baseline deterministic SWP
    final baselineResult = calculateSwp(
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      annualReturnPercent: baselineAnnualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    // Stressed decumulation execution
    double currentStressedCorpus = initialCorpus;
    double? depletionAge;
    final defaultMonthlyRate = baselineAnnualReturnPercent > 0
        ? (math.pow(1.0 + baselineAnnualReturnPercent / 100.0, 1.0 / 12.0) - 1.0)
        : 0.0;

    for (int y = 1; y <= totalYears; y++) {
      final int yearAge = startAge + y;
      final double milestoneCost = milestoneCostByAge[yearAge] ?? 0.0;

      if (milestoneCost > 0 && currentStressedCorpus > 0) {
        currentStressedCorpus = math.max(0.0, currentStressedCorpus - milestoneCost);
        if (currentStressedCorpus <= 0 && depletionAge == null) {
          depletionAge = (yearAge - 1).toDouble();
        }
      }

      double annualReturnForYear = baselineAnnualReturnPercent;
      double annualStepUpForYear = annualWithdrawalStepUpPercent;

      // Apply historical shock sequence in early retirement years
      switch (scenario) {
        case CrisisScenario.gfc2008:
          if (y == 1) annualReturnForYear = -38.5;
          if (y == 2) annualReturnForYear = 26.5;
          if (y == 3) annualReturnForYear = 15.1;
          break;
        case CrisisScenario.dotCom2000:
          if (y == 1) annualReturnForYear = -9.1;
          if (y == 2) annualReturnForYear = -11.9;
          if (y == 3) annualReturnForYear = -22.1;
          if (y == 4) annualReturnForYear = 28.7;
          break;
        case CrisisScenario.flashCrash2020:
          if (y == 1) annualReturnForYear = -19.6;
          if (y == 2) annualReturnForYear = 18.0;
          break;
        case CrisisScenario.stagflation:
          if (y == 1) {
            annualReturnForYear = -14.7;
            annualStepUpForYear = annualWithdrawalStepUpPercent + 11.0;
          } else if (y == 2) {
            annualReturnForYear = -26.5;
            annualStepUpForYear = annualWithdrawalStepUpPercent + 9.0;
          }
          break;
        case CrisisScenario.custom:
          if (y == 1) annualReturnForYear = customYear1CrashPercent;
          break;
      }

      final r = annualReturnForYear / 100.0;
      final monthlyRate = r > -1.0
          ? (math.pow(1.0 + r, 1.0 / 12.0) - 1.0)
          : defaultMonthlyRate;
      final monthlyWithdrawalForYear = effectiveStartingMonthlyWithdrawal *
          math.pow(1.0 + (annualStepUpForYear / 100.0), y - 1);

      for (int m = 1; m <= 12; m++) {
        if (currentStressedCorpus <= 0) {
          if (depletionAge == null) {
            depletionAge = startAge + (y - 1) + ((m - 1) / 12.0);
          }
          currentStressedCorpus = 0.0;
          continue;
        }

        final double interest = currentStressedCorpus * monthlyRate;
        currentStressedCorpus += interest;
        final double actualWithdrawal =
            math.min(currentStressedCorpus, monthlyWithdrawalForYear);
        currentStressedCorpus -= actualWithdrawal;
        if (currentStressedCorpus <= 0 && depletionAge == null) {
          depletionAge = startAge + (y - 1) + (m / 12.0);
          currentStressedCorpus = 0.0;
        }
      }

      final baselinePoint = baselineResult.yearlyPoints.length >= y
          ? baselineResult.yearlyPoints[y - 1].closingBalance
          : 0.0;

      yearlyPoints.add(CrisisYearlyPoint(
        year: y,
        age: yearAge,
        baselineCorpus: baselinePoint,
        stressedCorpus: currentStressedCorpus,
      ));
    }

    final isResilient = depletionAge == null || depletionAge >= targetEndAge;

    return CrisisStressTestResult(
      scenario: scenario,
      isResilient: isResilient,
      depletionAge: depletionAge,
      baselineFinalCorpus: baselineResult.finalCorpus,
      stressedFinalCorpus: currentStressedCorpus,
      yearlyPoints: yearlyPoints,
    );
  }

  /// Solves for the minimum starting retirement corpus required to sustain SWP decumulation
  /// all the way to targetEndAge without depletion.
  static double calculateRecommendedStandardCorpus({
    required double initialMonthlyWithdrawal,
    required double annualReturnPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    int? currentAge,
    bool isWithdrawalInTodayTerms = false,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
  }) {
    if (targetEndAge <= startAge || initialMonthlyWithdrawal <= 0) return 0.0;

    double low = 0.0;
    double high = 1e12; // 1 Trillion upper bound

    // Binary search for 45 iterations (precision < 0.1 currency unit)
    for (int i = 0; i < 45; i++) {
      final mid = (low + high) / 2.0;
      final result = calculateSwp(
        initialCorpus: mid,
        initialMonthlyWithdrawal: initialMonthlyWithdrawal,
        annualReturnPercent: annualReturnPercent,
        annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
        startAge: startAge,
        targetEndAge: targetEndAge,
        currentAge: currentAge,
        isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
        annualInflationPercent: annualInflationPercent,
        milestoneExpenses: milestoneExpenses,
        computeRecommendation: false,
      );

      if (result.isSustainable && result.finalCorpus >= 0) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return high;
  }

  /// Solves for the minimum starting retirement corpus needed to achieve a target
  /// success rate (e.g. 80% or 95%) in Monte Carlo stochastic simulations.
  static double calculateRecommendedMonteCarloCorpus({
    required double initialMonthlyWithdrawal,
    required double meanAnnualReturnPercent,
    required double annualVolatilityPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    double targetSuccessRatePercent = 80.0,
    int trials = 500,
    int randomSeed = 42,
    int? currentAge,
    bool isWithdrawalInTodayTerms = false,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
  }) {
    if (targetEndAge <= startAge || initialMonthlyWithdrawal <= 0) return 0.0;

    double low = 0.0;
    double high = 1e12;

    for (int i = 0; i < 30; i++) {
      final mid = (low + high) / 2.0;
      final result = runMonteCarloSimulation(
        initialCorpus: mid,
        initialMonthlyWithdrawal: initialMonthlyWithdrawal,
        meanAnnualReturnPercent: meanAnnualReturnPercent,
        annualVolatilityPercent: annualVolatilityPercent,
        annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
        startAge: startAge,
        targetEndAge: targetEndAge,
        trials: trials,
        randomSeed: randomSeed,
        currentAge: currentAge,
        isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
        annualInflationPercent: annualInflationPercent,
        milestoneExpenses: milestoneExpenses,
      );

      if (result.successRatePercent >= targetSuccessRatePercent) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return high;
  }

  /// Solves for the minimum starting retirement corpus needed to survive the
  /// 2008 Global Financial Crisis shock without premature depletion.
  static double calculateRecommendedCrisisCorpus({
    required double initialMonthlyWithdrawal,
    required double baselineAnnualReturnPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    CrisisScenario scenario = CrisisScenario.gfc2008,
    int? currentAge,
    bool isWithdrawalInTodayTerms = false,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
  }) {
    if (targetEndAge <= startAge || initialMonthlyWithdrawal <= 0) return 0.0;

    double low = 0.0;
    double high = 1e12;

    for (int i = 0; i < 35; i++) {
      final mid = (low + high) / 2.0;
      final result = runCrisisStressTest(
        scenario: scenario,
        initialCorpus: mid,
        initialMonthlyWithdrawal: initialMonthlyWithdrawal,
        baselineAnnualReturnPercent: baselineAnnualReturnPercent,
        annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
        startAge: startAge,
        targetEndAge: targetEndAge,
        currentAge: currentAge,
        isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
        annualInflationPercent: annualInflationPercent,
        milestoneExpenses: milestoneExpenses,
      );

      if (result.isResilient && result.stressedFinalCorpus >= 0) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return high;
  }

  /// Calculates comprehensive solvency recommendations across Standard SWP,
  /// Monte Carlo (80% and 95% confidence), and Crisis Stress-Test (2008 GFC).
  static SwpSolvencyRecommendation calculateSolvencyRecommendation({
    required double initialCorpus,
    required double initialMonthlyWithdrawal,
    required double annualReturnPercent,
    required double annualWithdrawalStepUpPercent,
    required int startAge,
    required int targetEndAge,
    double annualVolatilityPercent = 15.0,
    int? currentAge,
    bool isWithdrawalInTodayTerms = false,
    double annualInflationPercent = 6.0,
    List<SwpMilestoneExpense> milestoneExpenses = const [],
  }) {
    if (initialMonthlyWithdrawal <= 0 || targetEndAge <= startAge) {
      return SwpSolvencyRecommendation.empty();
    }

    final requiredStandard = calculateRecommendedStandardCorpus(
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      annualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final requiredMc80 = calculateRecommendedMonteCarloCorpus(
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      meanAnnualReturnPercent: annualReturnPercent,
      annualVolatilityPercent: annualVolatilityPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      targetSuccessRatePercent: 80.0,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final requiredMc95 = calculateRecommendedMonteCarloCorpus(
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      meanAnnualReturnPercent: annualReturnPercent,
      annualVolatilityPercent: annualVolatilityPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      targetSuccessRatePercent: 95.0,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final requiredGfc = calculateRecommendedCrisisCorpus(
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      baselineAnnualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      scenario: CrisisScenario.gfc2008,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final requiredDotCom = calculateRecommendedCrisisCorpus(
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      baselineAnnualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      scenario: CrisisScenario.dotCom2000,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final requiredCovid = calculateRecommendedCrisisCorpus(
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      baselineAnnualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      scenario: CrisisScenario.flashCrash2020,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final requiredStagflation = calculateRecommendedCrisisCorpus(
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      baselineAnnualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      scenario: CrisisScenario.stagflation,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final gfcStress = runCrisisStressTest(
      scenario: CrisisScenario.gfc2008,
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      baselineAnnualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final dotComStress = runCrisisStressTest(
      scenario: CrisisScenario.dotCom2000,
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      baselineAnnualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final covidStress = runCrisisStressTest(
      scenario: CrisisScenario.flashCrash2020,
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      baselineAnnualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final stagflationStress = runCrisisStressTest(
      scenario: CrisisScenario.stagflation,
      initialCorpus: initialCorpus,
      initialMonthlyWithdrawal: initialMonthlyWithdrawal,
      baselineAnnualReturnPercent: annualReturnPercent,
      annualWithdrawalStepUpPercent: annualWithdrawalStepUpPercent,
      startAge: startAge,
      targetEndAge: targetEndAge,
      currentAge: currentAge,
      isWithdrawalInTodayTerms: isWithdrawalInTodayTerms,
      annualInflationPercent: annualInflationPercent,
      milestoneExpenses: milestoneExpenses,
    );

    final standardShortfall = math.max(0.0, requiredStandard - initialCorpus);
    final mc80Shortfall = math.max(0.0, requiredMc80 - initialCorpus);
    final mc95Shortfall = math.max(0.0, requiredMc95 - initialCorpus);
    final gfcShortfall = math.max(0.0, requiredGfc - initialCorpus);
    final dotComShortfall = math.max(0.0, requiredDotCom - initialCorpus);
    final covidShortfall = math.max(0.0, requiredCovid - initialCorpus);
    final stagflationShortfall = math.max(0.0, requiredStagflation - initialCorpus);

    final isAtRisk = standardShortfall > 0 ||
        mc80Shortfall > 0 ||
        gfcShortfall > 0 ||
        dotComShortfall > 0 ||
        covidShortfall > 0 ||
        stagflationShortfall > 0;

    return SwpSolvencyRecommendation(
      requiredStandardCorpus: requiredStandard,
      standardShortfall: standardShortfall,
      requiredMonteCarlo80Corpus: requiredMc80,
      mc80Shortfall: mc80Shortfall,
      requiredMonteCarlo95Corpus: requiredMc95,
      mc95Shortfall: mc95Shortfall,
      requiredGfc2008Corpus: requiredGfc,
      gfc2008Shortfall: gfcShortfall,
      gfc2008DepletionAge: gfcStress.depletionAge,
      requiredDotComCorpus: requiredDotCom,
      dotComShortfall: dotComShortfall,
      dotComDepletionAge: dotComStress.depletionAge,
      requiredCovid2020Corpus: requiredCovid,
      covid2020Shortfall: covidShortfall,
      covid2020DepletionAge: covidStress.depletionAge,
      requiredStagflationCorpus: requiredStagflation,
      stagflationShortfall: stagflationShortfall,
      stagflationDepletionAge: stagflationStress.depletionAge,
      requiredCrisisCorpus: requiredGfc,
      crisisShortfall: gfcShortfall,
      isAtRisk: isAtRisk,
    );
  }

  /// Calculates comprehensive FIRE targets and year-by-year accumulation crossover trajectory.
  static FireCalculationResult calculateFireTrajectory({
    required double currentNetWorth,
    required double currentMonthlySavings,
    required double monthlyExpenses,
    required double swrPercent,
    required double inflationPercent,
    required double annualReturnPercent,
    double stepUpSavingsPercent = 0.0,
    required int currentAge,
    required int targetRetirementAge,
    double leanMultiplier = 0.75,
    double fatMultiplier = 1.35,
    double baristaPartTimePercent = 40.0,
  }) {
    final annualExpensesToday = (monthlyExpenses * 12.0).clamp(0.0, double.infinity);
    final effectiveSwr = swrPercent.clamp(1.0, 10.0);
    final fireMultiplier = 100.0 / effectiveSwr;

    final standardFireNumber = annualExpensesToday * fireMultiplier;
    final leanFireNumber = standardFireNumber * leanMultiplier;
    final fatFireNumber = standardFireNumber * fatMultiplier;
    final baristaFireNumber = standardFireNumber * (1.0 - (baristaPartTimePercent / 100.0).clamp(0.0, 0.90));

    final int horizonToRetirement = math.max(0, targetRetirementAge - currentAge);
    final double infFactor = math.pow(1.0 + (inflationPercent / 100.0), horizonToRetirement).toDouble();
    final double retFactor = math.pow(1.0 + (annualReturnPercent / 100.0), horizonToRetirement).toDouble();
    final double coastFireNumber = (retFactor > 0) ? (standardFireNumber * infFactor) / retFactor : standardFireNumber;

    final double readiness = standardFireNumber > 0 ? (currentNetWorth / standardFireNumber) * 100.0 : 0.0;
    final bool isAlreadyFire = currentNetWorth >= standardFireNumber && standardFireNumber > 0;

    final int simulationYears = math.max(35, (targetRetirementAge - currentAge) + 15).clamp(10, 60);
    final List<FireYearlyPoint> yearlyPoints = [];

    double runningNetWorth = currentNetWorth;
    double monthlySip = currentMonthlySavings;
    final double monthlyReturnRate = annualReturnPercent > -100.0
        ? (math.pow(1.0 + (annualReturnPercent / 100.0), 1.0 / 12.0) - 1.0)
        : 0.0;

    double? exactYearsToFire;

    if (isAlreadyFire) {
      exactYearsToFire = 0.0;
    }

    final currentYear = DateTime.now().year;

    for (int y = 1; y <= simulationYears; y++) {
      // Monthly compounding with monthly savings contributions
      for (int m = 1; m <= 12; m++) {
        runningNetWorth = runningNetWorth * (1.0 + monthlyReturnRate) + monthlySip;
      }

      // Step up monthly savings for the next year
      if (stepUpSavingsPercent > 0) {
        monthlySip *= (1.0 + stepUpSavingsPercent / 100.0);
      }

      final double currentInfFactor = math.pow(1.0 + (inflationPercent / 100.0), y).toDouble();
      final double yearlyExpenses = annualExpensesToday * currentInfFactor;
      final double inflationAdjustedFireTarget = yearlyExpenses * fireMultiplier;
      final double passiveIncome = runningNetWorth * (effectiveSwr / 100.0);
      final double coverageRatio = yearlyExpenses > 0 ? (passiveIncome / yearlyExpenses) * 100.0 : 0.0;
      final bool isAchieved = runningNetWorth >= inflationAdjustedFireTarget;

      if (isAchieved && exactYearsToFire == null) {
        // Linear interpolation for fractional year
        final prevNetWorth = y == 1 ? currentNetWorth : yearlyPoints.last.netWorth;
        final prevTarget = y == 1 ? standardFireNumber : yearlyPoints.last.inflationAdjustedFireTarget;
        final prevDiff = prevNetWorth - prevTarget;
        final currDiff = runningNetWorth - inflationAdjustedFireTarget;
        final fraction = (prevDiff < 0 && (currDiff - prevDiff) != 0)
            ? (-prevDiff / (currDiff - prevDiff)).clamp(0.0, 1.0)
            : 0.0;
        exactYearsToFire = (y - 1) + fraction;
      }

      yearlyPoints.add(FireYearlyPoint(
        year: y,
        age: currentAge + y,
        netWorth: runningNetWorth,
        inflationAdjustedFireTarget: inflationAdjustedFireTarget,
        annualExpenses: yearlyExpenses,
        passiveIncome: passiveIncome,
        coverageRatioPercent: coverageRatio,
        isFireAchieved: isAchieved,
      ));
    }

    final double finalYearsToFire = exactYearsToFire ?? 0.0;
    final double finalFireAge = currentAge + finalYearsToFire;
    final int finalFireYear = currentYear + finalYearsToFire.round();

    return FireCalculationResult(
      standardFireNumber: standardFireNumber,
      leanFireNumber: leanFireNumber,
      fatFireNumber: fatFireNumber,
      coastFireNumber: coastFireNumber,
      baristaFireNumber: baristaFireNumber,
      annualExpensesToday: annualExpensesToday,
      fireMultiplier: fireMultiplier,
      currentNetWorth: currentNetWorth,
      fireReadinessPercent: readiness,
      isFireAchieved: isAlreadyFire || exactYearsToFire != null,
      yearsToFire: finalYearsToFire,
      fireAge: finalFireAge,
      fireYear: finalFireYear,
      yearlyPoints: yearlyPoints,
    );
  }
}
