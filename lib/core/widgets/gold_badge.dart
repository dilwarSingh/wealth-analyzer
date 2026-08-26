import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class GoldBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isGlow;
  final VoidCallback? onTap;

  const GoldBadge({
    super.key,
    required this.label,
    this.icon,
    this.isGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.5),
          width: 1.0,
        ),
        boxShadow: [
          if (isGlow)
            BoxShadow(
              color: AppColors.gold.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.gold),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.goldLight,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: badge,
      );
    }
    return badge;
  }
}
