import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';

class KpiRibbon extends ConsumerWidget {
  const KpiRibbon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioState = ref.watch(portfolioProvider);
    final currency = ref.watch(currencyProvider);
    final summary = portfolioState.summary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        if (isDesktop) {
          return Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'TOTAL NET WORTH',
                  value: CurrencyFormatter.formatFull(summary.totalNetWorth, currency: currency),
                  compactValue: CurrencyFormatter.formatCompact(summary.totalNetWorth, currency: currency),
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.gold,
                  badgeText: '${summary.totalAssetCount} Assets',
                  badgeColor: AppColors.gold,
                  isHighlighted: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildGainsCard(summary, currency),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildKpiCard(
                  title: 'MONTHLY SIP INFLOW',
                  value: CurrencyFormatter.formatFull(summary.totalMonthlySipInflow, currency: currency),
                  compactValue: '${CurrencyFormatter.formatCompact(summary.totalMonthlySipInflow, currency: currency)} / mo',
                  icon: Icons.repeat_rounded,
                  iconColor: AppColors.info,
                  badgeText: 'Recurring',
                  badgeColor: AppColors.info,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildKpiCard(
                  title: 'BLENDED RETURN (CAGR)',
                  value: CurrencyFormatter.formatPercent(summary.blendedExpectedCagr, includeSign: false),
                  compactValue: CurrencyFormatter.formatPercent(summary.blendedExpectedCagr, includeSign: false),
                  icon: Icons.auto_graph_rounded,
                  iconColor: AppColors.crimson,
                  badgeText: 'Weighted XIRR',
                  badgeColor: AppColors.crimson,
                ),
              ),
            ],
          );
        } else if (isTablet) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'TOTAL NET WORTH',
                      value: CurrencyFormatter.formatFull(summary.totalNetWorth, currency: currency),
                      compactValue: CurrencyFormatter.formatCompact(summary.totalNetWorth, currency: currency),
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.gold,
                      badgeText: '${summary.totalAssetCount} Assets',
                      badgeColor: AppColors.gold,
                      isHighlighted: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGainsCard(summary, currency),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'MONTHLY SIP INFLOW',
                      value: CurrencyFormatter.formatFull(summary.totalMonthlySipInflow, currency: currency),
                      compactValue: '${CurrencyFormatter.formatCompact(summary.totalMonthlySipInflow, currency: currency)} / mo',
                      icon: Icons.repeat_rounded,
                      iconColor: AppColors.info,
                      badgeText: 'Recurring',
                      badgeColor: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'BLENDED RETURN (CAGR)',
                      value: CurrencyFormatter.formatPercent(summary.blendedExpectedCagr, includeSign: false),
                      compactValue: CurrencyFormatter.formatPercent(summary.blendedExpectedCagr, includeSign: false),
                      icon: Icons.auto_graph_rounded,
                      iconColor: AppColors.crimson,
                      badgeText: 'Weighted XIRR',
                      badgeColor: AppColors.crimson,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Mobile vertical stack
          return Column(
            children: [
              _buildKpiCard(
                title: 'TOTAL NET WORTH',
                value: CurrencyFormatter.formatFull(summary.totalNetWorth, currency: currency),
                compactValue: CurrencyFormatter.formatCompact(summary.totalNetWorth, currency: currency),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.gold,
                badgeText: '${summary.totalAssetCount} Active Assets',
                badgeColor: AppColors.gold,
                isHighlighted: true,
              ),
              const SizedBox(height: 10),
              _buildGainsCard(summary, currency),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'MONTHLY SIP',
                      value: CurrencyFormatter.formatFull(summary.totalMonthlySipInflow, currency: currency),
                      compactValue: CurrencyFormatter.formatCompact(summary.totalMonthlySipInflow, currency: currency),
                      icon: Icons.repeat_rounded,
                      iconColor: AppColors.info,
                      badgeText: 'Per Mo',
                      badgeColor: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'EXP. CAGR',
                      value: CurrencyFormatter.formatPercent(summary.blendedExpectedCagr, includeSign: false),
                      compactValue: CurrencyFormatter.formatPercent(summary.blendedExpectedCagr, includeSign: false),
                      icon: Icons.auto_graph_rounded,
                      iconColor: AppColors.crimson,
                      badgeText: 'XIRR',
                      badgeColor: AppColors.crimson,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String compactValue,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    bool isHighlighted = false,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderColor: isHighlighted ? AppColors.gold.withOpacity(0.4) : AppColors.border,
      glowShadow: isHighlighted
          ? BoxShadow(
              color: AppColors.gold.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.8),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  compactValue,
                  style: AppTypography.currencyMedium.copyWith(
                    fontSize: 22,
                    color: isHighlighted ? AppColors.goldLight : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGainsCard(PortfolioSummary summary, CurrencyType currency) {
    final isGain = summary.totalUnrealizedGains >= 0;
    final gainColor = isGain ? AppColors.profit : AppColors.loss;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderColor: gainColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'CAPITAL & RETURNS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: gainColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: gainColor.withOpacity(0.3), width: 0.8),
                ),
                child: Text(
                  CurrencyFormatter.formatPercent(summary.totalGainsPercent),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: gainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                CurrencyFormatter.formatCompact(summary.totalUnrealizedGains, currency: currency),
                style: AppTypography.currencyMedium.copyWith(
                  fontSize: 22,
                  color: gainColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isGain ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 20,
                color: gainColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Invested: ${CurrencyFormatter.formatCompact(summary.totalInvestedCapital, currency: currency)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
