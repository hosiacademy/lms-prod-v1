import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Redesigned Corporate Overlay - Flows from top with compact header
/// Focuses on advertising offerings with no enrollment CTAs
class CorporateOverlay extends StatefulWidget {
  final VoidCallback onHide;
  final VoidCallback onViewMasterclassSchedule;
  final VoidCallback? onCreateOwnMasterclass;
  final VoidCallback onFullDetails;
  final VoidCallback? onMouseEnter;
  final VoidCallback? onMouseExit;

  const CorporateOverlay({
    super.key,
    required this.onHide,
    required this.onViewMasterclassSchedule,
    this.onCreateOwnMasterclass,
    required this.onFullDetails,
    this.onMouseEnter,
    this.onMouseExit,
  });

  @override
  State<CorporateOverlay> createState() => _CorporateOverlayState();
}

class _CorporateOverlayState extends State<CorporateOverlay> {
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
                    colors.primary,
                    colors.secondary,
                    colors.tertiary,
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
                          'CORPORATE TRAINING',
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
                              value: '100+',
                              label: 'Certifications',
                              colors: colors,
                            ),
                            const SizedBox(width: 12),
                            _CompactInfoCard(
                              icon: Icons.business,
                              value: '500+',
                              label: 'Companies',
                              colors: colors,
                            ),
                            const SizedBox(width: 12),
                            _CompactInfoCard(
                              icon: Icons.people,
                              value: '10K+',
                              label: 'Trained',
                              colors: colors,
                            ),
                          ],
                        ),

                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: widget.onViewMasterclassSchedule,
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
                        'Future-Proof Your Workforce with AI-Driven Corporate Training',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Empower your team with the skills of tomorrow. From executive AI strategy to technical implementation, we provide personalized, role-based upskilling programs guaranteed to drive measurable productivity gains and strategic innovation within your organization.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.85),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Innovation Stats Row
                      Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _StatChip(
                            icon: Icons.trending_up,
                            value: r'$7.9T',
                            label: 'Productivity Impact',
                            colors: colors,
                          ),
                          _StatChip(
                            icon: Icons.groups_3,
                            value: '5.3M+',
                            label: 'Net New Jobs by 2030',
                            colors: colors,
                          ),
                          _StatChip(
                            icon: Icons.speed,
                            value: '70%',
                            label: 'Skill Transformation',
                            colors: colors,
                          ),
                        ],
                      ),

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
                                  icon: Icons.badge_outlined,
                                  label: 'Digital Credentials',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.analytics_outlined,
                                  label: 'Progress Analytics',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.groups_outlined,
                                  label: 'Custom Cohorts',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.schedule_outlined,
                                  label: 'Flexible Scheduling',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.update,
                                  label: 'Lifetime Updates',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.security_outlined,
                                  label: 'Enterprise Security',
                                  colors: colors,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Offerings Grid
                      Text(
                        'Our Corporate Training Solutions',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              constraints.maxWidth > 900 ? 2 : 1;
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 24,
                            childAspectRatio: 1.4,
                            children: [
                              _OfferingCard(
                                icon: Icons.calendar_month,
                                title: 'Scheduled Masterclasses',
                                description:
                                    'Structured, ready-to-attend programs for teams and departments. Perfect for rapid upskilling on industry-standard AI and Blockchain frameworks.',
                                highlights: [
                                  'AI+ Executive™ & Chief AI Officer™',
                                  'Role-based Sales, HR & Marketing AI',
                                  'Collaborative peer learning',
                                  'Globally recognized credentials',
                                ],
                                colors: colors,
                                theme: theme,
                              ),
                              _OfferingCard(
                                icon: Icons.insights,
                                title: 'Custom Enterprise Pathways',
                                description:
                                    'Bespoke training architecture designed to solve your specific technical and business challenges. Integrated with your corporate goals.',
                                highlights: [
                                  'Organizational skill gap analysis',
                                  'Personalized adaptive learning paths',
                                  'Direct ROI impact tracking',
                                  'Dedicated Enterprise Success Manager',
                                ],
                                colors: colors,
                                theme: theme,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 48),

                      // Featured Certifications
                      Text(
                        'Featured Certifications',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _CertificationBadge(
                            label: 'AI+ Executive™',
                            colors: colors,
                          ),
                          _CertificationBadge(
                            label: 'Blockchain+ Developer™',
                            colors: colors,
                          ),
                          _CertificationBadge(
                            label: 'AI+ Chief AI Officer™',
                            colors: colors,
                          ),
                          _CertificationBadge(
                            label: 'AI+ Marketing Professional™',
                            colors: colors,
                          ),
                          _CertificationBadge(
                            label: 'AI+ HR & Talent Management™',
                            colors: colors,
                          ),
                          _CertificationBadge(
                            label: 'AI+ Project Manager™',
                            colors: colors,
                          ),
                        ],
                      ),

                      const SizedBox(height: 64),

                      // Bottom CTA
                      Center(
                        child: Container(
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
                                Icons.rocket_launch,
                                size: 64,
                                color: colors.onPrimary,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Ready to Elevate Your Organization?',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Explore our masterclass schedules and discover how AICERTS-powered training can transform your workforce.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      colors.onPrimary.withValues(alpha: 0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: widget.onViewMasterclassSchedule,
                                icon:
                                    const Icon(Icons.calendar_today, size: 20),
                                label: const Text('View Full Schedule'),
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

// Offering Card for Main Content
class _OfferingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> highlights;
  final ColorScheme colors;
  final ThemeData theme;

  const _OfferingCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.highlights,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...highlights.map(
            (highlight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      highlight,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

// Certification Badge
class _CertificationBadge extends StatelessWidget {
  final String label;
  final ColorScheme colors;

  const _CertificationBadge({
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.1),
            colors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
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
