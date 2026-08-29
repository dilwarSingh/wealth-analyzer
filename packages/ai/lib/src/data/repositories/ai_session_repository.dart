import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/chat_session.dart';

/// Repository for persistent storage of multi-session chat threads in Hive
class AISessionRepository {
  static const String boxName = 'ai_chat_sessions_box';
  Box? _box;

  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(boxName);
    }
  }

  List<ChatSession> getAllSessions() {
    if (_box == null || !_box!.isOpen) return [];
    final sessions = <ChatSession>[];
    for (final key in _box!.keys) {
      final raw = _box!.get(key);
      if (raw == null) continue;
      try {
        if (raw is String) {
          sessions.add(ChatSession.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        } else if (raw is Map) {
          sessions.add(ChatSession.fromJson(Map<String, dynamic>.from(raw)));
        }
      } catch (_) {}
    }
    // Sort latest updated first
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  ChatSession? getSession(String id) {
    if (_box == null || !_box!.isOpen) return null;
    final raw = _box!.get(id);
    if (raw == null) return null;
    try {
      if (raw is String) {
        return ChatSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } else if (raw is Map) {
        return ChatSession.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveSession(ChatSession session) async {
    await init();
    await _box!.put(session.id, jsonEncode(session.toJson()));
  }

  Future<void> deleteSession(String id) async {
    await init();
    await _box!.delete(id);
  }
}
