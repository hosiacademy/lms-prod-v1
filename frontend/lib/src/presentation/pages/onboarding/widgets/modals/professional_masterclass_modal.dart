import 'package:flutter/material.dart';
import '../../../../blocs/course/corporate/combined_masterclass_page.dart';

class ProfessionalMasterclassModal extends StatelessWidget {
  const ProfessionalMasterclassModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screen = MediaQuery.of(context).size;
    final isNarrow = screen.width < 480;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12 : 24,
        vertical: isNarrow ? 16 : 32,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: screen.height * 0.88,
        ),
        child: Padding(
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
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
                        fontSize: (screen.width * 0.05).clamp(16.0, 22.0),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
                          fontSize: (screen.width * 0.045).clamp(14.0, 20.0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Professional masterclasses are intensive, high-value training programs designed for business leaders, managers, and professionals looking to enhance their expertise in strategic domains.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.8),
                          height: 1.6,
                          fontSize: (screen.width * 0.035).clamp(12.0, 15.0),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildTopic(
                          theme,
                          colors,
                          Icons.trending_up,
                          'Strategic Leadership',
                          'Master the art of leading teams, driving change, and making strategic decisions.',
                          screen),
                      _buildTopic(
                          theme,
                          colors,
                          Icons.business_center,
                          'Business Management',
                          'Learn essential business operations, financial management, and organizational development.',
                          screen),
                      _buildTopic(
                          theme,
                          colors,
                          Icons.psychology,
                          'Digital Transformation',
                          'Navigate the digital revolution, implement AI solutions, and transform business models.',
                          screen),
                      _buildTopic(
                          theme,
                          colors,
                          Icons.groups,
                          'People Management',
                          'Develop skills in talent acquisition, performance management, and building high-performing teams.',
                          screen),
                      _buildTopic(
                          theme,
                          colors,
                          Icons.account_balance,
                          'Financial Strategy',
                          'Master corporate finance, investment strategies, and financial decision-making.',
                          screen),
                      const SizedBox(height: 20),

                      Text(
                        'What You Get',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                          fontSize: (screen.width * 0.04).clamp(13.0, 17.0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...[
                        'Live interactive sessions with industry experts',
                        'Case studies from African businesses',
                        'Networking with peers and mentors',
                        'Internationally recognized certificate',
                        'Lifetime access to recorded sessions',
                        'Practical frameworks and tools',
                      ].map((f) => _buildFeature(colors, f, screen)),
                      const SizedBox(height: 20),

                      // Info cards — stack on narrow
                      isNarrow
                          ? Column(children: [
                              _buildInfoCard(theme, colors, Icons.schedule,
                                  'Duration', '4-8 weeks'),
                              const SizedBox(height: 10),
                              _buildInfoCard(theme, colors, Icons.video_library,
                                  'Format', 'Live + Recorded'),
                            ])
                          : Row(children: [
                              Expanded(
                                  child: _buildInfoCard(theme, colors,
                                      Icons.schedule, 'Duration', '4-8 weeks')),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildInfoCard(
                                      theme,
                                      colors,
                                      Icons.video_library,
                                      'Format',
                                      'Live + Recorded')),
                            ]),
                      const SizedBox(height: 20),

                      // Testimonial
                      Container(
                        padding: EdgeInsets.all(isNarrow ? 12 : 16),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.format_quote,
                                  color: colors.primary, size: 28),
                              const SizedBox(width: 8),
                              Text('Success Story',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  )),
                            ]),
                            const SizedBox(height: 10),
                            Text(
                              '"The professional masterclass transformed my leadership approach. The insights from African case studies were invaluable."',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                                fontSize:
                                    (screen.width * 0.033).clamp(12.0, 14.0),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('— Sarah M., Operations Manager',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      colors.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                opaque: false,
                                barrierDismissible: true,
                                barrierColor:
                                    Colors.black.withValues(alpha: 0.4),
                                pageBuilder: (ctx, _, __) {
                                  final c = Theme.of(ctx).colorScheme;
                                  final sw = MediaQuery.of(ctx).size.width;
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: sw < 480 ? 0 : 20,
                                        horizontal: sw < 480 ? 0 : 10,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: sw < 480 ? sw : 900,
                                          maxHeight:
                                              MediaQuery.of(ctx).size.height *
                                                  (sw < 480 ? 1.0 : 0.9),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: c.surface,
                                            borderRadius: sw < 480
                                                ? BorderRadius.zero
                                                : const BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(32),
                                                    bottomRight:
                                                        Radius.circular(32),
                                                    topLeft:
                                                        Radius.circular(16),
                                                    bottomLeft:
                                                        Radius.circular(16),
                                                  ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 30,
                                                offset: const Offset(10, 0),
                                              ),
                                            ],
                                          ),
                                          child: const CombinedMasterclassPage(
                                            initialType: 'professional',
                                            embedMode: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                transitionsBuilder: (_, animation, __, child) {
                                  return SlideTransition(
                                    position: animation.drive(
                                      Tween(
                                              begin: const Offset(-1.0, 0.0),
                                              end: Offset.zero)
                                          .chain(CurveTween(
                                              curve: Curves.easeInOut)),
                                    ),
                                    child: child,
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                              ),
                            );
                          },
                          icon: const Icon(Icons.explore),
                          label: const Text('Explore All Masterclasses'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: isNarrow ? 14 : 16),
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
      ),
    );
  }

  Widget _buildTopic(ThemeData theme, ColorScheme colors, IconData icon,
      String title, String desc, Size screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      fontSize: (screen.width * 0.038).clamp(12.0, 15.0),
                    )),
                const SizedBox(height: 3),
                Text(desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                      fontSize: (screen.width * 0.03).clamp(11.0, 13.0),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(ColorScheme colors, String text, Size screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                  fontSize: (screen.width * 0.032).clamp(11.0, 14.0),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, ColorScheme colors, IconData icon,
      String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              )),
          const SizedBox(height: 3),
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              )),
        ],
      ),
    );
  }
}
