import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/ai_session_repository.dart';
import '../../domain/entities/chat_session.dart';

final aiSessionRepoProvider = Provider<AISessionRepository>((ref) {
  final repo = AISessionRepository();
  repo.init();
  return repo;
});

class AISessionState {
  final List<ChatSession> sessions;
  final String activeSessionId;
  final bool isLoading;

  const AISessionState({
    this.sessions = const [],
    this.activeSessionId = 'default',
    this.isLoading = false,
  });

  ChatSession? get activeSession {
    return sessions.firstWhere(
      (s) => s.id == activeSessionId,
      orElse: () => sessions.isNotEmpty
          ? sessions.first
          : ChatSession(
              id: 'default',
              title: 'Wealth Advisor Chat',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
    );
  }

  AISessionState copyWith({
    List<ChatSession>? sessions,
    String? activeSessionId,
    bool? isLoading,
  }) {
    return AISessionState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final aiSessionProvider = StateNotifierProvider<AISessionViewModel, AISessionState>((ref) {
  final repo = ref.watch(aiSessionRepoProvider);
  return AISessionViewModel(repo);
});

class AISessionViewModel extends StateNotifier<AISessionState> {
  final AISessionRepository _repo;
  final _uuid = const Uuid();

  AISessionViewModel(this._repo) : super(const AISessionState()) {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    state = state.copyWith(isLoading: true);
    await _repo.init();
    var sessions = _repo.getAllSessions();
    if (sessions.isEmpty) {
      final initialSession = ChatSession(
        id: _uuid.v4(),
        title: 'Initial Wealth Audit',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repo.saveSession(initialSession);
      sessions = [initialSession];
    }
    state = state.copyWith(
      sessions: sessions,
      activeSessionId: sessions.first.id,
      isLoading: false,
    );
  }

  Future<ChatSession> createNewSession({String title = 'New Advisory Session', String personaId = 'fire_planner'}) async {
    final newSession = ChatSession(
      id: _uuid.v4(),
      title: title,
      personaId: personaId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.saveSession(newSession);
    final updated = [newSession, ...state.sessions];
    state = state.copyWith(sessions: updated, activeSessionId: newSession.id);
    return newSession;
  }

  void selectSession(String sessionId) {
    state = state.copyWith(activeSessionId: sessionId);
  }

  Future<void> updateSession(ChatSession session) async {
    await _repo.saveSession(session);
    final updated = state.sessions.map((s) => s.id == session.id ? session : s).toList();
    state = state.copyWith(sessions: updated);
  }

  Future<void> deleteSession(String sessionId) async {
    await _repo.deleteSession(sessionId);
    final remaining = state.sessions.where((s) => s.id != sessionId).toList();
    if (remaining.isEmpty) {
      final fresh = ChatSession(
        id: _uuid.v4(),
        title: 'Wealth Advisory Chat',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repo.saveSession(fresh);
      state = state.copyWith(sessions: [fresh], activeSessionId: fresh.id);
    } else {
      final nextActive = state.activeSessionId == sessionId ? remaining.first.id : state.activeSessionId;
      state = state.copyWith(sessions: remaining, activeSessionId: nextActive);
    }
  }
}
