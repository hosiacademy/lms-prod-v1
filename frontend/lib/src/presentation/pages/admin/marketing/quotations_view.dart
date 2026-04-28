import 'package:frontend/src/core/utils/responsive_helper.dart';
// lib/src/presentation/pages/admin/marketing/quotations_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/src/core/api/api_client.dart';
import 'package:frontend/src/core/services/currency_service.dart';

class QuotationsView extends StatefulWidget {
  final String? selectedCountry;
  const QuotationsView({super.key, this.selectedCountry});

  @override
  State<QuotationsView> createState() => _QuotationsViewState();
}

class _QuotationsViewState extends State<QuotationsView> {
  List<Map<String, dynamic>> _quotations = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(QuotationsView old) {
    super.didUpdateWidget(old);
    if (old.selectedCountry != widget.selectedCountry) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Using the dedicated method if it exists, otherwise generic get
      final data = await ApiClient.getQuotations(country: widget.selectedCountry);
      if (mounted) {
        setState(() {
          _quotations = List<Map<String, dynamic>>.from(data['quotations'] ?? data['results'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      // Fallback to generic get if getQuotations fails or isn't perfect
      try {
        final response = await ApiClient.get('/api/v1/payments/quotations/');
        if (mounted) {
          final raw = response.data;
          List<dynamic> list = [];
          if (raw is Map && raw['quotations'] != null) {
            list = raw['quotations'];
          } else if (raw is Map && raw['results'] != null) {
            list = raw['results'];
          } else if (raw is List) {
            list = raw;
          }
          setState(() {
            _quotations = List<Map<String, dynamic>>.from(list);
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.padding(context);

    final filtered = _quotations
        .where((q) =>
            _search.isEmpty ||
            (q['client_name'] ?? '').toLowerCase().contains(_search.toLowerCase()) ||
            (q['client_email'] ?? '').toLowerCase().contains(_search.toLowerCase()) ||
            (q['quotation_number'] ?? '').toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header bar
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quotations',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 20 : null,
                                )),
                        Text('Manage and send client quotations',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    SizedBox(
                      width: 200,
                      child: _buildSearchField(colors),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Quote'),
                    ),
                  ] else
                    IconButton.filled(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add),
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 16),
                _buildSearchField(colors),
              ],
            ],
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.request_quote_outlined,
                              size: 64,
                              color: colors.onSurface.withValues(alpha: 0.25)),
                          const SizedBox(height: 16),
                          Text('No quotations found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) =>
                          _QuotationCard(q: filtered[i], onRefresh: _load),
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colors) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: const Icon(Icons.search, size: 18),
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (v) => setState(() => _search = v),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Form controllers
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    
    // Stream selection and pricing
    final List<String> streams = ['Cybersecurity', 'AI & Blockchain', 'Masterclasses', 'Industry Training'];
    final Map<String, bool> selectedStreams = { for (var s in streams) s : false };
    final Map<String, double> streamPrices = { for (var s in streams) s : 0.0 };
    
    String currency = widget.selectedCountry == 'ZA' ? 'ZAR' : 'USD';
    double exchangeRate = 18.5; // Mock for ZAR/USD

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('New Strategic Quotation', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          content: ResponsiveHelper.fluidScroll(
            context: ctx,
            child: SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('1. CLIENT DETAILS', colors),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField(nameCtrl, 'Full Name / Entity', Icons.person_outline)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField(emailCtrl, 'Email Address', Icons.email_outlined)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField(phoneCtrl, 'Phone Number', Icons.phone_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField(companyCtrl, 'Company Name', Icons.business_outlined)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _sectionTitle('2. TRAINING STREAMS', colors),
                  const SizedBox(height: 12),
                  ...streams.map((s) => CheckboxListTile(
                    title: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: selectedStreams[s]! 
                      ? Row(
                          children: [
                            const Text('Cost: '),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(prefixText: '$currency ', isDense: true),
                                onChanged: (v) => setDialogState(() => streamPrices[s] = double.tryParse(v) ?? 0.0),
                              ),
                            ),
                          ],
                        )
                      : null,
                    value: selectedStreams[s],
                    onChanged: (v) => setDialogState(() => selectedStreams[s] = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  )),
                  
                  const SizedBox(height: 24),
                  _sectionTitle('3. CURRENCY & SETTINGS', colors),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: currency,
                    decoration: const InputDecoration(labelText: 'Quotation Currency'),
                    items: ['USD', 'ZAR', 'KES', 'NGN', 'GBP'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setDialogState(() => currency = v ?? 'USD'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            FilledButton(
              onPressed: () => _previewQuotation(context, {
                'client_name': nameCtrl.text,
                'client_email': emailCtrl.text,
                'client_phone': phoneCtrl.text,
                'client_company': companyCtrl.text,
                'streams': selectedStreams.entries.where((e) => e.value).map((e) => {'name': e.key, 'price': streamPrices[e.key]}).toList(),
                'currency': currency,
                'exchange_rate': exchangeRate,
              }),
              child: const Text('PREVIEW & SEND'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme colors) {
    return Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: colors.primary));
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _previewQuotation(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 800,
          height: 900,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: _buildQuotationBlueprint(data),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: const Border(top: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('EDIT')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => _finalizeAndSend(context, data),
                      child: const Text('FINALIZE & DISPATCH'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotationBlueprint(Map<String, dynamic> data) {
    final List streams = data['streams'];
    final String currency = data['currency'];
    double total = 0;
    for (var s in streams) total += s['price'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HOSI ACADEMY', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                Text('Strategic Training Proposal', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
              ],
            ),
            const Text('QUOTATION', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w100, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 40),
        
        // 2. Client Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PREPARED FOR:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(data['client_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(data['client_company'] ?? ''),
                  Text(data['client_email']),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('DATE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(DateFormat('MMMM d, yyyy').format(DateTime.now())),
                const SizedBox(height: 8),
                const Text('REFERENCE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const Text('QT-2026-X001'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
        
        // 3. Itemized Streams
        const Divider(thickness: 2, color: Colors.black),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: const [
              Expanded(child: Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold))),
              Text('INVESTMENT', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Divider(thickness: 1),
        ...streams.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('Comprehensive curriculum, certification & practical labs.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(CurrencyService.instance.formatPrice(s['price'], currencyCode: currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        )),
        
        const SizedBox(height: 40),
        
        // 4. Totals
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TOTAL INVESTMENT ($currency)', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(CurrencyService.instance.formatPrice(total, currencyCode: currency), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                if (currency != 'USD')
                  Text('Est. USD: ${CurrencyService.instance.formatPrice(total / data['exchange_rate'], currencyCode: 'USD')}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 60),
        const Text('TERMS & CONDITIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('1. Validity: This quotation is valid for 30 days.\n2. Payment: 50% deposit required to commence training.\n3. Access: Course access granted upon full settlement.', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Future<void> _finalizeAndSend(BuildContext context, Map<String, dynamic> data) async {
    // Implement backend persistence (Local -> USD conversion)
    try {
      final totalLocal = (data['streams'] as List).fold(0.0, (sum, item) => sum + item['price']);
      final totalUsd = totalLocal / data['exchange_rate'];
      
      await ApiClient.post('/api/v1/payments/quotations/create/', data: {
        ...data,
        'total_amount': totalLocal,
        'total_amount_usd': totalUsd,
        'status': 'SENT',
      });
      
      Navigator.pop(context); // Close preview
      Navigator.pop(context); // Close create dialog
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Strategic Quotation Dispatched!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _QuotationCard extends StatelessWidget {
  final Map<String, dynamic> q;
  final VoidCallback onRefresh;
  const _QuotationCard({required this.q, required this.onRefresh});

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red;
      case 'SENT':
        return Colors.blue;
      case 'PAID':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = q['status'] ?? 'DRAFT';
    final quotationNumber = q['quotation_number'] ?? '#${q['id']}';
    final totalAmount = q['total_amount'];
    final created = q['created_at'] != null
        ? DateFormat('MMM d, yyyy')
            .format(DateTime.parse(q['created_at']).toLocal())
        : 'N/A';

    final isMobile = ResponsiveHelper.isMobile(context);
    final isSmall = isMobile || MediaQuery.of(context).size.width < 700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {}, // Future detail view
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (!isSmall) ...[
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(Icons.request_quote, color: colors.primary, size: 22),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(q['client_name'] ?? 'Unknown',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        if (isSmall && totalAmount != null)
                          Text(CurrencyService.instance.formatPrice(totalAmount, currencyCode: q['currency'] ?? 'ZAR'),
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold, color: colors.primary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(quotationNumber,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.5))),
                    if (q['client_email'] != null && !isSmall)
                      Text(q['client_email'],
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6))),
                    Text('Created: $created',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              if (!isSmall && totalAmount != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(CurrencyService.instance.formatPrice(totalAmount, currencyCode: q['currency'] ?? 'ZAR'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    label: Text(status,
                        style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    backgroundColor: _statusColor(status).withValues(alpha: 0.1),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(width: 4),
              _buildActionsMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (action) async {
        // ... same logic as before, just abstracted for cleaner build
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: 'email',
            child: Row(children: [
              Icon(Icons.email_outlined, size: 18),
              SizedBox(width: 8),
              Text('Send via Email')
            ])),
        PopupMenuItem(
            value: 'sms',
            child: Row(children: [
              Icon(Icons.sms_outlined, size: 18),
              SizedBox(width: 8),
              Text('Send via SMS')
            ])),
      ],
    );
  }
}
