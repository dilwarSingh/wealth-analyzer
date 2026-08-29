import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/ai_config.dart';

/// Repository for persistent storage of AI credentials, endpoints, and privacy settings in Hive
class AISettingsRepository {
  static const String boxName = 'ai_settings_box';
  static const String configKey = 'active_ai_config';
  static const String personaKey = 'active_persona_id';

  Box? _box;

  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(boxName);
    }
  }

  AIConfig getConfig() {
    if (_box == null || !_box!.isOpen) return const AIConfig();
    final raw = _box!.get(configKey);
    if (raw == null) return const AIConfig();
    try {
      if (raw is String) {
        return AIConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } else if (raw is Map) {
        return AIConfig.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
    return const AIConfig();
  }

  Future<void> saveConfig(AIConfig config) async {
    await init();
    await _box!.put(configKey, jsonEncode(config.toJson()));
  }

  String getActivePersonaId() {
    if (_box == null || !_box!.isOpen) return 'fire_planner';
    return _box!.get(personaKey, defaultValue: 'fire_planner') as String;
  }

  Future<void> saveActivePersonaId(String personaId) async {
    await init();
    await _box!.put(personaKey, personaId);
  }
}
