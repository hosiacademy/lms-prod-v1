// lib/src/presentation/pages/dashboard/admin_analytics_dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Comprehensive Admin Analytics Dashboard
///
/// Displays all critical LMS analytics based on industry standards:
/// - Learning Analytics
/// - Performance Metrics
/// - Revenue Analytics
/// - User Engagement
/// - Course Performance
/// - Instructor Analytics
/// - Certificate Analytics
class AdminAnalyticsDashboard extends StatefulWidget {
  const AdminAnalyticsDashboard({super.key});

  @override
  State<AdminAnalyticsDashboard> createState() => _AdminAnalyticsDashboardState();
}

class _AdminAnalyticsDashboardState extends State<AdminAnalyticsDashboard> {
  String _selectedTimeRange = '30days';
  bool _isLoading = false;

  // Mock data - will be replaced with API calls
  final Map<String, dynamic> _analyticsData = {
    'kpis': {
      'completion_rate': 85.4,
      'completion_trend': 5.2,
      'engagement_score': 72.3,
      'engagement_trend': 8.1,
      'active_users_dau': 1245,
      'active_users_trend': 12.5,
      'revenue_month': 125430.00,
      'revenue_trend': 18.3,
      'satisfaction_score': 4.6,
      'satisfaction_trend': 0.3,
      'avg_completion_time': 28,
      'completion_time_trend': -3,
      'revenue_per_user': 245.50,
      'revenue_per_user_trend': 18.00,
      'retention_rate': 82.0,
      'retention_trend': 2.0,
    },
    'learning': {
      'total_enrollments': 8420,
      'new_enrollments_today': 45,
      'courses_in_progress': 3201,
      'courses_completed': 5219,
      'avg_time_to_complete_days': 28,
      'at_risk_learners': 156,
    },
    'revenue': {
      'total': 425890.00,
      'by_source': {
        'masterclass': 185240.00,
        'learnership': 142650.00,
        'industry_training': 68900.00,
        'aicerts': 29100.00,
      },
      'transactions_success': 1840,
      'transactions_failed': 23,
      'refunds_count': 12,
      'refunds_amount': 3600.00,
    },
    'courses': {
      'total_courses': 148,
      'masterclasses': 12,
      'learnerships': 10,
      'industry_trainings': 38,
      'aicerts': 88,
    },
    'instructors': {
      'total_instructors': 24,
      'active_instructors': 18,
      'avg_instructor_rating': 4.7,
    },
    'certificates': {
      'issued_total': 5219,
      'issued_this_month': 342,
      'expired': 48,
      'due_for_renewal': 156,
      'by_type': {
        'masterclass': 892,
        'learnership': 1245,
        'industry': 1823,
        'aicerts': 1259,
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with time range selector
            _buildHeader(theme, colors),
            const SizedBox(height: 32),

            // Critical KPIs Row (Top 8)
            _buildKPICards(theme, colors),
            const SizedBox(height: 32),

            // Learning Analytics Section
            _buildLearningAnalytics(theme, colors),
            const SizedBox(height: 32),

            // Revenue Analytics Section
            _buildRevenueAnalytics(theme, colors),
            const SizedBox(height: 32),

            // Course Performance Section
            _buildCoursePerformance(theme, colors),
            const SizedBox(height: 32),

            // Instructor & Certificate Analytics
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildInstructorAnalytics(theme, colors)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildCertificateAnalytics(theme, colors)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Trends Section
            _buildTrendsSection(theme, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Dashboard',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            Text(
              'Comprehensive LMS Performance Metrics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        // Time range selector
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: '7days', label: Text('7 Days')),
            ButtonSegment(value: '30days', label: Text('30 Days')),
            ButtonSegment(value: '90days', label: Text('90 Days')),
          ],
          selected: {_selectedTimeRange},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedTimeRange = newSelection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildKPICards(ThemeData theme, ColorScheme colors) {
    final kpis = _analyticsData['kpis'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Performance Indicators',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Row 1: Top 4 KPIs
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                icon: Icons.task_alt,
                label: 'Completion Rate',
                value: '${kpis['completion_rate']}%',
                trend: '${kpis['completion_trend'] >= 0 ? '+' : ''}${kpis['completion_trend']}%',
                isPositive: kpis['completion_trend'] >= 0,
                color: colors.primary,
                theme: theme,
                colors: colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                icon: Icons.trending_up,
                label: 'Engagement Score',
                value: '${kpis['engagement_score']}',
                trend: '${kpis['engagement_trend'] >= 0 ? '+' : ''}${kpis['engagement_trend']} pts',
                isPositive: kpis['engagement_trend'] >= 0,
                color: colors.secondary,
                theme: theme,
                colors: colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                icon: Icons.people,
                label: 'Active Users (DAU)',
                value: NumberFormat.decimalPattern().format(kpis['active_users_dau']),
                trend: '${kpis['active_users_trend'] >= 0 ? '+' : ''}${kpis['active_users_trend']}%',
                isPositive: kpis['active_users_trend'] >= 0,
                color: Colors.green,
                theme: theme,
                colors: colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                icon: Icons.attach_money,
                label: 'Revenue/Month',
                value: '\$${NumberFormat('#,##0.00').format(kpis['revenue_month'])}',
                trend: '${kpis['revenue_trend'] >= 0 ? '+' : ''}${kpis['revenue_trend']}%',
                isPositive: kpis['revenue_trend'] >= 0,
                color: Colors.orange,
                theme: theme,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 2: Next 4 KPIs
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                icon: Icons.star,
                label: 'Satisfaction Score',
                value: '${kpis['satisfaction_score']}/5.0',
                trend: '${kpis['satisfaction_trend'] >= 0 ? '+' : ''}${kpis['satisfaction_trend']}',
                isPositive: kpis['satisfaction_trend'] >= 0,
                color: Colors.amber,
                theme: theme,
                colors: colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                icon: Icons.schedule,
                label: 'Avg Time to Complete',
                value: '${kpis['avg_completion_time']} days',
                trend: '${kpis['completion_time_trend']} days',
                isPositive: kpis['completion_time_trend'] < 0, // Lower is better
                color: Colors.purple,
                theme: theme,
                colors: colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                icon: Icons.monetization_on,
                label: 'Revenue/User',
                value: '\$${NumberFormat('#,##0.00').format(kpis['revenue_per_user'])}',
                trend: '+\$${NumberFormat('#,##0.00').format(kpis['revenue_per_user_trend'])}',
                isPositive: true,
                color: Colors.teal,
                theme: theme,
                colors: colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                icon: Icons.loyalty,
                label: 'Retention Rate',
                value: '${kpis['retention_rate']}%',
                trend: '${kpis['retention_trend'] >= 0 ? '+' : ''}${kpis['retention_trend']}%',
                isPositive: kpis['retention_trend'] >= 0,
                color: Colors.blue,
                theme: theme,
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required String label,
    required String value,
    required String trend,
    required bool isPositive,
    required Color color,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.2),
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
                      trend,
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
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

  Widget _buildLearningAnalytics(ThemeData theme, ColorScheme colors) {
    final learning = _analyticsData['learning'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Analytics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.school,
                    label: 'Total Enrollments',
                    value: NumberFormat.decimalPattern().format(learning['total_enrollments']),
                    color: colors.primary,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.trending_up,
                    label: 'New Today',
                    value: '${learning['new_enrollments_today']}',
                    color: Colors.green,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.hourglass_bottom,
                    label: 'In Progress',
                    value: NumberFormat.decimalPattern().format(learning['courses_in_progress']),
                    color: Colors.orange,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: NumberFormat.decimalPattern().format(learning['courses_completed']),
                    color: Colors.green,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.warning,
                    label: 'At-Risk Learners',
                    value: '${learning['at_risk_learners']}',
                    color: Colors.red,
                    theme: theme,
                    isAlert: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (isAlert) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: const Text('View Details'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenueAnalytics(ThemeData theme, ColorScheme colors) {
    final revenue = _analyticsData['revenue'] as Map<String, dynamic>;
    final bySource = revenue['by_source'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Analytics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue summary
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildRevenueMetric(
                        'Total Revenue',
                        '\$${NumberFormat('#,##0.00').format(revenue['total'])}',
                        colors.primary,
                        theme,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRevenueMetric(
                              'Successful Transactions',
                              '${revenue['transactions_success']}',
                              Colors.green,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildRevenueMetric(
                              'Failed Transactions',
                              '${revenue['transactions_failed']}',
                              Colors.red,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRevenueMetric(
                              'Refunds Count',
                              '${revenue['refunds_count']}',
                              Colors.orange,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildRevenueMetric(
                              'Refunds Amount',
                              '\$${NumberFormat('#,##0.00').format(revenue['refunds_amount'])}',
                              Colors.orange,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 32),

                // Revenue by source (pie chart)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenue by Source',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: bySource['masterclass'],
                                      title: 'Master\nclass',
                                      color: colors.primary,
                                      radius: 80,
                                      titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value: bySource['learnership'],
                                      title: 'Learner\nship',
                                      color: colors.secondary,
                                      radius: 80,
                                      titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value: bySource['industry_training'],
                                      title: 'Industry',
                                      color: colors.tertiary,
                                      radius: 80,
                                      titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value: bySource['aicerts'],
                                      title: 'AICERTS',
                                      color: Colors.grey,
                                      radius: 80,
                                      titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem('Masterclass', '\$${NumberFormat('#,##0').format(bySource['masterclass'])}', colors.primary),
                                const SizedBox(height: 8),
                                _buildLegendItem('Learnership', '\$${NumberFormat('#,##0').format(bySource['learnership'])}', colors.secondary),
                                const SizedBox(height: 8),
                                _buildLegendItem('Industry Training', '\$${NumberFormat('#,##0').format(bySource['industry_training'])}', colors.tertiary),
                                const SizedBox(height: 8),
                                _buildLegendItem('AICERTS', '\$${NumberFormat('#,##0').format(bySource['aicerts'])}', Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueMetric(String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildCoursePerformance(ThemeData theme, ColorScheme colors) {
    final courses = _analyticsData['courses'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Performance',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildCourseTypeCard(
                    icon: Icons.stars,
                    label: 'Masterclasses',
                    count: courses['masterclasses'],
                    color: colors.primary,
                    description: 'Created by Admin',
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCourseTypeCard(
                    icon: Icons.school,
                    label: 'Learnerships',
                    count: courses['learnerships'],
                    color: colors.secondary,
                    description: 'Created by Admin',
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCourseTypeCard(
                    icon: Icons.business,
                    label: 'Industry Training',
                    count: courses['industry_trainings'],
                    color: colors.tertiary,
                    description: 'Created by Admin',
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCourseTypeCard(
                    icon: Icons.sync,
                    label: 'AICERTS Courses',
                    count: courses['aicerts'],
                    color: Colors.grey,
                    description: 'Synced (Read-Only)',
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Total Active Courses: ${courses['total_courses']}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseTypeCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required String description,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorAnalytics(ThemeData theme, ColorScheme colors) {
    final instructors = _analyticsData['instructors'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instructor Analytics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildSimpleMetric('Total Instructors', '${instructors['total_instructors']}', Icons.people, colors.primary, theme),
            const SizedBox(height: 16),
            _buildSimpleMetric('Active Instructors', '${instructors['active_instructors']}', Icons.person, Colors.green, theme),
            const SizedBox(height: 16),
            _buildSimpleMetric('Avg Instructor Rating', '${instructors['avg_instructor_rating']}/5.0', Icons.star, Colors.amber, theme),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                // Navigate to full instructor management
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Full Instructor Analytics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateAnalytics(ThemeData theme, ColorScheme colors) {
    final certificates = _analyticsData['certificates'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certificate Analytics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildSimpleMetric('Total Issued', NumberFormat.decimalPattern().format(certificates['issued_total']), Icons.card_membership, colors.primary, theme),
            const SizedBox(height: 16),
            _buildSimpleMetric('Issued This Month', '${certificates['issued_this_month']}', Icons.new_releases, Colors.green, theme),
            const SizedBox(height: 16),
            _buildSimpleMetric('Expired', '${certificates['expired']}', Icons.error, Colors.red, theme),
            const SizedBox(height: 16),
            _buildSimpleMetric('Due for Renewal', '${certificates['due_for_renewal']}', Icons.update, Colors.orange, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMetric(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsSection(ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trends & Insights',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Placeholder for trend charts
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 64, color: colors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Enrollment & Revenue Trends (Last 30 Days)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Interactive charts will be displayed here',
                      style: theme.textTheme.bodySmall,
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
