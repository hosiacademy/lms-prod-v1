// payment_widgets.dart - FIXED VERSION
import 'package:flutter/material.dart';
import '../pages/onboarding/models/payment_enums.dart';
import '../pages/onboarding/models/order_models.dart';
import '../../../core/services/currency_service.dart';

class PaymentMethodChip extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodChip({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/payments/${method.value}.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => Icon(
                method.icon,
                size: 24,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              method.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onPayPressed;
  final bool isLoading;

  const OrderSummaryCard({
    super.key,
    required this.order,
    this.onPayPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Course items
            ...order.items
                .map((item) => _buildCourseItem(item, theme, order.currency)),

            Divider(
              height: 24,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),

            // Pricing breakdown
            _buildPriceRow('Subtotal', order.subtotal, theme, order.currency),
            if (order.discount != null && order.discount! > 0)
              _buildPriceRow(
                  'Discount', -order.discount!, theme, order.currency,
                  isDiscount: true),
            _buildPriceRow('Tax', order.tax, theme, order.currency),
            const SizedBox(height: 8),
            Divider(
              height: 16,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            _buildPriceRow('Total', order.total, theme, order.currency,
                isTotal: true),

            const SizedBox(height: 20),

            if (onPayPressed != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onPayPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Pay ${order.formattedTotal}',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseItem(OrderItem item, ThemeData theme, String currency) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.courseImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.courseImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.school,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  )
                : Icon(
                    Icons.school,
                    color: colorScheme.onSurface,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.courseTitle,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.instructorName != null)
                  Text(
                    item.instructorName!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(item.finalPrice, currency),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount,
    ThemeData theme,
    String currency, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  )
                : textTheme.bodyMedium?.copyWith(
                    color: isDiscount
                        ? colorScheme.tertiary
                        : colorScheme.onSurface,
                  ),
          ),
          Text(
            '${isDiscount && amount > 0 ? '-' : ''}${_formatCurrency(amount.abs(), currency)}',
            style: isTotal
                ? textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  )
                : textTheme.bodyMedium?.copyWith(
                    color: isDiscount
                        ? colorScheme.tertiary
                        : colorScheme.onSurface,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    return CurrencyService.instance.formatPrice(amount, currencyCode: currency);
  }
}

class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const PaymentStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.processing:
        return Icons.refresh;
      case PaymentStatus.pending:
        return Icons.access_time;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.reply;
      case PaymentStatus.partiallyRefunded:
        return Icons.reply_outlined;
      case PaymentStatus.disputed:
        return Icons.warning;
      case PaymentStatus.onHold:
        return Icons.pause_circle;
      case PaymentStatus.expired:
        return Icons.timer_off;
      default:
        return Icons.help;
    }
  }
}

// Additional Payment Widgets

class PaymentDetailsForm extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final ValueChanged<String> onCardNumberChanged;
  final ValueChanged<String> onExpiryChanged;
  final ValueChanged<String> onCvvChanged;

  const PaymentDetailsForm({
    super.key,
    required this.controllers,
    required this.onCardNumberChanged,
    required this.onExpiryChanged,
    required this.onCvvChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controllers['cardNumber'],
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon:
                Icon(Icons.credit_card, color: colorScheme.onSurface),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
          keyboardType: TextInputType.number,
          onChanged: onCardNumberChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controllers['cardHolder'],
          decoration: InputDecoration(
            labelText: 'Card Holder Name',
            hintText: 'John Doe',
            prefixIcon: Icon(Icons.person, color: colorScheme.onSurface),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllers['expiry'],
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  prefixIcon: Icon(Icons.calendar_today,
                      color: colorScheme.onSurface),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                onChanged: onExpiryChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controllers['cvv'],
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon:
                      Icon(Icons.lock, color: colorScheme.onSurface),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: onCvvChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PaymentProviderSelector extends StatelessWidget {
  final dynamic selectedProvider;
  final Function(dynamic) onProviderSelected;

  const PaymentProviderSelector({
    super.key,
    required this.selectedProvider,
    required this.onProviderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Payment Provider',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred payment service provider',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentAmountDisplay extends StatelessWidget {
  final double amount;
  final String currency;
  final bool showDetails;
  final double? discount;
  final double? tax;

  const PaymentAmountDisplay({
    super.key,
    required this.amount,
    this.currency = 'USD',
    this.showDetails = false,
    this.discount,
    this.tax,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDetails && (discount != null || tax != null))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (discount != null && discount! > 0)
                  _buildDetailRow(
                      'Subtotal', amount + discount!, currency, theme),
                if (discount != null && discount! > 0)
                  _buildDetailRow('Discount', -discount!, currency, theme,
                      isDiscount: true),
                if (tax != null && tax! > 0)
                  _buildDetailRow('Tax', tax!, currency, theme),
                const SizedBox(height: 8),
                Divider(color: colorScheme.outline.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                _formatCurrency(amount, currency),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, double value, String currency, ThemeData theme,
      {bool isDiscount = false}) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: isDiscount
                  ? colorScheme.tertiary
                  : colorScheme.onSurface,
            ),
          ),
          Text(
            '${isDiscount && value > 0 ? '-' : ''}${_formatCurrency(value.abs(), currency)}',
            style: textTheme.bodySmall?.copyWith(
              color: isDiscount
                  ? colorScheme.tertiary
                  : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    return CurrencyService.instance.formatPrice(amount, currencyCode: currency);
  }
}
