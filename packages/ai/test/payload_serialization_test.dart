import 'package:ai/ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenerativeUIPayload Serialization Tests', () {
    test('KpiMetricPayload serializes and deserializes cleanly', () {
      const payload = KpiMetricPayload(
        widgetId: 'kpi_test',
        title: 'Net Worth',
        value: '₹1.5 Cr',
        subtitle: '15 Holdings',
        changePercent: 12.5,
        isPositive: true,
      );

      final json = payload.toJson();
      final restored = GenerativeUIPayload.fromJson(json) as KpiMetricPayload;

      expect(restored.widgetId, 'kpi_test');
      expect(restored.title, 'Net Worth');
      expect(restored.value, '₹1.5 Cr');
      expect(restored.changePercent, 12.5);
      expect(restored.isPositive, true);
    });

    test('MonteCarloCurvePayload serializes and deserializes cleanly', () {
      const payload = MonteCarloCurvePayload(
        widgetId: 'monte_test',
        probabilityOfSuccess: 93.4,
        years: [0, 5, 10, 15, 20],
        p10Curve: [100, 150, 220, 300, 420],
        p50Curve: [100, 180, 300, 500, 800],
        p90Curve: [100, 220, 450, 900, 1800],
        simulationsCount: 1000,
        currencySymbol: '₹',
      );

      final json = payload.toJson();
      final restored = GenerativeUIPayload.fromJson(json) as MonteCarloCurvePayload;

      expect(restored.widgetId, 'monte_test');
      expect(restored.probabilityOfSuccess, 93.4);
      expect(restored.years.length, 5);
      expect(restored.p50Curve.last, 800.0);
    });

    test('ActionConfirmationPayload copyWithApplied updates state', () {
      const payload = ActionConfirmationPayload(
        widgetId: 'act_test',
        actionId: '123',
        actionType: 'addAsset',
        title: 'Add Asset',
        description: 'Testing action',
        assetToAdd: AIAssetEntry(
          id: 'a1',
          name: 'Tesla',
          category: AIAssetCategory.equities,
          currentValue: 50000,
        ),
      );

      expect(payload.isApplied, false);
      final applied = payload.copyWithApplied();
      expect(applied.isApplied, true);
      expect(applied.appliedTimestamp != null, true);
    });
  });
}
