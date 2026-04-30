import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_theme.dart';

class LearningPathwaysCompact extends StatelessWidget {
  final Function(String route) onPathSelected;

  const LearningPathwaysCompact({
    super.key,
    required this.onPathSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use AppTheme colors
    final hosiBrown = AppTheme.hosiBrown;
    final successGreen = AppTheme.successGreen;
    final hosiPeach = AppTheme.hosiPeach;
    
    // Determine if mobile and calculate appropriate sizing
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    
    // Adjust sizing based on screen width
    final double cardMinWidth;
    final double imageSize;
    final double fontSize;
    final int columns;
    
    if (isSmallMobile) {
      // Very small screens: single column, full width cards
      cardMinWidth = screenWidth - 32; // Account for padding
      imageSize = 60;
      fontSize = 12;
      columns = 1;
    } else if (isMobile) {
      // Small mobile: 2 columns
      cardMinWidth = (screenWidth - 48) / 2; // Account for padding and spacing
      imageSize = 70;
      fontSize = 12;
      columns = 2;
    } else {
      // Tablet/Desktop: larger cards
      cardMinWidth = 180;
      imageSize = 80;
      fontSize = 13;
      columns = 5;
    }

    final pathways = [
      _Pathway(
        title: 'Corporate Training',
        icon: Icons.business_rounded,
        color: hosiBrown,
        route: '/enroll/corporate',
        svgAsset: 'assets/images/pathways/corporate_training.svg',
        showImage: true,
      ),
      _Pathway(
        title: 'AI & Blockchain Learnerships',
        icon: Icons.school_rounded,
        color: successGreen,
        route: '/enroll/learnerships',
        showImage: false,
      ),
      _Pathway(
        title: 'Cybersecurity Learnerships',
        icon: Icons.security_rounded,
        color: hosiPeach,
        route: '/enroll/cybersecurity',
        showImage: false,
      ),
      _Pathway(
        title: 'Industry & Role Based Training',
        icon: Icons.engineering_rounded,
        color: hosiBrown,
        route: '/enroll/industry',
        svgAsset: 'assets/images/pathways/industry_training.svg',
        showImage: true,
      ),
      _Pathway(
        title: 'Custom Selection',
        icon: Icons.dashboard_customize_rounded,
        color: hosiPeach,
        route: '/enroll/custom',
        svgAsset: 'assets/images/pathways/custom_selection.svg',
        showImage: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isNarrow = availableWidth < 600;
        final isVeryNarrow = availableWidth < 400;
        
        // Calculate dynamic spacing based on screen size
        final spacing = isVeryNarrow ? 12.0 : (isNarrow ? 14.0 : 16.0);
        final runSpacing = isVeryNarrow ? 12.0 : (isNarrow ? 14.0 : 16.0);
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: pathways
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final pathway = entry.value;
                
                // Calculate actual card width based on screen size
                final cardWidth = isVeryNarrow
                    ? availableWidth - 32
                    : isNarrow
                        ? (availableWidth - spacing * 2) / 2
                        : null; // Let card size itself on larger screens
                
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: 'Click to navigate to ${pathway.title}',
                    child: GestureDetector(
                      onTap: () => onPathSelected(pathway.route),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: BoxConstraints(
                          minWidth: cardMinWidth,
                          maxWidth: cardWidth ?? cardMinWidth,
                          minHeight: isVeryNarrow ? 80 : (isMobile ? 100 : 120),
                        ),
                        padding: EdgeInsets.all(isVeryNarrow ? 10 : 12),
                        decoration: BoxDecoration(
                          color: pathway.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: pathway.color.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: pathway.color.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // SVG Image or Icon
                            if (pathway.showImage && pathway.svgAsset != null) ...[
                              SizedBox(
                                width: isVeryNarrow ? 60 : imageSize,
                                height: isVeryNarrow ? 60 : imageSize,
                                child: SvgPicture.asset(
                                  pathway.svgAsset!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: isVeryNarrow ? 6 : 8),
                            ] else ...[
                              Container(
                                padding: EdgeInsets.all(isVeryNarrow ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: pathway.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  pathway.icon,
                                  color: pathway.color,
                                  size: isVeryNarrow ? 24 : 28,
                                ),
                              ),
                              SizedBox(height: isVeryNarrow ? 6 : 8),
                            ],
                            // Title - with responsive font size
                            Text(
                              pathway.title,
                              style: TextStyle(
                                fontSize: isVeryNarrow ? 11 : fontSize,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate(
                  delay: Duration(milliseconds: index * 40)
                ).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms);
              })
              .toList(),
        );
      },
    );
  }
}

class _Pathway {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final String? svgAsset;
  final bool showImage;

  const _Pathway({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    this.svgAsset,
    this.showImage = false,
  });
}
