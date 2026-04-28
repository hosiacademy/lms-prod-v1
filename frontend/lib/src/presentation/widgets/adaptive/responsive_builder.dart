import 'package:flutter/material.dart';
import 'screen_size.dart';

typedef ResponsiveWidgetBuilder = Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop);

class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = ScreenSize.isMobile(width);
    final isTablet = ScreenSize.isTablet(width);
    final isDesktop = ScreenSize.isDesktop(width);

    return builder(context, isMobile, isTablet, isDesktop);
  }
}