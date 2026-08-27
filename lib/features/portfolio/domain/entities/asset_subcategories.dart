import 'asset_category.dart';

/// Predefined and hierarchical subcategories for each AssetCategory.
class AssetSubcategories {
  /// Mutual Funds 2-Tier Hierarchy: Level 1 (Class) -> List of Level 2 (Subcategories)
  static const Map<String, List<String>> mutualFundHierarchy = {
    'Equity': [
      'Flexi Cap',
      'Large Cap',
      'Mid Cap',
      'Small Cap',
      'Multi Cap',
      'Large & Mid Cap',
      'ELSS / Tax Saver',
      'Sectoral / Thematic',
      'Focused Fund',
      'Value / Contra',
      'Other',
    ],
    'Debt': [
      'Liquid / Overnight',
      'Money Market',
      'Ultra Short / Low Duration',
      'Short Duration',
      'Medium to Long Duration',
      'Corporate Bond',
      'Banking & PSU',
      'Gilt / G-Sec',
      'Credit Risk',
      'Other',
    ],
    'Hybrid': [
      'Aggressive Hybrid',
      'Conservative Hybrid',
      'Balanced Advantage (BAF)',
      'Arbitrage Fund',
      'Multi Asset Allocation',
      'Equity Savings',
      'Other',
    ],
    'Index / ETF': [
      'Nifty 50 / Sensex Index',
      'Nifty Next 50',
      'Midcap / Smallcap Index',
      'Target Maturity Index',
      'International / Global ETF',
      'Commodity / Gold ETF',
      'Other',
    ],
    'Solution Oriented': [
      'Retirement Fund',
      "Children's Fund",
      'Other',
    ],
    'Other': [],
  };

  /// Single-tier preset subcategories for all other AssetCategories.
  static const Map<AssetCategory, List<String>> singleTierPresets = {
    AssetCategory.equities: [
      'Large Cap Bluechip',
      'Mid Cap Growth',
      'Small Cap',
      'Dividend Yield',
      'International / US Stocks',
      'Sectoral / Thematic',
      'Penny / Microcap',
      'Other',
    ],
    AssetCategory.realEstate: [
      'Residential Flat / Apartment',
      'Independent House / Villa',
      'Residential Plot / Land',
      'Commercial Office / Retail',
      'Agricultural Land',
      'Real Estate Investment Trust (REIT)',
      'Industrial / Warehouse',
      'Other',
    ],
    AssetCategory.goldPrecious: [
      'Physical Gold (Coins / Bars)',
      'Gold ETFs / SGB (Sovereign Gold Bonds)',
      'Digital Gold',
      'Physical Silver (Bars / Utensils)',
      'Silver ETFs',
      'Platinum',
      'Precious Jewelry',
      'Other',
    ],
    AssetCategory.fixedDeposit: [
      'Bank Fixed Deposit (FD)',
      'Corporate / NBFC FD',
      'Recurring Deposit (RD)',
      'Post Office Small Savings (TD/MIS)',
      'Senior Citizens Savings Scheme (SCSS)',
      'National Savings Certificate (NSC)',
      'Public Provident Fund (PPF)',
      'Other',
    ],
    AssetCategory.cashSavings: [
      'Savings Bank Account',
      'Emergency Liquid Fund',
      'Cash in Hand / Wallet',
      'Current / Business Account',
      'Sweep-in / Auto-sweep Account',
      'Other',
    ],
    AssetCategory.crypto: [
      'Layer 1 (BTC, ETH, SOL)',
      'Layer 2 & Scaling',
      'DeFi / Altcoins',
      'Stablecoins (USDT, USDC)',
      'NFTs & Web3 Assets',
      'Crypto ETF',
      'Other',
    ],
    AssetCategory.other: [
      'Venture / Angel Investment',
      'P2P Lending',
      'Collectibles & Art',
      'Annuity / Pension Scheme',
      'Private Equity',
      'Other',
    ],
  };

  /// Retrieves the list of subcategories for a given category.
  static List<String> getPresetsForCategory(AssetCategory category) {
    return singleTierPresets[category] ?? ['Other'];
  }

  /// Formats Mutual Fund 2-tier selection into a uniform display string.
  static String formatMutualFundSubcategory(String group, String? subSubCategory, {String? customText}) {
    if (group == 'Other') {
      return (customText != null && customText.trim().isNotEmpty) ? customText.trim() : 'Other';
    }
    if (subSubCategory == null || subSubCategory.isEmpty) {
      return group;
    }
    if (subSubCategory == 'Other') {
      if (customText != null && customText.trim().isNotEmpty) {
        return '$group: ${customText.trim()}';
      }
      return '$group: Other';
    }
    return '$group: $subSubCategory';
  }
}
