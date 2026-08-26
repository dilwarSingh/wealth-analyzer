import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/crimson_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/investment_asset.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';

class AddInvestmentDialog extends ConsumerStatefulWidget {
  final InvestmentAsset? assetToEdit;

  const AddInvestmentDialog({super.key, this.assetToEdit});

  @override
  ConsumerState<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends ConsumerState<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _investedController;
  late TextEditingController _currentValController;
  late TextEditingController _cagrController;
  late TextEditingController _stepUpController;

  late AssetCategory _selectedCategory;
  late InvestmentType _selectedType;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final a = widget.assetToEdit;

    _nameController = TextEditingController(text: a?.name ?? '');
    _investedController = TextEditingController(text: a != null ? a.investedAmount.toStringAsFixed(0) : '');
    _currentValController = TextEditingController(text: a != null ? a.currentValue.toStringAsFixed(0) : '');
    _cagrController = TextEditingController(text: a != null ? a.expectedCAGR.toStringAsFixed(1) : '12.0');
    _stepUpController = TextEditingController(text: a != null ? a.stepUpRate.toStringAsFixed(0) : '10.0');

    _selectedCategory = a?.category ?? AssetCategory.mutualFunds;
    _selectedType = a?.type ?? InvestmentType.monthlySip;
    _startDate = a?.startDate ?? DateTime.now();

