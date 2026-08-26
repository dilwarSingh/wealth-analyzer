import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Non-intrusive read-only label that displays the simple-language denomination
/// (e.g. "≈ 1.5 Cr", "≈ 45 L", "≈ 50 K" / "≈ 1.5 M", "≈ 450 K") on the right-hand side of headers/labels.
class CompactAmountLabel extends StatelessWidget {
  final TextEditingController controller;
  final CurrencyType currency;
  final Color? accentColor;
  final String prefix;

  const CompactAmountLabel({
    super.key,
    required this.controller,
    required this.currency,
    this.accentColor,
    this.prefix = '≈ ',
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final raw = value.text.replaceAll(',', '').trim();
        final amount = double.tryParse(raw) ?? 0.0;
        if (amount <= 0) return const SizedBox.shrink();

        final compactText = CurrencyFormatter.formatCompactDenomination(
          amount,
          currency: currency,
        );

        if (compactText.isEmpty) return const SizedBox.shrink();

        final color = accentColor ?? AppColors.goldLight;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text(
            '$prefix$compactText',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class CompactAmountSuffixBadge extends StatelessWidget {
  final TextEditingController controller;
  final CurrencyType currency;
  final Color? accentColor;

  const CompactAmountSuffixBadge({
    super.key,
    required this.controller,
    required this.currency,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CompactAmountLabel(
        controller: controller,
        currency: currency,
        accentColor: accentColor,
      ),
    );
  }
}
