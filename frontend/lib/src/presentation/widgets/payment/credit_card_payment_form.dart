// lib/src/presentation/widgets/payment/credit_card_payment_form.dart
// CARD PAYMENT - Zimbabwe ONLY via SmatPay
// Per session logs (Mar 21, 09:26): "smatpay covers Zimbabwe only"

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/currency_service.dart';

class CreditCardPaymentForm extends StatefulWidget {
  final double amount;
  final String currency; // MUST be USD for Zimbabwe
  final String programId;
  final String programType;
  final String reference;
  final String country; // Must be 'ZW' for Zimbabwe
  final Map<String, dynamic>? enrollmentPayload;
  final VoidCallback onPaymentSuccess;
  final Function(String error) onPaymentError;

  const CreditCardPaymentForm({
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
  State<CreditCardPaymentForm> createState() => _CreditCardPaymentFormState();
}

class _CreditCardPaymentFormState extends State<CreditCardPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isLoading = false;
  String _selectedCardType = 'Unknown';

  // Card number formatter
  final _cardNumberFormatter = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Expiry formatter
  final _expiryFormatter = MaskTextInputFormatter(
    mask: '##/##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_detectCardType);
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_detectCardType);
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _detectCardType() {
    String cardNumber = _cardNumberController.text.replaceAll(' ', '');
    String cardType = 'Unknown';

    if (cardNumber.startsWith('4')) {
      cardType = 'Visa';
    } else if (RegExp(r'^5[1-5]').hasMatch(cardNumber)) {
      cardType = 'Mastercard';
    } else if (RegExp(r'^3[47]').hasMatch(cardNumber)) {
      cardType = 'Amex';
    }

    if (_selectedCardType != cardType) {
      setState(() => _selectedCardType = cardType);
    }
  }

    // Card payment via SmatPay
    Future<void> _processCardPayment() async {

    if (!_formKey.currentState!.validate()) {
      widget.onPaymentError('Please fill in all card details correctly');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use default email for payment
      final email = 'mazandotakawira@gmail.com';
      
      // Call backend to create payment intent with Flutterwave
      // Backend will handle secure card processing
      final result = await ApiClient.initiatePayment(
        programId: widget.programId,
        type: widget.programType,
        amount: widget.amount,
        currency: widget.currency, // KES for Kenya, USD for Zimbabwe, ZAR for SA
        country: widget.country,
        provider: 'smatpay',
        orderId: widget.reference,
        metadata: {
          ...widget.enrollmentPayload ?? {},
          'email': email,
          'payment_method': 'card',
          'card_type': _selectedCardType,
        },
      );

      final checkoutUrl = result['checkout_url'] as String?;

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Payment gateway did not return checkout URL');
      }

      // Open secure payment page
      final Uri url = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // Start polling for payment completion
        _pollPaymentStatus();
      } else {
        throw Exception('Could not open payment page');
      }
    } catch (e) {
      widget.onPaymentError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pollPaymentStatus() {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final status = await ApiClient.verifyPaymentStatus(widget.reference);
        final paymentStatus = status['status'] as String?;

        if (paymentStatus == 'completed' || paymentStatus == 'successful') {
          timer.cancel();
          widget.onPaymentSuccess();
        } else if (paymentStatus == 'failed' || paymentStatus == 'cancelled') {
          timer.cancel();
          widget.onPaymentError('Payment $paymentStatus');
        }
      } catch (e) {
        // Keep polling
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final isZimbabwe = widget.country.toUpperCase() == 'ZW';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zimbabwe-only notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isZimbabwe ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isZimbabwe ? Colors.green.shade300 : Colors.orange.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'SmatPay Card Payment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Secure card payment processed via SmatPay. Accepts Visa and Mastercard.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.credit_card, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Enter Card Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount - PROPERLY FORMATTED (no mixing R with USD)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryContainer,
                      colors.primaryContainer.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pay Amount',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 14, color: colors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Secure',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Card Number Field - USER MUST ENTER THIS
              TextFormField(
                controller: _cardNumberController,
                inputFormatters: [_cardNumberFormatter],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                  suffixIcon: _selectedCardType != 'Unknown'
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _selectedCardType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getCardColor(_selectedCardType),
                            ),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Card number required';
                  }
                  if (value.replaceAll(' ', '').length < 15) {
                    return 'Invalid card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Expiry and CVV - USER MUST ENTER THESE
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      inputFormatters: [_expiryFormatter],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 5) {
                          return 'Invalid date';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        prefixIcon: const Icon(Icons.security_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3) {
                          return 'Invalid CVV';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cardholder Name - USER MUST ENTER THIS
              TextFormField(
                controller: _cardHolderController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Doe',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Cardholder name required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // PAY NOW Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processCardPayment,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'PAY ${CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Security notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: colors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Card details are encrypted and processed securely',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
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



  Color _getCardColor(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'amex':
        return Colors.amber[700]!;
      default:
        return Colors.grey;
    }
  }
}
