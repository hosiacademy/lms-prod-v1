import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatisticsSection extends StatelessWidget {
  final ThemeData theme;

  const StatisticsSection({super.key, required this.theme});

  Widget _buildStatItem({required IconData icon, required String label}) {
    final colors = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: colors.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;
    final isMediumScreen = screenWidth >= 768 && screenWidth < 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 40 : 60,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Why Thousands Choose Hosi Academy',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: isSmallScreen ? 20 : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Join a global community of learners transforming their careers',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontSize: isSmallScreen ? 14 : 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 32 : 40),

          // Mobile: 2 columns grid
          if (isSmallScreen)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 32,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildStatItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Active Learners',
                ),
                _buildStatItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Expert-Led Courses',
                ),
                _buildStatItem(
                  icon: Icons.trending_up_rounded,
                  label: 'Career Success',
                ),
                _buildStatItem(
                  icon: Icons.verified_rounded,
                  label: 'Industry Certifications',
                ),
                _buildStatItem(
                  icon: Icons.schedule_rounded,
                  label: 'Flexible Learning',
                ),
                _buildStatItem(
                  icon: Icons.public_rounded,
                  label: 'Global Community',
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0)

          // Tablet: 3 columns, 2 rows
          else if (isMediumScreen)
            Column(
              children: [
                Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatItem(
                      icon: Icons.people_alt_rounded,
                      label: 'Active Learners',
                    ),
                    _buildStatItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Expert-Led Courses',
                    ),
                    _buildStatItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Career Success',
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatItem(
                      icon: Icons.verified_rounded,
                      label: 'Industry Certifications',
                    ),
                    _buildStatItem(
                      icon: Icons.schedule_rounded,
                      label: 'Flexible Learning',
                    ),
                    _buildStatItem(
                      icon: Icons.public_rounded,
                      label: 'Global Community',
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0)

          // Desktop: Single row with all 6 items
          else
            Wrap(
              spacing: 40,
              runSpacing: 40,
              alignment: WrapAlignment.center,
              children: [
                _buildStatItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Active Learners',
                ),
                _buildStatItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Expert-Led Courses',
                    ),
                _buildStatItem(
                  icon: Icons.trending_up_rounded,
                  label: 'Career Success',
                ),
                _buildStatItem(
                  icon: Icons.verified_rounded,
                  label: 'Industry Certifications',
                ),
                _buildStatItem(
                  icon: Icons.schedule_rounded,
                  label: 'Flexible Learning',
                ),
                _buildStatItem(
                  icon: Icons.public_rounded,
                  label: 'Global Community',
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
