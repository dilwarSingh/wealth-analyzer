import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../domain/contracts/ai_portfolio_contract.dart';
import '../../domain/entities/ai_config.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/data_sharing_config.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/generative_ui_payload.dart';
import '../../domain/tools/ai_financial_tools.dart';
import 'ai_context_builder.dart';
import 'ai_rebalancing_engine.dart';

/// Callback when streaming text, thinking, or tools arrive
typedef StreamUpdateCallback = void Function({
  required String textDelta,
  required String accumulatedText,
  String? thinkingDelta,
  String? accumulatedThinking,
  bool isThinking,
  Duration? thinkingDuration,
  ToolExecutionStep? newStep,
  GenerativeUIPayload? newWidget,
});

/// Streaming parser for capturing token streams, thinking blocks (<think>...</think>), and native reasoning deltas
class StreamingThinkingParser {
  final void Function({
    required String textDelta,
    required String thinkingDelta,
    required bool isThinking,
    Duration? duration,
  }) onChunk;

  bool _insideThinkTag = false;
  bool _insideNativeReasoning = false;
  String _tagBuffer = '';
  final StringBuffer _thinkingBuffer = StringBuffer();
  final StringBuffer _textBuffer = StringBuffer();
  DateTime? _thinkingStartTime;
  DateTime? _thinkingEndTime;

  StreamingThinkingParser({required this.onChunk});

  String get accumulatedThinking => _thinkingBuffer.toString();
  String get accumulatedText => _textBuffer.toString();
  bool get isThinking => _insideNativeReasoning || _insideThinkTag;

  Duration? get thinkingDuration {
    if (_thinkingStartTime == null) return null;
    final end = _thinkingEndTime ?? DateTime.now();
    return end.difference(_thinkingStartTime!);
  }

  void feedNativeReasoning(String delta) {
    if (delta.isEmpty) return;
    _thinkingStartTime ??= DateTime.now();
    _insideNativeReasoning = true;
    _thinkingBuffer.write(delta);
    onChunk(
      textDelta: '',
      thinkingDelta: delta,
      isThinking: true,
      duration: thinkingDuration,
    );
  }

  void markNativeThinkingComplete() {
    if (_insideNativeReasoning) {
      _insideNativeReasoning = false;
      _thinkingEndTime = DateTime.now();
      onChunk(
        textDelta: '',
        thinkingDelta: '',
        isThinking: false,
        duration: thinkingDuration,
      );
    }
  }

  void feedContent(String chunk) {
    if (chunk.isEmpty) return;

    // Transition out of native reasoning if content starts streaming
    if (_insideNativeReasoning) {
      markNativeThinkingComplete();
    }

    for (int i = 0; i < chunk.length; i++) {
      final char = chunk[i];
      if (char == '<' || _tagBuffer.isNotEmpty) {
        _tagBuffer += char;
        final lower = _tagBuffer.toLowerCase();
        if (lower == '<think>' || lower == '<thought>') {
          _insideThinkTag = true;
          _thinkingStartTime ??= DateTime.now();
          _thinkingEndTime = null;
          _tagBuffer = '';
          onChunk(
            textDelta: '',
            thinkingDelta: '',
            isThinking: true,
            duration: thinkingDuration,
          );
        } else if (lower == '</think>' || lower == '</thought>') {
          _insideThinkTag = false;
          _thinkingEndTime = DateTime.now();
          _tagBuffer = '';
          onChunk(
            textDelta: '',
            thinkingDelta: '',
            isThinking: false,
            duration: thinkingDuration,
          );
        } else if (!_isPotentialTagPrefix(lower)) {
          // Not a think tag prefix, flush buffered tag characters immediately
          if (_insideThinkTag) {
            _thinkingBuffer.write(_tagBuffer);
            onChunk(
              textDelta: '',
              thinkingDelta: _tagBuffer,
              isThinking: true,
              duration: thinkingDuration,
            );
          } else {
            _textBuffer.write(_tagBuffer);
            onChunk(
              textDelta: _tagBuffer,
              thinkingDelta: '',
              isThinking: false,
              duration: thinkingDuration,
            );
          }
          _tagBuffer = '';
        }
      } else {
        if (_insideThinkTag) {
          _thinkingBuffer.write(char);
          onChunk(
            textDelta: '',
            thinkingDelta: char,
            isThinking: true,
            duration: thinkingDuration,
          );
        } else {
          _textBuffer.write(char);
          onChunk(
            textDelta: char,
            thinkingDelta: '',
            isThinking: false,
            duration: thinkingDuration,
          );
        }
      }
    }
  }

