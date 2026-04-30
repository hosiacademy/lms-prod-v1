// lib/src/presentation/pages/admin/payment_admin_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/currency_service.dart';
import '../../widgets/headers/dashboard_header.dart';

/// **Payment Operations Admin Dashboard - OPTIMIZED**
/// 
/// Comprehensive dashboard for Payment Administrators managing:
/// - In-office cash payments and verification
/// - Provisional enrollments (cash pending & learnership verification)
/// - Country-filtered operations (based on role assignment)
/// 
/// **Key Features:**
/// 1. Country-based filtering from role assignment
/// 2. Cash payment verification workflow
/// 3. Provisional enrollment management
/// 4. Revenue tracking by country, payment method, course type
class PaymentAdminPage extends StatefulWidget {
  const PaymentAdminPage({super.key});

  @override
  State<PaymentAdminPage> createState() => _PaymentAdminPageState();
}

class _PaymentAdminPageState extends State<PaymentAdminPage> {
  bool _isLoading = true;
  String _userName = 'Admin';
  
  // Country filtering from role assignment
  List<Map<String, dynamic>> _allowedCountries = [];
  String? _selectedCountry; // null = all countries

  // Operational Data
  List<Map<String, dynamic>> _provisionalEnrollments = [];
  List<Map<String, dynamic>> _cashPayments = [];
  List<Map<String, dynamic>> _eftPayments = []; // EFT/Bank Transfer payments
  List<Map<String, dynamic>> _gatewayTransactions = []; // Card/Digital payments
  List<Map<String, dynamic>> _verifiedEnrollments = [];
  List<Map<String, dynamic>> _rejectedEnrollments = [];
  Map<String, dynamic> _summaryStats = {};
  
  // Search
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Failed Provisioning Data
  List<Map<String, dynamic>> _failedProvisioning = [];
  Map<String, dynamic> _failedProvisioningSummary = {};
  String _failedProvisioningStatusFilter = 'all';
  String _failedProvisioningDaysFilter = '30';
  
  // Quotation System Data
  List<Map<String, dynamic>> _quotations = [];
  bool _isLoadingQuotations = false;

  // Date range filter
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final name = await AuthService.getUserName();

      // Load country restrictions from role assignment
      await _loadCountryRestrictions();

      // Load all operational data with country filter
      await _loadOperationalData();

      // Load failed provisioning data
      await _loadFailedProvisioningData();

      // Load quotations
      await _loadQuotations();

