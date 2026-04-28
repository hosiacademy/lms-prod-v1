import 'package:flutter/material.dart';

class TestimonialSection extends StatelessWidget {
  const TestimonialSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Text(
            'What Our Students Say',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Join thousands of satisfied learners who have transformed their careers.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _buildTestimonialCard(
                            context,
                            'Chioma Okonkwo',
                            'Data Scientist',
                            'Hosi Academy\'s curriculum is perfectly tailored for the African tech market. I went from novice to hired in 6 months.')),
                    const SizedBox(width: 24),
                    Expanded(
                        child: _buildTestimonialCard(
                            context,
                            'Thabo Mokoena',
                            'Software Developer',
                            'The masterclass gave me the practical skills I needed to secure a remote role. The mentorship was invaluable!')),
                    const SizedBox(width: 24),
                    Expanded(
                        child: _buildTestimonialCard(
                            context,
                            'Kwame Mensah',
                            'Product Designer',
                            'The community support and project-based learning approach made all the difference. best investment in my career.')),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTestimonialCard(
                        context,
                        'Chioma Okonkwo',
                        'Data Scientist',
                        'Hosi Academy\'s curriculum is perfectly tailored for the African tech market. I went from novice to hired in 6 months.'),
                    const SizedBox(height: 24),
                    _buildTestimonialCard(
                        context,
                        'Thabo Mokoena',
                        'Software Developer',
                        'The masterclass gave me the practical skills I needed to secure a remote role. The mentorship was invaluable!'),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  static const _avatarAssets = {
    'Chioma Okonkwo': 'assets/images/testimonials/ad54.jpeg',
    'Thabo Mokoena': 'assets/images/testimonials/ad13.jpeg',
    'Kwame Mensah': 'assets/images/testimonials/ghana.jpeg',
  };

  Widget _buildTestimonialCard(
      BuildContext context, String name, String role, String quote) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final avatarAsset = _avatarAssets[name];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Large avatar — ClipOval + topCenter alignment so heads are never cut
          ClipOval(
            child: SizedBox(
              width: 158,
              height: 158,
              child: avatarAsset != null
                  ? Image.asset(
                      avatarAsset,
                      fit: BoxFit.cover,
                      // top-centre keeps the face visible in portrait shots
                      alignment: const Alignment(0.0, -0.6),
                    )
                  : Container(
                      color: colorScheme.primaryContainer,
                      child: Center(
                        child: Text(
                          name[0],
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Role chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              role,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Divider
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          // Quote icon + text
          Icon(Icons.format_quote_rounded,
              color: colorScheme.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            '"$quote"',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
