import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/chat_session.dart';

/// Repository for persistent storage of multi-session chat threads in Hive with in-memory test fallback
class AISessionRepository {
  static const String boxName = 'ai_chat_sessions_box';
  Box? _box;
  final Map<String, ChatSession> _inMemorySessions = {};

  Future<void> init() async {
    try {
      if (_box == null || !_box!.isOpen) {
        _box = await Hive.openBox(boxName);
      }
    } catch (_) {
      // In widget tests where Hive.init() is not invoked, safely fallback to in-memory store
    }
  }

  List<ChatSession> getAllSessions() {
    if (_box != null && _box!.isOpen) {
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
    final memList = _inMemorySessions.values.toList();
    memList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return memList;
  }

  ChatSession? getSession(String id) {
    if (_box != null && _box!.isOpen) {
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
    return _inMemorySessions[id];
  }

  Future<void> saveSession(ChatSession session) async {
    await init();
    _inMemorySessions[session.id] = session;
    if (_box != null && _box!.isOpen) {
      try {
        await _box!.put(session.id, jsonEncode(session.toJson()));
      } catch (_) {}
    }
  }

  Future<void> deleteSession(String id) async {
    await init();
    _inMemorySessions.remove(id);
    if (_box != null && _box!.isOpen) {
      try {
        await _box!.delete(id);
      } catch (_) {}
    }
  }

  Future<void> clearAllSessions() async {
    await init();
    _inMemorySessions.clear();
    if (_box != null && _box!.isOpen) {
      try {
        await _box!.clear();
      } catch (_) {}
    }
  }
}
