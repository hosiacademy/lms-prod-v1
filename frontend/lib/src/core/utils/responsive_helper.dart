/// Responsive Design Helper for Flutter Web LMS
/// 
/// Provides utilities for implementing cross-platform responsive design
/// across mobile, tablet, and desktop devices with appropriate breakpoints.
/// 
/// **Breakpoints:**
/// - Mobile: < 600px
/// - Tablet: 600px - 1024px  
/// - Desktop: ≥ 1024px
/// 
/// **Usage:**
/// ```dart
/// ResponsiveHelper.isMobile(context)      // Check if mobile
/// ResponsiveHelper.isTablet(context)      // Check if tablet
/// ResponsiveHelper.isDesktop(context)     // Check if desktop
/// ResponsiveHelper.screenWidth(context)   // Get screen width
/// ResponsiveHelper.screenHeight(context)  // Get screen height
/// ResponsiveHelper.padding(context)       // Responsive padding
/// ResponsiveHelper.fontSize(context, 16)  // Responsive font size
/// ```

import 'package:flutter/material.dart';

class ResponsiveHelper {
  // ─────────────────────────────────────────────────────────────────────────
  // BREAKPOINTS - Standard Flutter Web Responsive Sizes
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Mobile breakpoint: screens < 600px (phones)
  static const double BREAKPOINT_MOBILE = 600.0;
  
  /// Tablet breakpoint: screens 600px - 1024px (tablets)
  static const double BREAKPOINT_TABLET = 1024.0;
  
  /// Desktop breakpoint: screens ≥ 1024px (desktops, large tablets)
  static const double BREAKPOINT_DESKTOP = 1024.0;
  
