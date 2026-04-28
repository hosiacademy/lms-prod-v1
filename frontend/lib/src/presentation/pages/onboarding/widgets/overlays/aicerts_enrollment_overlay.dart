import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/services/cart_service.dart';
import '../../../../../core/services/currency_service.dart';
import '../../../../../data/models/course.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../widgets/aicerts/aicerts_image_widget.dart';
import '../../../../widgets/modals/aicerts/aicerts_modals.dart';

/// AICERTS Enrollment Cart Overlay
/// Shows AICERTS courses added to the session cart, per-pathway subtotal,
/// grand total across all pathways, and a Proceed to Enrollment button.
class AICERTSEnrollmentOverlay extends StatefulWidget {
  const AICERTSEnrollmentOverlay({super.key});

  @override
  State<AICERTSEnrollmentOverlay> createState() =>
      _AICERTSEnrollmentOverlayState();
}

class _AICERTSEnrollmentOverlayState extends State<AICERTSEnrollmentOverlay> {
  late final StreamSubscription _cartSub;

  @override
  void initState() {
    super.initState();
    _cartSub = cartService.cartUpdatedStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cartSub.cancel();
    super.dispose();
  }

  void _proceedToEnrollment() {
    Navigator.pop(context);
    AicertsModals.showEnrollmentModal(
      context: context,
      courses: cartService.courses,
      onEnrollmentComplete: () => cartService.clearCart(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenH = MediaQuery.of(context).size.height;
    final courses = List<Course>.from(cartService.courses);

    // AICERTS subtotal (all courses are AICERTS in this pathway)
    double aicertsTotal = 0;
    for (final c in courses) {
      if (c.localPrice != null) {
        aicertsTotal += double.tryParse(c.localPrice!) ?? 0;
      } else {
        aicertsTotal += c.price ?? 199;
      }
    }

    // Grand total includes other pathways
    final grandTotal = cartService.calculateTotal();
    final totalItems = cartService.itemCount;
    final otherItems = totalItems - courses.length;

    return Container(
      height: screenH * 0.86,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.hosiPeach.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: AppTheme.hosiPeach, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AICERTS Enrollment Cart',
                        style: TextStyle( 
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        courses.isEmpty
                            ? 'No courses selected'
                            : '${courses.length} course${courses.length != 1 ? "s" : ""} selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          const Divider(height: 20, indent: 20, endIndent: 20),

          // Course list
          Expanded(
            child: courses.isEmpty
                ? _buildEmptyState(theme, colors)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: courses.length,
                    itemBuilder: (context, i) {
                      return _AICERTSCartTile(
                        course: courses[i],
                        onRemove: () async {
                          await cartService.removeCourse(courses[i].id);
                        },
                      );
                    },
                  ),
          ),

          // Bottom: totals + checkout
          if (courses.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                    top: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.3))),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                children: [
                  // AICERTS subtotal row
                  _TotalRow(
                    label: 'AICERTS Pathway (${courses.length} courses)',
                    value: CurrencyService.instance
                        .formatUSDAmount(aicertsTotal),
                    bold: false,
                    color: colors.onSurface,
                  ),
                  // Other pathways if present
                  if (otherItems > 0) ...[
                    const SizedBox(height: 4),
                    _TotalRow(
                      label: 'Other Pathways ($otherItems items)',
                      value: CurrencyService.instance
                          .formatUSDAmount(grandTotal - aicertsTotal),
                      bold: false,
                      color: colors.onSurface.withValues(alpha: 0.65),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _TotalRow(
                    label: 'Session Grand Total ($totalItems items)',
                    value: CurrencyService.instance
                        .formatUSDAmount(grandTotal),
                    bold: true,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _proceedToEnrollment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Proceed to Enrollment',
                        style: TextStyle( 
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined,
                size: 64, color: colors.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Your AICERTS cart is empty',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse courses above and click "Enroll Now" to add them here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AICERTSCartTile extends StatelessWidget {
  final Course course;
  final VoidCallback onRemove;

  const _AICERTSCartTile({required this.course, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image
          AICERTSImageWidget(
            imageUrl: course.featureImageUrl,
            imageType: AICERTSImageType.course,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.displayTitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  course.localPrice ??
                      CurrencyService.instance
                          .formatUSDAmount(course.price ?? 199),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline, color: colors.error, size: 20),
            tooltip: 'Remove from cart',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color color;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.bold,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold
              ? theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: color)
              : theme.textTheme.bodyMedium?.copyWith(color: color),
        ),
        Text(
          value,
          style: bold
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: color)
              : theme.textTheme.bodyMedium?.copyWith(
                  color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
