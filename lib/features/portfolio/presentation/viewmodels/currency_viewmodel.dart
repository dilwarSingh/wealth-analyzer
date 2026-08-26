import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/repositories/portfolio_repository.dart';
import 'portfolio_viewmodel.dart';

final currencyProvider = StateNotifierProvider<CurrencyViewModel, CurrencyType>((ref) {
  final repo = ref.watch(portfolioRepositoryProvider);
  return CurrencyViewModel(repo);
});

class CurrencyViewModel extends StateNotifier<CurrencyType> {
  final PortfolioRepository? _repository;
  bool _isUserModified = false;

  CurrencyViewModel([this._repository]) : super(CurrencyType.inr) {
    _loadStoredCurrency();
  }

  Future<void> _loadStoredCurrency() async {
    if (_repository == null) return;
    try {
      final settings = await _repository!.getUserSettings();
      if (_isUserModified) return;
      final loaded = settings.currencyCode.toUpperCase() == 'USD'
          ? CurrencyType.usd
          : CurrencyType.inr;
      if (mounted) {
        state = loaded;
      }
    } catch (_) {}
  }

  Future<void> toggleCurrency() async {
    _isUserModified = true;
    final next = state == CurrencyType.inr ? CurrencyType.usd : CurrencyType.inr;
    state = next;
    await _persistCurrency(next);
  }

  Future<void> setCurrency(CurrencyType currency) async {
    _isUserModified = true;
    state = currency;
    await _persistCurrency(currency);
  }

  Future<void> _persistCurrency(CurrencyType currency) async {
    if (_repository == null) return;
    try {
      final currentSettings = await _repository!.getUserSettings();
      final code = currency == CurrencyType.usd ? 'USD' : 'INR';
      await _repository!.saveUserSettings(currentSettings.copyWith(currencyCode: code));
    } catch (_) {}
  }
}
