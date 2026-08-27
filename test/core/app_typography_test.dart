import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/constants/app_colors.dart';
import 'package:wealth_projector/core/constants/app_typography.dart';

void main() {
  group('AppTypography Tests (Given - When - Then - Verify)', () {
    test('Given AppTypography styles, When accessed, Then returns configured fonts and weights', () {
      expect(AppTypography.heading1.fontSize, equals(28));
      expect(AppTypography.heading1.fontWeight, equals(FontWeight.w700));
      expect(AppTypography.heading1.color, equals(AppColors.textPrimary));

      expect(AppTypography.heading2.fontSize, equals(22));
      expect(AppTypography.heading2.fontWeight, equals(FontWeight.w600));

      expect(AppTypography.heading3.fontSize, equals(18));
      expect(AppTypography.heading3.fontWeight, equals(FontWeight.w600));

      expect(AppTypography.bodyLarge.fontSize, equals(16));
      expect(AppTypography.bodyLarge.fontWeight, equals(FontWeight.w400));

      expect(AppTypography.bodyMedium.fontSize, equals(14));
      expect(AppTypography.bodyMedium.fontWeight, equals(FontWeight.w400));

      expect(AppTypography.bodySmall.fontSize, equals(12));
      expect(AppTypography.bodySmall.fontWeight, equals(FontWeight.w400));

      expect(AppTypography.label.fontSize, equals(11));
      expect(AppTypography.label.fontWeight, equals(FontWeight.w600));

      expect(AppTypography.currencyLarge.fontSize, equals(32));
      expect(AppTypography.currencyLarge.fontWeight, equals(FontWeight.w700));

      expect(AppTypography.currencyMedium.fontSize, equals(20));
      expect(AppTypography.currencyMedium.fontWeight, equals(FontWeight.w700));

      expect(AppTypography.currencySmall.fontSize, equals(15));
      expect(AppTypography.currencySmall.fontWeight, equals(FontWeight.w600));

      expect(AppTypography.buttonText.fontSize, equals(14));
      expect(AppTypography.buttonText.fontWeight, equals(FontWeight.w600));
      expect(AppTypography.buttonText.color, equals(Colors.white));
    });
  });
}
