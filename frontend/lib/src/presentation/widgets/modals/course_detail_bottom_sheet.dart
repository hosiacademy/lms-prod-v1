// lib/src/presentation/widgets/modals/course_detail_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/currency_service.dart';

class CourseDetailBottomSheet extends StatelessWidget {
  final String courseId;
  final String title; // Added props for real data
  final String description;
  final double price;
  final String duration;
  final String instructor;
  final double rating;
  final int enrollmentCount;
  final VoidCallback? onEnroll;

  const CourseDetailBottomSheet({
    super.key,
    required this.courseId,
    required this.title,
    this.description =
        'A comprehensive course on cutting-edge AI technologies...',
    this.price = 299.00,
    this.duration = '8 weeks',
    this.instructor = 'Dr. Jane Smith',
    this.rating = 4.8,
    this.enrollmentCount = 1245,
    this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.60,
      maxChildSize: 0.96,
      expand: false,
      snap: true,
      snapSizes: const [0.60, 0.92, 0.96],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Modern drag handle + close button
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: colors.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero-like course header
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          color: colors.primaryContainer,
                          child: Center(
                            child: Icon(
                              Icons.school_rounded,
                              size: 80,
                              color: colors.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        title,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rating, duration, price row
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '$rating ($enrollmentCount enrolled)',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Duration: $duration',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Price
                      Text(
                        CurrencyService.instance.formatPrice(price, currencyCode: 'USD'),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Instructor
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colors.primaryContainer,
                            child: Icon(Icons.person, color: colors.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instructor',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                              Text(
                                instructor,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Description
                      Text(
                        'Description',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // What You'll Learn (example section)
                      Text(
                        'What You\'ll Learn',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletPoint(context,
                          'Master advanced AI concepts and real-world applications'),
                      _buildBulletPoint(context,
                          'Build practical projects using cutting-edge tools'),
                      _buildBulletPoint(context,
                          'Earn a verifiable certificate upon completion'),
                      const SizedBox(height: 40),

                      // Enroll Button (full-width, prominent)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: onEnroll ??
                              () {
                                // Your enroll logic here
                                Navigator.pop(context);
                              },
                          icon: const Icon(Icons.school_rounded),
                          label: const Text(
                            'Enroll Now',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 20, color: AppTheme.successGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
