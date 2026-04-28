import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Redesigned Learnerships Overlay - Flows from top with compact header
/// Focuses on advertising NQF-accredited skills development programs
class LearnershipsOverlay extends StatefulWidget {
  final VoidCallback onHide;
  final VoidCallback? onApplyNow;
  final VoidCallback? onDownloadBrochure;
  final VoidCallback? onMouseEnter;
  final VoidCallback? onMouseExit;

  const LearnershipsOverlay({
    super.key,
    required this.onHide,
    this.onApplyNow,
    this.onDownloadBrochure,
    this.onMouseEnter,
    this.onMouseExit,
  });

  @override
  State<LearnershipsOverlay> createState() => _LearnershipsOverlayState();
}

class _LearnershipsOverlayState extends State<LearnershipsOverlay> {
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
                    colors.tertiary,
                    colors.primary,
                    colors.secondary,
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
                          'LEARNERSHIPS',
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
                              icon: Icons.folder,
                              value: '10+',
                              label: 'Programs',
                              colors: colors,
                            ),
                            const SizedBox(width: 12),
                            _CompactInfoCard(
                              icon: Icons.verified,
                              value: 'NQF 5-6',
                              label: 'Accredited',
                              colors: colors,
                            ),
                            const SizedBox(width: 12),
                            _CompactInfoCard(
                              icon: Icons.payments,
                              value: 'Stipend',
                              label: 'Included',
                              colors: colors,
                            ),
                          ],
                        ),

                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: widget.onApplyNow,
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
                        'Transform Your Future with NQF-Accredited Learnerships',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bridge the gap between education and employment with South Africa\'s premier work-integrated learning programs. Combine structured theoretical learning with hands-on workplace experience, earn a nationally recognized qualification, and receive a monthly stipend—all while building the skills that employers demand.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.85),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Key Stats Row
                      Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _StatChip(
                            icon: Icons.trending_up,
                            value: '5.3M+',
                            label: 'Jobs Created by 2030',
                            colors: colors,
                          ),
                          _StatChip(
                            icon: Icons.attach_money,
                            value: 'R40K-R60K',
                            label: 'Tax Benefits per Learner',
                            colors: colors,
                          ),
                          _StatChip(
                            icon: Icons.schedule,
                            value: '12-24',
                            label: 'Months Duration',
                            colors: colors,
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // What are Learnerships Section
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
                                Icon(Icons.school,
                                    color: colors.primary, size: 32),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'What is a Learnership?',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Learnerships are formal, structured work-based learning programs registered with the South African Qualifications Authority (SAQA) that combine theoretical classroom instruction with practical workplace experience. These programs are specifically designed to address the critical skills gap in South Africa by providing learners with industry-relevant competencies while earning a nationally recognized NQF qualification.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.8),
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Developed in partnership with Sector Education and Training Authorities (SETAs) and industry leaders, learnerships ensure that training aligns with real-world job requirements. Upon completion, learners receive both a formal qualification and invaluable hands-on experience, dramatically improving their employability and opening doors to career advancement.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.8),
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Program Benefits Section
                      Text(
                        'Program Benefits',
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
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1.5,
                            children: [
                              _BenefitCard(
                                icon: Icons.work,
                                title: 'Hands-On Workplace Training',
                                description:
                                    'Work alongside industry professionals in a real business environment. Apply theoretical knowledge to practical challenges under expert mentorship, developing both technical skills and professional competencies valued by employers.',
                                colors: colors,
                                theme: theme,
                              ),
                              _BenefitCard(
                                icon: Icons.payments,
                                title: 'Earn While You Learn',
                                description:
                                    'Receive a monthly stipend throughout your 12-24 month program, covering living expenses while you gain skills. No student debt—just practical experience and a pathway to employment.',
                                colors: colors,
                                theme: theme,
                              ),
                              _BenefitCard(
                                icon: Icons.verified,
                                title: 'SAQA-Registered Qualification',
                                description:
                                    'Earn an NQF Level 5-6 qualification recognized nationwide by employers and institutions. Your certificate opens doors across industries and provides a foundation for further education.',
                                colors: colors,
                                theme: theme,
                              ),
                              _BenefitCard(
                                icon: Icons.trending_up,
                                title: 'Accelerated Career Growth',
                                description:
                                    'Bridge the gap between education and employment. Learnership graduates see significantly higher employment rates and faster career progression compared to traditional education paths.',
                                colors: colors,
                                theme: theme,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 48),

                      // Available Specializations
                      Text(
                        'Available Specializations',
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
                          _SpecializationChip(
                            label: 'Data Science & AI',
                            icon: Icons.analytics,
                            colors: colors,
                          ),
                          _SpecializationChip(
                            label: 'Blockchain Development',
                            icon: Icons.link,
                            colors: colors,
                          ),
                          _SpecializationChip(
                            label: 'Cybersecurity',
                            icon: Icons.security,
                            colors: colors,
                          ),
                          _SpecializationChip(
                            label: 'Software Development',
                            icon: Icons.code,
                            colors: colors,
                          ),
                          _SpecializationChip(
                            label: 'Digital Marketing',
                            icon: Icons.campaign,
                            colors: colors,
                          ),
                          _SpecializationChip(
                            label: 'Project Management',
                            icon: Icons.assignment,
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
                                  icon: Icons.workspace_premium,
                                  label: 'AICERTS Certified',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.business,
                                  label: 'Industry Partners',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.schedule,
                                  label: '12-24 Month Programs',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.support_agent,
                                  label: 'Mentorship Support',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.badge,
                                  label: 'Digital Credentials',
                                  colors: colors,
                                ),
                                _BenefitChip(
                                  icon: Icons.groups,
                                  label: 'Peer Community',
                                  colors: colors,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 64),

                      // Bottom CTA
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.tertiary,
                                colors.primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colors.tertiary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school,
                                size: 64,
                                color: colors.onPrimary,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Start Your Learning Journey',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Browse available learnership programs and take the first step toward your future career.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      colors.onPrimary.withValues(alpha: 0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: widget.onApplyNow,
                                icon:
                                    const Icon(Icons.calendar_today, size: 20),
                                label: const Text('View Program Schedule'),
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

// Benefit Card
class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colors;
  final ThemeData theme;

  const _BenefitCard({
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Specialization Chip
class _SpecializationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme colors;

  const _SpecializationChip({
    required this.label,
    required this.icon,
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
          Icon(icon, size: 16, color: colors.primary),
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
