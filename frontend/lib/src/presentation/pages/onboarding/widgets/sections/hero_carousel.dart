import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../data/models/course.dart';
import '../../../../../core/services/currency_service.dart';

/// Hero Carousel Section - Shows courses with LOCAL ASSET IMAGES
class HeroCarouselSection extends StatefulWidget {
  final bool isLoading;
  final String? courseError;
  final List<Course> courses;
  final Function(Course)? onEnrollPressed;
  final VoidCallback? onExploreCourses;
  final Function(Course)? onCardTapped;

  const HeroCarouselSection({
    super.key,
    this.isLoading = false,
    this.courseError,
    this.courses = const [],
    this.onEnrollPressed,
    this.onExploreCourses,
    this.onCardTapped,
  });

  @override
  State<HeroCarouselSection> createState() => _HeroCarouselSectionState();
}

class _HeroCarouselSectionState extends State<HeroCarouselSection> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  static const _courseImages = [
    'assets/images/onboarding/course_1.jpg',
    'assets/images/AI_2.png',  // Replaced: Classroom with AI robot
    'assets/images/AI_1.png',  // Replaced: Was "ARTIFICIAL TENELIGENCE" (wrong spelling)
    'assets/images/onboarding/course_4.jpg',
    'assets/images/onboarding/course_5.jpg',
    'assets/images/onboarding/course_6.jpg',
    'assets/images/onboarding/course_7.jpg',
    'assets/images/AI_3.png',  // Replaced: Was "Path to AI Certs" inscription
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_pageController.hasClients) return;
      // Use actual count (or 8 placeholders if courses haven't loaded yet)
      final coursesCount = widget.courses.isNotEmpty ? widget.courses.length : 8;
      final maxPages = coursesCount * 10;
      if (_currentPage >= maxPages - 1) {
        _pageController.jumpToPage(0);
        _currentPage = 0;
        return;
      }
      final nextPage = _currentPage + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
      _currentPage = nextPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 38, bottom: 53),
        height: 400,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayCourses =
        widget.courses.isNotEmpty ? widget.courses : _getPlaceholderCourses();

    final screenWidth = MediaQuery.of(context).size.width;
    final carouselHeight = screenWidth < 600 ? 380.0 : 520.0;

    return Container(
      margin: EdgeInsets.only(
        top: screenWidth < 600 ? 24 : 48,
        bottom: screenWidth < 600 ? 32 : 63,
        left: 8,
        right: 8,
      ),
      height: carouselHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: PageView.builder(
          controller: _pageController,
          itemCount: displayCourses.length * 10, // Infinite scroll effect
          onPageChanged: (page) => _currentPage = page,
          itemBuilder: (context, index) {
            final courseIndex = index % displayCourses.length;
            final course = displayCourses[courseIndex];
            final imagePath = _courseImages[courseIndex % _courseImages.length];
            return _buildCourseCard(context, theme, course, imagePath);
          },
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, ThemeData theme, Course course, String imagePath) {
    return GestureDetector(
      onTap: widget.onCardTapped != null
          ? () => widget.onCardTapped!(course)
          : (widget.onEnrollPressed != null ? () => widget.onEnrollPressed!(course) : null),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.image, size: 64, color: theme.colorScheme.onSurface),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.2, 0.5, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.certificateBadgeUrl != null &&
                    course.certificateBadgeUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 20,
                            color: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Certified',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  course.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                if (course.price != null)
                  Text(
                    'From ${CurrencyService.instance.formatUSDAmount(course.price!)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onEnrollPressed != null ? () => widget.onEnrollPressed!(course) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Enroll Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    if (widget.onExploreCourses != null)
                      GestureDetector(
                        onTap: widget.onExploreCourses,
                        child: Text(
                          "Explore Courses",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Course> _getPlaceholderCourses() {
    return List.generate(
      8,
      (index) => Course(
        id: 'placeholder_$index',
        title: 'Master AI & Technology: Build the Future',
        featureImageUrl: null,
        certificateBadgeUrl: null,
      ),
    );
  }
}
