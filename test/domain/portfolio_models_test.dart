import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/features/portfolio/data/models/investment_asset_model.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/asset_category.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';

void main() {
  group('Portfolio Models & Serialization Tests (Given - When - Then - Verify)', () {
    // -------------------------------------------------------------
    // 1. InvestmentAssetModel Serialization & Mapping
    // -------------------------------------------------------------
    group('InvestmentAssetModel', () {
      test('Given valid InvestmentAsset entity, When converted to Model and JSON and back, Then preserves all fields', () {
        // Given
        final date = DateTime(2025, 6, 15, 10, 30);
        final originalEntity = InvestmentAsset(
          id: 'asset-test-1',
          name: 'Nifty 50 Index',
          category: AssetCategory.mutualFunds,
          type: InvestmentType.monthlySip,
          investedAmount: 15000.0,
          currentValue: 45000.0,
          startDate: date,
          expectedCAGR: 13.5,
          stepUpRate: 10.0,
        );

        // When
        final model = InvestmentAssetModel.fromEntity(originalEntity);
        final jsonMap = model.toJson();
        final reconstructedModel = InvestmentAssetModel.fromJson(jsonMap);
        final reconstructedEntity = reconstructedModel.toEntity();

        // Then & Verify
        expect(reconstructedEntity.id, equals(originalEntity.id));
        expect(reconstructedEntity.name, equals(originalEntity.name));
        expect(reconstructedEntity.category, equals(AssetCategory.mutualFunds));
        expect(reconstructedEntity.type, equals(InvestmentType.monthlySip));
        expect(reconstructedEntity.investedAmount, equals(15000.0));
        expect(reconstructedEntity.currentValue, equals(45000.0));
        expect(reconstructedEntity.expectedCAGR, equals(13.5));
        expect(reconstructedEntity.stepUpRate, equals(10.0));
        expect(reconstructedEntity.startDate.year, equals(2025));
      });

      test('Given incomplete or corrupted JSON map, When parsed with fromJson, Then falls back to safe default values', () {
        // Given
        final emptyJson = <String, dynamic>{};

        // When
        final fallbackModel = InvestmentAssetModel.fromJson(emptyJson);
        final fallbackEntity = fallbackModel.toEntity();

        // Then & Verify
        expect(fallbackEntity.id, isEmpty);
        expect(fallbackEntity.name, isEmpty);
        expect(fallbackEntity.category, equals(AssetCategory.other));
        expect(fallbackEntity.type, equals(InvestmentType.oneTime));
        expect(fallbackEntity.investedAmount, equals(0.0));
        expect(fallbackEntity.currentValue, equals(0.0));
        expect(fallbackEntity.expectedCAGR, equals(10.0));
      });
    });

    // -------------------------------------------------------------
    // 2. UserSettingsModel Serialization & CopyWith
    // -------------------------------------------------------------
    group('UserSettingsModel', () {
      test('Given UserSettingsModel with custom attributes, When serialized and deserialized, Then preserves user configuration', () {
        // Given
        const settings = UserSettingsModel(
          currentAge: 32,
          targetRetirementAge: 58,
          inflationRate: 7.0,
          globalStepUpRate: 12.0,
          currencyCode: 'USD',
          hasSeenOnboarding: true,
        );

        // When
        final json = settings.toJson();
        final parsed = UserSettingsModel.fromJson(json);

        // Then & Verify
        expect(parsed.currentAge, equals(32));
        expect(parsed.targetRetirementAge, equals(58));
        expect(parsed.inflationRate, equals(7.0));
        expect(parsed.globalStepUpRate, equals(12.0));
        expect(parsed.currencyCode, equals('USD'));
        expect(parsed.hasSeenOnboarding, isTrue);
      });

      test('Given default UserSettingsModel, When copyWith is used, Then produces clean modified clone', () {
        // Given
        const initial = UserSettingsModel();

        // When
        final updated = initial.copyWith(
          currentAge: 30,
          currencyCode: 'INR',
        );

        // Then & Verify
        expect(updated.currentAge, equals(30));
        expect(updated.currencyCode, equals('INR'));
        expect(updated.targetRetirementAge, equals(initial.targetRetirementAge));
        expect(updated.inflationRate, equals(initial.inflationRate));
      });
    });

    // -------------------------------------------------------------
    // 3. AssetCategory Enums & String Mapping
    // -------------------------------------------------------------
    group('AssetCategory Mapping', () {
      test('Given string names, When fromString is called, Then maps to correct category or falls back to other', () {
        // When & Then & Verify
        expect(AssetCategory.fromString('equities'), equals(AssetCategory.equities));
        expect(AssetCategory.fromString('mutualFunds'), equals(AssetCategory.mutualFunds));
        expect(AssetCategory.fromString('realEstate'), equals(AssetCategory.realEstate));
        expect(AssetCategory.fromString('crypto'), equals(AssetCategory.crypto));
        expect(AssetCategory.fromString('fixedDeposit'), equals(AssetCategory.fixedDeposit));
        expect(AssetCategory.fromString('cashSavings'), equals(AssetCategory.cashSavings));
        expect(AssetCategory.fromString('goldPrecious'), equals(AssetCategory.goldPrecious));
        expect(AssetCategory.fromString('unknown_category'), equals(AssetCategory.other));
      });
    });
  });
}
