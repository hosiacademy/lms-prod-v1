// lib/src/presentation/widgets/panels/cart_panel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../data/models/course.dart';
import '../../../data/models/learnership.dart';
import '../modals/aicerts/multi_step_aicerts_custom_selection_modal.dart';

/// Course Cart Panel — Displays items added to cart.
/// Opened as a side drawer from the student portal header.
class CartPanel extends StatefulWidget {
  const CartPanel({super.key});

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  // ── Subscriptions / listeners ──────────────────────────────────────────────
  StreamSubscription<void>? _cartSub;

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _isCheckoutLoading = false;
  final Set<String> _removingItemIds = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Re-render whenever the cart changes (items added / removed / fetched)
    _cartSub = cartService.cartUpdatedStream.listen((_) {
      if (mounted) setState(() {});
    });
    // Re-render whenever the detected currency changes
    CurrencyService.instance.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    CurrencyService.instance.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Format a course price through CurrencyService.
  /// Uses backend-provided localPrice when available, otherwise converts the
  /// USD price.
  String _formatCoursePrice(Course course) {
    if (course.localPrice != null) {
      final price = double.tryParse(
            course.localPrice!.replaceAll(RegExp(r'[^\d.]'), ''),
          ) ??
          0.0;
      return CurrencyService.instance
          .formatPrice(price, currencyCode: course.localCurrency);
    }
    return CurrencyService.instance.formatUSDAmount(course.price ?? 0.0);
  }

  /// Compute the cart total using CartService which handles localization.
  double _calculateLocalTotal() {
    return cartService.calculateTotal();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final courses = cartService.courses;
    final learnerships = cartService.learnerships;
    final masterclasses = cartService.masterclasses;
    final industryTraining = cartService.industryTraining;
    final totalItems = cartService.itemCount;

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
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary,
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
                Icon(Icons.shopping_cart, color: colors.onPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Course Cart',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (totalItems > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalItems',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Cart Items ───────────────────────────────────────────────────────
          Expanded(
            child: totalItems == 0
                ? _buildEmptyState(theme, colors)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (courses.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Courses', courses.length, theme),
                        ...courses.map((c) =>
                            _buildCourseItem(c, theme, colors)),
                        const SizedBox(height: 16),
                      ],
                      if (learnerships.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Learnerships', learnerships.length, theme),
                        ...learnerships.map((l) =>
                            _buildLearnershipItem(l, theme, colors)),
                        const SizedBox(height: 16),
                      ],
                      if (masterclasses.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Masterclasses', masterclasses.length, theme),
                        ...masterclasses.entries.map((e) =>
                            _buildMasterclassItem(
                                e.key, e.value, theme, colors)),
                        const SizedBox(height: 16),
                      ],
                      if (industryTraining.isNotEmpty) ...[
                        _buildSectionHeader('Industry Training',
                            industryTraining.length, theme),
                        ...industryTraining.entries.map((e) =>
                            _buildIndustryTrainingItem(
                                e.key, e.value, theme, colors)),
                      ],
                    ],
                  ),
          ),

