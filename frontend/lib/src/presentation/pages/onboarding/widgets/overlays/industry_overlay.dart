import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Redesigned Industry Overlay - Flows from top with compact header
/// Focuses on advertising 67+ role-based certifications
class IndustryTrainingOverlay extends StatefulWidget {
  final VoidCallback onHide;
  final VoidCallback onBrowseCatalog;
  final VoidCallback onScheduleConsultation;
  final VoidCallback? onMouseEnter;
  final VoidCallback? onMouseExit;

  const IndustryTrainingOverlay({
    super.key,
    required this.onHide,
    required this.onBrowseCatalog,
    required this.onScheduleConsultation,
    this.onMouseEnter,
    this.onMouseExit,
  });

  @override
  State<IndustryTrainingOverlay> createState() =>
      _IndustryTrainingOverlayState();
}

class _IndustryTrainingOverlayState extends State<IndustryTrainingOverlay> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => widget.onMouseEnter?.call());
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => widget.onMouseExit?.call());
        }
      },
      child: Container(
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.4),
        child: Column(
          children: [
            // Compact Header Section with Info Cards and View Schedule
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.secondary,
                    colors.tertiary,
                    colors.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.onPrimary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'INDUSTRY SPECIFIC',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onPrimary,
                            letterSpacing: 1.2,
                            fontSize: 10,
                          ),
                        ),
                      ),

                      // Compact Info Cards
                      if (screenWidth > 600)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CompactInfoCard(
                              icon: Icons.workspace_premium,
                              value: '67+',
                              label: 'Certifications',
                              colors: colors,
                            ),
                            const SizedBox(width: 12),
                            _CompactInfoCard(
                              icon: Icons.business,
                              value: '6',
                              label: 'Verticals',
                              colors: colors,
                            ),
                            const SizedBox(width: 12),
                            _CompactInfoCard(
                              icon: Icons.verified,
                              value: 'Global',
                              label: 'Recognition',
                              colors: colors,
                            ),
                          ],
                        ),

                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: widget.onBrowseCatalog,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: const Text('View Schedule'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.onPrimary,
                              foregroundColor: colors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Close Button
                          IconButton(
                            onPressed: widget.onHide,
                            icon: Icon(Icons.close, color: colors.onPrimary),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  colors.onPrimary.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .slideY(
                    begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOut)
                .fadeIn(duration: 300.ms),

            // Main Content - Scrollable Advertisement Section
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
                        'Master AI for Your Specific Role with 67+ Industry Certifications',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Move beyond generic AI training. Our AICERTS-powered programs deliver role-specific skills tailored to your industry—from AI for Healthcare to AI for Marketing, Finance, Sales, and beyond. Gain globally recognized credentials that demonstrate practical, job-ready expertise employers actively seek.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.85),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Performance Stats Row
                      Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _StatChip(
                            icon: Icons.layers,
                            value: '67+',
                            label: 'Industry Verticals',
                            colors: colors,
                          ),
                          _StatChip(
                            icon: Icons.task_alt,
                            value: '95%',
                            label: 'Success Rate',
                            colors: colors,
                          ),
                          _StatChip(
                            icon: Icons.public,
                            value: 'Global',
                            label: 'AICERTS Certified',
                            colors: colors,
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Industry Verticals Section
                      Text(
                        'Industry Verticals',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),

                      ..._industries.map((industry) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _IndustryCard(
                              title: industry['title']!,
                              icon: industry['icon'] as IconData,
                              description: industry['description']!,
                              colors: colors,
                              theme: theme,
                            ),
                          )),

                      const SizedBox(height: 48),

                      // Partnership Benefits Section
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.primaryContainer.withValues(alpha: 0.3),
                              colors.secondaryContainer.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.handshake,
                                    color: colors.primary, size: 32),
                                const SizedBox(width: 16),
                                Text(
                                  'Partnership Benefits',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _BenefitChip(
                                  icon: Icons.workspace_premium,
                                  label: 'AICERTS Verified',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.public,
                                  label: 'Global Recognition',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.auto_awesome,
                                  label: 'Industry-Specific',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.trending_up,
                                  label: 'Career Advancement',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.school,
                                  label: 'Expert Instructors',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.update,
                                  label: 'Lifetime Access',
                                  colors: colors,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Why Choose Section
                      Text(
                        'Why Choose Industry-Specific Training?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              constraints.maxWidth > 900 ? 3 : 1;
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1.1,
                            children: [
                              _FeatureCard(
                                icon: Icons.psychology,
                                title: 'Job-Ready Skills',
                                description:
                                    'Master AI tools and techniques designed for your exact role—whether you\'re in marketing, finance, HR, healthcare, or technical development. No generic theory, just practical applications.',
                                colors: colors,
                                theme: theme,
                              ),
                              _FeatureCard(
                                icon: Icons.rocket_launch,
                                title: 'Immediate Impact',
                                description:
                                    'Apply what you learn directly to your daily work. See productivity gains, improved decision-making, and measurable ROI from day one of your training.',
                                colors: colors,
                                theme: theme,
                              ),
                              _FeatureCard(
                                icon: Icons.verified_user,
                                title: 'Global Recognition',
                                description:
                                    'Earn AICERTS certifications recognized by employers worldwide. Stand out in competitive job markets and demonstrate verified expertise in AI applications.',
                                colors: colors,
                                theme: theme,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 64),

                      // Bottom CTA
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.secondary,
                                colors.tertiary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colors.secondary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 64,
                                color: colors.onPrimary,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Transform Your Industry Career',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Explore 67+ certifications and find the perfect program for your professional goals.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      colors.onPrimary.withValues(alpha: 0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: widget.onBrowseCatalog,
                                icon:
                                    const Icon(Icons.calendar_today, size: 20),
                                label: const Text('View Training Schedule'),
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
                        ),
                      ),

                      const SizedBox(height: 40),
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

// Compact Info Card for Header
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

// Industry Card
class _IndustryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final ColorScheme colors;
  final ThemeData theme;

  const _IndustryCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colors.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Feature Card
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

// Benefit Chip
class _BenefitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;

  const _BenefitChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// Industry Data
final List<Map<String, dynamic>> _industries = [
  {
    'title': 'Healthcare & Life Sciences',
    'icon': Icons.medical_services_outlined,
    'description':
        'AI adoption in healthcare is projected to grow by 40% annually. Master diagnostics, patient care optimization, and drug discovery.',
  },
  {
    'title': 'Finance & Banking',
    'icon': Icons.account_balance_outlined,
    'description':
        'Blockchain and AI are revolutionizing fintech. Learn precision fraud detection, algorithmic trading, and decentralized finance (DeFi).',
  },
  {
    'title': 'Marketing & Retail',
    'icon': Icons.shopping_bag_outlined,
    'description':
        '70% of high-growth brands use AI for personalization. Master generative AI for content, predictive analytics, and customer journeys.',
  },
  {
    'title': 'Supply Chain & Logistics',
    'icon': Icons.local_shipping_outlined,
    'description':
        'AI-driven logistics can reduce operations costs by 20%. Scale up with blockchain tracking and predictive demand forecasting.',
  },
  {
    'title': 'Energy & Sustainability',
    'icon': Icons.eco_outlined,
    'description':
        'Optimize R&D and reduce carbon footprints using AI. Focus on smart grids, renewable energy management, and ESG reporting.',
  },
  {
    'title': 'Legal & Compliance',
    'icon': Icons.gavel_outlined,
    'description':
        'Transform contract analysis and legal research. AI-powered regtech is essential for navigated complex global regulatory landscapes.',
  },
  {
    'title': 'Technical Engineering',
    'icon': Icons.engineering_outlined,
    'description':
        'From AI-assisted coding to smart manufacturing. Bridge the gap between legacy systems and forward-thinking technical architecture.',
  },
];

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
