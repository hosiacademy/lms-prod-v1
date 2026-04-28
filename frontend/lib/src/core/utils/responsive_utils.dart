// lib/src/core/utils/responsive_utils.dart

import 'package:flutter/material.dart';

/// Responsive utility class
class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobileBreakpoint;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tabletBreakpoint;
  static bool isLandscape(BuildContext context) => MediaQuery.of(context).orientation == Orientation.landscape;

  static T valueWhen<T>(BuildContext context, {required T mobile, T? tablet, T? desktop}) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  static int getGridCrossAxisCount(BuildContext context, {int mobile = 2, int? tablet, int? desktop}) {
    return valueWhen(context, mobile: mobile, tablet: tablet ?? 3, desktop: desktop ?? 4);
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    return valueWhen(context, mobile: const EdgeInsets.all(16), tablet: const EdgeInsets.all(24), desktop: const EdgeInsets.all(32));
  }

  static double getResponsiveSpacing(BuildContext context) {
    return valueWhen(context, mobile: 8.0, tablet: 12.0, desktop: 16.0);
  }

  static double getCardAspectRatio(BuildContext context) {
    if (isLandscape(context)) return valueWhen(context, mobile: 1.2, tablet: 1.3, desktop: 1.4);
    return valueWhen(context, mobile: 0.7, tablet: 0.75, desktop: 0.8);
  }
}

extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  T responsiveValue<T>({required T mobile, T? tablet, T? desktop}) => ResponsiveUtils.valueWhen(this, mobile: mobile, tablet: tablet, desktop: desktop);
}
