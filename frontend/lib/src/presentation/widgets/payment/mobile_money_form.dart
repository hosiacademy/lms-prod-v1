// lib/src/presentation/widgets/payment/mobile_money_form.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/african_countries.dart';
import '../../../core/services/currency_service.dart';

class MobileMoneyForm extends StatefulWidget {
  final double amount;
  final String currency;
  final String programId;
  final String programType;
  final String reference;
  final String country;
  final Map<String, dynamic>? enrollmentPayload;
  final VoidCallback onPaymentSuccess;
  final Function(String error) onPaymentError;

  const MobileMoneyForm({
    super.key,
    required this.amount,
    required this.currency,
    required this.programId,
    required this.programType,
    required this.reference,
    required this.country,
    required this.enrollmentPayload,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  @override
  State<MobileMoneyForm> createState() => _MobileMoneyFormState();
}

class _MobileMoneyFormState extends State<MobileMoneyForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  
  bool _isLoading = false;
  bool _acceptTerms = false;
  String? _selectedProvider;
  
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'KE');

  // Mobile money providers with their details
  // Optimized for country-specific providers:
  // - Kenya (KE): M-Pesa is DEFAULT and PRIMARY
  // - Zimbabwe (ZW): EcoCash, OneMoney (via PayNow)
  // - Other countries: Appropriate local providers
  final List<Map<String, dynamic>> _mobileMoneyProviders = [
    // KENYA - M-PESA (PRIMARY)
    {
      'name': 'M-Pesa',
      'countries': ['KE'],
      'color': const Color(0xFF4CAF50),
      'provider_code': 'mpesa',
      'isPrimary': true, // M-Pesa is PRIMARY for Kenya
      'description': 'Kenya\'s #1 mobile money - Safaricom',
    },
    {
      'name': 'Airtel Money Kenya',
      'countries': ['KE'],
      'color': const Color(0xFFE91E63),
      'provider_code': 'airtel_money_ke',
      'description': 'Airtel Kenya mobile money',
    },
    // ZIMBABWE - PayNow PRIMARY, EcoCash secondary
    {
      'name': 'PayNow',
      'countries': ['ZW'],
      'color': const Color(0xFF00AEEF),
      'provider_code': 'paynow',
      'isPrimary': true, // PayNow is PRIMARY for Zimbabwe
      'description': 'Zimbabwe\'s payment gateway (EcoCash, OneMoney, Telecash)',
    },
    {
      'name': 'EcoCash',
      'countries': ['ZW'],
      'color': const Color(0xFFFFC107),
      'provider_code': 'ecocash',
      'description': 'Econet\'s mobile money service',
    },
    // OTHER COUNTRIES
    {
      'name': 'MTN MoMo',
      'countries': ['UG', 'GH', 'CM', 'CI', 'RW', 'ZM'],
      'color': const Color(0xFFFFC107),
      'provider_code': 'mtn_momo',
      'description': 'MTN Mobile Money',
    },
    {
      'name': 'Airtel Money',
      'countries': ['UG', 'MW', 'ZM', 'CD', 'MG', 'TD'],
      'color': const Color(0xFFE91E63),
      'provider_code': 'airtel_money',
      'description': 'Airtel Mobile Money',
    },
    {
      'name': 'Orange Money',
      'countries': ['CI', 'SN', 'ML', 'BF', 'CM', 'GN'],
      'color': const Color(0xFFFF9800),
      'provider_code': 'orange_money',
      'description': 'Orange Mobile Money',
    },
    {
      'name': 'Vodacom M-Pesa',
      'countries': ['TZ', 'MZ', 'CD'],
      'color': const Color(0xFF2196F3),
      'provider_code': 'vodacom_mpesa',
      'description': 'Vodacom\'s M-Pesa service',
    },
  ];

