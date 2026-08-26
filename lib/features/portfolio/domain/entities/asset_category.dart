import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum AssetCategory {
  equities('Stocks/Equities', AppColors.catEquities, Icons.trending_up_rounded),
  mutualFunds('Mutual Funds/ETFs', AppColors.catMutualFunds, Icons.pie_chart_rounded),
  realEstate('Real Estate', AppColors.catRealEstate, Icons.apartment_rounded),
  crypto('Crypto', AppColors.catCrypto, Icons.currency_bitcoin_rounded),
  fixedDeposit('FD/RD', AppColors.catFixedDeposit, Icons.account_balance_rounded),
  cashSavings('Cash & Savings', AppColors.catCashSavings, Icons.savings_rounded),
  goldPrecious('Gold/Precious Metals', AppColors.catGoldPrecious, Icons.workspace_premium_rounded),
  other('Other', AppColors.catOther, Icons.category_rounded);

  final String label;
  final Color color;
  final IconData icon;

  const AssetCategory(this.label, this.color, this.icon);

  static AssetCategory fromString(String val) {
    for (final cat in AssetCategory.values) {
      if (cat.name.toLowerCase() == val.toLowerCase() ||
          cat.label.toLowerCase() == val.toLowerCase()) {
        return cat;
      }
    }
    return AssetCategory.other;
  }
}
