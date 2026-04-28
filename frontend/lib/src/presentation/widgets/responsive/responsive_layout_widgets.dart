/// Responsive Layout Widgets for Flutter Web LMS
/// 
/// Provides reusable widgets for implementing responsive layouts across
/// mobile, tablet, and desktop with proper responsive behavior.
/// 
/// **Available Widgets:**
/// - ResponsiveRow: Responsive flex row with adaptive columns
/// - ResponsiveGrid: Responsive grid layout
/// - ResponsiveScaffold: Page layout with responsive spacing
/// - ResponsiveContainer: Container with max width and responsive padding
/// - ResponsiveAppBar: AppBar with responsive sizing
/// - ResponsiveBottomSheet: Bottom sheet with responsive sizing

import 'package:flutter/material.dart';
import 'package:frontend/src/core/utils/responsive_helper.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RESPONSIVE CONTAINER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Container with max width and responsive padding
/// Useful for centering content on large screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool useMaxWidth;
  final Color? backgroundColor;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.useMaxWidth = true,
    this.backgroundColor,
    this.alignment = Alignment.topCenter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final containerMaxWidth = maxWidth ?? ResponsiveHelper.maxContainerWidth(context);
    final containerPadding = padding ?? ResponsiveHelper.paddingAll(context);

    return Container(
      alignment: alignment,
      color: backgroundColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: useMaxWidth ? containerMaxWidth : double.infinity),
        child: Padding(
          padding: containerPadding,
          child: child,
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RESPONSIVE GRID
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Responsive GridView with adaptive column count
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final IndexedWidgetBuilder? itemBuilder;
  final int? itemCount;

  const ResponsiveGrid({
    Key? key,
    this.children = const [],
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.padding,
    this.shrinkWrap = true,
    this.physics,
    this.itemBuilder,
    this.itemCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columns = _getColumnCount(context);
    final mainSpacing = mainAxisSpacing ?? ResponsiveHelper.gridMainAxisSpacing(context);
    final crossSpacing = crossAxisSpacing ?? ResponsiveHelper.gridCrossAxisSpacing(context);
    final containerPadding = padding ?? ResponsiveHelper.paddingAll(context);

    if (itemBuilder != null && itemCount != null) {
      return Padding(
        padding: containerPadding,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: mainSpacing,
            crossAxisSpacing: crossSpacing,
            childAspectRatio: 1.0,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder!,
          shrinkWrap: shrinkWrap,
          physics: physics ?? const NeverScrollableScrollPhysics(),
        ),
      );
    }

    return Padding(
      padding: containerPadding,
      child: GridView.count(
        crossAxisCount: columns,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        children: children,
        shrinkWrap: shrinkWrap,
        physics: physics ?? const NeverScrollableScrollPhysics(),
      ),
    );
  }

  int _getColumnCount(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) return mobileColumns ?? 1;
    if (ResponsiveHelper.isTablet(context)) return tabletColumns ?? 2;
    return desktopColumns ?? 3;
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RESPONSIVE ROW / COLUMN WRAPPER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Responsive Row: Switches to Column on mobile
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? gap;
  final bool? wrapOnMobile;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.gap,
    this.wrapOnMobile = true,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spacing = gap ?? ResponsiveHelper.gap(context);
    
    // On mobile, switch to column layout
    if (ResponsiveHelper.isMobile(context) && (wrapOnMobile ?? true)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        children: _addSpacing(context, children, spacing),
      );
    }

    // On tablet/desktop, use row layout
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      children: _addSpacing(context, children, spacing),
    );
  }

  List<Widget> _addSpacing(BuildContext context, List<Widget> widgets, double spacing) {
    if (widgets.isEmpty) return widgets;
    
    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(SizedBox(
          width: ResponsiveHelper.isMobile(context) ? 0 : spacing,
          height: ResponsiveHelper.isMobile(context) ? spacing : 0,
        ));
      }
    }
    return result;
  }

  // Note: isMobile is not available here, will need to add context checking in actual widget
}

/// Responsive Row with flexible children
class ResponsiveFlexRow extends StatelessWidget {
  final List<({Widget child, int flex})> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? gap;

  const ResponsiveFlexRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.gap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spacing = gap ?? ResponsiveHelper.gap(context);
    
