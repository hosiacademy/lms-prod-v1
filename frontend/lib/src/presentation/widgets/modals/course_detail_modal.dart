import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../data/models/masterclass.dart';
import '../../../core/services/currency_service.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../pages/onboarding/models/course_payment_models.dart';
import '../../pages/onboarding/models/payment_enums.dart';
import '../../pages/onboarding/widgets/sections/payment_logo.dart';
import '../payment_widgets.dart';

// Payment provider mapping by country
const Map<String, List<String>> countryPaymentProviders = {
  // East Africa
  'KE': ['M-Pesa', 'Flutterwave', 'PayPal', 'Bank Transfer'], // Kenya
  'TZ': ['M-Pesa', 'Airtel Money', 'Flutterwave'], // Tanzania
  'UG': ['MTN MoMo', 'Airtel Money', 'Flutterwave'], // Uganda
  'RW': ['MTN MoMo', 'Airtel Money'], // Rwanda
  'ET': ['HelloCash', 'Amole', 'CBE Birr'], // Ethiopia
  'BI': ['Lumicash', 'EcoCash'], // Burundi
  'DJ': ['Djibouti Telecom', 'Somali Money Transfer'], // Djibouti
  'ER': ['EriTel', 'Nedbank Eritrea'], // Eritrea
  'SS': ['MTN MoMo', 'Zain Cash'], // South Sudan
  'SO': ['Dahabshiil', 'SomTel'], // Somalia

  // West Africa
  'NG': ['Paystack', 'Flutterwave', 'Interswitch', 'Remita'], // Nigeria
  'GH': ['MTN MoMo', 'Vodafone Cash', 'AirtelTigo Money'], // Ghana
  'CI': ['Orange Money', 'MTN MoMo', 'Moov Money'], // Ivory Coast
  'SN': ['Orange Money', 'Free Money', 'Wave'], // Senegal
  'ML': ['Orange Money', 'Moov Money'], // Mali
  'BF': ['Orange Money', 'Moov Money'], // Burkina Faso
  'BJ': ['MTN MoMo', 'Moov Money'], // Benin
  'NE': ['Orange Money', 'Moov Money'], // Niger
  'TG': ['Moov Money', 'Togocel'], // Togo
  'GN': ['Orange Money', 'MTN MoMo'], // Guinea
  'GW': ['Orange Money', 'MTN MoMo'], // Guinea-Bissau
  'SL': ['Orange Money', 'Africell'], // Sierra Leone
  'LR': ['Orange Money', 'Lonestar Cell'], // Liberia
  'MR': ['Mauritel', 'Mattrans'], // Mauritania
  'GM': ['QCell', 'Gamcel'], // Gambia
  'CV': ['CVMóvel', 'Unitel T+'], // Cape Verde

  // Southern Africa
  'ZA': ['SnapScan', 'PayFast', 'FNB', 'Nedbank'], // South Africa
  'ZM': ['MTN MoMo', 'Airtel Money', 'Zamtel Kwacha'], // Zambia
  'ZW': ['EcoCash', 'OneMoney', 'Telecash'], // Zimbabwe
  'BW': ['Orange Money', 'BTC Mobile', 'Mascom MyZaka'], // Botswana
  'NA': ['Namibia Bank', 'MTC', 'TN Mobile'], // Namibia
  'MW': ['Airtel Money', 'TNM Mpamba'], // Malawi
  'MZ': ['m-Pesa', 'Vodacom M-Pesa'], // Mozambique
  'SZ': ['MTN MoMo', 'Eswatini Mobile'], // Eswatini
  'LS': ['EcoCash', 'Vodacom M-Pesa'], // Lesotho
  'MG': ['Orange Money', 'Airtel Money'], // Madagascar
  'MU': ['MCB Juice', 'MauBank'], // Mauritius
  'KM': ['Comores Telecom', 'Huri'], // Comoros
  'SC': ['Seychelles Savings Bank', 'Mauritius Commercial Bank'], // Seychelles

  // North Africa
  'EG': ['Fawry', 'Paymob', 'Vodafone Cash'], // Egypt
  'MA': ['CIH Bank', 'Attijariwafa Bank', 'BMCE'], // Morocco
  'DZ': ['Djazicarte', 'Carte Edahabia'], // Algeria
  'TN': ['Poste Tunisienne', 'Amen Bank', 'BIAT'], // Tunisia
  'LY': ['Libyan Post', 'Al Wahda Bank'], // Libya
  'SD': ['Bank of Khartoum', 'Zain Cash'], // Sudan

  // Central Africa
  'CM': ['MTN MoMo', 'Orange Money', 'Express Union'], // Cameroon
  'CD': ['Airtel Money', 'Orange Money', 'Vodacom M-Pesa'], // DR Congo
  'CG': ['MTN MoMo', 'Airtel Money'], // Congo
  'GA': ['Airtel Money', 'Moov Money'], // Gabon
  'GQ': ['GETESA', 'GEPetrol'], // Equatorial Guinea
  'CF': ['Orange Money', 'Moov Money'], // Central African Republic
  'TD': ['Tigo Cash', 'Airtel Money'], // Chad
  'AO': ['Unitel', 'Movicel'], // Angola
  'ST': ['Standard Bank', 'Banco Internacional'], // São Tomé and Príncipe
};

