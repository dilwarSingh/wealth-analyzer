import 'dart:typed_data';
import 'generative_ui_payload.dart';

enum MessageRole {
  user,
  assistant,
  system,
  tool;

  String get displayName {
    switch (this) {
      case MessageRole.user:
        return 'You';
      case MessageRole.assistant:
        return 'AI Advisor';
      case MessageRole.system:
        return 'System';
      case MessageRole.tool:
        return 'Tool Engine';
    }
  }
}

enum ToolExecutionState {
  running,
  completed,
  failed;
}

class ToolExecutionStep {
  final String toolName;
  final String description;
  final ToolExecutionState state;
  final DateTime timestamp;

  const ToolExecutionStep({
    required this.toolName,
    required this.description,
    required this.state,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'toolName': toolName,
    'description': description,
    'state': state.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ToolExecutionStep.fromJson(Map<String, dynamic> json) => ToolExecutionStep(
    toolName: json['toolName'] as String? ?? '',
    description: json['description'] as String? ?? '',
    state: ToolExecutionState.values.firstWhere(
      (e) => e.name == json['state'],
      orElse: () => ToolExecutionState.completed,
    ),
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}

class ChatMessage {
  final String id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final String? thinkingContent;
  final Duration? thinkingDuration;
  final bool isThinking;
  final DateTime timestamp;
  final Uint8List? imageBytes;
  final String? imageName;
  final bool isStreaming;
  final String? error;
  final List<ToolExecutionStep> steps;
  final List<GenerativeUIPayload> generativeWidgets;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.thinkingContent,
    this.thinkingDuration,
    this.isThinking = false,
    required this.timestamp,
    this.imageBytes,
    this.imageName,
    this.isStreaming = false,
    this.error,
    this.steps = const [],
    this.generativeWidgets = const [],
  });

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    String? content,
    String? thinkingContent,
    Duration? thinkingDuration,
    bool? isThinking,
    DateTime? timestamp,
    Uint8List? imageBytes,
    String? imageName,
    bool? isStreaming,
    String? error,
    List<ToolExecutionStep>? steps,
    List<GenerativeUIPayload>? generativeWidgets,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      thinkingContent: thinkingContent ?? this.thinkingContent,
      thinkingDuration: thinkingDuration ?? this.thinkingDuration,
      isThinking: isThinking ?? this.isThinking,
      timestamp: timestamp ?? this.timestamp,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error ?? this.error,
      steps: steps ?? this.steps,
      generativeWidgets: generativeWidgets ?? this.generativeWidgets,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'role': role.name,
    'content': content,
    'thinkingContent': thinkingContent,
    'thinkingDurationMs': thinkingDuration?.inMilliseconds,
    'isThinking': isThinking,
    'timestamp': timestamp.toIso8601String(),
    'imageName': imageName,
    'error': error,
    'steps': steps.map((s) => s.toJson()).toList(),
    'generativeWidgets': generativeWidgets.map((w) => w.toJson()).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String? ?? '',
    sessionId: json['sessionId'] as String? ?? 'default',
    role: MessageRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => MessageRole.assistant,
    ),
    content: json['content'] as String? ?? '',
    thinkingContent: json['thinkingContent'] as String?,
    thinkingDuration: json['thinkingDurationMs'] != null
        ? Duration(milliseconds: json['thinkingDurationMs'] as int)
        : null,
    isThinking: json['isThinking'] as bool? ?? false,
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    imageName: json['imageName'] as String?,
    error: json['error'] as String?,
    steps: (json['steps'] as List<dynamic>? ?? [])
        .map((s) => ToolExecutionStep.fromJson(s as Map<String, dynamic>))
        .toList(),
    generativeWidgets: (json['generativeWidgets'] as List<dynamic>? ?? [])
        .map((w) => GenerativeUIPayload.fromJson(w as Map<String, dynamic>))
        .toList(),
  );
}
