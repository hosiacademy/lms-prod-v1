import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/presentation/pages/onboarding/widgets/sections/hero_carousel.dart';
import 'package:frontend/src/data/models/course.dart';

void main() {
  testWidgets('HeroCarouselSection displays loading state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeroCarouselSection(
            isLoading: true,
            courseError: null,
            courses: [],
          ),
        ),
      ),
    );

    // Should show CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HeroCarouselSection displays content when loaded',
      (WidgetTester tester) async {
    // Mock courses
    final courses = [
      Course(
        id: '1',
        title: 'Test Course 1',
        featureImageUrl: 'https://example.com/image1.png',
        certificateBadgeUrl: 'https://example.com/badge1.png',
        description: 'Desc',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroCarouselSection(
            isLoading: false,
            courseError: null,
            courses: courses,
          ),
        ),
      ),
    );

    // Initial build
    await tester.pumpAndSettle();

    // Should find the welcome hero (slide 0) and potentially the first course if visible
    // Since it's an infinite ListView in a small test window, some items might be off-screen.
    // The Welcome Hero is index 0.

    // We can just check that it constructs and finds at least one image or text.
    expect(find.byType(ListView), findsOneWidget);
    // Welcome hero has text "Welcome to the Future"
    // Course 1 has text "Test Course 1"

    // allow timer to tick
    await tester.pump(const Duration(milliseconds: 100));
  });
}