class CourseDetailModal extends StatefulWidget {
  final Masterclass masterclass;
  final VoidCallback? onEnroll;
  final bool showEnrollButton;

  const CourseDetailModal({
    super.key,
    required this.masterclass,
    this.onEnroll,
    this.showEnrollButton = true,
  });

  @override
  State<CourseDetailModal> createState() => _CourseDetailModalState();
}

class _CourseDetailModalState extends State<CourseDetailModal> {
  int _quantity = 1;
  bool _isCorporate = false;
  String? _selectedPaymentMethod;
  String? _selectedProviderName;
  PaymentLogo? _selectedProviderLogo;
  final Map<String, TextEditingController> _controllers = {};
  bool _isProcessing = false;
  List<String> _availableProviders = [];

  // Corporate fields
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _companyVATController = TextEditingController();

  // Individual fields
  final TextEditingController _individualNameController =
      TextEditingController();
  final TextEditingController _individualEmailController =
      TextEditingController();
  final TextEditingController _individualPhoneController =
      TextEditingController();

  // Payment fields
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  // Mobile money fields
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _mobileProviderController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize currency service for IP-based currency conversion
    CurrencyService.instance.initialize();

    // Initialize controllers
    _controllers['cardNumber'] = _cardNumberController;
    _controllers['cardHolder'] = _cardHolderController;
    _controllers['expiry'] = _expiryController;
    _controllers['cvv'] = _cvvController;
    _controllers['mobileNumber'] = _mobileNumberController;

    // Set default payment method
    _selectedPaymentMethod = PaymentMethod.creditCard.value;

    // Load available payment providers based on country
    _loadAvailableProviders();

