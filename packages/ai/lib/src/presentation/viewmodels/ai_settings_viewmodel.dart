import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ai_settings_repository.dart';
import '../../data/services/ai_provider_bridge.dart';
import '../../domain/entities/ai_config.dart';

final aiSettingsRepoProvider = Provider<AISettingsRepository>((ref) {
  final repo = AISettingsRepository();
  repo.init();
  return repo;
});

final aiSettingsProvider = StateNotifierProvider<AISettingsViewModel, AIConfig>((ref) {
  final repo = ref.watch(aiSettingsRepoProvider);
  return AISettingsViewModel(repo);
});

class AISettingsViewModel extends StateNotifier<AIConfig> {
  final AISettingsRepository _repo;
  final AIProviderBridge _bridge = AIProviderBridge();

  AISettingsViewModel(this._repo) : super(const AIConfig()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _repo.init();
    state = _repo.getConfig();
  }

  Future<void> updateConfig(AIConfig config) async {
    state = config;
    await _repo.saveConfig(config);
  }

  Future<void> setProvider(AIProviderType provider) async {
    final updated = state.copyWith(
      provider: provider,
      baseUrl: provider.defaultBaseUrl,
      modelName: provider.defaultModels.first,
    );
    await updateConfig(updated);
  }

  Future<void> setApiKey(String key) async {
    await updateConfig(state.copyWith(apiKey: key));
  }

  Future<void> setBaseUrl(String url) async {
    await updateConfig(state.copyWith(baseUrl: url));
  }

  Future<void> setModelName(String model) async {
    await updateConfig(state.copyWith(modelName: model));
  }

  Future<void> setPrivacyMode(ContextPrivacyMode mode) async {
    await updateConfig(state.copyWith(privacyMode: mode));
  }

  Future<void> toggleAnonymizeValues(bool anonymize) async {
    await updateConfig(state.copyWith(anonymizeValues: anonymize));
  }

  Future<void> toggleAutoShowPrivacyDialog(bool autoShow) async {
    await updateConfig(state.copyWith(autoShowPrivacyDialog: autoShow));
  }

  Future<bool> testConnection() async {
    return _bridge.testConnection(state);
  }
}
