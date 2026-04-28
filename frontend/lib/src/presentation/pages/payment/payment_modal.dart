// lib/src/presentation/pages/payment/payment_modal.dart
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/currency_service.dart';

class PaymentModal extends StatefulWidget {
  final double totalAmount;
  final String currency;
  final String enrollmentType;
  final int objectId;
  final VoidCallback onPaymentComplete;

  const PaymentModal({
    super.key,
    required this.totalAmount,
    required this.currency,
    required this.enrollmentType,
    required this.objectId,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _locationData;
  List<dynamic> _providers = [];
  String? _selectedProvider;
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _fetchAvailableProviders();
  }

  Future<void> _fetchAvailableProviders() async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Detect location from IP
      final locationResponse =
          await ApiClient.get('/api/v1/payments/detect-location/');
      setState(() => _locationData = locationResponse.data);

      // Step 2: Fetch available providers for detected country
      final providersResponse = await ApiClient.get(
        '/api/v1/payments/providers-list/',
        queryParameters: {
          'country': _locationData!['country_code'],
          'amount': widget.totalAmount.toString(),
          'currency': widget.currency,
        },
      );

      setState(() {
        _providers = providersResponse.data['providers'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch payment providers: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payment methods: $e')),
        );
      }
    }
  }

  Future<void> _initiatePayment() async {
    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await ApiClient.post(
        '/api/v1/payments/initiate/',
        data: {
          'program_id': widget.objectId.toString(),
          'type': widget.enrollmentType,
          'amount': widget.totalAmount,
          'currency': widget.currency,
          'country': _locationData?['country_code'] ?? 'ZA',
          'provider': _selectedProvider,
          'payment_method': _selectedMethod,
          'metadata': {
            'country_code': _locationData?['country_code'],
            'detected_currency': _locationData?['currency'],
          },
        },
      );

      if (response.data['success'] == true) {
        // Payment initiated successfully
        if (mounted) {
          _showPaymentInstructions(response.data);
        }
      } else {
        throw Exception(response.data['error'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      print('Payment initiation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showPaymentInstructions(Map<String, dynamic> paymentData) {
    final provider = _providers.firstWhere(
      (p) => p['code'] == _selectedProvider,
      orElse: () => {'name': 'Payment Provider'},
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Instructions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider: ${provider['name']}'),
            const SizedBox(height: 16),
            if (paymentData['payment_url'] != null) ...[
              const Text('Click the button below to complete payment:'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Open payment URL in browser
                  launchUrl(paymentData['payment_url']);
                },
                child: const Text('Continue to Payment'),
              ),
            ] else if (paymentData['instructions'] != null) ...[
              Text(paymentData['instructions']),
            ] else ...[
              const Text('Please complete the payment process.'),
            ],
            const SizedBox(height: 16),
            Text('Reference: ${paymentData['transaction_id'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close instructions
              widget.onPaymentComplete();
              Navigator.pop(context); // Close payment modal
            },
            child: const Text('I\'ve Completed Payment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardH = mq.viewInsets.bottom;
    final sw = mq.size.width;
    final sh = mq.size.height;
    final hInset = sw < 380 ? 8.0 : 16.0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.fromLTRB(hInset, 16, hInset, keyboardH + 8),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: sh - keyboardH - 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment,
                      color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Complete Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount Summary
                          _buildAmountSummary(),
                          const SizedBox(height: 24),

                          // Location Detection
                          if (_locationData != null) _buildLocationInfo(),
                          const SizedBox(height: 24),

                          // Payment Methods
                          Text(
                            'Select Payment Method',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _buildPaymentMethods(),
                        ],
                      ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isProcessing ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isProcessing || _selectedProvider == null
                        ? null
                        : _initiatePayment,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock),
                    label: Text(_isProcessing
                        ? 'Processing...'
                        : 'Pay ${CurrencyService.instance.formatPrice(widget.totalAmount, currencyCode: widget.currency)}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                CurrencyService.instance.formatPrice(widget.totalAmount,
                    currencyCode: widget.currency),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Price locked - no VAT, no additional fees',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Text(
                'Detected Location',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_locationData!['country_name']} (${_locationData!['country_code']})',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            'Currency: ${_locationData!['currency']}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    if (_providers.isEmpty) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.orange.shade700),
              const SizedBox(height: 16),
              Text(
                'No payment methods available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection or try again',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade800,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Group providers by category
    // ✅ Filter providers to only include authorized methods
    final cardProviders = _providers
        .where((p) =>
            p['name'].toString().toLowerCase().contains('smatpay') ||
            p['name'].toString().toLowerCase().contains('card') ||
            p['methods']?.contains('card') == true)
        .toList();

    final eftProviders = _providers
        .where((p) =>
            p['name'].toString().toLowerCase().contains('bank') ||
            p['name'].toString().toLowerCase().contains('eft') ||
            p['methods']?.contains('bank_transfer') == true)
        .toList();

    final cashProviders = _providers
        .where((p) =>
            p['code'] == 'cash' ||
            p['name'].toString().toLowerCase().contains('cash'))
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Card Payment Section - ALWAYS SHOWN
          _buildSectionHeader(
            icon: Icons.credit_card,
            title: 'Card Payment (Credit/Debit)',
            subtitle: 'Visa, Mastercard, American Express',
          ),
          if (cardProviders.isNotEmpty)
            ...cardProviders.map((p) => _buildProviderCard(p))
          else
            _buildGenericCardOption(),
          const SizedBox(height: 24),

          // ✅ EFT/Bank Transfer Section
          if (eftProviders.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.account_balance,
              title: 'Bank Transfer / EFT',
              subtitle: 'Electronic Funds Transfer',
            ),
            ...eftProviders.map((p) => _buildProviderCard(p)),
            const SizedBox(height: 24),
          ],

          // ✅ Cash Payment Section (if available)
          if (cashProviders.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.money,
              title: 'Cash / In-Person Payment',
              subtitle: 'Pay at office or authorized agent',
            ),
            ...cashProviders.map((p) => _buildProviderCard(p)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericCardOption() {
    // ✅ Generic card payment fallback (like Stripe/PayPal)
    final isSelected = _selectedProvider == 'generic_card';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedProvider = 'generic_card';
          _selectedMethod = 'card';
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.credit_card, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmatPay Card Payment',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Secure card payment via SmatPay',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pay Amount:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      CurrencyService.instance.formatPrice(widget.totalAmount,
                          currencyCode: widget.currency),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final providerId = provider['id']?.toString() ?? '';
    final name = provider['name']?.toString() ?? 'Payment Provider';
    final description = provider['description']?.toString() ?? '';
    final iconUrl = provider['logo_url']?.toString();
    final type = provider['type']?.toString();
    
    final isSelected = _selectedProvider == providerId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedProvider = providerId;
          _selectedMethod = type ?? 'card';
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: iconUrl != null && iconUrl.isNotEmpty
                        ? Image.network(
                            iconUrl, 
                            errorBuilder: (_, __, ___) => _getProviderIcon(type),
                          )
                        : _getProviderIcon(type),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                ],
              ),
              if (isSelected) ...[
                 const SizedBox(height: 12),
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         'Total to Pay:',
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                       ),
                       Text(
                         CurrencyService.instance.formatPrice(widget.totalAmount, currencyCode: widget.currency),
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                           color: Theme.of(context).colorScheme.primary,
                         ),
                       ),
                     ],
                   ),
                 ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getProviderIcon(String? type) {
    switch (type) {
      case 'mobile_money':
        return const Icon(Icons.phone_android);
      case 'card':
        return const Icon(Icons.credit_card);
      case 'bank_transfer':
        return const Icon(Icons.account_balance);
      case 'cash':
        return const Icon(Icons.money);
      default:
        return const Icon(Icons.payment);
    }
  }
}

// Helper function to launch URL (implement with url_launcher package)
void launchUrl(String url) {
  // TODO: Implement with url_launcher package
  print('Opening URL: $url');
}