    _investedController.addListener(() => setState(() {}));
    _currentValController.addListener(() => setState(() {}));
    _cagrController.addListener(() => setState(() {}));
    _stepUpController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _investedController.dispose();
    _currentValController.dispose();
    _cagrController.dispose();
    _stepUpController.dispose();
    super.dispose();
  }

  double _calculateTenYearPreview() {
    final investedStr = _investedController.text.replaceAll(',', '').replaceAll(' ', '').trim();
    final currentStr = _currentValController.text.replaceAll(',', '').replaceAll(' ', '').trim();
    final cagrStr = _cagrController.text.replaceAll(',', '').replaceAll(' ', '').trim();
    final stepUpStr = _stepUpController.text.replaceAll(',', '').replaceAll(' ', '').trim();

    final invested = double.tryParse(investedStr) ?? 0.0;
    final isSip = _selectedType == InvestmentType.monthlySip;
    double current = double.tryParse(currentStr) ?? (isSip ? 0.0 : invested);
    if (!isSip && current <= 0) {
      current = invested;
    }
    final cagr = double.tryParse(cagrStr) ?? 12.0;
    final stepUp = double.tryParse(stepUpStr) ?? 0.0;

    final tempAsset = InvestmentAsset(
      id: 'preview',
      name: 'Preview',
      category: _selectedCategory,
      type: _selectedType,
      investedAmount: invested,
      currentValue: current,
      startDate: _startDate,
      expectedCAGR: cagr,
      stepUpRate: stepUp,
    );

    return tempAsset.tenYearProjectedValue;
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final isEditing = widget.assetToEdit != null;
    final preview10Y = _calculateTenYearPreview();
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: screenHeight * 0.88,
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          borderColor: AppColors.gold.withOpacity(0.5),
          borderRadius: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header (Fixed at top)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.crimson.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.crimson.withOpacity(0.4)),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_note_rounded : Icons.add_chart_rounded,
                          color: AppColors.crimson,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? 'Edit Investment' : 'Add New Investment',
                        style: AppTypography.heading2.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scrollable Form Body
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Investment Type Toggle (Lump Sum vs SIP)
                        _buildFieldLabel(
                          'INVESTMENT FREQUENCY',
                          'Choose "Monthly SIP" for recurring monthly deposits or "One-Time Lump Sum" for a single upfront purchase.',
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTypeSegment(
                                  type: InvestmentType.monthlySip,
                                  label: 'Monthly SIP',
                                  icon: Icons.repeat_rounded,
                                ),
                              ),
                              Expanded(
                                child: _buildTypeSegment(
                                  type: InvestmentType.oneTime,
                                  label: 'One-Time Lump Sum',
                                  icon: Icons.monetization_on_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Category Selector Grid
                        _buildFieldLabel(
                          'ASSET CATEGORY',
                          'Categorize this asset to map your risk distribution in the Allocation Donut and cash-flow breakdown in the Sankey diagram.',
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: AssetCategory.values.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return InkWell(
                              onTap: () => setState(() => _selectedCategory = cat),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? cat.color.withOpacity(0.2) : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? cat.color : AppColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cat.icon, size: 13, color: isSelected ? cat.color : AppColors.textMuted),
                                    const SizedBox(width: 5),
                                    Text(
                                      cat.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Asset Name
                        _buildFieldLabel(
                          'ASSET NAME',
                          'The name or identifier for this holding (e.g. "Nifty 50 Index Fund", "Physical Gold Bar", "Tech ETF").',
                        ),
                        TextFormField(
                          controller: _nameController,
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                          decoration: _inputDecoration(
                            hintText: 'e.g. Nifty 50 Index Fund, Physical Gold, Tech ETF',
                            prefixIcon: Icons.drive_file_rename_outline_rounded,
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter asset name' : null,
                        ),

                        const SizedBox(height: 12),

                        // Invested Amount & Current Valuation
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(
                                    _selectedType == InvestmentType.monthlySip ? 'MONTHLY SIP AMOUNT' : 'INVESTED CAPITAL',
                                    _selectedType == InvestmentType.monthlySip
                                        ? 'The recurring installment amount you invest each month into this SIP.'
                                        : 'The initial principal amount or original capital you spent to acquire this asset.',
                                  ),
                                  TextFormField(
                                    controller: _investedController,
                                    keyboardType: TextInputType.number,
                                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                    decoration: _inputDecoration(
                                      hintText: '0',
                                      prefixText: '${currency.symbol} ',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Required';
                                      final cleaned = val.replaceAll(',', '').replaceAll(' ', '').trim();
                                      if (double.tryParse(cleaned) == null) return 'Invalid number';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(
                                    'CURRENT VALUATION',
                                    _selectedType == InvestmentType.monthlySip
                                        ? 'Current total market value of units already accumulated so far. Leave blank or 0 if starting fresh today.'
                                        : 'Current live market value of this asset today. Used to compute your unrealized profit or loss.',
                                  ),
                                  TextFormField(
                                    controller: _currentValController,
                                    keyboardType: TextInputType.number,
                                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                    decoration: _inputDecoration(
                                      hintText: _selectedType == InvestmentType.monthlySip ? 'Optional / Current' : '0',
                                      prefixText: '${currency.symbol} ',
                                    ),
                                    validator: (val) {
                                      if (val != null && val.trim().isNotEmpty) {
                                        final cleaned = val.replaceAll(',', '').replaceAll(' ', '').trim();
                                        if (double.tryParse(cleaned) == null) return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Expected Return % & Step Up %
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(
                                    'EXPECTED ANNUAL CAGR (%)',
                                    'Expected Compounded Annual Growth Rate per year. Typically 12-14% for diversified equity funds, 6-7% for FD/debt, 10-12% for gold.',
                                  ),
                                  TextFormField(
                                    controller: _cagrController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                    decoration: _inputDecoration(
                                      hintText: '12.0',
                                      suffixText: '%',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Required';
                                      final cleaned = val.replaceAll(',', '').replaceAll(' ', '').trim();
                                      if (double.tryParse(cleaned) == null) return 'Invalid';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedType == InvestmentType.monthlySip) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(
                                      'ANNUAL STEP-UP (%)',
                                      'Annual percentage to increase your monthly contribution every 12 months as your salary or savings capacity increases.',
                                    ),
                                    TextFormField(
                                      controller: _stepUpController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                      decoration: _inputDecoration(
                                        hintText: '10.0',
                                        suffixText: '%',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Quick Preset Chips for Expected CAGR
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildPresetChip('Conservative (7%)', 7.0),
                            _buildPresetChip('Moderate (12%)', 12.0),
                            _buildPresetChip('Aggressive (15%)', 15.0),
                            _buildPresetChip('High Growth (18%)', 18.0),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Real-time 10-Year Live Mini-Preview Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.insights_rounded, color: AppColors.gold, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(
                                      '10-YEAR ESTIMATED FUTURE VALUE',
                                      'Simulated future valuation after 10 years of compounding returns and monthly deposits based on your inputs.',
                                    ),
                                    Text(
                                      CurrencyFormatter.formatCompact(preview10Y, currency: currency),
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.goldLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${_cagrController.text}% CAGR',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.profit),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),

              // Modal Actions (Cancel & Save - Fixed at bottom)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: AppTypography.buttonText.copyWith(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  CrimsonButton(
                    text: isEditing ? 'Save Changes' : 'Add Investment',
                    icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
                    isLoading: _isSaving,
                    height: 42,
                    onPressed: _saveAsset,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required InvestmentType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (type == InvestmentType.oneTime) {
            final curr = double.tryParse(_currentValController.text.replaceAll(',', '').trim()) ?? 0.0;
            if (curr <= 0 && _investedController.text.trim().isNotEmpty) {
              _currentValController.text = _investedController.text.trim();
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.crimson : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.crimson.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double value) {
    final isCurrent = (double.tryParse(_cagrController.text) ?? 0.0) == value;
    return InkWell(
      onTap: () => setState(() => _cagrController.text = value.toStringAsFixed(1)),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.gold.withOpacity(0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrent ? AppColors.gold : AppColors.border,
            width: isCurrent ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isCurrent ? AppColors.goldLight : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, String tooltipMessage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 5),
          Tooltip(
            message: tooltipMessage,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.35,
            ),
            preferBelow: false,
            verticalOffset: 12,
            waitDuration: const Duration(milliseconds: 150),
            showDuration: const Duration(seconds: 5),
            child: MouseRegion(
              cursor: SystemMouseCursors.help,
              child: Container(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: AppColors.textMuted.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    IconData? prefixIcon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16, color: AppColors.textSecondary) : null,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700),
      suffixText: suffixText,
      suffixStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    );
  }

  bool _isSaving = false;

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    final investedStr = _investedController.text.replaceAll(',', '').replaceAll(' ', '').trim();
    final currentStr = _currentValController.text.replaceAll(',', '').replaceAll(' ', '').trim();
    final cagrStr = _cagrController.text.replaceAll(',', '').replaceAll(' ', '').trim();
    final stepUpStr = _stepUpController.text.replaceAll(',', '').replaceAll(' ', '').trim();

    final invested = double.tryParse(investedStr) ?? 0.0;
    final isSip = _selectedType == InvestmentType.monthlySip;
    double current = double.tryParse(currentStr) ?? (isSip ? 0.0 : invested);
    if (!isSip && current <= 0) {
      current = invested;
    }
    final cagr = double.tryParse(cagrStr) ?? 12.0;
    final stepUp = double.tryParse(stepUpStr) ?? 0.0;

    final asset = InvestmentAsset(
      id: widget.assetToEdit?.id ?? '',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      type: _selectedType,
      investedAmount: invested,
      currentValue: current,
      startDate: _startDate,
      expectedCAGR: cagr,
      stepUpRate: _selectedType == InvestmentType.monthlySip ? stepUp : 0.0,
    );

    setState(() => _isSaving = true);
    final success = await ref.read(portfolioProvider.notifier).saveAsset(asset);
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.profit,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.assetToEdit != null ? 'Asset updated successfully!' : 'Asset "${asset.name}" added to portfolio!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final error = ref.read(portfolioProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.loss,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Failed to save asset: ${error ?? "Unknown error"}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        );
      }
    }
  }
}
