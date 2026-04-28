// lib/src/presentation/widgets/cards/enrolled_course_card.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class EnrolledCourseCard extends StatelessWidget {
  final String title;
  final String instructor;
  final double progress; // 0.0 to 1.0
  final int completedModules;
  final int totalModules;
  final VoidCallback onContinue;

  const EnrolledCourseCard({
    super.key,
    required this.title,
    required this.instructor,
    required this.progress,
    required this.completedModules,
    required this.totalModules,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = (progress * 100).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by $instructor',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.7), // FIXED
                        ),
                      ),
                    ],
                  ),
                ),
                CircularPercentIndicator(
                  radius: 32,
                  lineWidth: 6,
                  percent: progress,
                  center: Text(
                    '$percent%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  progressColor: colorScheme.primary,
                  backgroundColor:
                      colorScheme.primary.withValues(alpha: 0.2), // FIXED
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$completedModules of $totalModules modules completed',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onContinue,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue Learning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
