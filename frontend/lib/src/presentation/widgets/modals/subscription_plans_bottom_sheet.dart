// subscription_plans_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/services/currency_service.dart';
import '../../pages/onboarding/models/payment_enums.dart';
import '../payment_widgets.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String period; // monthly, yearly, etc.
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
    this.isPopular = false,
  });
}

class SubscriptionPlansBottomSheet extends StatefulWidget {
  final List<SubscriptionPlan> plans;
  final Function(SubscriptionPlan, PaymentMethod)? onSubscribe;
  final String? selectedPlanId;

  const SubscriptionPlansBottomSheet({
    super.key,
    required this.plans,
    this.onSubscribe,
    this.selectedPlanId,
  });

  @override
  State<SubscriptionPlansBottomSheet> createState() =>
      _SubscriptionPlansBottomSheetState();
}

class _SubscriptionPlansBottomSheetState
    extends State<SubscriptionPlansBottomSheet> {
  SubscriptionPlan? _selectedPlan;
  PaymentMethod? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    if (widget.selectedPlanId != null) {
      _selectedPlan = widget.plans.firstWhere(
        (plan) => plan.id == widget.selectedPlanId,
        orElse: () => widget.plans.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choose a Plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Plan Selection
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                ...widget.plans
                    .map((plan) => _buildPlanCard(plan, primaryColor)),

                const SizedBox(height: 24),

                // Payment Method Selection
                if (_selectedPlan != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Payment Method',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        PaymentMethodChip(
                          method: PaymentMethod.creditCard,
                          isSelected: _selectedPaymentMethod ==
                              PaymentMethod.creditCard,
                          onTap: () => setState(() => _selectedPaymentMethod =
                              PaymentMethod.creditCard),
                        ),
                        const SizedBox(width: 8),
                        PaymentMethodChip(
                          method: PaymentMethod.mpesa,
                          isSelected:
                              _selectedPaymentMethod == PaymentMethod.mpesa,
                          onTap: () => setState(() =>
                              _selectedPaymentMethod = PaymentMethod.mpesa),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subscribe Button
                  if (_selectedPaymentMethod != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedPlan != null &&
                                _selectedPaymentMethod != null) {
                              widget.onSubscribe?.call(
                                  _selectedPlan!, _selectedPaymentMethod!);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Subscribe for ${CurrencyService.instance.formatPrice(_selectedPlan!.price)}/${_selectedPlan!.period}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, Color primaryColor) {
    final isSelected = _selectedPlan?.id == plan.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
                  .withValues(alpha: 0.05)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? primaryColor
                        : Colors.black,
                  ),
                ),
                if (plan.isPopular)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              '${CurrencyService.instance.formatPrice(plan.price)}/${plan.period}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: primaryColor, // FIXED: Use primaryColor directly
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
