// lib/src/presentation/widgets/payment/hosted_checkout_widget.dart
// REAL PAYMENT FLOW - Redirects to payment gateway's hosted checkout page
// This is how Stripe, Flutterwave, Paystack, and ALL real payment processors work

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class HostedCheckoutWidget extends StatefulWidget {
  final String provider; // 'flutterwave', 'paystack', 'payfast', 'stripe'
  final double amount;
  final String currency;
  final String programId;
  final String programType;
  final String reference;
  final String country;
  final Map<String, dynamic>? enrollmentPayload;
  final VoidCallback onPaymentSuccess;
  final Function(String error) onPaymentError;

  const HostedCheckoutWidget({
    super.key,
    required this.provider,
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
  State<HostedCheckoutWidget> createState() => _HostedCheckoutWidgetState();
}

class _HostedCheckoutWidgetState extends State<HostedCheckoutWidget> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _checkoutUrl;
  String? _errorMessage;
  InAppWebViewController? _webViewController;
  bool _showWebView = false;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call backend to create checkout session
      final result = await ApiClient.initiatePayment(
        programId: widget.programId,
        type: widget.programType,
        amount: widget.amount,
        currency: widget.currency,
        country: widget.country,
        orderId: widget.reference,
        provider: widget.provider,
        metadata: widget.enrollmentPayload ?? {},
      );

      final checkoutUrl = result['checkout_url'] as String?;

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('No checkout URL received from payment gateway');
      }

      setState(() {
        _checkoutUrl = checkoutUrl;
        _isLoading = false;
        _showWebView = true;
      });
      
      if (kIsWeb) {
        // Automatically launch for Web because iframe policies block hosted checkout UI
        final uri = Uri.parse(_checkoutUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        }
      }

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      widget.onPaymentError(_errorMessage!);
    }
  }

  void _handleWebViewNavigation(String url) {
    // Check for success/cancel URLs
    final uri = Uri.parse(url);
    
    // Success patterns
    if (uri.path.contains('/payment/success') ||
        uri.path.contains('/payment/complete') ||
        uri.path.contains('/enrollment/confirm') ||
        uri.queryParameters.containsKey('status') && 
        uri.queryParameters['status'] == 'successful') {
      
      // Payment successful!
      widget.onPaymentSuccess();
      return;
    }

    // Cancel patterns
    if (uri.path.contains('/payment/cancel') ||
        uri.path.contains('/payment/failed') ||
        uri.queryParameters.containsKey('status') && 
        uri.queryParameters['status'] == 'cancelled') {
      
      widget.onPaymentError('Payment was cancelled');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 24),
              Text(
                'Connecting to ${widget.provider.toUpperCase()}...',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we prepare your secure payment page',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Payment Initiation Failed',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initiatePayment,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_showWebView && _checkoutUrl != null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new_rounded, size: 64, color: colors.primary),
              const SizedBox(height: 24),
              Text(
                'Payment Ready',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please complete your payment securely using ${widget.provider.toUpperCase()}.\nReturn here to finalize your enrollment automatically once successful.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final uri = Uri.parse(_checkoutUrl!);
                  launchUrl(uri, webOnlyWindowName: '_blank', mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Open Payment Page Securely'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onPaymentSuccess,
                child: Text('I have completed the payment', style: TextStyle(color: colors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