    // Set default provider
    if (_availableProviders.isNotEmpty) {
      _selectedProviderName = _availableProviders.first;
      _selectedProviderLogo = paymentLogos.firstWhere(
        (logo) => logo.name == _selectedProviderName,
        orElse: () => paymentLogos.first,
      );
    }
  }

  void _loadAvailableProviders() {
    final countryCode =
        widget.masterclass.countryCode ?? 'KE'; // Default to Kenya
    final providers = countryPaymentProviders[countryCode] ??
        ['Flutterwave', 'PayPal', 'Bank Transfer'];

    // Add global providers
    final allProviders = [
      ...providers,
      'Flutterwave', // Always available
      'PayPal', // Always available
      'Bank Transfer', // Always available
    ].toSet().toList(); // Remove duplicates

    setState(() {
      _availableProviders = allProviders;
    });
  }

  List<PaymentLogo> _getProviderLogosForCountry() {
    final countryCode = widget.masterclass.countryCode ?? 'KE';
    final providers = countryPaymentProviders[countryCode] ?? [];

    return paymentLogos.where((logo) {
      // Include providers for this country
      if (providers.contains(logo.name)) return true;
      // Always include global providers
      if (['Flutterwave', 'PayPal', 'Bank Transfer'].contains(logo.name))
        return true;
      return false;
    }).toList();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _companyVATController.dispose();

    _individualNameController.dispose();
    _individualEmailController.dispose();
    _individualPhoneController.dispose();

    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _mobileNumberController.dispose();
    _mobileProviderController.dispose();

    super.dispose();
  }

  double get _totalAmount {
    final price = widget.masterclass.priceUsd ?? 0;
    return CurrencyService.instance.convertFromUSD(price * _quantity);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _getCountryName() {
    final countryCode = widget.masterclass.countryCode ?? 'KE';
    const countryNames = {
      'DZ': 'Algeria',
      'AO': 'Angola',
      'BJ': 'Benin',
      'BW': 'Botswana',
      'BF': 'Burkina Faso',
      'BI': 'Burundi',
      'CV': 'Cape Verde',
      'CM': 'Cameroon',
      'CF': 'Central African Republic',
      'TD': 'Chad',
      'KM': 'Comoros',
      'CG': 'Congo',
      'CD': 'DR Congo',
      'CI': 'Ivory Coast',
      'DJ': 'Djibouti',
      'EG': 'Egypt',
      'GQ': 'Equatorial Guinea',
      'ER': 'Eritrea',
      'SZ': 'Eswatini',
      'ET': 'Ethiopia',
      'GA': 'Gabon',
      'GM': 'Gambia',
      'GH': 'Ghana',
      'GN': 'Guinea',
      'GW': 'Guinea-Bissau',
      'KE': 'Kenya',
      'LS': 'Lesotho',
      'LR': 'Liberia',
      'LY': 'Libya',
      'MG': 'Madagascar',
      'MW': 'Malawi',
      'ML': 'Mali',
      'MR': 'Mauritania',
      'MU': 'Mauritius',
      'MA': 'Morocco',
      'MZ': 'Mozambique',
      'NA': 'Namibia',
      'NE': 'Niger',
      'NG': 'Nigeria',
      'RW': 'Rwanda',
      'ST': 'São Tomé and Príncipe',
      'SN': 'Senegal',
      'SC': 'Seychelles',
      'SL': 'Sierra Leone',
      'SO': 'Somalia',
      'ZA': 'South Africa',
      'SS': 'South Sudan',
      'SD': 'Sudan',
      'TZ': 'Tanzania',
      'TG': 'Togo',
      'TN': 'Tunisia',
      'UG': 'Uganda',
      'ZM': 'Zambia',
      'ZW': 'Zimbabwe',
    };
    return countryNames[countryCode] ??
        widget.masterclass.countryName ??
        'Africa';
  }

  void _processEnrollment() {
    if (_isProcessing) return;

    // Validate based on enrollment type
    if (_isCorporate) {
      if (_companyNameController.text.isEmpty ||
          _companyEmailController.text.isEmpty ||
          _companyPhoneController.text.isEmpty) {
        _showError('Please fill in all required company details');
        return;
      }
    } else {
      if (_individualNameController.text.isEmpty ||
          _individualEmailController.text.isEmpty) {
        _showError('Please fill in all required personal details');
        return;
      }
    }

    // Validate payment based on method
    if (_selectedPaymentMethod == PaymentMethod.creditCard.value) {
      if (_cardNumberController.text.isEmpty ||
          _cardHolderController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty) {
        _showError('Please fill in all payment details');
        return;
      }
    } else if (_selectedPaymentMethod == PaymentMethod.mobileMoney.value) {
      if (_mobileNumberController.text.isEmpty ||
          _selectedProviderName == null) {
        _showError('Please provide mobile number and select provider');
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    // Create user payment details
    final userDetails = UserPaymentDetails(
      // Remove the id parameter - it doesn't exist in the constructor
      userId: 'current_user_id', // Should come from auth
      paymentMethod: _selectedPaymentMethod!,
      providerName: _selectedProviderName,
      cardLastFour: _selectedPaymentMethod == PaymentMethod.creditCard.value &&
              _cardNumberController.text.isNotEmpty
          ? _cardNumberController.text
              .substring(_cardNumberController.text.length - 4)
          : null,
      cardHolderName: _cardHolderController.text,
      expiryDate: _expiryController.text,
      mobileNumber: _selectedPaymentMethod == PaymentMethod.mobileMoney.value
          ? _mobileNumberController.text
          : null,
      mobileProvider: _selectedPaymentMethod == PaymentMethod.mobileMoney.value
          ? _selectedProviderName
          : null,
      isDefault: false,
      createdAt: DateTime.now(),
    );

    // Create payment request
    final paymentRequest = CoursePaymentRequest(
      masterclassId: widget.masterclass.id,
      masterclassTitle: widget.masterclass.title,
      quantity: _quantity,
      unitPrice: CurrencyService.instance
          .convertFromUSD(widget.masterclass.priceUsd ?? 0),
      totalAmount: _totalAmount,
      currency: CurrencyService.instance.userCurrency,
      paymentMethod: _selectedPaymentMethod!,
      providerName: _selectedProviderName,
      userDetails: userDetails,
      isCorporate: _isCorporate,
      countryCode: widget.masterclass.countryCode,
      countryName: _getCountryName(),
      corporateDetails: _isCorporate
          ? CorporateDetails(
              companyName: _companyNameController.text,
              contactEmail: _companyEmailController.text,
              contactPhone: _companyPhoneController.text,
              companyAddress: _companyAddressController.text,
              vatNumber: _companyVATController.text,
            )
          : null,
      individualDetails: !_isCorporate
          ? IndividualDetails(
              fullName: _individualNameController.text,
              email: _individualEmailController.text,
              phone: _individualPhoneController.text,
            )
          : null,
      createdAt: DateTime.now(),
    );

    // Trigger payment through bloc
    context.read<PaymentBloc>().add(
          PaymentInitiated(paymentRequest: paymentRequest),
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Enrollment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have successfully enrolled in:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              widget.masterclass.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirmation has been sent to your email.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment Provider: ${_selectedProviderName ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close success dialog
              Navigator.pop(context); // Close modal
              if (widget.onEnroll != null) {
                widget.onEnroll!();
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentTypeSelector() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enrollment Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEnrollmentTypeButton(
                    'Individual',
                    Icons.person,
                    !_isCorporate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnrollmentTypeButton(
                    'Corporate',
                    Icons.business,
                    _isCorporate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentTypeButton(
      String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCorporate = label == 'Corporate';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50]! : Colors.grey[50]!,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsForm() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // High-contrast label style
    final labelStyle = TextStyle(
      color: colors.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );

    // Hint style
    final hintStyle = TextStyle(
      color: colors.onSurface,
      fontSize: 13,
    );

    // Background color for fields
    final fieldBg = isDark ? colors.surfaceContainerHighest : colors.surface;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isCorporate ? 'Company Details' : 'Personal Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (_isCorporate) ...[
              _buildTextField(
                controller: _companyNameController,
                label: 'Company Name *',
                icon: Icons.business,
                labelStyle: labelStyle,
                hintStyle: hintStyle,
                fillColor: fieldBg,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _companyEmailController,
                label: 'Contact Email *',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                labelStyle: labelStyle,
                hintStyle: hintStyle,
                fillColor: fieldBg,
                colors: colors,
              ),
              const SizedBox(height: 12),
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  _companyPhoneController.text = number.phoneNumber ?? '';
                },
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.DROPDOWN,
                  showFlags: true,
                  setSelectorButtonAsPrefixIcon: true,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.onUserInteraction,
                initialValue: PhoneNumber(
                    isoCode: widget.masterclass.countryCode ?? 'ZA'),
                textFieldController: _companyPhoneController,
                formatInput: true,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                inputDecoration: _buildInputDecorationForPhone(
                  label: 'Contact Phone *',
                  icon: Icons.phone,
                  labelStyle: labelStyle,
                  fillColor: fieldBg,
                  colors: colors,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _companyAddressController,
                label: 'Company Address',
                icon: Icons.location_on,
                maxLines: 2,
                labelStyle: labelStyle,
                hintStyle: hintStyle,
                fillColor: fieldBg,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _companyVATController,
                label: 'VAT Number',
                icon: Icons.numbers,
                labelStyle: labelStyle,
                hintStyle: hintStyle,
                fillColor: fieldBg,
                colors: colors,
              ),
            ] else ...[
              _buildTextField(
                controller: _individualNameController,
                label: 'Full Name *',
                icon: Icons.person,
                labelStyle: labelStyle,
                hintStyle: hintStyle,
                fillColor: fieldBg,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _individualEmailController,
                label: 'Email Address *',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                labelStyle: labelStyle,
                hintStyle: hintStyle,
                fillColor: fieldBg,
                colors: colors,
              ),
              const SizedBox(height: 12),
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  _individualPhoneController.text = number.phoneNumber ?? '';
                },
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.DROPDOWN,
                  showFlags: true,
                  setSelectorButtonAsPrefixIcon: true,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.onUserInteraction,
                initialValue: PhoneNumber(
                    isoCode: widget.masterclass.countryCode ?? 'ZA'),
                textFieldController: _individualPhoneController,
                formatInput: true,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                inputDecoration: _buildInputDecorationForPhone(
                  label: 'Phone Number',
                  icon: Icons.phone,
                  labelStyle: labelStyle,
                  fillColor: fieldBg,
                  colors: colors,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required TextStyle labelStyle,
    required TextStyle hintStyle,
    required Color fillColor,
    required ColorScheme colors,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        hintText: label.contains('*') ? null : 'Enter ${label.toLowerCase()}',
        hintStyle: hintStyle,
        prefixIcon: icon != null ? Icon(icon, color: labelStyle.color) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: labelStyle.color!.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: labelStyle.color!.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  InputDecoration _buildInputDecorationForPhone({
    required String label,
    required IconData icon,
    required TextStyle labelStyle,
    required Color fillColor,
    required ColorScheme colors,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: labelStyle,
      prefixIcon: Icon(icon, color: labelStyle.color),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: labelStyle.color!.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: labelStyle.color!.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildQuantitySelector() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Number of Participants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() {
                        _quantity--;
                      });
                    }
                  },
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _quantity++;
                    });
                  },
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${CurrencyService.instance.formatPrice(_totalAmount, currencyCode: 'USD')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_quantity > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Bulk enrollment: ${CurrencyService.instance.formatPrice(widget.masterclass.priceUsd ?? 0)} × $_quantity',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProviderSelector() {
    final countryProviders = _getProviderLogosForCountry();
    final countryName = _getCountryName();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Available Payment Providers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(countryName),
                  backgroundColor: Colors.blue[50]!,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Select a payment provider available in $countryName:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Payment providers grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth < 300
                    ? 2
                    : constraints.maxWidth < 500
                        ? 3
                        : 4;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: countryProviders.length,
                  itemBuilder: (context, index) {
                final logo = countryProviders[index];
                final isSelected = _selectedProviderName == logo.name;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedProviderName = logo.name;
                      _selectedProviderLogo = logo;
                      // Auto-select appropriate payment method
                      if (logo.name.contains('M-Pesa') ||
                          logo.name.contains('MoMo') ||
                          logo.name.contains('Money')) {
                        _selectedPaymentMethod =
                            PaymentMethod.mobileMoney.value;
                      } else if (logo.name == 'Bank Transfer') {
                        _selectedPaymentMethod =
                            PaymentMethod.bankTransfer.value;
                      } else {
                        _selectedPaymentMethod = PaymentMethod.creditCard.value;
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50]! : Colors.grey[50]!,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        logo.logoPath != null
                            ? Image.asset(
                                logo.logoPath!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                logo.icon,
                                size: 32,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                        const SizedBox(height: 8),
                        Text(
                          logo.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.blue : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
                );
              },
            ),

            // Provider description
            if (_selectedProviderLogo != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50]!,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedProviderLogo!.icon,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedProviderLogo!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getProviderDescription(
                                _selectedProviderLogo!.name),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getProviderDescription(String providerName) {
    final descriptions = {
      'M-Pesa': 'Mobile money service widely used in East Africa',
      'MTN MoMo': 'MTN Mobile Money available across Africa',
      'Airtel Money': 'Airtel mobile money service',
      'Flutterwave': 'Pan-African payment gateway',
      'Paystack': 'Nigerian payment processing company',
      'PayPal': 'International online payment system',
      'Bank Transfer': 'Direct bank-to-bank transfer',
      'Interswitch': 'Digital payment and commerce company',
      'Remita': 'Payment platform for Nigeria',
      'PayFast': 'South African payment gateway',
      'SnapScan': 'South African QR code payments',
      'Fawry': 'Egyptian e-payment platform',
      'Orange Money': 'Orange Telecom mobile money',
      'Vodacom': 'Vodacom mobile services',
      'EcoCash': 'Zimbabwe\'s leading mobile money',
      'HelloCash': 'Ethiopian mobile money service',
      'Amole': 'Ethiopian digital wallet',
      'CBE Birr': 'Commercial Bank of Ethiopia mobile money',
      'Lumicash': 'Burundi mobile money',
      'Dahabshiil': 'Somali money transfer service',
      'SomTel': 'Somalia telecom payment',
      'Vodafone Cash': 'Ghana Vodafone mobile money',
      'AirtelTigo Money': 'Ghana AirtelTigo mobile money',
      'Moov Money': 'West African mobile money',
      'Free Money': 'Senegal Free mobile money',
      'Wave': 'Senegal Wave money transfer',
      'Namibia Bank': 'Namibia banking services',
      'MTC': 'Namibia mobile services',
      'TN Mobile': 'Namibia TN Mobile',
      'TNM Mpamba': 'Malawi TNM mobile money',
      'Eswatini Mobile': 'Eswatini mobile services',
      'Comores Telecom': 'Comoros telecom payments',
      'Huri': 'Comoros payment service',
      'Seychelles Savings Bank': 'Seychelles banking',
      'Mauritius Commercial Bank': 'Mauritius banking',
      'CIH Bank': 'Morocco banking',
      'Attijariwafa Bank': 'Morocco banking',
      'BMCE': 'Morocco banking',
      'Djazicarte': 'Algeria payment card',
      'Carte Edahabia': 'Algeria payment card',
      'Poste Tunisienne': 'Tunisia postal bank',
      'Amen Bank': 'Tunisia banking',
      'BIAT': 'Tunisia banking',
      'Libyan Post': 'Libya postal bank',
      'Al Wahda Bank': 'Libya banking',
      'Bank of Khartoum': 'Sudan banking',
      'Zain Cash': 'Sudan Zain mobile money',
      'Express Union': 'Cameroon mobile money',
      'Zamtel Kwacha': 'Zambia Zamtel mobile money',
      'OneMoney': 'Zimbabwe mobile money',
      'Telecash': 'Zimbabwe mobile money',
      'BTC Mobile': 'Botswana mobile',
      'Mascom MyZaka': 'Botswana mobile money',
    };
    return descriptions[providerName] ?? 'Secure payment provider';
  }

  Widget _buildPaymentMethodForm() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // High-contrast label style
    final labelStyle = TextStyle(
      color: colors.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );

    // Hint style
    final hintStyle = TextStyle(
      color: colors.onSurface,
      fontSize: 13,
    );

    // Background color for fields
    final fieldBg = isDark ? colors.surfaceContainerHighest : colors.surface;

    if (_selectedPaymentMethod == PaymentMethod.mobileMoney.value) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mobile Money Details',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mobileNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number *',
                  labelStyle: labelStyle,
                  hintText: 'Enter mobile number',
                  hintStyle: hintStyle,
                  prefixText: '+',
                  prefixIcon:
                      Icon(Icons.phone_android, color: labelStyle.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: labelStyle.color!.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: labelStyle.color!.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: fieldBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: colors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Selected Provider: ${_selectedProviderName ?? 'None'}',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will receive a payment prompt on your phone to authorize the transaction.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_selectedPaymentMethod == PaymentMethod.creditCard.value) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Card Details',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              PaymentDetailsForm(
                controllers: _controllers,
                onCardNumberChanged: (value) {},
                onExpiryChanged: (value) {},
                onCvvChanged: (value) {},
              ),
            ],
          ),
        ),
      );
    } else if (_selectedPaymentMethod == PaymentMethod.bankTransfer.value) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Transfer Instructions',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: colors.secondary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance,
                            color: colors.secondary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Bank Account Details',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildBankDetailRow(
                        'Bank Name', 'Hosi Academy Bank', colors, textTheme),
                    _buildBankDetailRow(
                        'Account Name', 'Hosi Academy Ltd', colors, textTheme),
                    _buildBankDetailRow(
                        'Account Number', '1234567890', colors, textTheme),
                    _buildBankDetailRow(
                        'Branch Code', '123456', colors, textTheme),
                    _buildBankDetailRow(
                        'SWIFT/BIC', 'HOSIACCXXX', colors, textTheme),
                    _buildBankDetailRow('Reference',
                        'MC-${widget.masterclass.id}', colors, textTheme),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.errorContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: colors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please include the reference number in your transfer.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_selectedPaymentMethod == PaymentMethod.payPal.value) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.payment, color: colors.primary, size: 48),
                const SizedBox(height: 16),
                Text(
                  'PayPal Checkout',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You will be redirected to PayPal to complete your payment securely.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container();
  }

  Widget _buildBankDetailRow(
      String label, String value, ColorScheme colors, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: PaymentMethod.values.map((method) {
                final isSelected = _selectedPaymentMethod == method.value;
                final isAvailable = _isPaymentMethodAvailable(method);

                return GestureDetector(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            _selectedPaymentMethod = method.value;
                          });
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue[50]!
                          : (isAvailable
                              ? Colors.grey[50]!
                              : Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : (isAvailable
                                ? Colors.grey[300]!
                                : Colors.grey[400]!),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPaymentMethodIcon(method),
                          color: isSelected
                              ? Colors.blue
                              : (isAvailable ? Colors.grey : Colors.grey[400]),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          method.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.blue
                                : (isAvailable
                                    ? Colors.grey[800]
                                    : Colors.grey[400]),
                          ),
                        ),
                        if (!isAvailable) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.info,
                              size: 14, color: Colors.orange),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (!_isPaymentMethodAvailable(
                PaymentMethod.fromValue(_selectedPaymentMethod!)))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'This payment method is not available for ${_getCountryName()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700]!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isPaymentMethodAvailable(PaymentMethod method) {
    final countryCode = widget.masterclass.countryCode ?? 'KE';

    // Check if provider supports this method
    if (_selectedProviderName != null) {
      if (_selectedProviderName!.contains('M-Pesa') ||
          _selectedProviderName!.contains('MoMo') ||
          _selectedProviderName!.contains('Money')) {
        return method == PaymentMethod.mobileMoney;
      } else if (_selectedProviderName == 'Bank Transfer') {
        return method == PaymentMethod.bankTransfer;
      }
    }

    // Default availability
    if (method == PaymentMethod.mobileMoney) {
      return countryPaymentProviders[countryCode]?.any((provider) =>
              provider.contains('M-Pesa') ||
              provider.contains('MoMo') ||
              provider.contains('Money')) ??
          false;
    }

    return true;
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.payPal:
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  Widget _buildMasterclassInfo() {
    final mc = widget.masterclass;
    final isProfessional = mc.streamType == 'professional';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isProfessional ? Colors.green[50]! : Colors.red[50]!,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isProfessional ? 'Professional' : 'Technical',
                    style: TextStyle(
                      color: isProfessional
                          ? Colors.green[800]!
                          : Colors.red[800]!,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  CurrencyService.instance.formatPrice(mc.priceUsd ?? 0),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              mc.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (mc.focusArea != null) ...[
              const SizedBox(height: 8),
              Text(
                mc.focusArea!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoItem(
                  Icons.calendar_today,
                  '${_formatDate(mc.startDate)} - ${_formatDate(mc.endDate)}',
                ),
                if (mc.city != null || mc.country != null)
                  _buildInfoItem(
                    Icons.location_on,
                    '${mc.city ?? ''}${mc.city != null && mc.country != null ? ', ' : ''}${mc.country ?? ''}',
                  ),
                if (mc.venue != null)
                  _buildInfoItem(
                    Icons.place,
                    mc.venue!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          // Handle payment success
          setState(() {
            _isProcessing = false;
          });
          _showSuccessDialog();
        } else if (state is PaymentFailed) {
          // Handle payment failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      },
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 480 ? 8 : 16,
          vertical: MediaQuery.of(context).size.width < 480 ? 0 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 480 ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with country flag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enrollment Details',
                            style: TextStyle(
                              fontSize: (MediaQuery.of(context).size.width * 0.055).clamp(16.0, 24.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Location: ${_getCountryName()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Masterclass Information
                  _buildMasterclassInfo(),

                  // Quantity Selector
                  _buildQuantitySelector(),

                  // Enrollment Type
                  _buildEnrollmentTypeSelector(),

                  // Details Form
                  _buildDetailsForm(),

                  // Payment Provider Selector
                  _buildPaymentProviderSelector(),

                  // Payment Method Selector
                  _buildPaymentMethodSelector(),

                  // Payment Form based on method
                  _buildPaymentMethodForm(),

                  // Total and CTA
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${CurrencyService.instance.formatPrice(_totalAmount, currencyCode: 'USD')} USD',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_quantity} participant${_quantity > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed:
                                _isProcessing ? null : _processEnrollment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    children: [
                                      Icon(Icons.lock, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Secure Payment',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Security note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50]!,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your payment is secured with ${_selectedProviderName ?? 'our payment partner'}. All transactions are encrypted.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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
        ),
      ),
    );
  }
}