          // ── Footer ───────────────────────────────────────────────────────────
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
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyService.instance.formatPrice(
                          _calculateLocalTotal(),
                          currencyCode: cartService.getCurrency(),
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Checkout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isCheckoutLoading ? null : _proceedToCheckout,
                      icon: _isCheckoutLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.shopping_cart_checkout),
                      label: Text(_isCheckoutLoading
                          ? 'Processing…'
                          : 'Enroll Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor:
                            AppTheme.successGreen.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Clear cart
                  TextButton.icon(
                    onPressed: _isCheckoutLoading ? null : _confirmClear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear Cart'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Item builders ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: colors.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse courses and add them to your cart',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
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

  Widget _buildCourseItem(
      Course course, ThemeData theme, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _itemThumbnail(
            course.featureImageUrl, Icons.school, colors),
        title: Text(
          course.displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatCoursePrice(course),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.successGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Move to Wishlist',
              onPressed: () async {
                if (await wishlistService.addCourse(course)) {
                  _showSnack('${course.title} added to wishlist');
                }
              },
            ),
            _removingItemIds.contains(course.id)
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove',
                    onPressed: () async {
                      setState(() => _removingItemIds.add(course.id));
                      final success = await cartService.removeCourse(course.id);
                      if (mounted) {
                        setState(() => _removingItemIds.remove(course.id));
                        if (!success) {
                          _showSnack('Failed to remove item. Please try again.');
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnershipItem(
      Learnership learnership, ThemeData theme, ColorScheme colors) {
    final priceStr = CurrencyService.instance
        .formatUSDAmount(learnership.priceUsd ?? learnership.price ?? 0.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _itemThumbnail(null, Icons.card_membership, colors),
        title: Text(
          learnership.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          priceStr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.successGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Move to Wishlist',
              onPressed: () async {
                if (await wishlistService.addLearnership(learnership)) {
                  _showSnack('${learnership.title} added to wishlist');
                }
              },
            ),
            _removingItemIds.contains('learnership_${learnership.id}')
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove',
                    onPressed: () async {
                      final itemIdStr = 'learnership_${learnership.id}';
                      setState(() => _removingItemIds.add(itemIdStr));
                      final success = await cartService.removeLearnership(learnership.id);
                      if (mounted) {
                        setState(() => _removingItemIds.remove(itemIdStr));
                        if (!success) {
                          _showSnack('Failed to remove item. Please try again.');
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterclassItem(String id, Map<String, dynamic> data,
      ThemeData theme, ColorScheme colors) {
    final priceStr = CurrencyService.instance.formatUSDAmount(
      (data['price'] as num?)?.toDouble() ?? 0.0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _itemThumbnail(null, Icons.star, colors),
        title: Text(
          data['title'] as String? ?? 'Masterclass',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          priceStr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.successGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Move to Wishlist',
              onPressed: () async {
                if (await wishlistService.addMasterclass(id, data)) {
                  _showSnack('${data['title']} added to wishlist');
                }
              },
            ),
            _removingItemIds.contains('masterclass_$id')
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove',
                    onPressed: () async {
                      final itemIdStr = 'masterclass_$id';
                      setState(() => _removingItemIds.add(itemIdStr));
                      final success = await cartService.removeMasterclass(id);
                      if (mounted) {
                        setState(() => _removingItemIds.remove(itemIdStr));
                        if (!success) {
                          _showSnack('Failed to remove item. Please try again.');
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndustryTrainingItem(String id, Map<String, dynamic> data,
      ThemeData theme, ColorScheme colors) {
    final priceStr = CurrencyService.instance.formatUSDAmount(
      (data['price'] as num?)?.toDouble() ?? 0.0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _itemThumbnail(null, Icons.business, colors),
        title: Text(
          data['title'] as String? ?? 'Industry Training',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          priceStr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.successGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Move to Wishlist',
              onPressed: () async {
                if (await wishlistService.addIndustryTraining(id, data)) {
                  _showSnack('${data['title']} added to wishlist');
                }
              },
            ),
            _removingItemIds.contains('industry_$id')
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove',
                    onPressed: () async {
                      final itemIdStr = 'industry_$id';
                      setState(() => _removingItemIds.add(itemIdStr));
                      final success = await cartService.removeIndustryTraining(id);
                      if (mounted) {
                        setState(() => _removingItemIds.remove(itemIdStr));
                        if (!success) {
                          _showSnack('Failed to remove item. Please try again.');
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  /// Generic 50×50 thumbnail with an icon fallback.
  Widget _itemThumbnail(
      String? imageUrl, IconData fallback, ColorScheme colors) {
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _iconBox(fallback, colors),
        ),
      );
    }
    return _iconBox(fallback, colors);
  }

  Widget _iconBox(IconData icon, ColorScheme colors) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: colors.primary),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await cartService.clearCart();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToCheckout() async {
    if (cartService.itemCount == 0 || _isCheckoutLoading) return;

    setState(() => _isCheckoutLoading = true);
    bool dialogOpen = false;

    try {
      // Show loading overlay
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              const Center(child: CircularProgressIndicator()),
        );
        dialogOpen = true;
      }

      final existingStudentData =
          await ApiClient.checkExistingStudent();
      final isExistingStudent =
          existingStudentData['is_existing_student'] as bool? ?? false;

      // Close loading overlay
      if (mounted && dialogOpen) {
        Navigator.pop(context);
        dialogOpen = false;
      }

      // Collect all cart items as Course objects for EnhancedEnrollmentPanel
      final List<Course> courses = [];

      courses.addAll(cartService.courses);

      courses.addAll(cartService.learnerships.map((l) => Course(
            id: l.id.toString(),
            title: l.title,
            price: l.priceUsd ?? l.price,
            courseType: 'learnership',
            featureImageUrl: l.imageUrl,
          )));

      cartService.masterclasses.forEach((id, data) {
        courses.add(Course(
          id: id,
          title: data['title'] as String? ?? 'Masterclass',
          price: (data['price'] as num?)?.toDouble(),
          courseType: 'masterclass',
          featureImageUrl: data['imageUrl'] as String?,
        ));
      });

      cartService.industryTraining.forEach((id, data) {
        courses.add(Course(
          id: id,
          title: data['title'] as String? ?? 'Industry Training',
          price: (data['price'] as num?)?.toDouble(),
          courseType: 'industry_training',
          featureImageUrl: data['imageUrl'] as String?,
        ));
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MultiStepAICERTSCustomSelectionModal(
          courses: courses,
          onEnrollmentComplete: () {
            cartService.clearCart();
            if (mounted) setState(() {});
          },
          allowPrefill: true,
        ),
      );
    } catch (e) {
      if (mounted && dialogOpen) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckoutLoading = false);
    }
  }
}
