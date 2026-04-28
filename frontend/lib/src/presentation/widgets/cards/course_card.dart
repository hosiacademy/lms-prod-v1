// lib/src/presentation/widgets/cards/course_card.dart
import 'package:flutter/material.dart';

import '../common/safe_network_image.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String instructor;
  final String thumbnailUrl; // or Asset path
  final double rating;
  final int? enrolledCount; // Made optional
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.title,
    required this.instructor,
    required this.thumbnailUrl,
    required this.rating,
    this.enrolledCount, // Optional
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            // PERFORMANCE FIX: Use CachedNetworkImage instead of Image.network
            AspectRatio(
              aspectRatio: 16 / 9,
              child: SafeNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: colors.surfaceContainerHighest,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by $instructor',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: colors.tertiary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      if (enrolledCount != null && enrolledCount! > 0) ...[
                        const Spacer(),
                        Text(
                          '$enrolledCount enrolled',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
