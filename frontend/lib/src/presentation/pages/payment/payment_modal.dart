// lib/src/presentation/pages/payment/payment_modal.dart
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/currency_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentModal extends StatefulWidget {
  final double totalAmount;
  final String currency;
  final String enrollmentType;
  final int objectId;
  final VoidCallback onPaymentComplete;
  final String? userEmail;
  final Map<String, dynamic>? userDetails;

  const PaymentModal({
    super.key,
    required this.totalAmount,
    required this.currency,
    required this.enrollmentType,
    required this.objectId,
    required this.onPaymentComplete,
    this.userEmail,
    this.userDetails,
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

  final List<String> _allowedPaymentMethods = ['cash', 'eft', 'card'];

  @override
  void initState() {
    super.initState();
    _fetchAvailableProviders();
  }

  Future<void> _fetchAvailableProviders() async {
    setState(() => _isLoading = true);

    try {
      final locationResponse = await ApiClient.get(
        '/api/v1/payments/detect-location/',
      );
      setState(() => _locationData = locationResponse.data);

      final providersResponse = await ApiClient.get(
        '/api/v1/payments/methods/methods/',
        queryParameters: {
          'country': _locationData!['country_code'],
        },
      );

      final allProviders = providersResponse.data['methods'] ?? [];
      final filteredProviders = allProviders.where((provider) {
        final type = provider['method']?.toString().toLowerCase() ?? '';
        return _allowedPaymentMethods.contains(type);
      }).toList();

      setState(() {
        _providers = filteredProviders;
        if (_providers.isNotEmpty && _selectedProvider == null) {
          _selectedProvider = _providers.first['provider']?.toString();
          _selectedMethod = _providers.first['method']?.toString();
        }
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
      final userEmail = widget.userEmail ?? '';
      final firstName = widget.userDetails?['first_name'] ?? '';
      final lastName = widget.userDetails?['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();

      // Handle Cash Payment separately - uses dedicated on-site endpoint
      if (_selectedProvider == 'cash') {
        final onSiteResponse = await ApiClient.post(
          '/api/v1/payments/on-site/enroll/',
          data: {
            'enrollment_type': widget.enrollmentType,
            'program_id': widget.objectId,
            'amount': widget.totalAmount,
            'currency': widget.currency,
            'user_data': {
              'email': userEmail,
              'first_name': firstName,
              'last_name': lastName,
              'full_name': fullName,
            },
            'metadata': {
              'payment_method': 'cash',
              'country': _locationData?['country_code'],
            },
          },
        );
        _showCashInstructions(onSiteResponse.data);
        setState(() => _isProcessing = false);
        return;
      }

      // Handle EFT and Card using the standard initiate endpoint
      // STEP 1: Generate payment reference
      final referenceResponse = await ApiClient.post(
        '/api/v1/payments/initiate/',
        data: {
          'program_id': widget.objectId,
          'type': widget.enrollmentType,
          'amount': widget.totalAmount,
          'currency': widget.currency,
          'email': userEmail,
          'metadata': {
            'enrollment_type': widget.enrollmentType,
            'program_id': widget.objectId,
            'country': _locationData?['country_code'],
            'currency': widget.currency,
            'amount': widget.totalAmount,
            'individual_details': {
              'email': userEmail,
              'first_name': firstName,
              'last_name': lastName,
              'full_name': fullName,
            },
          },
        },
      );

      final reference = referenceResponse.data['reference'];
      print('Payment reference generated: $reference');

      // STEP 2: Initiate actual payment with provider
      final paymentResponse = await ApiClient.post(
        '/api/v1/payments/initiate/',
        data: {
          'program_id': widget.objectId,
          'type': widget.enrollmentType,
          'amount': widget.totalAmount,
          'currency': widget.currency,
          'country': _locationData?['country_code'],
          'provider': _selectedProvider,
          'payment_method': _selectedMethod,
          'order_id': reference,
          'email': userEmail,
          'metadata': {
            'enrollment_type': widget.enrollmentType,
            'program_id': widget.objectId,
            'country': _locationData?['country_code'],
            'currency': widget.currency,
            'amount': widget.totalAmount,
            'amount_usd': widget.totalAmount,
            'individual_details': {
              'email': userEmail,
              'first_name': firstName,
              'last_name': lastName,
              'full_name': fullName,
            },
          },
        },
      );

      // Handle based on provider type
      if (_selectedProvider == 'smatpay') {
        // CARD PAYMENT: Redirect to SmatPay hosted page
        final checkoutUrl = paymentResponse.data['checkout_url'];
        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          final url = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
          widget.onPaymentComplete();
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          throw Exception('No checkout URL returned from SmatPay');
        }
      } else if (_selectedProvider == 'eft') {
        // EFT PAYMENT: Show bank transfer instructions
        _showEFTInstructions(paymentResponse.data);
      } else {
        throw Exception('Unknown payment provider: $_selectedProvider');
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

  void _showCashInstructions(Map<String, dynamic> paymentData) {
    final referenceCode = paymentData['reference_code'] ?? 'N/A';
    final expiresAt = paymentData['expires_at'] ?? '';
    final instructions = paymentData['instructions'] ?? {};
    final nextSteps = paymentData['next_steps'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.money, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Cash Payment Instructions'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Reference Code:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText(referenceCode,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Valid Until: $expiresAt',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (instructions.isNotEmpty && instructions['locations'] != null) ...[
                const Text('Office Location:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(instructions['locations'] as List<dynamic>).map((loc) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📍 ${loc['city']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(loc['address'] ?? ''),
                          if (loc['hours'] != null)
                            Text('Hours: ${loc['hours']}',
                                style: const TextStyle(fontSize: 12)),
                          if (loc['phone'] != null)
                            Text('Phone: ${loc['phone']}',
                                style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 16),
              const Text('Next Steps:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...nextSteps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(step)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Save your reference code. You need it to pay at the office.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentComplete();
              Navigator.pop(context);
            },
            child: const Text('I Understand'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEFTInstructions(Map<String, dynamic> paymentData) {
    final reference = paymentData['order_id'] ?? paymentData['reference'] ?? 'N/A';
    final amount = paymentData['amount'] ?? widget.totalAmount;
    final currency = paymentData['currency'] ?? widget.currency;
    final bankDetails = paymentData['bank_details'] ?? {};

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('EFT Payment Instructions'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount to Transfer:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      CurrencyService.instance.formatPrice(amount,
                          currencyCode: currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Reference:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(reference,
                    style: const TextStyle(fontFamily: 'monospace')),
              ),
              const SizedBox(height: 16),
              const Text('Bank Account Details:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank: ${bankDetails['bank_name'] ?? 'FNB Business'}'),
                    Text(
                        'Account Name: ${bankDetails['account_name'] ?? 'HosiTech LMS (Pty) Ltd'}'),
                    Text(
                        'Account Number: ${bankDetails['account_number'] ?? '123456789'}'),
                    Text('Branch Code: ${bankDetails['branch_code'] ?? '250655'}'),
                    Text('Reference: $reference'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'After transfer, your enrollment will be activated within 24 hours.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentComplete();
              Navigator.pop(context);
            },
            child: const Text('I\'ve Transferred'),
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
          maxHeight: (sh - keyboardH - 40) > 0 ? (sh - keyboardH - 40) : double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Payment Method',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _providers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No payment methods available for your country.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _providers.length,
                          itemBuilder: (context, index) {
                            return _buildProviderCard(_providers[index]);
                          },
                        ),
            ),
            if (_selectedProvider != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue to Payment'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final providerId = provider['provider']?.toString() ?? '';
    final type = provider['method']?.toString() ?? '';

    String name = 'Payment Method';
    if (type == 'card') name = 'Credit / Debit Card';
    else if (type == 'eft') name = 'Bank Transfer / EFT';
    else if (type == 'cash') name = 'Pay in Cash at Office';

    final description = provider['description']?.toString() ?? '';
    final iconUrl = provider['logo_url']?.toString();

    final isSelected = _selectedProvider == providerId;

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
          _selectedProvider = providerId;
          _selectedMethod = type ?? 'card';
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: iconUrl != null && iconUrl.isNotEmpty
                    ? Image.network(iconUrl, errorBuilder: (_, __, ___) => _getProviderIcon(type))
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
        ),
      ),
    );
  }

  Widget _getProviderIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'cash':
        return const Icon(Icons.money, size: 32, color: Colors.green);
      case 'eft':
        return const Icon(Icons.account_balance, size: 32, color: Colors.blue);
      case 'card':
        return const Icon(Icons.credit_card, size: 32, color: Colors.purple);
      default:
        return const Icon(Icons.payment, size: 32, color: Colors.grey);
    }
  }
}
