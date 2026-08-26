import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class CustomFinancialSlider extends StatefulWidget {
  final String label;
  final String valueDisplay;
  final String Function(double value)? valueFormatter;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? subtitle;
  final IconData? icon;
  final Color activeColor;

  const CustomFinancialSlider({
    super.key,
    required this.label,
    required this.valueDisplay,
    this.valueFormatter,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.onChangeEnd,
    this.subtitle,
    this.icon,
    this.activeColor = AppColors.gold,
  });

  @override
  State<CustomFinancialSlider> createState() => _CustomFinancialSliderState();
}

class _CustomFinancialSliderState extends State<CustomFinancialSlider> {
  late double _currentValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(covariant CustomFinancialSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging || oldWidget.min != widget.min || oldWidget.max != widget.max) {
      _currentValue = widget.value.clamp(widget.min, widget.max);
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = widget.valueFormatter != null
        ? widget.valueFormatter!(_currentValue)
        : widget.valueDisplay;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 16, color: widget.activeColor),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.activeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: widget.activeColor.withOpacity(0.4)),
                ),
                child: Text(
                  display,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.activeColor == AppColors.gold ? AppColors.goldLight : widget.activeColor,
                  ),
                ),
              ),
            ],
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(widget.subtitle!, style: AppTypography.bodySmall),
          ],
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.activeColor,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: Colors.white,
              overlayColor: widget.activeColor.withOpacity(0.2),
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0, elevation: 3),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            ),
            child: Slider(
              value: _currentValue.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              onChangeStart: (_) {
                _isDragging = true;
              },
              onChanged: (newVal) {
                setState(() {
                  _currentValue = newVal;
                });
                widget.onChanged(newVal);
              },
              onChangeEnd: (finalVal) {
                _isDragging = false;
                widget.onChangeEnd?.call(finalVal);
              },
            ),
          ),
        ],
      ),
    );
  }
}
