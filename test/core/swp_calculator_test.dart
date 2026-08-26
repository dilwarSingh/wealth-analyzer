import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/financial_calculator.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/swp_models.dart';

void main() {
  group('FinancialCalculator SWP Tests (Given - When - Then - Verify)', () {
    test('Given zero initial corpus or invalid ages, When calculateSwp is called, Then returns empty result safely', () {
      // When: Zero initial corpus
      final res1 = FinancialCalculator.calculateSwp(
        initialCorpus: 0.0,
        initialMonthlyWithdrawal: 50000.0,
        annualReturnPercent: 8.0,
        annualWithdrawalStepUpPercent: 6.0,
        startAge: 60,
        targetEndAge: 85,
      );
      expect(res1.yearlyPoints, isEmpty);
      expect(res1.isSustainable, isFalse);

      // When: Target age <= start age
      final res2 = FinancialCalculator.calculateSwp(
        initialCorpus: 10000000.0,
        initialMonthlyWithdrawal: 50000.0,
        annualReturnPercent: 8.0,
        annualWithdrawalStepUpPercent: 6.0,
        startAge: 65,
        targetEndAge: 60,
      );
      expect(res2.yearlyPoints, isEmpty);
    });

    test('Given sustainable starting corpus (₹2 Cr, ₹50k/mo withdrawal, 8% return, 0% step-up), When decumulated from age 60 to 85, Then corpus grows/sustains and isSustainable is true', () {
      // ₹2 Cr at 8% CAGR yields ~₹16 Lakh/year interest (> ₹6 Lakh/year withdrawal)
      final result = FinancialCalculator.calculateSwp(
        initialCorpus: 20000000.0,
        initialMonthlyWithdrawal: 50000.0,
        annualReturnPercent: 8.0,
        annualWithdrawalStepUpPercent: 0.0,
        startAge: 60,
        targetEndAge: 85,
      );

      // Then & Verify
      expect(result.yearlyPoints.length, equals(25)); // 85 - 60
      expect(result.isSustainable, isTrue);
      expect(result.depletionAge, isNull);
      expect(result.totalWithdrawn, equals(50000.0 * 12 * 25)); // ₹1.5 Cr
      expect(result.finalCorpus, greaterThan(20000000.0)); // Grew in perpetuity
      expect(result.yearlyPoints.first.status, equals(SwpHealthStatus.healthy));
      expect(result.yearlyPoints.last.status, equals(SwpHealthStatus.healthy));
    });

    test('Given high withdrawal rate depleting corpus (₹10 Lakh corpus, ₹1 Lakh/mo withdrawal, 6% return), When decumulated, Then identifies exact depletion age and sets status to depleted', () {
      final result = FinancialCalculator.calculateSwp(
        initialCorpus: 1000000.0, // ₹10 Lakh
        initialMonthlyWithdrawal: 100000.0, // ₹1 Lakh/mo
        annualReturnPercent: 6.0,
        annualWithdrawalStepUpPercent: 0.0,
        startAge: 60,
        targetEndAge: 85,
      );

      // Then & Verify
      expect(result.isSustainable, isFalse);
      expect(result.depletionAge, isNotNull);
      expect(result.depletionAge!, lessThan(62.0)); // Depletes in ~10-11 months (Age ~60.9)
      expect(result.finalCorpus, equals(0.0));
      expect(result.yearlyPoints.last.status, equals(SwpHealthStatus.depleted));
    });
  });
}