  static bool _isPotentialTagPrefix(String lower) {
    const validPrefixes = [
      '<',
      '<t',
      '<th',
      '<thi',
      '<thin',
      '<think',
      '<think>',
      '<tho',
      '<thou',
      '<thoug',
      '<though',
      '<thought',
      '<thought>',
      '</',
      '</t',
      '</th',
      '</thi',
      '</thin',
      '</think',
      '</think>',
      '</tho',
      '</thou',
      '</thoug',
      '</though',
      '</thought',
      '</thought>',
    ];
    return validPrefixes.contains(lower);
  }

  void finalize() {
    if (_insideNativeReasoning || _insideThinkTag) {
      _insideNativeReasoning = false;
      _insideThinkTag = false;
      _thinkingEndTime = DateTime.now();
    }
    if (_tagBuffer.isNotEmpty) {
      if (_insideThinkTag) {
        _thinkingBuffer.write(_tagBuffer);
      } else {
        _textBuffer.write(_tagBuffer);
      }
      onChunk(
        textDelta: _insideThinkTag ? '' : _tagBuffer,
        thinkingDelta: _insideThinkTag ? _tagBuffer : '',
        isThinking: false,
        duration: thinkingDuration,
      );
      _tagBuffer = '';
    }
  }
}

/// Bridge connecting AI providers with local deterministic math engines and generative UI rendering
class AIProviderBridge {
  http.Client? _activeClient;
  bool _isCancelled = false;

  /// Cancel active in-flight request
  void cancelStream() {
    _isCancelled = true;
    _activeClient?.close();
    _activeClient = null;
  }

