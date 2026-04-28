import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

void _showLegalModal(
  BuildContext context, {
  required String title,
  required List<_Section> sections,
  required String effectiveDate,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => _LegalModal(
      title: title,
      sections: sections,
      effectiveDate: effectiveDate,
    ),
  );
}

class _Section {
  final String heading;
  final List<String> paragraphs;
  const _Section(this.heading, this.paragraphs);
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy Policy
// ─────────────────────────────────────────────────────────────────────────────

class PrivacyPolicyModal {
  static void show(BuildContext context) {
    _showLegalModal(
      context,
      title: 'Privacy Policy',
      effectiveDate: 'Effective Date: 1 January 2025',
      sections: const [
        _Section('1. Introduction', [
          'Hosi Academy (Pty) Ltd ("Hosi Academy", "we", "us" or "our") is committed to protecting your privacy and handling your personal information with transparency and care.',
          'This Privacy Policy explains how we collect, use, store, share and protect personal information when you access or use our learning management system, website, mobile application and related services (collectively, the "Platform"). Please read it carefully.',
          'By registering for or using the Platform you acknowledge that you have read and understood this Policy. If you do not agree, please do not use our services.',
        ]),
        _Section('2. Information We Collect', [
          'Account & Identity Information: When you register we collect your full name, email address, phone number, country of residence, and a password.',
          'Profile Information: You may optionally provide a profile photo, job title, employer name, and educational background.',
          'Course & Learning Data: We collect records of courses you browse, enrol in, start, complete, assessment scores, certificates issued, and time spent on each module.',
          'Payment Information: Billing name, billing address, and payment method details. Full card numbers are processed directly by our PCI-DSS-certified payment partners (Payfast, Paystack, Stripe, Flutterwave, and others) and are never stored on our servers.',
          'Technical & Usage Data: IP address, browser type and version, device identifiers, operating system, referring URLs, page views, clickstream data, session duration, and error logs.',
          'Communications: Any messages you send to our support team, survey responses, or feedback you provide.',
          'Cookies & Similar Technologies: We use first-party and third-party cookies, pixel tags, and local storage as described in Section 8.',
        ]),
        _Section('3. How We Use Your Information', [
          'Provision of Services: To create and manage your account, deliver course content, track your progress, issue digital certificates, and process payments.',
          'Personalisation: To recommend relevant courses, learning paths, and content based on your profile and activity on the Platform.',
          'Communications: To send transactional messages (enrolment confirmations, payment receipts, certificate issuance), platform announcements, and, where you have opted in, promotional materials about new courses and offers.',
          'Analytics & Improvement: To understand how learners use the Platform, diagnose technical issues, measure content effectiveness, and improve our services.',
          'Safety & Security: To detect, investigate and prevent fraudulent transactions, unauthorised access, and other illegal activities.',
          'Legal Compliance: To comply with applicable laws and regulations, respond to lawful requests from public authorities, and enforce our Terms of Service.',
        ]),
        _Section('4. Legal Basis for Processing (GDPR / POPIA)', [
          'Performance of a Contract: Processing is necessary to deliver the services you have subscribed to.',
          'Legitimate Interests: Analytics, fraud prevention, platform security, and service improvement, provided these interests are not overridden by your rights.',
          'Consent: Marketing communications and non-essential cookies — you may withdraw consent at any time.',
          'Legal Obligation: Where processing is required to comply with applicable law.',
        ]),
        _Section('5. Sharing Your Information', [
          'We do not sell, rent or trade your personal information to third parties for their marketing purposes.',
          'Service Providers: We share data with vetted third-party vendors who assist us in operating the Platform, including cloud hosting providers (AWS, Google Cloud), payment processors, email delivery services, analytics providers, and customer support tools. All processors are bound by data processing agreements.',
          'Instructors & Facilitators: Course instructors may see aggregate learner progress data but do not have access to your payment details or password.',
          'Corporate Transactions: If Hosi Academy is involved in a merger, acquisition, or asset sale, your information may be transferred as part of that transaction. We will notify you before your information is transferred and becomes subject to a different privacy policy.',
          'Legal Requirements: We may disclose your information if required to do so by law, court order, or governmental authority.',
        ]),
        _Section('6. Data Retention', [
          'We retain your personal information for as long as your account is active or as needed to provide services.',
          'After account deletion we retain certain information for up to 7 years where required for legal, tax, and financial compliance purposes.',
          'Certificate records and enrolment history may be retained indefinitely to allow you to verify prior achievements, unless you specifically request deletion.',
          'Anonymised and aggregated analytics data that cannot identify you may be retained indefinitely.',
        ]),
        _Section('7. Data Security', [
          'We implement industry-standard administrative, technical, and physical safeguards to protect your personal information against unauthorised access, alteration, disclosure, or destruction.',
          'These measures include: TLS/SSL encryption for all data in transit, AES-256 encryption for sensitive data at rest, role-based access control, multi-factor authentication for staff systems, regular security audits and penetration testing.',
          'No method of transmission over the Internet or electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your data, we cannot guarantee absolute security.',
        ]),
        _Section('8. Cookies', [
          'We use cookies and similar tracking technologies to operate and improve the Platform.',
          'Essential Cookies: Required for authentication, session management, and security. Cannot be disabled.',
          'Analytics Cookies: Help us understand how learners interact with the Platform (e.g., Google Analytics). You may opt out via your browser settings or our cookie preference centre.',
          'Marketing Cookies: Used to deliver relevant advertisements on third-party platforms when you have provided consent.',
          'You can control cookies through your browser settings. Note that disabling certain cookies may affect Platform functionality.',
        ]),
        _Section('9. Your Rights', [
          'Subject to applicable law, you have the right to:',
          '• Access: Request a copy of the personal information we hold about you.',
          '• Rectification: Request correction of inaccurate or incomplete data.',
          '• Erasure: Request deletion of your personal information ("right to be forgotten"), subject to our legal retention obligations.',
          '• Restriction: Request that we limit how we process your data in certain circumstances.',
          '• Data Portability: Receive a structured, machine-readable copy of the data you have provided to us.',
          '• Objection: Object to processing based on legitimate interests, including direct marketing.',
          '• Withdraw Consent: Withdraw any consent you have given at any time without affecting the lawfulness of prior processing.',
          'To exercise any of these rights, please email privacy@hosi.co.za. We will respond within 30 days.',
        ]),
        _Section('10. Children\'s Privacy', [
          'The Platform is not directed to children under the age of 18. We do not knowingly collect personal information from anyone under 18.',
          'If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately at privacy@hosi.co.za and we will take steps to delete that information.',
        ]),
        _Section('11. International Data Transfers', [
          'Hosi Academy operates primarily in Africa. Where we transfer personal information outside your country of residence, we ensure appropriate safeguards are in place, including standard contractual clauses approved by the relevant data protection authority.',
        ]),
        _Section('12. Changes to This Policy', [
          'We may update this Privacy Policy from time to time. We will notify you of material changes by posting the new policy on the Platform and, where appropriate, sending you an email notification.',
          'Your continued use of the Platform after any changes constitutes your acceptance of the updated Policy.',
        ]),
        _Section('13. Contact Us', [
          'If you have questions, concerns, or requests regarding this Privacy Policy, please contact our Data Protection Officer:',
          'Email: privacy@hosi.co.za',
          'Phone: +27 (0) 11 023 1995',
          'Address: Hosi Academy (Pty) Ltd, Johannesburg, South Africa',
          'If you are not satisfied with our response, you have the right to lodge a complaint with the Information Regulator (South Africa) or your local data protection authority.',
        ]),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Terms & Conditions
// ─────────────────────────────────────────────────────────────────────────────

class TermsConditionsModal {
  static void show(BuildContext context) {
    _showLegalModal(
      context,
      title: 'Terms & Conditions',
      effectiveDate: 'Effective Date: 1 January 2025',
      sections: const [
        _Section('1. Acceptance of Terms', [
          'These Terms & Conditions ("Terms") govern your access to and use of the Hosi Academy learning management platform, website, and all related services (collectively, the "Platform"), operated by Hosi Academy (Pty) Ltd, a company incorporated in South Africa ("Hosi Academy", "we", "us" or "our").',
          'By creating an account, enrolling in a course, or otherwise using the Platform, you agree to be bound by these Terms and our Privacy Policy. If you do not agree to these Terms, you must not use the Platform.',
          'We reserve the right to amend these Terms at any time. Continued use of the Platform following notice of changes constitutes acceptance of the revised Terms.',
        ]),
        _Section('2. Account Registration', [
          'To access most features of the Platform you must create an account by providing accurate, current and complete information.',
          'You are responsible for maintaining the confidentiality of your password and for all activity that occurs under your account. You must notify us immediately at support@hosi.co.za of any unauthorised use of your account.',
          'One person may not maintain more than one free account. Accounts are non-transferable.',
          'We reserve the right to suspend or terminate accounts that contain false information, violate these Terms, or have been inactive for an extended period.',
        ]),
        _Section('3. Courses and Content', [
          'Hosi Academy offers self-paced professional certification courses, live masterclasses, learnerships, and industry training programmes in partnership with AICERTS and other accredited bodies.',
          'Course content is for personal, non-commercial educational use only. You may not redistribute, resell, broadcast, or publicly display course materials without our prior written consent.',
          'Course availability, content, pricing, and scheduling are subject to change without notice. We will endeavour to notify enrolled learners of material changes.',
          'Completion of a course and the award of a certificate is conditional on satisfying all assessment requirements as set out in the respective course specifications.',
          'Digital certificates issued by Hosi Academy remain the property of Hosi Academy. Falsification or misrepresentation of certificates is strictly prohibited.',
        ]),
        _Section('4. Payment, Pricing and Refunds', [
          'All prices are displayed in your local currency where available, with the equivalent USD price shown for reference. Prices are inclusive of applicable taxes unless otherwise stated.',
          'Payment must be made in full prior to accessing paid course content. We accept payment via the methods listed on our checkout page, including major credit/debit cards, mobile money, and regional payment solutions.',
          'Refund Policy: You may request a full refund within 7 days of enrolment, provided you have not completed more than 20% of the course content. After 7 days or once 20% or more of the course has been completed, no refund will be issued.',
          'Refund requests must be submitted to billing@hosi.co.za with your order reference number. Approved refunds will be processed within 10 business days to the original payment method.',
          'Bundle and promotional pricing is non-refundable once any course within the bundle has been started.',
          'In the event of a course cancellation by Hosi Academy, enrolled learners will receive a full refund or a credit of equivalent value, at their election.',
        ]),
        _Section('5. Intellectual Property', [
          'All content on the Platform — including but not limited to course materials, videos, documents, graphics, logos, and software — is the exclusive property of Hosi Academy, its licensors, or course content providers, and is protected by copyright, trademark, and other intellectual property laws.',
          'Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable licence to access and use Platform content solely for your personal educational purposes.',
          'You may not copy, modify, create derivative works from, reverse engineer, decompile, or otherwise attempt to extract the source code of the Platform or its content.',
          'User-generated content (forum posts, assignment submissions) remains your property, but you grant Hosi Academy a worldwide, royalty-free licence to use, reproduce, and display such content for Platform operation and improvement.',
        ]),
        _Section('6. Acceptable Use', [
          'You agree not to use the Platform to:',
          '• Upload, post, or transmit content that is unlawful, harmful, threatening, abusive, harassing, defamatory, obscene, or otherwise objectionable.',
          '• Impersonate any person or entity, or falsely claim an affiliation with any person or entity.',
          '• Engage in any form of academic dishonesty, including sharing assessment answers, using unauthorised aids, or submitting work that is not your own.',
          '• Use automated tools (bots, scrapers) to access, collect, or copy Platform content without our express written permission.',
          '• Attempt to gain unauthorised access to any portion of the Platform, other accounts, or related systems.',
          '• Transmit spam, chain letters, or other unsolicited communications.',
          'Violation of these provisions may result in immediate account suspension or termination, and may be reported to law enforcement authorities.',
        ]),
        _Section('7. Third-Party Services', [
          'The Platform may contain links to or integrations with third-party websites, tools, and services. These are provided for convenience only.',
          'Hosi Academy does not endorse and is not responsible for the content, privacy practices, or accuracy of any third-party websites or services. Accessing third-party services is at your own risk and subject to their respective terms and privacy policies.',
        ]),
        _Section('8. Disclaimers', [
          'THE PLATFORM AND ALL CONTENT ARE PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED.',
          'We do not warrant that the Platform will be uninterrupted, error-free, or free of viruses or other harmful components. We do not guarantee that any course will lead to specific employment outcomes, salary improvements, or professional certifications from third-party bodies.',
          'Course content represents the views of instructors and content providers and does not constitute professional, legal, financial, or medical advice.',
        ]),
        _Section('9. Limitation of Liability', [
          'To the maximum extent permitted by applicable law, Hosi Academy, its directors, employees, agents, and partners shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or goodwill, arising out of or in connection with your use of the Platform.',
          'Our total cumulative liability to you for all claims arising from or related to your use of the Platform shall not exceed the total amount paid by you to Hosi Academy in the 12 months preceding the event giving rise to the claim.',
          'Nothing in these Terms limits our liability for death or personal injury caused by our negligence, fraud, or any other liability that cannot be excluded or limited by law.',
        ]),
        _Section('10. Indemnification', [
          'You agree to defend, indemnify, and hold harmless Hosi Academy and its officers, directors, employees, agents, and partners from any claims, damages, obligations, losses, liabilities, costs, or expenses (including attorney\'s fees) arising from: (a) your violation of these Terms; (b) your use of the Platform; or (c) your violation of any third-party rights.',
        ]),
        _Section('11. Termination', [
          'You may close your account at any time by contacting support@hosi.co.za. Upon account closure, your access to paid content will cease immediately.',
          'We may suspend or terminate your access to the Platform immediately, without prior notice or liability, if you breach these Terms or if we are required to do so by law.',
          'Upon termination, Sections 5 (Intellectual Property), 8 (Disclaimers), 9 (Limitation of Liability), 10 (Indemnification), and 13 (Governing Law) shall survive.',
        ]),
        _Section('12. Governing Law and Dispute Resolution', [
          'These Terms shall be governed by and construed in accordance with the laws of the Republic of South Africa, without regard to conflict-of-law principles.',
          'Any dispute arising from these Terms or your use of the Platform shall first be attempted to be resolved through good-faith negotiation. If not resolved within 30 days, the dispute shall be submitted to binding arbitration under the Arbitration Foundation of Southern Africa (AFSA) rules.',
          'Nothing in this clause prevents either party from seeking urgent or interim relief from a court of competent jurisdiction.',
        ]),
        _Section('13. Entire Agreement', [
          'These Terms, together with our Privacy Policy and any other policies or guidelines posted on the Platform, constitute the entire agreement between you and Hosi Academy regarding your use of the Platform and supersede all prior agreements, representations, and understandings.',
        ]),
        _Section('14. Contact', [
          'For any questions about these Terms, please contact us:',
          'Email: legal@hosi.co.za',
          'Phone: +27 (0) 11 023 1995',
          'Address: Hosi Academy (Pty) Ltd, Johannesburg, South Africa',
        ]),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared modal widget
// ─────────────────────────────────────────────────────────────────────────────

class _LegalModal extends StatelessWidget {
  final String title;
  final String effectiveDate;
  final List<_Section> sections;

  const _LegalModal({
    required this.title,
    required this.effectiveDate,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 48,
        vertical: isSmall ? 20 : 40,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 780),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(28, 20, 16, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF172E3D),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle( 
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: isSmall ? 18 : 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          effectiveDate,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────
            Flexible(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final section in sections) ...[
                        _buildSection(context, section),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© ${DateTime.now().year} Hosi Academy (Pty) Ltd',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF172E3D),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      backgroundColor:
                          const Color(0xFFF79150).withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, _Section section) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section heading
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF172E3D).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: const Color(0xFFF79150),
                width: 3,
              ),
            ),
          ),
          child: Text(
            section.heading,
            style: TextStyle( 
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: const Color(0xFF172E3D),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Paragraphs
        for (final para in section.paragraphs) ...[
          Text(
            para,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.65,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
