import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/crimson_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../viewmodels/portfolio_viewmodel.dart';

class PortfolioBackupModal extends ConsumerStatefulWidget {
  const PortfolioBackupModal({super.key});

  @override
  ConsumerState<PortfolioBackupModal> createState() => _PortfolioBackupModalState();
}

class _PortfolioBackupModalState extends ConsumerState<PortfolioBackupModal> {
  final TextEditingController _jsonController = TextEditingController();
  bool _copied = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderColor: AppColors.gold.withOpacity(0.4),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.settings_backup_restore_rounded, color: AppColors.gold, size: 22),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Presets & Backup Management',
                              style: AppTypography.heading2.copyWith(fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Presets Section
                Text('ONE-CLICK SAMPLE PORTFOLIOS', style: AppTypography.label),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CrimsonButton(
                        text: 'Balanced Starter',
                        icon: Icons.auto_awesome_rounded,
                        isSecondary: true,
                        height: 42,
                        onPressed: () {
                          ref.read(portfolioProvider.notifier).loadSamplePreset('balanced');
                          setState(() {
                            _statusMessage = 'Loaded Balanced Starter Portfolio!';
                            _isSuccess = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CrimsonButton(
                        text: 'Aggressive Tech',
                        icon: Icons.trending_up_rounded,
                        isSecondary: true,
                        height: 42,
                        onPressed: () {
                          ref.read(portfolioProvider.notifier).loadSamplePreset('aggressive');
                          setState(() {
                            _statusMessage = 'Loaded Aggressive Growth Portfolio!';
                            _isSuccess = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Export Section
                Text('EXPORT PORTFOLIO (JSON)', style: AppTypography.label),
                const SizedBox(height: 8),
                CrimsonButton(
                  text: _copied ? 'Copied to Clipboard!' : 'Copy Portfolio JSON to Clipboard',
                  icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                  isSecondary: true,
                  height: 42,
                  onPressed: () {
                    final json = ref.read(portfolioProvider.notifier).exportPortfolioAsJson();
                    Clipboard.setData(ClipboardData(text: json));
                    setState(() {
                      _copied = true;
                      _statusMessage = 'Portfolio JSON copied to clipboard!';
                      _isSuccess = true;
                    });
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _copied = false);
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Import Section
                Text('IMPORT PORTFOLIO FROM JSON', style: AppTypography.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _jsonController,
                  maxLines: 3,
                  style: GoogleFonts.firaCode(fontSize: 12, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Paste JSON portfolio array here...',
                    hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CrimsonButton(
                  text: 'Restore Portfolio from JSON',
                  icon: Icons.download_rounded,
                  isSecondary: true,
                  height: 42,
                  onPressed: () async {
                    final text = _jsonController.text.trim();
                    if (text.isEmpty) return;
                    final ok = await ref.read(portfolioProvider.notifier).importPortfolioFromJson(text);
                    setState(() {
                      if (ok) {
                        _statusMessage = 'Portfolio successfully imported!';
                        _isSuccess = true;
                        _jsonController.clear();
                      } else {
                        _statusMessage = 'Invalid JSON structure.';
                        _isSuccess = false;
                      }
                    });
                  },
                ),

                if (_statusMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_isSuccess ? AppColors.profit : AppColors.loss).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_isSuccess ? AppColors.profit : AppColors.loss).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isSuccess ? AppColors.profitLight : AppColors.lossLight,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),

                // Clear Portfolio Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reset All Data (${portfolio.assets.length} items)',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.loss),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.loss),
                      label: Text('Clear All', style: AppTypography.buttonText.copyWith(color: AppColors.loss)),
                      onPressed: () {
                        ref.read(portfolioProvider.notifier).clearAll();
                        Navigator.of(context).pop();
                      },
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
