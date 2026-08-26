import 'package:uuid/uuid.dart';
import '../entities/asset_category.dart';
import '../entities/investment_asset.dart';
import '../repositories/portfolio_repository.dart';

class ManageAssetsUseCase {
  final PortfolioRepository repository;

  ManageAssetsUseCase(this.repository);

  Future<List<InvestmentAsset>> getAssets() => repository.getAssets();

  Future<void> addOrUpdateAsset(InvestmentAsset asset) async {
    final effectiveAsset = asset.id.isEmpty
        ? asset.copyWith(id: const Uuid().v4())
        : asset;
    await repository.saveAsset(effectiveAsset);
  }

  Future<void> deleteAsset(String id) => repository.deleteAsset(id);

  Future<void> clearAll() => repository.clearAll();

  Future<void> loadSamplePortfolio(String presetType) async {
    List<InvestmentAsset> sampleAssets;
    final now = DateTime.now();

    switch (presetType) {
      case 'aggressive':
        sampleAssets = [
          InvestmentAsset(
            id: const Uuid().v4(),
            name: 'US Tech Index & Nasdaq ETF',
            category: AssetCategory.equities,
            type: InvestmentType.monthlySip,
            investedAmount: 25000,
            currentValue: 350000,
            startDate: now.subtract(const Duration(days: 365)),
            expectedCAGR: 16.0,
            stepUpRate: 10.0,
          ),
          InvestmentAsset(
            id: const Uuid().v4(),
            name: 'Nifty 50 Bluechip SIP',
            category: AssetCategory.mutualFunds,
            type: InvestmentType.monthlySip,
            investedAmount: 20000,
            currentValue: 280000,
            startDate: now.subtract(const Duration(days: 300)),
            expectedCAGR: 13.5,
            stepUpRate: 10.0,
          ),
          InvestmentAsset(
            id: const Uuid().v4(),
            name: 'Bitcoin & Top Crypto Fund',
            category: AssetCategory.crypto,
            type: InvestmentType.oneTime,
            investedAmount: 100000,
            currentValue: 180000,
            startDate: now.subtract(const Duration(days: 200)),
            expectedCAGR: 20.0,
            stepUpRate: 0.0,
          ),
          InvestmentAsset(
            id: const Uuid().v4(),
            name: 'Emergency Reserve in Liquid Fund',
            category: AssetCategory.cashSavings,
            type: InvestmentType.oneTime,
            investedAmount: 150000,
            currentValue: 155000,
            startDate: now.subtract(const Duration(days: 150)),
            expectedCAGR: 6.5,
            stepUpRate: 0.0,
          ),
        ];
        break;

      case 'balanced':
      default:
        sampleAssets = [
          InvestmentAsset(
            id: const Uuid().v4(),
            name: 'Nifty 50 & Large Cap Index SIP',
            category: AssetCategory.mutualFunds,
            type: InvestmentType.monthlySip,
            investedAmount: 20000,
            currentValue: 420000,
            startDate: now.subtract(const Duration(days: 500)),
            expectedCAGR: 12.5,
            stepUpRate: 10.0,
          ),
          InvestmentAsset(
            id: const Uuid().v4(),
            name: 'Mid & Small Cap Growth SIP',
            category: AssetCategory.equities,
            type: InvestmentType.monthlySip,
            investedAmount: 15000,
            currentValue: 310000,
            startDate: now.subtract(const Duration(days: 400)),
            expectedCAGR: 15.0,
            stepUpRate: 10.0,
          ),
          InvestmentAsset(
            id: const Uuid().v4(),
            name: 'Sovereign Gold Bonds & Digital Gold',
            category: AssetCategory.goldPrecious,
            type: InvestmentType.oneTime,
            investedAmount: 120000,
            currentValue: 165000,
            startDate: now.subtract(const Duration(days: 600)),
            expectedCAGR: 10.0,
            stepUpRate: 0.0,
          ),
          InvestmentAsset(
            id: const Uuid().v4(),
            name: 'Rental Real Estate REITs',
            category: AssetCategory.realEstate,
            type: InvestmentType.oneTime,
            investedAmount: 250000,
            currentValue: 290000,
            startDate: now.subtract(const Duration(days: 350)),
            expectedCAGR: 9.0,
            stepUpRate: 0.0,
          ),
          InvestmentAsset(
            id: const Uuid().v4(),
            name: 'Emergency Fund & Cash Reserve',
            category: AssetCategory.cashSavings,
            type: InvestmentType.oneTime,
            investedAmount: 200000,
            currentValue: 210000,
            startDate: now.subtract(const Duration(days: 200)),
            expectedCAGR: 6.5,
            stepUpRate: 0.0,
          ),
        ];
        break;
    }

    await repository.setAssets(sampleAssets);
  }
}
