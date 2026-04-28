// lib/src/presentation/pages/dashboard/home_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../widgets/adaptive/responsive_layout.dart';
import '../../widgets/cards/notification_card.dart';
import '../../widgets/headers/dashboard_header.dart';
import '../../../core/services/auth_service.dart';
import '../splash/splash_modal.dart';
import '../student_portal/student_portal_page.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Roles & Portal Configuration
// ──────────────────────────────────────────────────────────────────────────────

enum UserRole { student, instructor, facilitator, admin }

final Map<UserRole, String> roleLabels = {
  UserRole.student: 'Student Portal',
  UserRole.instructor: 'Instructor Portal',
  UserRole.facilitator: 'Facilitator Portal',
  UserRole.admin: 'Admin Portal',
};

final Map<UserRole, IconData> roleIcons = {
  UserRole.student: Icons.school,
  UserRole.instructor: Icons.create,
  UserRole.facilitator: Icons.group_work,
  UserRole.admin: Icons.admin_panel_settings,
};

extension UserRoleExtension on UserRole {
  String get label => roleLabels[this]!;
  IconData get icon => roleIcons[this]!;
}

// ──────────────────────────────────────────────────────────────────────────────
// Deep Blue Button Config - REPLACE WITH REAL VALUES
// ──────────────────────────────────────────────────────────────────────────────

const String deepBlueBaseUrl = 'https://your-deepblue-lms.deepbluebutton.org';
const String deepBlueSSOEndpoint = '$deepBlueBaseUrl/api/sso/login';
const String deepBlueCourseBase = '$deepBlueBaseUrl/course/';

