import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/contracts/ai_portfolio_contract.dart';
import '../../domain/entities/ai_config.dart';
import '../../domain/entities/data_sharing_config.dart';
import '../viewmodels/ai_settings_viewmodel.dart';
import '../widgets/ai_glass_card.dart';

class AIDataSharingDialog extends ConsumerStatefulWidget {
  final AIPortfolioSnapshot snapshot;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;
  final AIDataSharingConfig initialConfig;
  final ValueChanged<AIDataSharingConfig> onSaved;

  const AIDataSharingDialog({
    super.key,
    required this.snapshot,
    required this.theme,
    this.currencyDelegate,
    required this.initialConfig,
    required this.onSaved,
  });

  @override
  ConsumerState<AIDataSharingDialog> createState() => _AIDataSharingDialogState();
}

class _AIDataSharingDialogState extends ConsumerState<AIDataSharingDialog> {
  static const Set<String> _allFireKeys = {
    'targetCorpus',
    'expenses',
    'swr',
    'timeline',
    'milestones',
  };

  static const Set<String> _allCfKeys = {
    'sips',
    'expenses',
    'inflow',
    'fcf',
  };

  static const Set<String> _allSummKeys = {
    'netWorth',
    'allocation',
    'assumptions',
  };

  late ContextPrivacyMode _privacyMode;
  late bool _anonymizeValues;
  late bool _includeTotalNetWorth;
  late bool _includeAssetAllocation;
  late bool _includeCashFlows;
  late bool _includeFireMetrics;
  late Set<AIAssetCategory> _includedCategories;
  late Set<String> _excludedSubcategories;
  late Set<String> _excludedAssetIds;
  late Set<String> _includedFireMetrics;
  late Set<String> _includedCashFlowItems;
  late Set<String> _includedSummaryItems;
  late bool _rememberForFuture;

  // FIRE Target state
  String _selectedFireTargetType = 'Standard';
  late final TextEditingController _customFireTargetController;
  double? _customTargetValue;

  // Expansion state maps
  final Set<String> _expandedCategories = {};
  bool _isFireExpanded = false;
  bool _isCashFlowExpanded = false;
  bool _isSummaryExpanded = false;

  @override
  void initState() {
    super.initState();
    final cfg = widget.initialConfig;
    _privacyMode = cfg.privacyMode;
    _anonymizeValues = cfg.anonymizeValues;
    _includeTotalNetWorth = cfg.includeTotalNetWorth;
    _includeAssetAllocation = cfg.includeAssetAllocation;
    _includeCashFlows = cfg.includeCashFlows;
    _includeFireMetrics = cfg.includeFireMetrics;
    _includedCategories = Set.from(cfg.includedCategories);
    _excludedSubcategories = Set.from(cfg.excludedSubcategories);
    _excludedAssetIds = Set.from(cfg.excludedAssetIds);
    _includedFireMetrics = Set.from(cfg.includedFireMetrics)..remove('flavors');
    _includedCashFlowItems = Set.from(cfg.includedCashFlowItems);
    _includedSummaryItems = Set.from(cfg.includedSummaryItems);
    _rememberForFuture = cfg.rememberForFutureSessions;

    _customFireTargetController = TextEditingController(
      text: widget.snapshot.fireMetrics.fireNumber.toStringAsFixed(0),
    );

    // Default uncheck categories with 0 holdings
    for (final cat in AIAssetCategory.values) {
      final catAssets = widget.snapshot.assets.where((a) => a.category == cat).toList();
      if (catAssets.isEmpty) {
        _includedCategories.remove(cat);
      } else {
        // Expand populated categories by default
        _expandedCategories.add(cat.name);
      }
    }
  }

  @override
  void dispose() {
    _customFireTargetController.dispose();
    super.dispose();
  }

