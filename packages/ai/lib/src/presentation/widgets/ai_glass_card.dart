import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/contracts/ai_portfolio_contract.dart';

/// Reusable Glassmorphism container for AI widgets and chat bubbles
class AIGlassCard extends StatelessWidget {
  final Widget child;
  final AIThemeData theme;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double? borderRadius;
  final BoxBorder? customBorder;

  const AIGlassCard({
    super.key,
    required this.child,
    required this.theme,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? theme.borderRadius;
    final bg = backgroundColor ?? theme.surfaceColor.withOpacity(0.85);
    final border = customBorder ?? Border.all(color: borderColor ?? theme.borderColor, width: 1);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: theme.glassBlur, sigmaY: theme.glassBlur),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
