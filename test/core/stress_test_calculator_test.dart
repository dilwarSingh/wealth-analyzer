import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/financial_calculator.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/risk_analysis_models.dart';

void main() {
  group('FinancialCalculator Crisis Stress-Test Tests (Given - When - Then - Verify)', () {
    test('Given 2008 GFC scenario on resilient corpus, When runCrisisStressTest executes, Then reflects severe Year 1 drawdown and subsequent recovery', () {
      final result = FinancialCalculator.runCrisisStressTest(
        scenario: CrisisScenario.gfc2008,
        initialCorpus: 30000000.0, // ₹3 Cr
        initialMonthlyWithdrawal: 50000.0,
        baselineAnnualReturnPercent: 8.0,
        annualWithdrawalStepUpPercent: 5.0,
        startAge: 60,
        targetEndAge: 85,
      );

      expect(result.yearlyPoints.length, equals(25));
      expect(result.scenario, equals(CrisisScenario.gfc2008));
      // In Year 1, stressed corpus should drop substantially compared to baseline
      expect(result.yearlyPoints.first.stressedCorpus, lessThan(result.yearlyPoints.first.baselineCorpus));
      expect(result.isResilient, isTrue);
    });

    test('Given Dot-Com crash scenario on vulnerable corpus, When stress-tested, Then identifies premature depletion age', () {
      final result = FinancialCalculator.runCrisisStressTest(
        scenario: CrisisScenario.dotCom2000,
        initialCorpus: 5000000.0, // ₹50 Lakh
        initialMonthlyWithdrawal: 50000.0, // ₹50k/mo
        baselineAnnualReturnPercent: 8.0,
        annualWithdrawalStepUpPercent: 6.0,
        startAge: 60,
        targetEndAge: 85,
      );

      expect(result.isResilient, isFalse);
      expect(result.depletionAge, isNotNull);
      expect(result.depletionAge!, lessThan(85.0));
      expect(result.stressedFinalCorpus, equals(0.0));
    });

    test('Given Custom shock scenario with -40% crash, When simulated, Then executes custom shock rate in Year 1', () {
      final result = FinancialCalculator.runCrisisStressTest(
        scenario: CrisisScenario.custom,
        initialCorpus: 20000000.0,
        initialMonthlyWithdrawal: 40000.0,
        baselineAnnualReturnPercent: 8.0,
        annualWithdrawalStepUpPercent: 5.0,
        startAge: 60,
        targetEndAge: 85,
        customYear1CrashPercent: -40.0,
      );

      expect(result.scenario, equals(CrisisScenario.custom));
      expect(result.yearlyPoints.first.stressedCorpus, lessThan(15000000.0));
    });
  });
}
