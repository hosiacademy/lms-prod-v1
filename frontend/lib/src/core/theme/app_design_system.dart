/// Enhanced App Theme with Design System Variables
/// 
/// Extends AppTheme with comprehensive spacing, typography, and responsive
/// design system variables for consistent styling across the app.

import 'package:flutter/material.dart';

class AppDesignSystem {
  // ─────────────────────────────────────────────────────────────────────────
  // SPACING SCALE - 8px Base Unit System
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Spacing scale following Material Design 3
  /// Uses 8px as base unit for consistency
  static const double xs = 4.0;      // Extra small
  static const double sm = 8.0;      // Small (1x)
  static const double md = 16.0;     // Medium (2x) - Default
  static const double lg = 24.0;     // Large (3x)
  static const double xl = 32.0;     // Extra large (4x)
  static const double xxl = 48.0;    // 2X Extra large (6x)
  static const double xxxl = 64.0;   // 3X Extra large (8x)
  
  // Common spacing values
  static const double spacingNone = 0.0;
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  
  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY - Material Design 3 Type Scale
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Display sizes - Large headlines
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  
  /// Headline sizes - Section titles
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  
  /// Title sizes - Component titles
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  
  /// Body sizes - Main content text
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  
  /// Label sizes - Small/special text
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  
  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY - Font Weights
  // ─────────────────────────────────────────────────────────────────────────
  
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
  
  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY - Line Heights (in em units)
  // ─────────────────────────────────────────────────────────────────────────
  
  static const double lineHeightTight = 1.2;      // Headings
  static const double lineHeightNormal = 1.4;     // Default
  static const double lineHeightRelaxed = 1.6;    // Body text
  static const double lineHeightLoose = 1.8;      // Reading heavy content
  
  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY - Letter Spacing
  // ─────────────────────────────────────────────────────────────────────────
  
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingExtraWide = 1.0;
  
  // ─────────────────────────────────────────────────────────────────────────
  // BORDER RADIUS
  // ─────────────────────────────────────────────────────────────────────────
  
  static const double radiusXS = 2.0;     // Minimal rounding
  static const double radiusSM = 4.0;     // Small buttons, chips
  static const double radiusMD = 8.0;     // Default (most components)
  static const double radiusLG = 12.0;    // Cards, dialogs
  static const double radiusXL = 16.0;    // Large containers
  static const double radiusXXL = 20.0;   // Extra large
  static const double radiusFull = 999.0; // Fully rounded (pills)
  
  // ─────────────────────────────────────────────────────────────────────────
  // ELEVATION / SHADOWS
  // ─────────────────────────────────────────────────────────────────────────
  
  static const double elevationNone = 0.0;
  static const double elevation1 = 1.0;    // Subtle
  static const double elevation2 = 2.0;    // Raised
  static const double elevation3 = 4.0;    // Default card
  static const double elevation4 = 6.0;    // Floating
  static const double elevation5 = 8.0;    // Modal
  static const double elevation6 = 12.0;   // Dropdown
  static const double elevation7 = 16.0;   // High
  static const double elevation8 = 20.0;   // Maximum
  
  // ─────────────────────────────────────────────────────────────────────────
  // OPACITY LEVELS
  // ─────────────────────────────────────────────────────────────────────────
  
  static const double opacityDisabled = 0.38;
  static const double opacityHovered = 0.08;
  static const double opacityFocused = 0.12;
  static const double opacityPressed = 0.16;
  static const double opacityDraggedOver = 0.04;
  
  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT SIZES
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Button sizes
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 52.0;
  
  /// Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXL = 48.0;
  
  /// Input field heights
  static const double inputHeightSmall = 36.0;
  static const double inputHeightMedium = 44.0;
  static const double inputHeightLarge = 52.0;
  
  /// AppBar heights
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;
  
  /// Chip sizes
  static const double chipHeight = 32.0;
  
