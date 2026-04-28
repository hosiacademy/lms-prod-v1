import 'package:flutter/material.dart';

/// Payment Methods Strip — shows only the accepted payment methods
/// EFT, In-Shop, Visa Card, Mastercard, ZimSwitch — powered by SmatPay Africa
class PaymentMethodsMarquee extends StatelessWidget {
  const PaymentMethodsMarquee({super.key});

  static const _methods = [
    _PaymentMethod(label: 'EFT', icon: Icons.account_balance_rounded, color: Color(0xFF1565C0)),
    _PaymentMethod(label: 'In-Shop', icon: Icons.store_rounded, color: Color(0xFF2E7D32)),
    _PaymentMethod(label: 'Visa Card', icon: Icons.credit_card_rounded, color: Color(0xFF1A237E)),
    _PaymentMethod(label: 'Mastercard', icon: Icons.credit_card_rounded, color: Color(0xFFB71C1C)),
    _PaymentMethod(label: 'ZimSwitch', icon: Icons.swap_horiz_rounded, color: Color(0xFF4A148C)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: colors.surface,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // SmatPay branding header
          GestureDetector(
            onTap: () => _showPaymentExplanation(context, theme, colors),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF172E3D) : colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.primary.withAlpha(40), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: colors.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Secure Payments',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '|',
                      style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface.withAlpha(80)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Powered by SmatPay AFRICA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFF79150),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.info_outline_rounded, color: colors.primary.withValues(alpha: 0.5), size: 12),
                  ],
                ),
              ),
            ),
          ),
          // Payment method badges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _methods.map((method) => _PaymentMethodBadge(method: method, colors: colors, theme: theme)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentExplanation(BuildContext context, ThemeData theme, ColorScheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.security_rounded, color: colors.primary),
            const SizedBox(width: 12),
            const Text('Secure Payments'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How we protect your transactions:',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _bulletPoint(theme, colors, 'End-to-end encryption for all sensitive data.'),
            _bulletPoint(theme, colors, 'PCI-DSS compliant processing through SmatPay Africa.'),
            _bulletPoint(theme, colors, 'We do not store your full card details on our servers.'),
            _bulletPoint(theme, colors, 'Multi-factor authentication for high-value enrollments.'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF79150).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF79150).withValues(alpha: 0.3)),
              ),
              child: Text(
                'Powered by SmatPay AFRICA — Your trusted partner for secure digital payments across the continent.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFD35400),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(ThemeData theme, ColorScheme colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: colors.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  final String label;
  final IconData icon;
  final Color color;
  const _PaymentMethod({required this.label, required this.icon, required this.color});
}

class _PaymentMethodBadge extends StatelessWidget {
  final _PaymentMethod method;
  final ColorScheme colors;
  final ThemeData theme;

  const _PaymentMethodBadge({required this.method, required this.colors, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: method.color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: method.color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(method.icon, color: method.color, size: 18),
          const SizedBox(width: 8),
          Text(
            method.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: method.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
