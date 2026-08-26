import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/crimson_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import 'add_investment_dialog.dart';
import 'portfolio_backup_modal.dart';

class AppHeader extends ConsumerWidget {
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  const AppHeader({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final portfolio = ref.watch(portfolioProvider);

    return GlassContainer(
      borderRadius: 0,
      borderWidth: 0,
      backgroundColor: AppColors.surface.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showFullNav = constraints.maxWidth >= 920;
          final showCompactNav = constraints.maxWidth >= 720 && constraints.maxWidth < 920;

          return Row(
            children: [
              // Logo & Branding
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.crimson, AppColors.gold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.crimson.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_graph_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'WEALTH ',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'ANALYZER',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'PORTFOLIO MODELING',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Desktop Navigation Tabs
              if (showFullNav || showCompactNav) ...[
                const SizedBox(width: 20),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNavTab(context, 0, 'Overview', Icons.dashboard_rounded),
                        _buildNavTab(context, 1, 'Simulator', Icons.insights_rounded),
                        _buildNavTab(context, 2, 'FIRE Calculator', Icons.local_fire_department_rounded),
                        _buildNavTab(context, 3, 'Holdings (${portfolio.assets.length})', Icons.account_balance_wallet_rounded),
                        _buildNavTab(context, 4, 'Sankey Flow', Icons.alt_route_rounded),
                      ],
                    ),
                  ),
                ),
              ] else
                const Spacer(),

              const SizedBox(width: 10),

              // Currency Switcher Toggle
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCurrencyChip(
                      ref,
                      CurrencyType.inr,
                      '₹ INR',
                      isSelected: currency == CurrencyType.inr,
                    ),
                    _buildCurrencyChip(
                      ref,
                      CurrencyType.usd,
                      '\$ USD',
                      isSelected: currency == CurrencyType.usd,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Backup / Preset Loader Icon Button
              Tooltip(
                message: 'Presets & Backup',
                child: IconButton(
                  icon: const Icon(Icons.settings_backup_restore_rounded, color: AppColors.textSecondary, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const PortfolioBackupModal(),
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Primary Crimson Red CTA
              CrimsonButton(
                text: constraints.maxWidth >= 680 ? '+ Add Investment' : '+ Add',
                icon: Icons.add_rounded,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AddInvestmentDialog(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavTab(BuildContext context, int index, String label, IconData icon) {
    final isSelected = selectedTabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.gold.withOpacity(0.4), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyChip(
    WidgetRef ref,
    CurrencyType type,
    String label, {
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => ref.read(currencyProvider.notifier).setCurrency(type),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
