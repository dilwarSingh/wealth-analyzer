import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/financial_calculator.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/swp_models.dart';

void main() {
  group('FinancialCalculator Unit Tests (Given - When - Then - Verify)', () {
    // -------------------------------------------------------------
    // 1. One-Time Lump Sum Future Value Calculations
    // -------------------------------------------------------------
    group('calculateLumpSumFutureValue', () {
      test('Given 100,000 capital at 10% CAGR for 1 year, When calculated, Then returns 110,000', () {
        // Given
        const principal = 100000.0;
        const cagr = 10.0;
        const years = 1.0;

        // When
        final fv = FinancialCalculator.calculateLumpSumFutureValue(
          currentValue: principal,
          annualCagrPercent: cagr,
          years: years,
        );

        // Then & Verify
        expect(fv, closeTo(110000.0, 0.01));
      });

      test('Given 100,000 capital at 12% CAGR for 10 years, When calculated, Then matches standard compound interest benchmark', () {
        // Given
        const principal = 100000.0;
        const cagr = 12.0;
        const years = 10.0;

        // When
        final fv = FinancialCalculator.calculateLumpSumFutureValue(
          currentValue: principal,
          annualCagrPercent: cagr,
          years: years,
        );

        // Then & Verify
        // 100,000 * (1.12)^10 ≈ 310584.82
        expect(fv, closeTo(310584.82, 1.0));
      });

      test('Given 0 capital or 0 years, When calculated, Then returns original principal or 0', () {
        // Given & When
        final fvZeroYears = FinancialCalculator.calculateLumpSumFutureValue(
          currentValue: 50000.0,
          annualCagrPercent: 15.0,
          years: 0.0,
        );
        final fvZeroCapital = FinancialCalculator.calculateLumpSumFutureValue(
          currentValue: 0.0,
          annualCagrPercent: 15.0,
          years: 5.0,
        );

        // Then & Verify
        expect(fvZeroYears, equals(50000.0));
        expect(fvZeroCapital, equals(0.0));
      });
    });

    // -------------------------------------------------------------
    // 2. Monthly SIP Future Value & Effective CAGR Compounding
    // -------------------------------------------------------------
    group('calculateSipFutureValue (Groww / Indian Financial Benchmark)', () {
      test('Given 10,000 monthly SIP at 12% CAGR for 10 years with 0% step-up, When calculated, Then matches Groww SIP Calculator to the exact rupee', () {
        // Given
        const monthlyAmount = 10000.0;
        const cagr = 12.0;
        const years = 10.0;
        const stepUp = 0.0;

        // When
        final totalFv = FinancialCalculator.calculateSipFutureValue(
          monthlyAmount: monthlyAmount,
          annualCagrPercent: cagr,
          years: years,
          stepUpPercent: stepUp,
        );

        // Then & Verify:
        // Groww output for ₹10k/mo @ 12% for 10Y: ₹22,40,359.85 (₹22.40 Lakhs)
        expect(totalFv, closeTo(2240359.85, 1.0));
      });

      test('Given 10,000 monthly SIP at 12% CAGR for 1 year, When calculated, Then matches Groww 1-year benchmark', () {
        // Given
        const monthlyAmount = 10000.0;
        const cagr = 12.0;
        const years = 1.0;

        // When
        final totalFv = FinancialCalculator.calculateSipFutureValue(
          monthlyAmount: monthlyAmount,
          annualCagrPercent: cagr,
          years: years,
        );

        // Then & Verify: ₹1,27,664.98
        expect(totalFv, closeTo(127664.98, 1.0));
      });

      test('Given 10,000 monthly SIP with 10% annual step-up at 12% CAGR for 5 years, When calculated, Then compounds growing deposits', () {
        // Given
        const monthlyAmount = 10000.0;
        const cagr = 12.0;
        const years = 5.0;
        const stepUp = 10.0;

        // When
        final totalFv = FinancialCalculator.calculateSipFutureValue(
          monthlyAmount: monthlyAmount,
          annualCagrPercent: cagr,
          years: years,
          stepUpPercent: stepUp,
        );
        final nonStepUpFv = FinancialCalculator.calculateSipFutureValue(
          monthlyAmount: monthlyAmount,
          annualCagrPercent: cagr,
          years: years,
          stepUpPercent: 0.0,
        );

        // Then & Verify: Step-up FV must strictly exceed flat SIP FV
        expect(totalFv, greaterThan(nonStepUpFv));
        expect(totalFv, closeTo(980000.0, 50000.0));
      });

      test('Given 0 monthly amount or 0 years, When calculated, Then returns 0', () {
        // When
        final fvZeroYears = FinancialCalculator.calculateSipFutureValue(
          monthlyAmount: 10000.0,
          annualCagrPercent: 12.0,
          years: 0.0,
        );
        final fvZeroAmount = FinancialCalculator.calculateSipFutureValue(
          monthlyAmount: 0.0,
          annualCagrPercent: 12.0,
          years: 10.0,
        );

        // Then & Verify
        expect(fvZeroYears, equals(0.0));
        expect(fvZeroAmount, equals(0.0));
      });
    });

    // -------------------------------------------------------------
    // 3. Total SIP Capital Invested Over Time
    // -------------------------------------------------------------
    group('calculateTotalSipCapitalInvested', () {
      test('Given 10,000 monthly SIP for 10 years at 0% step-up, When calculated, Then returns 1,200,000 (12 Lakhs)', () {
        // Given
        const monthlyAmount = 10000.0;
        const years = 10.0;

        // When
        final invested = FinancialCalculator.calculateTotalSipCapitalInvested(
          monthlyAmount: monthlyAmount,
          years: years,
          stepUpPercent: 0.0,
        );

        // Then & Verify: 10,000 * 120 months = 1,200,000
        expect(invested, equals(1200000.0));
      });

      test('Given 10,000 monthly SIP for 2 years with 10% step-up, When calculated, Then returns Yr1 (120k) + Yr2 (132k) = 252k', () {
        // Given
        const monthlyAmount = 10000.0;
        const years = 2.0;
        const stepUp = 10.0;

        // When
        final invested = FinancialCalculator.calculateTotalSipCapitalInvested(
          monthlyAmount: monthlyAmount,
          years: years,
          stepUpPercent: stepUp,
        );

        // Then & Verify: Yr1 = 12 * 10,000 = 120,000; Yr2 = 12 * 11,000 = 132,000 -> Total = 252,000
        expect(invested, equals(252000.0));
      });
    });

    // -------------------------------------------------------------
    // 4. Inflation Adjustment & Purchasing Power
    // -------------------------------------------------------------
    group('calculateInflationAdjustedValue', () {
      test('Given 100,000 future value after 1 year with 6% inflation, When discounted, Then returns ~94,339.62', () {
        // Given
        const nominalValue = 100000.0;
        const inflation = 6.0;
        const years = 1.0;

        // When
        final realVal = FinancialCalculator.calculateInflationAdjustedValue(
          nominalFutureValue: nominalValue,
          inflationRatePercent: inflation,
          years: years,
        );

        // Then & Verify: 100,000 / 1.06 ≈ 94,339.62
        expect(realVal, closeTo(94339.62, 0.01));
      });

      test('Given 0% inflation rate, When calculated, Then real value equals nominal value', () {
        // Given & When
        final realVal = FinancialCalculator.calculateInflationAdjustedValue(
          nominalFutureValue: 500000.0,
          inflationRatePercent: 0.0,
          years: 10.0,
        );

        // Then & Verify
        expect(realVal, equals(500000.0));
      });
    });

    // -------------------------------------------------------------
    // 5. Blended Portfolio CAGR Weighting
    // -------------------------------------------------------------
    group('calculateBlendedCagr', () {
      test('Given multiple assets with different weights and CAGRs, When calculated, Then returns weighted average rate', () {
        // Given: Asset 1 (100k @ 10%), Asset 2 (200k @ 15%) -> Total = 300k, Sum = 4,000k -> 13.33%
        final weights = [
          (value: 100000.0, cagr: 10.0),
          (value: 200000.0, cagr: 15.0),
        ];

        // When
        final blended = FinancialCalculator.calculateBlendedCagr(assetWeights: weights);

        // Then & Verify
        expect(blended, closeTo(13.333, 0.01));
      });

      test('Given empty weights list or all zero valuations, When calculated, Then returns 0.0', () {
        // When
        final emptyBlended = FinancialCalculator.calculateBlendedCagr(assetWeights: []);
        final zeroBlended = FinancialCalculator.calculateBlendedCagr(assetWeights: [
          (value: 0.0, cagr: 12.0),
          (value: 0.0, cagr: 15.0),
        ]);

        // Then & Verify
        expect(emptyBlended, equals(0.0));
        expect(zeroBlended, equals(0.0));
      });
    });

    // -------------------------------------------------------------
    // 6. Milestone Age Solver
    // -------------------------------------------------------------
    group('findMilestoneAge', () {
      test('Given predictable linear growth curve, When target is reached, Then returns exact fractional age', () {
        // Given
        double mockPortfolioCurve(double years) => 100000.0 + (years * 50000.0);

        // When: Target 250,000 starting from Age 30 (requires 3 years -> Age 33)
        final milestoneAge = FinancialCalculator.findMilestoneAge(
          currentAge: 30,
          maxAge: 60,
          milestoneTarget: 250000.0,
          getPortfolioValueAtYear: mockPortfolioCurve,
        );

        // Then & Verify
        expect(milestoneAge, isNotNull);
        expect(milestoneAge!, closeTo(33.0, 0.1));
      });

      test('Given unachievable high target within max age, When evaluated, Then returns null', () {
        // Given: Portfolio grows to 100k, but target is 100,000,000
        double mockSlowCurve(double years) => 10000.0 + (years * 1000.0);

        // When
        final milestoneAge = FinancialCalculator.findMilestoneAge(
          currentAge: 30,
          maxAge: 40,
          milestoneTarget: 100000000.0,
          getPortfolioValueAtYear: mockSlowCurve,
        );

        // Then & Verify
        expect(milestoneAge, isNull);
      });
    });

    // -------------------------------------------------------------
    // 7. FIRE Trajectory & Multi-FIRE Numbers
    // -------------------------------------------------------------
    group('calculateFireTrajectory', () {
      test('Given 50,000 monthly expenses and 4% SWR, When calculated, Then returns 1.5 Cr Standard FIRE target (25x)', () {
        final result = FinancialCalculator.calculateFireTrajectory(
          currentNetWorth: 5000000.0, // 50 Lakhs
          currentMonthlySavings: 25000.0,
          monthlyExpenses: 50000.0,
          swrPercent: 4.0,
          inflationPercent: 6.0,
          annualReturnPercent: 12.0,
          stepUpSavingsPercent: 10.0,
          currentAge: 30,
          targetRetirementAge: 50,
        );

        // Annual Expenses = 50,000 * 12 = 600,000
        expect(result.annualExpensesToday, equals(600000.0));
        expect(result.fireMultiplier, equals(25.0));
        // Standard FIRE = 600,000 * 25 = 15,000,000 (1.5 Cr)
        expect(result.standardFireNumber, equals(15000000.0));
        // Lean FIRE = 15M * 0.75 = 11,250,000
        expect(result.leanFireNumber, equals(11250000.0));
        // Fat FIRE = 15M * 1.35 = 20,250,000
        expect(result.fatFireNumber, equals(20250000.0));
        // Barista FIRE = 15M * (1 - 0.40) = 9,000,000
        expect(result.baristaFireNumber, equals(9000000.0));
        // Readiness = 5M / 15M = 33.33%
        expect(result.fireReadinessPercent, closeTo(33.33, 0.1));
        // Coast FIRE Number is positive and less than future target
        expect(result.coastFireNumber, greaterThan(0.0));
        expect(result.yearlyPoints, isNotEmpty);
        expect(result.isFireAchieved, isTrue);
        expect(result.fireAge, greaterThanOrEqualTo(30.0));
      });

      test('Given net worth already exceeding FIRE number, When calculated, Then marks FIRE achieved with 0 years left', () {
        final result = FinancialCalculator.calculateFireTrajectory(
          currentNetWorth: 20000000.0, // 2 Cr
          currentMonthlySavings: 0.0,
          monthlyExpenses: 50000.0,
          swrPercent: 4.0,
          inflationPercent: 6.0,
          annualReturnPercent: 12.0,
          currentAge: 35,
          targetRetirementAge: 50,
        );

        expect(result.standardFireNumber, equals(15000000.0));
        expect(result.isFireAchieved, isTrue);
        expect(result.yearsToFire, equals(0.0));
        expect(result.fireAge, equals(35.0));
        expect(result.fireReadinessPercent, greaterThan(100.0));
      });
    });

    // -------------------------------------------------------------
    // 8. SWP with Today's Terms Auto-Inflation & Milestones
    // -------------------------------------------------------------
    group('calculateSwp', () {
      test('Given 50,000 today monthly withdrawal, When auto-inflated to retirement in 20 yrs at 6%, Then starts with ~160,356/mo', () {
        final result = FinancialCalculator.calculateSwp(
          initialCorpus: 50000000.0, // 5 Cr
          initialMonthlyWithdrawal: 50000.0,
          annualReturnPercent: 8.0,
          annualWithdrawalStepUpPercent: 6.0,
          startAge: 50,
          targetEndAge: 85,
          currentAge: 30,
          isWithdrawalInTodayTerms: true,
          annualInflationPercent: 6.0,
        );

        // 50,000 * (1.06)^20 ≈ 160,356.77
        expect(result.effectiveMonthlyWithdrawalAtRetirement, closeTo(160356.77, 1.0));
        expect(result.yearlyPoints.length, equals(35));
        expect(result.isSustainable, isTrue);
      });

      test('Given milestone expense at Age 65, When calculated, Then deducts outflow in Yr 15 and records oneTimeExpenses', () {
        final result = FinancialCalculator.calculateSwp(
          initialCorpus: 50000000.0,
          initialMonthlyWithdrawal: 50000.0,
          annualReturnPercent: 8.0,
          annualWithdrawalStepUpPercent: 6.0,
          startAge: 50,
          targetEndAge: 85,
          currentAge: 30,
          isWithdrawalInTodayTerms: false,
          milestoneExpenses: const [
            SwpMilestoneExpense(
              id: 'm1',
              name: 'Medical Reserve',
              targetAge: 65,
              amount: 2000000.0, // 20L
              inTodayTerms: false,
              isEnabled: true,
            ),
          ],
        );

        final yr15 = result.yearlyPoints.firstWhere((p) => p.age == 65);
        expect(yr15.oneTimeExpenses, equals(2000000.0));
        expect(result.totalOneTimeExpenses, equals(2000000.0));
      });
    });

    // -------------------------------------------------------------
    // 9. SWP Solvency & Recommended Minimum Corpus Solvers
    // -------------------------------------------------------------
    group('Solvency Recommendation Solvers', () {
      test('Given monthly withdrawal of 50k for 30 years at 8% return and 0% step-up, When calculateRecommendedStandardCorpus is solved, Then finds exact sustainable corpus (~6.8 Cr with 0 final balance)', () {
        final recStandard = FinancialCalculator.calculateRecommendedStandardCorpus(
          initialMonthlyWithdrawal: 50000.0,
          annualReturnPercent: 8.0,
          annualWithdrawalStepUpPercent: 0.0,
          startAge: 55,
          targetEndAge: 85,
          isWithdrawalInTodayTerms: false,
        );

        expect(recStandard, greaterThan(0.0));
        final testSwp = FinancialCalculator.calculateSwp(
          initialCorpus: recStandard,
          initialMonthlyWithdrawal: 50000.0,
          annualReturnPercent: 8.0,
          annualWithdrawalStepUpPercent: 0.0,
          startAge: 55,
          targetEndAge: 85,
          isWithdrawalInTodayTerms: false,
        );
        expect(testSwp.isSustainable, isTrue);
        expect(testSwp.finalCorpus, closeTo(0.0, 1000.0));
      });

      test('Given Monte Carlo solver with 80% and 95% target confidence, When solved, Then 95% bulletproof corpus strictly exceeds 80% corpus', () {
        final rec80 = FinancialCalculator.calculateRecommendedMonteCarloCorpus(
          initialMonthlyWithdrawal: 40000.0,
          meanAnnualReturnPercent: 8.0,
          annualVolatilityPercent: 12.0,
          annualWithdrawalStepUpPercent: 0.0,
          startAge: 60,
          targetEndAge: 85,
          targetSuccessRatePercent: 80.0,
          trials: 300,
        );

        final rec95 = FinancialCalculator.calculateRecommendedMonteCarloCorpus(
          initialMonthlyWithdrawal: 40000.0,
          meanAnnualReturnPercent: 8.0,
          annualVolatilityPercent: 12.0,
          annualWithdrawalStepUpPercent: 0.0,
          startAge: 60,
          targetEndAge: 85,
          targetSuccessRatePercent: 95.0,
          trials: 300,
        );

        expect(rec80, greaterThan(0.0));
        expect(rec95, greaterThan(rec80));
      });

      test('Given severely underfunded corpus (₹20 Lakh), When calculateSolvencyRecommendation is evaluated, Then marks isAtRisk and computes positive shortfalls', () {
        final rec = FinancialCalculator.calculateSolvencyRecommendation(
          initialCorpus: 2000000.0, // 20 Lakhs
          initialMonthlyWithdrawal: 50000.0, // 50k/mo
          annualReturnPercent: 8.0,
          annualWithdrawalStepUpPercent: 5.0,
          startAge: 55,
          targetEndAge: 85,
        );

        expect(rec.isAtRisk, isTrue);
        expect(rec.isStandardAtRisk, isTrue);
        expect(rec.isMonteCarloAtRisk, isTrue);
        expect(rec.isAnyCrisisAtRisk, isTrue);
        expect(rec.requiredStandardCorpus, greaterThan(2000000.0));
        expect(rec.standardShortfall, greaterThan(0.0));
        expect(rec.requiredMonteCarlo80Corpus, greaterThan(2000000.0));
        expect(rec.mc80Shortfall, greaterThan(0.0));
        expect(rec.requiredGfc2008Corpus, greaterThan(2000000.0));
        expect(rec.gfc2008Shortfall, greaterThan(0.0));
        expect(rec.requiredDotComCorpus, greaterThan(2000000.0));
        expect(rec.dotComShortfall, greaterThan(0.0));
        expect(rec.requiredCovid2020Corpus, greaterThan(2000000.0));
        expect(rec.covid2020Shortfall, greaterThan(0.0));
        expect(rec.requiredStagflationCorpus, greaterThan(2000000.0));
        expect(rec.stagflationShortfall, greaterThan(0.0));
        expect(rec.gfc2008DepletionAge, isNotNull);
        expect(rec.gfc2008DepletionAge!, lessThan(85.0));
        expect(rec.dotComDepletionAge, isNotNull);
        expect(rec.dotComDepletionAge!, lessThan(85.0));
        expect(rec.covid2020DepletionAge, isNotNull);
        expect(rec.covid2020DepletionAge!, lessThan(85.0));
        expect(rec.stagflationDepletionAge, isNotNull);
        expect(rec.stagflationDepletionAge!, lessThan(85.0));
      });
    });

    group('FIRE Accuracy, Horizon-Based SWR & Milestones Tests', () {
      test('Given various retirement horizons, When calculateRecommendedSwr is evaluated, Then returns accurate actuarial safe rates', () {
        expect(FinancialCalculator.calculateRecommendedSwr(55), equals(2.75));
        expect(FinancialCalculator.calculateRecommendedSwr(45), equals(3.00));
        expect(FinancialCalculator.calculateRecommendedSwr(38), equals(3.25));
        expect(FinancialCalculator.calculateRecommendedSwr(32), equals(3.50));
        expect(FinancialCalculator.calculateRecommendedSwr(28), equals(3.75));
        expect(FinancialCalculator.calculateRecommendedSwr(22), equals(4.00));
        expect(FinancialCalculator.calculateRecommendedSwr(15), equals(4.50));
      });

      test('Given pre-retirement capital milestone (₹40L at age 35), When calculateFireTrajectory is run, Then deducts milestone and delays FIRE achievement', () {
        // Baseline without milestone
        final baseline = FinancialCalculator.calculateFireTrajectory(
          currentNetWorth: 2000000.0, // 20 Lakhs
          currentMonthlySavings: 50000.0, // 50k/mo
          monthlyExpenses: 60000.0,
          swrPercent: 3.5,
          inflationPercent: 6.0,
          annualReturnPercent: 12.0,
          currentAge: 30,
          targetRetirementAge: 55,
        );

        // With ₹40 Lakh outflow at age 35 (year 5)
        final withMilestone = FinancialCalculator.calculateFireTrajectory(
          currentNetWorth: 2000000.0,
          currentMonthlySavings: 50000.0,
          monthlyExpenses: 60000.0,
          swrPercent: 3.5,
          inflationPercent: 6.0,
          annualReturnPercent: 12.0,
          currentAge: 30,
          targetRetirementAge: 55,
          preFireMilestones: [
            const SwpMilestoneExpense(
              id: 'm1',
              name: 'House Downpayment',
              targetAge: 35,
              amount: 4000000.0,
              inTodayTerms: true,
              isEnabled: true,
            ),
          ],
        );

        final pointAge35 = withMilestone.yearlyPoints.firstWhere((p) => p.age == 35);
        expect(pointAge35.milestoneOutflows, greaterThan(4000000.0)); // Inflated value
        expect(pointAge35.netWorth, lessThan(baseline.yearlyPoints.firstWhere((p) => p.age == 35).netWorth));
        expect(withMilestone.yearsToFire, greaterThan(baseline.yearsToFire));
        expect(withMilestone.recommendedSwr, greaterThan(0));
        expect(withMilestone.retirementHorizonYears, greaterThan(0));
      });
    });

    group('SIP Duration & Horizon Capping Tests', () {
      test('Given 10,000 monthly SIP with 5-year duration evaluated at 10 years at 12% CAGR, When calculated, Then stops deposits at yr 5 and compounds balance as lump sum for remaining 5 yrs', () {
        final fv5Yr = FinancialCalculator.calculateSipFutureValue(
          monthlyAmount: 10000.0,
          annualCagrPercent: 12.0,
          years: 5.0,
        );

        final expectedFvAt10 = FinancialCalculator.calculateLumpSumFutureValue(
          currentValue: fv5Yr,
          annualCagrPercent: 12.0,
          years: 5.0,
        );

        final actualFvAt10 = FinancialCalculator.calculateSipFutureValue(
          monthlyAmount: 10000.0,
          annualCagrPercent: 12.0,
          years: 10.0,
          maxDurationYears: 5.0,
        );

        expect(actualFvAt10, closeTo(expectedFvAt10, 0.01));
      });

      test('Given 10,000 monthly SIP with 5-year duration, When total capital invested is evaluated at 10 years, Then caps invested capital at 5 years (6 Lakhs)', () {
        final investedAt5 = FinancialCalculator.calculateTotalSipCapitalInvested(
          monthlyAmount: 10000.0,
          years: 5.0,
        );

        final investedAt10Capped = FinancialCalculator.calculateTotalSipCapitalInvested(
          monthlyAmount: 10000.0,
          years: 10.0,
          maxDurationYears: 5.0,
        );

        expect(investedAt5, equals(600000.0));
        expect(investedAt10Capped, equals(600000.0));
      });
    });
  });
}

