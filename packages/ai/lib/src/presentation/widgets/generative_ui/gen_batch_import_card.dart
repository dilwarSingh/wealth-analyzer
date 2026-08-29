import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenBatchImportCard extends StatefulWidget {
  final BatchAssetImportPayload payload;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;
  final AIPortfolioActionDelegate? actionDelegate;
  final VoidCallback? onImported;

  const GenBatchImportCard({
    super.key,
    required this.payload,
    required this.theme,
    this.currencyDelegate,
    this.actionDelegate,
    this.onImported,
  });

  @override
  State<GenBatchImportCard> createState() => _GenBatchImportCardState();
}

class _GenBatchImportCardState extends State<GenBatchImportCard> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.payload.extractedAssets.map((a) => a.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final payload = widget.payload;
    final compact = widget.currencyDelegate != null
        ? widget.currencyDelegate!.compactAmount
        : (double v) => '₹${v.toStringAsFixed(0)}';

    final totalSelected = widget.payload.extractedAssets
        .where((a) => _selectedIds.contains(a.id))
        .fold(0.0, (sum, a) => sum + a.currentValue);

    return AIGlassCard(
      theme: theme,
      margin: const EdgeInsets.symmetric(vertical: 8),
      borderColor: theme.secondaryAccentColor.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.secondaryAccentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long_rounded, color: theme.secondaryAccentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payload.sourceDescription,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      '${payload.extractedAssets.length} Holdings Extracted (${compact(totalSelected)})',
                      style: GoogleFonts.inter(fontSize: 11, color: theme.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              if (payload.isImported)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.successColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    'Imported ✓',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.successColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Holdings List
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: theme.surfaceLightColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.borderColor.withOpacity(0.3)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: payload.extractedAssets.length,
              separatorBuilder: (context, index) => Divider(color: theme.borderColor.withOpacity(0.2), height: 1),
              itemBuilder: (ctx, i) {
                final asset = payload.extractedAssets[i];
                final isSelected = _selectedIds.contains(asset.id);

                return InkWell(
                  onTap: payload.isImported
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(asset.id);
                            } else {
                              _selectedIds.add(asset.id);
                            }
                          });
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        if (!payload.isImported)
                          Checkbox(
                            value: isSelected,
                            activeColor: theme.secondaryAccentColor,
                            checkColor: Colors.black,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(asset.id);
                                } else {
                                  _selectedIds.remove(asset.id);
                                }
                              });
                            },
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                asset.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimaryColor,
                                ),
                              ),
                              Text(
                                asset.category.displayName,
                                style: GoogleFonts.inter(fontSize: 10, color: theme.textMutedColor),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          compact(asset.currentValue),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.secondaryAccentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (!payload.isImported && _selectedIds.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (widget.actionDelegate != null) {
                    final selectedAssets = widget.payload.extractedAssets
                        .where((a) => _selectedIds.contains(a.id))
                        .toList();
                    final success = await widget.actionDelegate!.onBatchImport(selectedAssets);
                    if (success && widget.onImported != null) {
                      widget.onImported!();
                    }
                  }
                },
                icon: const Icon(Icons.file_download_done_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Import ${_selectedIds.length} Assets into Portfolio',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryAccentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
