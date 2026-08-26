import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? borderGradient;
  final Gradient? backgroundGradient;
  final VoidCallback? onTap;
  final BoxShadow? glowShadow;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.blur = 12.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderGradient,
    this.backgroundGradient,
    this.onTap,
    this.glowShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surfaceGlass;
    final effectiveBorderColor = borderColor ?? AppColors.border;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundGradient == null ? effectiveBg : null,
            gradient: backgroundGradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    effectiveBg.withOpacity(0.85),
                    effectiveBg.withOpacity(0.65),
                  ],
                ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: effectiveBorderColor,
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              ?glowShadow,
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: AppColors.crimson.withOpacity(0.04),
          splashColor: AppColors.crimson.withOpacity(0.08),
          child: content,
        ),
      );
    }

    return content;
  }
}
