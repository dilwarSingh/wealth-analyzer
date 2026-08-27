import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/fire_models.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/swp_models.dart';

void main() {
  group('FireModels Entity Tests (Given - When - Then - Verify)', () {
    test('Given FireFlavor enum values, When inspected, Then contains correct titles and descriptions', () {
      expect(FireFlavor.standard.title, equals('Standard FIRE'));
      expect(FireFlavor.standard.description, contains('100%'));

      expect(FireFlavor.lean.title, equals('Lean FIRE'));
      expect(FireFlavor.lean.description, contains('75%'));

      expect(FireFlavor.fat.title, equals('Fat FIRE'));
      expect(FireFlavor.fat.description, contains('135%'));

      expect(FireFlavor.coast.title, equals('Coast FIRE'));
      expect(FireFlavor.coast.description, contains('Compounding alone'));

      expect(FireFlavor.barista.title, equals('Barista FIRE'));
      expect(FireFlavor.barista.description, contains('Part-time'));
    });

    test('Given FireYearlyPoint, When instantiated, Then props are correctly populated and equality works', () {
      const point1 = FireYearlyPoint(
        year: 2030,
        age: 35,
        netWorth: 5000000.0,
        inflationAdjustedFireTarget: 15000000.0,
        annualExpenses: 600000.0,
        passiveIncome: 200000.0,
        coverageRatioPercent: 33.3,
        isFireAchieved: false,
        milestoneOutflows: 50000.0,
      );

      const point2 = FireYearlyPoint(
        year: 2030,
        age: 35,
        netWorth: 5000000.0,
        inflationAdjustedFireTarget: 15000000.0,
        annualExpenses: 600000.0,
        passiveIncome: 200000.0,
        coverageRatioPercent: 33.3,
        isFireAchieved: false,
        milestoneOutflows: 50000.0,
      );

      expect(point1, equals(point2));
      expect(point1.props.length, equals(9));
      expect(point1.milestoneOutflows, equals(50000.0));
    });

    test('Given FireCalculationResult.empty(), When accessed, Then returns default empty zeroed state', () {
      final emptyResult = FireCalculationResult.empty();

      expect(emptyResult.standardFireNumber, equals(0.0));
      expect(emptyResult.leanFireNumber, equals(0.0));
      expect(emptyResult.fatFireNumber, equals(0.0));
      expect(emptyResult.coastFireNumber, equals(0.0));
      expect(emptyResult.baristaFireNumber, equals(0.0));
      expect(emptyResult.annualExpensesToday, equals(0.0));
      expect(emptyResult.fireMultiplier, equals(25.0));
      expect(emptyResult.currentNetWorth, equals(0.0));
      expect(emptyResult.fireReadinessPercent, equals(0.0));
      expect(emptyResult.isFireAchieved, isFalse);
      expect(emptyResult.yearsToFire, equals(0.0));
      expect(emptyResult.fireAge, equals(0.0));
      expect(emptyResult.fireYear, equals(0));
      expect(emptyResult.recommendedSwr, equals(3.50));
      expect(emptyResult.retirementHorizonYears, equals(35));
      expect(emptyResult.preFireMilestones, isEmpty);
      expect(emptyResult.yearlyPoints, isEmpty);
      expect(emptyResult.props.length, equals(17));
    });

    test('Given populated FireCalculationResult, When instantiated, Then props and equality hold', () {
      const milestone = SwpMilestoneExpense(
        id: 'm1',
        name: 'House Upgrade',
        targetAge: 40,
        amount: 2000000.0,
      );

      const result1 = FireCalculationResult(
        standardFireNumber: 15000000.0,
        leanFireNumber: 11250000.0,
        fatFireNumber: 20250000.0,
        coastFireNumber: 4500000.0,
        baristaFireNumber: 9000000.0,
        annualExpensesToday: 600000.0,
        fireMultiplier: 25.0,
        currentNetWorth: 5000000.0,
        fireReadinessPercent: 33.3,
        isFireAchieved: false,
        yearsToFire: 8.5,
        fireAge: 38.5,
        fireYear: 2034,
        recommendedSwr: 3.75,
        retirementHorizonYears: 40,
        preFireMilestones: [milestone],
        yearlyPoints: [],
      );

      const result2 = FireCalculationResult(
        standardFireNumber: 15000000.0,
        leanFireNumber: 11250000.0,
        fatFireNumber: 20250000.0,
        coastFireNumber: 4500000.0,
        baristaFireNumber: 9000000.0,
        annualExpensesToday: 600000.0,
        fireMultiplier: 25.0,
        currentNetWorth: 5000000.0,
        fireReadinessPercent: 33.3,
        isFireAchieved: false,
        yearsToFire: 8.5,
        fireAge: 38.5,
        fireYear: 2034,
        recommendedSwr: 3.75,
        retirementHorizonYears: 40,
        preFireMilestones: [milestone],
        yearlyPoints: [],
      );

      expect(result1, equals(result2));
    });
  });
}
