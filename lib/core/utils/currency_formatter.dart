import 'package:intl/intl.dart';

enum CurrencyType {
  inr('₹', 'INR', 'Indian Rupee'),
  usd('\$', 'USD', 'US Dollar'),
  eur('€', 'EUR', 'Euro'),
  gbp('£', 'GBP', 'British Pound');

  final String symbol;
  final String code;
  final String label;

  const CurrencyType(this.symbol, this.code, this.label);
}

class CurrencyFormatter {
  /// Format value with currency symbol and compact notation (Lakhs/Crores for INR, K/M/B for others)
  static String formatCompact(double value, {CurrencyType currency = CurrencyType.inr, bool includeDecimals = true}) {
    if (value.isNaN || value.isInfinite) return '${currency.symbol}0';

    final isNegative = value < 0;
    final absVal = value.abs();
    final sign = isNegative ? '-' : '';

    if (currency == CurrencyType.inr) {
      if (absVal >= 10000000) {
        final cr = absVal / 10000000;
        final decimals = includeDecimals ? (cr >= 100 ? 1 : 2) : 0;
        return '$sign${currency.symbol}${cr.toStringAsFixed(decimals)} Cr';
      } else if (absVal >= 100000) {
        final lk = absVal / 100000;
        final decimals = includeDecimals ? (lk >= 100 ? 1 : 2) : 0;
        return '$sign${currency.symbol}${lk.toStringAsFixed(decimals)} L';
      } else if (absVal >= 1000) {
        final k = absVal / 1000;
        return '$sign${currency.symbol}${k.toStringAsFixed(includeDecimals ? 1 : 0)} K';
      } else {
        return '$sign${currency.symbol}${absVal.toStringAsFixed(0)}';
      }
    } else {
      // USD / Standard International (K, M, B)
      if (absVal >= 1000000000) {
        final b = absVal / 1000000000;
        return '$sign${currency.symbol}${b.toStringAsFixed(includeDecimals ? 2 : 0)} B';
      } else if (absVal >= 1000000) {
        final m = absVal / 1000000;
        return '$sign${currency.symbol}${m.toStringAsFixed(includeDecimals ? 2 : 0)} M';
      } else if (absVal >= 1000) {
        final k = absVal / 1000;
        return '$sign${currency.symbol}${k.toStringAsFixed(includeDecimals ? 1 : 0)} K';
      } else {
        return '$sign${currency.symbol}${absVal.toStringAsFixed(0)}';
      }
    }
  }

  /// Compact denomination without repeating currency symbol (e.g. "1.5 Cr", "45 L", "10 K" / "1.5M", "450K")
  static String formatCompactDenomination(double value, {CurrencyType currency = CurrencyType.inr, bool includeDecimals = true}) {
    if (value.isNaN || value.isInfinite || value == 0) return '';

    final isNegative = value < 0;
    final absVal = value.abs();
    final sign = isNegative ? '-' : '';

    if (currency == CurrencyType.inr) {
      if (absVal >= 10000000) {
        final cr = absVal / 10000000;
        final decimals = includeDecimals ? (cr >= 100 ? 1 : 2) : 0;
        final crStr = cr.toStringAsFixed(decimals).replaceAll(RegExp(r'\.?0+$'), '');
        return '$sign$crStr Cr';
      } else if (absVal >= 100000) {
        final lk = absVal / 100000;
        final decimals = includeDecimals ? (lk >= 100 ? 1 : 2) : 0;
        final lkStr = lk.toStringAsFixed(decimals).replaceAll(RegExp(r'\.?0+$'), '');
        return '$sign$lkStr L';
      } else if (absVal >= 1000) {
        final k = absVal / 1000;
        final kStr = k.toStringAsFixed(includeDecimals ? 1 : 0).replaceAll(RegExp(r'\.?0+$'), '');
        return '$sign$kStr K';
      } else {
        return '$sign${absVal.toStringAsFixed(0)}';
      }
    } else {
      // USD / Standard International (K, M, B)
      if (absVal >= 1000000000) {
        final b = absVal / 1000000000;
        final bStr = b.toStringAsFixed(includeDecimals ? 2 : 0).replaceAll(RegExp(r'\.?0+$'), '');
        return '$sign$bStr B';
      } else if (absVal >= 1000000) {
        final m = absVal / 1000000;
        final mStr = m.toStringAsFixed(includeDecimals ? 2 : 0).replaceAll(RegExp(r'\.?0+$'), '');
        return '$sign$mStr M';
      } else if (absVal >= 1000) {
        final k = absVal / 1000;
        final kStr = k.toStringAsFixed(includeDecimals ? 1 : 0).replaceAll(RegExp(r'\.?0+$'), '');
        return '$sign$kStr K';
      } else {
        return '$sign${absVal.toStringAsFixed(0)}';
      }
    }
  }

  /// Full exact currency string with commas
  static String formatFull(double value, {CurrencyType currency = CurrencyType.inr, bool showDecimals = false}) {
    if (value.isNaN || value.isInfinite) return '${currency.symbol}0';

    final isNegative = value < 0;
    final absVal = value.abs();
    final sign = isNegative ? '-' : '';

    if (currency == CurrencyType.inr) {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '',
        decimalDigits: showDecimals ? 2 : 0,
      );
      return '$sign${currency.symbol}${formatter.format(absVal).trim()}';
    } else {
      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: '',
        decimalDigits: showDecimals ? 2 : 0,
      );
      return '$sign${currency.symbol}${formatter.format(absVal).trim()}';
    }
  }

  /// Percentage formatting (e.g. +14.2% or -3.5%)
  static String formatPercent(double percent, {bool includeSign = true, int decimals = 1}) {
    if (percent.isNaN || percent.isInfinite) return '0.0%';
    final sign = (percent > 0 && includeSign) ? '+' : '';
    return '$sign${percent.toStringAsFixed(decimals)}%';
  }
}