    // On mobile, switch to column layout
    if (ResponsiveHelper.isMobile(context)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children.expand((item) {
          final index = children.indexOf(item);
          final widgets = <Widget>[item.child];
          if (index < children.length - 1) {
            widgets.add(SizedBox(height: spacing));
          }
          return widgets;
        }).toList(),
      );
    }

    // On tablet/desktop, use row layout with flex
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.expand((item) {
        final index = children.indexOf(item);
        final widgets = <Widget>[
          Flexible(
            flex: item.flex,
            child: item.child,
          ),
        ];
        if (index < children.length - 1) {
          widgets.add(SizedBox(width: spacing));
        }
        return widgets;
      }).toList(),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RESPONSIVE SCAFFOLD
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Page layout with responsive spacing and optional sidebar
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? sidebar;
  final Widget? floatingActionButton;
  final bool showSidebar;
  final double? bodyMaxWidth;

  const ResponsiveScaffold({
    Key? key,
    this.appBar,
    required this.body,
    this.sidebar,
    this.floatingActionButton,
    this.showSidebar = true,
    this.bodyMaxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On mobile, hide sidebar
    if (ResponsiveHelper.isMobile(context) || !showSidebar) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }

    // On tablet/desktop, show sidebar
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          if (sidebar != null) ...[
            SizedBox(
              width: ResponsiveHelper.sidebarWidth(context),
              child: sidebar,
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RESPONSIVE SIZED BOX
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// SizedBox with responsive dimensions
class ResponsiveSizedBox extends StatelessWidget {
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final Widget? child;

  const ResponsiveSizedBox({
    Key? key,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late double height;
    late double width;

    if (ResponsiveHelper.isMobile(context)) {
      height = mobileHeight ?? 0;
      width = mobileWidth ?? 0;
    } else if (ResponsiveHelper.isTablet(context)) {
      height = tabletHeight ?? mobileHeight ?? 0;
      width = tabletWidth ?? mobileWidth ?? 0;
    } else {
      height = desktopHeight ?? tabletHeight ?? mobileHeight ?? 0;
      width = desktopWidth ?? tabletWidth ?? mobileWidth ?? 0;
    }

    return SizedBox(
      height: height,
      width: width,
      child: child,
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RESPONSIVE PADDING
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Padding that responds to screen size
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    Key? key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late EdgeInsets padding;

    if (ResponsiveHelper.isMobile(context)) {
      padding = mobilePadding ?? ResponsiveHelper.paddingAll(context);
    } else if (ResponsiveHelper.isTablet(context)) {
      padding = tabletPadding ?? ResponsiveHelper.paddingAll(context);
    } else {
      padding = desktopPadding ?? ResponsiveHelper.paddingAll(context);
    }

    return Padding(padding: padding, child: child);
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RESPONSIVE SPACER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Spacer that adapts to screen size
class ResponsiveSpacer extends StatelessWidget {
  final SpacingSize size;
  final bool vertical;

  const ResponsiveSpacer({
    Key? key,
    this.size = SpacingSize.medium,
    this.vertical = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double spacing = 0;

    switch (size) {
      case SpacingSize.small:
        spacing = ResponsiveHelper.spacingSmall(context);
        break;
      case SpacingSize.medium:
        spacing = ResponsiveHelper.spacingMedium(context);
        break;
      case SpacingSize.large:
        spacing = ResponsiveHelper.spacingLarge(context);
        break;
      case SpacingSize.extraLarge:
        spacing = ResponsiveHelper.spacingXL(context);
        break;
    }

    if (vertical) {
      return SizedBox(height: spacing);
    } else {
      return SizedBox(width: spacing);
    }
  }
}

enum SpacingSize { small, medium, large, extraLarge }

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RESPONSIVE BUILDER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Builder that rebuilds based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  const ResponsiveBuilder({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return mobile(context);
    } else if (ResponsiveHelper.isTablet(context)) {
      return (tablet ?? mobile)(context);
    } else {
      return (desktop ?? tablet ?? mobile)(context);
    }
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// RESPONSIVE TEXT
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Text with responsive font size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final double? baseFontSize;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.baseStyle,
    this.baseFontSize,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSize = baseFontSize ?? (baseStyle?.fontSize ?? 16);
    final responsiveFontSize = ResponsiveHelper.fontSize(context, fontSize);

    return Text(
      text,
      style: (baseStyle ?? const TextStyle()).copyWith(fontSize: responsiveFontSize),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}