  // ─────────────────────────────────────────────────────────────────────────
  // DURATION - Animation Timing
  // ─────────────────────────────────────────────────────────────────────────
  
  static const Duration durationFast = Duration(milliseconds: 100);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 800);
  
  // ─────────────────────────────────────────────────────────────────────────
  // CURVE - Animation Easing
  // ─────────────────────────────────────────────────────────────────────────
  
  static const Curve curveLinear = Curves.linear;
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveFastOutSlowIn = Curves.fastOutSlowIn;
  
  // ─────────────────────────────────────────────────────────────────────────
  // Z-INDEX / LAYER LEVELS
  // ─────────────────────────────────────────────────────────────────────────
  
  static const int zIndexBase = 0;
  static const int zIndexContent = 1;
  static const int zIndexOverlay = 10;
  static const int zIndexDropdown = 100;
  static const int zIndexModal = 1000;
  static const int zIndexToast = 10000;
  
  // ─────────────────────────────────────────────────────────────────────────
  // RESPONSIVE BREAKPOINTS
  // ─────────────────────────────────────────────────────────────────────────
  
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 1024.0;
  static const double breakpointDesktop = 1440.0;
  static const double breakpointXL = 1920.0;
  
  // ─────────────────────────────────────────────────────────────────────────
  // MAX WIDTHS - Container Constraints
  // ─────────────────────────────────────────────────────────────────────────
  
  static const double maxWidthXS = 320.0;    // Extra small containers
  static const double maxWidthSM = 480.0;    // Small containers
  static const double maxWidthMD = 640.0;    // Medium containers
  static const double maxWidthLG = 1024.0;   // Large containers
  static const double maxWidthXL = 1280.0;   // Extra large
  static const double maxWidth2XL = 1536.0;  // 2X Extra large
  
  // ─────────────────────────────────────────────────────────────────────────
  // PRESET PADDING CONFIGURATIONS
  // ─────────────────────────────────────────────────────────────────────────
  
  static EdgeInsets paddingXS = const EdgeInsets.all(4.0);
  static EdgeInsets paddingSM = const EdgeInsets.all(8.0);
  static EdgeInsets paddingMD = const EdgeInsets.all(16.0);
  static EdgeInsets paddingLG = const EdgeInsets.all(24.0);
  static EdgeInsets paddingXL = const EdgeInsets.all(32.0);
  static EdgeInsets paddingXXL = const EdgeInsets.all(48.0);
  
  // ─────────────────────────────────────────────────────────────────────────
  // PRESET GAP CONFIGURATIONS
  // ─────────────────────────────────────────────────────────────────────────
  
  static EdgeInsets gapXS = const EdgeInsets.all(4.0);
  static EdgeInsets gapSM = const EdgeInsets.all(8.0);
  static EdgeInsets gapMD = const EdgeInsets.all(12.0);
  static EdgeInsets gapLG = const EdgeInsets.all(16.0);
  static EdgeInsets gapXL = const EdgeInsets.all(24.0);
  
  // ─────────────────────────────────────────────────────────────────────────
  // PRESET TEXT STYLES
  // ─────────────────────────────────────────────────────────────────────────
  
  static TextStyle textStyleDisplayLarge = const TextStyle(
    fontSize: displayLarge,
    fontWeight: bold,
    height: lineHeightTight,
    letterSpacing: letterSpacingNormal,
  );
  
  static TextStyle textStyleHeadingLarge = const TextStyle(
    fontSize: headlineLarge,
    fontWeight: semiBold,
    height: lineHeightTight,
    letterSpacing: letterSpacingNormal,
  );
  
  static TextStyle textStyleHeadingMedium = const TextStyle(
    fontSize: headlineMedium,
    fontWeight: semiBold,
    height: lineHeightTight,
    letterSpacing: letterSpacingNormal,
  );
  
  static TextStyle textStyleTitleLarge = const TextStyle(
    fontSize: titleLarge,
    fontWeight: semiBold,
    height: lineHeightNormal,
    letterSpacing: letterSpacingNormal,
  );
  
  static TextStyle textStyleBodyLarge = const TextStyle(
    fontSize: bodyLarge,
    fontWeight: regular,
    height: lineHeightRelaxed,
    letterSpacing: letterSpacingNormal,
  );
  
  static TextStyle textStyleBodyMedium = const TextStyle(
    fontSize: bodyMedium,
    fontWeight: regular,
    height: lineHeightRelaxed,
    letterSpacing: letterSpacingNormal,
  );
  
  static TextStyle textStyleCaption = const TextStyle(
    fontSize: labelSmall,
    fontWeight: medium,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );
  
  // ─────────────────────────────────────────────────────────────────────────
  // PRESET BORDER RADIUS
  // ─────────────────────────────────────────────────────────────────────────
  
  static BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSM);
  static BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMD);
  static BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLG);
  static BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);
  
  // ─────────────────────────────────────────────────────────────────────────
  // COLOR SYSTEM - Already defined in AppTheme but referenced here
  // ─────────────────────────────────────────────────────────────────────────
  
  // Primary
  static const Color colorPrimary = Color(0xFFF5A623);        // hosiPeach
  static const Color colorPrimaryLight = Color(0xFFFEC894);   // Lighter peach
  static const Color colorPrimaryDark = Color(0xFFE5951B);    // Darker peach
  
  // Secondary
  static const Color colorSecondary = Color(0xFF8C4928);      // hosiBrown
  static const Color colorSecondaryLight = Color(0xFFA8614C); // Lighter brown
  static const Color colorSecondaryDark = Color(0xFF6B3520);  // Darker brown
  
  // Success
  static const Color colorSuccess = Color(0xFF4CAF50);        // Green
  static const Color colorSuccessLight = Color(0xFF81C784);   // Light green
  static const Color colorSuccessDark = Color(0xFF2E7D32);    // Dark green
  
  // Warning
  static const Color colorWarning = Color(0xFFFFA726);        // Orange
  static const Color colorWarningLight = Color(0xFFFFB74D);   // Light orange
  static const Color colorWarningDark = Color(0xFFF57C00);    // Dark orange
  
  // Error
  static const Color colorError = Color(0xFFD32F2F);          // Red
  static const Color colorErrorLight = Color(0xFFEF5350);     // Light red
  static const Color colorErrorDark = Color(0xFFC62828);      // Dark red
  
  // Info
  static const Color colorInfo = Color(0xFF1976D2);           // Blue
  static const Color colorInfoLight = Color(0xFF42A5F5);      // Light blue
  static const Color colorInfoDark = Color(0xFF1565C0);       // Dark blue
  
  // Neutral / Gray Scale
  static const Color colorSurface = Color(0xFFFAFAFA);        // Lightest
  static const Color colorBackground = Color(0xFFFFFFFF);     // White
  static const Color colorGray50 = Color(0xFFFAFAFA);
  static const Color colorGray100 = Color(0xFFF3F4F6);
  static const Color colorGray200 = Color(0xFFE5E7EB);
  static const Color colorGray300 = Color(0xFFD1D5DB);
  static const Color colorGray400 = Color(0xFF9CA3AF);
  static const Color colorGray500 = Color(0xFF6B7280);
  static const Color colorGray600 = Color(0xFF4B5563);
  static const Color colorGray700 = Color(0xFF374151);
  static const Color colorGray800 = Color(0xFF1F2937);
  static const Color colorGray900 = Color(0xFF111827);
  
  // ─────────────────────────────────────────────────────────────────────────
  // SHORTCUTS FOR COMMON PATTERNS
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get symmetric horizontal padding
  static EdgeInsets paddingHorizontal(double value) => EdgeInsets.symmetric(horizontal: value);
  
  /// Get symmetric vertical padding
  static EdgeInsets paddingVertical(double value) => EdgeInsets.symmetric(vertical: value);
  
  /// Get padding only on specific sides
  static EdgeInsets paddingOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) => EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
}