  // ─────────────────────────────────────────────────────────────────────────
  // BREAKPOINT CHECKS
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Check if current device is mobile (< 600px width)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < BREAKPOINT_MOBILE;
  }
  
  /// Check if current device is tablet (600px - 1024px width)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= BREAKPOINT_MOBILE && width < BREAKPOINT_TABLET;
  }
  
  /// Check if current device is desktop (≥ 1024px width)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= BREAKPOINT_DESKTOP;
  }
  
  /// Check if current device is mobile or tablet (< 1024px width)
  static bool isMobileOrTablet(BuildContext context) {
    return MediaQuery.of(context).size.width < BREAKPOINT_TABLET;
  }
  
  /// Get screen size category for responsive logic
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < BREAKPOINT_MOBILE) {
      return ScreenSize.mobile;
    } else if (width < BREAKPOINT_TABLET) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.desktop;
    }
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN DIMENSIONS
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Get device pixel ratio (scale factor)
  static double devicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }
  
  /// Get usable height (height - status bar - nav bar)
  static double usableHeight(BuildContext context) {
    return MediaQuery.of(context).size.height - 
           MediaQuery.of(context).padding.top - 
           MediaQuery.of(context).padding.bottom;
  }
  
  /// Get usable width (width - side padding)
  static double usableWidth(BuildContext context) {
    return MediaQuery.of(context).size.width - 
           MediaQuery.of(context).padding.left - 
           MediaQuery.of(context).padding.right;
  }
  
  /// Check if landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Check if portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // RESPONSIVE SPACING
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get responsive padding for page/container
  /// Mobile: 16px, Tablet: 24px, Desktop: 32px
  static double padding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }
  
  /// Get responsive horizontal padding (left/right)
  static EdgeInsets paddingHorizontal(BuildContext context) {
    final pad = padding(context);
    return EdgeInsets.symmetric(horizontal: pad);
  }
  
  /// Get responsive vertical padding (top/bottom)
  static EdgeInsets paddingVertical(BuildContext context) {
    final pad = padding(context);
    return EdgeInsets.symmetric(vertical: pad);
  }
  
  /// Get responsive padding for all sides
  static EdgeInsets paddingAll(BuildContext context) {
    final pad = padding(context);
    return EdgeInsets.all(pad);
  }
  
  /// Get responsive gap/spacing between elements
  /// Mobile: 12px, Tablet: 16px, Desktop: 20px
  static double gap(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }
  
  /// Get small responsive spacing
  /// Mobile: 8px, Tablet: 12px, Desktop: 16px
  static double spacingSmall(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }
  
  /// Get medium responsive spacing (default)
  /// Mobile: 12px, Tablet: 16px, Desktop: 20px
  static double spacingMedium(BuildContext context) {
    return gap(context);
  }
  
  /// Get large responsive spacing
  /// Mobile: 16px, Tablet: 24px, Desktop: 32px
  static double spacingLarge(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }
  
  /// Get extra large responsive spacing
  /// Mobile: 24px, Tablet: 32px, Desktop: 48px
  static double spacingXL(BuildContext context) {
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 32.0;
    return 48.0;
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // RESPONSIVE TYPOGRAPHY
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get responsive font size with scaling factor
  /// Scales down on mobile, normal on tablet, slight increase on desktop
  static double fontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize * 0.9; // 90% on mobile
    } else if (isTablet(context)) {
      return baseSize; // 100% on tablet (base)
    } else {
      return baseSize * 1.05; // 105% on desktop
    }
  }
  
  /// Get responsive heading 1 font size
  /// Mobile: 28px, Tablet: 32px, Desktop: 40px
  static double h1(BuildContext context) {
    if (isMobile(context)) return 28.0;
    if (isTablet(context)) return 32.0;
    return 40.0;
  }
  
  /// Get responsive heading 2 font size
  /// Mobile: 24px, Tablet: 28px, Desktop: 32px
  static double h2(BuildContext context) {
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 28.0;
    return 32.0;
  }
  
  /// Get responsive heading 3 font size
  /// Mobile: 20px, Tablet: 24px, Desktop: 28px
  static double h3(BuildContext context) {
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 24.0;
    return 28.0;
  }
  
  /// Get responsive body text font size
  /// Mobile: 14px, Tablet: 16px, Desktop: 16px
  static double body(BuildContext context) {
    if (isMobile(context)) return 14.0;
    return 16.0;
  }
  
  /// Get responsive caption font size
  /// Mobile: 12px, Tablet: 13px, Desktop: 14px
  static double caption(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 13.0;
    return 14.0;
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // RESPONSIVE LAYOUT - GRID/COLUMN COUNTS
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get responsive grid column count
  /// Mobile: 1, Tablet: 2, Desktop: 3
  static int gridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
  
  /// Get responsive grid column count (4-column variant)
  /// Mobile: 1, Tablet: 2, Desktop: 4
  static int gridColumns4(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 4;
  }
  
  /// Get responsive grid cross-axis spacing
  /// Mobile: 12px, Tablet: 16px, Desktop: 20px
  static double gridCrossAxisSpacing(BuildContext context) {
    return gap(context);
  }
  
  /// Get responsive grid main-axis spacing
  /// Mobile: 12px, Tablet: 16px, Desktop: 20px
  static double gridMainAxisSpacing(BuildContext context) {
    return gap(context);
  }
  
  /// Get responsive card width (for fixed-width layouts)
  /// Mobile: Full width with padding
  /// Tablet: ~320px with padding
  /// Desktop: ~400px with padding
  static double cardWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) - (padding(context) * 2);
    } else if (isTablet(context)) {
      return 320.0;
    } else {
      return 400.0;
    }
  }
  
  /// Get responsive dialog width
  /// Mobile: 90% of screen width
  /// Tablet: 500px
  /// Desktop: 600px
  static double dialogWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) * 0.9;
    } else if (isTablet(context)) {
      return 500.0;
    } else {
      return 600.0;
    }
  }
  
  /// Get responsive container max width (for centered layouts)
  /// Mobile: Full width
  /// Tablet: 600px
  /// Desktop: 1200px
  static double maxContainerWidth(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) - (padding(context) * 2);
    } else if (isTablet(context)) {
      return 600.0;
    } else {
      return 1200.0;
    }
  }
  
  /// Get responsive sidebar width
  /// Mobile: Full width or hidden
  /// Tablet: ~250px
  /// Desktop: ~300px
  static double sidebarWidth(BuildContext context) {
    if (isMobile(context)) return 0;
    if (isTablet(context)) return 250.0;
    return 300.0;
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // RESPONSIVE BORDER RADIUS
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get responsive border radius
  /// Mobile: 8px, Tablet: 10px, Desktop: 12px
  static double borderRadius(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 10.0;
    return 12.0;
  }
  
  /// Get responsive border radius small
  /// Mobile: 4px, Tablet: 6px, Desktop: 8px
  static double borderRadiusSmall(BuildContext context) {
    if (isMobile(context)) return 4.0;
    if (isTablet(context)) return 6.0;
    return 8.0;
  }
  
  /// Get responsive border radius large
  /// Mobile: 12px, Tablet: 16px, Desktop: 20px
  static double borderRadiusLarge(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // RESPONSIVE ELEVATION/SHADOW
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get responsive elevation/shadow
  /// Mobile: 2, Tablet: 4, Desktop: 6
  static double elevation(BuildContext context) {
    if (isMobile(context)) return 2.0;
    if (isTablet(context)) return 4.0;
    return 6.0;
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // RESPONSIVE WIDGET SIZE
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get responsive button height
  /// Mobile: 44px, Tablet: 48px, Desktop: 48px
  static double buttonHeight(BuildContext context) {
    if (isMobile(context)) return 44.0;
    return 48.0;
  }
  
  /// Get responsive icon size
  /// Mobile: 24px, Tablet: 28px, Desktop: 32px
  static double iconSize(BuildContext context, {IconSizeCategory size = IconSizeCategory.medium}) {
    switch (size) {
      case IconSizeCategory.small:
        if (isMobile(context)) return 16.0;
        if (isTablet(context)) return 20.0;
        return 24.0;
      case IconSizeCategory.medium:
        if (isMobile(context)) return 24.0;
        if (isTablet(context)) return 28.0;
        return 32.0;
      case IconSizeCategory.large:
        if (isMobile(context)) return 32.0;
        if (isTablet(context)) return 40.0;
        return 48.0;
    }
  }
  
  /// Get responsive image height
  /// Mobile: 160px, Tablet: 240px, Desktop: 300px
  static double imageHeight(BuildContext context) {
    if (isMobile(context)) return 160.0;
    if (isTablet(context)) return 240.0;
    return 300.0;
  }
  
  /// Get responsive appbar height
  /// Mobile: 56px, Tablet: 64px, Desktop: 64px
  static double appBarHeight(BuildContext context) {
    if (isMobile(context)) return 56.0;
    return 64.0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FLUID LAYOUT UTILITIES
  // ─────────────────────────────────────────────────────────────────────────

  /// Fluid Scroll Wrapper
  /// Ensures keyboard awareness on mobile and smooth scrolling on all platforms.
  static Widget fluidScroll({
    required BuildContext context,
    required Widget child,
    ScrollPhysics? physics,
    EdgeInsets? padding,
  }) {
    return SingleChildScrollView(
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      child: child,
    );
  }

  /// Adaptive Layout Wrapper
  /// Swaps between Row and Column based on screen width.
  static Widget adaptiveLayout({
    required BuildContext context,
    required List<Widget> children,
    double breakpoint = BREAKPOINT_MOBILE,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double spacing = 16.0,
  }) {
    final width = screenWidth(context);
    if (width < breakpoint) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children.expand((w) => [w, SizedBox(height: spacing)]).toList()..removeLast(),
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children.expand((w) => [w, SizedBox(width: spacing)]).toList()..removeLast(),
      );
    }
  }

  /// Keyboard-aware padding
  static double keyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }
}

/// Screen size categories for responsive design
enum ScreenSize { mobile, tablet, desktop }

/// Icon size categories
enum IconSizeCategory { small, medium, large }
