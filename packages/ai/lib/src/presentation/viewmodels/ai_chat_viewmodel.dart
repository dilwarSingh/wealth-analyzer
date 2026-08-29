import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/ai_provider_bridge.dart';
import '../../data/services/offline_heuristic_advisor.dart';
import '../../domain/contracts/ai_portfolio_contract.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/data_sharing_config.dart';
import '../../domain/entities/generative_ui_payload.dart';
import 'ai_persona_viewmodel.dart';
import 'ai_session_viewmodel.dart';
import 'ai_settings_viewmodel.dart';

class AIChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? streamingText;
  final String? streamingThinking;
  final bool isThinking;
  final Duration? thinkingDuration;
  final List<ToolExecutionStep> currentSteps;
  final List<GenerativeUIPayload> currentWidgets;
  final Uint8List? attachedImageBytes;
  final String? attachedImageName;
  final String? errorMessage;
  final AIDataSharingConfig? sharingConfig;

  const AIChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.streamingText,
    this.streamingThinking,
    this.isThinking = false,
    this.thinkingDuration,
    this.currentSteps = const [],
    this.currentWidgets = const [],
    this.attachedImageBytes,
    this.attachedImageName,
    this.errorMessage,
    this.sharingConfig,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? streamingText,
    String? streamingThinking,
    bool? isThinking,
    Duration? thinkingDuration,
    List<ToolExecutionStep>? currentSteps,
    List<GenerativeUIPayload>? currentWidgets,
    Uint8List? attachedImageBytes,
    String? attachedImageName,
    String? errorMessage,
    AIDataSharingConfig? sharingConfig,
    bool clearImage = false,
    bool clearStreaming = false,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText: clearStreaming ? null : (streamingText ?? this.streamingText),
      streamingThinking: clearStreaming ? null : (streamingThinking ?? this.streamingThinking),
      isThinking: isThinking ?? this.isThinking,
      thinkingDuration: clearStreaming ? null : (thinkingDuration ?? this.thinkingDuration),
      currentSteps: clearStreaming ? const [] : (currentSteps ?? this.currentSteps),
      currentWidgets: clearStreaming ? const [] : (currentWidgets ?? this.currentWidgets),
      attachedImageBytes: clearImage ? null : (attachedImageBytes ?? this.attachedImageBytes),
      attachedImageName: clearImage ? null : (attachedImageName ?? this.attachedImageName),
      errorMessage: errorMessage,
      sharingConfig: sharingConfig ?? this.sharingConfig,
    );
  }
}

