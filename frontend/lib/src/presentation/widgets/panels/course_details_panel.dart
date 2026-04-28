import 'package:flutter/material.dart';
import '../../../data/models/course.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/services/currency_service.dart';
import 'bulk_enrollment_panel.dart';

/// Course details panel with tabbed content (Overview, Curriculum, Instructor, Reviews)
class CourseDetailsPanel extends StatefulWidget {
  final Course course;

  const CourseDetailsPanel({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailsPanel> createState() => _CourseDetailsPanelState();
}

class _CourseDetailsPanelState extends State<CourseDetailsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWishlisted = false;
  bool _isInCart = false;
  bool _isLoading = true;
  bool _isEnrolling = false;
  Map<String, dynamic>? _courseDetails;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Check if course is in wishlist or cart
    _isWishlisted = wishlistService.hasCourse(widget.course.id);
    _isInCart = cartService.hasCourse(widget.course.id);
    _loadCourseDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseDetails() async {
    try {
      // TODO: Implement API call to get full course details
      // final details = await ApiClient.getCourseDetails(widget.course.id);

      setState(() {
        _courseDetails = {}; // Replace with actual API data
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isEnrolling) {
      return BulkEnrollmentPanel(courses: [widget.course]);
    }

    return Column(
      children: [
        // Course Header with Image
        _buildCourseHeader(theme, colors),

        // Tabs
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurface,
            indicatorColor: colors.primary,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Curriculum'),
              Tab(text: 'Instructor'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(theme, colors),
              _buildCurriculumTab(theme, colors),
              _buildInstructorTab(theme, colors),
              _buildReviewsTab(theme, colors),
            ],
          ),
        ),

        // Action Bar (Enroll/Add to Cart/Wishlist)
        _buildActionBar(theme, colors),
      ],
    );
  }

  Widget _buildCourseHeader(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Image
        if (widget.course.featureImageUrl != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.course.featureImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: colors.surfaceContainerHighest,
                  child: const Icon(Icons.school, size: 60),
                ),
              ),
            ),
          ),

        // Course Title and Meta
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.course.displayTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Rating and Student Count
              Row(
                children: [
                  if (widget.course.rating != null) ...[
                    Icon(Icons.star, size: 18, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      widget.course.rating!.toStringAsFixed(1),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (widget.course.studentCount != null) ...[
                    Icon(Icons.people_outline,
                        size: 18, color: colors.onSurface),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatStudentCount(widget.course.studentCount!)} students',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ],
              ),

              // Instructor
              if (widget.course.instructorName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (widget.course.instructorAvatar != null)
                      CircleAvatar(
                        radius: 14,
                        backgroundImage:
                            NetworkImage(widget.course.instructorAvatar!),
                      )
                    else
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: colors.primaryContainer,
                        child:
                            Icon(Icons.person, size: 18, color: colors.primary),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      widget.course.instructorName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],

              // Price
              if (widget.course.price != null) ...[
                const SizedBox(height: 12),
                Text(
                  CurrencyService.instance.formatPrice(widget.course.price ?? 0.0),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(ThemeData theme, ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'About This Course',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.course.description ?? 'No description available.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          // What You'll Learn
          Text(
            'What You\'ll Learn',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildLearningOutcomes(theme, colors),

          const SizedBox(height: 24),

          // Course Details
          Text(
            'Course Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCourseDetails(theme, colors),
        ],
      ),
    );
  }

  Widget _buildLearningOutcomes(ThemeData theme, ColorScheme colors) {
    // TODO: Get learning outcomes from API
    final outcomes = [
      'Master fundamental concepts',
      'Build practical skills',
      'Complete hands-on projects',
      'Earn a certificate of completion',
    ];

    return Column(
      children: outcomes
          .map((outcome) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: colors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        outcome,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCourseDetails(ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
                Icons.access_time,
                'Duration',
                widget.course.durationHours != null
                    ? '${widget.course.durationHours} hours'
                    : 'Self-paced',
                theme,
                colors),
            const Divider(),
            _buildDetailRow(Icons.signal_cellular_alt, 'Level', 'All levels',
                theme, colors),
            const Divider(),
            _buildDetailRow(
                Icons.language, 'Language', 'English', theme, colors),
            const Divider(),
            _buildDetailRow(
                Icons.closed_caption, 'Subtitles', 'Available', theme, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurface),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumTab(ThemeData theme, ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Curriculum',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Curriculum information will be loaded from the API.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // TODO: Implement curriculum sections/modules from API
          _buildCurriculumPlaceholder(theme, colors),
        ],
      ),
    );
  }

  Widget _buildCurriculumPlaceholder(ThemeData theme, ColorScheme colors) {
    return Column(
      children: List.generate(3, (sectionIndex) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Text(
                '${sectionIndex + 1}',
                style: TextStyle(
                    color: colors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              'Section ${sectionIndex + 1}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle:
                Text('TODO: Load from API', style: theme.textTheme.bodySmall),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Module content will be displayed here once API is integrated.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInstructorTab(ThemeData theme, ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructor Profile
          Row(
            children: [
              if (widget.course.instructorAvatar != null)
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      NetworkImage(widget.course.instructorAvatar!),
                )
              else
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(Icons.person, size: 40, color: colors.primary),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.instructorName ?? 'Instructor',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Course Instructor',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Instructor Bio
          Text(
            'About the Instructor',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Instructor biography and credentials will be loaded from the API.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          // Instructor Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInstructorStat(
                      Icons.school, 'Courses', 'TODO', theme, colors),
                  const Divider(),
                  _buildInstructorStat(
                      Icons.people, 'Students', 'TODO', theme, colors),
                  const Divider(),
                  _buildInstructorStat(
                      Icons.star, 'Rating', 'TODO', theme, colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorStat(IconData icon, String label, String value,
      ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(ThemeData theme, ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary
          _buildRatingSummary(theme, colors),

          const SizedBox(height: 24),

          // Reviews List
          Text(
            'Student Reviews',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Reviews will be loaded from the API.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          // TODO: Load actual reviews from API
          _buildReviewPlaceholder(theme, colors),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Overall Rating
            Column(
              children: [
                Text(
                  widget.course.rating?.toStringAsFixed(1) ?? 'N/A',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 20,
                      color: index < (widget.course.rating?.floor() ?? 0)
                          ? Colors.amber[700]
                          : colors.outlineVariant,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Course Rating',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 32),

            // Rating Breakdown
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final starCount = 5 - index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text('$starCount', style: theme.textTheme.bodySmall),
                        const SizedBox(width: 4),
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: 0.0, // TODO: Get from API
                            backgroundColor: colors.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('0%', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewPlaceholder(ThemeData theme, ColorScheme colors) {
    return Column(
      children: List.generate(2, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      child: Icon(Icons.person, color: colors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Name',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Row(
                                children: List.generate(
                                    5,
                                    (i) => Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber[700],
                                        )),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '2 days ago',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Review content will be loaded from the API.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionBar(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wishlist Button
          IconButton(
            onPressed: _toggleWishlist,
            icon: Icon(
              _isWishlisted ? Icons.bookmark : Icons.bookmark_border,
              color: _isWishlisted ? colors.primary : colors.onSurface,
            ),
            tooltip: _isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerHighest,
              padding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(width: 12),

          // Add to Cart Button
          if (!_isInCart)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Cart'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (!_isInCart) const SizedBox(width: 12),

          // Enroll Now Button
          Expanded(
            child: ElevatedButton(
              onPressed: _enrollNow,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isInCart ? 'Enroll Now' : 'Enroll Now',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStudentCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Future<void> _toggleWishlist() async {
    try {
      if (_isWishlisted) {
        // Remove from wishlist
        final success = await wishlistService.removeCourse(widget.course.id);
        if (success && mounted) {
          setState(() {
            _isWishlisted = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from wishlist')),
          );
        }
      } else {
        // Add to wishlist
        final success = await wishlistService.addCourse(widget.course);
        if (success && mounted) {
          setState(() {
            _isWishlisted = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to wishlist')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addToCart() async {
    try {
      if (await cartService.addCourse(widget.course)) {
        if (mounted) {
          setState(() {
            _isInCart = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to cart')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course already in cart')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _enrollNow() {
    setState(() => _isEnrolling = true);
  }
}
