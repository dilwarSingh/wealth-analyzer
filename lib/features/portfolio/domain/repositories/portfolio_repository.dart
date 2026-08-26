import '../../data/models/user_settings_model.dart';
import '../entities/investment_asset.dart';

abstract class PortfolioRepository {
  /// Stream or load all active investment assets
  Future<List<InvestmentAsset>> getAssets();

  /// Save or update an asset
  Future<void> saveAsset(InvestmentAsset asset);

  /// Delete an asset by ID
  Future<void> deleteAsset(String id);

  /// Bulk replace or import assets (for sample data presets & backup restore)
  Future<void> setAssets(List<InvestmentAsset> assets);

  /// Clear all portfolio data
  Future<void> clearAll();

  /// Load user settings (simulator parameters & currency)
  Future<UserSettingsModel> getUserSettings();

  /// Save user settings (simulator parameters & currency)
  Future<void> saveUserSettings(UserSettingsModel settings);
}
