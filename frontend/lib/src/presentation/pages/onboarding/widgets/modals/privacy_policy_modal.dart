import 'package:flutter/material.dart';

class PrivacyPolicyModal extends StatelessWidget {
  const PrivacyPolicyModal({super.key});

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
                  'Privacy Policy',
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
              'Last updated: January 2026 | ISO/IEC 27001 Certified',
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
                      '1. Information We Collect',
                      'We collect information you provide during registration (name, email, phone, country), payment information (processed by our secure payment partners), learning data (course progress, assessments, certificates), and technical data (IP address, device information, browser type).',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '2. How We Use Your Information',
                      'We use your data to: provide educational services, process payments and enrollments, issue certificates and credentials, improve platform functionality, send course updates and notifications, comply with legal obligations, and ensure platform security.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '3. Cookies & Tracking',
                      'We use cookies for authentication, preferences, analytics, and platform functionality. You can manage cookie preferences in your browser settings. See our Cookie Policy for detailed information.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '4. Third-Party Services',
                      'We share data with trusted partners: Payment processors (Flutterwave, Paystack, M-Pesa, etc.) for secure transactions, AICERTS for course delivery and certification, analytics providers for platform improvement, and cloud hosting services for data storage.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '5. Data Security (ISO/IEC 27001)',
                      'As an ISO/IEC 27001 certified organization, we implement industry-leading security measures: encrypted data transmission (SSL/TLS), secure cloud infrastructure, regular security audits, access controls and authentication, and blockchain-verified certificates for credential integrity.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '6. Your Rights (POPIA Compliance)',
                      'Under the Protection of Personal Information Act (POPIA), you have the right to: access your personal data, correct inaccurate information, request data deletion, withdraw consent, object to data processing, and export your data in a portable format.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '7. Data Retention',
                      'We retain your data for as long as your account is active and for 7 years after account closure for legal compliance. Certificate records are maintained indefinitely on the blockchain for verification purposes.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '8. International Data Transfers',
                      'Your data may be processed in servers located in South Africa and other countries. We ensure adequate protection through contractual safeguards and compliance with international data protection standards.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '9. Children\'s Privacy',
                      'Our services are not intended for users under 16 years of age. We do not knowingly collect data from children. If you believe we have inadvertently collected such data, contact us immediately.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '10. Changes to Privacy Policy',
                      'We may update this policy to reflect changes in our practices or legal requirements. We will notify you of significant changes via email or platform notifications.',
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
                            'Privacy Concerns or Data Requests?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contact our Data Protection Officer at info@hosiacademy.com or write to us at Montecasino Boulevard, Fourways, South Africa.',
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
        const SizedBox(height: 6),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.8),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
