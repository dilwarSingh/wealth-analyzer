import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class CustomFinancialSlider extends StatelessWidget {
  final String label;
  final String valueDisplay;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String? subtitle;
  final IconData? icon;
  final Color activeColor;

  const CustomFinancialSlider({
    super.key,
    required this.label,
    required this.valueDisplay,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.activeColor = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: activeColor),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
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
                color: activeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: activeColor.withOpacity(0.4)),
              ),
              child: Text(
                valueDisplay,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: activeColor == AppColors.gold ? AppColors.goldLight : activeColor,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTypography.bodySmall),
        ],
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: Colors.white,
            overlayColor: activeColor.withOpacity(0.2),
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0, elevation: 3),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
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
    );
  }
}