  List<Map<String, dynamic>> get _availableProviders {
    final countryCode = widget.country.toUpperCase();
    return _mobileMoneyProviders
        .where((p) => p['countries'].contains(countryCode))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Set initial phone number based on country
    _phoneNumber = PhoneNumber(isoCode: widget.country);
    
    // AUTO-SELECT primary provider for country:
    // - Kenya (KE): M-Pesa (DEFAULT)
    // - Zimbabwe (ZW): PayNow (DEFAULT)
    final countryCode = widget.country.toUpperCase();
    final primaryProvider = _mobileMoneyProviders
        .where((p) => p['countries'].contains(countryCode) && p['isPrimary'] == true)
        .firstOrNull;
    
    if (primaryProvider != null) {
      _selectedProvider = primaryProvider['provider_code'] as String;
    } else if (_availableProviders.isNotEmpty) {
      // Fallback to first available provider
      _selectedProvider = _availableProviders.first['provider_code'] as String;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  bool _needsPin(String provider) {
    return provider == 'mpesa' || provider == 'ecocash';
  }

  Future<void> _processMobileMoneyPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showErrorDialog('Please accept the terms and conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Initiate mobile money payment via backend
      final result = await ApiClient.initiatePayment(
        programId: widget.programId,
        type: widget.programType,
        amount: widget.amount,
        currency: widget.currency,
        country: widget.country,
        provider: _selectedProvider ?? 'mpesa',
        metadata: {
          'enrollment_type': widget.programType,
          'program_id': widget.programId,
          'payment_method': 'mobile_money',
          'phone_number': _phoneNumber.phoneNumber,
          'provider': _selectedProvider,
          'individual_details': widget.enrollmentPayload?['individual_details'],
          'corporate_details': widget.enrollmentPayload?['corporate_details'],
        },
      );

      if (result['checkout_url'] != null || result['provider_reference'] != null) {
        // Show STK push dialog
        _showStkPushDialog(result);
        // Start polling for payment status
        _startPaymentPolling();
      } else {
        throw Exception('Payment initiation failed');
      }
    } catch (e) {
      widget.onPaymentError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStkPushDialog(Map<String, dynamic> paymentData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm on Phone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone_android,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Check your phone: ${_phoneNumber.phoneNumber ?? '***'}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your PIN on your phone to complete payment',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount:', style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (paymentData['provider_reference'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reference:', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          paymentData['provider_reference'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Waiting for confirmation...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onPaymentError('Payment cancelled');
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _startPaymentPolling() {
    // Poll for payment completion every 3 seconds, max 60 seconds
    int attempts = 0;
    const maxAttempts = 20;

    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (attempts >= maxAttempts) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close STK dialog
          widget.onPaymentError('Payment timeout. Please try again.');
        }
        return;
      }

      try {
        final status = await ApiClient.verifyPaymentStatus(widget.reference);
        
        if (status['status'] == 'completed' || status['status'] == 'successful') {
          timer.cancel();
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // Close STK dialog
            widget.onPaymentSuccess();
          }
        } else if (status['status'] == 'failed' || status['status'] == 'cancelled') {
          timer.cancel();
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // Close STK dialog
            widget.onPaymentError('Payment ${status['status']}');
          }
        }
      } catch (e) {
        // Continue polling on error
      }

      attempts++;
    });
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _getProviderInstructions(String provider) {
    switch (provider) {
      case 'mpesa':
        return 'You will receive an M-Pesa STK push on your phone. Enter your M-Pesa PIN to complete payment.';
      case 'paynow':
        return 'You will be redirected to PayNow Zimbabwe. Choose EcoCash, OneMoney, Telecash, or card payment.';
      case 'ecocash':
        return 'You will receive an EcoCash prompt. Enter your EcoCash PIN to confirm.';
      case 'mtn_momo':
        return 'Check your phone for an MTN MoMo USSD prompt. Enter your PIN.';
      case 'airtel_money':
      case 'airtel_money_ke':
        return 'You will receive an Airtel Money prompt. Follow instructions on screen.';
      case 'orange_money':
        return 'An Orange Money USSD prompt will appear. Enter your PIN to confirm.';
      case 'vodacom_mpesa':
        return 'You will receive a Vodacom M-Pesa prompt. Enter your PIN to confirm.';
      default:
        return 'Follow the instructions on your phone to complete payment.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.phone_android, color: colors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Mobile Money',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount Due:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Available Providers
                if (_availableProviders.isNotEmpty) ...[
                  Text(
                    'Select Mobile Money Provider:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableProviders.map((provider) {
                      final isSelected = _selectedProvider == provider['provider_code'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedProvider = provider['provider_code'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (provider['color'] as Color).withOpacity(0.1)
                                : colors.surfaceVariant,
                            border: Border.all(
                              color: isSelected
                                  ? provider['color'] as Color
                                  : colors.outline.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: provider['color'] as Color,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  // PRIMARY BADGE for M-Pesa (Kenya) and PayNow (Zimbabwe)
                                  if (provider['isPrimary'] == true && !isSelected) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: provider['color'] as Color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'RECOMMENDED',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    provider['name'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? provider['color'] as Color
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              // Provider description
                              if (provider['description'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  provider['description'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: colors.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No mobile money providers available for ${widget.country.toUpperCase()}. Please select another payment method.',
                            style: TextStyle(color: colors.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Phone Number Input
                if (_availableProviders.isNotEmpty) ...[
                  InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {
                      setState(() {
                        _phoneNumber = number;
                      });
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      useBottomSheetSafeArea: true,
                    ),
                    ignoreBlank: false,
                    autoValidateMode: AutovalidateMode.disabled,
                    initialValue: _phoneNumber,
                    textFieldController: _phoneController,
                    formatInput: true,
                    keyboardType: TextInputType.phone,
                    inputBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    inputDecoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '712345678',
                      prefixIcon: const Icon(Icons.phone),
                      helperText: 'Enter the number registered with your mobile money account',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // PIN Entry (for M-Pesa/EcoCash)
                  if (_selectedProvider != null && _needsPin(_selectedProvider!)) ...[
                    TextFormField(
                      controller: _pinController,
                      obscureText: true,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Mobile Money PIN',
                        hintText: 'Enter your PIN',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        counterText: '',
                        helperText: 'Your ${_selectedProvider == 'mpesa' ? 'M-Pesa' : 'EcoCash'} PIN',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 4) {
                          return 'PIN must be 4-6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Provider Instructions
                  if (_selectedProvider != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: colors.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getProviderInstructions(_selectedProvider!),
                              style: TextStyle(color: colors.onPrimaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Terms Acceptance
                  CheckboxListTile(
                    title: Text(
                      'I confirm this phone number is registered with ${_selectedProvider ?? 'mobile money'} and has sufficient funds',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: colors.primary,
                  ),
                  const SizedBox(height: 24),

                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_selectedProvider == null || _isLoading)
                          ? null
                          : _processMobileMoneyPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone_android, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'PAY ${CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, size: 16, color: colors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'Secured by SSL | Direct carrier integration',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
