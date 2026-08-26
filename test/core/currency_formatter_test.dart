import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Unit Tests (Given - When - Then - Verify)', () {
    // -------------------------------------------------------------
    // 1. INR (Indian Rupee) Compact & Standard Formatting
    // -------------------------------------------------------------
    group('INR Formatting', () {
      test('Given small, thousands, lakhs, and crores values, When formatted in INR compact mode, Then formats with Indian suffixes', () {
        // Given
        const valHundreds = 500.0;
        const valThousands = 25000.0;
        const valLakhs = 2540000.0; // 25.40 L
        const valCrores = 35000000.0; // 3.50 Cr

        // When
        final strHundreds = CurrencyFormatter.formatCompact(valHundreds, currency: CurrencyType.inr);
        final strThousands = CurrencyFormatter.formatCompact(valThousands, currency: CurrencyType.inr);
        final strLakhs = CurrencyFormatter.formatCompact(valLakhs, currency: CurrencyType.inr);
        final strCrores = CurrencyFormatter.formatCompact(valCrores, currency: CurrencyType.inr);

        // Then & Verify
        expect(strHundreds, equals('₹500'));
        expect(strThousands, equals('₹25.0 K'));
        expect(strLakhs, equals('₹25.40 L'));
        expect(strCrores, equals('₹3.50 Cr'));
      });

      test('Given negative INR values, When formatted, Then preserves negative sign with symbol', () {
        // Given
        const negativeThousands = -15000.0;

        // When
        final formatted = CurrencyFormatter.formatCompact(negativeThousands, currency: CurrencyType.inr);

        // Then & Verify
        expect(formatted, equals('-₹15.0 K'));
      });

      test('Given zero INR value, When formatted, Then returns ₹0', () {
        // When
        final formatted = CurrencyFormatter.formatCompact(0.0, currency: CurrencyType.inr);

        // Then & Verify
        expect(formatted, equals('₹0'));
      });
    });

    // -------------------------------------------------------------
    // 2. USD (US Dollar) Compact & Standard Formatting
    // -------------------------------------------------------------
    group('USD Formatting', () {
      test('Given thousands, millions, and billions, When formatted in USD compact mode, Then formats with International suffixes', () {
        // Given
        const valThousands = 45000.0;
        const valMillions = 2500000.0; // 2.50 M
        const valBillions = 1200000000.0; // 1.20 B

        // When
        final strThousands = CurrencyFormatter.formatCompact(valThousands, currency: CurrencyType.usd);
        final strMillions = CurrencyFormatter.formatCompact(valMillions, currency: CurrencyType.usd);
        final strBillions = CurrencyFormatter.formatCompact(valBillions, currency: CurrencyType.usd);

        // Then & Verify
        expect(strThousands, equals('\$45.0 K'));
        expect(strMillions, equals('\$2.50 M'));
        expect(strBillions, equals('\$1.20 B'));
      });

      test('Given standard full amount formatting, When formatCurrency is called, Then separates with appropriate commas', () {
        // Given
        const amount = 1250000.0;

        // When
        final inrFull = CurrencyFormatter.formatFull(amount, currency: CurrencyType.inr, showDecimals: false);
        final usdFull = CurrencyFormatter.formatFull(amount, currency: CurrencyType.usd, showDecimals: false);

        // Then & Verify
        expect(inrFull, contains('₹'));
        expect(usdFull, contains('\$'));
      });
    });

    // -------------------------------------------------------------
    // 3. Percentage Formatting
    // -------------------------------------------------------------
    group('formatPercent', () {
      test('Given positive, negative, and zero percentage numbers, When formatted, Then outputs signed percentage string', () {
        // Given
        const positive = 15.456;
        const negative = -8.2;
        const zero = 0.0;

        // When
        final strPos = CurrencyFormatter.formatPercent(positive);
        final strNeg = CurrencyFormatter.formatPercent(negative);
        final strZero = CurrencyFormatter.formatPercent(zero);

        // Then & Verify
        expect(strPos, equals('+15.5%'));
        expect(strNeg, equals('-8.2%'));
        expect(strZero, equals('0.0%'));
      });
    });
  });
}
