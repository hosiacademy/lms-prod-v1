// lib/src/presentation/pages/admin/executive_admin_page.dart
// Optimized Executive Dashboard with Country Filtering & Strategic Analytics

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/auth_service.dart';
import '../../widgets/headers/dashboard_header.dart';

/// Executive Admin Page - OPTIMIZED
/// C-Suite level access with comprehensive strategic insights
/// Country-based filtering, financial intelligence, and operational analytics
class ExecutiveAdminPage extends StatefulWidget {
  const ExecutiveAdminPage({super.key});

  @override
  State<ExecutiveAdminPage> createState() => _ExecutiveAdminPageState();
}

class _ExecutiveAdminPageState extends State<ExecutiveAdminPage> {
  bool _isLoading = false;
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _financialInsights = {};
  Map<String, dynamic> _countryComparison = {};
  
  String _selectedPeriod = 'month'; // day, week, month, quarter, year
  String? _selectedCountry;
  List<Map<String, dynamic>> _allowedCountries = [];
  
  String _userName = 'Admin';
  String _userEmail = '';
  
  // Date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCountryRestrictions();
    _loadAllAnalytics();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getUserName();
    final email = await AuthService.getUserEmail();
    if (mounted) {
      setState(() {
        _userName = name ?? 'Executive';
        _userEmail = email ?? '';
      });
    }
  }

  Future<void> _loadCountryRestrictions() async {
    try {
      final roleData = await ApiClient.get('/api/v1/admin/role-assignment/');
      if (roleData.data != null && roleData.data['countries'] != null) {
        setState(() {
          _allowedCountries = List<Map<String, dynamic>>.from(
            roleData.data['countries']
          );
          if (_allowedCountries.length == 1) {
            _selectedCountry = _allowedCountries.first['code'];
          }
        });
      }
    } catch (e) {
      debugPrint('Could not load country restrictions: $e');
    }
  }

  Future<void> _loadAllAnalytics() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadDashboardAnalytics(),
        _loadFinancialInsights(),
        _loadCountryComparison(),
      ]);
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load analytics: $e')),
        );
      }
    }
  }

  Future<void> _loadDashboardAnalytics() async {
    try {
      final queryParams = <String, dynamic>{
        'period': _selectedPeriod,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
      };
      if (_selectedCountry != null) {
        queryParams['country'] = _selectedCountry;
      }
      
      final response = await ApiClient.getExecutiveDashboardAnalytics(
        queryParams: queryParams,
      );
      
      if (mounted) {
        setState(() {
          _analytics = response;
          if (response['filters'] != null && 
              response['filters']['allowed_countries'] != null) {
            _allowedCountries = List<Map<String, dynamic>>.from(
              response['filters']['allowed_countries']
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard analytics: $e');
    }
  }

  Future<void> _loadFinancialInsights() async {
    try {
      final response = await ApiClient.getExecutiveFinancialInsights(
        period: _selectedPeriod,
        country: _selectedCountry,
      );

      if (mounted) {
        setState(() => _financialInsights = response);
      }
    } catch (e) {
      debugPrint('Error loading financial insights: $e');
    }
  }

  Future<void> _loadCountryComparison() async {
    try {
      final response = await ApiClient.getExecutiveCountryComparison(
        period: _selectedPeriod,
      );
      
      if (mounted) {
        setState(() => _countryComparison = response);
      }
    } catch (e) {
      debugPrint('Error loading country comparison: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return DefaultTabController(
      length: 5,
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
                title: Text('Executive',
                    style: TextStyle(color: colors.onPrimary)),
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
                userDesignation: 'Chief Executive Officer',
                userImageUrl: null,
                isAdmin: true,
                notificationCount: 2,
                showMenuButton: false,
                showBackButton: false,
                showCart: false,
                showWishlist: false,
                onNotificationsTap: () {},
                onProfileTap: () {},
                onLogout: () async {
                  await AuthService.logout();
                  if (context.mounted) context.go('/onboarding');
                },
              ),
            if (!isMobile)
              Container(
                color: colors.surface,
                child: Column(
                  children: [
                    _buildFiltersBar(colors),
                    _buildTabBar(colors, screenWidth),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildDashboardTab(colors),
                        _buildFinancialsTab(colors),
                        _buildPerformanceTab(colors),
                        _buildCountriesTab(colors),
                        _buildMarketingTab(colors),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _exportReport,
          backgroundColor: colors.secondary,
          foregroundColor: colors.onSecondary,
          icon: const Icon(Icons.download),
          label: const Text('Export Report'),
        ),
      ),
    );
  }

  Widget _buildFiltersBar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Country Filter
          if (_allowedCountries.length > 1) ...[
            Text('Country:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                )),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Countries')),
                  ..._allowedCountries.map((country) => DropdownMenuItem(
                    value: country['code'],
                    child: Text(country['name'] ?? country['code']),
                  )),
                ],
                onChanged: (value) {
                  setState(() => _selectedCountry = value);
                  _loadAllAnalytics();
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Period Selector
          Text('Period:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              )),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'day', child: Text('Today')),
                DropdownMenuItem(value: 'week', child: Text('This Week')),
                DropdownMenuItem(value: 'month', child: Text('This Month')),
                DropdownMenuItem(value: 'quarter', child: Text('This Quarter')),
                DropdownMenuItem(value: 'year', child: Text('This Year')),
              ],
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
                _loadAllAnalytics();
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Refresh Button
          IconButton(
            onPressed: _loadAllAnalytics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colors, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      child: TabBar(
        isScrollable: screenWidth < 1200,
        indicatorColor: colors.primary,
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurface,
        labelPadding: EdgeInsets.symmetric(horizontal: screenWidth < 1200 ? 12 : 16),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Dashboard'),
          Tab(icon: Icon(Icons.attach_money_rounded, size: 20), text: 'Financials'),
          Tab(icon: Icon(Icons.show_chart_rounded, size: 20), text: 'Performance'),
          Tab(icon: Icon(Icons.public_rounded, size: 20), text: 'Countries'),
          Tab(icon: Icon(Icons.mark_email_read_rounded, size: 20), text: 'Marketing'),
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
              'EXECUTIVE DASHBOARD',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard_rounded, 'Dashboard', 0),
          _buildDrawerItem(context, Icons.attach_money_rounded, 'Financials', 1),
          _buildDrawerItem(context, Icons.show_chart_rounded, 'Performance', 2),
          _buildDrawerItem(context, Icons.public_rounded, 'Countries', 3),
          _buildDrawerItem(context, Icons.mark_email_read_rounded, 'Marketing', 4),
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

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 1: STRATEGIC DASHBOARD
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDashboardTab(ColorScheme colors) {
    final strategicKpis = _analytics['strategic_kpis'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Executive Strategic Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _selectedCountry != null
                        ? 'Country: ${_getCountryName(_selectedCountry!)}'
                        : 'Global View - All Countries',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _loadAllAnalytics,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Strategic KPIs
          _buildStrategicKPICards(colors, strategicKpis),
          const SizedBox(height: 32),
          
          // Revenue Trend
          _buildRevenueTrendChart(colors),
          const SizedBox(height: 32),
          
          // Top Performers
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTopCourses(colors)),
              const SizedBox(width: 24),
              Expanded(child: _buildEnrollmentByType(colors)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategicKPICards(
      ColorScheme colors, Map<String, dynamic> strategicKpis) {
    final revenue = strategicKpis['revenue'] as Map? ?? {};
    final customers = strategicKpis['customers'] as Map? ?? {};
    final enrollments = strategicKpis['enrollments'] as Map? ?? {};
    final operations = strategicKpis['operations'] as Map? ?? {};
    
    final totalRevenue = revenue['total'] ?? 0.0;
    final revenueGrowth = revenue['growth_rate'] ?? 0.0;
    final mrr = revenue['mrr'] ?? 0.0;
    final arr = revenue['arr'] ?? 0.0;
    
    final totalCustomers = customers['total'] ?? 0;
    final newCustomers = customers['new'] ?? 0;
    final customerGrowth = customers['growth_rate'] ?? 0.0;
    
    final totalEnrollments = enrollments['total'] ?? 0;
    final activeLearners = enrollments['active_learners'] ?? 0;
    final completionRate = enrollments['completion_rate'] ?? 0.0;
    
    final totalCourses = operations['total_courses'] ?? 0;
    final totalInstructors = operations['total_instructors'] ?? 0;
    final pendingVerifications = operations['pending_verifications'] ?? 0;

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildKPICardWithGrowth(
          'Total Revenue',
          CurrencyService.instance.formatPrice(totalRevenue),
          '${revenueGrowth >= 0 ? '+' : ''}${revenueGrowth}%',
          revenueGrowth >= 0,
          Icons.attach_money,
          Colors.green,
          colors,
        ),
        _buildKPICardWithGrowth(
          'MRR',
          CurrencyService.instance.formatPrice(mrr),
          'ARR: ${CurrencyService.instance.formatPrice(arr)}',
          true,
          Icons.trending_up,
          Colors.blue,
          colors,
        ),
        _buildKPICardWithGrowth(
          'Total Customers',
          totalCustomers.toString(),
          '+$newCustomers this period (${customerGrowth >= 0 ? '+' : ''}${customerGrowth}%)',
          customerGrowth >= 0,
          Icons.people,
          Colors.purple,
          colors,
        ),
        _buildKPICard(
          'Active Learners',
          activeLearners.toString(),
          Icons.school,
          colors.primary,
          colors,
        ),
        _buildKPICard(
          'Completion Rate',
          '${completionRate.toStringAsFixed(1)}%',
          Icons.verified,
          Colors.orange,
          colors,
        ),
        _buildKPICard(
          'Courses',
          totalCourses.toString(),
          Icons.library_books,
          Colors.teal,
          colors,
        ),
        _buildKPICard(
          'Instructors',
          totalInstructors.toString(),
          Icons.person,
          Colors.indigo,
          colors,
        ),
        _buildKPICard(
          'Pending Verifications',
          pendingVerifications.toString(),
          Icons.hourglass_empty,
          Colors.red,
          colors,
        ),
      ],
    );
  }

  Widget _buildKPICardWithGrowth(
    String label,
    String value,
    String growth,
    bool isPositive,
    IconData icon,
    Color color,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      growth.replaceAll(RegExp(r'[+%]'), ''),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTrendChart(ColorScheme colors) {
    final revenueAnalytics = _analytics['revenue_analytics'] as Map? ?? {};
    final trend = revenueAnalytics['trend'] as List? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: trend.isEmpty
                  ? const Center(child: Text('No revenue data available'))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '\$${(value / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: trend.length > 10 ? 2 : 1,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= trend.length) {
                                  return const Text('');
                                }
                                final date = DateTime.parse(trend[value.toInt()]['date']);
                                return Text(
                                  DateFormat('dd MMM').format(date),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: trend.asMap().entries.map((e) {
                              return FlSpot(
                                e.key.toDouble(),
                                (e.value['revenue'] ?? 0).toDouble(),
                              );
                            }).toList(),
                            isCurved: true,
                            color: colors.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: colors.primary.withValues(alpha: 0.1),
                            ),
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

  Widget _buildTopCourses(ColorScheme colors) {
    final topPerformers = _analytics['top_performers'] as Map? ?? {};
    final courses = topPerformers['courses'] as List? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Courses by Revenue',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (courses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No course data available')),
              )
            else
              ...courses.take(5).map((course) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title'] ?? 'Unknown Course',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${course['enrollments']} enrollments',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyService.instance.formatPrice(
                        course['revenue'] ?? 0,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentByType(ColorScheme colors) {
    final enrollmentAnalytics = _analytics['enrollment_analytics'] as Map? ?? {};
    final byType = enrollmentAnalytics['by_course_type'] as List? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enrollments by Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (byType.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No enrollment data')),
              )
            else
              ...byType.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['type'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item['count']} (${item['percentage']}%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (item['percentage'] ?? 0) / 100,
                      backgroundColor: colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  // Placeholder tabs for remaining content
  Widget _buildFinancialsTab(ColorScheme colors) {
    return const Center(child: Text('Financial Insights Tab - Coming Soon'));
  }

  Widget _buildPerformanceTab(ColorScheme colors) {
    return const Center(child: Text('Performance Analytics Tab - Coming Soon'));
  }

  Widget _buildCountriesTab(ColorScheme colors) {
    return const Center(child: Text('Country Comparison Tab - Coming Soon'));
  }

  Widget _buildMarketingTab(ColorScheme colors) {
    return const Center(child: Text('Marketing Funnel Tab - Coming Soon'));
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting executive report...')),
    );
  }

  String _getCountryName(String code) {
    final country = _allowedCountries.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'name': code},
    );
    return country['name'] ?? code;
  }
}
