import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_projector/core/utils/currency_formatter.dart';
import 'package:wealth_projector/features/portfolio/data/models/user_settings_model.dart';
import 'package:wealth_projector/features/portfolio/domain/entities/investment_asset.dart';
import 'package:wealth_projector/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:wealth_projector/features/portfolio/presentation/viewmodels/currency_viewmodel.dart';

class MockCurrencyRepository implements PortfolioRepository {
  UserSettingsModel settings;

  MockCurrencyRepository({this.settings = const UserSettingsModel()});

  @override
  Future<List<InvestmentAsset>> getAssets() async => [];
  @override
  Future<void> saveAsset(InvestmentAsset asset) async {}
  @override
  Future<void> setAssets(List<InvestmentAsset> assets) async {}
  @override
  Future<void> deleteAsset(String id) async {}
  @override
  Future<void> clearAll() async {}
  @override
  Future<UserSettingsModel> getUserSettings() async => settings;
  @override
  Future<void> saveUserSettings(UserSettingsModel s) async {
    settings = s;
  }
}

void main() {
  group('CurrencyViewModel Tests (Given - When - Then - Verify)', () {
    test('Given default state without repo, When initialized, Then starts with INR currency', () {
      final viewModel = CurrencyViewModel();
      expect(viewModel.state, equals(CurrencyType.inr));
      expect(viewModel.state.symbol, equals('₹'));
    });

    test('Given INR currency, When toggleCurrency is called, Then switches to USD and persists preference', () async {
      final repo = MockCurrencyRepository();
      final viewModel = CurrencyViewModel(repo);

      // When: First toggle
      await viewModel.toggleCurrency();

      // Then & Verify: USD
      expect(viewModel.state, equals(CurrencyType.usd));
      expect(viewModel.state.symbol, equals('\$'));
      expect(repo.settings.currencyCode, equals('USD'));

      // When: Second toggle
      await viewModel.toggleCurrency();

      // Then & Verify: INR
      expect(viewModel.state, equals(CurrencyType.inr));
      expect(repo.settings.currencyCode, equals('INR'));
    });

    test('Given stored USD currency preference, When CurrencyViewModel is initialized, Then restores USD state', () async {
      final repo = MockCurrencyRepository(
        settings: const UserSettingsModel(currencyCode: 'USD'),
      );
      final viewModel = CurrencyViewModel(repo);

      // Allow async _loadStoredCurrency to finish
      await Future.delayed(const Duration(milliseconds: 10));

      // Then & Verify
      expect(viewModel.state, equals(CurrencyType.usd));
    });

    test('Given CurrencyViewModel, When setCurrency is explicitly called, Then sets exact currency type and saves setting', () async {
      final repo = MockCurrencyRepository();
      final viewModel = CurrencyViewModel(repo);

      // When
      await viewModel.setCurrency(CurrencyType.usd);

      // Then & Verify
      expect(viewModel.state, equals(CurrencyType.usd));
      expect(repo.settings.currencyCode, equals('USD'));
    });
  });
}
