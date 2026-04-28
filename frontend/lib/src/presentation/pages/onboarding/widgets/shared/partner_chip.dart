// C:\Users\HosiTech\lms-monorepo\frontend\lib\src\presentation\pages\onboarding\widgets\shared\partner_chip.dart
import 'package:flutter/material.dart';

class PartnerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool isOutlined;
  final double? width; // Optional custom width
  final bool expandToFit; // Whether to expand to fill available width

  const PartnerChip({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.isOutlined = false,
    this.width,
    this.expandToFit = false, // Default to not expanding
  });

  // Constructor for full-width chip (98% of page width)
  const PartnerChip.fullWidth({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.isOutlined = false,
  })  : width = null,
        expandToFit = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Fixed: Always use transparent background and white text for contrast
    final bgColor = backgroundColor ?? Colors.transparent;

    // Fixed: Use white text for maximum contrast
    final txtColor = textColor ?? Colors.white;

    // Fixed: Use white icon color for contrast
    final icnColor = iconColor ?? Colors.white;

    // Main container widget
    Widget chipContent = Container(
      decoration: BoxDecoration(
        color: bgColor, // Always transparent
        borderRadius: BorderRadius.circular(20),
        border: isOutlined
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5, // White border for contrast
              )
            : null,
        boxShadow: isOutlined
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: icnColor, // White icon
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: txtColor, // White text
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );

    // Handle width constraints
    if (expandToFit) {
      // Option 1: Use FractionallySizedBox for percentage width
      return FractionallySizedBox(
        widthFactor: 0.98, // 98% of parent width
        child: chipContent,
      );
    } else if (width != null) {
      // Option 2: Fixed width
      return SizedBox(
        width: width,
        child: chipContent,
      );
    } else {
      // Option 3: Wrap with ConstrainedBox for minimum width
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 100, // Minimum width for chips
        ),
        child: chipContent,
      );
    }
  }
}

// VERSION 2: USING CONTAINER WITH WIDTH FROM CONTEXT
class PartnerChipFullWidth extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool isOutlined;

  const PartnerChipFullWidth({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Fixed: Always use transparent background and white text for contrast
    final bgColor = backgroundColor ?? Colors.transparent;

    // Fixed: Use white text for maximum contrast
    final txtColor = textColor ?? Colors.white;

    // Fixed: Use white icon color for contrast
    final icnColor = iconColor ?? Colors.white;

    return Container(
      width: mediaQuery.size.width * 0.98, // 98% of screen width
      decoration: BoxDecoration(
        color: bgColor, // Always transparent
        borderRadius: BorderRadius.circular(20),
        border: isOutlined
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5, // White border for contrast
              )
            : null,
        boxShadow: isOutlined
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center content
          children: [
            Icon(
              icon,
              color: icnColor, // White icon
              size: 20, // Slightly larger for full width
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: txtColor, // White text
                  fontWeight: FontWeight.w600,
                  fontSize: 14, // Slightly larger for full width
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// VERSION 3: USING LAYOUTBUILDER FOR RESPONSIVE 98% WIDTH
class PartnerChipResponsive extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool isOutlined;

  const PartnerChipResponsive({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);

        // Fixed: Always use transparent background and white text for contrast
        final bgColor = backgroundColor ?? Colors.transparent;

        // Fixed: Use white text for maximum contrast
        final txtColor = textColor ?? Colors.white;

        // Fixed: Use white icon color for contrast
        final icnColor = iconColor ?? Colors.white;

        return Container(
          width: constraints.maxWidth * 0.98, // 98% of available width
          decoration: BoxDecoration(
            color: bgColor, // Always transparent
            borderRadius: BorderRadius.circular(20),
            border: isOutlined
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.5, // White border for contrast
                  )
                : null,
            boxShadow: isOutlined
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: icnColor, // White icon
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: txtColor, // White text
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// EXAMPLE USAGE:
/*
// Original chip (default behavior)
PartnerChip(
  label: 'Microsoft',
  icon: Icons.business,
  isOutlined: true,
)

// Full width chip (98% of parent)
PartnerChip.fullWidth(
  label: 'Enterprise Partner',
  icon: Icons.handshake,
  isOutlined: true,
)

// Or using the dedicated full-width widget
PartnerChipFullWidth(
  label: 'Corporate Alliance',
  icon: Icons.corporate_fare,
)

// Or responsive version
PartnerChipResponsive(
  label: 'Strategic Partner',
  icon: Icons.star,
)
*/

// WRAPPER FOR EASY 98% WIDTH USAGE
class FullWidthPartnerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool isOutlined;

  const FullWidthPartnerChip({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500, // Optional: Maximum width constraint
          ),
          width:
              MediaQuery.of(context).size.width * 0.98, // 98% of screen width
          child: PartnerChip(
            label: label,
            icon: icon,
            backgroundColor: backgroundColor,
            textColor: textColor,
            iconColor: iconColor,
            isOutlined: isOutlined,
          ),
        ),
      ),
    );
  }
}
