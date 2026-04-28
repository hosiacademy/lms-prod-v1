// lib/src/presentation/widgets/sections/featured_courses_section.dart
import 'package:flutter/material.dart';
import '../cards/course_card.dart';

class FeaturedCoursesSection extends StatelessWidget {
  final List<Map<String, dynamic>> featuredCourses;

  const FeaturedCoursesSection({super.key, required this.featuredCourses});

  @override
  Widget build(BuildContext context) {
    if (featuredCourses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Featured Courses',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: featuredCourses.length,
            itemBuilder: (context, index) {
              final course = featuredCourses[index];
              return SizedBox(
                width: 280,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CourseCard(
                    title: course['title'] ?? 'Featured Course',
                    instructor: course['instructor'] ?? 'Expert Instructor',
                    thumbnailUrl: course['thumbnail'] ??
                        'https://via.placeholder.com/280x157',
                    rating: course['rating'] ?? 4.8,
                    enrolledCount: course['enrolled'] ?? 1200,
                    onTap: () {
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
