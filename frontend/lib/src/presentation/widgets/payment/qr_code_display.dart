// lib/src/presentation/widgets/payment/qr_code_display.dart

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeDisplayWidget extends StatefulWidget {
  final double amount;
  final String currency;
  final String programId;
  final String programType;
  final String? merchantName;
  final String reference;

  const QRCodeDisplayWidget({
    super.key,
    required this.amount,
    required this.currency,
    required this.programId,
    required this.programType,
    this.merchantName,
    required this.reference,
  });

  @override
  State<QRCodeDisplayWidget> createState() => _QRCodeDisplayWidgetState();
}

class _QRCodeDisplayWidgetState extends State<QRCodeDisplayWidget> {
  final GlobalKey _qrKey = GlobalKey();
  Timer? _timer;
  int _secondsRemaining = 900;
  late NumberFormat numberFormat;

  @override
  void initState() {
    super.initState();
    numberFormat = NumberFormat('#,##0.00');
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR code has expired'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadQRCode() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use screenshot to save QR code'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareQRCode() async {
    final text = 'Pay ${numberFormat.format(widget.amount)} ${widget.currency} to Hosi Academy\n'
        'Reference: ${widget.reference}\n'
        'Program: ${widget.programId}';
    
    await Clipboard.setData(ClipboardData(text: text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment details copied to clipboard')),
      );
    }
  }

  Future<void> _copyReference() async {
    await Clipboard.setData(ClipboardData(text: widget.reference));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reference copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final paymentData = {
      'amount': widget.amount,
      'currency': widget.currency,
      'programId': widget.programId,
      'programType': widget.programType,
      'reference': widget.reference,
      'merchant': widget.merchantName ?? 'Hosi Academy',
    };
    final paymentUrl = 'https://hosiacademy.africa/pay/${base64Encode(utf8.encode(jsonEncode(paymentData)))}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.qr_code, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment QR Code',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Valid for: ${_formatTime(_secondsRemaining)}',
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                key: _qrKey,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.primary.withOpacity(0.2)),
                ),
                child: QrImageView(
                  data: paymentUrl,
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: colors.primary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Amount: ${numberFormat.format(widget.amount)} ${widget.currency}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reference: ${widget.reference}',
              style: TextStyle(
                color: colors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyReference,
                    icon: Icon(Icons.copy, size: 16),
                    label: Text('COPY REFERENCE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareQRCode,
                    icon: Icon(Icons.share, size: 16),
                    label: Text('SHARE PAYMENT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
