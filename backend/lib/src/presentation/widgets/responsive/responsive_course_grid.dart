import 'package:flutter/material.dart';
import '../adaptive/screen_size.dart';

class ResponsiveCourseGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const ResponsiveCourseGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    int crossAxisCount;
    double childAspectRatio;

    if (width >= ScreenSize.desktop) {
      crossAxisCount = 4;
      childAspectRatio = 1.1;
    } else if (width >= ScreenSize.tablet) {
      crossAxisCount = 3;
      childAspectRatio = 1.05;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.95;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
