// lib/src/presentation/widgets/student_portal/course_catalog_card.dart

import 'package:flutter/material.dart';
import '../../../data/models/course_catalog.dart';

/// Course Catalog Card — displays a course item in the catalog grid.
class CourseCatalogCard extends StatelessWidget {
  final CourseCatalogItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToWishlist;
  final VoidCallback? onAddToCart;

  const CourseCatalogCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToWishlist,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                color: colors.primaryContainer.withValues(alpha: 0.3),
                child: item.thumbnailUrl != null
                    ? Image.network(
                        item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.school, size: 40)),
                      )
                    : Center(
                        child: Icon(
                          Icons.school,
                          size: 40,
                          color: colors.primary,
                        ),
                      ),
              ),
            ),

            // Content
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.trainingTypeDisplay,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Price and actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Text(
                          'R ${item.price}',
                          style:
                              theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),

                        // Action buttons
                        Row(
                          children: [
                            if (onAddToWishlist != null)
                              IconButton(
                                icon: Icon(
                                  item.inWishlist
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: item.inWishlist
                                      ? Colors.red
                                      : colors.onSurface,
                                ),
                                onPressed: onAddToWishlist,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            if (onAddToCart != null)
                              IconButton(
                                icon: Icon(
                                  item.inCart
                                      ? Icons.shopping_cart
                                      : Icons.add_shopping_cart,
                                  size: 18,
                                  color: item.inCart
                                      ? colors.primary
                                      : colors.onSurface,
                                ),
                                onPressed: onAddToCart,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                          ],
                        ),
                      ],
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
}
