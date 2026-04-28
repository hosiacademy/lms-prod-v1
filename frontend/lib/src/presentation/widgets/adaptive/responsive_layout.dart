import 'package:flutter/material.dart';
import 'screen_size.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= ScreenSize.desktop) {
      return desktop;
    } else if (width >= ScreenSize.tablet && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}