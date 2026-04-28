// lib/src/presentation/pages/dashboard/student_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/headers/dashboard_header.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/bbb_service.dart';
import '../../widgets/chat/chat_panel.dart';
import '../../widgets/aicerts/aicerts_course_viewer.dart';
import '../instructor/bbb_session_viewer.dart';
import '../student_portal/course_catalog_page.dart';
import '../learnerships/learnership_enrollment_page.dart';
import '../industry_training/industry_training_enrollment_page.dart';
import '../../blocs/course/corporate/combined_masterclass_page.dart';
import '../custom_selection/custom_selection_page.dart';

/// Student Portal - Full learning platform with chat
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _LearnerDashboardState();
}

class _LearnerDashboardState extends State<StudentDashboard> {
  String _userName = 'Learner';
  String _userEmail = '';
  String _userRole = 'learner';
  String _userId = 'current-user-id';
  String _selectedMenu = 'dashboard';

  // AICERTS course viewing state
  Map<String, dynamic>? _activeCourse;
  bool _isViewingCourse = false;

  // BBB session viewing state
  bool _showBBBInline = false;
  Map<String, dynamic>? _activeSession;

  // Enrolled courses
  List<Map<String, dynamic>> _enrolledCourses = [];

  // Scheduled BBB sessions
  List<Map<String, dynamic>> _scheduledSessions = [];

  @override
  void initState() {
    super.initState();
    _loadLearnerData();
    _fetchEnrolledCourses();
    _fetchUpcomingSessions();
  }

  Future<void> _fetchUpcomingSessions() async {
    try {
      final response = await ApiClient.getStudentBBBSessions();
      if (mounted && response != null) {
        setState(() {
          _scheduledSessions.clear();
          final upcoming = response['upcoming'] as List<dynamic>? ?? [];
          for (var item in upcoming) {
            final instructorData = item['instructor'] as Map<String, dynamic>?;
            _scheduledSessions.add({
              'id': item['id'].toString(),
              'title': item['title'] ?? 'Live Session',
              'instructor': instructorData?['full_name'] ?? instructorData?['name'] ?? item['instructor_name'] ?? 'Instructor',
              'course': item['course_title'] ?? 'Training',
              'startTime': DateTime.tryParse(item['scheduled_start'] ?? '') ?? DateTime.now(),
              'duration_minutes': item['duration_minutes'] ?? 60,
              'status': item['status'] ?? 'scheduled',
              'isLive': item['status'] == 'live',
              'joinUrl': '/api/v1/bbb/sessions/${item['id']}/join/',
              'attendeePassword': item['attendee_password'] ?? '',
            });
          }
        });
        print('📺 Loaded ${_scheduledSessions.length} BBB sessions from backend');
      }
    } catch (e) {
      print('⚠️ Failed to fetch BBB sessions: $e');
    }
  }

  Future<void> _fetchEnrolledCourses() async {
    // Data already loaded from login response - no API call needed!
    // AuthService has the dashboard data from /api/v1/auth/login/
    final dashboardData = await AuthService.getDashboardData();
    if (dashboardData != null && mounted) {
      setState(() {
        final enrollments = dashboardData['enrollments'] as List<dynamic>? ?? [];
        for (var item in enrollments) {
          _enrolledCourses.add({
            'id': item['id'].toString(),
            'title': item['title'] ?? item['programme_title'] ?? 'Course',
            'progress': item['progress'] ?? 0.0,
            'instructor': item['instructor'] ?? 'Hosi Academy',
            'nextLesson': 'Continue Learning',
            'isAICERTS': item['type'] == 'aicerts',
            'status': item['status'] ?? 'active',
            'type': item['type'] ?? 'learnership',
            'start_date': item['start_date'] ?? 'TBD',
            'end_date': item['end_date'] ?? 'TBD',
            'ssoUrl': item['sso_url'],  // Capture SSO URL for AICERTS courses
          });
        }
        print('📊 Dashboard loaded with ${_enrolledCourses.length} courses from login');
      });
    }
  }

