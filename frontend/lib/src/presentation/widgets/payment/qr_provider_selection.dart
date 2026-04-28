// lib/src/presentation/widgets/payment/qr_provider_selection.dart

import 'package:flutter/material.dart';

class QRProviderSelection extends StatelessWidget {
  final String? selectedProvider;
  final Function(String) onProviderSelected;

  const QRProviderSelection({
    super.key,
    this.selectedProvider,
    required this.onProviderSelected,
  });

  static const List<Map<String, dynamic>> _providers = const [
    const {
      'code': 'snapscan',
      'name': 'SnapScan',
      'color': const Color(0xFF0055A4),
      'icon': Icons.qr_code,
      'description': 'Snap to pay',
    },
    const {
      'code': 'zapper',
      'name': 'Zapper',
      'color': const Color(0xFF8A2BE2),
      'icon': Icons.qr_code_scanner,
      'description': 'Scan & pay',
    },
    const {
      'code': 'payfast',
      'name': 'PayFast',
      'color': const Color(0xFFFF6B00),
      'icon': Icons.payment,
      'description': 'Instant EFT & QR',
    },
    const {
      'code': 'mpesa_qr',
      'name': 'M-Pesa QR',
      'color': const Color(0xFF4CAF50),
      'icon': Icons.phone_android,
      'description': 'M-Pesa QR payments',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.qr_code, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select QR Provider',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Choose your preferred QR payment app',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _providers.map((provider) {
                final isSelected = selectedProvider == provider['code'];
                return GestureDetector(
                  onTap: () => onProviderSelected(provider['code']),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider['icon'] as IconData,
                          size: 32,
                          color: isSelected
                              ? provider['color'] as Color
                              : colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? provider['color'] as Color
                                : colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider['description'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? (provider['color'] as Color).withOpacity(0.8)
                                : colors.onSurfaceVariant.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
