import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/cash_flow_node.dart';
import '../viewmodels/currency_viewmodel.dart';
import '../viewmodels/portfolio_viewmodel.dart';

class SankeyCashFlowWidget extends ConsumerStatefulWidget {
  const SankeyCashFlowWidget({super.key});

  @override
  ConsumerState<SankeyCashFlowWidget> createState() => _SankeyCashFlowWidgetState();
}

class _SankeyCashFlowWidgetState extends ConsumerState<SankeyCashFlowWidget> {
  int? _hoveredLinkIndex;

  @override
  Widget build(BuildContext context) {
    final portfolioState = ref.watch(portfolioProvider);
    final currency = ref.watch(currencyProvider);
    final sankeyData = portfolioState.sankeyData;

    final hasData = sankeyData.links.isNotEmpty && sankeyData.totalMonthlyInflow > 0;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.alt_route_rounded, size: 20, color: AppColors.crimson),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'CASH-FLOW SANKEY',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Inflow: ${CurrencyFormatter.formatCompact(sankeyData.totalMonthlyInflow, currency: currency)} / mo',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Visual routing of your recurring monthly capital across wealth buckets and liquidity reserves.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),
          if (!hasData)
            Container(
              height: 240,
              alignment: Alignment.center,
              child: Text(
                'Add Monthly SIPs or assets to generate your interactive cash flow diagram.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double height = 260.0;

                return SizedBox(
                  height: height,
                  width: width,
                  child: CustomPaint(
                    painter: _SankeyPainter(
                      data: sankeyData,
                      hoveredIndex: _hoveredLinkIndex,
                      currency: currency,
                    ),
                    child: _buildInteractiveOverlay(width, height, sankeyData, currency),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          // Interactive hint
          if (hasData)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Hover or tap ribbons to highlight cash flow allocation paths',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveOverlay(
    double width,
    double height,
    SankeyCashFlowData data,
    CurrencyType currency,
  ) {
    const double nodeWidth = 135.0;
    final int targetCount = data.links.length;
    final double targetSpacing = height / (targetCount > 0 ? targetCount : 1);

    return Stack(
      children: [
        // Left Source Node (Monthly Inflow)
        Positioned(
          left: 0,
          top: (height - 64) / 2,
          child: Container(
            width: nodeWidth,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'TOTAL INFLOW',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.goldLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  CurrencyFormatter.formatCompact(data.totalMonthlyInflow, currency: currency),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Target Nodes
        ...List.generate(data.links.length, (i) {
          final link = data.links[i];
          final double topPos = (i * targetSpacing) + (targetSpacing - 46) / 2;
          final isHovered = _hoveredLinkIndex == i;
          final double pct = data.totalMonthlyInflow > 0
              ? (link.value / data.totalMonthlyInflow) * 100
              : 0;

          return Positioned(
            right: 0,
            top: topPos.clamp(0, height - 52),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredLinkIndex = i),
              onExit: (_) => setState(() => _hoveredLinkIndex = null),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hoveredLinkIndex = _hoveredLinkIndex == i ? null : i;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: nodeWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? link.color.withOpacity(0.25)
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isHovered ? link.color : AppColors.border,
                      width: isHovered ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              link.targetLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${CurrencyFormatter.formatCompact(link.value, currency: currency)} (${pct.toStringAsFixed(0)}%)',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: link.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: link.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SankeyPainter extends CustomPainter {
  final SankeyCashFlowData data;
  final int? hoveredIndex;
  final CurrencyType currency;

  _SankeyPainter({
    required this.data,
    required this.hoveredIndex,
    required this.currency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.links.isEmpty || data.totalMonthlyInflow <= 0) return;

    const double nodeWidth = 135.0;
    final double startX = nodeWidth;
    final double endX = size.width - nodeWidth;
    final double centerY = size.height / 2;

    final int linkCount = data.links.length;
    final double targetSpacing = size.height / linkCount;

    // Running Y offset for source ribbon splits
    double currentSourceY = centerY - 25;
    final double totalSourceHeight = 50.0;

    for (int i = 0; i < linkCount; i++) {
      final link = data.links[i];
      final double fraction = (link.value / data.totalMonthlyInflow).clamp(0.05, 1.0);
      final double ribbonHeight = (totalSourceHeight * fraction).clamp(4.0, 24.0);

      final double sourceTop = currentSourceY;
      final double sourceBottom = currentSourceY + ribbonHeight;
      currentSourceY += ribbonHeight;

      final double targetCenterY = (i * targetSpacing) + (targetSpacing / 2);
      final double targetTop = targetCenterY - (ribbonHeight / 2);
      final double targetBottom = targetCenterY + (ribbonHeight / 2);

      final isHovered = hoveredIndex == i;
      final bool dimOther = hoveredIndex != null && !isHovered;

      final Path path = Path();
      path.moveTo(startX, sourceTop);
      path.cubicTo(
        startX + (endX - startX) * 0.5,
        sourceTop,
        startX + (endX - startX) * 0.5,
        targetTop,
        endX,
        targetTop,
      );
      path.lineTo(endX, targetBottom);
      path.cubicTo(
        startX + (endX - startX) * 0.5,
        targetBottom,
        startX + (endX - startX) * 0.5,
        sourceBottom,
        startX,
        sourceBottom,
      );
      path.close();

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.gold.withOpacity(dimOther ? 0.08 : (isHovered ? 0.7 : 0.4)),
            link.color.withOpacity(dimOther ? 0.08 : (isHovered ? 0.7 : 0.4)),
          ],
        ).createShader(Rect.fromLTRB(startX, 0, endX, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      if (isHovered) {
        final borderPaint = Paint()
          ..color = link.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawPath(path, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SankeyPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.hoveredIndex != hoveredIndex;
  }
}
