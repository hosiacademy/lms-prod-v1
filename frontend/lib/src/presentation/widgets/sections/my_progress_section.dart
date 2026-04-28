// lib/src/presentation/widgets/sections/my_progress_section.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class MyProgressSection extends StatelessWidget {
  final double overallProgress;
  final int completedCourses;
  final int totalCourses;
  final int badgesEarned;

  const MyProgressSection({
    super.key,
    required this.overallProgress,
    required this.completedCourses,
    required this.totalCourses,
    required this.badgesEarned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (overallProgress * 100).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Learning Progress',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              lineHeight: 12,
              percent: overallProgress,
              // FIXED: Use theme.colorScheme.primary directly with opacity
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              progressColor: theme.colorScheme.primary,
              animation: true,
              animationDuration: 1200,
              barRadius: const Radius.circular(10),
              center: Text(
                '$percent%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat(
                    'Courses Completed', '$completedCourses/$totalCourses'),
                _buildStat('Badges Earned', '$badgesEarned',
                    icon: Icons.emoji_events),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {IconData? icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.amber),
              const SizedBox(width: 4),
            ],
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
