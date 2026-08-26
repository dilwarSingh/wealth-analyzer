import '../../domain/entities/investment_asset.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../datasources/local_portfolio_datasource.dart';
import '../models/investment_asset_model.dart';
import '../models/user_settings_model.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  final LocalPortfolioDataSource localDataSource;

  PortfolioRepositoryImpl({required this.localDataSource});

  @override
  Future<List<InvestmentAsset>> getAssets() async {
    final models = await localDataSource.getStoredAssets();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveAsset(InvestmentAsset asset) async {
    final model = InvestmentAssetModel.fromEntity(asset);
    await localDataSource.saveAsset(model);
  }

  @override
  Future<void> deleteAsset(String id) async {
    await localDataSource.deleteAsset(id);
  }

  @override
  Future<void> setAssets(List<InvestmentAsset> assets) async {
    final models = assets.map((a) => InvestmentAssetModel.fromEntity(a)).toList();
    await localDataSource.saveAllAssets(models);
  }

  @override
  Future<void> clearAll() async {
    await localDataSource.clearAll();
  }

  @override
  Future<UserSettingsModel> getUserSettings() async {
    return await localDataSource.getUserSettings();
  }

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await localDataSource.saveUserSettings(settings);
  }
}
