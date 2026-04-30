import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';

class QuotationsManagementTab extends StatefulWidget {
  const QuotationsManagementTab({super.key});

  @override
  State<QuotationsManagementTab> createState() => _QuotationsManagementTabState();
}

class _QuotationsManagementTabState extends State<QuotationsManagementTab> {
  List<dynamic> _quotations = [];
  List<dynamic> _allowedCountries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.get('/api/v1/payments/quotations/');
      if (mounted) {
        setState(() {
          _quotations = data is List ? data : (data.data['results'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return _buildQuotationView(Theme.of(context), Theme.of(context).colorScheme);
  }
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

