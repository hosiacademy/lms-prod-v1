// lib/src/presentation/pages/aicerts/aicerts_course_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../data/models/course.dart';
import '../../../core/services/aicerts_image_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/constants/pricing_constants.dart';
import '../../widgets/aicerts/aicerts_image_widget.dart';
import '../../widgets/aicerts/aicerts_course_viewer.dart';
import '../../widgets/modals/aicerts/aicerts_modals.dart';
import '../../../core/utils/string_utils.dart';

/// AICERTS Course Detail Page
///
/// Displays full course details with images, pricing, and enrollment options
///
/// **Features**:
/// - Large feature image display
/// - Certificate badge preview
/// - AI tool logos
/// - Course details and description
/// - Pricing and enrollment CTA
///
/// **Usage**:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => AICERTSCourseDetailPage(course: course),
///   ),
/// );
/// ```
class AICERTSCourseDetailPage extends StatefulWidget {
  final Course course;

  const AICERTSCourseDetailPage({
    super.key,
    required this.course,
  });

  @override
  State<AICERTSCourseDetailPage> createState() => _AICERTSCourseDetailPageState();
}

class _AICERTSCourseDetailPageState extends State<AICERTSCourseDetailPage> {
  bool _isEnrolling = false;

  void _handleEnroll() async {
    if (_isEnrolling) return;

    setState(() {
      _isEnrolling = true;
    });

    try {
      // Add to cart
      await cartService.addCourse(widget.course);

      if (!mounted) return;

      // Open enrollment modal using the appropriate AICERTS modal
      await AicertsModals.showEnrollmentModal(
        context: context,
        courses: cartService.courses,
        onEnrollmentComplete: () {
          cartService.clearCart();
          if (mounted) {
            setState(() {
              _isEnrolling = false;
            });
            Navigator.of(context).pop(); // Close modal
            Navigator.of(context).pop(); // Close detail page
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enroll: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _viewCourse() {
    // Open course viewer modal/bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AICERTSCourseViewer(
          courseId: int.tryParse(widget.course.externalId ?? '0') ?? 0,
          userId: widget.course.id, // Use course ID as user identifier
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colors.surface : colors.surfaceContainerHighest.withValues(alpha: 0.1),
      body: CustomScrollView(
        slivers: [
          // App Bar with image background
          _buildAppBar(context, colors),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image section
                _buildHeroSection(context, theme, colors),

                // Course content
                _buildCourseContent(context, theme, colors),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, theme, colors),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colors) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: colors.surface,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: colors.onSurface),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: colors.onSurface),
          onPressed: () {
            // TODO: Implement share functionality
          },
        ),
        IconButton(
          icon: Icon(Icons.bookmark_border, color: colors.onSurface),
          onPressed: () {
            // TODO: Implement bookmark functionality
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main feature image with certificate badge
          AICERTSCourseCardImage(
            featureImageUrl: widget.course.featureImageUrl,
            certificateBadgeUrl: widget.course.certificateBadgeUrl,
            width: double.infinity,
            height: 250, // Slightly reduced from 280
            showBadge: true,
            fit: BoxFit.contain, // Ensure no cropping
          ),

          const SizedBox(height: 24),

          // Course title
          Text(
            widget.course.title,
            style: TextStyle( 
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Category chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.signal_cellular_alt_rounded,
                label: 'Professional',
                colors: colors,
              ),
              _Chip(
                icon: Icons.timer_outlined,
                label: 'Self-Paced',
                colors: colors,
              ),
              if (widget.course.courseType != null)
                _Chip(
                  icon: Icons.class_,
                  label: widget.course.courseType!,
                  colors: colors,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Rating and students (if available)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 20, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '4.8',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(2,450 reviews)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 20, color: colors.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '10k+ learners',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What you'll learn section
          _buildSection(
            context,
            theme,
            colors,
            title: 'What You\'ll Learn',
            icon: Icons.psychology_outline,
            child: Text(
              StringUtils.stripHtml(widget.course.description ??
                  'Master industry-standard tools and techniques in this comprehensive certification course.'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
          ),

          // AI Tools section
          if (_hasAITools())
            _buildSection(
              context,
              theme,
              colors,
              title: 'AI Tools You\'ll Master',
              icon: Icons.build,
              child: _buildAIToolsSection(context, theme, colors),
            ),

          // Certificate section
          _buildSection(
            context,
            theme,
            colors,
            title: 'Certificate',
            icon: Icons.verified,
            child: _buildCertificateSection(context, theme, colors),
          ),

          // Pricing section
          _buildSection(
            context,
            theme,
            colors,
            title: 'Pricing',
            icon: Icons.attach_money,
            child: _buildPricingSection(context, theme, colors),
          ),

          // Bottom padding for bottom bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle( 
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAIToolsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
  ) {
    // TODO: Parse AI tools from course description or add to model
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        AICERTSAIToolLogo(
          toolImageUrl: null, // TODO: Get from course data
          toolName: 'TensorFlow',
          size: 56,
        ),
        AICERTSAIToolLogo(
          toolImageUrl: null, // TODO: Get from course data
          toolName: 'scikit-learn',
          size: 56,
        ),
      ],
    );
  }

  Widget _buildCertificateSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earn a recognized certificate',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Upon successful completion',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        AICERTSCertificateBadge(
          badgeUrl: widget.course.certificateBadgeUrl,
          size: 80,
        ),
      ],
    );
  }

  Widget _buildPricingSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
  ) {
    // Aligned with database: Use course price if available
    final localPrice = widget.course.localPrice ?? 
        (widget.course.price != null 
            ? CurrencyService.instance.formatPrice(widget.course.price!)
            : 'Contact for pricing');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localPrice,
          style: TextStyle( 
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2E7D32), // Success green
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'One-time payment, lifetime access',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
  ) {
    // Aligned with database: Use course price if available
    final localPrice = widget.course.localPrice ?? 
        (widget.course.price != null 
            ? CurrencyService.instance.formatPrice(widget.course.price!)
            : 'Contact for pricing');

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total price',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    localPrice,
                    style: TextStyle( 
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isEnrolling ? null : _handleEnroll,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isEnrolling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Enroll Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasAITools() {
    // TODO: Implement proper AI tools detection
    return false;
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;

  const _Chip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
