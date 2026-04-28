// lib/src/presentation/pages/onboarding/widgets/training_options_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

/// Training Options Modal
/// Shows 4 training pathways when user clicks on the Training Pathways buttons in the header
class TrainingOptionsModal extends StatelessWidget {
  final Function(String route) onOptionSelected;
  final bool isCybersecurity;

  const TrainingOptionsModal({
    super.key,
    required this.onOptionSelected,
    this.isCybersecurity = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final hosiBrown = AppTheme.hosiBrown;
    final successGreen = AppTheme.successGreen;
    final hosiPeach = AppTheme.hosiPeach;

    final isMobile = screenWidth < 600;

    // For Cybersecurity Training, only Learnerships is available
    // Other options show "Coming Soon"
    final options = isCybersecurity
        ? [
            _TrainingOption(
              title: 'Learnerships',
              subtitle: 'NQF-accredited cybersecurity skills programmes',
              icon: Icons.school_rounded,
              color: successGreen,
              route: '/enroll/cybersecurity',
            ),
            _TrainingOption(
              title: 'Corporate Training',
              subtitle: 'AI+ Security Masterclasses for businesses',
              icon: Icons.business_rounded,
              color: hosiBrown,
              route: 'coming_soon',
              svgAsset: 'assets/images/pathways/corporate_training.svg',
            ),
            _TrainingOption(
              title: 'Industry & Role Based Training',
              subtitle: 'Sector-specific cybersecurity certifications',
              icon: Icons.engineering_rounded,
              color: hosiBrown,
              route: 'coming_soon',
              svgAsset: 'assets/images/pathways/industry_training.svg',
            ),
            _TrainingOption(
              title: 'Custom Selection',
              subtitle: 'Build your own cybersecurity learning path',
              icon: Icons.dashboard_customize_rounded,
              color: hosiPeach,
              route: 'coming_soon',
              svgAsset: 'assets/images/pathways/custom_selection.svg',
            ),
          ]
        : [
            _TrainingOption(
              title: 'Corporate Training',
              subtitle: 'AI+ Masterclasses for businesses',
              icon: Icons.business_rounded,
              color: hosiBrown,
              route: '/enroll/corporate',
              svgAsset: 'assets/images/pathways/corporate_training.svg',
            ),
            _TrainingOption(
              title: 'Learnerships',
              subtitle: 'NQF-accredited skills programmes',
              icon: Icons.school_rounded,
              color: successGreen,
              route: '/enroll/learnerships',
            ),
            _TrainingOption(
              title: 'Industry & Role Based Training',
              subtitle: 'Sector-specific AI certifications',
              icon: Icons.engineering_rounded,
              color: hosiBrown,
              route: '/enroll/industry',
              svgAsset: 'assets/images/pathways/industry_training.svg',
            ),
            _TrainingOption(
              title: 'Custom Selection',
              subtitle: 'Build your own learning path',
              icon: Icons.dashboard_customize_rounded,
              color: hosiPeach,
              route: '/enroll/custom',
              svgAsset: 'assets/images/pathways/custom_selection.svg',
            ),
          ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 24 : 32,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.tertiary,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: colorScheme.onPrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Training Pathways',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        Text(
                          'Choose your learning journey',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colorScheme.onPrimary),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),

            // Options Grid
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: options
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final option = entry.value;

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          if (option.route == 'coming_soon') {
                            _showComingSoonModal(context);
                          } else {
                            onOptionSelected(option.route);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: option.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: option.color.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: option.color.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon/SVG
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: option.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: option.svgAsset != null
                                    ? SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: Image.asset(
                                          option.svgAsset!,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              option.icon,
                                              color: option.color,
                                              size: 32,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        option.icon,
                                        color: option.color,
                                        size: 32,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.title,
                                      style: TextStyle(fontFamily: 'Poppins', 
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option.subtitle,
                                      style: TextStyle(fontFamily: 'Poppins', 
                                        fontSize: 13,
                                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: option.color,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ).animate(
                        delay: Duration(milliseconds: index * 100)
                      ).fadeIn().slideX(begin: 0.1, end: 0);
                    })
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonModal(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.hosiBrown,
                        AppTheme.hosiPeach,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.construction_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coming Soon',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "We're working on it!",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 64,
                        color: AppTheme.hosiBrown.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'This cybersecurity training option is not available yet.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We\'re developing exciting new cybersecurity training programs. Please check back soon or explore our available Learnerships option.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Got it!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrainingOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String? svgAsset;

  const _TrainingOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.svgAsset,
  });
}
