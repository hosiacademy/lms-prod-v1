// lib/src/presentation/widgets/payment/qr_scanner.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String) onScanComplete;
  final VoidCallback onClose;

  const QRScannerWidget({
    super.key,
    required this.onScanComplete,
    required this.onClose,
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  MobileScannerController? _controller;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    if (_controller != null) {
      setState(() {
        _torchEnabled = !_torchEnabled;
      });
      _controller!.toggleTorch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan QR Code',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Scanner
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          widget.onScanComplete(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                  // Overlay with cutout
                  CustomPaint(
                    painter: QRScannerOverlay(
                      borderColor: colors.primary,
                      borderRadius: 16,
                    ),
                  ),
                  // Instructions
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.onPrimary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Align QR code within frame',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
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

          // Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Torch Toggle
                IconButton(
                  onPressed: _toggleTorch,
                  icon: Icon(
                    _torchEnabled ? Icons.flash_on : Icons.flash_off,
                    color: _torchEnabled ? colors.primary : colors.onSurfaceVariant,
                  ),
                  iconSize: 32,
                ),
                // Manual Entry
                ElevatedButton.icon(
                  onPressed: () {
                    // Could open manual entry dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Manual entry not available'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Enter Manually'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class QRScannerOverlay extends CustomPainter {
  final Color borderColor;
  final double borderRadius;

  QRScannerOverlay({
    required this.borderColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.7,
        height: size.height * 0.7,
      ),
      Radius.circular(borderRadius),
    );

    canvas.drawRRect(rect, paint);

    // Corner markers
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 20.0;
    final cornerOffset = 8.0;

    // Top-left
    canvas.drawLine(
      Offset(cornerOffset, rect.top + cornerOffset + cornerLength),
      Offset(cornerOffset, rect.top + cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cornerOffset, rect.top + cornerOffset),
      Offset(cornerOffset + cornerLength, rect.top + cornerOffset),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - cornerOffset, rect.top + cornerOffset + cornerLength),
      Offset(size.width - cornerOffset, rect.top + cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - cornerOffset, rect.top + cornerOffset),
      Offset(size.width - cornerOffset - cornerLength, rect.top + cornerOffset),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(cornerOffset, rect.bottom - cornerOffset - cornerLength),
      Offset(cornerOffset, rect.bottom - cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cornerOffset, rect.bottom - cornerOffset),
      Offset(cornerOffset + cornerLength, rect.bottom - cornerOffset),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - cornerOffset, rect.bottom - cornerOffset - cornerLength),
      Offset(size.width - cornerOffset, rect.bottom - cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - cornerOffset, rect.bottom - cornerOffset),
      Offset(size.width - cornerOffset - cornerLength, rect.bottom - cornerOffset),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