      if (mounted) {
        setState(() {
          _userName = name ?? 'Payment Admin';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadCountryRestrictions() async {
    try {
      // Fetch role assignment with countries of operation
      final roleData = await ApiClient.get('/api/v1/admin/role-assignment/');
      if (roleData.data != null && roleData.data['countries'] != null) {
        setState(() {
          _allowedCountries = List<Map<String, dynamic>>.from(
            roleData.data['countries']
          );
          // Default to first country if only one allowed
          if (_allowedCountries.length == 1) {
            _selectedCountry = _allowedCountries.first['code'];
          }
        });
      }
    } catch (e) {
      debugPrint('Could not load country restrictions: $e');
      // If no restrictions, show all countries
      final countries = await ApiClient.getAfricanCountries();
      setState(() {
        _allowedCountries = countries;
      });
    }
  }

  Future<void> _loadOperationalData() async {
    try {
      final queryParams = <String, dynamic>{};
      if (_selectedCountry != null) {
        queryParams['country'] = _selectedCountry;
      }
      queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(_startDate);
      queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate);

      final operationalData = await ApiClient.getOperationalAdminData(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        queryParams: queryParams,
      );

      // Load EFT payments separately
      List<Map<String, dynamic>> eftPayments = [];
      try {
        final eftData = await ApiClient.get('/api/v1/payments/eft/admin/pending/');
        if (eftData.data != null && eftData.data['results'] != null) {
          eftPayments = List<Map<String, dynamic>>.from(eftData.data['results']);
        }
      } catch (e) {
        debugPrint('Could not load EFT payments: $e');
      }

      setState(() {
        _provisionalEnrollments = List<Map<String, dynamic>>.from(
          operationalData['provisional_enrollments'] ?? []
        );
        _cashPayments = List<Map<String, dynamic>>.from(
          operationalData['cash_payments'] ?? []
        );
        _eftPayments = eftPayments;
        _gatewayTransactions = List<Map<String, dynamic>>.from(
          operationalData['gateway_transactions'] ?? []
        );
        _verifiedEnrollments = List<Map<String, dynamic>>.from(
          operationalData['verified_enrollments'] ?? []
        );
        _rejectedEnrollments = List<Map<String, dynamic>>.from(
          operationalData['rejected_enrollments'] ?? []
        );
        _summaryStats = operationalData['summary'] ?? {};
      });
    } catch (e) {
      debugPrint('Error loading operational data: $e');
    }
  }

  Future<void> _loadFailedProvisioningData() async {
    try {
      final data = await ApiClient.getFailedProvisioningData(
        status: _failedProvisioningStatusFilter,
        days: _failedProvisioningDaysFilter,
      );

      setState(() {
        _failedProvisioning = List<Map<String, dynamic>>.from(
          data['failed_provisioning'] ?? []
        );
        _failedProvisioningSummary = data['summary'] ?? {};
      });
    } catch (e) {
      debugPrint('Error loading failed provisioning data: $e');
    }
  }

  Future<void> _loadQuotations() async {
    try {
      final queryParams = <String, dynamic>{};
      if (_selectedCountry != null) {
        queryParams['country'] = _selectedCountry;
      }
      
      final quotationData = await ApiClient.getQuotations(
        country: _selectedCountry,
      );

      setState(() {
        _quotations = List<Map<String, dynamic>>.from(
          quotationData['results'] ?? []
        );
      });
    } catch (e) {
      debugPrint('Error loading quotations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return DefaultTabController(
      length: 7,
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
                title: Text('Payment Operations',
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
                userDesignation: 'Payment & Operations Administrator',
                isAdmin: true,
                showMenuButton: false,
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
                        _buildDashboardOverview(theme, colors),
                        _buildCashPaymentsView(theme, colors),
                        _buildGatewayPaymentsView(theme, colors),
                        _buildVerificationView(theme, colors),
                        _buildEnrollmentsView(theme, colors),
                        _buildFailedProvisioningView(theme, colors),
                        _buildQuotationView(theme, colors),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActions(colors),
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
          // Search Bar
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, Email, or Reference...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _loadData();
                      },
                    )
                  : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value);
                _loadData();
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Country Filter
          if (_allowedCountries.length > 1) ...[
            Text(
              'Country:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
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
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Countries'),
                  ),
                  ..._allowedCountries.map((country) => DropdownMenuItem(
                    value: country['code'],
                    child: Text(country['name'] ?? country['code']),
                  )),
                ],
                onChanged: (value) {
                  setState(() => _selectedCountry = value);
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Date Range Filter
          Text(
            'Period:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'From',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        DateFormat('dd MMM').format(_startDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'To',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        DateFormat('dd MMM').format(_endDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Refresh Button
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  Widget _buildTabBar(ColorScheme colors, double screenWidth) {
    final pendingCount = _provisionalEnrollments.length;
    
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
        tabs: [
          const Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Overview'),
          Tab(
            icon: Badge(
              label: Text('${_cashPayments.length + _eftPayments.length}'),
              isLabelVisible: (_cashPayments.length + _eftPayments.length) > 0,
              child: const Icon(Icons.pending_actions_rounded, size: 20),
            ),
            text: 'Pending Payments',
          ),
          Tab(
            icon: Badge(
              label: Text('${_gatewayTransactions.length}'),
              isLabelVisible: _gatewayTransactions.isNotEmpty,
              child: const Icon(Icons.credit_card_rounded, size: 20),
            ),
            text: 'Card Payments',
          ),
          Tab(
            icon: Badge(
              label: pendingCount > 0 ? Text('$pendingCount') : null,
              isLabelVisible: pendingCount > 0,
              child: const Icon(Icons.verified_user_rounded, size: 20),
            ),
            text: 'Verification',
          ),
          const Tab(icon: Icon(Icons.assignment_rounded, size: 20), text: 'Enrollments'),
          Tab(
            icon: Badge(
              label: _failedProvisioningSummary['pending_review'] != null &&
                      (_failedProvisioningSummary['pending_review'] as int) > 0
                  ? Text('${_failedProvisioningSummary['pending_review']}')
                  : null,
              isLabelVisible: _failedProvisioningSummary['pending_review'] != null &&
                  (_failedProvisioningSummary['pending_review'] as int) > 0,
              child: const Icon(Icons.error_outline_rounded, size: 20),
            ),
            text: 'Failed Provisioning',
          ),
          const Tab(
            icon: Icon(Icons.description_outlined, size: 20),
            text: 'Quotations',
          ),
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
              'PAYMENT OPERATIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard_rounded, 'Overview', 0),
          _buildDrawerItem(context, Icons.pending_actions_rounded, 'Pending Payments', 1),
          _buildDrawerItem(context, Icons.verified_user_rounded, 'Verification', 2),
          _buildDrawerItem(context, Icons.assignment_rounded, 'Enrollments', 3),
          _buildDrawerItem(context, Icons.error_outline_rounded, 'Failed Provisioning', 4),
          _buildDrawerItem(context, Icons.description_outlined, 'Quotations', 5),
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

  Widget _buildFloatingActions(ColorScheme colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'refresh',
          onPressed: _loadData,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          child: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 1: DASHBOARD OVERVIEW
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDashboardOverview(ThemeData theme, ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                    'Payment Operations Overview',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _selectedCountry != null
                        ? 'Country: ${_getCountryName(_selectedCountry!)}'
                        : 'All Countries',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // KPI Cards
          _buildKPICardsGrid(theme, colors),
          const SizedBox(height: 32),

          // Charts Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildPaymentDistributionChart(theme, colors),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildOperationalSummary(theme, colors),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Recent Activity
          _buildRecentActivitySection(theme, colors),
        ],
      ),
    );
  }

  Widget _buildKPICardsGrid(ThemeData theme, ColorScheme colors) {
    final totalRevenue = _summaryStats['total_revenue'] ?? 0.0;
    final pendingCash = _cashPayments.length;
    final pendingEft = _eftPayments.length;
    final pendingVerification = _provisionalEnrollments.length;
    final verifiedToday = _verifiedEnrollments
        .where((e) => _isToday(e['verified_at']))
        .length;

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          'Total Revenue',
          CurrencyService.instance.formatPrice(totalRevenue),
          Icons.attach_money,
          Colors.green,
          colors,
        ),
        _buildKPICard(
          'Cash Pending',
          '$pendingCash',
          Icons.money_rounded,
          Colors.orange,
          colors,
        ),
        _buildKPICard(
          'EFT Pending',
          '$pendingEft',
          Icons.account_balance_rounded,
          Colors.blue,
          colors,
        ),
        _buildKPICard(
          'Awaiting Verification',
          '$pendingVerification',
          Icons.verified_user_rounded,
          Colors.blue,
          colors,
        ),
        _buildKPICard(
          'Verified Today',
          '$verifiedToday',
          Icons.check_circle_rounded,
          Colors.green,
          colors,
        ),
      ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  Widget _buildPaymentDistributionChart(ThemeData theme, ColorScheme colors) {
    final cashRevenue = _cashPayments.fold<double>(0, (sum, item) => sum + (item['amount'] ?? 0.0));
    final eftRevenue = _eftPayments.fold<double>(0, (sum, item) => sum + (item['amount'] ?? 0.0));
    final cardRevenue = _gatewayTransactions.fold<double>(0, (sum, item) => sum + (item['amount'] ?? 0.0));
    final total = cashRevenue + eftRevenue + cardRevenue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Distribution',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: total == 0 
                ? const Center(child: Text('No revenue data for this period'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.orange,
                          value: cashRevenue,
                          title: '${(cashRevenue / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.blue,
                          value: eftRevenue,
                          title: '${(eftRevenue / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.green,
                          value: cardRevenue,
                          title: '${(cardRevenue / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChartLegend('Cash', Colors.orange),
                _buildChartLegend('EFT', Colors.blue),
                _buildChartLegend('Card', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildOperationalSummary(ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operational Summary',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildSummaryRow('Pending Cash', '${_cashPayments.length}', Colors.orange),
            _buildSummaryRow('Pending EFT', '${_eftPayments.length}', Colors.blue),
            _buildSummaryRow('Card Payments', '${_gatewayTransactions.length}', Colors.green),
            _buildSummaryRow('Verified Today', '${_verifiedEnrollments.where((e) => _isToday(e['verified_at'])).length}', Colors.green),
            _buildSummaryRow('Failed Provisioning', '${_failedProvisioningSummary['pending_review'] ?? 0}', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[..._cashPayments, ..._eftPayments].take(10).map((payment) {
              final isEft = payment['payment_method'] == 'eft' || payment['payment_method'] == 'eft_online';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isEft ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                  child: Icon(
                    isEft ? Icons.account_balance_rounded : Icons.money_rounded, 
                    color: isEft ? Colors.blue : Colors.orange,
                    size: 18,
                  ),
                ),
                title: Text(payment['learner_name'] ?? payment['customer_name'] ?? 'Unknown'),
                subtitle: Text('Course: ${payment['course_title'] ?? payment['program_title'] ?? 'N/A'}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyService.instance.formatPrice(
                        payment['amount'] ?? 0,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('dd MMM').format(
                        DateTime.parse(payment['created_at'] ?? DateTime.now().toIso8601String()),
                      ),
                      style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
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

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 2: PAYMENTS (CASH + IN-PERSON + ONLINE EFT)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildCashPaymentsView(ThemeData theme, ColorScheme colors) {
    // Combine cash payments and EFT payments
    final allPayments = [
      ..._cashPayments.map((p) => {...p, 'payment_method': 'cash'}),
      ..._eftPayments.map((p) => {...p, 'payment_method': 'eft_online'}),
    ];

    if (allPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_rounded, size: 80, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No pending payments',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cash, EFT, and in-person payments will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: allPayments.length,
      itemBuilder: (context, index) {
        final payment = allPayments[index];
        final isEft = payment['payment_method'] == 'eft_online';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isEft 
                          ? colors.secondary.withValues(alpha: 0.1)
                          : colors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        isEft ? Icons.account_balance : Icons.money,
                        color: isEft ? colors.secondary : colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment['learner_name'] ?? payment['customer_name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            payment['course_title'] ?? payment['program_title'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isEft ? colors.secondary.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEft ? Icons.account_balance : Icons.money,
                            size: 12,
                            color: isEft ? colors.secondary : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isEft ? 'EFT Online' : 'Cash/In-Person',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isEft ? colors.secondary : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email: ${payment['email'] ?? payment['customer_email'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phone: ${payment['phone'] ?? payment['customer_phone'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyService.instance.formatPrice(payment['amount'] ?? 0),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ref: ${payment['reference_code'] ?? payment['reference']}',
                          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isEft) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Transfer Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (payment['bank_details_submitted'] == true) ...[
                          Text(
                            '✓ Customer submitted bank details',
                            style: TextStyle(fontSize: 11, color: colors.secondary),
                          ),
                        ],
                        if (payment['proof_of_payment_uploaded'] == true) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '✓ Proof of payment uploaded',
                                style: TextStyle(fontSize: 11, color: colors.secondary),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _viewProofOfPayment(payment['reference'] ?? payment['reference_code']),
                                icon: const Icon(Icons.image_search_rounded, size: 16),
                                label: const Text('View Proof', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                        if (payment['time_remaining'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '⏱ ${payment['time_remaining']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: payment['is_expired'] == true ? Colors.red : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _verifyPayment(payment, 'verified'),
                        icon: const Icon(Icons.check, color: Colors.green),
                        label: const Text('Verify', style: TextStyle(color: Colors.green)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _verifyPayment(payment, 'rejected'),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Verification method for both Cash and EFT payments
  Future<void> _verifyPayment(Map<String, dynamic> payment, String status) async {
    final isEft = payment['payment_method'] == 'eft_online';
    final reference = payment['reference_code'] ?? payment['reference'];
    
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(status == 'verified' ? 'Verify Payment' : 'Reject Payment'),
          content: Text(
            status == 'verified'
                ? 'Confirm you have verified this payment in your bank statement?\n\nReference: $reference'
                : 'Are you sure you want to reject this payment?\n\nReference: $reference',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(status == 'verified' ? 'Verify' : 'Reject',
                style: TextStyle(
                  color: status == 'verified' ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (isEft) {
        // Verify EFT payment via API
        await ApiClient.post(
          '/api/v1/payments/admin/eft/verify/$reference/',
          data: {'notes': 'Verified by admin via payment dashboard'},
        );
      } else {
        // Verify cash/in-person payment
        await ApiClient.post(
          '/api/v1/payments/admin/verify/${payment['id']}/',
          data: {
            'status': status,
            'notes': 'Verified by admin via payment dashboard',
            'payment_method': 'cash',
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment ${status == 'verified' ? 'verified' : 'rejected'} successfully'),
            backgroundColor: status == 'verified' ? Colors.green : Colors.red,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewProofOfPayment(String reference) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Proof of Payment'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 800,
          child: Column(
            children: [
              Text('Reference: $reference', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '${ApiClient.baseUrl}/api/v1/payments/eft/admin/pop/$reference/',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Could not load proof of payment image.'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                // Fallback: open in browser
                              },
                              child: const Text('Try opening in browser'),
                            ),
                          ],
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 3: GATEWAY PAYMENTS (SmatPay, Card, etc.)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildGatewayPaymentsView(ThemeData theme, ColorScheme colors) {
    if (_gatewayTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off_rounded, size: 80, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No gateway transactions found',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gateway Transactions (Digital Payments)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_gatewayTransactions.length} Total',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            DataTable(
              headingRowColor: WidgetStateProperty.all(colors.surfaceContainerHighest.withValues(alpha: 0.3)),
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Reference')),
                DataColumn(label: Text('Learner')),
                DataColumn(label: Text('Provider')),
                DataColumn(label: Text('Amount (Local)')),
                DataColumn(label: Text('Amount (USD)')),
                DataColumn(label: Text('Status')),
              ],
              rows: _gatewayTransactions.map((tx) {
                final date = DateTime.parse(tx['created_at'] ?? DateTime.now().toIso8601String());
                final isSuccessful = tx['status'] == 'successful' || tx['status'] == 'completed';
                
                return DataRow(
                  cells: [
                    DataCell(Text(DateFormat('dd MMM HH:mm').format(date))),
                    DataCell(Text(tx['reference'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx['learner_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(tx['email'] ?? '', style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
                      ],
                    )),
                    DataCell(Text(tx['provider']?.toString().toUpperCase() ?? 'N/A')),
                    DataCell(Text('${tx['currency'] ?? 'USD'} ${tx['amount']}')),
                    DataCell(Text('USD ${tx['amount_usd']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSuccessful ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tx['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSuccessful ? Colors.green : Colors.orange,
                        ),
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 4: VERIFICATION QUEUE
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildVerificationView(ThemeData theme, ColorScheme colors) {
    if (_provisionalEnrollments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_rounded, size: 80, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'All enrollments verified',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _provisionalEnrollments.length,
      itemBuilder: (context, index) {
        final enrollment = _provisionalEnrollments[index];
        final isLearnership = enrollment['enrollment_type'] == 'learnership';
        final expiryDate = DateTime.parse(
          enrollment['expires_at'] ?? DateTime.now().toIso8601String(),
        );
        final isExpiringSoon = expiryDate.difference(DateTime.now()).inDays < 3;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: isExpiringSoon ? Colors.orange.withValues(alpha: 0.05) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isLearnership ? colors.secondary.withValues(alpha: 0.1) : colors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        isLearnership ? Icons.school : Icons.money,
                        color: isLearnership ? colors.secondary : colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            enrollment['learner_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            enrollment['course_title'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLearnership ? colors.secondary.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isLearnership ? 'Learnership' : 'Cash',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isLearnership ? colors.secondary : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${DateFormat('dd MMM yyyy').format(expiryDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpiringSoon ? Colors.orange : colors.onSurfaceVariant,
                        fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (enrollment['verification_notes'] != null &&
                    enrollment['verification_notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${enrollment['verification_notes']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _verifyProvisionalEnrollment(
                          enrollment['id'],
                          'confirmed',
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Confirm'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectionDialog(enrollment),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 4: ENROLLMENTS HISTORY
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildEnrollmentsView(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        // Summary Cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Verified',
                  _verifiedEnrollments.length.toString(),
                  Colors.green,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Rejected',
                  _rejectedEnrollments.length.toString(),
                  Colors.red,
                  Icons.cancel_rounded,
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _verifiedEnrollments.length,
            itemBuilder: (context, index) {
              final enrollment = _verifiedEnrollments[index];
              final method = (enrollment['payment_method'] ?? 'unknown').toString().toUpperCase();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    child: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  title: Row(
                    children: [
                      Text(enrollment['learner_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          method,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(enrollment['course_title'] ?? 'N/A'),
                      Text('Ref: ${enrollment['reference'] ?? 'N/A'}', style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyService.instance.formatPrice(enrollment['amount'] ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(
                          DateTime.parse(
                            enrollment['verified_at'] ?? DateTime.now().toIso8601String(),
                          ),
                        ),
                        style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailedProvisioningView(ThemeData theme, ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Failed Provisioning Management',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review and retry failed enrollment provisioning after successful payments',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Summary Statistics
          _buildFailedProvisioningSummary(theme, colors),
          const SizedBox(height: 32),

          // Filters
          _buildFailedProvisioningFilters(theme, colors),
          const SizedBox(height: 24),

          // Failed Provisioning Table
          _buildFailedProvisioningTable(theme, colors),
        ],
      ),
    );
  }

  Widget _buildFailedProvisioningSummary(ThemeData theme, ColorScheme colors) {
    final totalSuccessful = _failedProvisioningSummary['total_successful_payments'] ?? 0;
    final totalProvisioned = _failedProvisioningSummary['total_provisioned'] ?? 0;
    final totalFailed = _failedProvisioningSummary['total_failed'] ?? 0;
    final pendingReview = _failedProvisioningSummary['pending_review'] ?? 0;
    final successRate = _failedProvisioningSummary['success_rate'] ?? 0.0;
    final failureRate = _failedProvisioningSummary['failure_rate'] ?? 0.0;

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 6 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          'Total Successful Payments',
          totalSuccessful.toString(),
          Icons.check_circle_outline_rounded,
          Colors.green,
          colors,
        ),
        _buildKPICard(
          'Successfully Provisioned',
          totalProvisioned.toString(),
          Icons.verified_rounded,
          Colors.blue,
          colors,
        ),
        _buildKPICard(
          'Failed After Retries',
          totalFailed.toString(),
          Icons.error_outline_rounded,
          Colors.red,
          colors,
        ),
        _buildKPICard(
          'Pending Review',
          pendingReview.toString(),
          Icons.pending_actions_rounded,
          Colors.orange,
          colors,
        ),
        _buildKPICard(
          'Success Rate',
          '${successRate.toStringAsFixed(1)}%',
          Icons.trending_up_rounded,
          Colors.green,
          colors,
        ),
        _buildKPICard(
          'Failure Rate',
          '${failureRate.toStringAsFixed(1)}%',
          Icons.trending_down_rounded,
          Colors.red,
          colors,
        ),
      ],
    );
  }

  Widget _buildFailedProvisioningFilters(ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              'Status:',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'pending_review', label: Text('Pending')),
                ButtonSegment(value: 'retry_failed', label: Text('Failed')),
                ButtonSegment(value: 'resolved', label: Text('Resolved')),
              ],
              selected: {_failedProvisioningStatusFilter},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _failedProvisioningStatusFilter = selection.first;
                });
                _loadFailedProvisioningData();
              },
            ),
            const SizedBox(width: 24),
            Text(
              'Period:',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '7', label: Text('7D')),
                ButtonSegment(value: '30', label: Text('30D')),
                ButtonSegment(value: '90', label: Text('90D')),
              ],
              selected: {_failedProvisioningDaysFilter},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _failedProvisioningDaysFilter = selection.first;
                });
                _loadFailedProvisioningData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedProvisioningTable(ThemeData theme, ColorScheme colors) {
    if (_failedProvisioning.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: colors.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No failed provisioning cases',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All payments have been successfully provisioned',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(colors.surface),
          columns: const [
            DataColumn(label: Text('Transaction ID')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Error')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _failedProvisioning.map((item) {
            final status = item['provisioning_status'] ?? 'pending';
            final statusColor = status == 'resolved'
                ? Colors.green
                : status == 'retry_failed'
                    ? Colors.red
                    : Colors.orange;

            return DataRow(
              cells: [
                DataCell(
                  SelectableText(
                    item['transaction_id'] ?? 'N/A',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['user_name'] ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item['user_email'] ?? 'N/A',
                        style: TextStyle(fontSize: 12, color: colors.onSurface.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    '${CurrencyService.instance.formatPrice(item['amount'] ?? 0)} ${item['currency'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    (item['enrollment_type'] ?? 'Unknown').replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      item['provisioning_error'] ?? '-',
                      style: TextStyle(fontSize: 11, color: colors.onSurface.withOpacity(0.7)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status != 'resolved')
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          tooltip: 'Retry Provisioning',
                          onPressed: () => _retryProvisioning(
                            item['id'],
                            item['transaction_id'],
                            item['user_email'],
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.primary.withOpacity(0.1),
                            foregroundColor: colors.primary,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        tooltip: 'Mark as Resolved',
                        onPressed: () => _markProvisioningResolved(
                          item['id'],
                          item['transaction_id'],
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _retryProvisioning(
    String id,
    String transactionId,
    String userEmail,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Provisioning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction: $transactionId'),
            const SizedBox(height: 8),
            Text('User: $userEmail'),
            const SizedBox(height: 16),
            const Text(
              'This will attempt to provision enrollment again. Continue?',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await ApiClient.retryProvisioning(
        transactionId: id,
        notes: 'Manual retry initiated by admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Provisioning retried'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
        _loadFailedProvisioningData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markProvisioningResolved(
    String id,
    String transactionId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction: $transactionId'),
            const SizedBox(height: 16),
            const Text(
              'Mark this provisioning as manually resolved. Use this when enrollment was completed outside the system.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await ApiClient.markProvisioningResolved(
        transactionId: id,
        notes: 'Manually resolved by admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Marked as resolved'),
            backgroundColor: Colors.green,
          ),
        );
        _loadFailedProvisioningData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  // ──────────────────────────────────────────────────────────────────────────
  // TAB 8: QUOTATION MANAGEMENT
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildQuotationView(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        // Header with Create Action
        Container(
          padding: const EdgeInsets.all(24),
          color: colors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client Quotations',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Generate and manage professional training quotes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _showCreateQuotationDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Quotation'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Quotations List
        Expanded(
          child: _quotations.isEmpty
              ? _buildEmptyQuotationsView(theme, colors)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _quotations.length,
                  itemBuilder: (context, index) {
                    final quotation = _quotations[index];
                    return _buildQuotationCard(quotation, theme, colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyQuotationsView(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.description_outlined, size: 80, color: colors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'No quotations found',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by creating a new quotation for a client',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _showCreateQuotationDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create First Quotation'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCard(Map<String, dynamic> quotation, ThemeData theme, ColorScheme colors) {
    final status = quotation['status'] ?? 'draft';
    final statusColor = _getStatusColor(status);
    final trainingType = quotation['training_type_display'] ?? quotation['training_type'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description_rounded, color: statusColor),
                ),
                const SizedBox(width: 20),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            quotation['quotation_number'] ?? 'REF-NEW',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quotation['client_name'] ?? 'Guest Client',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${quotation['client_email']} • ${quotation['client_country']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$trainingType: ${quotation['training_item_name']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Price & Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${quotation['local_currency']} ${NumberFormat("#,##0.00").format(quotation['local_amount'] ?? 0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      'USD ${NumberFormat("#,##0.00").format(quotation['total_amount'] ?? 0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (quotation['email_sent'] == true)
                          const Tooltip(
                            message: 'Email Sent',
                            child: Icon(Icons.email_outlined, size: 16, color: Colors.green),
                          ),
                        if (quotation['sms_sent'] == true)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Tooltip(
                              message: 'SMS Sent',
                              child: Icon(Icons.sms_outlined, size: 16, color: Colors.green),
                            ),
                          ),
                        if (quotation['viewed_count'] > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Tooltip(
                              message: 'Viewed by Client',
                              child: Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.blue),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons Footer
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _sendQuotationEmail(quotation['id']),
                  icon: const Icon(Icons.email_rounded, size: 18),
                  label: const Text('Email'),
                ),
                TextButton.icon(
                  onPressed: () => _sendQuotationSMS(quotation['id']),
                  icon: const Icon(Icons.sms_rounded, size: 18),
                  label: const Text('SMS'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _viewQuotationPublic(quotation['quotation_number']),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  tooltip: 'View Web Quote',
                ),
                IconButton(
                  onPressed: () => _deleteQuotation(quotation['id']),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: Colors.red,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Colors.grey;
      case 'sent': return Colors.blue;
      case 'viewed': return Colors.purple;
      case 'accepted': return Colors.teal;
      case 'paid': return Colors.green;
      case 'expired': return Colors.red;
      default: return Colors.orange;
    }
  }

  // creation dialog state
  void _showCreateQuotationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateQuotationDialog(
        countries: _allowedCountries,
        onSuccess: () {
          _loadQuotations();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation created successfully'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  Future<void> _sendQuotationEmail(int id) async {
    try {
      await ApiClient.sendQuotationEmail(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation email sent')),
      );
      _loadQuotations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendQuotationSMS(int id) async {
    try {
      await ApiClient.sendQuotationSMS(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation SMS sent')),
      );
      _loadQuotations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SMS: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _viewQuotationPublic(String? number) {
    if (number == null) return;
    // Launch public URL
    final url = '/quotations/view/$number';
    // In a real app we'd use url_launcher
    debugPrint('Launching quotation view: $url');
    // For now we might just go there in router or mock it
    // context.push(url);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Public Link: $url (Routing to be implemented)')),
    );
  }

  Future<void> _deleteQuotation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: const Text('Are you sure you want to permanently delete this quotation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.delete('/api/v1/payments/quotations/$id/delete/');
      _loadQuotations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACTION HANDLERS
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _verifyCashPayment(String id, String status) async {
    try {
      await ApiClient.verifyProvisionalEnrollment(
        enrollmentId: int.parse(id.toString()),
        status: status,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment $status successfully'),
            backgroundColor: status == 'verified' ? Colors.green : Colors.red,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyProvisionalEnrollment(String id, String status) async {
    try {
      await ApiClient.verifyProvisionalEnrollment(
        enrollmentId: int.parse(id.toString()),
        status: status,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enrollment $status successfully'),
            backgroundColor: status == 'confirmed' ? Colors.green : Colors.red,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectionDialog(Map<String, dynamic> enrollment) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Enrollment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Learner: ${enrollment['learner_name']}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyProvisionalEnrollment(
                enrollment['id'],
                'rejected',
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting report...')),
    );
    // TODO: Implement PDF/CSV export
  }

  String _getCountryName(String code) {
    final country = _allowedCountries.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'name': code},
    );
    return country['name'] ?? code;
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}

class _CreateQuotationDialog extends StatefulWidget {
  final List<dynamic> countries;
  final VoidCallback onSuccess;

  const _CreateQuotationDialog({
    required this.countries,
    required this.onSuccess,
  });

  @override
  State<_CreateQuotationDialog> createState() => _CreateQuotationDialogState();
}

class _CreateQuotationDialogState extends State<_CreateQuotationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _referenceCodeController = TextEditingController();
  
  String? _selectedCountry;
  String? _selectedCurrency;
  String? _selectedType;
  dynamic _selectedItem;
  
  List<dynamic> _types = [];
  List<dynamic> _items = [];
  Map<String, dynamic>? _pricing;
  
  bool _isLoadingTypes = true;
  bool _isLoadingItems = false;
  bool _isLoadingPricing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await ApiClient.getQuotationTrainingTypes();
      setState(() {
        _types = types;
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTypes = false);
    }
  }

  Future<void> _loadItems(String type) async {
    setState(() {
      _isLoadingItems = true;
      _items = [];
      _selectedItem = null;
      _pricing = null;
    });
    
    try {
      final items = await ApiClient.getQuotationTrainingItems(
        type,
        country: _selectedCountry,
        currency: _selectedCurrency,
      );
      setState(() {
        _items = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _loadPricing() async {
    if (_selectedType == null || _selectedItem == null || _selectedCountry == null || _selectedCurrency == null) return;
    
    setState(() => _isLoadingPricing = true);
    try {
      final pricing = await ApiClient.getQuotationPricing(
        type: _selectedType!,
        itemId: _selectedItem['id'],
        country: _selectedCountry!,
        currency: _selectedCurrency!,
      );
      setState(() {
        _pricing = pricing;
        _isLoadingPricing = false;
      });
    } catch (e) {
      setState(() => _isLoadingPricing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null || _selectedCountry == null || _selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiClient.createQuotation({
        'client_name': _nameController.text,
        'client_email': _emailController.text,
        'client_phone': _phoneController.text,
        'client_address': _addressController.text,
        'client_reference_code': _referenceCodeController.text,
        'client_country': _selectedCountry,
        'local_currency': _selectedCurrency,
        'training_type': _selectedType,
        'training_item_id': _selectedItem['id'],
      });
      
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create quotation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.description_rounded, color: colors.primary),
          const SizedBox(width: 12),
          const Text('Generate Quotation'),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        width: MediaQuery.of(context).size.width * 0.9,
        child: _isLoadingTypes 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Client Details
                    _buildSectionHeader('Client Information'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _referenceCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Reference Code (e.g. HA2001)',
                              prefixIcon: Icon(Icons.tag),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Client Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                            decoration: const InputDecoration(
                              labelText: 'Client Country',
                              prefixIcon: Icon(Icons.public),
                            ),
                            items: widget.countries.map((c) => DropdownMenuItem(
                              value: c['code'].toString(),
                              child: Text(c['name'].toString()),
                            )).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedCountry = v;
                                if (v == 'ZA') _selectedCurrency = 'ZAR';
                                else if (v == 'ZW') _selectedCurrency = 'USD';
                                else if (v == 'KE') _selectedCurrency = 'KES';
                                else if (v == 'ZM') _selectedCurrency = 'ZMW';
                                else _selectedCurrency = 'USD';
                              });
                              if (_selectedType != null) _loadItems(_selectedType!);
                            },
                          ),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('Training Selection'),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Training Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _types.map((t) => DropdownMenuItem(
                        value: t['code'].toString(),
                        child: Text(t['name'].toString()),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedType = v);
                          _loadItems(v);
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (_isLoadingItems)
                      const LinearProgressIndicator()
                    else if (_selectedType != null)
                      DropdownButtonFormField<dynamic>(
                        value: _selectedItem,
                        decoration: const InputDecoration(
                          labelText: 'Select Program/Course',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: _items.map((i) => DropdownMenuItem(
                          value: i,
                          child: Text(i['name'].toString()),
                        )).toList(),
                        onChanged: (v) {
                          setState(() => _selectedItem = v);
                          _loadPricing();
                        },
                      ),
                      
                    if (_pricing != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Estimated Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(
                                  '${_selectedCurrency} ${NumberFormat("#,##0.00").format(_pricing!['local_price'])}',
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Base USD', style: TextStyle(fontSize: 10)),
                                Text(
                                  '\$${NumberFormat("#,##0.00").format(_pricing!['base_price_usd'])}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Generate Quotation'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}
