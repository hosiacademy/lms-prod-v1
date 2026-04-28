// lib/src/presentation/widgets/payment/qr_payment_widget.dart

import 'package:flutter/material.dart';
import 'qr_provider_selection.dart';
import 'qr_scanner.dart';
import 'qr_code_display.dart';
import '../../../core/services/currency_service.dart';

class QRPaymentWidget extends StatefulWidget {
  final double amount;
  final String currency;
  final String programId;
  final String programType;
  final String reference;
  final String? merchantName;
  final VoidCallback onPaymentSuccess;
  final Function(String error) onPaymentError;

  const QRPaymentWidget({
    super.key,
    required this.amount,
    required this.currency,
    required this.programId,
    required this.programType,
    required this.reference,
    this.merchantName,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  @override
  State<QRPaymentWidget> createState() => _QRPaymentWidgetState();
}

class _QRPaymentWidgetState extends State<QRPaymentWidget> {
  String? _selectedProvider;
  String? _paymentReference;
  bool _showScanner = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                  child: Icon(Icons.qr_code, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'QR Code Payment',
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

            if (_selectedProvider == null) ...[
              // Provider Selection
              QRProviderSelection(
                selectedProvider: _selectedProvider,
                onProviderSelected: (provider) {
                  setState(() {
                    _selectedProvider = provider;
                    _paymentReference = 'QR-${DateTime.now().millisecondsSinceEpoch}';
                  });
                },
              ),
              const SizedBox(height: 24),

              // Scan QR Option
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 48,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Have a QR code to scan?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'If you already have a payment QR code, scan it here',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _openScanner,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // QR Code Display
              QRCodeDisplayWidget(
                amount: widget.amount,
                currency: widget.currency,
                programId: widget.programId,
                programType: widget.programType,
                merchantName: widget.merchantName,
                reference: _paymentReference!,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedProvider = null;
                      _paymentReference = null;
                    });
                  },
                  child: const Text('Choose Different Method'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QRScannerWidget(
        onScanComplete: (qrData) {
          Navigator.pop(ctx);
          _processScannedQR(qrData);
        },
        onClose: () {
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _processScannedQR(String qrData) {
    try {
      // Parse scanned QR data
      // In production, this would parse the actual QR payment format
      setState(() {
        _selectedProvider = 'scanned_qr';
        _paymentReference = 'QR-${DateTime.now().millisecondsSinceEpoch}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code scanned successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      widget.onPaymentError('Invalid QR code format');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code format'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