final aiChatProvider = StateNotifierProvider.family<AIChatViewModel, AIChatState, String>((ref, sessionId) {
  final sessionState = ref.watch(aiSessionProvider);
  final session = sessionState.sessions.firstWhere(
    (s) => s.id == sessionId,
    orElse: () => sessionState.activeSession ?? ChatSession(
      id: sessionId,
      title: 'Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );
  return AIChatViewModel(ref, session);
});

class AIChatViewModel extends StateNotifier<AIChatState> {
  final Ref _ref;
  final ChatSession _session;
  final AIProviderBridge _bridge = AIProviderBridge();
  final _uuid = const Uuid();

  AIChatViewModel(this._ref, this._session)
      : super(AIChatState(
          messages: _session.messages,
          sharingConfig: _session.dataSharingConfig ?? const AIDataSharingConfig(),
        ));

  void attachImage(Uint8List bytes, String name) {
    state = state.copyWith(attachedImageBytes: bytes, attachedImageName: name);
  }

  void clearAttachedImage() {
    state = state.copyWith(clearImage: true);
  }

  void updateDataSharingConfig(AIDataSharingConfig config) {
    state = state.copyWith(sharingConfig: config);
    final updatedSession = _session.copyWith(dataSharingConfig: config);
    _ref.read(aiSessionProvider.notifier).updateSession(updatedSession);
  }

  void cancelGeneration() {
    _bridge.cancelStream();
    state = state.copyWith(isStreaming: false, clearStreaming: true);
  }

  /// Send prompt with autonomous tool calling or instant offline heuristic execution
  Future<void> sendMessage({
    required String prompt,
    required AIPortfolioSnapshot snapshot,
    AIMathEngineDelegate? mathDelegate,
    AICurrencyDelegate? currencyDelegate,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty && state.attachedImageBytes == null) return;

    final config = _ref.read(aiSettingsProvider);
    final persona = _ref.read(aiPersonaProvider);
    final effectiveSharingConfig = state.sharingConfig ?? const AIDataSharingConfig();

    // 1. Create user message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      sessionId: _session.id,
      role: MessageRole.user,
      content: trimmed.isNotEmpty ? trimmed : 'Analyzed attached statement screenshot.',
      timestamp: DateTime.now(),
      imageBytes: state.attachedImageBytes,
      imageName: state.attachedImageName,
    );

    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: updatedMessages,
      isStreaming: true,
      streamingText: '',
      streamingThinking: '',
      isThinking: true,
      currentSteps: const [],
      currentWidgets: const [],
      clearImage: true,
      errorMessage: null,
    );

    // 2. Check if Zero-Key Offline mode applies
    if (!config.isConfigured) {
      // Execute local deterministic heuristic advisor
      await Future.delayed(const Duration(milliseconds: 400));
      final responseMsg = OfflineHeuristicAdvisor.generateInstantAudit(
        sessionId: _session.id,
        snapshot: effectiveSharingConfig.filterSnapshot(snapshot),
        currencyDelegate: currencyDelegate,
      );

      final finalMessages = [...updatedMessages, responseMsg];
      state = state.copyWith(
        messages: finalMessages,
        isStreaming: false,
        clearStreaming: true,
      );
      _persistSession(finalMessages);
      return;
    }

    // 3. Online Conversational AI Stream with Tools and Thinking
    try {
      final responseMsg = await _bridge.sendMessageStream(
        sessionId: _session.id,
        prompt: trimmed,
        imageBytes: userMessage.imageBytes,
        imageName: userMessage.imageName,
        conversationHistory: state.messages,
        persona: persona,
        config: config,
        snapshot: snapshot,
        sharingConfig: effectiveSharingConfig,
        mathDelegate: mathDelegate,
        currencyDelegate: currencyDelegate,
        onUpdate: ({
          required textDelta,
          required accumulatedText,
          thinkingDelta,
          accumulatedThinking,
          isThinking = false,
          thinkingDuration,
          newStep,
          newWidget,
        }) {
          final steps = List<ToolExecutionStep>.from(state.currentSteps);
          if (newStep != null) {
            steps.removeWhere((s) => s.toolName == newStep.toolName && s.state == ToolExecutionState.running);
            steps.add(newStep);
          }
          final widgets = List<GenerativeUIPayload>.from(state.currentWidgets);
          if (newWidget != null && !widgets.any((w) => w.widgetId == newWidget.widgetId)) {
            widgets.add(newWidget);
          }
          state = state.copyWith(
            streamingText: accumulatedText.isNotEmpty ? accumulatedText : state.streamingText,
            streamingThinking: accumulatedThinking != null && accumulatedThinking.isNotEmpty
                ? accumulatedThinking
                : state.streamingThinking,
            isThinking: isThinking,
            thinkingDuration: thinkingDuration ?? state.thinkingDuration,
            currentSteps: steps,
            currentWidgets: widgets,
          );
        },
      );

      final finalMessages = [...updatedMessages, responseMsg];
      state = state.copyWith(
        messages: finalMessages,
        isStreaming: false,
        clearStreaming: true,
      );
      _persistSession(finalMessages);
    } catch (e) {
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        sessionId: _session.id,
        role: MessageRole.assistant,
        content: '⚠️ Failed to get AI response: $e\n\nCheck your API key in AI Settings or switch to another provider.',
        timestamp: DateTime.now(),
        error: e.toString(),
      );
      final finalMessages = [...updatedMessages, errorMsg];
      state = state.copyWith(
        messages: finalMessages,
        isStreaming: false,
        clearStreaming: true,
        errorMessage: e.toString(),
      );
      _persistSession(finalMessages);
    }
  }

  /// Run Instant Full Audit
  Future<void> runInstantAudit({
    required AIPortfolioSnapshot snapshot,
    AICurrencyDelegate? currencyDelegate,
  }) async {
    final effectiveSharingConfig = state.sharingConfig ?? const AIDataSharingConfig();
    final auditMsg = OfflineHeuristicAdvisor.generateInstantAudit(
      sessionId: _session.id,
      snapshot: effectiveSharingConfig.filterSnapshot(snapshot),
      currencyDelegate: currencyDelegate,
    );
    final finalMessages = [...state.messages, auditMsg];
    state = state.copyWith(messages: finalMessages);
    _persistSession(finalMessages);
  }

  void _persistSession(List<ChatMessage> messages) {
    final updatedSession = _session.copyWith(
      messages: messages,
      dataSharingConfig: state.sharingConfig,
      updatedAt: DateTime.now(),
    );
    _ref.read(aiSessionProvider.notifier).updateSession(updatedSession);
  }
}
