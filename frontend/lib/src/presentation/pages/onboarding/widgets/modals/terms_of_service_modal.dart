import 'package:flutter/material.dart';

class TermsOfServiceModal extends StatelessWidget {
  const TermsOfServiceModal({super.key});

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
                  'Terms of Service',
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
                      '1. Acceptance of Terms',
                      'By accessing and using Hosi Academy\'s platform, you accept and agree to be bound by these Terms of Service. If you do not agree with these terms, please do not use our services.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '2. Account Registration',
                      'You must provide accurate, complete, and current information during registration. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '3. Course Enrollment & Access',
                      'Course access is granted upon successful payment and enrollment. Course materials are for personal, non-commercial use only. Sharing course content or login credentials is prohibited and may result in account termination.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '4. Payment & Refunds',
                      'All payments are processed securely through our payment partners. Refund requests must be submitted within 7 days of enrollment for courses where you haven\'t accessed course materials. Learnerships and specialized programs may have different refund policies.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '5. Intellectual Property',
                      'All course content, including videos, documents, and assessments, are protected by copyright and belong to Hosi Academy or its licensors. You may not reproduce, distribute, or create derivative works without prior written permission.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '6. User Conduct',
                      'You agree not to: (a) use the platform for any unlawful purpose, (b) harass or harm other users, (c) upload malicious code or viruses, (d) attempt to gain unauthorized access to systems, or (e) interfere with platform operations.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '7. Certificates & Credentials',
                      'Certificates are awarded upon successful course completion. Blockchain-verified certificates can be verified through our verification system. Misrepresenting or falsifying certificates is prohibited.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '8. Platform Availability',
                      'We strive to maintain 99.9% uptime but do not guarantee uninterrupted access. We may suspend services for maintenance, updates, or security reasons with prior notice when possible.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '9. Termination',
                      'We reserve the right to suspend or terminate accounts that violate these terms. Upon termination, your access to courses and materials will be revoked.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '10. Limitation of Liability',
                      'Hosi Academy is not liable for indirect, incidental, or consequential damages arising from platform use. Our total liability is limited to the amount you paid for the service.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '11. Governing Law',
                      'These terms are governed by the laws of the Republic of South Africa. Any disputes will be resolved in South African courts.',
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      theme,
                      colors,
                      '12. Changes to Terms',
                      'We may update these terms at any time. Continued use of the platform after changes constitutes acceptance of the new terms.',
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
                            'Questions About These Terms?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contact us at info@hosiacademy.com or call +27110231995',
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
