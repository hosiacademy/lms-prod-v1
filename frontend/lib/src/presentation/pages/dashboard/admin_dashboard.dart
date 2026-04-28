// lib/src/presentation/pages/dashboard/admin_dashboard.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../widgets/headers/dashboard_header.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/currency_service.dart';

/// Admin Portal - Role-based access control for specialized admin functions
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _userName = 'Admin';
  String _userRole = 'admin'; // admin, payment_admin, hr_admin, executive_admin
  String _selectedMenu = 'dashboard';
  WebViewController? _webViewController;
  bool _isDisposed = false;

  Map<String, dynamic>? _executiveAnalytics;
  Map<String, dynamic>? _salesMarketingAnalytics;
  Map<String, dynamic>? _executiveBillingInsights;
  Map<String, dynamic>? _payrollData;
  List<Map<String, dynamic>> _facilitators = [];
  List<Map<String, dynamic>> _pendingOvertime = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _loadDashboardsData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _webViewController = null;
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    final name = await AuthService.getUserName();
    final role = await AuthService.getUserRole();

    if (!_isDisposed && mounted) {
      setState(() {
        _userName = name ?? 'Admin';
        _userRole = role ?? 'admin';

        // Set initial menu based on role permissions
        if (!_hasAccess(_selectedMenu)) {
          _selectedMenu = _getDefaultMenuForRole();
        }
      });
    }
  }

  String _getDefaultMenuForRole() {
    if (_userRole == 'payment_admin') return 'instructor_payroll';
    if (_userRole == 'hr_admin') return 'student_mgmt';
    if (_userRole == 'executive_admin') return 'dashboard';
    return 'dashboard';
  }

  bool _hasAccess(String menuKey) {
    // Super admin has access to everything
    if (_userRole == 'admin') return true;

    switch (menuKey) {
      case 'dashboard':
        return _userRole == 'executive_admin';
      case 'sales_marketing':
        return _userRole == 'executive_admin' || _userRole == 'payment_admin';
      case 'instructor_payroll':
        return _userRole == 'hr_admin' ||
            _userRole == 'payment_admin' ||
            _userRole == 'executive_admin';
      case 'student_mgmt':
      case 'staff_mgmt':
      case 'instructor_mgmt':
        return _userRole == 'hr_admin' || _userRole == 'executive_admin';
      case 'django_admin':
      case 'settings':
        return false; // Restricted to super admins only
      default:
        return false;
    }
  }

  Future<void> _loadDashboardsData() async {
    if (_isDisposed) return;
    setState(() => _isLoading = true);

    try {
      final List<Future> tasks = [];

      // Load based on role
      if (_hasAccess('dashboard')) {
        tasks.add(ApiClient.getExecutiveAnalytics());
        tasks.add(ApiClient.getExecutiveInsights());
      }
      if (_hasAccess('sales_marketing'))
        tasks.add(ApiClient.getSalesMarketingAnalytics());
      if (_hasAccess('instructor_payroll'))
        tasks.add(ApiClient.getInstructorPayrollData());
      if (_hasAccess('student_mgmt'))
        tasks.add(ApiClient.getUsersByRole(3)); // Students
      if (_hasAccess('staff_mgmt')) {
        tasks.add(ApiClient.getUsersByRole(1)); // Admins
        tasks.add(ApiClient.getUsersByRole(2)); // Instructors
        tasks.add(ApiClient.get('/api/v1/instructors/profiles/')
            .then((r) => r.data));
        tasks.add(ApiClient.getFacilitatorOvertimeRequests());
      }

      final results = await Future.wait(tasks);

      if (!_isDisposed && mounted) {
        setState(() {
          int index = 0;
          if (_hasAccess('dashboard')) {
            _executiveAnalytics = results[index++];
            _executiveBillingInsights = results[index++];
          }
          if (_hasAccess('sales_marketing'))
            _salesMarketingAnalytics = results[index++];
          if (_hasAccess('instructor_payroll')) _payrollData = results[index++];
          if (_hasAccess('student_mgmt')) _students = results[index++];
          if (_hasAccess('staff_mgmt')) {
            final admins = results[index++];
            final instructors = results[index++];
            _staff = [...admins, ...instructors];
            final facilitatorsData = results[index++];
            _facilitators = List<Map<String, dynamic>>.from(
                facilitatorsData is Map
                    ? facilitatorsData['results']
                    : facilitatorsData);
            _pendingOvertime = List<Map<String, dynamic>>.from(results[index++])
                .where((r) => r['status'] == 'pending')
                .toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading dashboard data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      drawer: isMobile
          ? Drawer(
              child: Container(
                color: colors.surface,
                child: _buildLeftSidebar(theme, colors),
              ),
            )
          : null,
      body: Column(
        children: [
          DashboardHeader(
            userName: _userName,
            userDesignation: _getRoleDisplayName(),
            userImageUrl: null,
            isAdmin: true,
            notificationCount: 3,
            showMenuButton: isMobile,
            showCart: false,
            showWishlist: false,
            onNotificationsTap: () {},
            onProfileTap: () {},
            onLogout: () async {
              await AuthService.logout();
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
          ),
          Expanded(
            child: isMobile
                ? _buildMainContent(theme, colors, isDark)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: isTablet ? 200 : 250,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.hosiMidnight : Colors.white,
                          border: Border(
                            right: BorderSide(
                              color:
                                  AppTheme.hosiMidnight.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: _buildLeftSidebar(theme, colors),
                      ),
                      Expanded(
                        child: _buildMainContent(theme, colors, isDark),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName() {
    switch (_userRole) {
      case 'payment_admin':
        return 'Finance Administrator';
      case 'hr_admin':
        return 'HR & People Operations';
      case 'executive_admin':
        return 'C-Suite Executive';
      case 'admin':
        return 'System Administrator';
      default:
        return 'Administrator';
    }
  }

  Widget _buildLeftSidebar(ThemeData theme, ColorScheme colors) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      children: [
        if (_hasAccess('dashboard')) ...[
          _buildMenuItem(
            icon: Icons.dashboard_outlined,
            label: 'Executive Overview',
            menuKey: 'dashboard',
            theme: theme,
            colors: colors,
          ),
          const SizedBox(height: 12),
        ],
        if (_hasAccess('sales_marketing')) ...[
          _buildMenuItem(
            icon: Icons.trending_up,
            label: 'Sales & Marketing',
            menuKey: 'sales_marketing',
            theme: theme,
            colors: colors,
          ),
          const SizedBox(height: 12),
        ],
        if (_hasAccess('django_admin')) ...[
          _buildMenuItem(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Django Admin',
            menuKey: 'django_admin',
            theme: theme,
            colors: colors,
          ),
          const SizedBox(height: 12),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1),
        ),

        // Financials (Access for Payment/Executive/Super)
        if (_hasAccess('instructor_payroll')) ...[
          _buildSectionHeader(theme, colors, 'FINANCIALS'),
          _buildMenuItem(
            icon: Icons.payments_outlined,
            label: 'Instructor Payroll',
            menuKey: 'instructor_payroll',
            theme: theme,
            colors: colors,
          ),
          const SizedBox(height: 12),
        ],

        // Management (Access for HR/Executive/Super)
        if (_hasAccess('student_mgmt') || _hasAccess('staff_mgmt')) ...[
          _buildSectionHeader(theme, colors, 'MANAGEMENT'),
          if (_hasAccess('student_mgmt')) ...[
            _buildMenuItem(
              icon: Icons.school_outlined,
              label: 'Enrolled Learners',
              menuKey: 'student_mgmt',
              theme: theme,
              colors: colors,
            ),
            const SizedBox(height: 12),
          ],
          if (_hasAccess('staff_mgmt')) ...[
            _buildMenuItem(
              icon: Icons.badge_outlined,
              label: 'Staff & Facilitators',
              menuKey: 'staff_mgmt',
              theme: theme,
              colors: colors,
            ),
            const SizedBox(height: 12),
          ],
          if (_hasAccess('courses_mgmt')) ...[
            _buildMenuItem(
              icon: Icons.library_books_outlined,
              label: 'Course Catalog',
              menuKey: 'courses_mgmt',
              theme: theme,
              colors: colors,
            ),
            const SizedBox(height: 12),
          ],
        ],

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1),
        ),
        if (_hasAccess('settings'))
          _buildMenuItem(
            icon: Icons.settings_outlined,
            label: 'System Settings',
            menuKey: 'settings',
            theme: theme,
            colors: colors,
          ),
      ],
    );
  }

  Widget _buildSectionHeader(
      ThemeData theme, ColorScheme colors, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String menuKey,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    final isSelected = _selectedMenu == menuKey;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colors.primary : colors.onSurface,
        size: 22,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? colors.primary : colors.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colors.primary.withValues(alpha: 0.1),
      onTap: () {
        if (!_isDisposed && mounted) {
          setState(() {
            _selectedMenu = menuKey;
          });
        }
      },
    );
  }

  Widget _buildMainContent(ThemeData theme, ColorScheme colors, bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Synchronizing administrative records...'),
          ],
        ),
      );
    }

    return Container(
      color: colors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildSelectedContent(theme, colors, isDark),
      ),
    );
  }

  Widget _buildSelectedContent(
      ThemeData theme, ColorScheme colors, bool isDark) {
    switch (_selectedMenu) {
      case 'dashboard':
        return _buildExecutiveDashboard(theme, colors, isDark);
      case 'sales_marketing':
        return _buildSalesMarketingDashboard(theme, colors, isDark);
      case 'django_admin':
        return _buildDjangoAdminPanel(theme, colors);
      case 'instructor_payroll':
        return _buildInstructorPayroll(theme, colors, isDark);
      case 'student_mgmt':
        return _buildUserManagementView(
            theme, colors, 'Learner Population', _students);
      case 'staff_mgmt':
        return _buildUserManagementView(
            theme, colors, 'Administrative Staff & Instructors', _staff);
      case 'courses_mgmt':
        return _buildPlaceholder(theme, colors, 'Course Catalog');
      case 'settings':
        return _buildPlaceholder(theme, colors, 'System Settings');
      default:
        return _buildPlaceholder(theme, colors, _selectedMenu);
    }
  }

  // --- Dashboard Modules ---

  Widget _buildExecutiveDashboard(
      ThemeData theme, ColorScheme colors, bool isDark) {
    if (_executiveAnalytics == null) {
      return const Center(
          child: Text('Unauthorized or Failed to load analytics'));
    }

    final totalRevenue = _executiveAnalytics!['total_revenue'] ?? 0.0;
    final totalEnrollments = _executiveAnalytics!['total_enrollments'] ?? 0;
    final activeLearners = _executiveAnalytics!['active_learners'] ?? 0;
    final completionRate = _executiveAnalytics!['completion_rate'] ?? 0.0;
    final enrollmentDistribution =
        _executiveAnalytics!['enrollment_distribution'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Executive Overview',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Real-time organizational KPIs and growth metrics',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6))),
              ],
            ),
            IconButton(
                onPressed: _loadDashboardsData,
                icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
                child: _buildMetricCard(
                    icon: Icons.trending_up,
                    label: 'Gross Revenue',
                    value: CurrencyService.instance.formatPrice(totalRevenue),
                    trend: '+18%',
                    color: Colors.blue,
                    theme: theme,
                    colors: colors,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildMetricCard(
                    icon: Icons.school_outlined,
                    label: 'Active Learners',
                    value: activeLearners.toString(),
                    trend: '+5%',
                    color: AppTheme.hosiPeach,
                    theme: theme,
                    colors: colors,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildMetricCard(
                    icon: Icons.people_outline,
                    label: 'Total Registrations',
                    value: totalEnrollments.toString(),
                    trend: '+12%',
                    color: colors.primary,
                    theme: theme,
                    colors: colors,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildMetricCard(
                    icon: Icons.verified_outlined,
                    label: 'Certification Rate',
                    value: '${completionRate.toStringAsFixed(1)}%',
                    trend: '+3%',
                    color: AppTheme.successGreen,
                    theme: theme,
                    colors: colors,
                    isDark: isDark)),
          ],
        ),
        const SizedBox(height: 32),
        _buildExecutiveBillingTrendingView(theme, colors, isDark),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                flex: 2,
                child: _buildDistributionCard(
                    theme, colors, enrollmentDistribution)),
            const SizedBox(width: 24),
            Expanded(child: _buildAttendanceAlertsCard(theme, colors, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildExecutiveBillingTrendingView(
      ThemeData theme, ColorScheme colors, bool isDark) {
    if (_executiveBillingInsights == null) return const SizedBox();

    final List trends = _executiveBillingInsights!['trends'] ?? [];
    final metrics = _executiveBillingInsights!['metrics'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Annual Billing & Revenue Trending',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Comparison of Instructor Payouts vs Training Revenue',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Efficiency: ${metrics['cost_revenue_ratio']}% Cost Ratio',
                    style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: trends.isEmpty
                  ? const Center(child: Text('Insufficient trending data'))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: trends.map<Widget>((item) {
                        final double cost =
                            (item['instructor_cost'] as num).toDouble();
                        final double revenue =
                            (item['revenue'] as num).toDouble();
                        final maxVal = (cost > revenue ? cost : revenue) * 1.2;
                        final costHeight =
                            maxVal > 0 ? (cost / maxVal) * 200 : 0.0;
                        final revHeight =
                            maxVal > 0 ? (revenue / maxVal) * 200 : 0.0;

                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 12,
                                    height: costHeight,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withValues(alpha: 0.7),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 12,
                                    height: revHeight,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.7),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['month'].toString().split('-')[1],
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Instructor Cost', Colors.orange),
                const SizedBox(width: 24),
                _buildLegendItem('Training Revenue', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAttendanceAlertsCard(
      ThemeData theme, ColorScheme colors, bool isDark) {
    final alerts =
        _executiveBillingInsights?['attendance_alerts'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instructor Attendance Watchlist',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Flagged for atypical logging patterns or excessive OT',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            if (alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No critical attendance flags.')),
              )
            else
              ...alerts.take(5).map((alert) {
                final double otPercent =
                    (alert['ot_percentage'] as num).toDouble();
                final bool critical = otPercent > 50;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: critical
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    child: Icon(Icons.warning,
                        color: critical ? Colors.red : Colors.orange, size: 20),
                  ),
                  title: Text(
                      '${alert['facilitator__user__first_name']} ${alert['facilitator__user__last_name']}'),
                  subtitle: Text(
                      '${alert['ot_count']} OT sessions in ${alert['total_logs']} logs'),
                  trailing: Text(
                    '${otPercent.toStringAsFixed(0)}% OT',
                    style: TextStyle(
                        color: critical ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() => _selectedMenu = 'staff_mgmt');
              },
              child: const Text('View Detailed Personnel Logs'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesMarketingDashboard(
      ThemeData theme, ColorScheme colors, bool isDark) {
    if (_salesMarketingAnalytics == null) {
      return const Center(
          child: Text('Unauthorized access to Sales & Marketing'));
    }

    final wishlist =
        _salesMarketingAnalytics!['wishlist'] as Map<String, dynamic>? ?? {};
    final cart =
        _salesMarketingAnalytics!['cart'] as Map<String, dynamic>? ?? {};
    final topLeads = _salesMarketingAnalytics!['top_leads'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sales & Marketing Intelligence',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
                child: _buildSimpleMetricCard(
                    label: 'Interest Intensity',
                    value: (wishlist['total'] ?? 0).toString(),
                    icon: Icons.favorite_border,
                    color: Colors.pink,
                    theme: theme)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildSimpleMetricCard(
                    label: 'Cart Conversion',
                    value:
                        '${(wishlist['conversion_rate'] ?? 0.0).toStringAsFixed(1)}%',
                    icon: Icons.auto_graph,
                    color: Colors.purple,
                    theme: theme)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildSimpleMetricCard(
                    label: 'Abandoned Opportunity',
                    value: (cart['abandoned'] ?? 0).toString(),
                    icon: Icons.remove_shopping_cart_outlined,
                    color: colors.error,
                    theme: theme)),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildLeadsCard(theme, colors, topLeads)),
            const SizedBox(width: 24),
            Expanded(child: _buildProvisionalActionsCard(theme, colors)),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructorPayroll(
      ThemeData theme, ColorScheme colors, bool isDark) {
    if (_payrollData == null) {
      return const Center(
          child: Text('Unauthorized access to Financial Records'));
    }

    final instructors = _payrollData!['instructors'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payroll & Instructor Compensation',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Compensation Ledger',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                        onPressed: _loadDashboardsData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Sync All Records')),
                  ],
                ),
              ),
              if (_pendingOvertime.isNotEmpty) ...[
                _buildPendingOvertimeSection(theme, colors),
                const Divider(),
              ],
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Instructor')),
                    DataColumn(label: Text('Hourly Rate')),
                    DataColumn(label: Text('Accrued Balance')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: instructors.map<DataRow>((instructor) {
                    return DataRow(cells: [
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(instructor['name'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(instructor['email'] ?? '',
                              style: theme.textTheme.bodySmall),
                        ],
                      )),
                      DataCell(Text(CurrencyService.instance
                          .formatPrice(instructor['hourly_rate'] ?? 0.0))),
                      DataCell(Text(CurrencyService.instance
                          .formatPrice(instructor['balance'] ?? 0.0))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('Verified',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () =>
                                _handleUpdateRateFacilitator(instructor),
                            tooltip: 'Adjust Rate',
                          ),
                          IconButton(
                            icon: Icon(
                                instructor['is_suspended'] == true
                                    ? Icons.play_arrow
                                    : Icons.pause,
                                size: 20,
                                color: instructor['is_suspended'] == true
                                    ? Colors.green
                                    : Colors.orange),
                            onPressed: () =>
                                _handleToggleSuspension(instructor),
                            tooltip: instructor['is_suspended'] == true
                                ? 'Unsuspend'
                                : 'Suspend',
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingOvertimeSection(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.error),
              const SizedBox(width: 8),
              Text(
                'Pending Overtime Requests (${_pendingOvertime.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: colors.error),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingOvertime.length,
            itemBuilder: (context, index) {
              final req = _pendingOvertime[index];
              return Card(
                color: colors.error.withValues(alpha: 0.05),
                child: ListTile(
                  title: Text(
                      '${req['facilitator_name']} - ${req['assignment_title']}'),
                  subtitle: Text(
                      'Hours: ${req['hours']}h | Date: ${req['date']}\nReason: ${req['reason']}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _handleApproveOvertime(req),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _handleRejectOvertime(req),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleApproveOvertime(Map<String, dynamic> req) async {
    final notesController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Overtime'),
        content: TextField(
          controller: notesController,
          decoration:
              const InputDecoration(labelText: 'Admin Notes (Optional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiClient.approveOvertime(req['id'],
                    notes: notesController.text);
                Navigator.pop(context);
                _loadDashboardsData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Overtime approved. Earnings accrued.')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Approval failed: $e')));
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRejectOvertime(Map<String, dynamic> req) async {
    final notesController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Overtime'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(labelText: 'Reason for Rejection'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ApiClient.rejectOvertime(req['id'],
                    notes: notesController.text);
                Navigator.pop(context);
                _loadDashboardsData();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request rejected.')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rejection failed: $e')));
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleSuspension(Map<String, dynamic> facilitator) async {
    // We need to find the profile ID. If this is a user map, we need to map to facilitator profile.
    // Assuming facilitators list is loaded and matched.
    final profile = _facilitators.firstWhere(
        (f) => f['user']['id'] == facilitator['id'],
        orElse: () => {});
    if (profile.isEmpty) return;

    try {
      await ApiClient.toggleFacilitatorSuspension(profile['id']);
      _loadDashboardsData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(profile['is_suspended'] == true
              ? 'Facilitator unsuspended'
              : 'Facilitator suspended')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  Future<void> _handleUpdateRateFacilitator(
      Map<String, dynamic> facilitator) async {
    final profile = _facilitators.firstWhere(
        (f) => f['user']['id'] == facilitator['id'],
        orElse: () => {});
    if (profile.isEmpty)
      return _handleUpdateRate(facilitator); // Fallback to old method

    final controller = TextEditingController(
        text: (profile['hourly_rate'] ?? facilitator['hourly_rate'] ?? 0.0)
            .toString());
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Compensation: ${facilitator['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Changes will be applied to all future billable hours.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Hourly Rate', prefixText: '\$ '),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newRate = double.tryParse(controller.text);
              if (newRate == null) return;
              try {
                await ApiClient.updateFacilitatorRate(profile['id'], newRate);
                Navigator.pop(context);
                _loadDashboardsData();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compensation adjusted.')));
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Apply Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementView(ThemeData theme, ColorScheme colors,
      String title, List<Map<String, dynamic>> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('${users.length} active records in directory',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6))),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add User'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              final roleId =
                  int.tryParse(user['role_id']?.toString() ?? '3') ?? 3;
              final roleLabel = roleId == 1
                  ? 'Admin'
                  : (roleId == 2 ? 'Instructor' : 'Learner');
              final roleColor = roleId == 1
                  ? Colors.red
                  : (roleId == 2 ? Colors.orange : Colors.blue);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Text(user['name']?[0] ?? user['username']?[0] ?? '?',
                      style: TextStyle(color: colors.primary)),
                ),
                title: Text(user['name'] ?? user['username'] ?? 'Anonymous'),
                subtitle: Text(user['email'] ?? 'No email provided'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          border: Border.all(
                              color: roleColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(roleLabel,
                          style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        icon: const Icon(Icons.more_vert), onPressed: () {}),
                  ],
                ),
              );
            },
          ),
        ),
        if (users.isEmpty)
          const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: Text('No matching records found'))),
      ],
    );
  }

  Future<void> _handleUpdateRate(Map<String, dynamic> instructor) async {
    final controller = TextEditingController(
        text: (instructor['hourly_rate'] ?? 0.0).toString());
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Compensation: ${instructor['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Changes will be applied to all future billable hours.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Hourly Rate (ZAR)', prefixText: 'R '),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newRate = double.tryParse(controller.text);
              if (newRate == null) return;
              try {
                await ApiClient.updateInstructorRate(
                    userId: int.parse(instructor['id'].toString()),
                    hourlyRate: newRate);
                if (mounted) {
                  Navigator.pop(context);
                  _loadDashboardsData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Compensation rate adjusted')));
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Adjustment failed: $e')));
              }
            },
            child: const Text('Apply Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildDjangoAdminPanel(ThemeData theme, ColorScheme colors) {
    if (_userRole != 'admin')
      return const Center(
          child: Text('Unauthorized: Super Admin access required'));

    final adminUrl =
        '${AppConstants.apiBaseUrl.replaceAll('/api/v1', '')}/admin/';
    if (kIsWeb) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.terminal, size: 64, color: colors.primary),
                const SizedBox(height: 24),
                Text('Advanced System Controls',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                    'The secondary admin panel requires direct browser access.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(adminUrl),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Access Django Admin'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _webViewController ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(adminUrl));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('System Administration',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _webViewController?.reload()),
                IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => launchUrl(Uri.parse(adminUrl),
                        mode: LaunchMode.externalApplication)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 800,
          decoration: BoxDecoration(
              border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: WebViewWidget(controller: _webViewController!),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildMetricCard(
      {required IconData icon,
      required String label,
      required String value,
      required String trend,
      required Color color,
      required ThemeData theme,
      required ColorScheme colors,
      required bool isDark}) {
    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:
              BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 24)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(trend,
                      style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(value,
                style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: colors.onSurface)),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMetricCard(
      {required String label,
      required String value,
      required IconData icon,
      required Color color,
      required ThemeData theme}) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.2))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionCard(
      ThemeData theme, ColorScheme colors, List distribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Program Enrollment Distribution',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (distribution.isEmpty)
              const Center(child: Text('Awaiting synchronization...'))
            else
              ...distribution.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['name'] ?? 'Generic Program',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          Text(item['value'].toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: 0.7, // Simulated percentage for UI
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(colors.primary),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadsCard(ThemeData theme, ColorScheme colors, List leads) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Marketing: High Interest Leads',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (leads.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No prioritized leads identified')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leads.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lead = leads[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(lead['user__name'] ?? lead['user__email']),
                    subtitle: Text('Engagement: ${lead['training_type']}'),
                    trailing: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.mail_outline, size: 16),
                        label: const Text('Contact')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvisionalActionsCard(ThemeData theme, ColorScheme colors) {
    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.1))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.verified_user_outlined, size: 48),
            const SizedBox(height: 16),
            Text('Pending Verifications',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Manual payment slips waiting for review.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => context.go('/admin/payments'),
                    child: const Text('Audit Payments'))),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, ColorScheme colors, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_person_outlined,
              size: 64, color: colors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('$title Module', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Interface restricted based on your security clearance.'),
        ],
      ),
    );
  }
}
