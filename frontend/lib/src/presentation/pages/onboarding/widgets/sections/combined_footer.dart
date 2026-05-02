import 'package:flutter/material.dart';
import '../modals/privacy_policy_modal.dart';
import '../modals/terms_of_service_modal.dart';
import '../modals/partner_program_modal.dart';
import '../shared/footer_column.dart';

class CombinedFooterSection extends StatelessWidget {
  final Function(String) onShowOverlay;
  final VoidCallback onHideOverlay;

  const CombinedFooterSection({
    super.key,
    required this.onShowOverlay,
    required this.onHideOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Premium Navy Gradient Background
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0B1C2C),
        const Color(0xFF0F2438),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: screenWidth < 1200 ? 24 : screenWidth * 0.08,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1C2C),
        gradient: gradient,
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (screenWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandingColumn(context),
                    const SizedBox(height: 64),
                    _buildProgramsColumn(context),
                    const SizedBox(height: 48),
                    _buildEcosystemColumn(context),
                    const SizedBox(height: 48),
                    _buildContactColumn(context),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildBrandingColumn(context)),
                  const SizedBox(width: 48),
                  Expanded(flex: 2, child: _buildProgramsColumn(context)),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: _buildEcosystemColumn(context)),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: _buildContactColumn(context)),
                ],
              );
            },
          ),
          const SizedBox(height: 80),
          const Divider(color: Colors.white10),
          const SizedBox(height: 32),
          // Bottom Bar
          Text(
            '© 2026 Hosi Academy South Africa. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF79151),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text(
                'Hosi Academy',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Empowering Africa through AI & Technology',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildProgramsColumn(BuildContext context) {
    return _FooterColumn(
      title: 'PROGRAMS',
      items: const [
        'AI Masterclasses',
        'AI & Blockchain Learnerships',
        'Cybersecurity Learnerships',
        'Industry Training',
        'Custom Training',
      ],
      onTap: (item) {
        // Implement navigation or switch case
      },
    );
  }

  Widget _buildEcosystemColumn(BuildContext context) {
    return _FooterColumn(
      title: 'ECOSYSTEM',
      items: const [
        'Student Portal',
        'Expert Trainers',
        'Become a Partner',
        'About Us',
        'FAQ',
      ],
      onTap: (item) {
        if (item == 'Become a Partner') {
          PartnerProgramModal.show(context);
        }
      },
    );
  }

  Widget _buildContactColumn(BuildContext context) {
    return _FooterColumn(
      title: 'CONTACT & SUPPORT',
      items: const [
        'info@hosiacademy.com',
        'Contacts',
        'Privacy Policy',
        'Terms of Service',
      ],
      onTap: (item) {
        if (item == 'Privacy Policy') {
          showDialog(context: context, builder: (_) => const PrivacyPolicyModal());
        } else if (item == 'Terms of Service') {
          showDialog(context: context, builder: (_) => const TermsOfServiceModal());
        }
      },
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onTap;

  const _FooterColumn({
    required this.title,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: InkWell(
                onTap: () => onTap(item),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

