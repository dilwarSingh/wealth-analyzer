import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/contracts/ai_portfolio_contract.dart';
import '../../../domain/entities/generative_ui_payload.dart';
import '../ai_glass_card.dart';

class GenScenarioSliderCard extends StatefulWidget {
  final ScenarioSimulatorPayload payload;
  final AIThemeData theme;
  final AICurrencyDelegate? currencyDelegate;

  const GenScenarioSliderCard({
    super.key,
    required this.payload,
    required this.theme,
    this.currencyDelegate,
  });

  @override
  State<GenScenarioSliderCard> createState() => _GenScenarioSliderCardState();
}

class _GenScenarioSliderCardState extends State<GenScenarioSliderCard> {
  late double _expectedReturn;
  late double _annualSavings;
  late double _inflationRate;
  late int _years;

  @override
  void initState() {
    super.initState();
    _expectedReturn = widget.payload.defaultExpectedReturn;
    _annualSavings = widget.payload.defaultAnnualSavings;
    _inflationRate = widget.payload.defaultInflationRate;
    _years = widget.payload.defaultYears;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final compact = widget.currencyDelegate != null
        ? widget.currencyDelegate!.compactAmount
        : (double v) => '${widget.payload.currencySymbol}${v.toStringAsFixed(0)}';

    // Calculate curve points
    final initial = widget.payload.initialNetWorth;
    final realRate = ((1 + _expectedReturn / 100) / (1 + _inflationRate / 100)) - 1;

    final spots = <FlSpot>[];
    for (int y = 0; y <= _years; y += (_years > 20 ? 5 : 2)) {
      double fv = initial * pow(1 + realRate, y);
      if (realRate > 0) {
        fv += _annualSavings * ((pow(1 + realRate, y) - 1) / realRate);
      } else {
        fv += _annualSavings * y;
      }
      spots.add(FlSpot(y.toDouble(), fv));
    }
    final finalValue = spots.isNotEmpty ? spots.last.y : 0.0;

    return AIGlassCard(
      theme: theme,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: theme.secondaryAccentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Interactive What-If Scenario Simulator',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Text(
                'Corpus: ${compact(finalValue)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.secondaryAccentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Chart Preview
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (val, meta) => Text(
                        'Y${val.toInt()}',
                        style: GoogleFonts.inter(fontSize: 9, color: theme.textMutedColor),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: theme.secondaryAccentColor,
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.secondaryAccentColor.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Return Slider
          _buildSlider(
            label: 'Expected Return (CAGR): ${_expectedReturn.toStringAsFixed(1)}%',
            value: _expectedReturn,
            min: 4.0,
            max: 25.0,
            onChanged: (v) => setState(() => _expectedReturn = v),
          ),

          // Annual Savings Slider
          _buildSlider(
            label: 'Annual SIP / Savings: ${compact(_annualSavings)}',
            value: _annualSavings,
            min: 0.0,
            max: (widget.payload.defaultAnnualSavings * 3).clamp(50000.0, 50000000.0),
            onChanged: (v) => setState(() => _annualSavings = v),
          ),

          // Horizon Slider
          _buildSlider(
            label: 'Time Horizon: $_years Years',
            value: _years.toDouble(),
            min: 5.0,
            max: 40.0,
            divisions: 35,
            onChanged: (v) => setState(() => _years = v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.secondaryAccentColor,
              inactiveTrackColor: theme.surfaceLightColor,
              thumbColor: theme.secondaryAccentColor,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
