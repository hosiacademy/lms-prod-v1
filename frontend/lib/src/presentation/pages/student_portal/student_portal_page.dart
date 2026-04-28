import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../widgets/headers/dashboard_header.dart';
import 'wishlist_page.dart';
import '../../../core/utils/responsive_helper.dart';

// ---------------------------------------------------------------------------
// Unified internal course model for the portal's "My Courses" view.
// Merges AICERTS enrollments (from /api/v1/aicerts/enrollments/) and
// general payment enrollments (from /api/v1/payments/enrollments/).
// ---------------------------------------------------------------------------
class _PortalCourse {
  final int enrollmentId;
  final String title;
  final String status; // 'enrolled' | 'pending' | 'failed' | 'unenrolled'
  final DateTime enrolledAt;
  final double progress; // 0–100
  final String type; // 'aicerts' | 'native'
  final DateTime? completedAt;

  const _PortalCourse({
    required this.enrollmentId,
    required this.title,
    required this.status,
    required this.enrolledAt,
    required this.progress,
    required this.type,
    this.completedAt,
  });

  bool get canLaunch => status == 'enrolled';

  // Only AICERTS courses whose sync hasn't succeeded yet have a retry option.
  bool get canRetry =>
      type == 'aicerts' && (status == 'failed' || status == 'pending');
}

/// Student Portal
/// Uses the same structure as Instructor Portal:
/// Top Header -> TabBar -> Content Area (No Left Sidebar on Desktop)
class StudentPortalPage extends StatefulWidget {
  final String userName;
  final int? initialTabIndex;

  const StudentPortalPage({
    super.key,
    required this.userName,
    this.initialTabIndex,
  });

  @override
  State<StudentPortalPage> createState() => _StudentPortalPageState();
}

