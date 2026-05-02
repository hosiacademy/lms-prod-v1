/// Payment Result Page - Handles redirect back from payment gateway
/// Shows success or failure message after payment completion

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/currency_service.dart';
import 'payment_password_setup.dart';

class PaymentResultPage extends StatefulWidget {
  final String reference;
  final String programId;
  final String programType;
  final double amount;
  final String currency;
  final String email;

  const PaymentResultPage({
    super.key,
    required this.reference,
    required this.programId,
    required this.programType,
    required this.amount,
    required this.currency,
    this.email = '',
  });

  static Future<void> show(
    BuildContext context, {
    required String reference,
    required String programId,
    required String programType,
    required double amount,
    required String currency,
    String email = '',
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentResultPage(
          reference: reference,
          programId: programId,
          programType: programType,
          amount: amount,
          currency: currency,
          email: email,
        ),
      ),
    );
  }

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _statusMessage = 'Verifying payment...';
  Map<String, dynamic>? _paymentData;

  @override
  void initState() {
    super.initState();
    _verifyPayment();
  }

  Future<void> _verifyPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final verification = await ApiClient.verifyPaymentStatus(widget.reference);
      final status = verification['status']?.toString().toLowerCase();

      setState(() {
        _paymentData = verification;
        _isLoading = false;

        if (status == 'success' || status == 'successful' || status == 'completed') {
          _isSuccess = true;
          _statusMessage = 'Payment Successful!';
          // Show password setup immediately after card payment verified
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showPasswordSetupDialog(context, reference: widget.reference, email: widget.email);
            }
          });
        } else if (status == 'failed' || status == 'cancelled') {
          _isSuccess = false;
          _statusMessage = status == 'cancelled' 
              ? 'Payment Cancelled' 
              : 'Payment Failed';
        } else {
          _isSuccess = false;
          _statusMessage = 'Payment Pending';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Unable to verify payment';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    'Verifying your payment...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Status Icon
                    Icon(
                      _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      size: 100,
                      color: _isSuccess ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    // Status Message
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isSuccess ? Colors.green : Colors.orange,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Payment Details Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Details',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Divider(height: 24),
                            _buildDetailRow('Reference', widget.reference),
                            _buildDetailRow('Amount', CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency)),
                            _buildDetailRow('Status', _statusMessage),
                            if (_paymentData?['provider_reference'] != null)
                              _buildDetailRow('Transaction ID', _paymentData!['provider_reference']),
                            if (_paymentData?['completed_at'] != null)
                              _buildDetailRow('Completed', _paymentData!['completed_at']),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Action Buttons
                    if (_isSuccess) ...[
                      const Text(
                        'Your enrollment has been confirmed!',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to dashboard or courses
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.dashboard),
                          label: const Text('Go to Dashboard'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Show receipt or send email
                          },
                          icon: const Icon(Icons.receipt),
                          label: const Text('View Receipt'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Your enrollment is not yet confirmed',
                        style: TextStyle(fontSize: 16, color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Retry payment
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Contact support
                            final supportUri = Uri.parse('mailto:support@hosiacademy.africa');
                            if (await canLaunchUrl(supportUri)) {
                              await launchUrl(supportUri);
                            }
                          },
                          icon: const Icon(Icons.support),
                          label: const Text('Contact Support'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
