import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ai_settings_repository.dart';
import '../../domain/entities/ai_persona.dart';
import 'ai_settings_viewmodel.dart';

final aiPersonaProvider = StateNotifierProvider<AIPersonaViewModel, AIPersona>((ref) {
  final repo = ref.watch(aiSettingsRepoProvider);
  return AIPersonaViewModel(repo);
});

class AIPersonaViewModel extends StateNotifier<AIPersona> {
  final AISettingsRepository _repo;

  AIPersonaViewModel(this._repo) : super(AIPersona.defaultPersona) {
    _loadPersona();
  }

  Future<void> _loadPersona() async {
    await _repo.init();
    final personaId = _repo.getActivePersonaId();
    state = AIPersona.getById(personaId);
  }

  Future<void> selectPersona(AIPersona persona) async {
    state = persona;
    await _repo.saveActivePersonaId(persona.id);
  }

  Future<void> selectPersonaById(String id) async {
    final persona = AIPersona.getById(id);
    await selectPersona(persona);
  }
}
