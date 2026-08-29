/// Supported AI Providers
enum AIProviderType {
  openAI,
  gemini,
  claude,
  openRouter,
  groq,
  customOllama;

  String get displayName {
    switch (this) {
      case AIProviderType.openAI:
        return 'OpenAI (GPT-4o)';
      case AIProviderType.gemini:
        return 'Google Gemini';
      case AIProviderType.claude:
        return 'Anthropic Claude';
      case AIProviderType.openRouter:
        return 'OpenRouter';
      case AIProviderType.groq:
        return 'Groq (Ultra-Fast)';
      case AIProviderType.customOllama:
        return 'Ollama / Local LLM';
    }
  }

  bool get requiresApiKey {
    return this != AIProviderType.customOllama;
  }

  String get defaultBaseUrl {
    switch (this) {
      case AIProviderType.openAI:
        return 'https://api.openai.com/v1';
      case AIProviderType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AIProviderType.claude:
        return 'https://api.anthropic.com/v1';
      case AIProviderType.openRouter:
        return 'https://openrouter.ai/api/v1';
      case AIProviderType.groq:
        return 'https://api.groq.com/openai/v1';
      case AIProviderType.customOllama:
        return 'http://127.0.0.1:11434/v1';
    }
  }

  List<String> get defaultModels {
    switch (this) {
      case AIProviderType.openAI:
        return ['gpt-4o', 'gpt-4o-mini', 'o3-mini'];
      case AIProviderType.gemini:
        return ['gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-1.5-pro'];
      case AIProviderType.claude:
        return ['claude-3-5-sonnet-latest', 'claude-3-5-haiku-latest', 'claude-3-opus-latest'];
      case AIProviderType.openRouter:
        return ['meta-llama/llama-3.3-70b-instruct', 'deepseek/deepseek-r1', 'google/gemini-2.0-flash-exp:free'];
      case AIProviderType.groq:
        return ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant', 'deepseek-r1-distill-llama-70b'];
      case AIProviderType.customOllama:
        return ['llama3.1:8b', 'qwen2.5:7b', 'mistral:7b', 'deepseek-r1:8b'];
    }
  }
}

/// Context privacy mode determining how much financial data is shared with the AI
enum ContextPrivacyMode {
  fullPortfolio,
  summaryOnly,
  promptOnly;

  String get displayName {
    switch (this) {
      case ContextPrivacyMode.fullPortfolio:
        return 'Full Portfolio (All Holdings)';
      case ContextPrivacyMode.summaryOnly:
        return 'Aggregated Summary (Totals & Categories)';
      case ContextPrivacyMode.promptOnly:
        return 'Prompt Only (No Context)';
    }
  }

  String get description {
    switch (this) {
      case ContextPrivacyMode.fullPortfolio:
        return 'Includes itemized asset names, categories, and values in AI prompt for deep personalized analysis.';
      case ContextPrivacyMode.summaryOnly:
        return 'Shares category percentages and net worth totals without individual asset holdings.';
      case ContextPrivacyMode.promptOnly:
        return 'Sends only your typed prompt. No financial data is transmitted.';
    }
  }
}

/// Persistent configuration for the AI subsystem
class AIConfig {
  final AIProviderType provider;
  final String apiKey;
  final String baseUrl;
  final String modelName;
  final double temperature;
  final ContextPrivacyMode privacyMode;
  final bool anonymizeValues; // If true, normalizes real amounts to percentages (100k dummy scale)
  final bool autoShowPrivacyDialog;

  const AIConfig({
    this.provider = AIProviderType.gemini,
    this.apiKey = '',
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
    this.modelName = 'gemini-2.0-flash',
    this.temperature = 0.3,
    this.privacyMode = ContextPrivacyMode.fullPortfolio,
    this.anonymizeValues = false,
    this.autoShowPrivacyDialog = true,
  });

  bool get isConfigured {
    if (!provider.requiresApiKey) return baseUrl.isNotEmpty;
    return apiKey.trim().isNotEmpty;
  }

  AIConfig copyWith({
    AIProviderType? provider,
    String? apiKey,
    String? baseUrl,
    String? modelName,
    double? temperature,
    ContextPrivacyMode? privacyMode,
    bool? anonymizeValues,
    bool? autoShowPrivacyDialog,
  }) {
    return AIConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      modelName: modelName ?? this.modelName,
      temperature: temperature ?? this.temperature,
      privacyMode: privacyMode ?? this.privacyMode,
      anonymizeValues: anonymizeValues ?? this.anonymizeValues,
      autoShowPrivacyDialog: autoShowPrivacyDialog ?? this.autoShowPrivacyDialog,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider.name,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'modelName': modelName,
    'temperature': temperature,
    'privacyMode': privacyMode.name,
    'anonymizeValues': anonymizeValues,
    'autoShowPrivacyDialog': autoShowPrivacyDialog,
  };

  factory AIConfig.fromJson(Map<String, dynamic> json) {
    final provider = AIProviderType.values.firstWhere(
      (e) => e.name == json['provider'],
      orElse: () => AIProviderType.gemini,
    );
    return AIConfig(
      provider: provider,
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? provider.defaultBaseUrl,
      modelName: json['modelName'] as String? ?? provider.defaultModels.first,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
      privacyMode: ContextPrivacyMode.values.firstWhere(
        (e) => e.name == json['privacyMode'],
        orElse: () => ContextPrivacyMode.fullPortfolio,
      ),
      anonymizeValues: json['anonymizeValues'] as bool? ?? false,
      autoShowPrivacyDialog: json['autoShowPrivacyDialog'] as bool? ?? true,
    );
  }
}
