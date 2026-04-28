// quick_payment_modal.dart
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../country_selector.dart';
import '../../../core/constants/african_currencies.dart';
import '../../../core/services/currency_service.dart';

class PaymentBottomSheet extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final double price; // USD price
  final String? userCountry;
  final String? userId;
  final String? userEmail;
  final String? userName;

  const PaymentBottomSheet({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.price,
    this.userCountry,
    this.userId,
    this.userEmail,
    this.userName,
  });

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  String? _selectedCountry;
  String? _selectedPaymentMethod;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.userCountry ?? 'KE';
  }

  @override
  Widget build(BuildContext context) {
    final localPrice = _calculateLocalPrice(widget.price, _selectedCountry!);
    final currencySymbol =
        AfricanCurrencies.getCurrencySymbol(_selectedCountry!);
    final currencyCode = AfricanCurrencies.getCurrencyCode(_selectedCountry!);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enroll in Course',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Course info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.courseTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyService.instance.formatPrice(localPrice, currencyCode: currencyCode),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Country selector
          Text(
            'Select your country for correct pricing:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          CountrySelector(
            selectedCountryCode: _selectedCountry,
            onCountrySelected: (countryCode) {
              setState(() => _selectedCountry = countryCode);
            },
            showCurrencyInfo: true,
          ),

          const SizedBox(height: 20),

          // Payment method selection
          Text(
            'Select payment method:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodSelection(),

          // Phone input for mobile money
          if (_selectedPaymentMethod == 'mpesa' ||
              _selectedPaymentMethod == 'mtn_mobile_money')
            _buildPhoneInput(),

          const SizedBox(height: 24),

          // Pay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _selectedPaymentMethod != null ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Complete Enrollment',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'You\'ll get instant access to the course after payment',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    final methods = ['mpesa', 'paystack', 'card', 'paypal'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((method) {
        final methodName = method.toString().split('.').last;
        final isSelected = _selectedPaymentMethod == methodName;

        return ChoiceChip(
          label: Text(_getMethodDisplayName(methodName)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedPaymentMethod = selected ? methodName : null;
            });
          },
          avatar: Image.asset(
            'assets/images/payments/$methodName.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                Icon(_getMethodIcon(methodName), size: 24),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhoneInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InternationalPhoneNumberInput(
        key: ValueKey('phone_$_selectedCountry'),
        onInputChanged: (PhoneNumber number) {
          _phoneNumber = number.phoneNumber;
        },
        selectorConfig: const SelectorConfig(
          selectorType: PhoneInputSelectorType.DROPDOWN,
          showFlags: true,
          setSelectorButtonAsPrefixIcon: true,
        ),
        ignoreBlank: false,
        autoValidateMode: AutovalidateMode.onUserInteraction,
        initialValue: PhoneNumber(isoCode: _selectedCountry),
        formatInput: true,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        inputDecoration: const InputDecoration(
          labelText: 'Phone Number',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  double _calculateLocalPrice(double usdPrice, String countryCode) {
    // In real app, get exchange rate from API
    final rates = {
      'KE': 150.0,
      'NG': 1200.0,
      'GH': 12.0,
      'ZA': 18.0,
      'TZ': 2500.0,
      'UG': 3700.0,
      'RW': 1300.0,
      'ZM': 25.0,
    };

    final rate = rates[countryCode] ?? 100.0;
    return usdPrice * rate;
  }

  String _getMethodDisplayName(String methodName) {
    switch (methodName) {
      case 'mpesa':
        return 'M-Pesa';
      case 'paystack':
        return 'Paystack';
      case 'mtn_mobile_money':
        return 'MTN Mobile Money';
      case 'airtel_money':
        return 'Airtel Money';
      case 'card':
        return 'Credit/Debit Card';
      case 'paypal':
        return 'PayPal';
      default:
        return methodName.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _getMethodIcon(String methodName) {
    switch (methodName) {
      case 'mpesa':
      case 'mtn_mobile_money':
      case 'airtel_money':
        return Icons.phone_android;
      case 'card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.payments;
      default:
        return Icons.payment;
    }
  }

  void _processPayment() {
    // Create order
    // Process payment
    // This would integrate with your bloc
    print('Processing payment for ${widget.courseTitle}');
    print('Country: $_selectedCountry');
    print('Method: $_selectedPaymentMethod');
    print('Phone: $_phoneNumber');

    // Close bottom sheet
    Navigator.pop(context);

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful!'),
        content: const Text('You now have access to the course.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
