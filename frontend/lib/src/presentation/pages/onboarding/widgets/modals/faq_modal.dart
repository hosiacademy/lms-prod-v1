import 'package:flutter/material.dart';

class FAQModal extends StatelessWidget {
  const FAQModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frequently Asked Questions',
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

            // FAQ List
            Expanded(
              child: ListView(
                children: const [
                  FAQItem(
                    question: 'What courses does Hosi Academy offer?',
                    answer:
                        'Hosi Academy specializes in AI, Blockchain, and Cybersecurity training. We offer internationally recognized certifications, industry-specific courses, corporate training programs, and learnerships aligned with African workforce needs.',
                  ),
                  FAQItem(
                    question: 'Are the certificates internationally recognized?',
                    answer:
                        'Yes! All our certificates are internationally recognized and blockchain-verified. We are an ISO/IEC 27001 certified training provider and partner with AICERTS for globally recognized AI and blockchain certifications.',
                  ),
                  FAQItem(
                    question: 'How do I enroll in a course?',
                    answer:
                        'Simply browse our course catalog, select your desired program, and complete the enrollment process. You can pay using any of our 16+ African payment methods including M-Pesa, Flutterwave, Paystack, and more.',
                  ),
                  FAQItem(
                    question: 'Can I learn offline?',
                    answer:
                        'Yes! Our mobile-first platform is designed for African learners with offline capabilities and low-data modes, allowing you to study anywhere, even with limited internet connectivity.',
                  ),
                  FAQItem(
                    question: 'What is blockchain certification?',
                    answer:
                        'Blockchain certification means your credentials are stored on the blockchain, making them tamper-proof, instantly verifiable, and globally recognized. Employers can verify your certificates in seconds.',
                  ),
                  FAQItem(
                    question: 'Do you offer corporate training?',
                    answer:
                        'Yes! We provide customized corporate training programs, professional masterclasses, and technical masterclasses tailored for businesses across Africa. Contact us for enterprise solutions.',
                  ),
                  FAQItem(
                    question: 'What are learnerships?',
                    answer:
                        'Learnerships are structured learning programs that combine theoretical knowledge with practical workplace experience, aligned with South African NQF standards and SETA requirements.',
                  ),
                  FAQItem(
                    question: 'How long do courses take to complete?',
                    answer:
                        'Course duration varies by program. Short courses may take 4-8 weeks, while comprehensive programs can span 3-12 months. You can learn at your own pace with our flexible learning system.',
                  ),
                  FAQItem(
                    question: 'What payment methods do you accept?',
                    answer:
                        'We accept 16+ payment methods including M-Pesa, MTN Mobile Money, Airtel Money, Flutterwave, Paystack, Stripe, PayPal, bank transfers, and many more African payment gateways.',
                  ),
                  FAQItem(
                    question: 'Can I get a refund?',
                    answer:
                        'Refund policies vary by course type. Generally, we offer full refunds within 7 days of enrollment if you haven\'t accessed course materials. Contact our support team for specific inquiries.',
                  ),
                  FAQItem(
                    question: 'Do you offer job placement assistance?',
                    answer:
                        'Yes! We connect graduates with our network of African employers, provide career guidance, and offer job placement support. Our community also includes peer mentoring and networking opportunities.',
                  ),
                  FAQItem(
                    question: 'Is there a mobile app?',
                    answer:
                        'Yes! Download our mobile app from Google Play Store or Apple App Store to access courses on-the-go with offline capabilities and low-data modes optimized for African networks.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItem({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.primary,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.answer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