class _StudentPortalPageState extends State<StudentPortalPage>
    with TickerProviderStateMixin {
  late int _currentIndex;
  String _userName = 'Student';
  int _unreadMessages = 2;

  // Unified course list built from both AICERTS and native enrollments
  List<_PortalCourse> _courses = [];
  bool _isLoadingEnrollments = false;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _currentIndex = widget.initialTabIndex ?? 0;
    _fetchEnrollments();
  }

  // ---------------------------------------------------------------------------
  // Data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchEnrollments() async {
    if (!mounted) return;
    setState(() => _isLoadingEnrollments = true);

    try {
      // Fetch both sources in parallel
      final results = await Future.wait([
        ApiClient.getAICertsEnrollments(),
        ApiClient.getMyEnrollments(),
      ]);

      final aicertsData = results[0];
      final generalData = results[1];

      final merged = <_PortalCourse>[];

      // Map AICERTS enrollments
      for (final json in aicertsData) {
        try {
          merged.add(_PortalCourse(
            enrollmentId: json['id'] as int,
            title: json['course_title'] as String? ?? 'Unknown Course',
            status:
                json['aicerts_enrollment_status'] as String? ?? 'pending',
            enrolledAt:
                DateTime.parse(json['enrolled_at'] as String),
            progress:
                double.tryParse(json['progress_percentage']?.toString() ?? '') ?? 0.0,
            type: 'aicerts',
            completedAt: json['completed_at'] != null
                ? DateTime.parse(json['completed_at'] as String)
                : null,
          ));
        } catch (e) {
          debugPrint('Error parsing AICERTS enrollment: $e');
        }
      }

      // Map general payment enrollments — exclude custom_selection to avoid
      // duplicating AICERTS courses already covered by the AICERTS list above.
      for (final json in generalData) {
        final enrollmentType =
            json['enrollment_type'] as String? ?? '';
        if (enrollmentType == 'custom_selection') continue;

        final rawStatus = json['status'] as String? ?? '';
        if (rawStatus != 'enrolled') continue; // only show active enrolments

        try {
          merged.add(_PortalCourse(
            enrollmentId: json['id'] is int
                ? json['id'] as int
                : int.tryParse(json['id'].toString()) ?? 0,
            title: json['enrolled_item_name'] as String? ??
                json['course_name'] as String? ??
                'Unknown Course',
            status: 'enrolled',
            enrolledAt: json['enrolled_at'] != null
                ? DateTime.parse(json['enrolled_at'] as String)
                : (json['created_at'] != null
                    ? DateTime.parse(json['created_at'] as String)
                    : DateTime.now()),
            progress: 0.0,
            type: 'native',
          ));
        } catch (e) {
          debugPrint('Error parsing general enrollment: $e');
        }
      }

      // Sort by most recently enrolled first
      merged.sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt));

      if (!mounted) return;
      setState(() {
        _courses = merged;
        _isLoadingEnrollments = false;
      });
    } catch (e) {
      debugPrint('Error fetching enrollments: $e');
      if (!mounted) return;
      setState(() => _isLoadingEnrollments = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Course launch
  // ---------------------------------------------------------------------------

  Future<void> _launchCourse(_PortalCourse course) async {
    try {
      String? ssoUrl;
      if (course.type == 'aicerts') {
        ssoUrl = await ApiClient.getAICertsSSOUrl(course.enrollmentId);
      } else {
        ssoUrl = await ApiClient.getEnrollmentSSOUrl(course.enrollmentId);
      }

      if (ssoUrl != null) {
        final uri = Uri.parse(ssoUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar('Could not open course URL.');
        }
      } else {
        _showSnackBar('No launch URL available for this course.');
      }
    } catch (e) {
      debugPrint('Error launching course: $e');
      _showSnackBar('Could not launch course. Please try again.');
    }
  }

  Future<void> _retryCourseSync(_PortalCourse course) async {
    _showSnackBar('Retrying enrollment sync…');
    try {
      await ApiClient.post(
        '/api/v1/aicerts/enrollments/${course.enrollmentId}/retry-sync/',
        data: {},
      );
      _showSnackBar('Sync requested. Refreshing…');
      await _fetchEnrollments();
    } catch (e) {
      debugPrint('Retry sync error: $e');
      _showSnackBar(
          'Sync retry failed. Our team has been notified — please try again later.');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ---------------------------------------------------------------------------
  // Computed stats for the dashboard
  // ---------------------------------------------------------------------------

  int get _enrolledCount => _courses.length;
  int get _completedCount =>
      _courses.where((c) => c.progress >= 100 || c.completedAt != null).length;
  int get _inProgressCount =>
      _courses.where((c) => c.progress > 0 && c.progress < 100).length;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    // Resolve active page widget inline so stats always reflect current state.
    Widget activeView;
    switch (_currentIndex) {
      case 1:
        activeView = _buildMyCoursesView();
      case 2:
        activeView = const WishlistPage(embedMode: true);
      case 3:
        activeView = _buildProgressView();
      default:
        activeView = _buildDashboardView();
    }

    return Scaffold(
      backgroundColor: colors.surfaceContainer,
      appBar: isMobile
          ? AppBar(
              title: Text('Student Portal',
                  style: TextStyle(color: colors.onPrimary)),
              backgroundColor: colors.primary,
            )
          : null,
      body: Column(
        children: [
          // Header (Desktop/Tablet Only)
          if (!isMobile)
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colors.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: ResponsiveHelper.maxContainerWidth(context)),
                  child: DashboardHeader(
                    userName: _userName,
                    userDesignation: 'Student Portal',
                    isAdmin: false,
                    notificationCount: _unreadMessages,
                    showMenuButton: false,
                    showCart: true,
                    showWishlist: true,
                    onLogout: () async {
                      await AuthService.logout();
                      if (context.mounted) context.go('/onboarding');
                    },
                  ),
                ),
              ),
            ),

          // Horizontal Navigation
          if (!isMobile)
            Container(
              color: colors.surface,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: ResponsiveHelper.maxContainerWidth(context)),
                  padding: ResponsiveHelper.paddingHorizontal(context),
                  child: Row(
                    children: [
                      _buildPortalNavItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: 'Dashboard',
                        index: 0,
                        colors: colors,
                      ),
                      _buildPortalNavItem(
                        icon: Icons.play_circle_outline,
                        activeIcon: Icons.play_circle_fill,
                        label: 'My Courses',
                        index: 1,
                        colors: colors,
                      ),
                      _buildPortalNavItem(
                        icon: Icons.favorite_border,
                        activeIcon: Icons.favorite,
                        label: 'Wishlist',
                        index: 2,
                        colors: colors,
                      ),
                      _buildPortalNavItem(
                        icon: Icons.trending_up,
                        activeIcon: Icons.trending_up,
                        label: 'Progress',
                        index: 3,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!isMobile)
            Divider(
              height: 1,
              thickness: 1,
              color: colors.outlineVariant,
            ),

          // Main Content
          Expanded(
            child: isMobile
                ? activeView
                : Container(
                    width: double.infinity,
                    color: colors.surfaceContainerLowest,
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: ResponsiveHelper.maxContainerWidth(context)),
                        child: activeView,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(
                    icon: Icon(Icons.play_circle_fill), label: 'Courses'),
                NavigationDestination(
                    icon: Icon(Icons.favorite), label: 'Wishlist'),
                NavigationDestination(
                    icon: Icon(Icons.trending_up), label: 'Progress'),
              ],
            )
          : null,
    );
  }

  Widget _buildPortalNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required ColorScheme colors,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color:
                  isSelected ? colors.primary : colors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? colors.primary : colors.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard View
  // ---------------------------------------------------------------------------

  Widget _buildDashboardView() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message removed - already shown in header
                  SizedBox(height: 8),
                ],
              ),
              const Spacer(),
              _buildNotificationBadge(colors),
            ],
          ),
          const SizedBox(height: 40),

          // Stats — use real data from _courses
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 700;
              final cardWidth = isSmall
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 48) / 3;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      icon: Icons.school_rounded,
                      label: 'Enrolled Courses',
                      value: _isLoadingEnrollments
                          ? '…'
                          : _enrolledCount.toString(),
                      color: colors.primary,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      icon: Icons.verified_rounded,
                      label: 'Completed',
                      value: _isLoadingEnrollments
                          ? '…'
                          : _completedCount.toString(),
                      color: const Color(0xFF10B981),
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      icon: Icons.auto_graph_rounded,
                      label: 'In Progress',
                      value: _isLoadingEnrollments
                          ? '…'
                          : _inProgressCount.toString(),
                      color: colors.tertiary,
                      theme: theme,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Course Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingEnrollments)
            const Center(child: CircularProgressIndicator())
          else if (_courses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  'No courses yet. Browse our catalog to get started.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            )
          else
            // Show up to 3 most recent courses
            ..._courses.take(3).map(
                  (course) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActivityCard(
                      course: course,
                      theme: theme,
                      colors: colors,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined,
              color: colors.onSurfaceVariant),
          if (_unreadMessages > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 8,
                  minHeight: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required _PortalCourse course,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    final isComplete =
        course.progress >= 100 || course.completedAt != null;
    final icon = isComplete
        ? Icons.check_circle
        : (course.progress > 0 ? Icons.play_circle_fill : Icons.school);
    final color =
        isComplete ? const Color(0xFF10B981) : colors.primary;
    final statusLabel = isComplete
        ? 'Completed'
        : (course.progress > 0
            ? 'In Progress • ${course.progress.toInt()}%'
            : 'Enrolled');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(course.enrolledAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // My Courses View
  // ---------------------------------------------------------------------------

  Widget _buildMyCoursesView() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoadingEnrollments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_courses.isEmpty) {
      return Container(
        color: colors.surfaceContainerLowest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_outlined,
                    size: 80,
                    color: colors.primary.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 24),
              Text('My Courses',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 12),
              Text(
                'Your enrolled courses will appear here.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/courses'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Browse Courses'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: colors.surfaceContainerLowest,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Enrolled Courses',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_courses.length}',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _fetchEnrollments,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) =>
                  _buildEnrollmentCard(_courses[index], theme, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentCard(
      _PortalCourse course, ThemeData theme, ColorScheme colors) {
    final statusColor =
        course.status == 'enrolled' ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Course icon / thumbnail placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school, color: colors.primary, size: 40),
          ),
          const SizedBox(width: 20),

          // Title, badges, progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + provider badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (course.type == 'aicerts')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFF1A56DB)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'AICERTS',
                          style: TextStyle(
                            color: Color(0xFF1A56DB),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Status chip + enrollment date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _statusLabel(course.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Enrolled: ${_formatDate(course.enrolledAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // Sync-pending notice for AICERTS courses not yet active
                if (course.canRetry) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 12,
                          color: Colors.orange.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Enrollment sync in progress — '
                          'tap Retry to expedite.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: course.progress / 100,
                    backgroundColor: colors.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Action column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${course.progress.toInt()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (course.canLaunch)
                ElevatedButton(
                  onPressed: () => _launchCourse(course),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Launch Course'),
                )
              else if (course.canRetry)
                ElevatedButton.icon(
                  onPressed: () => _retryCourseSync(course),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Launch Course'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Progress View (placeholder — unchanged)
  // ---------------------------------------------------------------------------

  Widget _buildProgressView() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      color: colors.surfaceContainerLowest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.tertiary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bar_chart_rounded,
                  size: 80,
                  color: colors.tertiary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text('My Progress',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 12),
            Text(
              'Track your growth and achievements.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.tertiary,
                foregroundColor: colors.onTertiary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View Detailed Analytics'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _statusLabel(String status) {
    switch (status) {
      case 'enrolled':
        return 'ENROLLED';
      case 'pending':
        return 'SYNC PENDING';
      case 'failed':
        return 'SYNC FAILED';
      case 'unenrolled':
        return 'UNENROLLED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}
