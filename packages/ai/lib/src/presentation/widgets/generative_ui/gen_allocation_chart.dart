import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenAllocationChart extends StatefulWidget {
  final AllocationChartPayload payload;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;

  const GenAllocationChart({
    super.key,
    required this.payload,
    required this.theme,
    this.currencyDelegate,
  });

  @override
  State<GenAllocationChart> createState() => _GenAllocationChartState();
}

class _GenAllocationChartState extends State<GenAllocationChart> {
  int _touchedIndex = -1;

  final List<Color> _palette = const [
    Color(0xFFE63946), // Crimson
    Color(0xFFFFD166), // Gold
    Color(0xFF06D6A0), // Emerald
    Color(0xFF118AB2), // Ocean Blue
    Color(0xFF9D4EDD), // Purple
    Color(0xFFFF8800), // Orange
    Color(0xFF8338EC), // Violet
    Color(0xFF457B9D), // Steel Blue
  ];

  @override
  Widget build(BuildContext context) {
    final slices = widget.payload.slices;
    final theme = widget.theme;
    final compact = widget.currencyDelegate != null
        ? widget.currencyDelegate!.compactAmount
        : (double v) => '${widget.payload.currencySymbol}${v.toStringAsFixed(0)}';

    return AIGlassCard(
      theme: theme,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: theme.secondaryAccentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Asset Allocation Breakdown',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${compact(widget.payload.totalAmount)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryAccentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Donut Chart
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: List.generate(slices.length, (i) {
                        final isTouched = i == _touchedIndex;
                        final slice = slices[i];
                        final radius = isTouched ? 48.0 : 40.0;
                        final color = _palette[i % _palette.length];

                        return PieChartSectionData(
                          color: color,
                          value: slice.percentage,
                          title: isTouched ? '${slice.percentage.toStringAsFixed(0)}%' : '',
                          radius: radius,
                          titleStyle: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Legend
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(slices.length, (i) {
                        final slice = slices[i];
                        final color = _palette[i % _palette.length];
                        final isTouched = i == _touchedIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  slice.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isTouched ? FontWeight.w700 : FontWeight.w500,
                                    color: isTouched ? theme.textPrimaryColor : theme.textSecondaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${slice.percentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
