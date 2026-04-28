// lib/src/presentation/pages/admin/marketing_admin_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/src/core/api/api_client.dart';
import 'package:frontend/src/core/services/auth_service.dart';
import 'package:frontend/src/core/services/currency_service.dart';
import '../../widgets/headers/dashboard_header.dart';
import 'marketing/marketing_sidebar.dart';
import 'marketing/quotations_view.dart';
import 'marketing/messaging_view.dart';
import 'package:frontend/src/core/utils/responsive_helper.dart';

class MarketingAdminPage extends StatefulWidget {
  const MarketingAdminPage({super.key});

  @override
  State<MarketingAdminPage> createState() => _MarketingAdminPageState();
}

class _MarketingAdminPageState extends State<MarketingAdminPage> {
  bool _isLoading = true;
  String _userName = 'Marketing Admin';
  String _selectedSection = 'summary';

  // Filters
  String? _selectedCountry;
  List<Map<String, dynamic>> _allowedCountries = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Marketing data
  Map<String, dynamic> _marketingStats = {};
  List<Map<String, dynamic>> _wishlistLeads = [];
  List<Map<String, dynamic>> _recentConversions = [];
  List<Map<String, dynamic>> _trainingTypeBreakdown = [];

  // Sales data
  Map<String, dynamic> _salesStats = {};
  List<Map<String, dynamic>> _revenueByCountry = [];
  List<Map<String, dynamic>> _revenueByType = [];

  // Partner apps
  List<Map<String, dynamic>> _partnerApplications = [];

