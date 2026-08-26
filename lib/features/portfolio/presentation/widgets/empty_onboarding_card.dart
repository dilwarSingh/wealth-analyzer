import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/crimson_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import 'add_investment_dialog.dart';

class EmptyOnboardingCard extends ConsumerWidget {
  const EmptyOnboardingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      borderColor: AppColors.gold.withOpacity(0.4),
      glowShadow: BoxShadow(
        color: AppColors.gold.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.crimson, AppColors.gold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to Wealth Analyzer',
            style: AppTypography.heading1.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              'Model, aggregate, and project your complete investment portfolio across one-time assets and recurring monthly SIPs with precision compound interest and inflation forecasting.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          // Sample Presets or Custom Add
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              CrimsonButton(
                text: '+ Add Your First Investment',
                icon: Icons.add_rounded,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AddInvestmentDialog(),
                  );
                },
              ),
              CrimsonButton(
                text: 'Load Balanced Starter Preset',
                icon: Icons.auto_awesome_rounded,
                isSecondary: true,
                onPressed: () {
                  ref.read(portfolioProvider.notifier).loadSamplePreset('balanced');
                },
              ),
              CrimsonButton(
                text: 'Load Aggressive Growth Preset',
                icon: Icons.trending_up_rounded,
                isSecondary: true,
                onPressed: () {
                  ref.read(portfolioProvider.notifier).loadSamplePreset('aggressive');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
