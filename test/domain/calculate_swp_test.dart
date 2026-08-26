import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/domain/usecases/calculate_swp.dart';

void main() {
  group('CalculateSwpUseCase Tests (Given - When - Then - Verify)', () {
    late CalculateSwpUseCase useCase;

    setUp(() {
      useCase = CalculateSwpUseCase();
    });

    test('Given retirement parameters, When execute is called, Then delegates to calculation engine and returns SwpResult', () {
      final result = useCase.execute(
        initialCorpus: 10000000.0,
        initialMonthlyWithdrawal: 40000.0,
        annualReturnPercent: 8.0,
        annualWithdrawalStepUpPercent: 5.0,
        startAge: 55,
        targetEndAge: 85,
      );

      expect(result.yearlyPoints.length, equals(30));
      expect(result.initialCorpus, equals(10000000.0));
      expect(result.totalWithdrawn, greaterThan(0));
      expect(result.totalReturnsEarned, greaterThan(0));
    });
  });
}