  @override
  void initState() {
    super.initState();
    CurrencyService.instance.initialize();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final name = await AuthService.getUserName();
      await _loadCountryRestrictions();
      await _refreshData();
      if (mounted) {
        setState(() {
          _userName = name ?? 'Marketing Admin';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCountryRestrictions() async {
    try {
      final roleData = await ApiClient.get('/api/v1/admin/role-assignment/');
      if (roleData.data?['countries'] != null) {
        setState(() {
          _allowedCountries =
              List<Map<String, dynamic>>.from(roleData.data['countries']);
          if (_allowedCountries.length == 1) {
            _selectedCountry = _allowedCountries.first['code'];
          }
        });
      }
    } catch (_) {
      final countries = await ApiClient.getAfricanCountries();
      setState(() => _allowedCountries = countries);
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadMarketing(),
      _loadSales(),
      _loadPartners(),
    ]);
  }

  Future<void> _loadMarketing() async {
    try {
      final params = <String, dynamic>{};
      if (_selectedCountry != null) params['country'] = _selectedCountry;
      final data =
          await ApiClient.getMarketingAnalytics(limit: 50, queryParams: params);
      if (mounted) {
        setState(() {
          _marketingStats = data['stats'] ?? {};
          _wishlistLeads =
              List<Map<String, dynamic>>.from(data['high_priority_leads'] ?? []);
          _recentConversions =
              List<Map<String, dynamic>>.from(data['recent_conversions'] ?? []);
          _trainingTypeBreakdown =
              List<Map<String, dynamic>>.from(data['by_training_type'] ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSales() async {
    try {
      final params = <String, dynamic>{
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
      };
      if (_selectedCountry != null) params['country'] = _selectedCountry;
      final data =
          await ApiClient.getPaymentAdminSalesAnalytics(queryParams: params);
      if (mounted) {
        setState(() {
          _salesStats = data['stats'] ?? {};
          _revenueByCountry =
              List<Map<String, dynamic>>.from(data['revenue_by_country'] ?? []);
          _revenueByType = List<Map<String, dynamic>>.from(
              data['revenue_by_course_type'] ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPartners() async {
    try {
      final apps = await ApiClient.getPartnerApplications();
      if (mounted) setState(() => _partnerApplications = apps);
    } catch (_) {}
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: colors.surface,
      // ── Drawer (mobile only) ──
      drawer: isMobile
          ? Drawer(
              child: MarketingSidebar(
                selectedSection: _selectedSection,
                onSectionChanged: (s) {
                  setState(() => _selectedSection = s);
                  Navigator.pop(context);
                },
                userName: _userName,
              ),
            )
          : null,

      body: Column(
        children: [
          // ── Header ──
          DashboardHeader(
            userName: _userName,
            userDesignation: 'Marketing Admin',
            isAdmin: false,
            showMenuButton: isMobile,
            showCart: false,
            showWishlist: false,
            onLogout: () async {
              await AuthService.logout();
              if (context.mounted) context.go('/onboarding');
            },
          ),

          // ── Main layout ──
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  Container(
                    width: ResponsiveHelper.sidebarWidth(context),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        right: BorderSide(
                          color: colors.outline.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: MarketingSidebar(
                      selectedSection: _selectedSection,
                      onSectionChanged: (s) =>
                          setState(() => _selectedSection = s),
                      userName: _userName,
                    ),
                  ),
                // Content area
                Expanded(child: _buildContent(theme, colors)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Content router ───────────────────────────────────────────────────────

  Widget _buildContent(ThemeData theme, ColorScheme colors) {
    switch (_selectedSection) {
      case 'leads':
        return _buildLeadsView(theme, colors);
      case 'revenue':
        return _buildSalesView(theme, colors);
      case 'partners':
        return _buildPartnersView(theme, colors);
      case 'quotations':
        return QuotationsView(selectedCountry: _selectedCountry);
      case 'messaging':
        return MessagingView(selectedCountry: _selectedCountry);
      default:
        return _buildSummaryView(theme, colors);
    }
  }

  // ─── Filter bar ───────────────────────────────────────────────────────────

  Widget _buildFilterBar(ThemeData theme, ColorScheme colors) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.padding(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border:
            Border(bottom: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (!isMobile) Icon(Icons.filter_list, size: 18, color: colors.onSurface.withValues(alpha: 0.5)),
          SizedBox(
            width: isMobile ? double.infinity : 190,
            child: DropdownButtonFormField<String>(
              value: _selectedCountry,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                labelText: 'Country',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Countries', overflow: TextOverflow.ellipsis)),
                ..._allowedCountries.map((c) =>
                    DropdownMenuItem(value: c['code'], child: Text(c['name'], overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) {
                setState(() => _selectedCountry = v);
                _refreshData();
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange:
                    DateTimeRange(start: _startDate, end: _endDate),
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                });
                _refreshData();
              }
            },
            icon: const Icon(Icons.calendar_today, size: 14),
            label: Text(
                '${DateFormat('MMM d').format(_startDate)} – ${DateFormat('MMM d').format(_endDate)}',
                style: const TextStyle(fontSize: 13)),
          ),
          if (!isMobile) ...[
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _refreshData,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Summary view ─────────────────────────────────────────────────────────

  Widget _buildSummaryView(ThemeData theme, ColorScheme colors) {
    final padding = ResponsiveHelper.padding(context);
    
    return Column(
      children: [
        _buildFilterBar(theme, colors),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1000;
              
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Marketing Summary',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    // Stat cards
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _statCard('Total Leads',
                            _marketingStats['total_leads']?.toString() ?? '0',
                            colors.primary, theme, constraints.maxWidth),
                        _statCard('Conversions',
                            _marketingStats['enrollment_conversions']?.toString() ?? '0',
                            Colors.green, theme, constraints.maxWidth),
                        _statCard('Conv. Rate',
                            '${_marketingStats['enrollment_conversion_rate'] ?? 0}%',
                            Colors.orange, theme, constraints.maxWidth),
                        _statCard('Total Revenue',
                            CurrencyService.instance.formatUSDAmount(double.tryParse(_salesStats['total_revenue']?.toString() ?? '0') ?? 0),
                            Colors.teal, theme, constraints.maxWidth),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (isNarrow) ...[
                      _buildLeadsCard(theme, colors),
                      const SizedBox(height: 20),
                      _buildTypeCard(theme, colors),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildLeadsCard(theme, colors)),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: _buildTypeCard(theme, colors)),
                        ],
                      ),
                    const SizedBox(height: 20),
                    _buildConversionsCard(theme, colors),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color, ThemeData theme, [double? maxWidth]) {
    final width = maxWidth ?? MediaQuery.of(context).size.width;
    final cardWidth = width < 600 ? (width - 48) : 220.0;
    
    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLeadsCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('High Priority Leads',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                  onPressed: () =>
                      setState(() => _selectedSection = 'leads'),
                  child: const Text('View All')),
            ]),
            const SizedBox(height: 12),
            if (_wishlistLeads.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No high priority leads')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _wishlistLeads.length > 5 ? 5 : _wishlistLeads.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final lead = _wishlistLeads[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(lead['learner_name'] ?? 'Guest'),
                    subtitle: Text('${lead['course_title']} (${lead['training_type']})'),
                    trailing: Chip(
                      label: Text('${lead['days_waiting']}d',
                          style: TextStyle(
                              fontSize: 11,
                              color: (lead['days_waiting'] as int? ?? 0) > 14
                                  ? Colors.red
                                  : Colors.orange)),
                      backgroundColor:
                          ((lead['days_waiting'] as int? ?? 0) > 14
                                  ? Colors.red
                                  : Colors.orange)
                              .withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interest by Type',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._trainingTypeBreakdown.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['type'].toString().toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(item['count'].toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                        value: (item['count'] as num) / 100,
                        backgroundColor: colors.surfaceContainerHighest,
                        color: colors.primary),
                  ]),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionsCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Conversions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_recentConversions.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No conversions yet')))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Learner')),
                    DataColumn(label: Text('Program')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Days')),
                    DataColumn(label: Text('Converted')),
                  ],
                  rows: _recentConversions.map((c) => DataRow(cells: [
                        DataCell(Text(c['learner_name'] ?? 'Guest')),
                        DataCell(Text(c['course_title'] ?? 'N/A')),
                        DataCell(Text(c['training_type'] ?? 'N/A')),
                        DataCell(Text(c['days_in_funnel']?.toString() ?? '0')),
                        DataCell(Text(c['converted_at'] != null
                            ? DateFormat('MMM d, yy')
                                .format(DateTime.parse(c['converted_at']))
                            : 'N/A')),
                      ])).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Leads view ───────────────────────────────────────────────────────────

  Widget _buildLeadsView(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        _buildFilterBar(theme, colors),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lead Funnel Analytics',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildLeadsCard(theme, colors),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Revenue / Sales view ─────────────────────────────────────────────────

  Widget _buildSalesView(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        _buildFilterBar(theme, colors),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue Analytics',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _statCard('Avg. Order',
                        'R ${_salesStats['avg_order_value'] ?? 0}',
                        Colors.purple, theme),
                    _statCard('Transactions',
                        _salesStats['total_transactions']?.toString() ?? '0',
                        Colors.indigo, theme),
                    _statCard('Refund Rate',
                        '${_salesStats['refund_rate'] ?? 0}%',
                        Colors.red, theme),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _revenueByCountryCard(theme, colors)),
                    const SizedBox(width: 20),
                    Expanded(child: _revenueByTypeCard(theme, colors)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _revenueByCountryCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue by Country',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _revenueByCountry.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = _revenueByCountry[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.public, color: Colors.blueAccent, size: 20),
                  title: Text(item['country_name'] ?? 'Unknown'),
                  subtitle: Text('${item['count']} transactions'),
                  trailing: Text('R ${item['revenue']}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _revenueByTypeCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue by Program Type',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._revenueByType.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['type'] ?? 'Other',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('R ${item['revenue']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ]),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                          value: (item['percentage'] as num) / 100,
                          backgroundColor: colors.surfaceContainerHighest,
                          color: Colors.indigo),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ─── Partners view ────────────────────────────────────────────────────────

  Widget _buildPartnersView(ThemeData theme, ColorScheme colors) {
    if (_partnerApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined,
                size: 64, color: colors.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No partner applications found.',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Partner Applications',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _partnerApplications.length,
            itemBuilder: (context, i) {
              final app = _partnerApplications[i];
              final isPending = app['status'] == 'PENDING';
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: Icon(Icons.handshake,
                      color: isPending
                          ? Colors.orange
                          : (app['status'] == 'APPROVED'
                              ? Colors.green
                              : Colors.red)),
                  title: Text('${app['full_name']} — ${app['business_name'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Status: ${app['status']} | Reach: ${app['estimated_reach']}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${app['email']}'),
                          Text('Phone: ${app['phone']}'),
                          const SizedBox(height: 8),
                          Text('Notes: ${app['notes']}'),
                          if (isPending) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _updatePartner(app['id'], 'reject'),
                                  child: const Text('Reject',
                                      style: TextStyle(color: Colors.red)),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () =>
                                      _updatePartner(app['id'], 'approve'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updatePartner(int id, String action) async {
    try {
      await ApiClient.updatePartnerApplicationStatus(id, action);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Application ${action}d')));
      _loadPartners();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
