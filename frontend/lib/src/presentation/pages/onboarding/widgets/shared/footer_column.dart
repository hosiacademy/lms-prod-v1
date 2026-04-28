// lib/src/presentation/pages/onboarding/widgets/shared/footer_column.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ? REQUIRED

class FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  final void Function(int index, String item)? onItemTap;

  const FooterColumn({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // High-contrast background that adapts to theme
    final bgColor = colorScheme.surface.withValues(alpha: 0.85);
    final textColor = colorScheme.onSurface;
    final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.85);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          /// ITEMS
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Animate(
              effects: [
                FadeEffect(
                  delay: (index * 60).ms,
                  duration: 400.ms,
                ),
                SlideEffect(
                  begin: const Offset(-0.1, 0),
                  end: Offset.zero,
                  delay: (index * 60).ms,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
              ],
              child: InkWell(
                onTap: onItemTap != null ? () => onItemTap!(index, item) : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
