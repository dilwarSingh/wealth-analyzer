import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class CrimsonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const CrimsonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.width,
    this.height = 44,
    this.padding,
  });

  @override
  State<CrimsonButton> createState() => _CrimsonButtonState();
}

class _CrimsonButtonState extends State<CrimsonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    if (widget.isSecondary) {
      bg = _isHovered ? AppColors.surfaceLight : AppColors.surface;
    } else {
      bg = _isHovered ? AppColors.crimsonHover : AppColors.crimson;
    }

    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 18, vertical: 10);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isEnabled ? widget.onPressed : null,
        onHover: (hovered) {
          if (mounted) setState(() => _isHovered = hovered);
        },
        borderRadius: BorderRadius.circular(10),
        splashColor: (widget.isSecondary ? AppColors.gold : Colors.white).withOpacity(0.15),
        highlightColor: (widget.isSecondary ? AppColors.gold : Colors.white).withOpacity(0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: isEnabled ? bg : AppColors.surfaceLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSecondary
                  ? (_isHovered ? AppColors.gold.withOpacity(0.6) : AppColors.border)
                  : (_isHovered ? AppColors.crimsonLight : AppColors.crimson),
              width: 1.2,
            ),
            boxShadow: [
              if (!widget.isSecondary && isEnabled)
                BoxShadow(
                  color: _isHovered
                      ? AppColors.crimson.withOpacity(0.45)
                      : AppColors.crimsonGlow,
                  blurRadius: _isHovered ? 14 : 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 17,
                          color: widget.isSecondary
                              ? (_isHovered ? AppColors.goldLight : AppColors.textSecondary)
                              : Colors.white,
                        ),
                        const SizedBox(width: 7),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          style: AppTypography.buttonText.copyWith(
                            fontSize: 13,
                            color: widget.isSecondary
                                ? (_isHovered ? AppColors.goldLight : AppColors.textPrimary)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
