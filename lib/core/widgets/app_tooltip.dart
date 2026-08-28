import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTooltip extends StatelessWidget {
  final String message;
  final Widget? child;
  final bool showIcon;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final bool preferBelow;
  final double verticalOffset;
  final MainAxisSize mainAxisSize;

  const AppTooltip({
    super.key,
    required this.message,
    this.child,
    this.showIcon = true,
    this.icon = Icons.info_outline_rounded,
    this.iconSize = 14,
    this.iconColor,
    this.preferBelow = false,
    this.verticalOffset = 12,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? AppColors.textMuted;

    Widget content;
    if (child != null && showIcon) {
      content = Row(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(child: child!),
          const SizedBox(width: 5),
          Icon(icon, size: iconSize, color: effectiveColor),
        ],
      );
    } else if (child != null) {
      content = child!;
    } else {
      content = Icon(icon, size: iconSize, color: effectiveColor);
    }

    return Tooltip(
      message: message,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effectiveColor.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.35,
      ),
      preferBelow: preferBelow,
      verticalOffset: verticalOffset,
      child: content,
    );
  }
}
