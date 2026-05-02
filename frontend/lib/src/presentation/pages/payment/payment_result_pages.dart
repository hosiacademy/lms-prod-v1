// lib/src/presentation/pages/payment/payment_result_pages.dart

import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import 'payment_password_setup.dart';
import '../../../core/services/currency_service.dart';

/// Payment Success Page – Finalizes enrollment only after confirmed payment
class PaymentSuccessPage extends StatefulWidget {
  final String reference;
  final String programType;
  final int programId;
  final double amount;
  final String? currency;
  final Map<String, dynamic>? metadata; // learners, company, etc.

  const PaymentSuccessPage({
    super.key,
    required this.reference,
    required this.programType,
    required this.programId,
    required this.amount,
    this.currency,
    this.metadata,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  bool _isFinalizing = true;
  String? _errorMessage;
  Map<String, dynamic>? _enrollmentResult;
  bool _isProvisional = false; // for cash/manual payments

  @override
  void initState() {
    super.initState();
    _finalizeEnrollment();
  }

  Future<void> _finalizeEnrollment() async {
    try {
      // Step 1: Verify payment status (critical safety check)
      final verification =
          await ApiClient.verifyPaymentStatus(widget.reference);

      final paymentStatus =
          verification['status']?.toString().toLowerCase() ?? '';
      
      // Check if this was a cash/provisional payment
      _isProvisional = widget.metadata?['method'] == 'cash' ||
          widget.metadata?['method'] == 'bank_transfer' ||
          widget.metadata?['method'] == 'manual' ||
          verification['provider'] == 'cash' ||
          verification['provider'] == 'bank_transfer';

      // Allow 'cash_pending' or 'pending' for provisional enrollments
      final isAllowedStatus = paymentStatus == 'success' || 
                             paymentStatus == 'successful' || 
                             (_isProvisional && (paymentStatus == 'cash_pending' || paymentStatus == 'pending'));

      if (!isAllowedStatus) {
        throw Exception('Payment not confirmed: $paymentStatus');
      }

      // Step 2: Finalize enrollment in YOUR database
      final result = await ApiClient.finalizeEnrollment(
        reference: widget.reference,
        programId: widget.programId,
        programType: widget.programType,
        metadata: widget.metadata ?? {},
      );

      if (!mounted) return;

      setState(() {
        _enrollmentResult = result;
        _isFinalizing = false;
      });

      // Show password setup immediately after enrollment is confirmed
      if (mounted) {
        final email = extractEmailFromPayload(widget.metadata);
        await showPasswordSetupDialog(context, reference: widget.reference, email: email);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isFinalizing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isFinalizing) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _isProvisional
                    ? 'Confirming your provisional enrollment...'
                    : 'Finalizing your enrollment...',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorPage(theme);
    }

    // Success UI
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  _isProvisional
                      ? 'Provisional Enrollment Confirmed'
                      : 'Enrollment Successful!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  _isProvisional
                      ? 'Your spot is reserved. Pay at our office to activate full access.'
                      : 'You now have full access to your course.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Details Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          'Transaction Reference',
                          widget.reference,
                          Icons.receipt_long,
                          theme,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Amount Paid',
                          CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency ?? 'USD'),
                          Icons.payments,
                          theme,
                        ),
                        if (_enrollmentResult != null &&
                            _enrollmentResult!['enrollment_code'] != null) ...[
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Enrollment Code',
                            _enrollmentResult!['enrollment_code'],
                            Icons.confirmation_number,
                            theme,
                          ),
                        ],
                        if (_isProvisional &&
                            _enrollmentResult?['expires_at'] != null) ...[
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Provisional Until',
                            _enrollmentResult!['expires_at'],
                            Icons.timer,
                            theme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isProvisional
                              ? 'A confirmation has been sent with office details and reference.'
                              : 'A confirmation email has been sent to your registered address.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Actions
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/my-courses',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.school),
                  label: const Text('Go to My Courses'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPage(ThemeData theme) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Enrollment Finalization Failed',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'An unexpected error occurred.',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Payment Failure Page (kept mostly as-is, minor polish)
class PaymentFailurePage extends StatelessWidget {
  final String? reason;
  final String? transactionReference;

  const PaymentFailurePage({
    super.key,
    this.reason,
    this.transactionReference,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Payment Failed',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  reason ??
                      "We couldn't process your payment. Please try again.",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                if (transactionReference != null) ...[
                  const SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Transaction Reference',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  transactionReference!,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Contact support at support@hosiacademy.com')),
                    );
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Support'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
