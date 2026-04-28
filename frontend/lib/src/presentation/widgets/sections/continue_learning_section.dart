// lib/src/presentation/widgets/sections/continue_learning_section.dart
import 'package:flutter/material.dart';
import '../cards/enrolled_course_card.dart';

class ContinueLearningSection extends StatelessWidget {
  final List<Map<String, dynamic>>
      continueCourses; // mock data: [{title, instructor, progress, ...}]

  const ContinueLearningSection({super.key, required this.continueCourses});

  @override
  Widget build(BuildContext context) {
    if (continueCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Continue Learning',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: continueCourses.length,
            itemBuilder: (context, index) {
              final course = continueCourses[index];
              return SizedBox(
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: EnrolledCourseCard(
                    title: course['title'] ?? 'Course Title',
                    instructor: course['instructor'] ?? 'Instructor',
                    progress: course['progress'] ?? 0.0,
                    completedModules: course['completedModules'] ?? 0,
                    totalModules: course['totalModules'] ?? 10,
                    onContinue: () {
                      // TODO: Navigate to course detail
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