  /// Test connectivity to the configured provider endpoint
  Future<bool> testConnection(AIConfig config) async {
    final client = http.Client();
    try {
      if (config.provider == AIProviderType.gemini) {
        final url = Uri.parse(
          '${config.baseUrl}/models/${config.modelName}?key=${config.apiKey}',
        );
        final res = await client.get(url).timeout(const Duration(seconds: 8));
        return res.statusCode == 200;
      } else if (config.provider == AIProviderType.claude) {
        final url = Uri.parse('${config.baseUrl}/messages');
        final res = await client.post(
          url,
          headers: {
            'x-api-key': config.apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': config.modelName,
            'max_tokens': 10,
            'messages': [{'role': 'user', 'content': 'ping'}],
          }),
        ).timeout(const Duration(seconds: 8));
        return res.statusCode == 200 || res.statusCode == 400;
      } else {
        // OpenAI / OpenRouter / Groq / Ollama
        final url = Uri.parse('${config.baseUrl}/models');
        final headers = <String, String>{'content-type': 'application/json'};
        if (config.apiKey.isNotEmpty) {
          headers['authorization'] = 'Bearer ${config.apiKey}';
        }
        final res = await client.get(url, headers: headers).timeout(const Duration(seconds: 8));
        return res.statusCode == 200;
      }
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Send message stream with autonomous tool execution loop and streaming thinking
  Future<ChatMessage> sendMessageStream({
    required String sessionId,
    required String prompt,
    Uint8List? imageBytes,
    String? imageName,
    required List<ChatMessage> conversationHistory,
    required AIPersona persona,
    required AIConfig config,
    required AIPortfolioSnapshot snapshot,
    AIDataSharingConfig? sharingConfig,
    AIMathEngineDelegate? mathDelegate,
    AICurrencyDelegate? currencyDelegate,
    required StreamUpdateCallback onUpdate,
  }) async {
    _isCancelled = false;
    _activeClient = http.Client();

    final systemPrompt = AIContextBuilder.buildSystemPrompt(
      persona: persona,
      config: config,
      snapshot: snapshot,
      sharingConfig: sharingConfig,
      currencyDelegate: currencyDelegate,
    );

    final history = AIContextBuilder.compactMessagesForLLM(conversationHistory);
    final toolSteps = <ToolExecutionStep>[];
    final generatedWidgets = <GenerativeUIPayload>[];

    final parser = StreamingThinkingParser(
      onChunk: ({required textDelta, required thinkingDelta, required isThinking, duration}) {
        onUpdate(
          textDelta: textDelta,
          accumulatedText: '', // Filled in caller
          thinkingDelta: thinkingDelta,
          accumulatedThinking: '',
          isThinking: isThinking,
          thinkingDuration: duration,
        );
      },
    );

    try {
      if (config.provider == AIProviderType.gemini) {
        await _executeGeminiStream(
          prompt: prompt,
          imageBytes: imageBytes,
          systemPrompt: systemPrompt,
          history: history,
          config: config,
          snapshot: snapshot,
          mathDelegate: mathDelegate,
          currencyDelegate: currencyDelegate,
          toolSteps: toolSteps,
          generatedWidgets: generatedWidgets,
          parser: parser,
          onUpdate: onUpdate,
        );
      } else if (config.provider == AIProviderType.claude) {
        await _executeClaudeStream(
          prompt: prompt,
          systemPrompt: systemPrompt,
          history: history,
          config: config,
          snapshot: snapshot,
          mathDelegate: mathDelegate,
          currencyDelegate: currencyDelegate,
          toolSteps: toolSteps,
          generatedWidgets: generatedWidgets,
          parser: parser,
          onUpdate: onUpdate,
        );
      } else {
        // OpenAI / OpenRouter / Groq / Ollama
        await _executeOpenAICompatibleStream(
          prompt: prompt,
          imageBytes: imageBytes,
          systemPrompt: systemPrompt,
          history: history,
          config: config,
          snapshot: snapshot,
          mathDelegate: mathDelegate,
          currencyDelegate: currencyDelegate,
          toolSteps: toolSteps,
          generatedWidgets: generatedWidgets,
          parser: parser,
          onUpdate: onUpdate,
        );
      }

      parser.finalize();

      // Check fallback markdown regex if no widgets were emitted yet
      _extractFallbackMarkdownTools(
        text: parser.accumulatedText,
        snapshot: snapshot,
        mathDelegate: mathDelegate,
        currencyDelegate: currencyDelegate,
        generatedWidgets: generatedWidgets,
        toolSteps: toolSteps,
        onUpdate: (step, widget) {
          onUpdate(
            textDelta: '',
            accumulatedText: parser.accumulatedText,
            accumulatedThinking: parser.accumulatedThinking,
            isThinking: false,
            newStep: step,
            newWidget: widget,
          );
        },
      );

      final thinking = parser.accumulatedThinking.trim();

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        role: MessageRole.assistant,
        content: parser.accumulatedText.isEmpty && generatedWidgets.isNotEmpty
            ? '### Analysis & Recommendations'
            : parser.accumulatedText,
        thinkingContent: thinking.isNotEmpty ? thinking : null,
        thinkingDuration: parser.thinkingDuration,
        isThinking: false,
        timestamp: DateTime.now(),
        steps: toolSteps,
        generativeWidgets: generatedWidgets,
      );
    } catch (e) {
      if (_isCancelled) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: sessionId,
          role: MessageRole.assistant,
          content: '${parser.accumulatedText}\n\n*(Generation stopped by user)*',
          thinkingContent: parser.accumulatedThinking.isNotEmpty ? parser.accumulatedThinking : null,
          thinkingDuration: parser.thinkingDuration,
          timestamp: DateTime.now(),
          steps: toolSteps,
          generativeWidgets: generatedWidgets,
        );
      }
      rethrow;
    } finally {
      _activeClient?.close();
      _activeClient = null;
    }
  }

  /// OpenAI / OpenRouter / Groq / Ollama Compatible Stream Handler
  Future<void> _executeOpenAICompatibleStream({
    required String prompt,
    Uint8List? imageBytes,
    required String systemPrompt,
    required List<Map<String, dynamic>> history,
    required AIConfig config,
    required AIPortfolioSnapshot snapshot,
    AIMathEngineDelegate? mathDelegate,
    AICurrencyDelegate? currencyDelegate,
    required List<ToolExecutionStep> toolSteps,
    required List<GenerativeUIPayload> generatedWidgets,
    required StreamingThinkingParser parser,
    required StreamUpdateCallback onUpdate,
  }) async {
    final url = Uri.parse('${config.baseUrl}/chat/completions');
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...history,
    ];

    if (imageBytes != null) {
      final base64Image = base64Encode(imageBytes);
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
        ],
      });
    } else {
      messages.add({'role': 'user', 'content': prompt});
    }

    final tools = AIFinancialToolDefinitions.getAllToolSchemas().map((t) {
      return {
        'type': 'function',
        'function': {
          'name': t['name'],
          'description': t['description'],
          'parameters': t['parameters'],
        },
      };
    }).toList();

    final reqBody = {
      'model': config.modelName,
      'messages': messages,
      'tools': tools,
      'tool_choice': 'auto',
      'temperature': config.temperature,
      'stream': true,
    };

    final headers = <String, String>{'content-type': 'application/json'};
    if (config.apiKey.isNotEmpty) {
      headers['authorization'] = 'Bearer ${config.apiKey}';
    }

    final req = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(reqBody);

    final streamedRes = await _activeClient!.send(req);
    if (streamedRes.statusCode != 200) {
      final errBody = await streamedRes.stream.bytesToString();
      throw Exception('AI Provider Error (${streamedRes.statusCode}): $errBody');
    }

    final toolCallsAccumulator = <int, Map<String, dynamic>>{};

    await for (final line in streamedRes.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (_isCancelled) break;
      if (!line.startsWith('data: ')) continue;
      final dataStr = line.substring(6).trim();
      if (dataStr == '[DONE]') break;

      try {
        final data = jsonDecode(dataStr) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) continue;

        final delta = choices[0]['delta'] as Map<String, dynamic>?;
        if (delta == null) continue;

        // Native reasoning delta (e.g. DeepSeek-R1, OpenAI o1/o3-mini)
        if (delta.containsKey('reasoning_content') && delta['reasoning_content'] != null) {
          final r = delta['reasoning_content'] as String;
          parser.feedNativeReasoning(r);
          onUpdate(
            textDelta: '',
            accumulatedText: parser.accumulatedText,
            thinkingDelta: r,
            accumulatedThinking: parser.accumulatedThinking,
            isThinking: true,
            thinkingDuration: parser.thinkingDuration,
          );
        } else if (delta.containsKey('reasoning') && delta['reasoning'] != null) {
          final r = delta['reasoning'] as String;
          parser.feedNativeReasoning(r);
          onUpdate(
            textDelta: '',
            accumulatedText: parser.accumulatedText,
            thinkingDelta: r,
            accumulatedThinking: parser.accumulatedThinking,
            isThinking: true,
            thinkingDuration: parser.thinkingDuration,
          );
        }

        // Standard Content delta (with potential <think> tags)
        if (delta.containsKey('content') && delta['content'] != null) {
          final c = delta['content'] as String;
          parser.feedContent(c);
          onUpdate(
            textDelta: c,
            accumulatedText: parser.accumulatedText,
            thinkingDelta: '',
            accumulatedThinking: parser.accumulatedThinking,
            isThinking: parser.isThinking,
            thinkingDuration: parser.thinkingDuration,
          );
        }

        // Tool calls delta
        if (delta.containsKey('tool_calls') && delta['tool_calls'] != null) {
          final tcs = delta['tool_calls'] as List<dynamic>;
          for (final tc in tcs) {
            final idx = (tc['index'] as num?)?.toInt() ?? 0;
            if (!toolCallsAccumulator.containsKey(idx)) {
              toolCallsAccumulator[idx] = {
                'id': tc['id'] ?? '',
                'name': tc['function']?['name'] ?? '',
                'arguments': '',
              };
            }
            if (tc['function']?['name'] != null && (tc['function']['name'] as String).isNotEmpty) {
              toolCallsAccumulator[idx]!['name'] = tc['function']['name'];
            }
            if (tc['function']?['arguments'] != null) {
              toolCallsAccumulator[idx]!['arguments'] =
                  (toolCallsAccumulator[idx]!['arguments'] as String) + (tc['function']['arguments'] as String);
            }
          }
        }
      } catch (_) {}
    }

    // Execute any accumulated tool calls
    for (final tc in toolCallsAccumulator.values) {
      final name = tc['name'] as String;
      final argsStr = tc['arguments'] as String;
      if (name.isEmpty) continue;

      Map<String, dynamic> args = {};
      try {
        args = jsonDecode(argsStr) as Map<String, dynamic>;
      } catch (_) {}

      final step = ToolExecutionStep(
        toolName: name,
        description: 'Executing $name...',
        state: ToolExecutionState.running,
        timestamp: DateTime.now(),
      );
      onUpdate(
        textDelta: '',
        accumulatedText: parser.accumulatedText,
        accumulatedThinking: parser.accumulatedThinking,
        isThinking: false,
        newStep: step,
      );

      final widget = await _executeTool(
        toolName: name,
        args: args,
        snapshot: snapshot,
        mathDelegate: mathDelegate,
        currencyDelegate: currencyDelegate,
      );

      final completedStep = ToolExecutionStep(
        toolName: name,
        description: '✓ Completed $name',
        state: ToolExecutionState.completed,
        timestamp: DateTime.now(),
      );

      if (widget != null) {
        generatedWidgets.add(widget);
        toolSteps.add(completedStep);
        onUpdate(
          textDelta: '',
          accumulatedText: parser.accumulatedText,
          accumulatedThinking: parser.accumulatedThinking,
          isThinking: false,
          newStep: completedStep,
          newWidget: widget,
        );
      }
    }
  }

  /// Google Gemini Stream Handler
  Future<void> _executeGeminiStream({
    required String prompt,
    Uint8List? imageBytes,
    required String systemPrompt,
    required List<Map<String, dynamic>> history,
    required AIConfig config,
    required AIPortfolioSnapshot snapshot,
    AIMathEngineDelegate? mathDelegate,
    AICurrencyDelegate? currencyDelegate,
    required List<ToolExecutionStep> toolSteps,
    required List<GenerativeUIPayload> generatedWidgets,
    required StreamingThinkingParser parser,
    required StreamUpdateCallback onUpdate,
  }) async {
    final url = Uri.parse(
      '${config.baseUrl}/models/${config.modelName}:streamGenerateContent?alt=sse&key=${config.apiKey}',
    );

    final contents = <Map<String, dynamic>>[];

    for (final m in history) {
      contents.add({
        'role': m['role'] == 'user' ? 'user' : 'model',
        'parts': [{'text': m['content']}],
      });
    }

    final userParts = <Map<String, dynamic>>[];
    userParts.add({'text': prompt});
    if (imageBytes != null) {
      userParts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': base64Encode(imageBytes),
        },
      });
    }
    contents.add({'role': 'user', 'parts': userParts});

    final tools = [
      {
        'functionDeclarations': AIFinancialToolDefinitions.getAllToolSchemas().map((t) {
          return {
            'name': t['name'],
            'description': t['description'],
            'parameters': t['parameters'],
          };
        }).toList(),
      }
    ];

    final reqBody = {
      'systemInstruction': {
        'parts': [{'text': systemPrompt}]
      },
      'contents': contents,
      'tools': tools,
      'generationConfig': {
        'temperature': config.temperature,
      },
    };

    final req = http.Request('POST', url)
      ..headers.addAll({'content-type': 'application/json'})
      ..body = jsonEncode(reqBody);

    final streamedRes = await _activeClient!.send(req);
    if (streamedRes.statusCode != 200) {
      final errBody = await streamedRes.stream.bytesToString();
      throw Exception('Gemini Error (${streamedRes.statusCode}): $errBody');
    }

    await for (final line in streamedRes.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (_isCancelled) break;
      if (!line.startsWith('data: ')) continue;
      final dataStr = line.substring(6).trim();
      if (dataStr.isEmpty) continue;

      try {
        final data = jsonDecode(dataStr) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) continue;

        final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
        if (parts == null) continue;

        for (final part in parts) {
          // Native thought in Gemini
          if (part.containsKey('thought') && part['thought'] != null) {
            final t = part['thought'] as String;
            parser.feedNativeReasoning(t);
            onUpdate(
              textDelta: '',
              accumulatedText: parser.accumulatedText,
              thinkingDelta: t,
              accumulatedThinking: parser.accumulatedThinking,
              isThinking: true,
              thinkingDuration: parser.thinkingDuration,
            );
          }

          // Text content
          if (part.containsKey('text') && part['text'] != null) {
            final t = part['text'] as String;
            parser.feedContent(t);
            onUpdate(
              textDelta: t,
              accumulatedText: parser.accumulatedText,
              thinkingDelta: '',
              accumulatedThinking: parser.accumulatedThinking,
              isThinking: parser.isThinking,
              thinkingDuration: parser.thinkingDuration,
            );
          }

          // Function Calls
          if (part.containsKey('functionCall') && part['functionCall'] != null) {
            final fc = part['functionCall'] as Map<String, dynamic>;
            final name = fc['name'] as String;
            final args = (fc['args'] as Map<String, dynamic>?) ?? {};

            final step = ToolExecutionStep(
              toolName: name,
              description: 'Executing $name...',
              state: ToolExecutionState.running,
              timestamp: DateTime.now(),
            );
            onUpdate(
              textDelta: '',
              accumulatedText: parser.accumulatedText,
              accumulatedThinking: parser.accumulatedThinking,
              isThinking: false,
              newStep: step,
            );

            final widget = await _executeTool(
              toolName: name,
              args: args,
              snapshot: snapshot,
              mathDelegate: mathDelegate,
              currencyDelegate: currencyDelegate,
            );

            final completedStep = ToolExecutionStep(
              toolName: name,
              description: '✓ Completed $name',
              state: ToolExecutionState.completed,
              timestamp: DateTime.now(),
            );

            if (widget != null) {
              generatedWidgets.add(widget);
              toolSteps.add(completedStep);
              onUpdate(
                textDelta: '',
                accumulatedText: parser.accumulatedText,
                accumulatedThinking: parser.accumulatedThinking,
                isThinking: false,
                newStep: completedStep,
                newWidget: widget,
              );
            }
          }
        }
      } catch (_) {}
    }
  }

  /// Anthropic Claude Stream Handler
  Future<void> _executeClaudeStream({
    required String prompt,
    required String systemPrompt,
    required List<Map<String, dynamic>> history,
    required AIConfig config,
    required AIPortfolioSnapshot snapshot,
    AIMathEngineDelegate? mathDelegate,
    AICurrencyDelegate? currencyDelegate,
    required List<ToolExecutionStep> toolSteps,
    required List<GenerativeUIPayload> generatedWidgets,
    required StreamingThinkingParser parser,
    required StreamUpdateCallback onUpdate,
  }) async {
    final url = Uri.parse('${config.baseUrl}/messages');
    final messages = <Map<String, dynamic>>[
      ...history,
      {'role': 'user', 'content': prompt},
    ];

    final tools = AIFinancialToolDefinitions.getAllToolSchemas().map((t) {
      return {
        'name': t['name'],
        'description': t['description'],
        'input_schema': t['parameters'],
      };
    }).toList();

    final reqBody = {
      'model': config.modelName,
      'system': systemPrompt,
      'messages': messages,
      'tools': tools,
      'max_tokens': 4096,
      'stream': true,
    };

    final headers = {
      'x-api-key': config.apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    };

    final req = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(reqBody);

    final streamedRes = await _activeClient!.send(req);
    if (streamedRes.statusCode != 200) {
      final errBody = await streamedRes.stream.bytesToString();
      throw Exception('Claude Error (${streamedRes.statusCode}): $errBody');
    }

    await for (final line in streamedRes.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (_isCancelled) break;
      if (!line.startsWith('data: ')) continue;
      final dataStr = line.substring(6).trim();

      try {
        final data = jsonDecode(dataStr) as Map<String, dynamic>;
        final type = data['type'] as String?;

        if (type == 'content_block_delta') {
          final delta = data['delta'] as Map<String, dynamic>?;
          if (delta != null) {
            // Claude thinking delta
            if (delta['type'] == 'thinking_delta') {
              final t = delta['thinking'] as String? ?? '';
              parser.feedNativeReasoning(t);
              onUpdate(
                textDelta: '',
                accumulatedText: parser.accumulatedText,
                thinkingDelta: t,
                accumulatedThinking: parser.accumulatedThinking,
                isThinking: true,
                thinkingDuration: parser.thinkingDuration,
              );
            } else if (delta['type'] == 'text_delta') {
              final t = delta['text'] as String? ?? '';
              parser.feedContent(t);
              onUpdate(
                textDelta: t,
                accumulatedText: parser.accumulatedText,
                thinkingDelta: '',
                accumulatedThinking: parser.accumulatedThinking,
                isThinking: parser.isThinking,
                thinkingDuration: parser.thinkingDuration,
              );
            }
          }
        }
      } catch (_) {}
    }
  }

  /// Tool Execution Router
  Future<GenerativeUIPayload?> _executeTool({
    required String toolName,
    required Map<String, dynamic> args,
    required AIPortfolioSnapshot snapshot,
    AIMathEngineDelegate? mathDelegate,
    AICurrencyDelegate? currencyDelegate,
  }) async {
    final widgetId = 'gen_${DateTime.now().millisecondsSinceEpoch}_${toolName.hashCode.abs()}';

    switch (toolName) {
      case AIFinancialToolDefinitions.toolRunMonteCarlo:
        final currentPort = (args['currentPortfolio'] as num?)?.toDouble() ?? snapshot.totalNetWorth;
        final savings = (args['annualSavings'] as num?)?.toDouble() ?? 300000.0;
        final expectedRet = (args['expectedReturn'] as num?)?.toDouble() ?? 12.0;
        final vol = (args['volatility'] as num?)?.toDouble() ?? 15.0;
        final years = (args['years'] as num?)?.toInt() ?? 20;
        final sims = (args['simulations'] as num?)?.toInt() ?? 1000;

        if (mathDelegate != null) {
          final res = await mathDelegate.runMonteCarlo(
            currentPortfolio: currentPort,
            annualSavings: savings,
            expectedReturn: expectedRet,
            volatility: vol,
            years: years,
            simulations: sims,
          );
          return MonteCarloCurvePayload(
            widgetId: widgetId,
            probabilityOfSuccess: (res['probabilityOfSuccess'] as num?)?.toDouble() ?? 90.0,
            years: (res['years'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [0, 5, 10, 15, 20],
            p10Curve: (res['p10Curve'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
            p50Curve: (res['p50Curve'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
            p90Curve: (res['p90Curve'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
            simulationsCount: sims,
            currencySymbol: snapshot.currencySymbol,
          );
        }
        return null;

      case AIFinancialToolDefinitions.toolRunStressTest:
        final netWorth = snapshot.totalNetWorth;
        return StressTestResultPayload(
          widgetId: widgetId,
          overallResilienceScore: 82.0,
          scenarios: [
            StressTestScenarioItem(
              name: '2008 Global Financial Crisis',
              marketDropPercent: -52.0,
              portfolioImpactPercent: -28.4,
              projectedLossAmount: netWorth * 0.284,
              recoveryMonths: '24 Months',
            ),
            StressTestScenarioItem(
              name: 'Covid-19 Liquidity Shock',
              marketDropPercent: -38.0,
              portfolioImpactPercent: -21.0,
              projectedLossAmount: netWorth * 0.21,
              recoveryMonths: '8 Months',
            ),
            StressTestScenarioItem(
              name: 'Stagflation & Rate Hike Regime',
              marketDropPercent: -25.0,
              portfolioImpactPercent: -12.5,
              projectedLossAmount: netWorth * 0.125,
              recoveryMonths: '18 Months',
            ),
          ],
        );

      case AIFinancialToolDefinitions.toolCalculateFire:
        final netWorth = snapshot.totalNetWorth;
        final annualExpenses = (args['annualExpenses'] as num?)?.toDouble() ?? (netWorth * 0.04);
        final swr = (args['safeWithdrawalRate'] as num?)?.toDouble() ?? 4.0;
        final fireNum = annualExpenses / (swr / 100);

        return KpiMetricPayload(
          widgetId: widgetId,
          title: 'Target FIRE Corpus ($swr% SWR)',
          value: currencyDelegate != null ? currencyDelegate.compactAmount(fireNum) : '${snapshot.currencySymbol}${fireNum.toStringAsFixed(0)}',
          subtitle: 'Annual Expenses: ${currencyDelegate != null ? currencyDelegate.compactAmount(annualExpenses) : annualExpenses.toStringAsFixed(0)}',
          changePercent: netWorth > 0 ? (netWorth / fireNum) * 100 : 0.0,
          isPositive: true,
        );

      case AIFinancialToolDefinitions.toolCalculateSwp:
        final corpus = (args['corpus'] as num?)?.toDouble() ?? snapshot.totalNetWorth;
        final monthlyWithdrawal = (args['initialMonthlyWithdrawal'] as num?)?.toDouble() ?? (corpus * 0.04 / 12);
        final inflation = (args['inflationRate'] as num?)?.toDouble() ?? 6.0;
        final expReturn = (args['expectedReturn'] as num?)?.toDouble() ?? 10.0;
        final years = (args['years'] as num?)?.toInt() ?? 30;

        final curve = <double>[];
        var remaining = corpus;
        var currentMonthly = monthlyWithdrawal;
        int? depletionYear;

        for (int y = 0; y <= years; y++) {
          curve.add(remaining.clamp(0.0, double.infinity));
          if (remaining <= 0 && depletionYear == null) {
            depletionYear = y;
          }
          final annualWithdrawn = currentMonthly * 12;
          remaining = (remaining - annualWithdrawn) * (1 + expReturn / 100);
          currentMonthly *= (1 + inflation / 100);
        }

        return SwpCashFlowPayload(
          widgetId: widgetId,
          initialCorpus: corpus,
          annualWithdrawal: monthlyWithdrawal * 12,
          isPerpetual: remaining > 0,
          depletionYear: depletionYear,
          remainingCorpusOverTime: curve,
          currencySymbol: snapshot.currencySymbol,
        );

      case AIFinancialToolDefinitions.toolRecommendGoalRebalance:
        final goalName = args['goalName'] as String? ?? 'FIRE Retirement';
        final goal = FinancialGoal(
          id: 'goal_$goalName',
          name: goalName,
          targetAmount: (args['targetAmount'] as num?)?.toDouble() ?? (snapshot.totalNetWorth * 2),
          targetYears: (args['targetYears'] as num?)?.toInt() ?? 15,
          targetEquitiesPercent: (args['targetEquitiesPercent'] as num?)?.toDouble() ?? 60.0,
          targetDebtPercent: (args['targetDebtPercent'] as num?)?.toDouble() ?? 30.0,
          targetGoldPercent: (args['targetGoldPercent'] as num?)?.toDouble() ?? 10.0,
        );

        final monthlySip = (args['monthlySipInflow'] as num?)?.toDouble() ?? 50000.0;
        return AIRebalancingEngine.calculateRebalance(
          snapshot: snapshot,
          goal: goal,
          monthlySipInflow: monthlySip,
        );

      case AIFinancialToolDefinitions.toolProposeAddAsset:
        final name = args['name'] as String? ?? 'New Asset';
        final catStr = args['category'] as String? ?? 'equities';
        final val = (args['currentValue'] as num?)?.toDouble() ?? 100000.0;
        final cagr = (args['expectedReturnPercent'] as num?)?.toDouble() ?? 12.0;

        final category = AIAssetCategory.values.firstWhere(
          (c) => c.name.toLowerCase() == catStr.toLowerCase(),
          orElse: () => AIAssetCategory.equities,
        );

        return ActionConfirmationPayload(
          widgetId: widgetId,
          actionId: 'add_${DateTime.now().millisecondsSinceEpoch}',
          actionType: 'addAsset',
          title: 'Confirm Investment Addition',
          description: 'Add $name to your live portfolio database.',
          assetToAdd: AIAssetEntry(
            id: 'asset_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            category: category,
            currentValue: val,
            expectedReturnPercent: cagr,
          ),
        );

      case AIFinancialToolDefinitions.toolProposeBatchImport:
        final rawAssets = (args['extractedAssets'] as List<dynamic>?) ?? [];
        final source = args['sourceDescription'] as String? ?? 'Imported Statement';
        final assets = rawAssets.map((a) {
          final m = a as Map<String, dynamic>;
          final cStr = m['category'] as String? ?? 'equities';
          final cat = AIAssetCategory.values.firstWhere(
            (c) => c.name.toLowerCase() == cStr.toLowerCase(),
            orElse: () => AIAssetCategory.equities,
          );
          return AIAssetEntry(
            id: 'imported_${DateTime.now().millisecondsSinceEpoch}_${m['name'].hashCode.abs()}',
            name: m['name'] as String? ?? 'Holding',
            category: cat,
            currentValue: (m['currentValue'] as num?)?.toDouble() ?? 0.0,
            expectedReturnPercent: (m['expectedReturnPercent'] as num?)?.toDouble() ?? 12.0,
          );
        }).toList();

        return BatchAssetImportPayload(
          widgetId: widgetId,
          importId: 'batch_${DateTime.now().millisecondsSinceEpoch}',
          sourceDescription: source,
          extractedAssets: assets,
        );

      case AIFinancialToolDefinitions.toolRenderKpiCard:
        return KpiMetricPayload(
          widgetId: widgetId,
          title: args['title'] as String? ?? 'Metric',
          value: args['value'] as String? ?? '₹0',
          subtitle: args['subtitle'] as String?,
          changePercent: (args['changePercent'] as num?)?.toDouble(),
          isPositive: args['isPositive'] as bool? ?? true,
        );

      case AIFinancialToolDefinitions.toolRenderAllocationChart:
        return AllocationChartPayload(
          widgetId: widgetId,
          slices: snapshot.categoryBreakdown.entries.map((e) {
            return AllocationSliceData(
              category: e.key.displayName,
              percentage: snapshot.totalNetWorth > 0 ? (e.value / snapshot.totalNetWorth) * 100 : 0.0,
              amount: e.value,
            );
          }).toList(),
          totalAmount: snapshot.totalNetWorth,
          currencySymbol: snapshot.currencySymbol,
        );

      case AIFinancialToolDefinitions.toolRenderScenarioSimulator:
        return ScenarioSimulatorPayload(
          widgetId: widgetId,
          initialNetWorth: (args['initialNetWorth'] as num?)?.toDouble() ?? snapshot.totalNetWorth,
          defaultExpectedReturn: (args['defaultExpectedReturn'] as num?)?.toDouble() ?? 12.0,
          defaultAnnualSavings: (args['defaultAnnualSavings'] as num?)?.toDouble() ?? 300000.0,
          defaultInflationRate: (args['defaultInflationRate'] as num?)?.toDouble() ?? 6.0,
          defaultYears: (args['defaultYears'] as num?)?.toInt() ?? 20,
          currencySymbol: snapshot.currencySymbol,
        );

      case AIFinancialToolDefinitions.toolGenerateAuditReport:
        return AuditReportPayload(
          widgetId: widgetId,
          healthScore: (args['healthScore'] as num?)?.toDouble() ?? 85.0,
          summary: args['summary'] as String? ?? 'Comprehensive diagnostic summary of wealth state.',
          strengths: ((args['strengths'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList(),
          risks: ((args['risks'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList(),
          actionPlan: ((args['actionPlan'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList(),
          rawMarkdown: args['rawMarkdown'] as String? ?? '',
        );

      default:
        return null;
    }
  }

  /// Dual-Layer Fallback Markdown Tool Parser
  void _extractFallbackMarkdownTools({
    required String text,
    required AIPortfolioSnapshot snapshot,
    AIMathEngineDelegate? mathDelegate,
    AICurrencyDelegate? currencyDelegate,
    required List<GenerativeUIPayload> generatedWidgets,
    required List<ToolExecutionStep> toolSteps,
    required void Function(ToolExecutionStep step, GenerativeUIPayload widget) onUpdate,
  }) async {
    final regex = RegExp(r'```json\s*(\{[\s\S]*?"tool"[\s\S]*?\})\s*```', multiLine: true);
    final matches = regex.allMatches(text);

    for (final match in matches) {
      final jsonStr = match.group(1);
      if (jsonStr == null) continue;

      try {
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final toolName = parsed['tool'] as String?;
        final args = (parsed['parameters'] as Map<String, dynamic>?) ?? (parsed['args'] as Map<String, dynamic>?) ?? {};

        if (toolName != null) {
          final step = ToolExecutionStep(
            toolName: toolName,
            description: 'Executing $toolName (markdown fallback)...',
            state: ToolExecutionState.completed,
            timestamp: DateTime.now(),
          );
          final widget = await _executeTool(
            toolName: toolName,
            args: args,
            snapshot: snapshot,
            mathDelegate: mathDelegate,
            currencyDelegate: currencyDelegate,
          );
          if (widget != null) {
            generatedWidgets.add(widget);
            toolSteps.add(step);
            onUpdate(step, widget);
          }
        }
      } catch (_) {}
    }
  }
}
