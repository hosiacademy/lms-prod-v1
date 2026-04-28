// lib/src/presentation/widgets/panels/wishlist_panel.dart

import 'package:flutter/material.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/course.dart';
import '../../../data/models/learnership.dart';

/// Wishlist Panel - Displays items added to wishlist
/// Accessible from Student Portal header
class WishlistPanel extends StatefulWidget {
  const WishlistPanel({super.key});

  @override
  State<WishlistPanel> createState() => _WishlistPanelState();
}

class _WishlistPanelState extends State<WishlistPanel> {
  @override
  void initState() {
    super.initState();
    // Listen to wishlist updates
    wishlistService.wishlistUpdatedStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final courses = wishlistService.courses;
    final learnerships = wishlistService.learnerships;
    final masterclasses = wishlistService.masterclasses;
    final industryTraining = wishlistService.industryTraining;

    final totalItems = wishlistService.itemCount;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF79150), // Gold/Orange for wishlist
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'My Wishlist',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (totalItems > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalItems',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFF79150),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Wishlist Items
          Expanded(
            child: totalItems == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 80,
                          color: colors.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your wishlist is empty',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Save courses you\'re interested in for later',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Courses
                      if (courses.isNotEmpty) ...[
                        _buildSectionHeader('Courses', courses.length, theme),
                        ...courses.map((course) => _buildCourseItem(
                              course,
                              theme,
                              colors,
                            )),
                        const SizedBox(height: 16),
                      ],

                      // Learnerships
                      if (learnerships.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Learnerships', learnerships.length, theme),
                        ...learnerships
                            .map((learnership) => _buildLearnershipItem(
                                  learnership,
                                  theme,
                                  colors,
                                )),
                        const SizedBox(height: 16),
                      ],

                      // Masterclasses
                      if (masterclasses.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Masterclasses', masterclasses.length, theme),
                        ...masterclasses.entries
                            .map((entry) => _buildMasterclassItem(
                                  entry.key,
                                  entry.value,
                                  theme,
                                  colors,
                                )),
                        const SizedBox(height: 16),
                      ],

                      // Industry Training
                      if (industryTraining.isNotEmpty) ...[
                        _buildSectionHeader('Industry Training',
                            industryTraining.length, theme),
                        ...industryTraining.entries
                            .map((entry) => _buildIndustryTrainingItem(
                                  entry.key,
                                  entry.value,
                                  theme,
                                  colors,
                                )),
                      ],
                    ],
                  ),
          ),

          // Footer with actions
          if (totalItems > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _moveAllToCart(context);
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Move All to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Wishlist'),
                          content: const Text(
                              'Are you sure you want to remove all items from your wishlist?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await wishlistService.clearWishlist();
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear Wishlist'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$title ($count)',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.hosiMidnight,
        ),
      ),
    );
  }

  Widget _buildCourseItem(Course course, ThemeData theme, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: course.featureImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  course.featureImageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: colors.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.school, color: colors.primary),
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.school, color: colors.primary),
              ),
        title: Text(
          course.displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          course.localPrice != null
              ? '${course.localCurrency ?? "USD"} ${course.localPrice}'
              : 'USD ${course.price ?? 0}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFF79150),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () async {
                if (await cartService.addCourse(course)) {
                  await wishlistService.removeCourse(course.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${course.title} moved to cart'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              tooltip: 'Move to Cart',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await wishlistService.removeCourse(course.id);
              },
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnershipItem(
      Learnership learnership, ThemeData theme, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.card_membership, color: colors.primary),
        ),
        title: Text(
          learnership.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${learnership.currency ?? "USD"} ${learnership.price ?? 0}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFF79150),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () async {
                if (await cartService.addLearnership(learnership)) {
                  await wishlistService.removeLearnership(learnership.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${learnership.title} moved to cart'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              tooltip: 'Move to Cart',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await wishlistService.removeLearnership(learnership.id);
              },
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterclassItem(String id, Map<String, dynamic> data,
      ThemeData theme, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.star, color: colors.primary),
        ),
        title: Text(
          data['title'] ?? 'Masterclass',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'USD ${data['price'] ?? 0}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFF79150),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () async {
                if (await cartService.addMasterclass(id, data)) {
                  await wishlistService.removeMasterclass(id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${data['title']} moved to cart'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              tooltip: 'Move to Cart',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await wishlistService.removeMasterclass(id);
              },
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndustryTrainingItem(String id, Map<String, dynamic> data,
      ThemeData theme, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.business, color: colors.primary),
        ),
        title: Text(
          data['title'] ?? 'Industry Training',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'USD ${data['price'] ?? 0}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFF79150),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () async {
                if (await cartService.addIndustryTraining(id, data)) {
                  await wishlistService.removeIndustryTraining(id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${data['title']} moved to cart'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              tooltip: 'Move to Cart',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await wishlistService.removeIndustryTraining(id);
              },
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveAllToCart(BuildContext context) async {
    // Show loading? or just do it.

    int movedCount = 0;

    // Copy lists to avoid modification during iteration issues if checking live lists
    // using wishlistService.courses creates a new list from Unmodifiable but better be safe
    final courses = List<Course>.from(wishlistService.courses);
    for (var course in courses) {
      if (await cartService.addCourse(course)) {
        movedCount++;
      }
    }

    final learnerships = List<Learnership>.from(wishlistService.learnerships);
    for (var learnership in learnerships) {
      if (await cartService.addLearnership(learnership)) {
        movedCount++;
      }
    }

    final masterclasses =
        Map<String, dynamic>.from(wishlistService.masterclasses);
    for (var entry in masterclasses.entries) {
      if (await cartService.addMasterclass(entry.key, entry.value)) {
        movedCount++;
      }
    }

    final industryTraining =
        Map<String, dynamic>.from(wishlistService.industryTraining);
    for (var entry in industryTraining.entries) {
      if (await cartService.addIndustryTraining(entry.key, entry.value)) {
        movedCount++;
      }
    }

    // Clear wishlist after moving (or just those moved, but here we assume all)
    await wishlistService.clearWishlist();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$movedCount items moved to cart'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
