// lib/src/presentation/pages/payment/payment_provider_selection_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/payment_config.dart';
import '../../../core/config/african_banks.dart';
import 'payment_result_pages.dart';
import 'payment_result_page.dart' as result_page;
import 'cash_payment_instructions_page.dart';
import '../../widgets/payment/hosted_checkout_widget.dart';
import '../../widgets/payment/eft_payment_widget.dart';
import 'payment_password_setup.dart';
import '../../../core/services/currency_service.dart';

class PaymentProviderSelectionPage extends StatefulWidget {
  final String reference; // from initiatePayment
  final double amount;
  final String currency;
  final String country;
  final String programId;
  final String programType;
  final Map<String, dynamic>?
      paymentMetadata; // Minimal data for payment intent
  final Map<String, dynamic>? enrollmentPayload; // Full data for finalization
  final bool isDialog;

  const PaymentProviderSelectionPage({
    super.key,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.country,
    required this.programId,
    required this.programType,
    this.paymentMetadata,
    this.enrollmentPayload,
    this.isDialog = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String reference,
    required double amount,
    required String currency,
    required String country,
    required String programId,
    required String programType,
    Map<String, dynamic>? paymentMetadata,
    Map<String, dynamic>? enrollmentPayload,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: PaymentProviderSelectionPage(
              reference: reference,
              amount: amount,
              currency: currency,
              country: country,
              programId: programId,
              programType: programType,
              paymentMetadata: paymentMetadata,
              enrollmentPayload: enrollmentPayload,
              isDialog: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<PaymentProviderSelectionPage> createState() =>
      _PaymentProviderSelectionPageState();
}

class _PaymentProviderSelectionPageState
    extends State<PaymentProviderSelectionPage> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _providers = [];
  String? _selectedProviderCode;
  String? _selectedMethod;
  String? _error;
  String? _paymentUrl;
  bool _showSuccess = false;
  Timer? _statusTimer;
  String?
      _selectedPaymentCategory;

  // Bank selection for EFT
  String? _selectedBankCode;
  AfricanBank? _selectedBank;

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProvidersForCategory(String category) async {
    setState(() {
      _selectedPaymentCategory = category;
      _isLoading = true;
    });

    try {
      final response = await ApiClient.get(
        '/api/v1/payments/providers-by-category/',
        queryParameters: {
          'country': widget.country.isNotEmpty ? widget.country : null,
          'category': category,
          'amount': widget.amount,
          'currency': widget.currency.isNotEmpty ? widget.currency : null,
        },
      );

      final providers =
          List<Map<String, dynamic>>.from(response.data['providers'] ?? []);

      // Fallback for SmatPay if it's missing from the card category
      if (category == 'card' && !providers.any((p) => p['code'].toString().contains('smatpay'))) {
        providers.add({
          'code': 'smatpay',
          'name': 'Card Payment (SmatPay)',
          'methods': ['card', 'credit_card', 'debit_card'],
          'fees': {'percentage': 0, 'fixed': 0},
          'description': 'Secure card payment via SmatPay (Visa/Mastercard worldwide)',
        });
      }

      setState(() {
        _providers = providers;
        _isLoading = false;
        
        if (category == 'card') {
          _selectedProviderCode = 'smatpay';
        } else if (providers.isNotEmpty) {
          _selectedProviderCode = providers.first['code'];
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load payment options: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.getAvailablePaymentProviders(
        country: widget.country.isNotEmpty ? widget.country : null,
        amount: widget.amount,
        currency: widget.currency.isNotEmpty ? widget.currency : null,
      );

      final detectedCountry =
          response['detected_country'] as String? ?? widget.country;
      final providers = List<Map<String, dynamic>>.from(
          response['available_providers'] ?? []);

      final filteredProviders = providers.where((p) {
        final code = p['code']?.toString().toLowerCase() ?? '';
        return code.contains('smatpay') || 
               code == 'cash' || 
               code == 'bank_transfer' || 
               code == 'eft' || 
               code == 'on_site_payment';
      }).toList();

      if (!filteredProviders.any((p) => p['code'].toString().contains('smatpay'))) {
        filteredProviders.add({
          'code': 'smatpay',
          'name': 'Card Payment (SmatPay)',
          'methods': ['card', 'credit_card', 'debit_card'],
          'fees': {'percentage': 0, 'fixed': 0},
          'description': 'Secure card payment via SmatPay (Visa/Mastercard worldwide)',
        });
      }

      setState(() {
        _providers = filteredProviders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load payment options: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initiatePayment() async {
    if (_selectedProviderCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment provider'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedProviderCode == 'cash' || _selectedProviderCode == 'on_site_payment') {
      await _handleCashPayment();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      String backendEnrollmentType = widget.programType;

      double finalAmount = widget.amount;
      String finalCurrency = widget.currency;

      if (_selectedProviderCode == 'smatpay') {
        finalAmount = (widget.enrollmentPayload?['amount_usd'] as num?)?.toDouble() ?? widget.amount;
        finalCurrency = 'USD';
      }

      final result = await ApiClient.initiatePayment(
        programId: widget.programId,
        type: backendEnrollmentType,
        amount: finalAmount,
        currency: finalCurrency,
        country: widget.country,
        orderId: widget.reference,
        provider: _selectedProviderCode!,
        metadata: widget.paymentMetadata ?? {},
      );

      final checkoutUrl = result['checkout_url'] as String?;

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        setState(() {
          _paymentUrl = checkoutUrl;
          _isProcessing = false;
          _launchPaymentUrl(checkoutUrl);
        });
      } else {
        throw Exception('No valid payment URL received');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment initiation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCashPayment() async {
    setState(() => _isProcessing = true);

    try {
      final confirmed = await CashPaymentInstructionsPage.show(
        context,
        enrollmentType: widget.programType,
        programId: widget.programId,
        programTitle: widget.paymentMetadata?['program_title'] as String? ??
            'Selected Programme',
        reference: widget.reference,
        amount: widget.amount,
        currency: widget.currency,
      );

      if (!mounted) return;

      if (confirmed == true) {
        final provisional = await ApiClient.createProvisionalEnrollment(
          programId: widget.programId,
          type: widget.programType,
          userData: widget.enrollmentPayload ?? {},
          method: _selectedMethod ?? 'cash',
          amount: widget.amount,
        );

        final reference = provisional['reference'] as String?;
        final expiresAt = provisional['expires_at'] as String?;

        if (!mounted) return;

        // SHOW PASSWORD SETUP DIALOG AFTER PROVISIONAL ENROLLMENT
        final email = extractEmailFromPayload(widget.enrollmentPayload);
        await showPasswordSetupDialog(
          context,
          reference: reference ?? widget.reference,
          email: email,
        );

        if (!mounted) return;

        final trainingTitle =
            provisional['training_title'] as String? ?? 'Training Program';
        final trainingDate = provisional['training_date'] as String?;

        final completed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Payment Reference Generated')),
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
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ SEAT NOT SECURED UNTIL PAYMENT',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your seat is NOT reserved. Seats are allocated on a first-come-first-served basis AFTER payment is received.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Training: $trainingTitle',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (trainingDate != null) ...[
                    const SizedBox(height: 4),
                    Text('Date: $trainingDate',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 16),
                  if (reference != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Reference:',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          SelectableText(
                            reference,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Quote this reference when making payment',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  if (expiresAt != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Payment Deadline:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expiresAt,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '14 days OR before training commencement date (whichever is earlier)',
                            style: TextStyle(
                                fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Visit Hosi Training Centre - Pretoria CBD'),
                  const Text('• Bring ID/Passport and payment reference'),
                  const Text('• Cash or bank transfer accepted'),
                  const Text('• Request receipt for payment confirmation'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✓ Your enrollment will be confirmed and seat secured ONLY after payment is verified by our admin team.',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('I Understand'),
              ),
            ],
          ),
        );

        if (completed == true && mounted) {
          setState(() {
            _showSuccess = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to reserve enrollment: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return PaymentSuccessPage(
        reference: widget.reference,
        programType: widget.programType,
        programId: int.tryParse(widget.programId) ?? 0,
        amount: widget.amount,
        currency: widget.currency,
        metadata: widget.enrollmentPayload,
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadProviders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                if (widget.isDialog) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: widget.isDialog
          ? AppBar(
              title: const Text('Select Payment Method'),
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            )
          : AppBar(
              title: const Text('Select Payment Method'),
              elevation: 0,
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Pay Amount:',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!PaymentConfig.isProduction)
            _buildSandboxHelper(theme, colorScheme),

          const SizedBox(height: 24),

          _buildPaymentCategoryBar(theme, colorScheme),

          const SizedBox(height: 24),

          _buildProvidersForSelectedCategory(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPaymentCategoryBar(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Type:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCategoryButton(
              theme: theme,
              icon: Icons.credit_card,
              label: 'Card',
              category: 'card',
              isSelected: _selectedPaymentCategory == 'card',
              onTap: () => _loadProvidersForCategory('card'),
              colorScheme: colorScheme,
              disabled: false,
            ),
            _buildCategoryButton(
              theme: theme,
              icon: Icons.account_balance,
              label: 'EFT / Bank',
              category: 'eft',
              isSelected: _selectedPaymentCategory == 'eft',
              onTap: () => _loadProvidersForCategory('eft'),
              colorScheme: colorScheme,
            ),
            _buildCategoryButton(
              theme: theme,
              icon: Icons.store,
              label: 'In-Shop Payment',
              category: 'cash',
              isSelected: _selectedPaymentCategory == 'cash',
              onTap: () => _loadProvidersForCategory('cash'),
              colorScheme: colorScheme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String category,
    required bool isSelected,
    required VoidCallback? onTap,
    required ColorScheme colorScheme,
    bool disabled = false,
    String? disabledTooltip,
  }) {
    final button = Expanded(
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : (disabled
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : (disabled
                      ? colorScheme.outline.withOpacity(0.3)
                      : colorScheme.outline),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: disabled
                    ? colorScheme.onSurface.withOpacity(0.3)
                    : (isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface),
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
    return button;
  }

  Widget _buildProvidersForSelectedCategory(
      ThemeData theme, ColorScheme colorScheme) {
    if (_selectedPaymentCategory == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Select a payment type above to see available providers',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedPaymentCategory == 'card') {
      return _buildCardForm(theme, colorScheme);
    }

    if (_selectedPaymentCategory == 'eft') {
      return _buildEftForm(theme, colorScheme);
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_providers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No providers available for this payment type in your region',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Providers:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._providers.map((p) => _buildProviderCard(p, theme, colorScheme)),
      ],
    );
  }

  Widget _buildCardForm(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          colorScheme,
          icon: Icons.credit_card,
          title: 'Card Payment (Credit/Debit)',
          subtitle: 'Secure checkout via payment gateway',
        ),
        const SizedBox(height: 16),
        HostedCheckoutWidget(
          provider: 'smatpay',
          amount: widget.amount,
          currency: widget.currency,
          programId: widget.programId,
          programType: widget.programType,
          reference: widget.reference,
          country: widget.country,
          enrollmentPayload: widget.enrollmentPayload,
          onPaymentSuccess: () {
            Navigator.pop(context);
            result_page.PaymentResultPage.show(
              context,
              reference: widget.reference,
              programId: widget.programId,
              programType: widget.programType,
              amount: widget.amount,
              currency: widget.currency,
              email: extractEmailFromPayload(widget.paymentMetadata),
            );
          },
          onPaymentError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEftForm(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          colorScheme,
          icon: Icons.account_balance,
          title: 'EFT / Bank Transfer',
          subtitle: 'Direct bank transfer, 24-72 hour verification',
        ),
        const SizedBox(height: 16),
        EftPaymentWidget(
          amount: widget.amount,
          currency: widget.currency,
          programId: widget.programId,
          programType: widget.programType,
          reference: widget.reference,
          country: widget.country,
          enrollmentPayload: widget.enrollmentPayload,
          onPaymentSuccess: () {
            Navigator.pop(context);
            context.push(
              '/eft-payment-result',
              extra: {
                'reference': widget.reference,
                'programId': widget.programId,
                'programType': widget.programType,
                'amount': widget.amount,
                'currency': widget.currency,
                'programTitle':
                    widget.paymentMetadata?['program_title'] as String? ??
                        'Selected Program',
              },
            );
          },
          onPaymentError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('EFT initiation failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme, {
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
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _buildProviderCard(
      Map<String, dynamic> provider, ThemeData theme, ColorScheme colorScheme) {
    final code = provider['code'] as String;
    final name = provider['name'] as String;
    final methods = List<String>.from(provider['methods'] ?? []);
    final fees = provider['fees'] as Map<String, dynamic>?;

    final isSelected = _selectedProviderCode == code;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2),
      ),
      child: GestureDetector(
        onTap: () => _selectProviderAndPay(code, methods),
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.payment,
                        color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (fees != null)
                          Text(
                            _getFeeText(fees, widget.currency),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 18, color: colorScheme.primary),
                ],
              ),
              if (methods.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text('Payment Methods:',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: methods.map((method) {
                    return Chip(
                      label: Text(_formatMethodName(method),
                          style: const TextStyle(fontSize: 11)),
                      avatar: Icon(_getMethodIcon(method), size: 16),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
   );
  }



  Future<void> _selectProviderAndPay(
      String providerCode, List<String> methods) async {
    setState(() {
      _selectedProviderCode = providerCode;
      _selectedMethod = methods.isNotEmpty ? methods.first : null;
    });

    await _initiatePayment();
  }

  Future<void> _launchPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        _showVerificationDialog();
        _startPolling();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch payment page')),
        );
      }
    }
  }

  void _startPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final verification =
            await ApiClient.verifyPaymentStatus(widget.reference);
        final status = verification['status']?.toString().toLowerCase();

        if (status == 'success' || status == 'successful') {
          timer.cancel();
          if (mounted) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            setState(() => _showSuccess = true);
          }
        } else if (status == 'failed') {
          timer.cancel();
          if (mounted) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });

    Timer(const Duration(minutes: 10), () {
      _statusTimer?.cancel();
    });
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment in Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Please complete the payment in the browser/app that opened.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We are verifying your payment status...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _statusTimer?.cancel();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _checkPaymentStatus();
            },
            child: const Text('I Have Completed Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final verification =
          await ApiClient.verifyPaymentStatus(widget.reference);
      final status = verification['status']?.toString().toLowerCase();

      if (mounted) {
        if (status == 'success' || status == 'successful') {
          _statusTimer?.cancel();
          Navigator.pop(context);
          setState(() => _showSuccess = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status: ${status ?? "Pending"}. Please wait...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check failed: $e')),
        );
      }
    }
  }

  String _getFeeText(Map<String, dynamic> fees, String currency) {
    final percentage = fees['percentage'] ?? 0;
    final fixed = fees['fixed'] ?? 0.0;
    if (percentage > 0 && fixed > 0)
      return '$percentage% + $currency $fixed fee';
    if (percentage > 0) return '$percentage% fee';
    if (fixed > 0) return '$currency $fixed fee';
    return 'No additional fees';
  }

  IconData _getMethodIcon(String method) {
    final m = method.toLowerCase();
    if (m.contains('card')) return Icons.credit_card;
    if (m.contains('mobile') || m.contains('momo') || m.contains('mpesa'))
      return Icons.phone_android;
    if (m.contains('bank') || m.contains('transfer'))
      return Icons.account_balance;
    if (m.contains('ussd')) return Icons.dialpad;
    if (m.contains('qr')) return Icons.qr_code;
    return Icons.payment;
  }

  String _formatMethodName(String method) {
    return method
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Widget _buildSandboxHelper(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real Payment Processing',
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                Text(
                  'Secure checkout via payment gateway',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
