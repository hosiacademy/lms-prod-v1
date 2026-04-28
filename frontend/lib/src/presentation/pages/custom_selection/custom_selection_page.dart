import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../data/models/course.dart';
import '../../widgets/headers/enrollment_page_header.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/auth_service.dart';
import '../../widgets/modals/aicerts/multi_step_aicerts_custom_selection_modal.dart';
import '../../widgets/common/slide_in_panel.dart';
import '../../widgets/panels/course_details_panel.dart';
import '../../../core/services/concierge_service.dart';
import '../../widgets/aicerts/aicerts_image_widget.dart';
import '../../../core/services/aicerts_image_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomSelectionPage extends StatefulWidget {
  final String? initialView;
  final bool embedMode;
  final String? initialCourseId; // NEW: Pre-select a specific course

  const CustomSelectionPage({
    super.key,
    this.initialView,
    this.embedMode = false,
    this.initialCourseId,
  });

  @override
  State<CustomSelectionPage> createState() => _CustomSelectionPageState();
}

class _CustomSelectionPageState extends State<CustomSelectionPage> {
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  List<Map<String, dynamic>> _bundles = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  StreamSubscription? _cartSubscription;
  Set<String> _selectedCourseIds = {}; // Track selected courses for Custom Selection

  @override
  void initState() {
    super.initState();
    _loadCourses();
    CurrencyService.instance.initialize();
    CurrencyService.instance.addListener(_onCurrencyChanged);

    // Listen for cart updates
    _cartSubscription = cartService.cartUpdatedStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    CurrencyService.instance.removeListener(_onCurrencyChanged);
    _cartSubscription?.cancel();
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await ApiClient.get('/api/v1/courses/custom-selection-catalog/');

      if (response.data != null) {
        final List<dynamic> coursesJson = response.data['results'] ?? [];
        final List<dynamic> bundlesJson = response.data['bundles'] ?? [];

        final courses = coursesJson
            .map((json) => Course.fromJson(json as Map<String, dynamic>))
            .toList();

        if (!mounted) return;
        setState(() {
          _allCourses = courses;
          _filteredCourses = courses;
          _bundles = List<Map<String, dynamic>>.from(bundlesJson);
          _isLoading = false;
          
          // Pre-select the initial course if specified
          if (widget.initialCourseId != null) {
            _selectedCourseIds = {widget.initialCourseId!};
            // Show the multi-step modal for the pre-selected course
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCustomSelectionModalForPreSelectedCourse();
            });
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load courses: $e';
        _isLoading = false;
      });
    }
  }

  void _filterCourses() {
    setState(() {
      _filteredCourses = _allCourses.where((course) {
        return _searchQuery.isEmpty ||
            course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (course.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);
      }).toList();
    });
  }

  Future<void> _addToCart(Course course) async {
    if (await cartService.addCourse(course)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.title} added to cart'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addBundleToCart(Map<String, dynamic> bundle) async {
    // Actually bundles should be handled as a special item, but for now
    // we just add all individual courses from the bundle to the cart
    final List<dynamic> coursesData = bundle['courses'] ?? [];
    int addedCount = 0;

    for (var courseData in coursesData) {
      // Find the corresponding full course object or create a proxy
      final courseId = courseData['id'].toString();
      final existingCourse = _allCourses.firstWhere(
        (c) => c.id == courseId,
        orElse: () => Course(
          id: courseId,
          title: courseData['title'],
          featureImageUrl: AICERTSImageService.getFeatureImageUrl(courseData['image_url'] as String?),
          price: (bundle['price'] as num).toDouble() / coursesData.length,
          courseType: 'custom_selection',
        ),
      );

      if (await cartService.addCourse(existingCourse)) {
        addedCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Added $addedCount courses from "${bundle['title']}" to cart'),
          duration: const Duration(seconds: 3),
          backgroundColor: AppTheme.hosiPeach,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeFromCart(Course course) {
    cartService.removeCourse(course.id);
  }

  void _proceedToEnrollment() async {
    final currentCourses = cartService.courses;
    if (currentCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one course to your cart'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if user is authenticated
    final isAuthenticated = await AuthService.isAuthenticated();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MultiStepAICERTSCustomSelectionModal(
          courses: currentCourses,
          onEnrollmentComplete: () {
            cartService.clearCart();
            setState(() {});
          },
          allowPrefill: isAuthenticated, // Only pre-fill if logged in
        );
      },
    );
  }

  /// Show the Custom Selection modal for a pre-selected course (from onboarding page)
  void _showCustomSelectionModalForPreSelectedCourse() async {
    if (widget.initialCourseId == null || !mounted) return;
    
    final preSelectedCourse = _allCourses.firstWhere(
      (course) => course.id == widget.initialCourseId,
      orElse: () => _allCourses.first,
    );

    final isAuthenticated = await AuthService.isAuthenticated();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MultiStepAICERTSCustomSelectionModal(
          courses: [preSelectedCourse],
          onEnrollmentComplete: () {
            Navigator.of(context).pop(); // Close modal
            // Navigate back to previous page (onboarding)
            Navigator.of(context).maybePop();
          },
          allowPrefill: isAuthenticated,
        );
      },
    );
  }

  void _showCourseDetails(Course course) {
    ConciergeService.setPrompt('Architect a learning path for: ${course.title}');

    SlideInPanel.show(
      context,
      title: 'Course Details',
      child: CourseDetailsPanel(course: course),
    );
  }

  List<String> get _categories {
    final cats = _allCourses
        .map((c) => c.industry ?? 'General')
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList();
    cats.sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Column(
      children: [
        if (!widget.embedMode)
          const EnrollmentPageHeader(
            title: 'Custom Course Selection',
            subtitle:
                'Tailor your learning journey by building your own course combo',
          ),

        // Tabs and Filters
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _filterCourses();
                  },
                ),
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorView()
                  : _buildCoursesView(),
        ),

        // Global Cart Summary Bar
        _buildCartBar(colorScheme, theme),
      ],
    );

    if (widget.embedMode) return content;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: content,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Unknown error', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCourses,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesView() {
    if (_filteredCourses.isEmpty) {
      return const Center(child: Text('No courses match your criteria'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        childAspectRatio: 0.95,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        final isInCart = cartService.hasCourse(course.id);

        return _CourseCard(
          course: course,
          isInCart: isInCart,
          onAddToCart: () => _addToCart(course),
          onRemoveFromCart: () => _removeFromCart(course),
          onShowDetails: () => _showCourseDetails(course),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 50 * index))
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildBundlesView() {
    if (_bundles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: AppTheme.hosiPeach.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No bundles available right now.',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Check back soon for curated learning paths!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _bundles.length,
      itemBuilder: (context, index) {
        final bundle = _bundles[index];
        return _BundleCard(
          bundle: bundle,
          onAddToCart: () => _addBundleToCart(bundle),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 100 * index))
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildCartBar(ColorScheme colorScheme, ThemeData theme) {
    if (cartService.courses.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cartService.courses.length} Course${cartService.courses.length > 1 ? 's' : ''} Selected',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  ListenableBuilder(
                    listenable: CurrencyService.instance,
                    builder: (context, _) {
                      final total = cartService.calculateTotal();
                      return Text(
                        'Total: ${CurrencyService.instance.formatPrice(total)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            ElevatedButton(
              onPressed: _proceedToEnrollment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 8),
                  Text('Enroll Now',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 3.seconds, delay: 1.seconds),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final bool isInCart;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;
  final VoidCallback onShowDetails;

  const _CourseCard({
    required this.course,
    required this.isInCart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isInCart
              ? AppTheme.hosiPeach
              : colorScheme.outline.withValues(alpha: 0.1),
          width: isInCart ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onShowDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                _buildCourseImage(theme),
                if (isInCart)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.hosiPeach,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.displayTitle,
                      style: TextStyle(fontFamily: 'Poppins', 
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.2,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.description ?? 'No description provided.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Price and Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price: USD $100 converted to local currency by backend
                            ListenableBuilder(
                              listenable: CurrencyService.instance,
                              builder: (context, _) => Text(
                                CurrencyService.instance.formatUSDAmount(
                                  course.price ?? 100.0,
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _ActionButton(
                              icon: Icons.info_outline,
                              onTap: onShowDetails,
                              color: colorScheme.primary,
                              tooltip: 'Details',
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: isInCart
                                  ? Icons.remove_shopping_cart
                                  : Icons.add_shopping_cart,
                              onTap: isInCart ? onRemoveFromCart : onAddToCart,
                              color:
                                  isInCart ? Colors.red : AppTheme.successGreen,
                              filled: isInCart,
                              tooltip: isInCart ? 'Remove' : 'Add to Cart',
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildCourseImage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: AICERTSCourseCardImage(
        featureImageUrl: course.featureImageUrl,
        certificateBadgeUrl: course.certificateBadgeUrl,
        height: 110, // Reduced further
        width: double.infinity,
        showBadge: false, // Badge removed for cleaner certificate view
        fit: BoxFit.contain,
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  final Map<String, dynamic> bundle;
  final VoidCallback onAddToCart;

  const _BundleCard({required this.bundle, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<dynamic> bundleCourses = bundle['courses'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Feature Side
            Container(
              width: 200,
              decoration: const BoxDecoration(
                color: AppTheme.hosiMidnight,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bundle['image_url'] != null)
                    AICERTSImageWidget(
                      imageUrl: bundle['image_url'],
                      imageType: AICERTSImageType.course,
                      fit: BoxFit.cover,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.orange, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        '${bundleCourses.length} COURSES',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.hosiPeach,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('BUNDLE SAVINGS',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Content Side
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            bundle['title'],
                            style: TextStyle(fontFamily: 'Poppins', 
                                fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ),
                        // Use formatted_price from API if available, otherwise show USD price
                        Text(
                          bundle['formatted_price'] ?? 'USD ${bundle['price']}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bundle['description'] ??
                          'Curated professional learning path.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),

                    // Course chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: bundleCourses
                          .take(3)
                          .map((c) => Chip(
                                label: Text(c['title'],
                                    style: const TextStyle(fontSize: 11)),
                                backgroundColor: colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ))
                          .toList(),
                    ),

                    const Spacer(),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Explore Path Details'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: onAddToCart,
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add Entire Combo to Cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.hosiPeach,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool filled;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.filled = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: filled ? Colors.white : color, size: 20),
          ),
        ),
      ),
    );
  }
}
