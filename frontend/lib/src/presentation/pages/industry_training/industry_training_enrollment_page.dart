// lib/src/presentation/pages/industry_training/industry_training_enrollment_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/course.dart';
import '../../../core/api/api_client.dart';
import '../../widgets/headers/enrollment_page_header.dart';
import '../../../core/services/concierge_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/cart_service.dart';
import '../../widgets/aicerts/aicerts_image_widget.dart';
import '../../widgets/modals/aicerts/multi_step_aicerts_industry_training_modal.dart';
import '../../widgets/modals/marketing/wishlist_lead_modal.dart';
import '../../../core/services/wishlist_service.dart';

class IndustryTrainingEnrollmentPage extends StatefulWidget {
  final bool embedMode;
  const IndustryTrainingEnrollmentPage({super.key, this.embedMode = false});

  @override
  State<IndustryTrainingEnrollmentPage> createState() =>
      _IndustryTrainingEnrollmentPageState();
}

class _IndustryTrainingEnrollmentPageState
    extends State<IndustryTrainingEnrollmentPage> {
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _error;

  String _selectedIndustry = 'all';
  String _selectedRole = 'all';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, String>> _industries = [];
  List<Map<String, String>> _roles = [];
  bool _metadataLoaded = false;
  String? _metadataError;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _metadataLoaded = false;
      _metadataError = null;
    });

    try {
      // Fetch industries
      final industriesRes = await ApiClient.get(
        '/api/v1/industry-training/industries/',
      );

      final industriesData = industriesRes.data is Map<String, dynamic>
          ? (industriesRes.data['results'] as List<dynamic>? ?? [])
          : (industriesRes.data as List<dynamic>? ?? []);

      // Fetch roles
      final rolesRes = await ApiClient.get(
        '/api/v1/industry-training/roles/',
      );

      final rolesData = rolesRes.data is Map<String, dynamic>
          ? (rolesRes.data['results'] as List<dynamic>? ?? [])
          : (rolesRes.data as List<dynamic>? ?? []);

      setState(() {
        _industries = [
          {'value': 'all', 'label': 'All Industries'},
          ...industriesData.map((item) {
            final m = item as Map<String, dynamic>;
            return {
              'value': m['slug']?.toString() ?? m['id']?.toString() ?? '',
              'label': m['name']?.toString() ?? '',
            };
          }),
        ];
        _roles = [
          {'value': 'all', 'label': 'All Roles'},
          ...rolesData.map((item) {
            final m = item as Map<String, dynamic>;
            return {
              'value': m['slug']?.toString() ?? m['id']?.toString() ?? '',
              'label': m['name']?.toString() ?? '',
            };
          }),
        ];
        _metadataLoaded = true;
      });
    } catch (e) {
      setState(() {
        _metadataError = e.toString();
        _metadataLoaded = true;
        _industries = [
          {'value': 'all', 'label': 'All Industries'}
        ];
        _roles = [
          {'value': 'all', 'label': 'All Roles'}
        ];
      });
    }
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final params = <String, dynamic>{};
      if (_selectedIndustry != 'all') params['industry'] = _selectedIndustry;
      if (_selectedRole != 'all') params['role'] = _selectedRole;
      if (_searchController.text.isNotEmpty) {
        params['search'] = _searchController.text;
      }

      final response = await ApiClient.get(
        '/api/v1/industry-training/courses/',
        queryParameters: params,
      );

      final rawData = response.data;
      List<dynamic> items = [];

      if (rawData is Map<String, dynamic>) {
        if (rawData.containsKey('courses') || rawData.containsKey('bundles')) {
          items = [
            ...(rawData['courses'] as List<dynamic>? ?? []),
            ...(rawData['bundles'] as List<dynamic>? ?? []),
          ];
        } else if (rawData.containsKey('results')) {
          items = rawData['results'] as List<dynamic>? ?? [];
        } else {
          // If it's a single item Map but not the wrapper we expect
          items = [rawData];
        }
      } else if (rawData is List<dynamic>) {
        items = rawData;
      }

      setState(() {
        _courses = items
            .map((item) => Course.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Course> get _filteredCourses {
    var courses = List<Course>.from(_courses);
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      courses = courses
          .where((c) =>
              (c.title.toLowerCase().contains(query)) ||
              (c.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    return courses;
  }

  void _showEnrollmentModal(Course course) async {
    // Check if already in cart
    if (cartService.hasCourse(course.id)) {
      _showAlreadyInCartSnackbar(course);
      return;
    }

    // Show enrollment options dialog
    _showEnrollmentOptionsDialog(course);
  }

  void _showEnrollmentOptionsDialog(Course course) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          color: colors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enrollment Options',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                course.displayTitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Course Price',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Text(
                                    course.localPrice ??
                                        CurrencyService.instance
                                            .formatUSDAmount(
                                                course.price ?? 250),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 24,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.attach_money,
                                color: colors.primary,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Option 1: Add to Cart
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final success =
                                  await cartService.addCourse(course);
                              if (mounted) {
                                Navigator.of(context).pop();
                                if (success) {
                                  _showAddedToCartSnackbar(course);
                                } else {
                                  _showErrorSnackbar('Failed to add to cart');
                                }
                              }
                            },
                            icon: const Icon(Icons.shopping_cart_rounded),
                            label: const Text('Add to Cart'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Option 2: Enroll Now (direct)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showDirectEnrollmentForm(course);
                            },
                            icon: const Icon(Icons.person_add_rounded),
                            label: const Text('Enroll Now'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.primary,
                              side: BorderSide(color: colors.primary),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info text
                        Text(
                          'This industry-specific certification is delivered through the AICERTS platform with AI-powered learning tools.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDirectEnrollmentForm(Course course) async {
    final isAuthenticated = await AuthService.isAuthenticated();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MultiStepAICERTSIndustryTrainingModal(
          courses: [course],
          industry: _selectedIndustry,
          role: _selectedRole,
          onEnrollmentComplete: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enrollment submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          allowPrefill: isAuthenticated,
        );
      },
    );
  }

  void _showAddedToCartSnackbar(Course course) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Added to Cart',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    course.displayTitle,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to cart or show cart panel
          },
        ),
      ),
    );
  }

  void _showAlreadyInCartSnackbar(Course course) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This course is already in your cart',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          if (!widget.embedMode)
            EnrollmentPageHeader(
              title: 'Industry Specific & Role-based Training',
              subtitle: '67+ Professional AI Certifications for your Vertical',
              onBack: () => context.pop(),
            ),
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search courses...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (_) => _loadCourses(),
                      ),
                    ),
                    if (_metadataLoaded) ...[
                      DropdownButton<String>(
                        value: _selectedIndustry,
                        items: _industries
                            .map((i) => DropdownMenuItem<String>(
                                  value: i['value'],
                                  child: Text(i['label']!),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedIndustry = v);
                            _loadCourses();
                          }
                        },
                      ),
                      DropdownButton<String>(
                        value: _selectedRole,
                        items: _roles
                            .map((r) => DropdownMenuItem<String>(
                                  value: r['value'],
                                  child: Text(r['label']!),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedRole = v);
                            _loadCourses();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadCourses,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredCourses.isEmpty
                        ? Center(
                            child: Text(
                              'No courses found.',
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 360,
                              mainAxisExtent: 398,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _filteredCourses.length,
                            itemBuilder: (ctx, i) {
                              final course = _filteredCourses[i];
                              return _CourseCard(
                                course: course,
                                onEnroll: () => _showEnrollmentModal(course),
                                onAskAI: () => ConciergeService.setPrompt(
                                    'Tell me about ${course.title} industry training course.'),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// _CourseCard Widget (Fixed)
// ============================================================

class _CourseCard extends StatefulWidget {
  final Course course;
  final VoidCallback onEnroll;
  final VoidCallback onAskAI;

  const _CourseCard({
    required this.course,
    required this.onEnroll,
    required this.onAskAI,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _isWishlisted = wishlistService.hasCourse(widget.course.id);
  }

  void _handleWishlist() {
    if (_isWishlisted) {
      wishlistService.removeCourse(widget.course.id).then((success) {
        if (success && mounted) {
          setState(() => _isWishlisted = false);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Removed from wishlist')));
        }
      });
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WishlistLeadModal(
          course: widget.course,
          onComplete: (interest, timing, notes) async {
            final success = await wishlistService.addCourse(widget.course);
            if (success && mounted) {
              setState(() => _isWishlisted = true);
            }
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 8,
      shadowColor: colors.primary.withValues(alpha: 0.15),
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors.primary.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Image
          Stack(
            children: [
              AICERTSCourseCardImage(
                featureImageUrl: widget.course.featureImageUrl,
                certificateBadgeUrl: widget.course.certificateBadgeUrl,
                height: 140,
                width: double.infinity,
                showBadge: false,
                fit: BoxFit.contain,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CERTIFIED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: _handleWishlist,
                        icon: Icon(
                          _isWishlisted
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 20,
                          color: _isWishlisted
                              ? colors.primary
                              : colors.primary.withValues(alpha: 0.6),
                        ),
                        tooltip: 'Wishlist',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.course.description ??
                              'No description available.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Footer Actions
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (widget.course.price != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ENROLLMENT FEE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 8,
                                letterSpacing: 1,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              CurrencyService.instance
                                  .formatUSDAmount(widget.course.price!),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ElevatedButton(
                        onPressed: widget.onEnroll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_rounded, size: 14),
                            SizedBox(width: 6),
                            Text('Enroll',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
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
    );
  }
}