  double _getEffectiveFireTarget() {
    final fire = widget.snapshot.fireMetrics;
    switch (_selectedFireTargetType) {
      case 'Lean':
        return fire.leanFireNumber > 0 ? fire.leanFireNumber : fire.fireNumber * 0.75;
      case 'Fat':
        return fire.fatFireNumber > 0 ? fire.fatFireNumber : fire.fireNumber * 1.35;
      case 'Coast':
        return fire.coastFireNumber > 0 ? fire.coastFireNumber : fire.fireNumber * 0.5;
      case 'Barista':
        return fire.baristaFireNumber > 0 ? fire.baristaFireNumber : fire.fireNumber * 0.6;
      case 'Custom':
        return _customTargetValue ?? double.tryParse(_customFireTargetController.text) ?? fire.fireNumber;
      case 'Standard':
      default:
        return fire.fireNumber;
    }
  }

  // --- Helper for Holding Inclusion ---
  bool _isHoldingSelected(AIAssetEntry a) {
    if (!_includedCategories.contains(a.category)) return false;
    if (_excludedAssetIds.contains(a.id)) return false;
    final sub = (a.subCategory != null && a.subCategory!.isNotEmpty)
        ? a.subCategory!
        : ((a.notes != null && a.notes!.isNotEmpty) ? a.notes! : 'General');
    if (_excludedSubcategories.contains(sub)) return false;
    return true;
  }

  // --- Helpers for Formatting ---
  String _formatAmount(double amount) {
    if (widget.currencyDelegate != null) {
      return widget.currencyDelegate!.compactAmount(amount);
    }
    final sym = widget.snapshot.currencySymbol;
    return '$sym${amount.toStringAsFixed(0)}';
  }

  String _formatAssetVal(double val) {
    if (_anonymizeValues) {
      final total = widget.snapshot.totalNetWorth;
      final pct = total > 0 ? (val / total) * 100 : 0.0;
      return '${pct.toStringAsFixed(1)}%';
    }
    return _formatAmount(val);
  }

  String _formatSip(double sip) {
    if (_anonymizeValues) {
      final totalSips = widget.snapshot.assets.where((a) => a.isSip).fold(0.0, (s, a) => s + a.monthlySipAmount);
      final pct = totalSips > 0 ? (sip / totalSips) * 100 : 0.0;
      return '${pct.toStringAsFixed(1)}% SIP';
    }
    return '${_formatAmount(sip)}/mo';
  }

