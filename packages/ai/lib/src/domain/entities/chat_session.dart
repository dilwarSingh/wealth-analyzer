import 'chat_message.dart';
import 'data_sharing_config.dart';

/// Represents a distinct conversation thread with its message history and privacy context
class ChatSession {
  final String id;
  final String title;
  final String personaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final AIDataSharingConfig? dataSharingConfig;

  const ChatSession({
    required this.id,
    required this.title,
    this.personaId = 'fire_planner',
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.dataSharingConfig,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    String? personaId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    AIDataSharingConfig? dataSharingConfig,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      personaId: personaId ?? this.personaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      dataSharingConfig: dataSharingConfig ?? this.dataSharingConfig,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'personaId': personaId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
    'dataSharingConfig': dataSharingConfig?.toJson(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String? ?? 'default',
    title: json['title'] as String? ?? 'New Advisory Chat',
    personaId: json['personaId'] as String? ?? 'fire_planner',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    messages: (json['messages'] as List<dynamic>? ?? [])
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList(),
    dataSharingConfig: json['dataSharingConfig'] != null
        ? AIDataSharingConfig.fromJson(json['dataSharingConfig'] as Map<String, dynamic>)
        : null,
  );
}
