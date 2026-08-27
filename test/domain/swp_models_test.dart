import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/swp_models.dart';

void main() {
  group('SwpModels Entity Tests (Given - When - Then - Verify)', () {
    test('Given SwpHealthStatus enum values, When label is called, Then returns descriptive text', () {
      expect(SwpHealthStatus.healthy.label, equals('Healthy / Sustainable'));
      expect(SwpHealthStatus.moderate.label, equals('Moderate Depletion'));
      expect(SwpHealthStatus.critical.label, equals('Critical'));
      expect(SwpHealthStatus.depleted.label, equals('Depleted'));
    });

    test('Given SwpMilestoneExpense, When serialized and deserialized with JSON, Then values match exactly', () {
      const milestone = SwpMilestoneExpense(
        id: 'm-101',
        name: 'World Tour Vacation',
        targetAge: 60,
        amount: 1500000.0,
        inTodayTerms: true,
        isEnabled: true,
      );

      final json = milestone.toJson();
      expect(json['id'], equals('m-101'));
      expect(json['name'], equals('World Tour Vacation'));
      expect(json['targetAge'], equals(60));
      expect(json['amount'], equals(1500000.0));
      expect(json['inTodayTerms'], isTrue);
      expect(json['isEnabled'], isTrue);

      final restored = SwpMilestoneExpense.fromJson(json);
      expect(restored.id, equals(milestone.id));
      expect(restored.name, equals(milestone.name));
      expect(restored.targetAge, equals(milestone.targetAge));
      expect(restored.amount, equals(milestone.amount));
      expect(restored.inTodayTerms, equals(milestone.inTodayTerms));
      expect(restored.isEnabled, equals(milestone.isEnabled));

      // Test copyWith
      final updated = milestone.copyWith(amount: 2000000.0, isEnabled: false);
      expect(updated.amount, equals(2000000.0));
      expect(updated.isEnabled, isFalse);
      expect(updated.name, equals('World Tour Vacation'));

      // Test fallback defaults in fromJson
      final fallback = SwpMilestoneExpense.fromJson(const {});
      expect(fallback.id, isEmpty);
      expect(fallback.name, equals('Milestone Outflow'));
      expect(fallback.targetAge, equals(65));
      expect(fallback.amount, equals(1000000.0));
    });

    test('Given SwpResult.empty(), When instantiated, Then returns default zeroed state', () {
      final empty = SwpResult.empty();
      expect(empty.yearlyPoints, isEmpty);
      expect(empty.initialCorpus, equals(0.0));
      expect(empty.totalWithdrawn, equals(0.0));
      expect(empty.totalReturnsEarned, equals(0.0));
      expect(empty.totalOneTimeExpenses, equals(0.0));
      expect(empty.finalCorpus, equals(0.0));
      expect(empty.depletionAge, isNull);
      expect(empty.isSustainable, isFalse);
      expect(empty.effectiveMonthlyWithdrawalAtRetirement, equals(0.0));
      expect(empty.recommendation, isNull);

      final copy = empty.copyWith(initialCorpus: 1000000.0, isSustainable: true);
      expect(copy.initialCorpus, equals(1000000.0));
      expect(copy.isSustainable, isTrue);
    });

    test('Given SwpSolvencyRecommendation, When risk getters are evaluated, Then returns correct risk flags', () {
      final emptyRec = SwpSolvencyRecommendation.empty();
      expect(emptyRec.isStandardAtRisk, isFalse);
      expect(emptyRec.isMonteCarloAtRisk, isFalse);
      expect(emptyRec.isAnyCrisisAtRisk, isFalse);

      const riskyRec = SwpSolvencyRecommendation(
        requiredStandardCorpus: 20000000.0,
        standardShortfall: 5000000.0,
        requiredMonteCarlo80Corpus: 22000000.0,
        mc80Shortfall: 7000000.0,
        requiredMonteCarlo95Corpus: 26000000.0,
        mc95Shortfall: 11000000.0,
        requiredGfc2008Corpus: 24000000.0,
        gfc2008Shortfall: 9000000.0,
        requiredDotComCorpus: 21000000.0,
        dotComShortfall: 6000000.0,
        requiredCovid2020Corpus: 19000000.0,
        covid2020Shortfall: 4000000.0,
        requiredStagflationCorpus: 25000000.0,
        stagflationShortfall: 10000000.0,
        requiredCrisisCorpus: 25000000.0,
        crisisShortfall: 10000000.0,
        isAtRisk: true,
      );

      expect(riskyRec.isStandardAtRisk, isTrue);
      expect(riskyRec.isMonteCarloAtRisk, isTrue);
      expect(riskyRec.isAnyCrisisAtRisk, isTrue);
    });
  });
}
