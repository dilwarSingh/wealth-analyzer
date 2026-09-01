import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/contracts/ai_portfolio_contract.dart';
import '../../domain/entities/ai_config.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/data_sharing_config.dart';
import '../registry/generative_widget_registry.dart';
import '../viewmodels/ai_chat_viewmodel.dart';
import '../viewmodels/ai_persona_viewmodel.dart';
import '../viewmodels/ai_session_viewmodel.dart';
import '../viewmodels/ai_settings_viewmodel.dart';
import '../widgets/ai_glass_card.dart';
import '../widgets/ai_thought_stream_box.dart';
import 'ai_data_sharing_dialog.dart';
import 'ai_session_drawer.dart';
import 'ai_settings_modal.dart';

class AIScreen extends ConsumerStatefulWidget {
  final AIPortfolioSnapshot snapshot;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;
  final AIPortfolioActionDelegate? actionDelegate;
  final AIMathEngineDelegate? mathDelegate;
  final String? initialPrompt;

  const AIScreen({
    super.key,
    required this.snapshot,
    required this.theme,
    this.currencyDelegate,
    this.actionDelegate,
    this.mathDelegate,
    this.initialPrompt,
  });

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _lastSessionId;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
        _handleSend(prompt: widget.initialPrompt!);
      }
    });
  }

  void _openDataSharingDialog(String activeSessionId) {
    final chatState = ref.read(aiChatProvider(activeSessionId));
    showDialog(
      context: context,
      builder: (ctx) => AIDataSharingDialog(
        snapshot: widget.snapshot,
        theme: widget.theme,
        currencyDelegate: widget.currencyDelegate,
        initialConfig: chatState.sharingConfig ?? const AIDataSharingConfig(),
        onSaved: (newConfig) {
          ref.read(aiChatProvider(activeSessionId).notifier).updateDataSharingConfig(newConfig);
        },
      ),
    );
  }

  String _getPrivacyPillLabel(AIDataSharingConfig config, {bool compact = false}) {
    if (config.privacyMode == ContextPrivacyMode.promptOnly) {
      return compact ? 'Prompt Only' : '🛡️ Prompt Only';
    } else if (config.anonymizeValues) {
      return compact ? 'Masked' : '🛡️ Masked (100k)';
    } else if (config.privacyMode == ContextPrivacyMode.summaryOnly) {
      return compact ? 'Summary' : '🛡️ Summary Only';
    } else {
      final count = config.includedCategories.length;
      return compact ? '$count Cats' : '🛡️ $count Categories';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _handleSend({String? prompt}) async {
    final text = prompt ?? _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    final activeSessionId = ref.read(aiSessionProvider).activeSessionId;
    final chatVm = ref.read(aiChatProvider(activeSessionId).notifier);

    _scrollToBottom();
    await chatVm.sendMessage(
      prompt: text,
      snapshot: widget.snapshot,
      mathDelegate: widget.mathDelegate,
      currencyDelegate: widget.currencyDelegate,
    );
    _scrollToBottom();
  }

  Future<void> _pickImage(String sessionId) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'csv', 'txt'],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty && res.files.first.bytes != null) {
      final file = res.files.first;
      ref.read(aiChatProvider(sessionId).notifier).attachImage(file.bytes!, file.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final activeSession = ref.watch(aiSessionProvider).activeSession;
    final activeSessionId = activeSession?.id ?? 'default';
    final chatState = ref.watch(aiChatProvider(activeSessionId));
    final persona = ref.watch(aiPersonaProvider);
    final config = ref.watch(aiSettingsProvider);

    if (_lastSessionId != activeSessionId || _lastMessageCount != chatState.messages.length) {
      _lastSessionId = activeSessionId;
      _lastMessageCount = chatState.messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: AISessionDrawer(
        theme: theme,
        onSessionSelected: () {
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            Navigator.of(context).pop();
          }
          _scrollToBottom();
        },
        onNewSessionCreated: (newSessionId) {
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            Navigator.of(context).pop();
          }
          _scrollToBottom();
          final config = ref.read(aiSettingsProvider);
          if (config.autoShowPrivacyDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openDataSharingDialog(newSessionId);
            });
          }
        },
      ),
      body: Column(
        children: [
          // Top Bar
          _buildTopBar(context, activeSessionId, chatState, persona, config, theme),

          // Message Feed
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isStreaming
                ? _buildEmptyState(theme)
                : _buildMessageList(chatState, theme),
          ),

          // Bottom Input Area & Disclaimer
          _buildInputBar(activeSessionId, chatState, theme),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    String activeSessionId,
    AIChatState chatState,
    AIPersona persona,
    AIConfig config,
    AIThemeData theme,
  ) {
    final sharingConfig = chatState.sharingConfig ?? const AIDataSharingConfig();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isVeryNarrow = constraints.maxWidth < 390;
        final privacyLabel = _getPrivacyPillLabel(sharingConfig, compact: isCompact);

        return AIGlassCard(
          theme: theme,
          borderRadius: 0,
          borderWidth: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isVeryNarrow ? 6 : (isCompact ? 8 : 12),
            vertical: isCompact ? 6 : 8,
          ),
          child: Row(
            children: [
              // Drawer Trigger
              IconButton(
                icon: Icon(Icons.menu_rounded, color: theme.secondaryAccentColor, size: 19),
                tooltip: 'Chat Threads',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 3),

              // Persona Selector (Wrapped in Flexible so it never overflows)
              Flexible(
                child: PopupMenuButton<AIPersona>(
                  color: theme.surfaceLightColor,
                  tooltip: 'Switch Advisor Persona',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
                  onSelected: (p) => ref.read(aiPersonaProvider.notifier).selectPersona(p),
                  itemBuilder: (ctx) => AIPersona.presets.map((p) {
                    return PopupMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Text(p.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textPrimaryColor,
                                  ),
                                ),
                                Text(
                                  p.tagline,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: theme.textMutedColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVeryNarrow ? 5 : 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surfaceLightColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.borderColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(persona.icon, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            persona.name,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down_rounded, color: theme.secondaryAccentColor, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Privacy Shield Pill
              InkWell(
                onTap: () => _openDataSharingDialog(activeSessionId),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVeryNarrow ? 5 : 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.secondaryAccentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.secondaryAccentColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: theme.secondaryAccentColor),
                      const SizedBox(width: 3),
                      Text(
                        privacyLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.secondaryAccentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 3),

              // Provider Badge (Hidden on compact mobile, visible on desktop)
              if (!isCompact) ...[
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AISettingsModal(theme: theme),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (config.isConfigured ? theme.successColor : theme.secondaryAccentColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (config.isConfigured ? theme.successColor : theme.secondaryAccentColor).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          config.isConfigured ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
                          size: 13,
                          color: config.isConfigured ? theme.successColor : theme.secondaryAccentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          config.isConfigured ? config.provider.displayName : 'Offline / Heuristics',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: config.isConfigured ? theme.successColor : theme.secondaryAccentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // 1-Click Instant Audit CTA
              IconButton(
                icon: Icon(Icons.bolt_rounded, color: theme.secondaryAccentColor, size: 18),
                tooltip: 'Instant Wealth Audit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  ref.read(aiChatProvider(activeSessionId).notifier).runInstantAudit(
                    snapshot: widget.snapshot,
                    currencyDelegate: widget.currencyDelegate,
                  );
                  _scrollToBottom();
                },
              ),
              const SizedBox(width: 1),

              // Settings Button
              IconButton(
                icon: Icon(Icons.settings_outlined, color: theme.textSecondaryColor, size: 17),
                tooltip: 'AI Settings',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AISettingsModal(theme: theme),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AIThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryAccentColor, theme.secondaryAccentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryAccentColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'How can I help optimize your wealth today?',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ask any question, simulate custom financial what-ifs, run Monte Carlo crash tests, or paste a broker statement.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: theme.textSecondaryColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Starter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildPromptChip('📊 Full Health Audit', 'Run a comprehensive wealth health audit and diagnostic review.'),
                  _buildPromptChip('🎯 Rebalance for FIRE Goal', 'Evaluate my asset allocation drift and recommend a rebalancing strategy for my FIRE goal.'),
                  _buildPromptChip('🛡️ Stress Test 2008 Crash', 'Stress test my portfolio against a 2008-style market crash and stagflation.'),
                  _buildPromptChip('📈 Interactive Scenario Simulator', 'Open the interactive scenario simulator for my net worth compounding.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptChip(String title, String prompt) {
    final theme = widget.theme;
    return InkWell(
      onTap: () => _handleSend(prompt: prompt),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.surfaceLightColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.borderColor.withOpacity(0.3)),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textPrimaryColor),
        ),
      ),
    );
  }

  Widget _buildMessageList(AIChatState chatState, AIThemeData theme) {
    final messages = chatState.messages;

    return Scrollbar(
      controller: _scrollController,
      radius: const Radius.circular(8),
      thickness: 6,
      interactive: true,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        cacheExtent: 10000,
        itemCount: messages.length + (chatState.isStreaming ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i < messages.length) {
            final msg = messages[i];
            return _buildMessageBubble(msg, theme);
          } else {
            return _buildStreamingBubble(chatState, theme);
          }
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, AIThemeData theme) {
    final isUser = msg.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender Header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser) ...[
                Icon(Icons.psychology_rounded, size: 14, color: theme.secondaryAccentColor),
                const SizedBox(width: 4),
              ],
              Text(
                isUser ? 'You' : 'Wealth Copilot',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isUser ? theme.textSecondaryColor : theme.secondaryAccentColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(fontSize: 9, color: theme.textMutedColor),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Attached Image (if any)
          if (msg.imageBytes != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              height: 120,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderColor),
                image: DecorationImage(
                  image: MemoryImage(msg.imageBytes!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Live Thinking Box (if assistant message contains thinking)
          if (!isUser && msg.thinkingContent != null && msg.thinkingContent!.isNotEmpty)
            AIThoughtStreamBox(
              thinkingContent: msg.thinkingContent!,
              duration: msg.thinkingDuration,
              theme: theme,
            ),

          // Message Content Box
          if (msg.content.isNotEmpty)
            AIGlassCard(
              theme: theme,
              backgroundColor: isUser ? theme.primaryAccentColor.withOpacity(0.18) : theme.surfaceColor.withOpacity(0.85),
              borderColor: isUser ? theme.primaryAccentColor.withOpacity(0.4) : theme.borderColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: SelectableText(
                msg.content,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.45,
                  color: theme.textPrimaryColor,
                ),
              ),
            ),

          // Render Embedded Generative UI Widgets
          if (msg.generativeWidgets.isNotEmpty)
            ...msg.generativeWidgets.map((w) {
              return GenerativeWidgetRegistry.buildWidget(
                payload: w,
                theme: theme,
                currencyDelegate: widget.currencyDelegate,
                actionDelegate: widget.actionDelegate,
                onStateMutated: () => setState(() {}),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStreamingBubble(AIChatState chatState, AIThemeData theme) {
    final isCurrentlyThinking = chatState.isThinking;
    final thinkingContent = chatState.streamingThinking ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, size: 14, color: theme.secondaryAccentColor),
              const SizedBox(width: 4),
              Text(
                isCurrentlyThinking ? 'Wealth Copilot (Reasoning...)' : 'Wealth Copilot (Streaming...)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: theme.secondaryAccentColor),
              ),
              const Spacer(),
              // Stop Generating Button
              InkWell(
                onTap: () {
                  final activeSessionId = ref.read(aiSessionProvider).activeSessionId;
                  ref.read(aiChatProvider(activeSessionId).notifier).cancelGeneration();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.primaryAccentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.primaryAccentColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop_circle_outlined, size: 12, color: theme.primaryAccentColor),
                      const SizedBox(width: 4),
                      Text(
                        'Stop',
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: theme.primaryAccentColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Streaming Thinking Box
          if (thinkingContent.isNotEmpty || isCurrentlyThinking)
            AIThoughtStreamBox(
              thinkingContent: thinkingContent,
              isThinking: isCurrentlyThinking,
              duration: chatState.thinkingDuration,
              theme: theme,
              initiallyExpanded: true,
            ),

          // Tool Execution Timeline Steps
          if (chatState.currentSteps.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: chatState.currentSteps.map((s) {
                final isCompleted = s.state == ToolExecutionState.completed;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isCompleted ? theme.successColor : theme.secondaryAccentColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (isCompleted ? theme.successColor : theme.secondaryAccentColor).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isCompleted)
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.secondaryAccentColor),
                        )
                      else
                        Icon(Icons.check_rounded, size: 12, color: theme.successColor),
                      const SizedBox(width: 5),
                      Text(
                        s.description,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? theme.successColor : theme.secondaryAccentColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Partial Streaming Text
          if (chatState.streamingText != null && chatState.streamingText!.isNotEmpty)
            AIGlassCard(
              theme: theme,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                chatState.streamingText!,
                style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: theme.textPrimaryColor),
              ),
            ),

          // Live Rendered Tool Widgets
          if (chatState.currentWidgets.isNotEmpty)
            ...chatState.currentWidgets.map((w) {
              return GenerativeWidgetRegistry.buildWidget(
                payload: w,
                theme: theme,
                currencyDelegate: widget.currencyDelegate,
                actionDelegate: widget.actionDelegate,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInputBar(String activeSessionId, AIChatState chatState, AIThemeData theme) {
    final sharingConfig = chatState.sharingConfig ?? const AIDataSharingConfig();
    final privacyLabel = _getPrivacyPillLabel(sharingConfig);

    return AIGlassCard(
      theme: theme,
      borderRadius: 0,
      borderWidth: 0,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Privacy Indicator Bar
          InkWell(
            onTap: () => _openDataSharingDialog(activeSessionId),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 11, color: theme.textMutedColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Data Sharing: $privacyLabel (Tap to customize)',
                      style: GoogleFonts.inter(fontSize: 10, color: theme.textMutedColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Image Attachment Chip (if attached)
          if (chatState.attachedImageBytes != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.surfaceLightColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.borderColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.image_outlined, size: 14, color: theme.secondaryAccentColor),
                      const SizedBox(width: 6),
                      Text(
                        chatState.attachedImageName ?? 'Statement Image',
                        style: GoogleFonts.inter(fontSize: 11, color: theme.textPrimaryColor),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => ref.read(aiChatProvider(activeSessionId).notifier).clearAttachedImage(),
                        child: Icon(Icons.close_rounded, size: 14, color: theme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Input Row
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file_rounded, color: theme.secondaryAccentColor, size: 20),
                tooltip: 'Attach Statement / Screenshot',
                onPressed: () => _pickImage(activeSessionId),
              ),
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter;
                      if (isEnter) {
                        final isShift = HardwareKeyboard.instance.isShiftPressed;
                        final isControl = HardwareKeyboard.instance.isControlPressed;
                        final isAlt = HardwareKeyboard.instance.isAltPressed;
                        final isMeta = HardwareKeyboard.instance.isMetaPressed;

                        if (isShift || isControl || isAlt || isMeta) {
                          // Shift/Ctrl/Alt/Meta + Enter: Allow default newline insertion
                          return KeyEventResult.ignored;
                        } else {
                          // Plain Enter: Send message immediately and prevent newline
                          if (_textController.text.trim().isNotEmpty && !chatState.isStreaming) {
                            _handleSend();
                          }
                          return KeyEventResult.handled;
                        }
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    style: GoogleFonts.inter(fontSize: 13, color: theme.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: 'Ask financial question, simulate what-ifs, or audit portfolio...',
                      hintStyle: GoogleFonts.inter(fontSize: 12.5, color: theme.textMutedColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onSubmitted: (_) {
                      if (_textController.text.trim().isNotEmpty && !chatState.isStreaming) {
                        _handleSend();
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  chatState.isStreaming ? Icons.stop_circle_rounded : Icons.send_rounded,
                  color: chatState.isStreaming ? theme.primaryAccentColor : theme.secondaryAccentColor,
                  size: 22,
                ),
                tooltip: chatState.isStreaming ? 'Stop Generating' : 'Send Prompt',
                onPressed: () {
                  if (chatState.isStreaming) {
                    ref.read(aiChatProvider(activeSessionId).notifier).cancelGeneration();
                  } else {
                    _handleSend();
                  }
                },
              ),
            ],
          ),

          // Ambient Planning Disclaimer
          const SizedBox(height: 4),
          Text(
            'Modeled projections & simulations are for informational planning and educational purposes.',
            style: GoogleFonts.inter(fontSize: 9.5, color: theme.textMutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
