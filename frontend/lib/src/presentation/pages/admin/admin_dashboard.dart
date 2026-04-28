// lib/src/presentation/pages/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/api_client.dart'; // Add this import
import 'payment_admin_page.dart';
import 'hr_admin_page.dart';
import 'executive_admin_page.dart';

/// Admin Dashboard Selector
/// Routes users to appropriate admin page based on their role
/// Supports three admin roles: Payment Admin, HR Admin, Executive Admin
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? '';

    // Determine which admin page to show based on role
    switch (userRole.toLowerCase()) {
      case 'payment_admin':
      case 'paymentadmin':
        return const PaymentAdminPage();

      case 'hr_admin':
      case 'hradmin':
        return const HRAdminPage();

      case 'executive_admin':
      case 'executive':
      case 'executiveadmin':
      case 'c_suite':
      case 'csuite':
        return const ExecutiveAdminPage();

      case 'admin':
      case 'superuser':
        return const AdminRoleSelector(
          availableRoles: ['payment_admin', 'hr_admin', 'executive_admin'],
        );

      default:
        // User doesn't have admin access
        return _buildNoAccessPage(context);
    }
  }

  Widget _buildNoAccessPage(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: colors.error,
        foregroundColor: colors.onError,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 100,
                color: colors.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Admin Access Required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You do not have permission to access admin functionality.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Admin Role Selector Page
/// Allows multi-role users to choose which admin interface to access
class AdminRoleSelector extends StatefulWidget {
  final List<String> availableRoles;

  const AdminRoleSelector({
    super.key,
    required this.availableRoles,
  });

  @override
  State<AdminRoleSelector> createState() => _AdminRoleSelectorState();
}

class _AdminRoleSelectorState extends State<AdminRoleSelector> {
  bool _isLoading = false;
  Map<String, dynamic>? _adminStats;

  @override
  void initState() {
    super.initState();
    _loadAdminStats();
  }

  Future<void> _loadAdminStats() async {
    setState(() => _isLoading = true);
    try {
      // Load stats for each admin role
      final stats = <String, dynamic>{};

      // Try to get payment admin stats
      try {
        final paymentStats = await ApiClient.getAdminPayments();
        stats['payment_stats'] = paymentStats;
      } catch (e) {
        stats['payment_stats'] = {'error': e.toString()};
      }

      // Try to get HR admin stats
      try {
        final hrStats = await ApiClient.getHRDashboardData();
        stats['hr_stats'] = hrStats;
      } catch (e) {
        stats['hr_stats'] = {'error': e.toString()};
      }

      // Try to get executive stats
      try {
        final execStats = await ApiClient.getExecutiveAnalytics();
        stats['exec_stats'] = execStats;
      } catch (e) {
        stats['exec_stats'] = {'error': e.toString()};
      }

      setState(() {
        _adminStats = stats;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Admin Role'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onPrimary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Admin Interface',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have multiple admin roles. Please select which interface to access.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  if (_adminStats != null) ...[
                    const SizedBox(height: 24),
                    _buildStatsSummary(_adminStats!),
                  ],
                  const SizedBox(height: 32),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        if (widget.availableRoles.contains('payment_admin'))
                          _buildRoleCard(
                            context,
                            'Payment Admin',
                            'Verify and manage payments',
                            Icons.payment,
                            colors.primary,
                            _getPaymentStats(_adminStats),
                            () => context.go('/admin/payment'),
                          ),
                        if (widget.availableRoles.contains('hr_admin'))
                          _buildRoleCard(
                            context,
                            'HR Admin',
                            'Manage Personnel',
                            Icons.badge_rounded,
                            colors.secondary,
                            _getHRStats(_adminStats),
                            () => context.go('/admin/hr'),
                          ),
                        if (widget.availableRoles.contains('executive_admin'))
                          _buildRoleCard(
                            context,
                            'Executive Dashboard',
                            'C-suite insights and analytics',
                            Icons.business_center,
                            colors.tertiary,
                            _getExecStats(_adminStats),
                            () => context.go('/admin/executive'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSummary(Map<String, dynamic> stats) {
    int pendingPayments = 0;
    int activeLearners = 0;
    double totalRevenue = 0.0;

    // Parse payment stats
    if (stats['payment_stats'] is Map &&
        stats['payment_stats']['pending'] != null) {
      pendingPayments = (stats['payment_stats']['pending'] as List).length;
    }

    // Parse HR stats
    if (stats['hr_stats'] is Map &&
        stats['hr_stats']['active_learners'] != null) {
      activeLearners = stats['hr_stats']['active_learners'] as int;
    }

    // Parse executive stats
    if (stats['exec_stats'] is Map && stats['exec_stats']['revenue'] != null) {
      totalRevenue = (stats['exec_stats']['revenue'] as num).toDouble();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              '$pendingPayments',
              'Pending Payments',
              Icons.pending_actions,
              Colors.orange,
            ),
            _buildStatItem(
              '$activeLearners',
              'Instructors',
              Icons.people_outline,
              Colors.green,
            ),
            _buildStatItem(
              '\$${totalRevenue.toStringAsFixed(0)}',
              'Total Revenue',
              Icons.attach_money,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _getPaymentStats(Map<String, dynamic>? stats) {
    if (stats == null || stats['payment_stats'] == null) return '';
    final paymentStats = stats['payment_stats'];
    if (paymentStats is Map) {
      final pending = paymentStats['pending']?.length ?? 0;
      final verified = paymentStats['verified']?.length ?? 0;
      final rejected = paymentStats['rejected']?.length ?? 0;
      return '$pending pending, $verified verified, $rejected rejected';
    }
    return '';
  }

  String _getHRStats(Map<String, dynamic>? stats) {
    if (stats == null || stats['hr_stats'] == null) return '';
    final hrStats = stats['hr_stats'];
    if (hrStats is Map) {
      final instructors = hrStats['instructors']?['total'] ?? 0;
      final activeNow = hrStats['attendance']?['active_now'] ?? 0;
      final pendingOT = hrStats['overtime']?['pending_count'] ?? 0;

      return '$instructors instructors, $activeNow active, $pendingOT OT requests';
    }
    return '';
  }

  String _getExecStats(Map<String, dynamic>? stats) {
    if (stats == null || stats['exec_stats'] == null) return '';
    final execStats = stats['exec_stats'];
    if (execStats is Map) {
      final revenue = execStats['revenue'] ?? 0;
      final growth = execStats['growth'] ?? 0;
      return '\$${(revenue as num).toStringAsFixed(0)} revenue, ${growth}% growth';
    }
    return '';
  }

  Widget _buildRoleCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    String stats,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              if (stats.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    stats,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
