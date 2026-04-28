import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Custom Selection Overlay
/// Allows users to browse and add selected courses to a shopping list / cart
class CustomSelectionOverlay extends StatefulWidget {
  final VoidCallback onHide;
  final VoidCallback onBrowseCourses; // → go to course catalog
  final VoidCallback onViewCart; // → go to shopping list / summary
  final VoidCallback?
      onStartEnrollment; // optional: quick start enrollment flow
  final VoidCallback? onMouseEnter;
  final VoidCallback? onMouseExit;

  const CustomSelectionOverlay({
    super.key,
    required this.onHide,
    required this.onBrowseCourses,
    required this.onViewCart,
    this.onStartEnrollment,
    this.onMouseEnter,
    this.onMouseExit,
  });

  @override
  State<CustomSelectionOverlay> createState() => _CustomSelectionOverlayState();
}

class _CustomSelectionOverlayState extends State<CustomSelectionOverlay> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return MouseRegion(
      onEnter: (_) => widget.onMouseEnter?.call(),
      onExit: (_) => widget.onMouseExit?.call(),
      child: Container(
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.4),
        child: Column(
          children: [
            // Header: AICERTS image covering all upper space
            SizedBox(
              width: double.infinity,
              height: screenWidth < 600 ? 140 : 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // AICERTS image as background
                  Image.asset(
                    'assets/images/onboarding/aicerts.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  // Dark scrim for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                  // Content overlay
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'CUSTOM SELECTION',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Build Your Own\nLearning Path',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: widget.onBrowseCourses,
                                icon:
                                    const Icon(Icons.explore, size: 16),
                                label: const Text('Browse Courses'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: colors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: widget.onHide,
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .slideY(
                    begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOut)
                .fadeIn(duration: 300.ms),

            // Main Content - Scrollable Section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surface,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Section
                      Text(
                        'Architect Your Own Success with a Custom Learning Path',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Why settle for a one-size-fits-all education? Design a learning journey as unique as your career goals. Browse our extensive catalog of AI and Blockchain courses, mix and match certifications, and build a personalized portfolio of skills that sets you apart in the global job market.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.85),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Career Stats Row
                      Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _StatChip(
                            icon: Icons.auto_awesome,
                            value: '100%',
                            label: 'Personalized Control',
                            colors: colors,
                          ),
                          _StatChip(
                            icon: Icons.savings,
                            value: '15-20%',
                            label: 'Bundle Discounts',
                            colors: colors,
                          ),
                          _StatChip(
                            icon: Icons.workspace_premium,
                            value: 'Global',
                            label: 'AICERTS Certified',
                            colors: colors,
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // The 3-Step Journey
                      Text(
                        'Your Path to Mastery in 3 Simple Steps',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          return Flex(
                            direction:
                                isMobile ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStep(
                                context,
                                '1',
                                'Explore & Discover',
                                'Browse our extensive catalog of AI, Blockchain, and technical masterclasses.',
                                Icons.search_rounded,
                                colors,
                              ),
                              if (!isMobile) const SizedBox(width: 24),
                              if (isMobile) const SizedBox(height: 24),
                              _buildStep(
                                context,
                                '2',
                                'Build Your Bundle',
                                'Add certifications to your cart. The more you add, the more you save with adaptive discounts.',
                                Icons.auto_fix_high_rounded,
                                colors,
                              ),
                              if (!isMobile) const SizedBox(width: 24),
                              if (isMobile) const SizedBox(height: 24),
                              _buildStep(
                                context,
                                '3',
                                'Graduate & Prosper',
                                'Complete your custom track at your own pace and earn globally recognized AICERTS credentials.',
                                Icons.school_rounded,
                                colors,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 48),

                      // Key Advantages
                      Text(
                        'Why Choose Custom Selection?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              constraints.maxWidth > 900 ? 3 : 1;
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 24,
                            childAspectRatio: 1.3,
                            children: [
                              _FeatureCard(
                                icon: Icons.dashboard_customize,
                                title: 'Curation Freedom',
                                description:
                                    'Select exactly the skills you need for your next promotion or project. From generative AI to blockchain architecture, the choice is yours.',
                                colors: colors,
                                theme: theme,
                              ),
                              _FeatureCard(
                                icon: Icons.savings,
                                title: 'Intelligent Value',
                                description:
                                    'Invest in yourself efficiently. Benefit from scalable discounts as you add more certifications to your customized learning track.',
                                colors: colors,
                                theme: theme,
                              ),
                              _FeatureCard(
                                icon: Icons.trending_up,
                                title: 'Accelerated Impact',
                                description:
                                    'Don\'t waste time on what you already know. Focus 100% on the new competencies that will move the needle for your career.',
                                colors: colors,
                                theme: theme,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 64),

                      // Popular Combinations Section
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_graph_rounded,
                                    color: colors.primary, size: 28),
                                const SizedBox(width: 16),
                                Text(
                                  'Popular Career Accelerators',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'These combinations are currently high in demand among our learners.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _CombinationTile(
                                  title: 'AI Strategy Leader',
                                  courses: [
                                    'AI+ Executive™',
                                    'Generative AI Specialist™'
                                  ],
                                  colors: colors,
                                ),
                                _CombinationTile(
                                  title: 'Web3 Architect',
                                  courses: [
                                    'Blockchain+ Developer™',
                                    'Ethereum Specialist™'
                                  ],
                                  colors: colors,
                                ),
                                _CombinationTile(
                                  title: 'Technical AI Lead',
                                  courses: [
                                    'Applied AI Engineer™',
                                    'NLP Specialist™'
                                  ],
                                  colors: colors,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 64),

                      // Strong CTA / Shopping List Teaser
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 700),
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.primary,
                                colors.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_basket_rounded,
                                size: 64,
                                color: colors.onPrimary,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Start Building Your Learning Cart',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Browse hundreds of courses, add your favorites to the cart, review your selection, and proceed to secure enrollment.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      colors.onPrimary.withValues(alpha: 0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: widget.onBrowseCourses,
                                    icon: const Icon(Icons.explore_outlined),
                                    label: const Text('Browse Courses'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.onPrimary,
                                      side: BorderSide(color: colors.onPrimary),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  ElevatedButton.icon(
                                    onPressed: widget.onViewCart,
                                    icon: const Icon(
                                        Icons.shopping_cart_checkout),
                                    label: const Text('View Your Cart'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.onPrimary,
                                      foregroundColor: colors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 20,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reused Components (copied style from other overlays) ──

class _CompactInfoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ColorScheme colors;

  const _CompactInfoCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.onPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.onPrimary, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimary,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.onPrimary.withValues(alpha: 0.8),
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colors;
  final ThemeData theme;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: colors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Touch-up Helper Widgets ──

Widget _buildStep(
  BuildContext context,
  String number,
  String title,
  String description,
  IconData icon,
  ColorScheme colors,
) {
  final theme = Theme.of(context);
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: colors.primary, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _CombinationTile extends StatelessWidget {
  final String title;
  final List<String> courses;
  final ColorScheme colors;

  const _CombinationTile({
    required this.title,
    required this.courses,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...courses.map((course) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: colors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        course,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// Stat Chip for Key Metrics
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ColorScheme colors;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