  double _parseProgress(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble() / 100.0;
    if (value is String) return (double.tryParse(value) ?? 0.0) / 100.0;
    return 0.0;
  }

  Future<void> _loadLearnerData() async {
    final name = await AuthService.getUserName();
    final email = await AuthService.getUserEmail();
    final id = await AuthService.getUserId();
    final role = await AuthService.getUserRole();

    if (mounted) {
      setState(() {
        _userName = name ?? 'Learner';
        _userEmail = email ?? '';
        _userId = id ?? 'current-user-id';
        _userRole = role ?? 'learner';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: colors.surface,
          child: _buildLeftSidebar(theme, colors),
        ),
      ),
      body: Column(
        children: [
          // Header with welcome message (ONLY HERE)
          DashboardHeader(
            userName: _userName,
            userDesignation:
                _userRole[0].toUpperCase() + _userRole.substring(1),
            userImageUrl: null,
            isAdmin: false,
            notificationCount: 3,
            showMenuButton: true, // Always show menu button for navigation
            onNotificationsTap: () {},
            onProfileTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile page coming soon')),
              );
            },
            onLogout: () async {
              await AuthService.logout();
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
          ),

          // Main layout: Responsive based on screen size
          Expanded(
            child: isMobile
                ? _buildMainContent(
                    theme, colors) // Mobile: Full screen content
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT SIDEBAR - Menu (tablet and desktop only)
                      if (!isMobile)
                        Container(
                          width: isTablet ? 200 : 250,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border(
                              right: BorderSide(
                                color: colors.outline.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: _buildLeftSidebar(theme, colors),
                        ),

                      // MAIN CONTENT AREA
                      Expanded(
                        child: _buildMainContent(theme, colors),
                      ),

                      // RIGHT CHAT PANEL (desktop only)
                      if (!isMobile && !isTablet)
                        Container(
                          width: 320,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border(
                              left: BorderSide(
                                color: colors.outline.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: ChatPanel(
                            userId: _userId,
                            userName: _userName,
                            enrolledCourses: _enrolledCourses,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: (isMobile || isTablet)
          ? FloatingActionButton.extended(
              onPressed: () {
                _showChatPanel(context, theme, colors);
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat'),
              backgroundColor: colors.primary,
            )
          : null,
    );
  }

  void _showChatPanel(
      BuildContext context, ThemeData theme, ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ChatPanel(
            userId: _userId,
            userName: _userName,
            enrolledCourses: _enrolledCourses,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSidebar(ThemeData theme, ColorScheme colors) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildMenuItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          menuKey: 'dashboard',
          theme: theme,
          colors: colors,
        ),
        _buildMenuItem(
          icon: Icons.school,
          label: 'My Courses',
          menuKey: 'courses',
          theme: theme,
          colors: colors,
        ),
        _buildMenuItem(
          icon: Icons.trending_up,
          label: 'Progress',
          menuKey: 'progress',
          theme: theme,
          colors: colors,
        ),
        _buildMenuItem(
          icon: Icons.assignment,
          label: 'Assignments',
          menuKey: 'assignments',
          theme: theme,
          colors: colors,
        ),
        _buildMenuItem(
          icon: Icons.calendar_today,
          label: 'Schedule',
          menuKey: 'schedule',
          theme: theme,
          colors: colors,
        ),
        _buildMenuItem(
          icon: Icons.video_call,
          label: 'Live Sessions',
          menuKey: 'live_sessions',
          theme: theme,
          colors: colors,
          badge: _scheduledSessions
              .where((s) => s['isLive'] == true)
              .length
              .toString(),
        ),
        _buildMenuItem(
          icon: Icons.quiz,
          label: 'Quizzes',
          menuKey: 'quizzes',
          theme: theme,
          colors: colors,
        ),
        _buildMenuItem(
          icon: Icons.grade,
          label: 'Grades',
          menuKey: 'grades',
          theme: theme,
          colors: colors,
        ),
        _buildMenuItem(
          icon: Icons.library_books,
          label: 'Resources',
          menuKey: 'resources',
          theme: theme,
          colors: colors,
        ),
        const Divider(),
        // Course Catalog Label (non-clickable)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'COURSE CATALOG',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // Enrollment Pathways (indented)
        _buildMenuItem(
          icon: Icons.star_border_rounded,
          label: 'Masterclasses',
          menuKey: 'masterclasses',
          theme: theme,
          colors: colors,
          isIndented: true,
        ),
        _buildMenuItem(
          icon: Icons.card_membership,
          label: 'Learnerships',
          menuKey: 'learnerships',
          theme: theme,
          colors: colors,
          isIndented: true,
        ),
        _buildMenuItem(
          icon: Icons.business,
          label: 'Industry Training',
          menuKey: 'industry_training',
          theme: theme,
          colors: colors,
          isIndented: true,
        ),
        _buildMenuItem(
          icon: Icons.tune,
          label: 'Custom Selection',
          menuKey: 'custom_selection',
          theme: theme,
          colors: colors,
          isIndented: true,
        ),
        const Divider(),
        _buildMenuItem(
          icon: Icons.settings,
          label: 'Settings',
          menuKey: 'settings',
          theme: theme,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String menuKey,
    required ThemeData theme,
    required ColorScheme colors,
    String? badge,
    bool isIndented = false,
  }) {
    final isSelected = _selectedMenu == menuKey;

    return Padding(
      padding: EdgeInsets.only(left: isIndented ? 16.0 : 0.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? colors.primary : colors.onSurface,
          size: isIndented ? 20 : 24,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? colors.primary : colors.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: isIndented ? 13 : null,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor: colors.primary.withValues(alpha: 0.1),
        onTap: () {
          setState(() {
            _selectedMenu = menuKey;
          });
        },
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, ColorScheme colors) {
    // If viewing BBB session inline
    if (_showBBBInline && _activeSession != null) {
      return Container(
        color: colors.surface,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _showBBBInline = false;
                      _activeSession = null;
                    });
                  },
                  tooltip: 'Leave Session',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeSession!['title'],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Instructor: ${_activeSession!['instructor']}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // BBB Session Viewer - Display inline
            Expanded(
              child: BBBSessionViewer(
                sessionId: _activeSession!['id'],
                sessionTitle: _activeSession!['title'],
                joinUrl: BBBService.generateStudentJoinUrl(
                  sessionId: _activeSession!['id'],
                  userName: _userName,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // If viewing an AICERTS course, show the course viewer inline
    if (_isViewingCourse &&
        _activeCourse != null &&
        _activeCourse!['isAICERTS'] == true) {
      return Container(
        color: colors.surface,
        padding: const EdgeInsets.all(24),
        child: AICERTSCourseViewer(
          courseId: _activeCourse!['aicertsCourseId'],
          userId: _userEmail.isNotEmpty ? _userEmail : 'student@hosiafrica.com',
          userName: _userName,
          onProgressUpdate: (progress) {
            // Update course progress in real-time
            setState(() {
              final courseIndex = _enrolledCourses.indexWhere(
                (c) => c['id'] == _activeCourse!['id'],
              );
              if (courseIndex != -1) {
                _enrolledCourses[courseIndex]['progress'] = progress / 100;
              }
            });
          },
          onCourseComplete: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Course completed! Certificate available.'),
                backgroundColor: colors.primary,
                action: SnackBarAction(
                  label: 'View',
                  textColor: colors.onPrimary,
                  onPressed: () {
                    // TODO: Show certificate
                  },
                ),
              ),
            );
          },
          onBack: () {
            setState(() {
              _isViewingCourse = false;
              _activeCourse = null;
            });
          },
        ),
      );
    }

    // Full-page embedded menus that handle their own scrolling
    final bool isEmbeddedMenu = _selectedMenu == 'catalog' ||
        _selectedMenu == 'masterclasses' ||
        _selectedMenu == 'learnerships' ||
        _selectedMenu == 'industry_training' ||
        _selectedMenu == 'custom_selection';

    if (isEmbeddedMenu) {
      return Container(
        color: colors.surface,
        child: _buildSelectedContent(theme, colors),
      );
    }

    // Default dashboard/menu content with its own scrolling
    return Container(
      color: colors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show Quick Stats at top when dashboard is selected
            if (_selectedMenu == 'dashboard') ...[
              _buildDashboardStats(theme, colors),
              const SizedBox(height: 32),
              _buildEnrolledCoursesSection(theme, colors),
            ] else
              _buildSelectedContent(theme, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledCoursesSection(ThemeData theme, ColorScheme colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Enrolled Courses',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                fontSize: isMobile ? 18 : null,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedMenu = 'courses';
                });
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Responsive grid for enrolled courses
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            if (constraints.maxWidth < 600) {
              crossAxisCount = 1; // Mobile: single column
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 2; // Tablet: 2 columns
            } else {
              crossAxisCount = 3; // Desktop: 3 columns
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: isMobile ? 280 : 240,
              ),
              itemCount: _enrolledCourses.length,
              itemBuilder: (context, index) {
                final course = _enrolledCourses[index];
                return Card(
                  elevation: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course icon
                        Container(
                          width: double.infinity,
                          height: isMobile ? 100 : 80,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.school, color: colors.primary, size: 48),
                        ),
                        const SizedBox(height: 12),
                        // Course title
                        Expanded(
                          child: Text(
                            course['title'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Instructor
                        Text(
                          'Instructor: ${course['instructor']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Next lesson
                        Text(
                          'Next: ${course['nextLesson']}',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Progress bar
                        LinearProgressIndicator(
                          value: course['progress'],
                          backgroundColor: colors.surfaceContainerHighest,
                          color: colors.primary,
                          minHeight: 6,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(course['progress'] * 100).toInt()}% complete',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (course['isAICERTS'] == true) {
                                final ssoUrl = course['ssoUrl'] as String?;
                                if (ssoUrl != null && ssoUrl.isNotEmpty) {
                                  launchUrl(Uri.parse(ssoUrl), mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Course access not available. Please contact support.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: course['isAICERTS'] == true
                                  ? colors.primary
                                  : colors.secondary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: Icon(
                              course['isAICERTS'] == true
                                  ? Icons.open_in_new
                                  : Icons.school,
                              size: 16,
                            ),
                            label: Text(
                              course['isAICERTS'] == true
                                  ? 'Launch'
                                  : 'Continue',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashboardStats(ThemeData theme, ColorScheme colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    final double avgProgress = _enrolledCourses.isEmpty
        ? 0.0
        : _enrolledCourses
                .map((c) => c['progress'] as double)
                .reduce((a, b) => a + b) /
            _enrolledCourses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Responsive grid layout for all screen sizes
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate optimal cross axis count based on width
            int crossAxisCount;
            if (constraints.maxWidth < 400) {
              crossAxisCount = 1; // Very small mobile
            } else if (constraints.maxWidth < 768) {
              crossAxisCount = 2; // Mobile
            } else if (constraints.maxWidth < 1024) {
              crossAxisCount = 3; // Tablet
            } else {
              crossAxisCount = 4; // Desktop
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isMobile ? 2.0 : 2.5,
              children: [
                _buildStatCard(
                  icon: Icons.school,
                  label: 'Active Courses',
                  value: '${_enrolledCourses.length}',
                  color: colors.primary,
                  theme: theme,
                  colors: colors,
                ),
                _buildStatCard(
                  icon: Icons.trending_up,
                  label: 'Avg Progress',
                  value: '${(avgProgress * 100).toInt()}%',
                  color: Colors.green,
                  theme: theme,
                  colors: colors,
                ),
                _buildStatCard(
                  icon: Icons.assignment,
                  label: 'Assignments',
                  value: '3',
                  color: Colors.orange,
                  theme: theme,
                  colors: colors,
                ),
                if (!isMobile)
                  _buildStatCard(
                    icon: Icons.video_call,
                    label: 'Live Sessions',
                    value: _scheduledSessions
                        .where((s) => s['isLive'] == true)
                        .length
                        .toString(),
                    color: Colors.purple,
                    theme: theme,
                    colors: colors,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedContent(ThemeData theme, ColorScheme colors) {
    // Handle Live Sessions menu
    if (_selectedMenu == 'live_sessions') {
      return _buildLiveSessions(theme, colors);
    }

    // Handle Exploration Menus
    if (_selectedMenu == 'catalog') {
      return const CourseCatalogPage(embedMode: true);
    }

    if (_selectedMenu == 'masterclasses') {
      return const CombinedMasterclassPage(embedMode: true);
    }

    if (_selectedMenu == 'learnerships') {
      return const LearnershipEnrollmentPage(embedMode: true);
    }

    if (_selectedMenu == 'industry_training') {
      return const IndustryTrainingEnrollmentPage(embedMode: true);
    }

    if (_selectedMenu == 'custom_selection') {
      return const CustomSelectionPage(embedMode: true);
    }

    // Default placeholder for other menus
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: colors.onSurface,
          ),
          const SizedBox(height: 16),
          Text(
            '$_selectedMenu Section',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This section is under construction',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSessions(ThemeData theme, ColorScheme colors) {
    // Separate live and upcoming sessions
    final liveSessions =
        _scheduledSessions.where((s) => s['isLive'] == true).toList();
    final upcomingSessions =
        _scheduledSessions.where((s) => s['isLive'] == false).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Sessions',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Live Now Section
        if (liveSessions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: colors.error.withValues(alpha: 0.3), width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, color: colors.error, size: 16),
                const SizedBox(width: 8),
                Text(
                  'LIVE NOW',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...liveSessions.map((session) =>
              _buildSessionCard(session, theme, colors, isLive: true)),
          const SizedBox(height: 32),
        ],

        // Upcoming Sessions
        Text(
          'Upcoming Sessions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (upcomingSessions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                children: [
                  Icon(Icons.event_available,
                      size: 64, color: colors.onSurface),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming sessions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...upcomingSessions.map((session) =>
              _buildSessionCard(session, theme, colors, isLive: false)),
      ],
    );
  }

  Widget _buildSessionCard(
      Map<String, dynamic> session, ThemeData theme, ColorScheme colors,
      {required bool isLive}) {
    final DateTime startTime = session['startTime'];
    final String timeUntil = _formatTimeUntil(startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isLive
                    ? colors.error.withValues(alpha: 0.1)
                    : colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.video_call,
                size: 40,
                color: isLive ? colors.error : colors.primary,
              ),
            ),
            const SizedBox(width: 20),

            // Session Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fiber_manual_record,
                                  color: colors.onError, size: 10),
                              const SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onError,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            timeUntil,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session['title'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: colors.onSurface),
                      const SizedBox(width: 4),
                      Text(
                        session['instructor'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.school, size: 16, color: colors.onSurface),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session['course'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: colors.onSurface),
                      const SizedBox(width: 4),
                      Text(
                        '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${session['duration']}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: colors.onSurface),
                      const SizedBox(width: 4),
                      Text(
                        '${session['attendees']} attendees',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Join Button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _activeSession = session;
                  _showBBBInline = true;
                });
              },
              icon: Icon(isLive ? Icons.video_call : Icons.schedule),
              label: Text(isLive ? 'Join Now' : 'Schedule'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: isLive ? colors.error : colors.primary,
                foregroundColor: isLive ? colors.onError : colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeUntil(DateTime startTime) {
    final now = DateTime.now();
    final difference = startTime.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes}m';
    } else {
      return 'Starting soon';
    }
  }
}
