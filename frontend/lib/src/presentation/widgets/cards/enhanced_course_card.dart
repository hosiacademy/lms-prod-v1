import 'package:flutter/material.dart';
import '../../../data/models/course.dart';
import '../aicerts/aicerts_image_widget.dart';

/// Enhanced course card with ratings, wishlist, and cart functionality
class EnhancedCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final VoidCallback onWishlist;
  final VoidCallback onAddToCart;

  const EnhancedCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.onWishlist,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Wishlist Button and Price Badge
            Stack(
              children: [
                AICERTSImageWidget(
                  imageUrl: course.featureImageUrl,
                  imageType: AICERTSImageType.course,
                  fit: BoxFit.cover,
                  height: (MediaQuery.of(context).size.width * 9 / 16).clamp(150, 200),
                  borderRadius: BorderRadius.zero,
                ),

                // Wishlist Button (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: onWishlist,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          course.isWishlisted
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: course.isWishlisted
                              ? colors.primary
                              : colors.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                // Price Badge (Bottom Left)
                if (course.price != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '\$${course.price!.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      course.displayTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Instructor (if available)
                    if (course.instructorName != null)
                      Text(
                        course.instructorName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Rating and Student Count
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          course.rating?.toStringAsFixed(1) ?? 'N/A',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_formatCount(course.studentCount ?? 0)})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      child: course.isInCart
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('In Cart'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: onAddToCart,
                              icon:
                                  const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('Add to Cart'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
