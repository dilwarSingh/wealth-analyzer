import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/investment_asset.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import 'add_investment_dialog.dart';

class AssetListTable extends ConsumerWidget {
  const AssetListTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final currency = ref.watch(currencyProvider);
    final assets = portfolio.assets;
    final activeCount = assets.where((a) => a.isIncluded).length;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, size: 20, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'HOLDINGS & ASSET ALLOCATION',
                            style: AppTypography.heading3.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeCount == assets.length
                          ? AppColors.profit.withOpacity(0.12)
                          : (activeCount > 0 ? AppColors.gold.withOpacity(0.12) : AppColors.loss.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: activeCount == assets.length
                            ? AppColors.profit.withOpacity(0.4)
                            : (activeCount > 0 ? AppColors.gold.withOpacity(0.4) : AppColors.loss.withOpacity(0.4)),
                      ),
                    ),
                    child: Text(
                      '$activeCount / ${assets.length} Active in Calculations',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: activeCount == assets.length
                            ? AppColors.profitLight
                            : (activeCount > 0 ? AppColors.goldLight : AppColors.lossLight),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          if (assets.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Text(
                'No investment holdings found. Click "+ Add Investment" to add your first asset.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            )
          else ...[
            if (activeCount == 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.loss.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.loss.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.loss),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All holdings are currently unchecked (excluded from calculations). Check any holding to include it.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.lossLight, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(portfolioProvider.notifier).toggleAllAssetsInclusion(true),
                      child: const Text('Check All', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 768;
                if (isWide) {
                  return _buildDesktopTable(context, ref, assets, currency);
                } else {
                  return _buildMobileCardList(context, ref, assets, currency);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    WidgetRef ref,
    List<InvestmentAsset> assets,
    CurrencyType currency,
  ) {
    final allIncluded = assets.every((a) => a.isIncluded);
    final noneIncluded = assets.every((a) => !a.isIncluded);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 850),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight.withOpacity(0.5)),
          horizontalMargin: 8,
          columnSpacing: 16,
          columns: [
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: allIncluded ? true : (noneIncluded ? false : null),
                    tristate: true,
                    activeColor: AppColors.gold,
                    checkColor: AppColors.canvas,
                    onChanged: (val) {
                      ref.read(portfolioProvider.notifier).toggleAllAssetsInclusion(val == true);
                    },
                  ),
                  const Text('INC', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const DataColumn(label: Text('ASSET / CATEGORY', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(label: Text('TYPE', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(label: Text('INVESTED CAPITAL', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(label: Text('CURRENT VALUATION', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(label: Text('EXP. CAGR', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(label: Text('RETURNS (%)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(label: Text('ACTIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
          ],
          rows: assets.map((asset) {
            final isIncluded = asset.isIncluded;
            final isNeutral = asset.isSip && asset.currentValue == 0;
            final isGain = asset.unrealizedGain > 0;
            final returnColor = !isIncluded
                ? AppColors.textDisabled
                : (isNeutral
                    ? AppColors.textMuted
                    : (isGain ? AppColors.profit : (asset.unrealizedGain < 0 ? AppColors.loss : AppColors.textSecondary)));

            final textColor = isIncluded ? AppColors.textPrimary : AppColors.textDisabled;
            final secondaryTextColor = isIncluded ? AppColors.textSecondary : AppColors.textDisabled;
            final valuationColor = isIncluded ? AppColors.goldLight : AppColors.textDisabled;

            return DataRow(
              color: !isIncluded ? WidgetStateProperty.all(Colors.black.withOpacity(0.2)) : null,
              cells: [
                DataCell(
                  Checkbox(
                    value: isIncluded,
                    activeColor: AppColors.gold,
                    checkColor: AppColors.canvas,
                    onChanged: (val) {
                      ref.read(portfolioProvider.notifier).toggleAssetInclusion(asset.id, val ?? true);
                    },
                  ),
                ),
                DataCell(
                  Opacity(
                    opacity: isIncluded ? 1.0 : 0.45,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: asset.category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(asset.category.icon, size: 14, color: asset.category.color),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              asset.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              asset.category.label,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isIncluded ? asset.category.color : AppColors.textDisabled,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Opacity(
                    opacity: isIncluded ? 1.0 : 0.45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: asset.isSip ? AppColors.crimson.withOpacity(0.12) : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: asset.isSip ? AppColors.crimson.withOpacity(0.4) : AppColors.border,
                        ),
                      ),
                      child: Text(
                        asset.isSip ? 'SIP (${asset.stepUpRate.toStringAsFixed(0)}% Step)' : 'Lump Sum',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isIncluded ? (asset.isSip ? AppColors.crimsonLight : AppColors.textSecondary) : AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    asset.isSip
                        ? '${CurrencyFormatter.formatCompact(asset.investedAmount, currency: currency)} / mo'
                        : CurrencyFormatter.formatCompact(asset.investedAmount, currency: currency),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryTextColor),
                  ),
                ),
                DataCell(
                  Text(
                    CurrencyFormatter.formatCompact(asset.currentValue, currency: currency),
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: valuationColor),
                  ),
                ),
                DataCell(
                  Text(
                    '${asset.expectedCAGR.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                  ),
                ),
                DataCell(
                  Text(
                    CurrencyFormatter.formatPercent(asset.returnPercentage),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: returnColor),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.textSecondary),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AddInvestmentDialog(assetToEdit: asset),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.loss),
                        onPressed: () => _confirmDelete(context, ref, asset),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(
    BuildContext context,
    WidgetRef ref,
    List<InvestmentAsset> assets,
    CurrencyType currency,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final isIncluded = asset.isIncluded;
        final isNeutral = asset.isSip && asset.currentValue == 0;
        final isGain = asset.unrealizedGain > 0;
        final returnColor = !isIncluded
            ? AppColors.textDisabled
            : (isNeutral
                ? AppColors.textMuted
                : (isGain ? AppColors.profit : (asset.unrealizedGain < 0 ? AppColors.loss : AppColors.textSecondary)));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isIncluded ? AppColors.surfaceLight.withOpacity(0.4) : AppColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isIncluded ? AppColors.border : AppColors.border.withOpacity(0.3)),
          ),
          child: Opacity(
            opacity: isIncluded ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isIncluded,
                          activeColor: AppColors.gold,
                          checkColor: AppColors.canvas,
                          onChanged: (val) {
                            ref.read(portfolioProvider.notifier).toggleAssetInclusion(asset.id, val ?? true);
                          },
                        ),
                        Icon(asset.category.icon, size: 16, color: isIncluded ? asset.category.color : AppColors.textDisabled),
                        const SizedBox(width: 8),
                        Text(
                          asset.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isIncluded ? AppColors.textPrimary : AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.textSecondary),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AddInvestmentDialog(assetToEdit: asset),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.loss),
                          onPressed: () => _confirmDelete(context, ref, asset),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Valuation', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                        Text(
                          CurrencyFormatter.formatCompact(asset.currentValue, currency: currency),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isIncluded ? AppColors.goldLight : AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('CAGR / Returns', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                        Text(
                          '${asset.expectedCAGR}% (${CurrencyFormatter.formatPercent(asset.returnPercentage)})',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: returnColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, InvestmentAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        title: Text('Delete Asset', style: AppTypography.heading3),
        content: Text('Are you sure you want to remove "${asset.name}" from your portfolio?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(portfolioProvider.notifier).deleteAsset(asset.id);
              Navigator.of(ctx).pop();
            },
            child: Text('Delete', style: AppTypography.buttonText.copyWith(color: AppColors.loss)),
          ),
        ],
      ),
    );
  }
}
