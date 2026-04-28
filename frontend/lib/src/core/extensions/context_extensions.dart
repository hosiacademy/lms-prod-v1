// lib/src/core/extensions/context_extensions.dart

import 'package:flutter/material.dart';

extension BuildContextResponsive on BuildContext {
  // ──────────────────────────────────────────────────────────────
  // Existing responsive helpers (your original code)
  // ──────────────────────────────────────────────────────────────
  bool get isMobile => MediaQuery.of(this).size.width < 600;

  bool get isTablet =>
      MediaQuery.of(this).size.width >= 600 &&
      MediaQuery.of(this).size.width < 1200;

  bool get isDesktop => MediaQuery.of(this).size.width >= 1200;

  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  // ──────────────────────────────────────────────────────────────
  // NEW: WordPress-style responsive spacing values
  // (inspired by common design systems: 4–64px scale)
  // ──────────────────────────────────────────────────────────────
  double wpSpacingValue(String size) {
    final scale = isMobile
        ? 0.9
        : isDesktop
            ? 1.2
            : 1.0;

    final baseValues = {
      'xs': 4.0,
      'sm': 8.0,
      'md': 16.0,
      'lg': 24.0,
      'xl': 32.0,
      '2xl': 48.0,
      '3xl': 64.0,
    };

    final base = baseValues[size.toLowerCase()] ?? 16.0;
    return base * scale;
  }

  // Shorter alias (optional, more convenient)
  double spacing(String size) => wpSpacingValue(size);

  // ──────────────────────────────────────────────────────────────
  // NEW: Responsive border radius
  // (smaller on mobile, slightly larger on desktop)
  // ──────────────────────────────────────────────────────────────
  BorderRadius get wpBorderRadius {
    final radius = isMobile
        ? 12.0
        : isDesktop
            ? 16.0
            : 14.0;
    return BorderRadius.circular(radius);
  }

  // Quick access to theme parts (very useful shortcuts)
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
