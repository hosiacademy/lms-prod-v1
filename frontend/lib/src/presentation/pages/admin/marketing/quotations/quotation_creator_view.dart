import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/services/currency_service.dart';
import 'pdf_generator.dart';
import 'package:printing/printing.dart';

class QuotationCreatorView extends StatefulWidget {
  const QuotationCreatorView({super.key});

  @override
  State<QuotationCreatorView> createState() => _QuotationCreatorViewState();
}

class _QuotationCreatorViewState extends State<QuotationCreatorView> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientCompanyCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _introCtrl = TextEditingController();
  final _prereqCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  
  // State
  List<Map<String, dynamic>> _countries = [];
  Map<String, dynamic>? _selectedCountry;
  String _selectedCurrency = 'USD';
  double _exchangeRate = 1.0;
  bool _isUniversal = false;
  
  List<Map<String, dynamic>> _trainingStreams = [];
  String? _selectedStreamId;
  List<Map<String, dynamic>> _availableCourses = [];
  final List<Map<String, dynamic>> _selectedItems = [];
  
  bool _loading = false;
  bool _fetchingItems = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final countryResp = await ApiClient.getAfricanCountries();
      final streamResp = await ApiClient.get('/api/v1/payments/admin/marketing/quotations/training-types/');
      
      setState(() {
        _countries = List<Map<String, dynamic>>.from(countryResp);
        _trainingStreams = List<Map<String, dynamic>>.from(streamResp.data['types'] ?? []);
        _loading = false;
      });
    } catch (e) {
      _snack('Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _onStreamChanged(String? val) async {
    setState(() {
      _selectedStreamId = val;
      _availableCourses = [];
      _fetchingItems = true;
    });
    
    if (val == null) return;
    
    try {
      final resp = await ApiClient.get(
        '/api/v1/payments/admin/marketing/quotations/courses/',
        queryParameters: {'type': val}
      );
      setState(() {
        _availableCourses = List<Map<String, dynamic>>.from(resp.data['items'] ?? []);
        _fetchingItems = false;
      });
    } catch (e) {
      _snack('Error fetching items: $e');
      setState(() => _fetchingItems = false);
    }
  }

  Future<void> _onCountryChanged(Map<String, dynamic>? country) async {
    setState(() {
      _selectedCountry = country;
      _loading = true;
    });
    
    if (country == null || _isUniversal) {
      setState(() {
        _selectedCurrency = 'USD';
        _exchangeRate = 1.0;
        _loading = false;
      });
      return;
    }

    try {
      final rateResp = await ApiClient.getExchangeRates();
      // Get currency for country - assuming Geolocation logic or manual map
      // For now, simplify or fetch from backend currency view
      final rates = rateResp['rates'] as Map<String, dynamic>;
      
      // Basic African currency mapping if not in country object
      final countryCode = country['code']?.toString().toUpperCase() ?? 'US';
      String currency = 'USD';
      if (countryCode == 'ZA') currency = 'ZAR';
      else if (countryCode == 'ZW') currency = 'USD'; // ZW uses USD mostly for these
      else if (countryCode == 'KE') currency = 'KES';
      else if (countryCode == 'NG') currency = 'NGN';
      
      setState(() {
        _selectedCurrency = currency;
        _exchangeRate = (rates[currency] ?? 1.0).toDouble();
        _loading = false;
      });
    } catch (e) {
      _snack('Error fetching rates: $e');
      setState(() => _loading = false);
    }
  }

  void _addItem(Map<String, dynamic> item) {
    if (_selectedItems.any((si) => si['id'] == item['id'] && si['training_type'] == _selectedStreamId)) {
      _snack('Item already added');
      return;
    }
    setState(() {
      _selectedItems.add({
        ...item,
        'training_type': _selectedStreamId,
        'quantity': 1,
        'unit_price_usd': item['price'],
      });
    });
  }

  double get _subtotalUsd => _selectedItems.fold(0, (sum, item) => sum + (item['unit_price_usd'] * item['quantity']));
  double get _discountAmountUsd => _subtotalUsd * (double.tryParse(_discountCtrl.text) ?? 0) / 100;
  double get _totalUsd => _subtotalUsd - _discountAmountUsd;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, colors),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildForm(theme, colors)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildItemsSelector(theme, colors)),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(colors),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create New Quotation', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text('Generate multi-stream quotations with local currency conversion', 
             style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _buildForm(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        _sectionCard(
          title: 'Client Information',
          icon: Icons.person_outline,
          colors: colors,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _textField(_clientNameCtrl, 'Client Name', Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(child: _textField(_clientEmailCtrl, 'Email Address', Icons.email)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _textField(_clientPhoneCtrl, 'Phone Number', Icons.phone)),
                  const SizedBox(width: 12),
                  Expanded(child: _textField(_clientCompanyCtrl, 'Company', Icons.business)),
                ],
              ),
              const SizedBox(height: 12),
              _buildLocationRow(colors),
              const SizedBox(height: 12),
              _textField(_clientAddressCtrl, 'Physical Address', Icons.location_on, lines: 2),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Narrative Content',
          icon: Icons.article_outlined,
          colors: colors,
          child: Column(
            children: [
              _textField(_introCtrl, 'Introduction (Narrative)', Icons.short_text, lines: 3),
              const SizedBox(height: 12),
              _textField(_prereqCtrl, 'Prerequisites (Bullet separated)', Icons.list, lines: 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedCountry,
            decoration: _inputDecoration('Country', Icons.public, colors),
            items: _countries.map((c) => DropdownMenuItem(
              value: c,
              child: Text(c['name'] ?? ''),
            )).toList(),
            onChanged: _onCountryChanged,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _isUniversal, 
                onChanged: (v) {
                  setState(() => _isUniversal = v ?? false);
                  _onCountryChanged(_selectedCountry);
                },
              ),
              const Text('Universal (USD)', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSelector(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        _sectionCard(
          title: 'Select Training',
          icon: Icons.school_outlined,
          colors: colors,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedStreamId,
                decoration: _inputDecoration('Training Stream', Icons.stream, colors),
                items: _trainingStreams.map((s) => DropdownMenuItem(
                  value: s['id'],
                  child: Text(s['name'] ?? ''),
                )).toList(),
                onChanged: _onStreamChanged,
              ),
              const SizedBox(height: 12),
              if (_fetchingItems)
                const LinearProgressIndicator()
              else if (_availableCourses.isNotEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    itemCount: _availableCourses.length,
                    padding: const EdgeInsets.all(8),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _availableCourses[index];
                      return ListTile(
                        title: Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('Code: ${item['code']} | ${CurrencyService.instance.formatPrice(item['price'] is num ? (item['price'] as num).toDouble() : 0.0, currencyCode: 'USD')}', style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _addItem(item),
                          color: colors.primary,
                        ),
                        dense: true,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Selected Items',
          icon: Icons.shopping_cart_outlined,
          colors: colors,
          child: Column(
            children: [
              if (_selectedItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No items selected', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                )
              else
                ..._selectedItems.map((item) => _buildSelectedItemRow(item, colors)),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(CurrencyService.instance.formatPrice(_subtotalUsd, currencyCode: 'USD'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              _textField(_discountCtrl, 'Discount %', Icons.percent, keyboard: TextInputType.number),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemRow(Map<String, dynamic> item, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 12))),
          SizedBox(
            width: 40,
            child: TextField(
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              onChanged: (v) {
                setState(() {
                  item['quantity'] = int.tryParse(v) ?? 1;
                });
              },
              controller: TextEditingController(text: item['quantity'].toString()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            onPressed: () => setState(() => _selectedItems.remove(item)),
            color: colors.error,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required ColorScheme colors, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon, {int lines = 1, TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: _inputDecoration(label, icon, Theme.of(context).colorScheme),
      style: const TextStyle(fontSize: 13),
      onChanged: (_) => setState(() {}),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ColorScheme colors) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
    );
  }

  Widget _buildBottomBar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: _selectedItems.isEmpty ? null : _previewQuote,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview Quote'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _selectedItems.isEmpty ? null : _submitQuotation,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Generate & Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _previewQuote() async {
    final data = _prepareQuoteData();
    final pdfBytes = await QuotePdfGenerator.generate(data);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            children: [
              AppBar(title: const Text('Quotation Preview'), leading: const CloseButton()),
              Expanded(child: PdfPreview(
                build: (format) => pdfBytes,
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
              )),
            ],
          ),
        ),
      );
    }
  }

  QuoteData _prepareQuoteData() {
    return QuoteData(
      companyName: "Hosi Academy",
      clientName: _clientNameCtrl.text.isEmpty ? "Client Name" : _clientNameCtrl.text,
      clientDetails: "${_clientCompanyCtrl.text}\n${_clientAddressCtrl.text}\n${_clientEmailCtrl.text}",
      quoteNumber: "DRAFT",
      quoteDate: DateFormat('dd MMM yyyy').format(DateTime.now()),
      validUntil: DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 30))),
      items: _selectedItems.map((item) => QuoteItem(
        code: item['code'],
        description: item['name'],
        unitCost: (item['unit_price_usd'] as num).toDouble() * (_isUniversal ? 1.0 : _exchangeRate),
        quantity: item['quantity'],
      )).toList(),
      discountPercent: double.tryParse(_discountCtrl.text) ?? 0,
      paidToDate: 0,
      description: _clientAddressCtrl.text,
      introduction: _introCtrl.text,
      prerequisites: _prereqCtrl.text.split('\n').where((s) => s.isNotEmpty).toList(),
      currency: _isUniversal ? '\$' : (_selectedCurrency == 'ZAR' ? 'R' : '\$'),
    );
  }

  Future<void> _submitQuotation() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    try {
      final payload = {
        'client_name': _clientNameCtrl.text,
        'client_email': _clientEmailCtrl.text,
        'client_phone': _clientPhoneCtrl.text,
        'client_company': _clientCompanyCtrl.text,
        'client_address': _clientAddressCtrl.text,
        'client_country': _selectedCountry?['id'],
        'local_currency': _selectedCurrency,
        'exchange_rate': _exchangeRate,
        'is_universal': _isUniversal,
        'introduction': _introCtrl.text,
        'prerequisites': _prereqCtrl.text,
        'discount_percentage': double.tryParse(_discountCtrl.text) ?? 0,
        'items': _selectedItems.map((item) => {
          'training_type': item['training_type'],
          'item_id': item['id'],
          'item_code': item['code'],
          'description': item['name'],
          'quantity': item['quantity'],
          'unit_price_usd': item['unit_price_usd'],
        }).toList(),
      };

      await ApiClient.post('/api/v1/payments/admin/marketing/quotations/create/', data: payload);
      _snack('✅ Quotation generated and recorded');
      Navigator.pop(context);
    } catch (e) {
      _snack('Error generating quotation: $e');
      setState(() => _loading = false);
    }
  }
}
