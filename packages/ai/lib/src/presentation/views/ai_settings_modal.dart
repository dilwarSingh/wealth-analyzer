import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/contracts/ai_portfolio_contract.dart';
import '../../domain/entities/ai_config.dart';
import '../viewmodels/ai_settings_viewmodel.dart';
import '../widgets/ai_glass_card.dart';

class AISettingsModal extends ConsumerStatefulWidget {
  final AIThemeData theme;

  const AISettingsModal({super.key, required this.theme});

  @override
  ConsumerState<AISettingsModal> createState() => _AISettingsModalState();
}

class _AISettingsModalState extends ConsumerState<AISettingsModal> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  bool _isTesting = false;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiSettingsProvider);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _baseUrlController = TextEditingController(text: config.baseUrl);
    _modelController = TextEditingController(text: config.modelName);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final config = ref.watch(aiSettingsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: AIGlassCard(
          theme: theme,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.secondaryAccentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.psychology_rounded, color: theme.secondaryAccentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Advisor Configuration',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            'Model & Provider Settings',
                            style: GoogleFonts.inter(fontSize: 11, color: theme.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: theme.textSecondaryColor, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Provider Selector Chips
                Text(
                  'Select AI Provider:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AIProviderType.values.map((p) {
                    final isSelected = config.provider == p;
                    return InkWell(
                      onTap: () {
                        ref.read(aiSettingsProvider.notifier).setProvider(p);
                        _baseUrlController.text = p.defaultBaseUrl;
                        _modelController.text = p.defaultModels.first;
                        setState(() => _testResult = null);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.secondaryAccentColor.withOpacity(0.2) : theme.surfaceLightColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? theme.secondaryAccentColor : theme.borderColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          p.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? theme.secondaryAccentColor : theme.textPrimaryColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // API Key Field (if needed)
                if (config.provider.requiresApiKey) ...[
                  Text(
                    'API Key:',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    style: GoogleFonts.inter(fontSize: 13, color: theme.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: 'sk-...',
                      hintStyle: GoogleFonts.inter(color: theme.textMutedColor, fontSize: 13),
                      filled: true,
                      fillColor: theme.surfaceLightColor.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.secondaryAccentColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) => ref.read(aiSettingsProvider.notifier).setApiKey(val),
                  ),
                  const SizedBox(height: 14),
                ],

                // Model Selection
                Text(
                  'Model Name / Preset:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _modelController,
                        style: GoogleFonts.inter(fontSize: 13, color: theme.textPrimaryColor),
                        decoration: InputDecoration(
                          hintText: 'model-name',
                          hintStyle: GoogleFonts.inter(color: theme.textMutedColor, fontSize: 13),
                          filled: true,
                          fillColor: theme.surfaceLightColor.withOpacity(0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.secondaryAccentColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) => ref.read(aiSettingsProvider.notifier).setModelName(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.arrow_drop_down_circle_outlined, color: theme.secondaryAccentColor),
                      color: theme.surfaceLightColor,
                      onSelected: (model) {
                        _modelController.text = model;
                        ref.read(aiSettingsProvider.notifier).setModelName(model);
                      },
                      itemBuilder: (ctx) => config.provider.defaultModels.map((m) {
                        return PopupMenuItem(
                          value: m,
                          child: Text(m, style: GoogleFonts.inter(fontSize: 12, color: theme.textPrimaryColor)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Base URL Field
                Text(
                  'Endpoint Base URL:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _baseUrlController,
                  style: GoogleFonts.inter(fontSize: 12, color: theme.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    hintStyle: GoogleFonts.inter(color: theme.textMutedColor, fontSize: 12),
                    filled: true,
                    fillColor: theme.surfaceLightColor.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => ref.read(aiSettingsProvider.notifier).setBaseUrl(val),
                ),
                const SizedBox(height: 18),

                // Privacy Mode Dropdown
                Text(
                  'Financial Data Privacy Mode:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.surfaceLightColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.borderColor.withOpacity(0.3)),
                  ),
                  child: DropdownButton<ContextPrivacyMode>(
                    value: config.privacyMode,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: theme.surfaceLightColor,
                    items: ContextPrivacyMode.values.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(
                          mode.displayName,
                          style: GoogleFonts.inter(fontSize: 12.5, color: theme.textPrimaryColor),
                        ),
                      );
                    }).toList(),
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(aiSettingsProvider.notifier).setPrivacyMode(mode);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Percentage Anonymization Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Anonymize Net Worth (Percentage Mode)',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textPrimaryColor),
                  ),
                  subtitle: Text(
                    'Normalizes dollar values into percentage ratios before transmitting to AI.',
                    style: GoogleFonts.inter(fontSize: 10.5, color: theme.textMutedColor),
                  ),
                  activeColor: theme.secondaryAccentColor,
                  value: config.anonymizeValues,
                  onChanged: (val) => ref.read(aiSettingsProvider.notifier).toggleAnonymizeValues(val),
                ),
                const SizedBox(height: 6),

                // Auto Prompt Privacy Dialog Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Prompt Data Sharing on New Chat',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textPrimaryColor),
                  ),
                  subtitle: Text(
                    'Automatically opens Data Sharing Dialog when starting a new advisory thread.',
                    style: GoogleFonts.inter(fontSize: 10.5, color: theme.textMutedColor),
                  ),
                  activeColor: theme.secondaryAccentColor,
                  value: config.autoShowPrivacyDialog,
                  onChanged: (val) => ref.read(aiSettingsProvider.notifier).toggleAutoShowPrivacyDialog(val),
                ),
                const SizedBox(height: 20),

                // Test Connection & Save Action Buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isTesting
                          ? null
                          : () async {
                              setState(() {
                                _isTesting = true;
                                _testResult = null;
                              });
                              final res = await ref.read(aiSettingsProvider.notifier).testConnection();
                              if (mounted) {
                                setState(() {
                                  _isTesting = false;
                                  _testResult = res;
                                });
                              }
                            },
                      icon: _isTesting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(
                              _testResult == null
                                  ? Icons.wifi_protected_setup_rounded
                                  : (_testResult! ? Icons.check_circle_rounded : Icons.error_outline_rounded),
                              size: 16,
                              color: _testResult == null
                                  ? theme.textSecondaryColor
                                  : (_testResult! ? theme.successColor : theme.primaryAccentColor),
                            ),
                      label: Text(
                        _isTesting
                            ? 'Testing...'
                            : (_testResult == null
                                ? 'Test Connection'
                                : (_testResult! ? 'Connected ✓' : 'Failed ✗')),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _testResult == null
                              ? theme.textSecondaryColor
                              : (_testResult! ? theme.successColor : theme.primaryAccentColor),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.borderColor.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryAccentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
