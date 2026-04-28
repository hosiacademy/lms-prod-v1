// lib/src/presentation/pages/dashboard/instructor_dashboard.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;

import '../../../core/services/auth_service.dart';
import '../../../core/services/instructor_service.dart';
import '../../../core/api/api_client.dart';
import '../../../data/models/learnership.dart';
import '../../../data/models/instructor_profile.dart';
import '../../widgets/headers/dashboard_header.dart';
import '../../widgets/chat/instructor_chat_panel.dart';
import '../instructor/sessions_page.dart';
import '../instructor/recordings_page.dart';
import '../instructor/start_session_modal.dart';
import '../instructor/bbb_session_viewer.dart';

/// Instructor Portal — 10-tab dashboard for teaching, BBB sessions, AICERTs, HR & earnings.
class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  String _userName = 'Instructor';
  String _userId = '';

  // Instructor dashboard data from backend
  InstructorDashboardData? _dashboardData;
  bool _isLoadingDashboard = true;
  String? _dashboardError;

  // Legacy support for learnerships
  List<Learnership> _teachingLearnerships = [];
  List<Map<String, dynamic>> _instructorStudents = [];
  int _unreadMessages = 0;
  bool _isLoadingLearnerships = true;
  String? _learnershipsError;

  // Upcoming sessions for Schedule tab
  List<Map<String, dynamic>> _upcomingSessions = [];
  bool _isLoadingSessions = false;
  String? _sessionsError;

  // All sessions for BBB tab
  List<Map<String, dynamic>> _allUpcomingSessions = [];
  List<Map<String, dynamic>> _allLiveSessions = [];
  List<Map<String, dynamic>> _allPastSessions = [];
  bool _isLoadingAllSessions = false;
  String? _allSessionsError;

  bool _isDisposed = false;

  static const Map<String, int> _tabIndex = {
    'dashboard': 0,
    'courses': 1,
    'students': 2,
    'assignments': 3,
    'grading': 4,
    'schedule': 5,
    'bbb': 6,
    'sessions': 7,
    'aicerts': 8,
    'earnings': 9,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadInstructorDashboard();
    _loadUpcomingSessions();
    _loadAllSessions();
  }

  Future<void> _loadInstructorDashboard() async {
    try {
      setState(() {
        _isLoadingDashboard = true;
      });

      // Try to fetch from backend API
      final dashboardData = await InstructorService.fetchDashboardData();

      if (!_isDisposed && mounted) {
        setState(() {
          _dashboardData = dashboardData;
          _userName = dashboardData.profile.name;

          // Convert instructor courses to learnerships for legacy compatibility
          _teachingLearnerships = dashboardData.courses.map((c) => Learnership(
            id: c.id,
            title: c.title,
            slug: 'course-${c.id}',
            specialization: c.type ?? 'Assigned Course',
            active: c.status == 'active' || c.status == 'ongoing',
          )).toList();

          // Convert instructor students to legacy format
          _instructorStudents = dashboardData.students.map((s) => {
            'id': s.id,
            'name': s.name,
            'email': s.email,
            'chat_room_id': s.chatRoomId ?? '',
            'unread_count': s.unreadCount,
          }).toList();

          // Update unread messages count
          _unreadMessages = dashboardData.stats.unreadMessages;

          _isLoadingDashboard = false;
          _isLoadingLearnerships = false;
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _dashboardError = e.toString();
          _isLoadingDashboard = false;
          _isLoadingLearnerships = false;
        });
      }
    }
  }

  Future<void> _loadUpcomingSessions() async {
    try {
      setState(() {
        _isLoadingSessions = true;
      });

      final response = await ApiClient.get('/api/v1/bbb/sessions/my_sessions/');
      
      if (!_isDisposed && mounted && response.data != null) {
        setState(() {
          _upcomingSessions = List<Map<String, dynamic>>.from(
            response.data['upcoming'] ?? []
          );
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _sessionsError = e.toString();
          _isLoadingSessions = false;
        });
      }
    }
  }

  Future<void> _loadAllSessions() async {
    try {
      print('📺 [BBB] Loading all sessions...');
      setState(() {
        _isLoadingAllSessions = true;
      });

      final response = await ApiClient.get('/api/v1/bbb/sessions/my_sessions/');
      print('📺 [BBB] Response status: ${response.statusCode}');
      print('📺 [BBB] Response data type: ${response.data.runtimeType}');
      print('📺 [BBB] Response data: $response.data');

      if (!_isDisposed && mounted && response.data != null) {
        final upcoming = response.data['upcoming'] as List? ?? [];
        final live = response.data['live'] as List? ?? [];
        final past = response.data['past'] as List? ?? [];
        
        print('📺 [BBB] Parsed - Upcoming: ${upcoming.length}, Live: ${live.length}, Past: ${past.length}');
        
        setState(() {
          _allUpcomingSessions = List<Map<String, dynamic>>.from(upcoming);
          _allLiveSessions = List<Map<String, dynamic>>.from(live);
          _allPastSessions = List<Map<String, dynamic>>.from(past);
          _isLoadingAllSessions = false;
        });
        print('📺 [BBB] State updated! Live sessions: ${_allLiveSessions.length}');
      }
    } catch (e, stackTrace) {
      print('📺 [BBB] ERROR: $e');
      print('📺 [BBB] Stack: $stackTrace');
      if (!_isDisposed && mounted) {
        setState(() {
          _allSessionsError = e.toString();
          _isLoadingAllSessions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getUserName();
    final id = await AuthService.getUserId();
    if (!_isDisposed && mounted) {
      setState(() {
        _userName = name ?? 'Instructor';
        _userId = id ?? '';
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

    return DefaultTabController(
      length: 10,
      child: Scaffold(
        drawer: Drawer(
          child: Container(
            color: colors.surface,
            child: _buildLeftSidebar(theme, colors),
          ),
        ),
        appBar: isMobile
            ? AppBar(
                title: Text('Instructor',
                    style: TextStyle(color: colors.onPrimary)),
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: _buildTabBar(theme, colors),
                ),
              )
            : null,
        body: Column(
          children: [
            // Header with welcome message (shown on tablet/desktop)
            if (!isMobile)
              DashboardHeader(
                userName: _userName,
                userDesignation: 'Instructor Portal',
                userImageUrl: null,
                isAdmin: false,
                notificationCount: _dashboardData?.stats.unreadMessages ?? _unreadMessages,
                showMenuButton: false,
                showCart: false,
                showWishlist: false,
                onNotificationsTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${_dashboardData?.stats.unreadMessages ?? _unreadMessages} unread messages from students')),
                  );
                },
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

            // TabBar on tablet/desktop (below header)
            if (!isMobile)
              Container(
                color: colors.surface,
                child: _buildTabBar(theme, colors),
              ),

            Expanded(
              child: isMobile
                  ? TabBarView(
                      children: [
                        _buildMainContent(theme, colors),
                        _buildMyCourses(theme, colors),
                        _buildMyStudents(theme, colors),
                        _buildPlaceholder(theme, colors, 'Assignments'),
                        _buildPlaceholder(theme, colors, 'Grading'),
                        _buildScheduleLecture(theme, colors),
                        _buildBigBlueButton(theme, colors),
                        _buildRecordings(theme, colors),
                        _buildAICERTsAccess(theme, colors),
                        _buildEarningsAndHR(theme, colors),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TabBarView(
                            children: [
                              _buildMainContent(theme, colors),
                              _buildMyCourses(theme, colors),
                              _buildMyStudents(theme, colors),
                              _buildPlaceholder(theme, colors, 'Assignments'),
                              _buildPlaceholder(theme, colors, 'Grading'),
                              _buildScheduleLecture(theme, colors),
                              _buildBigBlueButton(theme, colors),
                              _buildRecordings(theme, colors),
                              _buildAICERTsAccess(theme, colors),
                              _buildEarningsAndHR(theme, colors),
                            ],
                          ),
                        ),

                        // Right chat panel
                        Container(
                          width: isTablet ? 300 : 380,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border(
                              left: BorderSide(
                                color: colors.outline.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: InstructorChatPanel(
                            userId: _userId,
                            userName: _userName,
                            teachingCourses: (_dashboardData?.courses ?? []).map((c) => {'id': c.id, 'title': c.title}).toList(),
                            students: (_dashboardData?.students ?? []).map((s) => {
                              'id': s.id,
                              'name': s.name,
                              'email': s.email,
                              'chat_room_id': s.chatRoomId ?? '',
                              'unread_count': s.unreadCount,
                            }).toList(),
                            onUnreadCountChange: (count) {
                              setState(() {
                                _unreadMessages = count;
                              });
                            },
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
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme colors) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      child: TabBar(
        isScrollable: screenWidth < 1200,
        indicatorColor: colors.primary,
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurface,
        labelPadding:
            EdgeInsets.symmetric(horizontal: screenWidth < 1200 ? 12 : 16),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard, size: 20), text: "Dashboard"),
          Tab(icon: Icon(Icons.school, size: 20), text: "Courses"),
          Tab(icon: Icon(Icons.people, size: 20), text: "Students"),
          Tab(icon: Icon(Icons.assignment, size: 20), text: "Assignments"),
          Tab(icon: Icon(Icons.grade, size: 20), text: "Grading"),
          Tab(icon: Icon(Icons.video_call, size: 20), text: "Schedule"),
          Tab(icon: Icon(Icons.ondemand_video, size: 20), text: "BBB"),
          Tab(icon: Icon(Icons.video_library, size: 20), text: "Recordings"),
          Tab(icon: Icon(Icons.school_outlined, size: 20), text: "AICERTs"),
          Tab(icon: Icon(Icons.payments_outlined, size: 20), text: "Earnings & HR"),
        ],
      ),
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: InstructorChatPanel(
            userId: _userId,
            userName: _userName,
            teachingCourses: (_dashboardData?.courses ?? []).map((c) => {
              'id': c.id,
              'title': c.title,
            }).toList(),
            students: (_dashboardData?.students ?? []).map((s) => {
              'id': s.id,
              'name': s.name,
              'email': s.email,
              'chat_room_id': s.chatRoomId ?? '',
              'unread_count': s.unreadCount,
            }).toList(),
            onUnreadCountChange: (count) {
              setState(() {
                _unreadMessages = count;
              });
            },
          ),
        ),
      ),
    );
  }

  // ── Left sidebar (mobile drawer) ──────────────────────────────────────────

  Widget _buildLeftSidebar(ThemeData theme, ColorScheme colors) {
    return Builder(
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildDrawerItem(ctx, icon: Icons.dashboard, label: 'Dashboard', tabKey: 'dashboard', theme: theme, colors: colors),
          _sectionLabel(theme, colors, 'TEACHING'),
          _buildDrawerItem(ctx, icon: Icons.school, label: 'My Courses', tabKey: 'courses', theme: theme, colors: colors),
          _buildDrawerItem(ctx, icon: Icons.people, label: 'Students', tabKey: 'students', theme: theme, colors: colors),
          _buildDrawerItem(ctx, icon: Icons.assignment, label: 'Assignments', tabKey: 'assignments', theme: theme, colors: colors),
          _buildDrawerItem(ctx, icon: Icons.grade, label: 'Grading', tabKey: 'grading', theme: theme, colors: colors),
          _sectionLabel(theme, colors, 'LIVE SESSIONS'),
          _buildDrawerItem(ctx, icon: Icons.video_call, label: 'Schedule', tabKey: 'schedule', theme: theme, colors: colors),
          _buildDrawerItem(ctx, icon: Icons.ondemand_video, label: 'BBB', tabKey: 'bbb', theme: theme, colors: colors),
          _buildDrawerItem(ctx, icon: Icons.video_library, label: 'Recordings', tabKey: 'sessions', theme: theme, colors: colors),
          _sectionLabel(theme, colors, 'OTHER'),
          _buildDrawerItem(ctx, icon: Icons.school_outlined, label: 'AICERTs', tabKey: 'aicerts', theme: theme, colors: colors),
          _buildDrawerItem(ctx, icon: Icons.payments_outlined, label: 'Earnings & HR', tabKey: 'earnings', theme: theme, colors: colors),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, ColorScheme colors, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext drawerCtx, {
    required IconData icon,
    required String label,
    required String tabKey,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    final idx = _tabIndex[tabKey] ?? 0;
    return ListTile(
      leading: Icon(icon, size: 22, color: colors.onSurface),
      title: Text(label, style: theme.textTheme.bodyMedium),
      onTap: () {
        Navigator.of(drawerCtx).pop(); // close drawer
        DefaultTabController.of(drawerCtx).animateTo(idx);
      },
    );
  }

  // ── Tab content builders ──────────────────────────────────────────────────

  Widget _buildMainContent(ThemeData theme, ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message removed - already shown in header
          const SizedBox(height: 16),
          _buildStatCards(theme, colors),
          const SizedBox(height: 24),
          Text('Quick Actions',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAction(theme, colors, Icons.video_call, 'New Session',
                      () => _openNewSessionModal()),
                  _buildQuickAction(theme, colors, Icons.school, 'My Courses',
                      () => DefaultTabController.of(context).animateTo(1)),
                  _buildQuickAction(theme, colors, Icons.school_outlined, 'AICERTs',
                      () => DefaultTabController.of(context).animateTo(8)),
                  _buildQuickAction(theme, colors, Icons.payments_outlined,
                      'Earnings', () => DefaultTabController.of(context).animateTo(9)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(ThemeData theme, ColorScheme colors) {
    // Use real data from dashboard if available
    final stats = _dashboardData?.stats;
    final statsCards = [
      _StatCard(
        Icons.school,
        'Courses',
        stats?.coursesCount.toString() ?? '—',
        colors.primary
      ),
      _StatCard(
        Icons.people,
        'Students',
        stats?.studentsCount.toString() ?? '—',
        Colors.green
      ),
      _StatCard(
        Icons.ondemand_video,
        'Sessions',
        stats?.sessionsCount.toString() ?? '—',
        Colors.orange
      ),
      _StatCard(
        Icons.payments,
        'Earnings',
        '—', // TODO: Add earnings from backend
        Colors.purple
      ),
    ];
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth < 400) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 768) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1024) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 4;
        }
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 2.0 : 2.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: statsCards.map((s) => _buildStatCard(theme, colors, s)).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(
      ThemeData theme, ColorScheme colors, _StatCard s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(s.icon, color: s.color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.value,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700, color: s.color)),
                Text(s.label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(ThemeData theme, ColorScheme colors, IconData icon,
      String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
          color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCourses(ThemeData theme, ColorScheme colors) {
    // Show loading state
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_dashboardError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text('Failed to load courses', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_dashboardError!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInstructorDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    final courses = _dashboardData?.courses ?? [];
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: colors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Courses Assigned', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('You are not currently assigned to any courses.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    // Show courses list
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: colors.primary,
              child: Icon(Icons.school, color: colors.onPrimary),
            ),
            title: Text(
              course.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Status: ${course.status}'),
                if (course.enrolledCount > 0)
                  Text('Students: ${course.enrolledCount}'),
                if (course.startDate != null)
                  Text('Started: ${_formatDate(course.startDate)}'),
              ],
            ),
            trailing: Icon(
              course.status == 'active' || course.status == 'ongoing'
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: course.status == 'active' || course.status == 'ongoing'
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.5),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPlaceholder(
      ThemeData theme, ColorScheme colors, String sectionName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction,
              size: 64, color: colors.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(sectionName, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Coming soon.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildScheduleLecture(ThemeData theme, ColorScheme colors) {
    // Show loading state
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_sessionsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text('Failed to load sessions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_sessionsError!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUpcomingSessions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (_upcomingSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call, size: 64, color: colors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Upcoming Sessions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('You don\'t have any upcoming sessions scheduled.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openNewSessionModal,
              icon: const Icon(Icons.add),
              label: const Text('Create Live Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    // Show upcoming sessions summary with quick actions
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Sessions',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _openNewSessionModal,
                icon: const Icon(Icons.add),
                label: const Text('New Session'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Quick overview of your scheduled sessions. Tap "Manage All" to access full session management.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  theme,
                  colors,
                  icon: Icons.schedule,
                  label: 'Upcoming',
                  value: _upcomingSessions.length.toString(),
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  theme,
                  colors,
                  icon: Icons.live_tv,
                  label: 'Live Now',
                  value: _dashboardData?.stats.liveSessions.toString() ?? '0',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  theme,
                  colors,
                  icon: Icons.video_library,
                  label: 'Total Sessions',
                  value: _dashboardData?.stats.sessionsCount.toString() ?? '—',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Next session highlight
          if (_upcomingSessions.isNotEmpty) ...[
            Text(
              'Next Session',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildNextSessionCard(_upcomingSessions.first, theme, colors),
            const SizedBox(height: 16),
          ],

          // More upcoming sessions
          if (_upcomingSessions.length > 1) ...[
            Text(
              'More Upcoming',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._upcomingSessions.skip(1).take(3).map((session) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCompactSessionCard(session, theme, colors),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Manage all button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to BBB tab
                DefaultTabController.of(context).animateTo(6);
              },
              icon: const Icon(Icons.manage_search),
              label: const Text('Manage All Sessions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    ThemeData theme,
    ColorScheme colors, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSessionCard(
    Map<String, dynamic> session,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final title = session['title'] as String;
    final scheduledStart = session['scheduled_start'] != null
        ? DateTime.parse(session['scheduled_start'].toString())
        : null;
    final courseType = session['course_type'] as String? ?? 'Course';

    final dateStr = scheduledStart != null
        ? '${scheduledStart.day}/${scheduledStart.month}/${scheduledStart.year}'
        : 'TBD';
    final timeStr = scheduledStart != null
        ? '${scheduledStart.hour.toString().padLeft(2, '0')}:${scheduledStart.minute.toString().padLeft(2, '0')}'
        : '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.1),
              colors.primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 12, color: colors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.star, size: 16, color: colors.primary),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(courseType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      )),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      )),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(timeStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Session: $title')),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSessionCard(
    Map<String, dynamic> session,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final title = session['title'] as String;
    final scheduledStart = session['scheduled_start'] != null
        ? DateTime.parse(session['scheduled_start'].toString())
        : null;

    final dateStr = scheduledStart != null
        ? '${scheduledStart.day}/${scheduledStart.month}'
        : 'TBD';
    final timeStr = scheduledStart != null
        ? '${scheduledStart.hour.toString().padLeft(2, '0')}:${scheduledStart.minute.toString().padLeft(2, '0')}'
        : '';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primary.withValues(alpha: 0.1),
          child: Icon(Icons.schedule, color: colors.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$dateStr at $timeStr',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Session: $title')),
            );
          },
        ),
      ),
    );
  }

  /// Full BBB sessions management — Upcoming / Live / Past with management actions
  Widget _buildBigBlueButton(ThemeData theme, ColorScheme colors) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Header with refresh button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BBB Sessions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadAllSessions,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          // Tab Bar
          Container(
            color: colors.surface,
            child: TabBar(
              indicatorColor: colors.primary,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
              tabs: const [
                Tab(icon: Icon(Icons.schedule), text: 'Upcoming'),
                Tab(icon: Icon(Icons.live_tv), text: 'Live Now'),
                Tab(icon: Icon(Icons.history), text: 'Past'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoadingAllSessions
                ? const Center(child: CircularProgressIndicator())
                : _allSessionsError != null
                    ? _buildAllSessionsError(theme, colors)
                    : TabBarView(
                        children: [
                          _buildAllUpcomingSessions(theme, colors),
                          _buildAllLiveSessions(theme, colors),
                          _buildAllPastSessions(theme, colors),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSessionsError(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          const SizedBox(height: 16),
          Text('Failed to load sessions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_allSessionsError!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAllSessions,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllUpcomingSessions(ThemeData theme, ColorScheme colors) {
    if (_allUpcomingSessions.isEmpty) {
      return _buildSessionsEmptyState(
        theme,
        colors,
        icon: Icons.event,
        message: 'No upcoming sessions',
        actionLabel: 'Create Session',
        onAction: _openNewSessionModal,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allUpcomingSessions.length,
      itemBuilder: (context, index) {
        final session = _allUpcomingSessions[index];
        return _buildManageableSessionCard(session, theme, colors, 'upcoming');
      },
    );
  }

  Widget _buildAllLiveSessions(ThemeData theme, ColorScheme colors) {
    if (_allLiveSessions.isEmpty) {
      return _buildSessionsEmptyState(
        theme,
        colors,
        icon: Icons.videocam_off,
        message: 'No live sessions right now',
        actionLabel: 'Start Session',
        onAction: _openNewSessionModal,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allLiveSessions.length,
      itemBuilder: (context, index) {
        final session = _allLiveSessions[index];
        return _buildManageableSessionCard(session, theme, colors, 'live');
      },
    );
  }

  Widget _buildAllPastSessions(ThemeData theme, ColorScheme colors) {
    if (_allPastSessions.isEmpty) {
      return _buildSessionsEmptyState(
        theme,
        colors,
        icon: Icons.history,
        message: 'No past sessions yet',
        actionLabel: 'Create Session',
        onAction: _openNewSessionModal,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allPastSessions.length,
      itemBuilder: (context, index) {
        final session = _allPastSessions[index];
        return _buildManageableSessionCard(session, theme, colors, 'past');
      },
    );
  }

  Widget _buildManageableSessionCard(
    Map<String, dynamic> session,
    ThemeData theme,
    ColorScheme colors,
    String status,
  ) {
    final sessionId = session['id']?.toString() ?? '';
    final title = session['title'] as String;
    final scheduledStart = session['scheduled_start'] != null
        ? DateTime.parse(session['scheduled_start'].toString())
        : null;
    final scheduledEnd = session['scheduled_end'] != null
        ? DateTime.parse(session['scheduled_end'].toString())
        : null;
    final courseType = session['course_type'] as String? ?? 'Course';
    final maxParticipants = session['max_participants'] as int? ?? 100;
    final hasRecording = session['record'] as bool?;
    final joinUrl = session['join_url'] as String?;
    final startUrl = session['start_url'] as String?;

    // Format date and time
    final dateStr = scheduledStart != null
        ? '${scheduledStart.day}/${scheduledStart.month}/${scheduledStart.year}'
        : 'TBD';
    final timeStr = scheduledStart != null
        ? '${scheduledStart.hour.toString().padLeft(2, '0')}:${scheduledStart.minute.toString().padLeft(2, '0')}'
        : '';
    final durationStr = (scheduledStart != null && scheduledEnd != null)
        ? '${scheduledEnd.difference(scheduledStart).inMinutes} min'
        : '';

    // Determine status display
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == 'live') {
      statusColor = Colors.red;
      statusText = 'LIVE NOW';
      statusIcon = Icons.fiber_manual_record;
    } else if (status == 'upcoming') {
      statusColor = colors.primary;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule;
    } else {
      statusColor = colors.onSurface.withValues(alpha: 0.5);
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (hasRecording == true)
                  Icon(Icons.videocam, size: 16, color: colors.primary),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Course Type
            Row(
              children: [
                Icon(Icons.school, size: 14, color: colors.onSurface),
                const SizedBox(width: 4),
                Text(
                  courseType,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date & Time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: colors.onSurface),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: colors.onSurface),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                if (durationStr.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    durationStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Participants
            Row(
              children: [
                Icon(Icons.people, size: 14, color: colors.onSurface),
                const SizedBox(width: 4),
                Text(
                  'Up to $maxParticipants participants',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            _buildSessionActions(
              session,
              status,
              theme,
              colors,
              joinUrl,
              startUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionActions(
    Map<String, dynamic> session,
    String status,
    ThemeData theme,
    ColorScheme colors,
    String? joinUrl,
    String? startUrl,
  ) {
    final sessionId = session['id']?.toString() ?? '';
    final title = session['title'] as String;

    if (status == 'live') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _joinSession(sessionId, title, joinUrl),
              icon: const Icon(Icons.login),
              label: const Text('Join Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _endSession(sessionId),
            icon: const Icon(Icons.stop),
            tooltip: 'End Session',
            style: IconButton.styleFrom(
              backgroundColor: colors.errorContainer,
              foregroundColor: colors.onErrorContainer,
            ),
          ),
        ],
      );
    } else if (status == 'upcoming') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _startSessionNow(sessionId, title, startUrl),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _editSession(session),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Session',
          ),
          IconButton(
            onPressed: () => _deleteSession(sessionId),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Session',
            style: IconButton.styleFrom(
              foregroundColor: colors.error,
            ),
          ),
        ],
      );
    } else {
      // Past session
      final hasRecording = session['has_recording'] as bool? ?? false;
      if (hasRecording) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Viewing recording for: $title')),
              );
            },
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('View Recording'),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget _buildSessionsEmptyState(
    ThemeData theme,
    ColorScheme colors, {
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: colors.onSurface.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _joinSession(String sessionId, String title, String? joinUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog.fullscreen(
        child: BBBSessionViewer(
          sessionId: sessionId,
          sessionTitle: title,
          joinUrl: joinUrl,
        ),
      ),
    );
  }

  Future<void> _startSessionNow(String sessionId, String title, String? startUrl) async {
    try {
      final response = await ApiClient.post('/api/v1/bbb/sessions/$sessionId/start/');
      if (response.statusCode == 200 && mounted) {
        final data = response.data as Map<String, dynamic>;
        final joinUrl = data['join_url'] as String?;

        if (mounted) {
          Navigator.pop(context); // Close any open dialogs
          _loadAllSessions(); // Refresh sessions list

          // On web, open BBB directly in new tab and show confirmation
          if (kIsWeb && joinUrl != null) {
            // Convert to HTTPS for web
            final httpsJoinUrl = joinUrl.replaceFirst('http://', 'https://');
            html.window.open(httpsJoinUrl, '_blank');
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'BBB session "$title" opened in new tab!',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            // Native platforms or fallback: show embedded viewer
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Dialog.fullscreen(
                child: BBBSessionViewer(
                  sessionId: sessionId,
                  sessionTitle: title,
                  joinUrl: joinUrl,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _endSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this live session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiClient.post('/api/v1/bbb/sessions/$sessionId/end/');
        if (mounted) {
          _loadAllSessions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session ended successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to end session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editSession(Map<String, dynamic> session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit session: ${session['title']}')),
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiClient.delete('/api/v1/bbb/sessions/$sessionId/');
        if (mounted) {
          _loadAllSessions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Build recordings page
  Widget _buildRecordings(ThemeData theme, ColorScheme colors) {
    return const RecordingsPage();
  }

  /// Build students list with chat integration
  Widget _buildMyStudents(ThemeData theme, ColorScheme colors) {
    // Show loading state
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_dashboardError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text('Failed to load students', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_dashboardError!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInstructorDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    final students = _dashboardData?.students ?? [];
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: colors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Students Found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('You don\'t have any students enrolled in your courses.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    // Show students list with chat integration
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final hasUnread = student.unreadCount > 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: hasUnread ? colors.primary : colors.surfaceContainerHighest,
              child: Text(
                student.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                style: TextStyle(
                  color: hasUnread ? colors.onPrimary : colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  student.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${student.unreadCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(student.email),
                if (student.lastMessage != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (student.lastMessageFromMe ?? false)
                        Icon(Icons.done_all, size: 16, color: colors.primary)
                      else
                        const SizedBox.shrink(),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          student.lastMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasUnread ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.chat, color: colors.primary),
              onPressed: () {
                // Open chat with this student
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chat with ${student.name} coming soon')),
                );
              },
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildAICERTsAccess(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined,
              size: 64, color: colors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('AICERTS Access', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('AICERTS course management coming soon.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildEarningsAndHR(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined,
              size: 64, color: colors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Earnings & HR', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Earnings and HR management coming soon.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Future<void> _openNewSessionModal() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StartSessionModal(),
    );
    if (result == true && mounted) {
      setState(() {}); // trigger refresh
    }
  }
}

// ── Helper data classes ────────────────────────────────────────────────────

class _StatCard {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.icon, this.label, this.value, this.color);
}
