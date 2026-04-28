import 'package:flutter/material.dart';

class CookiePolicyModal extends StatelessWidget {
  const CookiePolicyModal({super.key});

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
                  'Cookie Policy',
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
            const SizedBox(height: 8),
            Text(
              'Last updated: January 2026',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      theme,
                      colors,
                      'What Are Cookies?',
                      'Cookies are small text files stored on your device when you visit websites. They help us provide a better, faster, and more secure experience by remembering your preferences and login information.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      'Types of Cookies We Use',
                      '',
                    ),
                    const SizedBox(height: 8),

                    _buildCookieType(
                      theme,
                      colors,
                      'Essential Cookies',
                      'Required for platform functionality including authentication, security, and course access. These cannot be disabled.',
                      Icons.security,
                    ),
                    const SizedBox(height: 12),

                    _buildCookieType(
                      theme,
                      colors,
                      'Preference Cookies',
                      'Remember your settings like language, theme (dark/light mode), and course preferences.',
                      Icons.settings,
                    ),
                    const SizedBox(height: 12),

                    _buildCookieType(
                      theme,
                      colors,
                      'Analytics Cookies',
                      'Help us understand how you use the platform so we can improve user experience and course delivery.',
                      Icons.analytics,
                    ),
                    const SizedBox(height: 12),

                    _buildCookieType(
                      theme,
                      colors,
                      'Marketing Cookies',
                      'Track your interests to show relevant course recommendations and promotional content.',
                      Icons.campaign,
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      theme,
                      colors,
                      'Third-Party Cookies',
                      'We use services from trusted partners that may set their own cookies: Payment processors (Flutterwave, Paystack), analytics tools (Google Analytics), video hosting (for course videos), and social media plugins.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      'How to Manage Cookies',
                      'You can control cookies through your browser settings. Note that disabling essential cookies may affect platform functionality.',
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint(colors, 'Chrome: Settings > Privacy and Security > Cookies'),
                    _buildBulletPoint(colors, 'Firefox: Options > Privacy & Security > Cookies'),
                    _buildBulletPoint(colors, 'Safari: Preferences > Privacy > Cookies'),
                    _buildBulletPoint(colors, 'Edge: Settings > Privacy > Cookies'),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      'Cookie Duration',
                      'Session cookies expire when you close your browser. Persistent cookies remain for a set period (typically 30-365 days) to remember your preferences across visits.',
                    ),
                    const SizedBox(height: 20),

                    // Contact Info
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
                            'Questions About Cookies?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contact us at info@hosiacademy.com for more information about our cookie practices.',
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
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 6),
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

  Widget _buildCookieType(ThemeData theme, ColorScheme colors, String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: colors.primary),
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

  Widget _buildBulletPoint(ColorScheme colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.arrow_right,
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
