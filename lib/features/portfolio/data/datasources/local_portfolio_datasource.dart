import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/investment_asset_model.dart';
import '../models/user_settings_model.dart';

abstract class LocalPortfolioDataSource {
  Future<List<InvestmentAssetModel>> getStoredAssets();
  Future<void> saveAsset(InvestmentAssetModel asset);
  Future<void> deleteAsset(String id);
  Future<void> saveAllAssets(List<InvestmentAssetModel> assets);
  Future<void> clearAll();
  Future<UserSettingsModel> getUserSettings();
  Future<void> saveUserSettings(UserSettingsModel settings);
}

class HiveLocalPortfolioDataSource implements LocalPortfolioDataSource {
  static const String assetsBoxName = 'wealth_analyzer_assets';
  static const String settingsBoxName = 'wealth_analyzer_settings';

  final Map<String, String> _inMemoryAssetFallback = {};
  UserSettingsModel _inMemorySettingsFallback = const UserSettingsModel();

  Future<Box?> _getAssetsBox() async {
    try {
      if (Hive.isBoxOpen(assetsBoxName)) {
        return Hive.box(assetsBoxName);
      }
      return await Hive.openBox(assetsBoxName);
    } catch (_) {
      return null;
    }
  }

  Future<Box?> _getSettingsBox() async {
    try {
      if (Hive.isBoxOpen(settingsBoxName)) {
        return Hive.box(settingsBoxName);
      }
      return await Hive.openBox(settingsBoxName);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<InvestmentAssetModel>> getStoredAssets() async {
    final box = await _getAssetsBox();
    final List<InvestmentAssetModel> list = [];

    if (box != null) {
      try {
        for (final key in box.keys) {
          final dynamic item = box.get(key);
          if (item != null) {
            if (item is String) {
              try {
                final decoded = jsonDecode(item) as Map<dynamic, dynamic>;
                list.add(InvestmentAssetModel.fromJson(decoded));
              } catch (_) {}
            } else if (item is Map) {
              list.add(InvestmentAssetModel.fromJson(Map<dynamic, dynamic>.from(item)));
            }
          }
        }
        return list;
      } catch (_) {}
    }

    // Fallback to in-memory store
    for (final raw in _inMemoryAssetFallback.values) {
      try {
        final decoded = jsonDecode(raw) as Map<dynamic, dynamic>;
        list.add(InvestmentAssetModel.fromJson(decoded));
      } catch (_) {}
    }
    return list;
  }

  @override
  Future<void> saveAsset(InvestmentAssetModel asset) async {
    final jsonStr = jsonEncode(asset.toJson());
    _inMemoryAssetFallback[asset.id] = jsonStr;

    final box = await _getAssetsBox();
    if (box != null) {
      try {
        await box.put(asset.id, jsonStr);
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteAsset(String id) async {
    _inMemoryAssetFallback.remove(id);
    final box = await _getAssetsBox();
    if (box != null) {
      try {
        await box.delete(id);
      } catch (_) {}
    }
  }

  @override
  Future<void> saveAllAssets(List<InvestmentAssetModel> assets) async {
    _inMemoryAssetFallback.clear();
    final Map<String, String> entries = {};
    for (final asset in assets) {
      final jsonStr = jsonEncode(asset.toJson());
      _inMemoryAssetFallback[asset.id] = jsonStr;
      entries[asset.id] = jsonStr;
    }

    final box = await _getAssetsBox();
    if (box != null) {
      try {
        await box.clear();
        await box.putAll(entries);
      } catch (_) {}
    }
  }

  @override
  Future<void> clearAll() async {
    _inMemoryAssetFallback.clear();
    final box = await _getAssetsBox();
    if (box != null) {
      try {
        await box.clear();
      } catch (_) {}
    }
  }

  @override
  Future<UserSettingsModel> getUserSettings() async {
    final box = await _getSettingsBox();
    if (box != null) {
      try {
        final dynamic raw = box.get('settings');
        if (raw != null) {
          if (raw is String) {
            final decoded = jsonDecode(raw) as Map<dynamic, dynamic>;
            return UserSettingsModel.fromJson(decoded);
          } else if (raw is Map) {
            return UserSettingsModel.fromJson(Map<dynamic, dynamic>.from(raw));
          }
        }
      } catch (_) {}
    }
    return _inMemorySettingsFallback;
  }

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    _inMemorySettingsFallback = settings;
    final box = await _getSettingsBox();
    if (box != null) {
      try {
        await box.put('settings', jsonEncode(settings.toJson()));
      } catch (_) {}
    }
  }
}
