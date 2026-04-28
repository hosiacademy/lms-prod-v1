import 'package:flutter/material.dart';
import 'package:frontend/src/core/theme/app_theme.dart';
import '../shared/benefit_item.dart';

class BenefitsGridSection extends StatelessWidget {
  const BenefitsGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    // AppTheme brand colours only — professional, on-brand
    final items = [
      BenefitItem(
        icon: Icons.rocket_launch_rounded,
        title: 'Career-Focused Skills',
        description: 'Learn what African employers need today.',
        cardColor: AppTheme.hosiPeach,
      ),
      BenefitItem(
        icon: Icons.phone_android_rounded,
        title: 'Mobile-First & Offline',
        description: 'Study anywhere – even with low data.',
        cardColor: AppTheme.successGreen,
      ),
      BenefitItem(
        icon: Icons.workspace_premium_rounded,
        title: 'Internationally Recognised Certificates',
        description: 'Boost your CV with verified credentials.',
        cardColor: AppTheme.hosiBrown,
      ),
      BenefitItem(
        icon: Icons.verified_rounded,
        title: 'Blockchain-Verified Certification',
        description: 'Blockchain-verified credentials recognized globally.',
        cardColor: AppTheme.hosiPeach,
      ),
      BenefitItem(
        icon: Icons.security_rounded,
        title: 'ISO/IEC 27001 Certified Provider',
        description: 'Training that meets international security standards.',
        cardColor: AppTheme.successGreen,
      ),
      BenefitItem(
        icon: Icons.group_rounded,
        title: 'Thriving Community',
        description: 'Connect with peers & mentors across Africa.',
        cardColor: AppTheme.hosiBrown,
      ),
    ];

    if (isSmallScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: items
              .map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: b,
                  ))
              .toList(),
        ),
      );
    }

    // Desktop: strict 3 × 2 grid
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          IntrinsicHeight(child: _buildRow(items.sublist(0, 3))),
          const SizedBox(height: 16),
          IntrinsicHeight(child: _buildRow(items.sublist(3, 6))),
        ],
      ),
    );
  }

  Widget _buildRow(List<BenefitItem> rowItems) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rowItems.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: rowItems[i]),
        ],
      ],
    );
  }
}
