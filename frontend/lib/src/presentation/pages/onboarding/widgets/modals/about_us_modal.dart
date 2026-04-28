import 'package:flutter/material.dart';

class AboutUsModal extends StatelessWidget {
  const AboutUsModal({super.key});

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
                Text(
                  'About Hosi Academy',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
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
                    // Mission & Vision
                    _buildSection(
                      theme,
                      colors,
                      'Our Mission',
                      'Hosi Academy is Africa\'s premier learning management system, dedicated to empowering individuals and organizations with world-class AI, Blockchain, and Cybersecurity training. We believe in an Africa-first approach to education, making cutting-edge technology skills accessible to everyone across the continent.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      theme,
                      colors,
                      'Why Hosi Academy?',
                      'We combine internationally recognized certifications with practical, industry-relevant training designed specifically for African learners. Our platform is mobile-first, works offline, and supports over 16 African payment methods to ensure accessibility for all.',
                    ),
                    const SizedBox(height: 20),

                    // Platform Statistics
                    _buildSection(
                      theme,
                      colors,
                      'Platform Highlights',
                      '',
                    ),
                    _buildBulletPoint(colors, 'ISO/IEC 27001 Certified training provider'),
                    _buildBulletPoint(colors, 'Blockchain-verified certificates'),
                    _buildBulletPoint(colors, 'Partnership with AICERTS for globally recognized AI certifications'),
                    _buildBulletPoint(colors, 'Mobile-first platform with offline capabilities'),
                    _buildBulletPoint(colors, 'Support for 16+ African payment methods'),
                    _buildBulletPoint(colors, 'Career-focused skills aligned with African industry needs'),
                    const SizedBox(height: 20),

                    // Strategic Partnerships
                    _buildSection(
                      theme,
                      colors,
                      'Strategic Partnerships',
                      'We partner with leading organizations like AICERTS to bring you the best AI and blockchain certifications. Our network includes major African payment providers (Flutterwave, Paystack, M-Pesa, MTN Mobile Money) to ensure seamless enrollment.',
                    ),
                    const SizedBox(height: 20),

                    // Call to Action
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to Start Learning?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Explore our courses and begin your journey to mastering AI, Blockchain, and Cybersecurity skills that African employers need today.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
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

  Widget _buildSection(ThemeData theme, ColorScheme colors, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBulletPoint(ColorScheme colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: colors.primary,
            ),
          ),
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
}