// ──────────────────────────────────────────────────────────────────────────────
// Main Dashboard Page
// ──────────────────────────────────────────────────────────────────────────────

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  UserRole? _currentRole;
  String _userName = 'User';
  bool _isLoading = true;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await AuthService.getUserRole();
    final name = await AuthService.getUserName();

    if (mounted) {
      setState(() {
        _currentRole = _mapStringToUserRole(role);
        _userName = name ?? 'User';
        _isLoading = false;
      });
    }
  }

  UserRole _mapStringToUserRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'instructor':
        return UserRole.instructor;
      case 'facilitator':
        return UserRole.facilitator;
      case 'learner':
      default:
        return UserRole.student;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Content Layer
    Widget content;
    if (_isLoading || _currentRole == null) {
      // While loading data, show empty container (Splash will cover it)
      // or a loading indicator if Splash is somehow dismissed early
      content = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      content = ResponsiveLayout(
        mobile: _MobileDashboard(
          currentRole: _currentRole!,
          userName: _userName,
          onRoleChanged: _currentRole == UserRole.admin
              ? (role) => setState(() => _currentRole = role)
              : null,
        ),
        desktop: _DesktopDashboard(
          currentRole: _currentRole!,
          userName: _userName,
          onRoleChanged: _currentRole == UserRole.admin
              ? (role) => setState(() => _currentRole = role)
              : null,
        ),
      );
    }

    // Stack Splash on top
    return Stack(
      children: [
        content,
        if (_showSplash)
          Positioned.fill(
            child: SplashModal(
              onComplete: () {
                if (mounted) setState(() => _showSplash = false);
              },
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MOBILE VERSION
// ──────────────────────────────────────────────────────────────────────────────

class _MobileDashboard extends StatelessWidget {
  final UserRole currentRole;
  final String userName;
  final ValueChanged<UserRole>? onRoleChanged;

  const _MobileDashboard({
    required this.currentRole,
    required this.userName,
    this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Full-width header at top
          DashboardHeader(
            userName: userName,
            userDesignation: currentRole.label,
            userImageUrl: null, // Will use default avatar
            isAdmin: currentRole == UserRole.admin,
            notificationCount: 3,
            onNotificationsTap: () => _showNotificationsSheet(context),
            onProfileTap: () {
              // TODO: Navigate to profile page
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
          // Content below header
          Expanded(
            child: _buildDashboardContent(context),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurface,
        backgroundColor: colors.surface,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Badge(
                label: Text('2'), child: Icon(Icons.notifications_outlined)),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to ${currentRole.label}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: _getRoleCards(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getRoleCards(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    switch (currentRole) {
      case UserRole.student:
        return [
          _buildCard(
            context,
            icon: Icons.play_circle_fill_rounded,
            title: 'Start / Continue Learning',
            subtitle: 'Powered by Deep Blue Button',
            color: colors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeepBlueCoursePlayerPage(
                    courseId: 'active-course-001',
                    deepBlueCourseSlug: 'ai-foundations-2026',
                  ),
                ),
              );
            },
          ),
          _buildCard(
            context,
            icon: Icons.school,
            title: 'My Courses',
            subtitle: '5 active courses',
            color: colors.secondary,
            onTap: () => context.go('/courses'),
          ),
          _buildCard(
            context,
            icon: Icons.trending_up,
            title: 'Progress',
            subtitle: 'View your learning progress',
            color: colors.tertiary,
            onTap: () => context.go('/progress'),
          ),
          _buildCard(
            context,
            icon: Icons.assignment,
            title: 'Assignments',
            subtitle: '3 pending assignments',
            color: colors.primaryContainer,
            onTap: () {},
          ),
          _buildCard(
            context,
            icon: Icons.forum,
            title: 'Discussions',
            subtitle: 'Active class discussions',
            color: colors.secondaryContainer,
            onTap: () => context.go('/discussions'),
          ),
        ];
      case UserRole.instructor:
        return [
          _buildCard(
            context,
            icon: Icons.video_call,
            title: 'Start Live Session',
            subtitle: 'BigBlueButton - Go Live',
            color: colors.primary,
            onTap: () => context.go('/instructor/start-session'),
          ),
          _buildCard(
            context,
            icon: Icons.calendar_today,
            title: 'My Sessions',
            subtitle: 'Upcoming & past sessions',
            color: colors.secondary,
            onTap: () => context.go('/instructor/sessions'),
          ),
          _buildCard(
            context,
            icon: Icons.video_library,
            title: 'Recordings',
            subtitle: 'Session recordings & clips',
            color: colors.tertiary,
            onTap: () => context.go('/instructor/recordings'),
          ),
          _buildCard(
            context,
            icon: Icons.group,
            title: 'My Students',
            subtitle: 'Manage students',
            color: colors.secondary,
            onTap: () => context.go('/students'),
          ),
          _buildCard(
            context,
            icon: Icons.create,
            title: 'Create Course',
            subtitle: 'Design new content',
            color: colors.primaryContainer,
            onTap: () => context.go('/create-course'),
          ),
          _buildCard(
            context,
            icon: Icons.assessment,
            title: 'Assessments',
            subtitle: 'Grade submissions',
            color: colors.secondaryContainer,
            onTap: () => context.go('/assessments'),
          ),
        ];
      case UserRole.facilitator:
        return [
          _buildCard(
            context,
            icon: Icons.group_work,
            title: 'Facilitate',
            subtitle: 'Manage learning sessions',
            color: colors.primary,
            onTap: () {},
          ),
          _buildCard(
            context,
            icon: Icons.support,
            title: 'Support',
            subtitle: 'Help learners succeed',
            color: colors.secondary,
            onTap: () {},
          ),
          _buildCard(
            context,
            icon: Icons.schedule,
            title: 'Schedule',
            subtitle: 'Manage sessions calendar',
            color: colors.tertiary,
            onTap: () {},
          ),
          _buildCard(
            context,
            icon: Icons.feedback,
            title: 'Feedback',
            subtitle: 'Review learner feedback',
            color: colors.primaryContainer,
            onTap: () {},
          ),
        ];
      case UserRole.admin:
        return [
          _buildCard(
            context,
            icon: Icons.people,
            title: 'Manage Users',
            subtitle: 'User accounts & permissions',
            color: colors.primary,
            onTap: () => context.go('/users'),
          ),
          _buildCard(
            context,
            icon: Icons.analytics,
            title: 'System Analytics',
            subtitle: 'Platform performance',
            color: colors.secondary,
            onTap: () => context.go('/analytics'),
          ),
          _buildCard(
            context,
            icon: Icons.settings,
            title: 'System Settings',
            subtitle: 'Configure platform',
            color: colors.tertiary,
            onTap: () => context.go('/settings'),
          ),
          _buildCard(
            context,
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Security & permissions',
            color: colors.primaryContainer,
            onTap: () {},
          ),
        ];
    }
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Drawer(
      backgroundColor: colors.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colors.primary),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(currentRole.icon, size: 40, color: colors.onPrimary),
                const SizedBox(height: 8),
                Text(
                  currentRole.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: _getRoleNavItems(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getRoleNavItems(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final items = <Widget>[
      ListTile(
        leading: Icon(Icons.dashboard, color: colors.onSurface),
        title: Text('Dashboard', style: TextStyle(color: colors.onSurface)),
        onTap: () {
          context.go('/');
          Navigator.pop(context);
        },
      ),
      ListTile(
        leading: Icon(Icons.person, color: colors.onSurface),
        title: Text('Profile', style: TextStyle(color: colors.onSurface)),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: Icon(Icons.settings, color: colors.onSurface),
        title: Text('Settings', style: TextStyle(color: colors.onSurface)),
        onTap: () => Navigator.pop(context),
      ),
      Divider(color: colors.outline.withValues(alpha: 0.2)),
    ];

    items.addAll(_getRoleSpecificNavItems(context));

    return items;
  }

  List<Widget> _getRoleSpecificNavItems(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    switch (currentRole) {
      case UserRole.student:
        return [
          ListTile(
            leading: Icon(Icons.school, color: colors.onSurface),
            title:
                Text('My Courses', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/courses');
            },
          ),
          ListTile(
            leading: Icon(Icons.trending_up, color: colors.onSurface),
            title: Text('Progress', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/progress');
            },
          ),
          ListTile(
            leading: Icon(Icons.forum, color: colors.onSurface),
            title:
                Text('Discussions', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/discussions');
            },
          ),
        ];
      case UserRole.instructor:
        return [
          ListTile(
            leading: Icon(Icons.video_call, color: colors.onSurface),
            title: Text('Start Live Session (BBB)',
                style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/instructor/start-session');
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today, color: colors.onSurface),
            title:
                Text('My Sessions', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/instructor/sessions');
            },
          ),
          ListTile(
            leading: Icon(Icons.video_library, color: colors.onSurface),
            title:
                Text('Recordings', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/instructor/recordings');
            },
          ),
          ListTile(
            leading: Icon(Icons.create, color: colors.onSurface),
            title: Text('Create Course',
                style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/create-course');
            },
          ),
          ListTile(
            leading: Icon(Icons.group, color: colors.onSurface),
            title:
                Text('My Students', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/students');
            },
          ),
          ListTile(
            leading: Icon(Icons.assessment, color: colors.onSurface),
            title:
                Text('Assessments', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/assessments');
            },
          ),
        ];
      case UserRole.facilitator:
        return [
          ListTile(
            leading: Icon(Icons.group_work, color: colors.onSurface),
            title:
                Text('Facilitate', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.support, color: colors.onSurface),
            title: Text('Support', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.schedule, color: colors.onSurface),
            title: Text('Schedule', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ];
      case UserRole.admin:
        return [
          ListTile(
            leading: Icon(Icons.people, color: colors.onSurface),
            title:
                Text('Manage Users', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/users');
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics, color: colors.onSurface),
            title: Text('System Analytics',
                style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/analytics');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: colors.onSurface),
            title: Text('System Settings',
                style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),
        ];
    }
  }

  int _getSelectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/courses')) return 1;
    if (loc.startsWith('/chat')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/courses');
        break;
      case 2:
        context.go('/chat');
        break;
      case 3:
        _showNotificationsSheet(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Feature coming soon',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        );
    }
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildNotificationsSheet(context),
    );
  }

  Widget _buildNotificationsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Mark all as read',
                  style: TextStyle(color: colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: const [
                NotificationCard(
                  title: 'New Assignment',
                  message: 'Complete Calculus by Friday',
                  time: '10 min ago',
                ),
                NotificationCard(
                  title: 'Live Session',
                  message: 'Machine Learning in 15 mins',
                  time: '1 hr ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// DESKTOP VERSION
// ──────────────────────────────────────────────────────────────────────────────

class _DesktopDashboard extends StatelessWidget {
  final UserRole currentRole;
  final String userName;
  final ValueChanged<UserRole>? onRoleChanged;

  const _DesktopDashboard({
    required this.currentRole,
    required this.userName,
    this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Use specific Student Portal implementation for students
    if (currentRole == UserRole.student) {
      return Stack(
        children: [
          StudentPortalPage(userName: userName),
          // Admin Switcher Overlay
          if (onRoleChanged != null)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () => onRoleChanged!(UserRole.admin),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Back to Admin'),
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Full-width header at top
          DashboardHeader(
            userName: userName,
            userDesignation: currentRole.label,
            userImageUrl: null, // Will use default avatar
            isAdmin: currentRole == UserRole.admin,
            notificationCount: 3,
            onNotificationsTap: () => _showNotificationsSheet(context),
            onProfileTap: () {
              // TODO: Navigate to profile page
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
          // Portal switcher buttons (desktop-specific, ADMIN ONLY)
          if (onRoleChanged != null && currentRole == UserRole.admin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  bottom:
                      BorderSide(color: colors.outline.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Switch Portal View (Admin Only):',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _PortalButton(
                    label: 'Learner',
                    isActive: currentRole == UserRole.student,
                    onPressed: () => onRoleChanged!(UserRole.student),
                  ),
                  const SizedBox(width: 12),
                  _PortalButton(
                    label: 'Instructor',
                    isActive: currentRole == UserRole.instructor,
                    onPressed: () => onRoleChanged!(UserRole.instructor),
                  ),
                  const SizedBox(width: 12),
                  _PortalButton(
                    label: 'Facilitator',
                    isActive: currentRole == UserRole.facilitator,
                    onPressed: () => onRoleChanged!(UserRole.facilitator),
                  ),
                ],
              ),
            ),
          // Content area below header and portal switcher
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(currentRole.icon, size: 32, color: colors.primary),
                      const SizedBox(width: 12),
                      Text(
                        currentRole.label,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      childAspectRatio: 1.2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: _getRoleCards(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getRoleCards(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    switch (currentRole) {
      case UserRole.student:
        return [
          _buildDesktopCard(
            context,
            icon: Icons.play_circle_fill_rounded,
            title: 'Continue Learning',
            count: 'Deep Blue',
            color: colors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeepBlueCoursePlayerPage(
                    courseId: 'active-course-001',
                    deepBlueCourseSlug: 'ai-foundations-2026',
                  ),
                ),
              );
            },
          ),
          _buildDesktopCard(
            context,
            icon: Icons.school,
            title: 'My Courses',
            count: '5',
            color: colors.secondary,
            onTap: () => context.go('/courses'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.trending_up,
            title: 'Progress',
            count: '85%',
            color: colors.tertiary,
            onTap: () => context.go('/progress'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.assignment,
            title: 'Assignments',
            count: '3',
            color: colors.primaryContainer,
            onTap: () {},
          ),
          _buildDesktopCard(
            context,
            icon: Icons.forum,
            title: 'Discussions',
            count: '12',
            color: colors.secondaryContainer,
            onTap: () => context.go('/discussions'),
          ),
        ];
      case UserRole.instructor:
        return [
          _buildDesktopCard(
            context,
            icon: Icons.video_call,
            title: 'Start Live Session',
            count: 'BBB',
            color: colors.primary,
            onTap: () => context.go('/instructor/start-session'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.calendar_today,
            title: 'My Sessions',
            count: '8',
            color: colors.secondary,
            onTap: () => context.go('/instructor/sessions'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.video_library,
            title: 'Recordings',
            count: '12',
            color: colors.tertiary,
            onTap: () => context.go('/instructor/recordings'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.group,
            title: 'My Students',
            count: '125',
            color: colors.secondary,
            onTap: () => context.go('/students'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.create,
            title: 'Create Course',
            count: 'New',
            color: colors.primaryContainer,
            onTap: () => context.go('/create-course'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.assessment,
            title: 'Assessments',
            count: '24',
            color: colors.secondaryContainer,
            onTap: () => context.go('/assessments'),
          ),
        ];
      case UserRole.facilitator:
        return [
          _buildDesktopCard(
            context,
            icon: Icons.group_work,
            title: 'Facilitate',
            count: '8',
            color: colors.primary,
            onTap: () {},
          ),
          _buildDesktopCard(
            context,
            icon: Icons.support,
            title: 'Support',
            count: 'Help',
            color: colors.secondary,
            onTap: () {},
          ),
          _buildDesktopCard(
            context,
            icon: Icons.schedule,
            title: 'Schedule',
            count: '12',
            color: colors.tertiary,
            onTap: () {},
          ),
          _buildDesktopCard(
            context,
            icon: Icons.feedback,
            title: 'Feedback',
            count: '45',
            color: colors.primaryContainer,
            onTap: () {},
          ),
        ];
      case UserRole.admin:
        return [
          _buildDesktopCard(
            context,
            icon: Icons.people,
            title: 'Manage Users',
            count: '1.2K',
            color: colors.primary,
            onTap: () => context.go('/users'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.analytics,
            title: 'System Analytics',
            count: '📈',
            color: colors.secondary,
            onTap: () => context.go('/analytics'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.settings,
            title: 'System Settings',
            count: '⚙️',
            color: colors.tertiary,
            onTap: () => context.go('/settings'),
          ),
          _buildDesktopCard(
            context,
            icon: Icons.security,
            title: 'Security',
            count: '🔒',
            color: colors.primaryContainer,
            onTap: () {},
          ),
        ];
    }
  }

  Widget _buildDesktopCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 4,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  Text(
                    count,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildNotificationsSheet(context),
    );
  }

  Widget _buildNotificationsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Mark all as read',
                  style: TextStyle(color: colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: const [
                NotificationCard(
                  title: 'New Assignment',
                  message: 'Complete Calculus by Friday',
                  time: '10 min ago',
                ),
                NotificationCard(
                  title: 'Live Session',
                  message: 'Machine Learning in 15 mins',
                  time: '1 hr ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Portal Button Widget
// ──────────────────────────────────────────────────────────────────────────────

class _PortalButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _PortalButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isActive ? colors.primary : colors.onSurface,
        backgroundColor:
            isActive ? colors.primary.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive
                ? colors.primary
                : colors.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Deep Blue Button Course Player Page (FULLY FIXED)
// ──────────────────────────────────────────────────────────────────────────────

class DeepBlueCoursePlayerPage extends StatefulWidget {
  final String courseId;
  final String deepBlueCourseSlug;

  const DeepBlueCoursePlayerPage({
    super.key,
    required this.courseId,
    required this.deepBlueCourseSlug,
  });

  @override
  State<DeepBlueCoursePlayerPage> createState() =>
      _DeepBlueCoursePlayerPageState();
}

class _DeepBlueCoursePlayerPageState extends State<DeepBlueCoursePlayerPage> {
  late final WebViewController _controller;
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // Initialize WebViewController correctly
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100 && !_isDisposed && mounted) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (String url) {
            if (!_isDisposed && mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (!_isDisposed && mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (!_isDisposed && mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    error.description ?? 'Unknown error loading page';
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return request.url.startsWith(deepBlueBaseUrl)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      );

    _loadDeepBlueCourse();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadDeepBlueCourse() async {
    if (_isDisposed || !mounted) return;

    String? token = await _storage.read(key: 'deepblue_sso_token');

    if (_isDisposed || !mounted) return;

    if (token == null || token.isEmpty) {
      token = await _fetchSSOToken();
      if (_isDisposed || !mounted) return;

      if (token == null) {
        if (!_isDisposed && mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Authentication failed. Please login again.';
          });
        }
        return;
      }
      await _storage.write(key: 'deepblue_sso_token', value: token);
    }

    if (_isDisposed || !mounted) return;

    final String finalUrl =
        '$deepBlueCourseBase${widget.deepBlueCourseSlug}?token=$token'
        '&courseId=${widget.courseId}&platform=hosi-academy';

    try {
      await _controller.loadRequest(Uri.parse(finalUrl));
    } catch (e) {
      // Silently catch errors during disposal
    }
  }

  Future<String?> _fetchSSOToken() async {
    try {
      final response = await http.post(
        Uri.parse('https://your-backend-api.com/api/v1/sso/deepblue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'course_id': widget.courseId,
          'user_id':
              'current-logged-in-user-id', // ← REPLACE WITH REAL USER ID FROM AUTH
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'] as String?;
      }
    } catch (e) {
      debugPrint('SSO fetch error: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Course: ${widget.courseId}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: colors.error),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurface),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadDeepBlueCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      ),
                      child: const Text('Retry'),
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
