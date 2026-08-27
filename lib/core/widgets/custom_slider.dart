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
  final String? tooltipMessage;
  final Widget? headerAction;

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
    this.tooltipMessage,
    this.headerAction,
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.tooltipMessage != null) ...[
                    const SizedBox(width: 5),
                    Tooltip(
                      message: widget.tooltipMessage!,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.activeColor.withOpacity(0.4), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      textStyle: const TextStyle(
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
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: AppColors.textMuted.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (widget.headerAction != null) widget.headerAction!,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.activeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.activeColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      display,
                      style: AppTypography.label.copyWith(
                        color: widget.activeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