  void _handleSave() {
    final effectiveTarget = _getEffectiveFireTarget();
    final updated = AIDataSharingConfig(
      includeTotalNetWorth: _includeTotalNetWorth,
      includeAssetAllocation: _includeAssetAllocation,
      includeCashFlows: _includeCashFlows,
      includeFireMetrics: _includeFireMetrics,
      includedCategories: _includedCategories,
      excludedSubcategories: _excludedSubcategories,
      excludedAssetIds: _excludedAssetIds,
      includedFireMetrics: _includedFireMetrics,
      includedCashFlowItems: _includedCashFlowItems,
      includedSummaryItems: _includedSummaryItems,
      selectedFireTarget: effectiveTarget,
      privacyMode: _privacyMode,
      anonymizeValues: _anonymizeValues,
      rememberForFutureSessions: _rememberForFuture,
    );

    if (_rememberForFuture) {
      final globalConfig = ref.read(aiSettingsProvider);
      ref.read(aiSettingsProvider.notifier).updateConfig(
        globalConfig.copyWith(
          privacyMode: _privacyMode,
          anonymizeValues: _anonymizeValues,
          autoShowPrivacyDialog: !_rememberForFuture,
        ),
      );
    }

    widget.onSaved(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isPromptOnly = _privacyMode == ContextPrivacyMode.promptOnly;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
        child: AIGlassCard(
          theme: theme,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              _buildHeader(theme),
              const SizedBox(height: 12),
              Divider(color: theme.borderColor.withOpacity(0.2), height: 1),
              const SizedBox(height: 12),

              // 2. Global Privacy Mode & Anonymize Controls
              _buildTopPrivacyControls(theme),
              const SizedBox(height: 12),
              Divider(color: theme.borderColor.withOpacity(0.2), height: 1),
              const SizedBox(height: 12),

              // 3. Scrollable Tree Body
              Expanded(
                child: isPromptOnly
                    ? _buildPromptOnlyBanner(theme)
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Non-Asset Section 1: FIRE Portfolio
                            _buildFireAccordion(theme),
                            const SizedBox(height: 8),

                            // Non-Asset Section 2: Cash Flows & SIPs
                            _buildCashFlowAccordion(theme),
                            const SizedBox(height: 8),

                            // Non-Asset Section 3: Summary & Assumptions
                            _buildSummaryAccordion(theme),
                            const SizedBox(height: 14),

                            // Section 4: 3-Tier Asset Hierarchy Tree
                            Text(
                              'Portfolio Holdings & Asset Classes:',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: theme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildAssetHierarchyTree(theme),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 12),
              Divider(color: theme.borderColor.withOpacity(0.2), height: 1),
              const SizedBox(height: 10),

              // 4. Footer & Actions
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AIThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.secondaryAccentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.shield_outlined, color: theme.secondaryAccentColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Sharing & Context Privacy Controls',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimaryColor,
                ),
              ),
              Text(
                'Review and select the exact assets, FIRE goals, and cash flows shared with AI',
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
    );
  }

  Widget _buildTopPrivacyControls(AIThemeData theme) {
    final isPromptOnly = _privacyMode == ContextPrivacyMode.promptOnly;

    return Row(
      children: [
        // Privacy Mode Dropdown
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Data Privacy Mode:',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 38,
                decoration: BoxDecoration(
                  color: theme.surfaceLightColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderColor.withOpacity(0.3)),
                ),
                child: DropdownButton<ContextPrivacyMode>(
                  value: _privacyMode,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: theme.surfaceLightColor,
                  items: ContextPrivacyMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(
                        mode.displayName,
                        style: GoogleFonts.inter(fontSize: 12, color: theme.textPrimaryColor),
                      ),
                    );
                  }).toList(),
                  onChanged: (mode) {
                    if (mode != null) setState(() => _privacyMode = mode);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Anonymize Switch
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surfaceLightColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.borderColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Anonymize Values',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textPrimaryColor),
                      ),
                      Text(
                        _anonymizeValues ? 'Percentages Mode' : 'Exact Currency Mode',
                        style: GoogleFonts.inter(fontSize: 10, color: theme.textMutedColor),
                      ),
                    ],
                  ),
                ),
                Switch(
                  activeColor: theme.secondaryAccentColor,
                  value: _anonymizeValues,
                  onChanged: isPromptOnly ? null : (val) => setState(() => _anonymizeValues = val),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptOnlyBanner(AIThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: theme.secondaryAccentColor),
            const SizedBox(height: 12),
            Text(
              'Zero Financial Data Shared',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textPrimaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Prompt-Only mode active. The AI will operate purely as a conversational companion without access to your net worth, holdings, cash flows, or FIRE metrics.',
              style: GoogleFonts.inter(fontSize: 12, color: theme.textSecondaryColor, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Accordion 1: FIRE Portfolio ---
  Widget _buildFireAccordion(AIThemeData theme) {
    final fire = widget.snapshot.fireMetrics;
    final effectiveTarget = _getEffectiveFireTarget();
    final targetStr = _anonymizeValues
        ? '${(fire.annualExpenses > 0 ? effectiveTarget / fire.annualExpenses : fire.fireMultiplier).toStringAsFixed(1)}x Annual Expenses'
        : _formatAmount(effectiveTarget);
    final expStr = _anonymizeValues
        ? (widget.snapshot.totalNetWorth > 0
            ? '${((fire.annualExpenses / widget.snapshot.totalNetWorth) * 100).toStringAsFixed(1)}% of Net Worth/yr'
            : '4.0% of Net Worth/yr')
        : '${_formatAmount(fire.monthlyExpenses)}/mo (${_formatAmount(fire.annualExpenses)}/yr)';

    final selectedFireCount = _includeFireMetrics ? _includedFireMetrics.length : 0;
    final bool? fireCheckState = (selectedFireCount == 0 || !_includeFireMetrics)
        ? false
        : (selectedFireCount == _allFireKeys.length ? true : null);

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceLightColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            leading: Checkbox(
              tristate: true,
              value: fireCheckState,
              activeColor: theme.secondaryAccentColor,
              checkColor: Colors.black,
              onChanged: (v) {
                setState(() {
                  if (fireCheckState == true) {
                    _includeFireMetrics = false;
                    _includedFireMetrics.clear();
                  } else {
                    _includeFireMetrics = true;
                    _includedFireMetrics.addAll(_allFireKeys);
                  }
                });
              },
            ),
            title: Row(
              children: [
                const Text('🔥 ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    'FIRE & Retirement Portfolio',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: theme.textPrimaryColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.secondaryAccentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Target: $targetStr',
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.secondaryAccentColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                _isFireExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: theme.textSecondaryColor,
              ),
              onPressed: () => setState(() => _isFireExpanded = !_isFireExpanded),
            ),
          ),
          if (_isFireExpanded) ...[
            Padding(
              padding: const EdgeInsets.only(left: 44, right: 14, bottom: 10),
              child: Column(
                children: [
                  _buildTargetFireCorpusRow(theme, effectiveTarget, targetStr),
                  _buildMetricRow(
                    label: 'Living Expenses',
                    value: expStr,
                    keyName: 'expenses',
                    selectedSet: _includedFireMetrics,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedFireMetrics.add('expenses');
                          _includeFireMetrics = true;
                        } else {
                          _includedFireMetrics.remove('expenses');
                          if (_includedFireMetrics.isEmpty) _includeFireMetrics = false;
                        }
                      });
                    },
                  ),
                  _buildMetricRow(
                    label: 'Safe Withdrawal Rate (SWR) & Multiplier',
                    value: '${fire.swrPercent.toStringAsFixed(1)}% SWR (${fire.fireMultiplier.toStringAsFixed(1)}x)',
                    keyName: 'swr',
                    selectedSet: _includedFireMetrics,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedFireMetrics.add('swr');
                          _includeFireMetrics = true;
                        } else {
                          _includedFireMetrics.remove('swr');
                          if (_includedFireMetrics.isEmpty) _includeFireMetrics = false;
                        }
                      });
                    },
                  ),
                  _buildMetricRow(
                    label: 'Timeline & Independence Velocity',
                    value: '${fire.yearsToFire.toStringAsFixed(1)} Yrs • ${fire.savingsRate.toStringAsFixed(1)}% Savings',
                    keyName: 'timeline',
                    selectedSet: _includedFireMetrics,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedFireMetrics.add('timeline');
                          _includeFireMetrics = true;
                        } else {
                          _includedFireMetrics.remove('timeline');
                          if (_includedFireMetrics.isEmpty) _includeFireMetrics = false;
                        }
                      });
                    },
                  ),
                  _buildMetricRow(
                    label: 'Pre-FIRE Major Outflow Milestones',
                    value: '${fire.preFireMilestonesCount} Scheduled Milestones',
                    keyName: 'milestones',
                    selectedSet: _includedFireMetrics,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedFireMetrics.add('milestones');
                          _includeFireMetrics = true;
                        } else {
                          _includedFireMetrics.remove('milestones');
                          if (_includedFireMetrics.isEmpty) _includeFireMetrics = false;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetFireCorpusRow(AIThemeData theme, double effectiveTarget, String targetStr) {
    final isChecked = _includedFireMetrics.contains('targetCorpus');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isChecked,
                  activeColor: theme.secondaryAccentColor,
                  checkColor: Colors.black,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _includedFireMetrics.add('targetCorpus');
                        _includeFireMetrics = true;
                      } else {
                        _includedFireMetrics.remove('targetCorpus');
                        if (_includedFireMetrics.isEmpty) _includeFireMetrics = false;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Target FIRE Corpus:',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isChecked ? theme.textPrimaryColor : theme.textMutedColor,
                ),
              ),
              const SizedBox(width: 8),
              // Target Flavor Selector Dropdown
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.surfaceColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.borderColor.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFireTargetType,
                    dropdownColor: theme.surfaceLightColor,
                    icon: Icon(Icons.arrow_drop_down_rounded, size: 18, color: theme.secondaryAccentColor),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.secondaryAccentColor),
                    items: const [
                      DropdownMenuItem(value: 'Standard', child: Text('Standard FIRE')),
                      DropdownMenuItem(value: 'Lean', child: Text('Lean FIRE')),
                      DropdownMenuItem(value: 'Fat', child: Text('Fat FIRE')),
                      DropdownMenuItem(value: 'Coast', child: Text('Coast FIRE')),
                      DropdownMenuItem(value: 'Barista', child: Text('Barista FIRE')),
                      DropdownMenuItem(value: 'Custom', child: Text('Custom Target')),
                    ],
                    onChanged: (newType) {
                      if (newType != null) {
                        setState(() {
                          _selectedFireTargetType = newType;
                          if (newType == 'Custom' && _customTargetValue == null) {
                            _customTargetValue = widget.snapshot.fireMetrics.fireNumber;
                            _customFireTargetController.text = _customTargetValue!.toStringAsFixed(0);
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              const Spacer(),
              if (_selectedFireTargetType != 'Custom')
                Text(
                  targetStr,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isChecked ? theme.secondaryAccentColor : theme.textMutedColor,
                  ),
                ),
            ],
          ),
          // If Custom is selected, show editable text field row
          if (_selectedFireTargetType == 'Custom')
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 6, bottom: 2),
              child: Row(
                children: [
                  Text(
                    'Desired Target: ${widget.snapshot.currencySymbol}',
                    style: GoogleFonts.inter(fontSize: 11, color: theme.textSecondaryColor),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 140,
                    height: 30,
                    child: TextField(
                      controller: _customFireTargetController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: theme.textPrimaryColor),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        filled: true,
                        fillColor: theme.surfaceColor.withOpacity(0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: theme.secondaryAccentColor),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
                        if (parsed != null && parsed > 0) {
                          setState(() {
                            _customTargetValue = parsed;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_formatAmount(_getEffectiveFireTarget())})',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.secondaryAccentColor),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Accordion 2: Cash Flows ---
  Widget _buildCashFlowAccordion(AIThemeData theme) {
    final totalMonthlySips = widget.snapshot.assets
        .where((a) => a.isSip)
        .fold(0.0, (s, a) => s + a.monthlySipAmount);

    final selectedCfCount = _includeCashFlows ? _includedCashFlowItems.length : 0;
    final bool? cfCheckState = (selectedCfCount == 0 || !_includeCashFlows)
        ? false
        : (selectedCfCount == _allCfKeys.length ? true : null);

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceLightColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            leading: Checkbox(
              tristate: true,
              value: cfCheckState,
              activeColor: theme.secondaryAccentColor,
              checkColor: Colors.black,
              onChanged: (v) {
                setState(() {
                  if (cfCheckState == true) {
                    _includeCashFlows = false;
                    _includedCashFlowItems.clear();
                  } else {
                    _includeCashFlows = true;
                    _includedCashFlowItems.addAll(_allCfKeys);
                  }
                });
              },
            ),
            title: Row(
              children: [
                const Text('💵 ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    'Cash Flows & Recurring SIPs',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: theme.textPrimaryColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.secondaryAccentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Active SIPs: ${_formatSip(totalMonthlySips)}',
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.secondaryAccentColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                _isCashFlowExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: theme.textSecondaryColor,
              ),
              onPressed: () => setState(() => _isCashFlowExpanded = !_isCashFlowExpanded),
            ),
          ),
          if (_isCashFlowExpanded) ...[
            Padding(
              padding: const EdgeInsets.only(left: 44, right: 14, bottom: 10),
              child: Column(
                children: [
                  _buildMetricRow(
                    label: 'Active Monthly SIP Commitments',
                    value: _formatSip(totalMonthlySips),
                    keyName: 'sips',
                    selectedSet: _includedCashFlowItems,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedCashFlowItems.add('sips');
                          _includeCashFlows = true;
                        } else {
                          _includedCashFlowItems.remove('sips');
                          if (_includedCashFlowItems.isEmpty) _includeCashFlows = false;
                        }
                      });
                    },
                  ),
                  _buildMetricRow(
                    label: 'Monthly Living Outflows',
                    value: _anonymizeValues ? '[Ratio of Net Worth]' : _formatAmount(widget.snapshot.fireMetrics.monthlyExpenses),
                    keyName: 'expenses',
                    selectedSet: _includedCashFlowItems,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedCashFlowItems.add('expenses');
                          _includeCashFlows = true;
                        } else {
                          _includedCashFlowItems.remove('expenses');
                          if (_includedCashFlowItems.isEmpty) _includeCashFlows = false;
                        }
                      });
                    },
                  ),
                  _buildMetricRow(
                    label: 'Income / Inflow Nodes',
                    value: '[Tracked Inflow Streams]',
                    keyName: 'inflow',
                    selectedSet: _includedCashFlowItems,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedCashFlowItems.add('inflow');
                          _includeCashFlows = true;
                        } else {
                          _includedCashFlowItems.remove('inflow');
                          if (_includedCashFlowItems.isEmpty) _includeCashFlows = false;
                        }
                      });
                    },
                  ),
                  _buildMetricRow(
                    label: 'Free Cash Flow Buffer',
                    value: '[Discretionary Cash Surplus]',
                    keyName: 'fcf',
                    selectedSet: _includedCashFlowItems,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedCashFlowItems.add('fcf');
                          _includeCashFlows = true;
                        } else {
                          _includedCashFlowItems.remove('fcf');
                          if (_includedCashFlowItems.isEmpty) _includeCashFlows = false;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Accordion 3: Portfolio Summary & Assumptions ---
  Widget _buildSummaryAccordion(AIThemeData theme) {
    final selectedSummCount = _includeTotalNetWorth ? _includedSummaryItems.length : 0;
    final bool? summCheckState = (selectedSummCount == 0 || !_includeTotalNetWorth)
        ? false
        : (selectedSummCount == _allSummKeys.length ? true : null);

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceLightColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            leading: Checkbox(
              tristate: true,
              value: summCheckState,
              activeColor: theme.secondaryAccentColor,
              checkColor: Colors.black,
              onChanged: (v) {
                setState(() {
                  if (summCheckState == true) {
                    _includeTotalNetWorth = false;
                    _includedSummaryItems.clear();
                  } else {
                    _includeTotalNetWorth = true;
                    _includedSummaryItems.addAll(_allSummKeys);
                  }
                });
              },
            ),
            title: Row(
              children: [
                const Text('📊 ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    'Portfolio Summary & Assumptions',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: theme.textPrimaryColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.secondaryAccentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Net Worth: ${_formatAssetVal(widget.snapshot.totalNetWorth)}',
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.secondaryAccentColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                _isSummaryExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: theme.textSecondaryColor,
              ),
              onPressed: () => setState(() => _isSummaryExpanded = !_isSummaryExpanded),
            ),
          ),
          if (_isSummaryExpanded) ...[
            Padding(
              padding: const EdgeInsets.only(left: 44, right: 14, bottom: 10),
              child: Column(
                children: [
                  _buildMetricRow(
                    label: 'Total Net Worth & Invested Capital Basis',
                    value: _formatAssetVal(widget.snapshot.totalNetWorth),
                    keyName: 'netWorth',
                    selectedSet: _includedSummaryItems,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedSummaryItems.add('netWorth');
                          _includeTotalNetWorth = true;
                        } else {
                          _includedSummaryItems.remove('netWorth');
                          if (_includedSummaryItems.isEmpty) _includeTotalNetWorth = false;
                        }
                      });
                    },
                  ),
                  _buildMetricRow(
                    label: 'Asset Allocation Breakdown Percentages',
                    value: '${widget.snapshot.categoryBreakdown.length} Categories',
                    keyName: 'allocation',
                    selectedSet: _includedSummaryItems,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedSummaryItems.add('allocation');
                          _includeTotalNetWorth = true;
                        } else {
                          _includedSummaryItems.remove('allocation');
                          if (_includedSummaryItems.isEmpty) _includeTotalNetWorth = false;
                        }
                      });
                    },
                  ),
                  _buildMetricRow(
                    label: 'Long-Term CAGR & Inflation Assumptions',
                    value: '${widget.snapshot.fireMetrics.expectedReturn.toStringAsFixed(1)}% Return • ${widget.snapshot.fireMetrics.expectedInflation.toStringAsFixed(1)}% Inflation',
                    keyName: 'assumptions',
                    selectedSet: _includedSummaryItems,
                    theme: theme,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _includedSummaryItems.add('assumptions');
                          _includeTotalNetWorth = true;
                        } else {
                          _includedSummaryItems.remove('assumptions');
                          if (_includedSummaryItems.isEmpty) _includeTotalNetWorth = false;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required String keyName,
    required Set<String> selectedSet,
    required AIThemeData theme,
    required ValueChanged<bool?> onChanged,
  }) {
    final isChecked = selectedSet.contains(keyName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isChecked,
              activeColor: theme.secondaryAccentColor,
              checkColor: Colors.black,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isChecked ? theme.textPrimaryColor : theme.textMutedColor,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isChecked ? theme.secondaryAccentColor : theme.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- Section 4: 3-Tier Asset Hierarchy Tree ---
  Widget _buildAssetHierarchyTree(AIThemeData theme) {
    return Column(
      children: AIAssetCategory.values.map((cat) {
        final catAssets = widget.snapshot.assets.where((a) => a.category == cat).toList();
        final catCount = catAssets.length;
        final catValue = catAssets.fold(0.0, (s, a) => s + a.currentValue);
        final catSip = catAssets.where((a) => a.isSip).fold(0.0, (s, a) => s + a.monthlySipAmount);
        final isExpanded = _expandedCategories.contains(cat.name);

        // Group into subcategories
        final subCatMap = <String, List<AIAssetEntry>>{};
        for (final a in catAssets) {
          final sub = (a.subCategory != null && a.subCategory!.isNotEmpty)
              ? a.subCategory!
              : ((a.notes != null && a.notes!.isNotEmpty) ? a.notes! : 'General');
          subCatMap.putIfAbsent(sub, () => []).add(a);
        }

        // Determine category tri-state
        final selectedCatCount = catAssets.where(_isHoldingSelected).length;
        final bool? categoryCheckState = (catCount == 0 || selectedCatCount == 0)
            ? false
            : (selectedCatCount == catCount ? true : null);

        final isCatActive = categoryCheckState == true || categoryCheckState == null;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: theme.surfaceLightColor.withOpacity(isCatActive ? 0.35 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCatActive ? theme.borderColor.withOpacity(0.4) : theme.borderColor.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level 1: Category Header
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedCategories.remove(cat.name);
                    } else {
                      _expandedCategories.add(cat.name);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Checkbox(
                        tristate: true,
                        value: categoryCheckState,
                        activeColor: theme.secondaryAccentColor,
                        checkColor: Colors.black,
                        onChanged: (val) {
                          setState(() {
                            if (categoryCheckState == true) {
                              // Unselect all in category
                              _includedCategories.remove(cat);
                              for (final a in catAssets) {
                                _excludedAssetIds.add(a.id);
                              }
                            } else {
                              // Select all in category
                              _includedCategories.add(cat);
                              for (final a in catAssets) {
                                _excludedAssetIds.remove(a.id);
                              }
                              for (final sub in subCatMap.keys) {
                                _excludedSubcategories.remove(sub);
                              }
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                cat.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isCatActive ? FontWeight.w700 : FontWeight.w500,
                                  color: isCatActive ? theme.textPrimaryColor : theme.textMutedColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.surfaceColor.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$selectedCatCount/$catCount',
                                style: GoogleFonts.inter(fontSize: 10, color: theme.textMutedColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Val: ${_formatAssetVal(catValue)}${catSip > 0 ? ' • SIP: ${_formatSip(catSip)}' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCatActive ? theme.secondaryAccentColor : theme.textMutedColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: theme.textSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),

              // Level 2 & Level 3: Subcategories & Holdings (Always visible when expanded)
              if (isExpanded && catCount > 0) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 28, right: 10, bottom: 8),
                  child: Column(
                    children: subCatMap.entries.map((subEntry) {
                      final subName = subEntry.key;
                      final subHoldings = subEntry.value;
                      final subCount = subHoldings.length;
                      final subTotal = subHoldings.fold(0.0, (s, a) => s + a.currentValue);
                      final subSip = subHoldings.where((a) => a.isSip).fold(0.0, (s, a) => s + a.monthlySipAmount);

                      // Subcategory Tri-State
                      final selectedSubCount = subHoldings.where(_isHoldingSelected).length;
                      final bool? subCheckState = (subCount == 0 || selectedSubCount == 0)
                          ? false
                          : (selectedSubCount == subCount ? true : null);

                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.surfaceColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.borderColor.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Level 2: Subcategory Bar
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    tristate: true,
                                    value: subCheckState,
                                    activeColor: theme.secondaryAccentColor,
                                    checkColor: Colors.black,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (subCheckState == true) {
                                          // Deselect all in subcategory
                                          _excludedSubcategories.add(subName);
                                          for (final a in subHoldings) {
                                            _excludedAssetIds.add(a.id);
                                          }
                                          // If all holdings in category now deselected, update _includedCategories
                                          final totalSelectedInCat = catAssets.where((x) => _isHoldingSelected(x) && !subHoldings.contains(x)).length;
                                          if (totalSelectedInCat == 0) {
                                            _includedCategories.remove(cat);
                                          }
                                        } else {
                                          // Select all in subcategory
                                          _excludedSubcategories.remove(subName);
                                          _includedCategories.add(cat);
                                          for (final a in subHoldings) {
                                            _excludedAssetIds.remove(a.id);
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.secondaryAccentColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    subName,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: theme.secondaryAccentColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$selectedSubCount/$subCount items • Val: ${_formatAssetVal(subTotal)}${subSip > 0 ? ' • SIP: ${_formatSip(subSip)}' : ''}',
                                    style: GoogleFonts.inter(fontSize: 10.5, color: theme.textSecondaryColor),
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // Level 3: 1-Line Holdings Rows (Persistent Subtree)
                            const SizedBox(height: 4),
                            ...subHoldings.asMap().entries.map((holdingEntry) {
                              final idx = holdingEntry.key + 1;
                              final a = holdingEntry.value;
                              final isSelected = _isHoldingSelected(a);
                              final isMasked = _privacyMode == ContextPrivacyMode.summaryOnly;
                              final displayName = isMasked ? '${cat.displayName} #$idx' : a.name;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.surfaceLightColor.withOpacity(0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: Checkbox(
                                        value: isSelected,
                                        activeColor: theme.secondaryAccentColor,
                                        checkColor: Colors.black,
                                        onChanged: (checked) {
                                          setState(() {
                                            if (isSelected) {
                                              _excludedAssetIds.add(a.id);
                                              // If all in category are deselected, remove from _includedCategories
                                              final totalSelectedInCat = catAssets.where((x) => x.id != a.id && _isHoldingSelected(x)).length;
                                              if (totalSelectedInCat == 0) {
                                                _includedCategories.remove(cat);
                                              }
                                            } else {
                                              _excludedAssetIds.remove(a.id);
                                              _excludedSubcategories.remove(subName);
                                              _includedCategories.add(cat);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Asset Name
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          color: isSelected ? theme.textPrimaryColor : theme.textMutedColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Right-Aligned Val and SIP
                                    Flexible(
                                      child: Text(
                                        'Val: ${_formatAssetVal(a.currentValue)}${a.isSip ? ' • SIP: ${_formatSip(a.monthlySipAmount)}' : ' • One-Time'}',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? (a.isSip ? theme.secondaryAccentColor : theme.textPrimaryColor)
                                              : theme.textMutedColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(AIThemeData theme) {
    return Row(
      children: [
        Checkbox(
          value: _rememberForFuture,
          activeColor: theme.secondaryAccentColor,
          checkColor: Colors.black,
          onChanged: (v) => setState(() => _rememberForFuture = v ?? false),
        ),
        Expanded(
          child: Text(
            'Remember choices for future sessions',
            style: GoogleFonts.inter(fontSize: 11, color: theme.textSecondaryColor),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.inter(fontSize: 12, color: theme.textSecondaryColor)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _handleSave,
          icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
          label: Text(
            'Apply & Start Chat',
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryAccentColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
        ),
      ],
    );
  }
}
