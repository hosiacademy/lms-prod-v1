import 'package:flutter/material.dart';

class SupportModal extends StatelessWidget {
  const SupportModal({super.key});

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
                  'Support Center',
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
                    _buildSupportCategory(
                      theme,
                      colors,
                      Icons.rocket_launch,
                      'Getting Started',
                      [
                        'Create your account and complete your profile',
                        'Browse course catalog and learnerships',
                        'Enroll in courses using any African payment method',
                        'Download mobile app for offline access',
                        'Join community forums and connect with peers',
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSupportCategory(
                      theme,
                      colors,
                      Icons.school,
                      'Course Enrollment Help',
                      [
                        'Select course from catalog or AICerts partnership',
                        'Click "Enroll Now" and choose payment method',
                        'Complete payment via Flutterwave, M-Pesa, Paystack, etc.',
                        'Access course immediately after successful payment',
                        'Track progress from your dashboard',
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSupportCategory(
                      theme,
                      colors,
                      Icons.payment,
                      'Payment Assistance',
                      [
                        'We support 16+ African payment methods',
                        'Mobile money: M-Pesa, MTN, Airtel Money',
                        'Card payments: Visa, Mastercard, Verve',
                        'Bank transfers and USSD options available',
                        'Secure transactions with ISO/IEC 27001 compliance',
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSupportCategory(
                      theme,
                      colors,
                      Icons.badge,
                      'Certificates & Credentials',
                      [
                        'Certificates awarded upon course completion',
                        'Blockchain-verified for tamper-proof verification',
                        'Download PDF and digital badge versions',
                        'Share on LinkedIn and social media',
                        'Employers can verify at verify.hosi.academy',
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSupportCategory(
                      theme,
                      colors,
                      Icons.computer,
                      'Technical Requirements',
                      [
                        'Web: Chrome, Firefox, Safari, or Edge (latest versions)',
                        'Mobile: Android 8.0+ or iOS 13.0+',
                        'Internet: 2G or higher (offline mode available)',
                        'Storage: 500MB for mobile app',
                        'Resolution: 1280x720 minimum for optimal experience',
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSupportCategory(
                      theme,
                      colors,
                      Icons.help_outline,
                      'Common Issues',
                      [
                        'Can\'t login? Reset password or check email verification',
                        'Payment failed? Try another method or contact bank',
                        'Video not loading? Check internet or try offline mode',
                        'Certificate not received? Check "My Certificates" section',
                        'Still stuck? Contact us at info@hosiacademy.com',
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Contact Support CTA
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.support_agent, size: 48, color: colors.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need More Help?',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '24/7 Support: +27110231995\ninfo@hosiacademy.com',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
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

  Widget _buildSupportCategory(
    ThemeData theme,
    ColorScheme colors,
    IconData icon,
    String title,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
