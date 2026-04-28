import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StrategicPartnersSection extends StatelessWidget {
  const StrategicPartnersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: 20,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            const SizedBox(width: 8),
            _MeritPoint(
              icon: Icons.verified_user_rounded,
              text: 'Globally Recognized AI & Blockchain Certifications',
              colors: colors,
            ),
            const SizedBox(width: 16),
            _MeritPoint(
              icon: Icons.rocket_launch_rounded,
              text: 'Instant Enrollment + Auto-Login',
              colors: colors,
            ),
            const SizedBox(width: 16),
            _MeritPoint(
              icon: Icons.trending_up_rounded,
              text: 'Role-Based Training for African Industry',
              colors: colors,
            ),
            const SizedBox(width: 16),
            _MeritPoint(
              icon: Icons.badge_rounded,
              text: 'Digital Badges & Verified Certificates',
              colors: colors,
            ),
            const SizedBox(width: 16),
            _MeritPoint(
              icon: Icons.school_rounded,
              text: 'Africa-First Skills for Career Growth',
              colors: colors,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _MeritPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colors;

  const _MeritPoint({
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 400)),
        SlideEffect(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      ],
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.secondary.withValues(alpha: 0.9),
                    colors.tertiary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: colors.secondary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: colors.onSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: colors.shadow.withValues(alpha: 0.4),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
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
}
