// lib/src/presentation/widgets/payment/eft_payment_widget.dart
// EFT/BANK TRANSFER — Show company bank details, user transfers independently

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/currency_service.dart';
import '../../pages/payment/payment_password_setup.dart';

class EftPaymentWidget extends StatefulWidget {
  final double amount;
  final String currency;
  final String programId;
  final String programType;
  final String reference;
  final String country;
  final Map<String, dynamic>? enrollmentPayload;
  final VoidCallback onPaymentSuccess;
  final Function(String error) onPaymentError;

  const EftPaymentWidget({
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
  State<EftPaymentWidget> createState() => _EftPaymentWidgetState();
}

class _EftPaymentWidgetState extends State<EftPaymentWidget> {
  bool _isLoading = true;
  bool _isConfirming = false;
  String? _error;

  String _reference = '';
  Map<String, dynamic> _bankDetails = {};
  List<String> _instructions = [];
  String? _expiresAt;

  @override
  void initState() {
    super.initState();
    _reference = widget.reference;
    _initiateEft();
  }

  Future<void> _initiateEft() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiClient.initiateEftPayment(
        programId: widget.programId,
        type: widget.programType,
        amount: widget.amount,
        currency: widget.currency,
        country: widget.country,
        metadata: widget.enrollmentPayload ?? {},
      );

      final bankDetails = result['bank_details'];
      final instructions = result['instructions'];

      setState(() {
        _reference = result['reference'] ?? widget.reference;
        _bankDetails = (bankDetails is Map<String, dynamic>) ? bankDetails : {};
        _instructions = (instructions is List)
            ? List<String>.from(instructions)
            : [
                'Transfer ${CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency)} to the account above',
                'Use reference: $_reference',
                'Payment verified within 24–72 hours',
              ];
        _expiresAt = result['expires_at'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmTransfer() async {
    setState(() => _isConfirming = true);
    try {
      await ApiClient.createProvisionalEnrollment(
        programId: widget.programId,
        type: widget.programType,
        userData: {
          'country': widget.country,
          'reference': _reference,
        },
        method: 'eft',
        amount: widget.amount,
      );

      // Show password setup immediately — user has a provisional spot, give them access now
      if (mounted) {
        final email = extractEmailFromPayload(widget.enrollmentPayload);
        await showPasswordSetupDialog(
          context,
          reference: _reference,
          email: email,
          onDone: widget.onPaymentSuccess,
        );
      }
    } catch (e) {
      widget.onPaymentError(e.toString());
      if (mounted) setState(() => _isConfirming = false);
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 48),
              const SizedBox(height: 12),
              Text('Could not load bank details', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colors.error, fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initiateEft,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                  child: Icon(Icons.account_balance, color: colors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank Transfer (EFT)',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Transfer directly from your bank',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primaryContainer, colors.primaryContainer.withOpacity(0.5)],
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
                      Text('Amount to Transfer',
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
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
                  if (_expiresAt != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Pay before', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
                        Text(
                          _formatExpiry(_expiresAt!),
                          style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary, fontSize: 13),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Company Bank Details
            Text(
              'Transfer to this account',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.primary.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(12),
                color: colors.surfaceContainerHighest.withOpacity(0.2),
              ),
              child: Column(
                children: [
                  if (_bankDetails['bank_name'] != null)
                    _buildDetailRow(context, 'Bank', _bankDetails['bank_name'], copyable: false),
                  if (_bankDetails['account_name'] != null)
                    _buildDetailRow(context, 'Account Name', _bankDetails['account_name'], copyable: false),
                  if (_bankDetails['account_type'] != null)
                    _buildDetailRow(context, 'Account Type', _bankDetails['account_type'], copyable: false),
                  if (_bankDetails['account_number'] != null)
                    _buildDetailRow(context, 'Account Number', _bankDetails['account_number'].toString(), copyable: true),
                  if (_bankDetails['branch_code'] != null)
                    _buildDetailRow(context, 'Branch Code', _bankDetails['branch_code'].toString(), copyable: true),
                  if (_bankDetails['swift_code'] != null)
                    _buildDetailRow(context, 'SWIFT / BIC', _bankDetails['swift_code'].toString(), copyable: true),
                  _buildDetailRow(context, 'Reference', _reference, copyable: true, highlight: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Warning — use exact reference
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade600.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use the exact reference number above when making the transfer. This is how we match your payment.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instructions
            if (_instructions.isNotEmpty) ...[
              Text(
                'Steps to complete payment',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._instructions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1, right: 10),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
            ],

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _confirmTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                child: _isConfirming
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'I Have Made the Transfer',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Your enrollment will be confirmed once payment is verified (24–72 hrs)',
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool copyable = false,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant.withOpacity(0.4))),
        color: highlight ? colors.primary.withOpacity(0.06) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                color: highlight ? colors.primary : colors.onSurface,
                fontFamily: highlight ? 'monospace' : null,
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () => _copy(value, label),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.copy, size: 16, color: colors.primary),
              ),
            ),
        ],
      ),
    );
  }



  String _formatExpiry(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
