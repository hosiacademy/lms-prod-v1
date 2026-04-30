// lib/src/presentation/widgets/enrollment/enrollment_form_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../../../core/api/api_client.dart';
import '../student_portal/cascading_location_dropdowns.dart';
import '../../../data/models/location.dart' as location_models;
import '../../../core/services/currency_service.dart';

class EnrollmentFormWidget extends StatefulWidget {
  final String
      enrollmentType; // 'learnership', 'industry_training', 'masterclass'
  final int trainingId;
  final String trainingTitle;
  final double enrollmentFee;
  final String currency;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback? onCancel;
  final bool isCompanyEnrollment;
  final int? companyId;
  final Map<String, dynamic>? companyLocation; // Company location data for auto-fill

  const EnrollmentFormWidget({
    super.key,
    required this.enrollmentType,
    required this.trainingId,
    required this.trainingTitle,
    required this.enrollmentFee,
    required this.currency,
    required this.onSubmit,
    this.onCancel,
    this.isCompanyEnrollment = false,
    this.companyId,
    this.companyLocation,
  });

  @override
  State<EnrollmentFormWidget> createState() => _EnrollmentFormWidgetState();
}

class _EnrollmentFormWidgetState extends State<EnrollmentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  // Optional
  final TextEditingController _dietaryRequirementsController =
      TextEditingController();
  final TextEditingController _accessibilityNeedsController =
      TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();

  // Company fields
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _managerEmailController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  // Dropdown selections
  String? _selectedGender;
  int? _selectedCountryId;
  int? _selectedStateId;
  int? _selectedCityId;
  String _phoneIsoCode = 'ZA';
  String _emergencyPhoneIsoCode = 'ZA';
  String? _selectedPhoneCode;

  String? _selectedEducationLevel;
  String? _selectedEmergencyRelationship;

  // Data
  // _countries and _cities are handled by CascadingLocationDropdowns
  bool _termsAccepted = false;

  DateTime? _selectedDob;
  
  // Track if company location has been applied
  bool _companyLocationApplied = false;
  // Tracks the logged-in user's own email so we skip the "already registered" check
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    // Countries loaded by CascadingLocationDropdowns

    // Auto-fill location from company if provided
    if (widget.isCompanyEnrollment &&
        widget.companyLocation != null &&
        !_companyLocationApplied) {
      _applyCompanyLocation();
    }

    // Pre-fill personal details from the student's existing profile
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    try {
      final p = await ApiClient.getStudentProfile();
      if (!mounted) return;
      setState(() {
        final fullName = (p['user_full_name'] as String? ?? '').trim();
        final email = (p['user_email'] as String? ?? '').trim();

        if (fullName.isNotEmpty) _fullNameController.text = fullName;
        if (email.isNotEmpty) {
          _emailController.text = email;
          _currentUserEmail = email;
        }
        _fillString(_phoneController, p['phone']);
        _fillString(_idNumberController, p['id_number']);
        _fillString(_dobController, p['date_of_birth']);
        _fillString(_addressController, p['address']);
        _fillString(_postalCodeController, p['postal_code']);
        _fillString(_occupationController, p['job_title'] ?? p['employer']);
        _fillString(_institutionController, p['qualification_institution']);
        _fillString(_emergencyNameController, p['emergency_contact_name']);
        _fillString(_emergencyPhoneController, p['emergency_contact_phone']);
        if ((p['gender'] as String? ?? '').isNotEmpty) _selectedGender = p['gender'] as String;
        if ((p['highest_qualification'] as String? ?? '').isNotEmpty)
          _selectedEducationLevel = p['highest_qualification'] as String;

        // Location — only if company location hasn't overridden it
        if (!_companyLocationApplied) {
          final countryId = p['country'] as int? ?? p['preferred_country'] as int?;
          final stateId = p['state'] as int? ?? p['preferred_state'] as int?;
          final cityId = p['city'] as int? ?? p['preferred_city'] as int?;
          if (countryId != null) _selectedCountryId = countryId;
          if (stateId != null) _selectedStateId = stateId;
          if (cityId != null) _selectedCityId = cityId;
        }
      });
    } catch (e) {
      // Not logged in or profile unavailable — leave form blank
      debugPrint('Profile pre-fill skipped: $e');
    }
  }

  void _fillString(TextEditingController ctrl, dynamic value) {
    final s = (value as String? ?? '').trim();
    if (s.isNotEmpty) ctrl.text = s;
  }
  
  void _applyCompanyLocation() {
    final companyLoc = widget.companyLocation;
    if (companyLoc == null) return;
    
    setState(() {
      // Apply country, state, city from company location
      final countryId = companyLoc['country_id'] as int?;
      final stateId = companyLoc['state_id'] as int?;
      final cityId = companyLoc['city_id'] as int?;
      final countryCode = companyLoc['country_code'] as String?;
      
      if (countryId != null) {
        _selectedCountryId = countryId;
      }
      if (stateId != null) {
        _selectedStateId = stateId;
      }
      if (cityId != null) {
        _selectedCityId = cityId;
      }
      
      // Update phone ISO code based on company's country
      if (countryCode != null && countryCode.isNotEmpty) {
        _phoneIsoCode = countryCode;
        _emergencyPhoneIsoCode = countryCode;
      }
      
      _companyLocationApplied = true;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _occupationController.dispose();
    _institutionController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _dietaryRequirementsController.dispose();
    _accessibilityNeedsController.dispose();
    _additionalNotesController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _managerNameController.dispose();
    _managerEmailController.dispose();
    super.dispose();
  }

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
      labelStyle:
          TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      helperStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final contentPad = (sw * 0.05).clamp(16.0, 24.0);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(contentPad),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: colorScheme.primary, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enrollment Form',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: (sw * 0.05).clamp(18.0, 24.0),
                              ),
                            ),
                            Text(
                              widget.trainingTitle,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.primary,
                                fontSize: (sw * 0.035).clamp(13.0, 16.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: colorScheme.onPrimaryContainer, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please fill in all required fields marked with *',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: (sw * 0.03).clamp(11.0, 13.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: _onStepContinue,
                  onStepCancel: _onStepCancel,
                  controlsBuilder: _buildStepperControls,
                  steps: _buildSteps(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Step> _buildSteps() {
    final steps = <Step>[
      Step(
        title: const Text('Personal Information'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: _buildPersonalInfoStep(),
      ),
      Step(
        title: const Text('Contact & Address'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: _buildContactAddressStep(),
      ),
    ];

    if (widget.isCompanyEnrollment) {
      steps.add(
        Step(
          title: const Text('Company Information'),
          subtitle: const Text('Required for company enrollments'),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          content: _buildCompanyInfoStep(),
        ),
      );
    }

    final profStepIndex = widget.isCompanyEnrollment ? 3 : 2;
    final emergStepIndex = widget.isCompanyEnrollment ? 4 : 3;
    final addStepIndex = widget.isCompanyEnrollment ? 5 : 4;

    steps.addAll([
      Step(
        title: const Text('Professional Background'),
        isActive: _currentStep >= profStepIndex,
        state: _currentStep > profStepIndex
            ? StepState.complete
            : StepState.indexed,
        content: _buildProfessionalStep(),
      ),
      Step(
        title: const Text('Emergency Contact'),
        isActive: _currentStep >= emergStepIndex,
        state: _currentStep > emergStepIndex
            ? StepState.complete
            : StepState.indexed,
        content: _buildEmergencyContactStep(),
      ),
      Step(
        title: const Text('Additional Information'),
        isActive: _currentStep >= addStepIndex,
        state: _currentStep > addStepIndex
            ? StepState.complete
            : StepState.indexed,
        content: _buildAdditionalInfoStep(),
      ),
    ]);

    return steps;
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Full Name *',
            hintText: 'John Doe',
            prefixIcon: Icons.person,
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your full name';
            if (value.length < 2) return 'Name must be at least 2 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Email Address *',
            hintText: 'john.doe@example.com',
            prefixIcon: Icons.email,
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your email';
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value))
              return 'Please enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: 16),
        InternationalPhoneNumberInput(
          key: ValueKey('personal_phone_$_phoneIsoCode'),
          onInputChanged: (PhoneNumber number) {
            _phoneIsoCode = number.isoCode ?? _phoneIsoCode;
            _selectedPhoneCode = number.dialCode;
          },
          onInputValidated: (bool isValid) {
            // Updated by autoValidateMode
          },
          selectorConfig: const SelectorConfig(
            selectorType: PhoneInputSelectorType.DROPDOWN,
            showFlags: true,
            setSelectorButtonAsPrefixIcon: true,
          ),
          ignoreBlank: false,
          autoValidateMode: AutovalidateMode.onUserInteraction,
          initialValue: PhoneNumber(isoCode: _phoneIsoCode),
          textFieldController: _phoneController,
          formatInput: true,
          keyboardType: TextInputType.phone,
          inputDecoration: _buildInputDecoration(
            context: context,
            labelText: 'Phone Number *',
            hintText: 'Enter phone number',
            prefixIcon: Icons.phone,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _idNumberController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'ID/Passport Number *',
            hintText: 'Enter your ID or passport number',
            prefixIcon: Icons.badge,
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your ID or passport number';
            if (value.length < 5)
              return 'ID/Passport must be at least 5 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Date of Birth *',
            hintText: 'Select your date of birth',
            prefixIcon: Icons.calendar_today,
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate:
                  DateTime.now().subtract(const Duration(days: 365 * 18)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedDob = picked;
                _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please select your date of birth';
            if (_selectedDob != null) {
              final age =
                  DateTime.now().difference(_selectedDob!).inDays ~/ 365;
              if (age < 16)
                return 'You must be at least 16 years old to enroll';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedGender),
          value: (_selectedGender ?? '').isEmpty ? null : _selectedGender,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Gender *',
            prefixIcon: Icons.people,
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
            DropdownMenuItem(
                value: 'prefer_not_to_say', child: Text('Prefer not to say')),
          ],
          onChanged: (value) => setState(() => _selectedGender = value),
          validator: (value) =>
              value == null ? 'Please select your gender' : null,
        ),
      ],
    );
  }

  Widget _buildContactAddressStep() {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Street Address *',
            hintText: '123 Main Street, Apartment 4B',
            prefixIcon: Icons.home,
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your address';
            return null;
          },
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        CascadingLocationDropdowns(
          isRequired: true,
          countryLabel: 'Country *',
          cityLabel: 'City *',
          initialCountry: _selectedCountryId != null
              ? location_models.Country(
                  id: _selectedCountryId!, name: '', code: '')
              : null,
          initialState: _selectedStateId != null
              ? location_models.State(
                  id: _selectedStateId!,
                  name: '',
                  countryId: _selectedCountryId!)
              : null,
          initialCity: _selectedCityId != null
              ? location_models.City(
                  id: _selectedCityId!, name: '', stateId: _selectedStateId!)
              : null,
          onLocationChanged: (location_models.Country? country,
              location_models.State? state, location_models.City? city) {
            setState(() {
              _selectedCountryId = country?.id;
              _selectedStateId = state?.id;
              _selectedCityId = city?.id;
              if (country != null) {
                _phoneIsoCode = country.code;
                _emergencyPhoneIsoCode = country.code;
              }
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _postalCodeController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Postal Code *',
            hintText: '2000',
            prefixIcon: Icons.markunread_mailbox,
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your postal code';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCompanyInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.business, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please provide your company-related information. This helps us tailor the training experience.',
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: _employeeIdController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Employee ID *',
            hintText: 'EMP001234',
            prefixIcon: Icons.badge,
            helperText: 'Your unique employee identification number',
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your employee ID' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _departmentController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Department *',
            hintText: 'Engineering, HR, Sales, etc.',
            prefixIcon: Icons.apartment,
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your department' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _positionController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Position/Job Title *',
            hintText: 'Software Developer, Manager, etc.',
            prefixIcon: Icons.work,
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your position' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _managerNameController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Manager Name *',
            hintText: 'Direct manager or supervisor name',
            prefixIcon: Icons.person_outline,
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your manager name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _managerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Manager Email *',
            hintText: 'manager@company.com',
            prefixIcon: Icons.email_outlined,
            helperText: 'Progress reports will be sent to this email',
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your manager email';
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value))
              return 'Please enter a valid email address';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfessionalStep() {
    return Column(
      children: [
        TextFormField(
          controller: _occupationController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Current Occupation *',
            hintText: 'Software Developer',
            prefixIcon: Icons.work,
          ),
          validator: (value) => value?.isEmpty ?? true
              ? 'Please enter your current occupation'
              : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedEducationLevel),
          value: (_selectedEducationLevel ?? '').isEmpty ? null : _selectedEducationLevel,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Education Level *',
            prefixIcon: Icons.school,
          ),
          items: const [
            DropdownMenuItem(value: 'high_school', child: Text('High School')),
            DropdownMenuItem(value: 'diploma', child: Text('Diploma')),
            DropdownMenuItem(
                value: 'bachelors', child: Text("Bachelor's Degree")),
            DropdownMenuItem(value: 'masters', child: Text("Master's Degree")),
            DropdownMenuItem(value: 'doctorate', child: Text('Doctorate')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) => setState(() => _selectedEducationLevel = value),
          validator: (value) =>
              value == null ? 'Please select your education level' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _institutionController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Institution/Company *',
            hintText: 'University of Johannesburg',
            prefixIcon: Icons.business,
          ),
          validator: (value) => value?.isEmpty ?? true
              ? 'Please enter your institution or company'
              : null,
        ),
      ],
    );
  }

  Widget _buildEmergencyContactStep() {
    return Column(
      children: [
        TextFormField(
          controller: _emergencyNameController,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Emergency Contact Name *',
            hintText: 'Jane Doe',
            prefixIcon: Icons.person_outline,
          ),
          validator: (value) => value?.isEmpty ?? true
              ? 'Please enter emergency contact name'
              : null,
        ),
        const SizedBox(height: 16),
        InternationalPhoneNumberInput(
          key: ValueKey('emergency_phone_$_emergencyPhoneIsoCode'),
          onInputChanged: (PhoneNumber number) {
            _emergencyPhoneIsoCode = number.isoCode ?? _emergencyPhoneIsoCode;
          },
          selectorConfig: const SelectorConfig(
            selectorType: PhoneInputSelectorType.DROPDOWN,
            showFlags: true,
            setSelectorButtonAsPrefixIcon: true,
          ),
          ignoreBlank: false,
          autoValidateMode: AutovalidateMode.onUserInteraction,
          initialValue: PhoneNumber(isoCode: _emergencyPhoneIsoCode),
          textFieldController: _emergencyPhoneController,
          formatInput: true,
          keyboardType: TextInputType.phone,
          inputDecoration: _buildInputDecoration(
            context: context,
            labelText: 'Emergency Contact Phone *',
            hintText: 'Enter phone number',
            prefixIcon: Icons.phone_in_talk,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedEmergencyRelationship),
          value: (_selectedEmergencyRelationship ?? '').isEmpty ? null : _selectedEmergencyRelationship,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Relationship *',
            prefixIcon: Icons.group,
          ),
          items: const [
            DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
            DropdownMenuItem(value: 'parent', child: Text('Parent')),
            DropdownMenuItem(value: 'sibling', child: Text('Sibling')),
            DropdownMenuItem(value: 'child', child: Text('Child')),
            DropdownMenuItem(value: 'friend', child: Text('Friend')),
            DropdownMenuItem(value: 'colleague', child: Text('Colleague')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) =>
              setState(() => _selectedEmergencyRelationship = value),
          validator: (value) =>
              value == null ? 'Please select the relationship' : null,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoStep() {
    return Column(
      children: [
        TextFormField(
          controller: _dietaryRequirementsController,
          maxLines: 2,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Dietary Requirements (Optional)',
            hintText: 'Vegetarian, Halal, Allergies, etc.',
            prefixIcon: Icons.restaurant,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _accessibilityNeedsController,
          maxLines: 2,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Accessibility Needs (Optional)',
            hintText: 'Wheelchair access, Sign language interpreter, etc.',
            prefixIcon: Icons.accessible,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _additionalNotesController,
          maxLines: 3,
          decoration: _buildInputDecoration(
            context: context,
            labelText: 'Additional Notes (Optional)',
            hintText: 'Any other information you would like to share',
            prefixIcon: Icons.notes,
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: _termsAccepted,
          onChanged: (value) => setState(() => _termsAccepted = value ?? false),
          title: const Text('I accept the terms and conditions *'),
          subtitle: const Text(
              'By checking this box, you agree to our terms of service and privacy policy'),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enrollment Fee:',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                CurrencyService.instance.formatUSDAmount(widget.enrollmentFee),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepperControls(BuildContext context, ControlsDetails details) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalSteps = widget.isCompanyEnrollment ? 6 : 5;
    final isLastStep = _currentStep == (totalSteps - 1);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: details.onStepCancel,
              child: const Text('Back'),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isSubmitting ? null : details.onStepContinue,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isLastStep ? 'Proceed to Payment' : 'Continue'),
            ),
          ),
          const SizedBox(width: 12),
          if (_currentStep == 0 && widget.onCancel != null)
            OutlinedButton(
              onPressed: widget.onCancel,
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }

  void _onStepContinue() async {
    final totalSteps = widget.isCompanyEnrollment ? 6 : 5;
    if (_currentStep < (totalSteps - 1)) {
      if (_validateCurrentStep()) {
        // Special validation for step 0 (Personal Information)
        if (_currentStep == 0) {
          setState(() => _isSubmitting = true);
          try {
            final email = _emailController.text.trim().toLowerCase();
            // Skip the check if this is the logged-in user's own pre-filled email
            final isOwnEmail = _currentUserEmail != null &&
                email == _currentUserEmail!.toLowerCase();
            if (!isOwnEmail) {
              final exists = await ApiClient.checkEmailExists(email);
              if (exists) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'This email is already registered. Please sign in or use a different email.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                setState(() => _isSubmitting = false);
                return;
              }
            }
          } catch (e) {
            debugPrint('Error checking email: $e');
            // If check fails, we might want to let them proceed anyway or show error
          } finally {
            if (mounted) setState(() => _isSubmitting = false);
          }
        }

        setState(() => _currentStep += 1);
      }
    } else {
      _submitForm();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  bool _validateCurrentStep() {
    final companyStepIndex = 2;
    final professionalStepIndex = widget.isCompanyEnrollment ? 3 : 2;
    final emergencyStepIndex = widget.isCompanyEnrollment ? 4 : 3;
    final additionalStepIndex = widget.isCompanyEnrollment ? 5 : 4;

    switch (_currentStep) {
      case 0:
        return _fullNameController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty &&
            _idNumberController.text.isNotEmpty &&
            _dobController.text.isNotEmpty &&
            _selectedGender != null;
      case 1:
        return _addressController.text.isNotEmpty &&
            _selectedCityId != null &&
            _selectedStateId != null &&
            _selectedCountryId != null &&
            _postalCodeController.text.isNotEmpty;
      default:
        if (widget.isCompanyEnrollment && _currentStep == companyStepIndex) {
          return _employeeIdController.text.isNotEmpty &&
              _departmentController.text.isNotEmpty &&
              _positionController.text.isNotEmpty &&
              _managerNameController.text.isNotEmpty &&
              _managerEmailController.text.isNotEmpty;
        } else if (_currentStep == professionalStepIndex) {
          return _occupationController.text.isNotEmpty &&
              _selectedEducationLevel != null &&
              _institutionController.text.isNotEmpty;
        } else if (_currentStep == emergencyStepIndex) {
          return _emergencyNameController.text.isNotEmpty &&
              _emergencyPhoneController.text.isNotEmpty &&
              _selectedEmergencyRelationship != null;
        } else if (_currentStep == additionalStepIndex) {
          return _termsAccepted;
        }
        return true;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final enrollmentData = {
        'training_id': widget.trainingId,
        'enrollment_type': widget.enrollmentType,
        'learner_full_name': _fullNameController.text.trim(),
        'learner_email': _emailController.text.trim().toLowerCase(),
        'learner_phone': (_selectedPhoneCode != null &&
                !_phoneController.text.trim().startsWith('+'))
            ? '$_selectedPhoneCode${_phoneController.text.trim()}'
            : _phoneController.text.trim(),
        'phone_code': _selectedPhoneCode,
        'learner_id_number': _idNumberController.text.trim(),
        'learner_dob': _dobController.text,
        'learner_gender': _selectedGender,
        'learner_address': _addressController.text.trim(),
        'selected_city': _selectedCityId,
        'selected_state': _selectedStateId,
        'selected_country': _selectedCountryId,
        'learner_postal_code': _postalCodeController.text.trim(),
        'current_occupation': _occupationController.text.trim(),
        'education_level': _selectedEducationLevel,
        'institution': _institutionController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': (_selectedPhoneCode != null &&
                !_emergencyPhoneController.text.trim().startsWith('+'))
            ? '$_selectedPhoneCode${_emergencyPhoneController.text.trim()}'
            : _emergencyPhoneController.text.trim(),
        'emergency_contact_relationship': _selectedEmergencyRelationship,
        if (_dietaryRequirementsController.text.isNotEmpty)
          'dietary_requirements': _dietaryRequirementsController.text.trim(),
        if (_accessibilityNeedsController.text.isNotEmpty)
          'accessibility_needs': _accessibilityNeedsController.text.trim(),
        if (_additionalNotesController.text.isNotEmpty)
          'additional_notes': _additionalNotesController.text.trim(),
        if (widget.isCompanyEnrollment) ...{
          'company_id': widget.companyId,
          'employee_id': _employeeIdController.text.trim(),
          'department': _departmentController.text.trim(),
          'position': _positionController.text.trim(),
          'manager_name': _managerNameController.text.trim(),
          'manager_email': _managerEmailController.text.trim().toLowerCase(),
        },
        'enrollment_fee': widget.enrollmentFee,
        'currency': widget.currency,
        'terms_accepted': _termsAccepted,
        'terms_accepted_at': DateTime.now().toIso8601String(),
      };

      widget.onSubmit(enrollmentData);
      setState(() => _isSubmitting = false);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
