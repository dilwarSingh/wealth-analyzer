import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType)? builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return ScreenType.desktop;
    if (width >= 640) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 640 && width < 1024;
  }
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 640;

  @override
  Widget build(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.desktop:
        return desktop ?? builder?.call(context, screenType) ?? const SizedBox.shrink();
      case ScreenType.tablet:
        return tablet ?? mobile ?? builder?.call(context, screenType) ?? const SizedBox.shrink();
      case ScreenType.mobile:
        return mobile ?? builder?.call(context, screenType) ?? const SizedBox.shrink();
    }
  }
}
