import 'package:flutter/material.dart';
import '../../blocs/course/corporate/combined_masterclass_page.dart';

class ProfessionalMasterclassModal extends StatelessWidget {
  const ProfessionalMasterclassModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Professional Masterclasses',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elevate Your Leadership & Business Skills',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Professional masterclasses are intensive, high-value training programs designed for business leaders, managers, and professionals looking to enhance their expertise in strategic domains.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildMasterclassTopic(
                      theme,
                      colors,
                      Icons.trending_up,
                      'Strategic Leadership',
                      'Master the art of leading teams, driving change, and making strategic decisions in complex business environments.',
                    ),
                    _buildMasterclassTopic(
                      theme,
                      colors,
                      Icons.business_center,
                      'Business Management',
                      'Learn essential business operations, financial management, and organizational development strategies.',
                    ),
                    _buildMasterclassTopic(
                      theme,
                      colors,
                      Icons.psychology,
                      'Digital Transformation',
                      'Navigate the digital revolution, implement AI solutions, and transform traditional business models.',
                    ),
                    _buildMasterclassTopic(
                      theme,
                      colors,
                      Icons.groups,
                      'People Management',
                      'Develop skills in talent acquisition, performance management, and building high-performing teams.',
                    ),
                    _buildMasterclassTopic(
                      theme,
                      colors,
                      Icons.account_balance,
                      'Financial Strategy',
                      'Master corporate finance, investment strategies, and financial decision-making for business growth.',
                    ),
                    const SizedBox(height: 24),

                    // Key Features
                    Text(
                      'What You Get',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeature(colors, 'Live interactive sessions with industry experts'),
                    _buildFeature(colors, 'Case studies from African businesses'),
                    _buildFeature(colors, 'Networking with peers and mentors'),
                    _buildFeature(colors, 'Internationally recognized certificate'),
                    _buildFeature(colors, 'Lifetime access to recorded sessions'),
                    _buildFeature(colors, 'Practical frameworks and tools'),
                    const SizedBox(height: 24),

                    // Format & Duration
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            theme,
                            colors,
                            Icons.schedule,
                            'Duration',
                            '4-8 weeks',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            theme,
                            colors,
                            Icons.video_library,
                            'Format',
                            'Live + Recorded',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Testimonial
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.format_quote, color: colors.primary, size: 32),
                              const SizedBox(width: 8),
                              Text(
                                'Success Story',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '"The professional masterclass transformed my leadership approach. The insights from African case studies were invaluable for my role."',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '— Sarah M., Operations Manager',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to professional masterclasses only
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              opaque: false,
                              barrierDismissible: true,
                              barrierColor: Colors.black.withValues(alpha: 0.4),
                              pageBuilder: (context, animation, secondaryAnimation) {
                                final colors = Theme.of(context).colorScheme;
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 950),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colors.surface,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(32),
                                            bottomRight: Radius.circular(32),
                                            topLeft: Radius.circular(16),
                                            bottomLeft: Radius.circular(16),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 30,
                                              offset: const Offset(10, 0),
                                            ),
                                          ],
                                        ),
                                        child: const CombinedMasterclassPage(initialType: 'professional', embedMode: true),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(-1.0, 0.0);
                                const end = Offset.zero;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                                return SlideTransition(position: animation.drive(tween), child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        icon: const Icon(Icons.explore),
                        label: const Text('Explore All Masterclasses'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterclassTopic(
    ThemeData theme,
    ColorScheme colors,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(ColorScheme colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    ColorScheme colors,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
