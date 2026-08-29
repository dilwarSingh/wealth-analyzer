import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../widgets/app_header.dart';
import 'dashboard_desktop_view.dart';
import 'dashboard_mobile_view.dart';

class WealthDashboardScreen extends ConsumerStatefulWidget {
  const WealthDashboardScreen({super.key});

  @override
  ConsumerState<WealthDashboardScreen> createState() => _WealthDashboardScreenState();
}

class _WealthDashboardScreenState extends ConsumerState<WealthDashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Ambient Background Glows
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.crimson.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Column(
              children: [
                // Top Glass Header
                AppHeader(
                  selectedTabIndex: _selectedTabIndex,
                  onTabSelected: (index) => setState(() => _selectedTabIndex = index),
                ),

                // Responsive Body
                Expanded(
                  child: ResponsiveBuilder(
                    desktop: DashboardDesktopView(
                      selectedTabIndex: _selectedTabIndex,
                      onTabSelected: (index) => setState(() => _selectedTabIndex = index),
                    ),
                    mobile: DashboardMobileView(
                      selectedTabIndex: _selectedTabIndex,
                      onTabSelected: (index) => setState(() => _selectedTabIndex = index),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
