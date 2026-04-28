// lib/src/presentation/widgets/enrollment/company_enrollment_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../blocs/student_portal/location_bloc.dart';
import '../student_portal/cascading_location_dropdowns.dart';
import '../../../data/models/location.dart' as location_models;

/// Company Enrollment Form Widget
/// Collects company-specific information for bulk learnership enrollment
class CompanyEnrollmentForm extends StatefulWidget {
  final int programmeId;
  final String programmeTitle;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback? onCancel;

  const CompanyEnrollmentForm({
    Key? key,
    required this.programmeId,
    required this.programmeTitle,
    required this.onSubmit,
    this.onCancel,
  }) : super(key: key);

  @override
  State<CompanyEnrollmentForm> createState() => _CompanyEnrollmentFormState();
}

class _CompanyEnrollmentFormState extends State<CompanyEnrollmentForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Controllers for company fields
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyRegistrationController =
      TextEditingController();
  final TextEditingController _companyTaxNumberController =
      TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _companyPostalCodeController =
      TextEditingController();
  final TextEditingController _billingContactNameController =
      TextEditingController();
  final TextEditingController _billingContactEmailController =
      TextEditingController();
  final TextEditingController _billingContactPhoneController =
      TextEditingController();
  final TextEditingController _numberOfLearnersController =
      TextEditingController();

  String? _selectedPaymentTerms = 'immediate';

  // Dropdown values (using models now)
  location_models.Country? _selectedCountry;
  location_models.State? _selectedState;
  location_models.City? _selectedCity;
  String _companyPhoneIsoCode = 'ZA';
  String _billingContactPhoneIsoCode = 'ZA';
  String? _selectedPhoneCode;

  // Bulk learner details
  List<Map<String, TextEditingController>> _learnerControllers = [];
  bool _showLearnerDetailsSection = false;

  @override
  void initState() {
    super.initState();
    // No need to load manually here, CascadingLocationDropdowns handles it via LocationBloc

    // Listen to number of learners changes
    _numberOfLearnersController.addListener(_onNumberOfLearnersChanged);
  }

  void _onNumberOfLearnersChanged() {
    final numberOfLearners =
        int.tryParse(_numberOfLearnersController.text) ?? 0;
    if (numberOfLearners > 0 &&
        numberOfLearners != _learnerControllers.length) {
      _generateLearnerControllers(numberOfLearners);
    }
  }

  void _generateLearnerControllers(int count) {
    // Clean up old controllers
    for (var controllers in _learnerControllers) {
      controllers['name']?.dispose();
      controllers['email']?.dispose();
      controllers['phone']?.dispose();
    }

    // Generate new controllers
    setState(() {
      _learnerControllers = List.generate(count, (index) {
        return {
          'name': TextEditingController(),
          'email': TextEditingController(),
          'phone': TextEditingController(),
        };
      });
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyRegistrationController.dispose();
    _companyTaxNumberController.dispose();
    _contactPersonController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _companyPostalCodeController.dispose();
    _billingContactNameController.dispose();
    _billingContactEmailController.dispose();
    _billingContactPhoneController.dispose();
    _numberOfLearnersController.dispose();

    // Dispose learner controllers
    for (var controllers in _learnerControllers) {
      controllers['name']?.dispose();
      controllers['email']?.dispose();
      controllers['phone']?.dispose();
    }

    super.dispose();
  }

  void _onLocationChanged(location_models.Country? country,
      location_models.State? state, location_models.City? city) {
    setState(() {
      _selectedCountry = country;
      _selectedState = state;
      _selectedCity = city;

      // Update phone code if country changed
      if (country != null) {
        _companyPhoneIsoCode = country.code;
        _billingContactPhoneIsoCode = country.code;
        _updatePhoneControllersWithNewCode(_companyPhoneIsoCode);
      }
    });
  }

  void _updatePhoneControllersWithNewCode(String? newCode) {
    // Re-rendering via setState handles the ISO code update for InternationalPhoneNumberInput
    setState(() {});
  }

  // Helper method to create themed InputDecoration
  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    String? helperText,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: colorScheme.primary)
          : null,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      helperStyle:
          TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline)),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 2)),
      errorBorder:
          OutlineInputBorder(borderSide: BorderSide(color: colorScheme.error)),
      filled: true,
      fillColor: colorScheme.surface,
    );
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required String title,
    required IconData icon,
  }) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(theme, colors),
              const SizedBox(height: 24),

              // Form Fields
              Text(
                'Company Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 16),

              _buildCompanyNameField(),
              const SizedBox(height: 16),

              _buildCompanyRegistrationField(),
              const SizedBox(height: 16),

              _buildCompanyTaxNumberField(),
              const SizedBox(height: 16),

              _buildContactPersonField(),
              const SizedBox(height: 16),

              _buildCompanyEmailField(),
              const SizedBox(height: 16),

              _buildCompanyPhoneField(),
              const SizedBox(height: 16),

              _buildCompanyAddressField(),
              const SizedBox(height: 16),

              _buildLocationSection(theme, colors),
              const SizedBox(height: 16),

              _buildCompanyPostalCodeField(),
              const SizedBox(height: 24),

              Text(
                'Billing Contact Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Person responsible for invoice processing and payments',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              _buildBillingContactNameField(),
              const SizedBox(height: 16),

              _buildBillingContactEmailField(),
              const SizedBox(height: 16),

              _buildBillingContactPhoneField(),
              const SizedBox(height: 16),

              _buildPaymentTermsDropdown(),
              const SizedBox(height: 24),

              Text(
                'Enrollment Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 16),

              _buildNumberOfLearnersField(),
              const SizedBox(height: 24),

              // Info Box
              _buildInfoBox(colors),
              const SizedBox(height: 24),

              // Student Details Section (Bulk Enrollment)
              if (_learnerControllers.isNotEmpty)
                _buildLearnerDetailsSection(theme, colors),

              // Action Buttons
              _buildActionButtons(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.business, color: colors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Enrollment',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.programmeTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: colors.onPrimaryContainer, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Register your company to enroll multiple employees for this learnership programme',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyNameField() {
    return TextFormField(
      controller: _companyNameController,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Company Name *',
        hintText: 'Enter your company name',
        prefixIcon: Icons.business_center,
        helperText: 'Official registered company name',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Company name is required';
        }
        if (value.length < 2) {
          return 'Company name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyRegistrationField() {
    return TextFormField(
      controller: _companyRegistrationController,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Company Registration Number *',
        hintText: 'Enter registration number',
        prefixIcon: Icons.numbers,
        helperText: 'Official company registration number',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Company registration number is required';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyTaxNumberField() {
    return TextFormField(
      controller: _companyTaxNumberController,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Tax/VAT Number *',
        hintText: 'Enter tax or VAT number',
        prefixIcon: Icons.receipt_long,
        helperText: 'Required for invoice and tax purposes',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tax/VAT number is required for invoicing';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyAddressField() {
    return TextFormField(
      controller: _companyAddressController,
      maxLines: 2,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Company Address *',
        hintText: 'Enter full street address',
        prefixIcon: Icons.location_on,
        helperText: 'Physical address for invoicing',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Company address is required for invoicing';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyPostalCodeField() {
    return TextFormField(
      controller: _companyPostalCodeController,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Postal Code *',
        hintText: 'Enter postal/ZIP code',
        prefixIcon: Icons.markunread_mailbox,
        helperText: 'Required for invoice delivery',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Postal code is required';
        }
        return null;
      },
    );
  }

  Widget _buildBillingContactNameField() {
    return TextFormField(
      controller: _billingContactNameController,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Billing Contact Name *',
        hintText: 'Enter billing contact full name',
        prefixIcon: Icons.person_outline,
        helperText: 'Person handling invoices and payments',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Billing contact name is required';
        }
        return null;
      },
    );
  }

  Widget _buildBillingContactEmailField() {
    return TextFormField(
      controller: _billingContactEmailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Billing Contact Email *',
        hintText: 'billing@company.com',
        prefixIcon: Icons.email_outlined,
        helperText: 'Email for invoice delivery',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Billing contact email is required';
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildBillingContactPhoneField() {
    return InternationalPhoneNumberInput(
      key: ValueKey('billing_phone_$_billingContactPhoneIsoCode'),
      onInputChanged: (PhoneNumber number) {
        _billingContactPhoneIsoCode =
            number.isoCode ?? _billingContactPhoneIsoCode;
      },
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.DROPDOWN,
        showFlags: true,
        setSelectorButtonAsPrefixIcon: true,
      ),
      ignoreBlank: false,
      autoValidateMode: AutovalidateMode.onUserInteraction,
      initialValue: PhoneNumber(isoCode: _billingContactPhoneIsoCode),
      textFieldController: _billingContactPhoneController,
      formatInput: true,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      inputDecoration: _buildInputDecoration(
        context: context,
        labelText: 'Billing Contact Phone *',
        hintText: 'Enter phone number',
        prefixIcon: Icons.phone_outlined,
        helperText: 'Phone for invoice queries',
      ),
    );
  }

  Widget _buildPaymentTermsDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedPaymentTerms),
      value: (_selectedPaymentTerms ?? '').isEmpty ? null : _selectedPaymentTerms,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Payment Terms',
        prefixIcon: Icons.payment,
        helperText: 'When payment will be processed',
      ),
      items: const [
        DropdownMenuItem(value: 'immediate', child: Text('Immediate Payment')),
        DropdownMenuItem(value: 'net7', child: Text('Net 7 Days')),
        DropdownMenuItem(value: 'net15', child: Text('Net 15 Days')),
        DropdownMenuItem(value: 'net30', child: Text('Net 30 Days')),
        DropdownMenuItem(value: 'net60', child: Text('Net 60 Days')),
      ],
      onChanged: (value) {
        setState(() => _selectedPaymentTerms = value);
      },
    );
  }

  Widget _buildContactPersonField() {
    return TextFormField(
      controller: _contactPersonController,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Contact Person Name *',
        hintText: 'Enter contact person full name',
        prefixIcon: Icons.person,
        helperText: 'Primary contact person for this enrollment',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Contact person name is required';
        }
        if (value.length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyEmailField() {
    return TextFormField(
      controller: _companyEmailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Company Email *',
        hintText: 'company@example.com',
        prefixIcon: Icons.email,
        helperText: 'Official company email for correspondence',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Company email is required';
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyPhoneField() {
    return InternationalPhoneNumberInput(
      key: ValueKey('company_phone_$_companyPhoneIsoCode'),
      onInputChanged: (PhoneNumber number) {
        _companyPhoneIsoCode = number.isoCode ?? _companyPhoneIsoCode;
      },
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.DROPDOWN,
        showFlags: true,
        setSelectorButtonAsPrefixIcon: true,
      ),
      ignoreBlank: false,
      autoValidateMode: AutovalidateMode.onUserInteraction,
      initialValue: PhoneNumber(isoCode: _companyPhoneIsoCode),
      textFieldController: _companyPhoneController,
      formatInput: true,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      inputDecoration: _buildInputDecoration(
        context: context,
        labelText: 'Company Phone Number *',
        hintText: 'Enter phone number',
        prefixIcon: Icons.phone,
        helperText: 'Include country code at the beginning',
      ),
    );
  }

  Widget _buildNumberOfLearnersField() {
    return TextFormField(
      controller: _numberOfLearnersController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _buildInputDecoration(
        context: context,
        labelText: 'Number of Learners *',
        hintText: 'Enter number of employees to enroll',
        prefixIcon: Icons.groups,
        helperText: 'How many employees will participate?',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Number of learners is required';
        }
        final number = int.tryParse(value);
        if (number == null || number < 1) {
          return 'Must be at least 1 learner';
        }
        if (number > 1000) {
          return 'Maximum 1000 learners per enrollment';
        }
        return null;
      },
    );
  }

  Widget _buildLocationSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            theme: theme, title: 'Company Location *', icon: Icons.map),
        const SizedBox(height: 16),
        BlocProvider(
          create: (context) => LocationBloc(),
          child: CascadingLocationDropdowns(
            isRequired: true,
            onLocationChanged: _onLocationChanged,
            initialCountry: _selectedCountry,
            initialState: _selectedState,
            initialCity: _selectedCity,
            countryLabel: 'Country',
            cityLabel: 'City',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(ColorScheme colors) {
    final numberOfLearners =
        int.tryParse(_numberOfLearnersController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'What happens next?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('1. Company pays upfront for all learners'),
          _buildInfoItem('2. Provisional enrollments are created immediately'),
          _buildInfoItem(
              '3. Email notifications sent to each learner with registration link'),
          _buildInfoItem(
              '4. Learners complete their personal details for validation'),
          _buildInfoItem(
              '5. Once validated, provisional enrollment migrates to full enrollment'),
          _buildInfoItem(
              '6. Refund available if enrollment doesn\'t migrate to full status'),
          if (numberOfLearners > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Learners:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$numberOfLearners',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnerDetailsSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Expand/Collapse
        InkWell(
          onTap: () {
            setState(() {
              _showLearnerDetailsSection = !_showLearnerDetailsSection;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.group_add,
                  color: colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learner Details (${_learnerControllers.length} Learners)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showLearnerDetailsSection
                            ? 'Click to collapse learner details'
                            : 'Click to provide individual learner information',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showLearnerDetailsSection
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ),

        // Student Forms
        if (_showLearnerDetailsSection) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colors.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Provide names and emails for each learner. Emails will be used to send enrollment links for them to complete their registration.',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Individual learner forms
                ..._learnerControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controllers = entry.value;
                  return _buildLearnerForm(
                    index,
                    controllers,
                    theme,
                    colors,
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildLearnerForm(
    int index,
    Map<String, TextEditingController> controllers,
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student number header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Learner ${index + 1}',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name field
          TextFormField(
            controller: controllers['name'],
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'Enter learner full name',
              prefixIcon: Icon(Icons.person_outline, color: colors.primary),
              labelStyle: TextStyle(color: colors.onSurface),
              hintStyle:
                  TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
              isDense: true,
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Email field
          TextFormField(
            controller: controllers['email'],
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              hintText: 'learner@example.com',
              prefixIcon: Icon(Icons.email_outlined, color: colors.primary),
              labelStyle: TextStyle(color: colors.onSurface),
              hintStyle:
                  TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
              isDense: true,
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Phone field
          InternationalPhoneNumberInput(
            key: ValueKey('learner_${index}_phone_$_companyPhoneIsoCode'),
            onInputChanged: (PhoneNumber number) {
              controllers['phone']?.text = number.phoneNumber ?? '';
            },
            selectorConfig: const SelectorConfig(
              selectorType: PhoneInputSelectorType.DROPDOWN,
              showFlags: true,
              setSelectorButtonAsPrefixIcon: true,
            ),
            ignoreBlank: true,
            autoValidateMode: AutovalidateMode.onUserInteraction,
            initialValue: PhoneNumber(isoCode: _companyPhoneIsoCode),
            textFieldController: controllers['phone'],
            formatInput: true,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputDecoration: InputDecoration(
              labelText: 'Phone Number (Optional)',
              hintText: 'Enter phone number',
              prefixIcon: Icon(Icons.phone_outlined, color: colors.primary),
              labelStyle: TextStyle(color: colors.onSurface),
              hintStyle:
                  TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
              isDense: true,
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colors) {
    return Row(
      children: [
        if (widget.onCancel != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitForm,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(_isSubmitting ? 'Processing...' : 'Proceed to Payment'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Validate email existence
      final companyEmail = _companyEmailController.text.trim().toLowerCase();
      final companyEmailExists = await ApiClient.checkEmailExists(companyEmail);
      if (companyEmailExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Company email is already registered. Please sign in or use a different email.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      if (_learnerControllers.isNotEmpty && _showLearnerDetailsSection) {
        for (var i = 0; i < _learnerControllers.length; i++) {
          final name = _learnerControllers[i]['name']?.text.trim() ?? '';
          final email =
              _learnerControllers[i]['email']?.text.trim().toLowerCase() ?? '';

          if (name.isEmpty || email.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Please complete all learner details for Learner ${i + 1}'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isSubmitting = false);
            return;
          }

          final exists = await ApiClient.checkEmailExists(email);
          if (exists) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Learner ${i + 1} email "$email" is already registered.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            setState(() => _isSubmitting = false);
            return;
          }
        }
      }

      // Collect learner details
      final learnerDetails = _learnerControllers.map((controllers) {
        return {
          'name': controllers['name']?.text.trim() ?? '',
          'email': controllers['email']?.text.trim().toLowerCase() ?? '',
          'phone': controllers['phone']?.text.trim() ?? '',
        };
      }).toList();

      final int numberOfLearners =
          int.tryParse(_numberOfLearnersController.text) ?? 0;

      final formData = {
        'programme_id': widget.programmeId,
        'enrollment_type': 'company',
        'company_name': _companyNameController.text.trim(),
        'company_registration_number':
            _companyRegistrationController.text.trim(),
        'company_tax_number': _companyTaxNumberController.text.trim(),
        'company_contact_person': _contactPersonController.text.trim(),
        'company_email': _companyEmailController.text.trim().toLowerCase(),
        'company_phone': _companyPhoneController.text.trim(),
        'company_address': _companyAddressController.text.trim(),
        'company_postal_code': _companyPostalCodeController.text.trim(),
        // Location IDs for auto-fill
        'selected_country': _selectedCountry?.id,
        'selected_state': _selectedState?.id,
        'selected_city': _selectedCity?.id,
        // Country code for phone ISO
        'country_code': _selectedCountry?.code,
        'phone_code': _selectedPhoneCode,
        'billing_contact_name': _billingContactNameController.text.trim(),
        'billing_contact_email':
            _billingContactEmailController.text.trim().toLowerCase(),
        'billing_contact_phone': _billingContactPhoneController.text.trim(),
        'payment_terms': _selectedPaymentTerms,
        'number_of_learners': numberOfLearners,
        'learner_details': _learnerControllers
            .map((c) => {
                  'name': c['name']?.text.trim(),
                  'email': c['email']?.text.trim().toLowerCase(),
                  'phone': c['phone']?.text.trim(),
                })
            .toList(),
        'is_bulk_enrollment': learnerDetails.isNotEmpty,
        'payment_required': true, // Company must pay upfront
      };

      widget.onSubmit(formData);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
