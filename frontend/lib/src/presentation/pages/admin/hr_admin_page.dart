// lib/src/presentation/pages/admin/hr_admin_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../widgets/headers/dashboard_header.dart';
import '../instructor/bbb_session_viewer.dart';

/// HR Admin Page
/// Accessible only to HR Admin role
/// Focus: Instructor management, Payroll, Attendance, and Overtime approvals.
class HRAdminPage extends StatefulWidget {
  const HRAdminPage({super.key});

  @override
  State<HRAdminPage> createState() => _HRAdminPageState();
}

class _HRAdminPageState extends State<HRAdminPage> {
  String _userName = 'Admin';
  bool _isLoading = true;

  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _facilitators = [];
  List<Map<String, dynamic>> _attendanceLogs = [];
  List<Map<String, dynamic>> _overtimeRequests = [];
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadData();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getUserName();
    if (mounted) {
      setState(() {
        _userName = name ?? 'HR Admin';
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final dashboard = await ApiClient.getHRDashboardData();
      final instructors = await ApiClient.getInstructorPayrollData();
      final attendance = await ApiClient.getAttendanceLogs();
      final overtime = await ApiClient.getFacilitatorOvertimeRequests();
      
      // Fetch instructor applications
      List<Map<String, dynamic>> applicationsList = [];
      try {
        final appsResponse = await ApiClient.get('/api/v1/instructors/applications/');
        if (appsResponse.data != null) {
          applicationsList = List<Map<String, dynamic>>.from(
            (appsResponse.data is Map ? appsResponse.data['results'] : appsResponse.data) ?? []
          );
        }
      } catch (e) {
        debugPrint('Could not load applications: $e');
      }

      if (mounted) {
        setState(() {
          _dashboardData = dashboard;
          _facilitators =
              List<Map<String, dynamic>>.from(instructors['instructors'] ?? []);
          _attendanceLogs = List<Map<String, dynamic>>.from(attendance);
          _overtimeRequests = List<Map<String, dynamic>>.from(overtime);
          _applications = applicationsList;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load HR data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        drawer: isMobile
            ? Drawer(
                child: Container(
                  color: colors.surface,
                  child: _buildDrawerContent(theme, colors),
                ),
              )
            : null,
        appBar: isMobile
            ? AppBar(
                title:
                    Text('HR Portal', style: TextStyle(color: colors.onPrimary)),
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: _buildTabBar(colors, screenWidth),
                ),
              )
            : null,
        body: Column(
          children: [
            if (!isMobile)
              DashboardHeader(
                userName: _userName,
                userDesignation: 'HR Admin Portal',
                isAdmin: true,
                notificationCount: 0,
                showMenuButton: false,
                showBackButton: false,
                showCart: false,
                showWishlist: false,
                onLogout: () async {
                  await AuthService.logout();
                  if (context.mounted) context.go('/onboarding');
                },
              ),
            if (!isMobile)
              Container(
                color: colors.surface,
                child: _buildTabBar(colors, screenWidth),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDashboardOverview(colors),
                  _buildInstructorsList(colors),
                  _buildApplicationsList(colors),
                  _buildAttendanceList(colors),
                  _buildOvertimeList(colors),
                  _buildPayrollSection(colors),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _exportData,
          backgroundColor: colors.secondary,
          foregroundColor: colors.onSecondary,
          icon: const Icon(Icons.download),
          label: const Text('Export Report'),
        ),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colors, double screenWidth) {
    final pendingOvertime =
        _overtimeRequests.where((e) => e['status'] == 'pending').length;
    final scheduledInterviews = 
        _applications.where((e) => e['interview_status'] == 'scheduled').length;
    
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
        tabs: [
          const Tab(
              icon: Icon(Icons.dashboard_rounded, size: 20),
              text: 'Dashboard'),
          const Tab(
              icon: Icon(Icons.school_rounded, size: 20),
              text: 'Instructors'),
          Tab(
            icon: Badge(
              label: scheduledInterviews > 0 ? Text('$scheduledInterviews') : null,
              isLabelVisible: scheduledInterviews > 0,
              child: const Icon(Icons.assignment_ind_rounded, size: 20),
            ),
            text: 'Applications',
          ),
          const Tab(
              icon: Icon(Icons.timer_rounded, size: 20), text: 'Attendance'),
          Tab(
            icon: Badge(
              label: pendingOvertime > 0 ? Text('$pendingOvertime') : null,
              isLabelVisible: pendingOvertime > 0,
              child: const Icon(Icons.pending_actions_rounded, size: 20),
            ),
            text: 'Overtime',
          ),
          const Tab(
              icon: Icon(Icons.account_balance_wallet_rounded, size: 20),
              text: 'Payroll'),
        ],
      ),
    );
  }

  Widget _buildDrawerContent(ThemeData theme, ColorScheme colors) {
    return Builder(builder: (context) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'HR PORTAL',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard_rounded, 'Dashboard', 0),
          _buildDrawerItem(context, Icons.school_rounded, 'Instructors', 1),
          _buildDrawerItem(context, Icons.assignment_ind_rounded, 'Applications', 2),
          _buildDrawerItem(context, Icons.timer_rounded, 'Attendance', 3),
          _buildDrawerItem(
              context, Icons.pending_actions_rounded, 'Overtime', 4),
          _buildDrawerItem(
              context, Icons.account_balance_wallet_rounded, 'Payroll', 5),
        ],
      );
    });
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String label, int tabIndex) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        DefaultTabController.of(context).animateTo(tabIndex);
        Navigator.pop(context);
      },
    );
  }

  // ── Content Builders ─────────────────────────────────────────────────────

  Widget _buildDashboardOverview(ColorScheme colors) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HR Operations Centre',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              FilledButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Sync Data')),
            ],
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                  'Total Instructors',
                  '${_dashboardData?['instructors']?['total'] ?? 0}',
                  Icons.people_rounded,
                  Colors.blue),
              _buildStatCard(
                  'Active Sessions',
                  '${_dashboardData?['attendance']?['active_now'] ?? 0}',
                  Icons.timer_rounded,
                  Colors.green),
              _buildStatCard(
                  'Pending Overtime',
                  '${_dashboardData?['overtime']?['pending_count'] ?? 0}',
                  Icons.pending_actions_rounded,
                  Colors.orange),
              _buildStatCard(
                  'Payroll (MTD)',
                  '\$${_dashboardData?['payroll']?['monthly_total'] ?? 0}',
                  Icons.account_balance_wallet_rounded,
                  Colors.amber),
            ],
          ),
          const SizedBox(height: 40),
          _buildRecentSection(colors),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInstructorsList(ColorScheme colors) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_facilitators.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 80, color: colors.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No instructors found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _facilitators.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final f = _facilitators[index];
        final name = f['name'] ?? 'Unknown';
        final email = f['email'] ?? 'N/A';
        final status = f['status'] ?? 'N/A';
        final rate = f['hourly_rate'] ?? 0;

        return Card(
          elevation: 0,
          color: colors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.primary.withValues(alpha: 0.1),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: colors.primary)),
            ),
            title:
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$email • \$$rate/hr'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (status == 'Active' ? Colors.green : Colors.red)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: status == 'Active' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplicationsList(ColorScheme colors) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_ind_outlined,
                size: 80, color: colors.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No instructor applications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final app = _applications[index];
        final id = app['id']?.toString() ?? '';
        final name = app['applicant_name'] ?? 'Unknown';
        final email = app['applicant_email'] ?? 'N/A';
        final status = app['status'] ?? 'pending';
        final interviewStatus = app['interview_status'] ?? 'not_scheduled';
        final interviewDate = app['interview_datetime']?.toString().split('T')[0] ?? '';
        
        return Card(
          elevation: 0,
          color: colors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.secondary.withValues(alpha: 0.1),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: colors.secondary)),
            ),
            title:
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Status: ${status.toUpperCase()}'),
                    if (interviewStatus == 'scheduled') ...[
                      const SizedBox(width: 8),
                      Text('• Interview: $interviewDate', 
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
              ],
            ),
            isThreeLine: true,
            trailing: interviewStatus == 'scheduled' 
              ? ElevatedButton.icon(
                  onPressed: () => _joinInterview(app),
                  icon: const Icon(Icons.video_call),
                  label: const Text('Join Interview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                )
              : OutlinedButton(
                  onPressed: () {
                    // TODO: Implement Schedule Interview dialog logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scheduling to be implemented via dialog'))
                    );
                  },
                  child: const Text('Schedule'),
                ),
          ),
        );
      },
    );
  }

  Future<void> _joinInterview(Map<String, dynamic> app) async {
    final appId = app['id']?.toString() ?? '';
    final applicantName = app['applicant_name'] ?? 'Applicant';
    
    try {
      final response = await ApiClient.get('/api/v1/instructors/applications/$appId/join_interview/');
      if (response.data != null && response.data['join_url'] != null) {
        final joinUrl = response.data['join_url'];
        final meetingId = response.data['meeting_id'];
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog.fullscreen(
              child: BBBSessionViewer(
                sessionId: meetingId ?? appId,
                sessionTitle: 'Interview: $applicantName',
                joinUrl: joinUrl,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join interview: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAttendanceList(ColorScheme colors) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_attendanceLogs.isEmpty) {
      return const Center(child: Text('No logs today'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _attendanceLogs.length,
      itemBuilder: (context, index) {
        final log = _attendanceLogs[index];
        return Card(
          elevation: 0,
          color: colors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(log['facilitator_name'] ?? 'Instructor'),
            subtitle: Text('Clock in: ${log['clock_in'] ?? 'N/A'}'),
            trailing: Text(log['status'] ?? 'N/A'),
          ),
        );
      },
    );
  }

  Widget _buildOvertimeList(ColorScheme colors) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_overtimeRequests.isEmpty) {
      return const Center(child: Text('No requests'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _overtimeRequests.length,
      itemBuilder: (context, index) {
        final req = _overtimeRequests[index];
        return Card(
          elevation: 0,
          color: colors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(req['facilitator_name'] ?? 'Instructor'),
            subtitle: Text('${req['hours'] ?? 0} hours requested'),
            trailing: Text((req['status'] ?? 'pending').toUpperCase()),
          ),
        );
      },
    );
  }

  Widget _buildPayrollSection(ColorScheme colors) {
    return const Center(child: Text('Payroll Management Module'));
  }

  Widget _buildRecentSection(ColorScheme colors) {
    return const Text('Recent Activity List Coming Soon');
  }

  void _exportData() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Exporting Report...')));
  }
}