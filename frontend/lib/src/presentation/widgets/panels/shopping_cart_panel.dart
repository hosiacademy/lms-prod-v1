import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/services/currency_service.dart';
import '../../../data/models/course.dart';
import 'bulk_enrollment_panel.dart';
import 'offerings_browser_panel.dart';

/// Shopping cart panel showing courses added to cart
class ShoppingCartPanel extends StatefulWidget {
  const ShoppingCartPanel({super.key});

  @override
  State<ShoppingCartPanel> createState() => _ShoppingCartPanelState();
}

class _ShoppingCartPanelState extends State<ShoppingCartPanel> {
  bool _isCheckingOut = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final cartItems = cart.cartItems;

        if (_isCheckingOut) {
          return BulkEnrollmentPanel(courses: cartItems);
        }

        if (cartItems.isEmpty) {
          return const OfferingsBrowserPanel();
        }

        return Column(
          children: [
            // Cart Items List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return _CartItem(item: item);
                },
              ),
            ),

            // Total and Checkout Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Payment',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: CurrencyService.instance,
                        builder: (context, _) => Text(
                          CurrencyService.instance
                              .formatUSDAmount(cart.totalPrice),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Premium Checkout Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _proceedToCheckout(context, cartItems),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary, // Using brand primary
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Complete Secure Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Secure Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 14,
                          color: colors.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 8),
                      Text(
                        '256-bit SSL Secure Encryption',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _proceedToCheckout(BuildContext context, List<Course> items) {
    setState(() => _isCheckingOut = true);
  }
}

class _CartItem extends StatelessWidget {
  final Course item;

  const _CartItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 70,
                child: item.featureImageUrl != null
                    ? Image.network(
                        item.featureImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: colors.surfaceContainerHighest,
                          child: Icon(Icons.school, color: colors.onSurface),
                        ),
                      )
                    : Container(
                        color: colors.surfaceContainerHighest,
                        child: Icon(Icons.school, color: colors.onSurface),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Course Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.instructorName != null)
                    Text(
                      'by ${item.instructorName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.rating != null) ...[
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          item.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                      ],
                      ListenableBuilder(
                        listenable: CurrencyService.instance,
                        builder: (context, _) => Text(
                          CurrencyService.instance
                              .formatUSDAmount(item.price ?? 0.0),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error),
              onPressed: () {
                context.read<CartProvider>().removeFromCart(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Removed from cart')),
                );
              },
              tooltip: 'Remove from cart',
            ),
          ],
        ),
      ),
    );
  }
}
