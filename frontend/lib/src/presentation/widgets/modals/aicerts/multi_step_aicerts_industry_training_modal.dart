// lib/src/presentation/widgets/modals/aicerts/multi_step_aicerts_industry_training_modal.dart
// AICERTS Industry Training Pathway Enrollment Modal

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/course.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/constants/pricing_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/african_phone_validator.dart';
import '../../../pages/payment/payment_provider_selection_page.dart';
import '../../student_portal/cascading_location_dropdowns.dart';
import '../../../blocs/student_portal/location_bloc.dart';
import '../../../../data/models/location.dart' as location_models;
import '../../contact_otp_field.dart';
import '../../aicerts/aicerts_image_widget.dart';
import 'shared/aicerts_form_data.dart';

/// AICERTS Industry Training Enrollment Modal
/// For enrolling learners in industry-specific AICERTS courses
class MultiStepAICERTSIndustryTrainingModal extends StatefulWidget {
  final List<Course> courses; // Industry-specific AICERTS courses
  final String industry; // Industry name (e.g., 'finance', 'healthcare')
  final String? role; // Optional role (e.g., 'analyst', 'manager')
  final VoidCallback? onEnrollmentComplete;
  final bool allowPrefill; // NEW: Control pre-population from profile

  const MultiStepAICERTSIndustryTrainingModal({
    super.key,
    required this.courses,
    required this.industry,
    this.role,
    this.onEnrollmentComplete,
    this.allowPrefill = true, // Default true for backward compatibility
  });

  @override
  State<MultiStepAICERTSIndustryTrainingModal> createState() =>
      _MultiStepAICERTSIndustryTrainingModalState();
}

class _MultiStepAICERTSIndustryTrainingModalState
    extends State<MultiStepAICERTSIndustryTrainingModal> {
  int _currentStep = 0;
  int _currentLearnerIndex = 0;
  int _quantity = 1;
  bool _isCorporate = false;
  bool _isProcessing = false;
  bool _isSubmitting = false;

  // Industry-specific experience level
  String _selectedExperienceLevel =
      'beginner'; // beginner, intermediate, advanced

  // Form keys for validation
  final _formKey0 = GlobalKey<FormState>();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Company details controllers (for corporate enrollment)
  final _companyNameController = TextEditingController();
  final _companyRegistrationController = TextEditingController();
  final _companyTaxNumberController = TextEditingController();
  final _companyContactPersonController =
      TextEditingController(); // Contact Person
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  String _companyPhoneIsoCode = 'ZA';
  final _companyWebsiteController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPostalCodeController = TextEditingController();
  final _billingContactNameController = TextEditingController();
  final _billingContactEmailController = TextEditingController();
  final _billingContactPhoneController = TextEditingController();
  String _billingPhoneIsoCode = 'ZA';
  final _companyIndustryController = TextEditingController();
  String _selectedPaymentTerms = 'immediate'; // Payment Terms
  final _poNumberController = TextEditingController(); // PO Number

  // Location selection for company
  location_models.Country? _selectedCompanyCountry;
  location_models.State? _selectedCompanyState;
  location_models.City? _selectedCompanyCity;

  // Industry-specific AI tools selection
  List<String> _availableAiTools = [
    'ChatGPT/OpenAI',
    'Midjourney/DALL-E',
    'GitHub Copilot',
    'Tableau/Power BI',
    'Python/R',
    'TensorFlow/PyTorch',
    'AWS/Azure ML',
    'Google Analytics',
    'CRM Systems',
    'ERP Systems'
  ];

  // AICERTS-specific learner form data
  final List<AicertsLearnerFormData> _learners = [AicertsLearnerFormData()];

  String? _prefillEmail;

  @override
  void initState() {
    super.initState();

    if (widget.industry.isNotEmpty && widget.industry != 'all') {
      _companyIndustryController.text = widget.industry;
    }

    _initializeIndustryTools();
    CurrencyService.instance.addListener(_onCurrencyChanged);

    // NEW: Only pre-fill from profile if allowPrefill is true
    if (widget.allowPrefill) {
      _prefillFromProfile();
    }
  }

  Future<void> _prefillFromProfile() async {
    try {
      final p = await ApiClient.getStudentProfile();
      if (!mounted) return;
      final fullName = (p['user_full_name'] as String? ?? '').trim();
      final email = (p['user_email'] as String? ?? '').trim();
      if (email.isNotEmpty) _prefillEmail = email;
      if (_learners.isNotEmpty) {
        final l = _learners[0];
        if (fullName.isNotEmpty) {
          final parts = fullName.split(' ');
          l.firstNameController.text = parts.first;
          l.lastNameController.text =
              parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }
        if (email.isNotEmpty) l.emailController.text = email;
        _fillString(l.phoneController, p['phone']);
        _fillString(l.idNumberController, p['id_number']);
        _fillString(l.dobController, p['date_of_birth']);
        _fillString(l.addressController, p['address']);
        _fillString(l.postalCodeController, p['postal_code']);
        _fillString(l.occupationController, p['job_title'] ?? p['employer']);
        _fillString(l.institutionController, p['qualification_institution']);
        _fillString(l.emergencyNameController, p['emergency_contact_name']);
        _fillString(l.emergencyPhoneController, p['emergency_contact_phone']);
        if ((p['gender'] as String? ?? '').isNotEmpty)
          l.selectedGender = p['gender'] as String;
        if ((p['emergency_contact_relationship'] as String? ?? '').isNotEmpty)
          l.selectedEmergencyRelationship =
              p['emergency_contact_relationship'] as String;
        if ((p['highest_qualification'] as String? ?? '').isNotEmpty)
          l.selectedEducationLevel = p['highest_qualification'] as String;
      }
      _fillString(_companyNameController, p['last_used_company_name']);
      _fillString(_companyEmailController, p['last_used_company_email']);
      _fillString(_companyPhoneController, p['last_used_company_phone']);
      _fillString(_companyAddressController, p['last_used_company_address']);
      if (mounted) setState(() {});
      
      // Pre-set stream type for learners
      final streamType = _getStreamTypeForIndustry();
      for (var learner in _learners) {
        learner.selectedStreamType = streamType;
      }
    } catch (_) {}
  }

  void _fillString(TextEditingController ctrl, dynamic value) {
    final s = (value as String? ?? '').trim();
    if (s.isNotEmpty) ctrl.text = s;
  }

  Future<void> _cascadeProfileUpdate(AicertsLearnerFormData l) async {
    final data = <String, dynamic>{};
    if (l.phoneController.text.trim().isNotEmpty)
      data['phone'] = l.phoneController.text.trim();
    if (l.idNumberController.text.trim().isNotEmpty)
      data['id_number'] = l.idNumberController.text.trim();
    if (l.dobController.text.trim().isNotEmpty)
      data['date_of_birth'] = l.dobController.text.trim();
    if (l.addressController.text.trim().isNotEmpty)
      data['address'] = l.addressController.text.trim();
    if (l.postalCodeController.text.trim().isNotEmpty)
      data['postal_code'] = l.postalCodeController.text.trim();
    if (l.occupationController.text.trim().isNotEmpty)
      data['job_title'] = l.occupationController.text.trim();
    if (l.institutionController.text.trim().isNotEmpty)
      data['qualification_institution'] = l.institutionController.text.trim();
    if (l.emergencyNameController.text.trim().isNotEmpty)
      data['emergency_contact_name'] = l.emergencyNameController.text.trim();
    if (l.emergencyPhoneController.text.trim().isNotEmpty)
      data['emergency_contact_phone'] = l.emergencyPhoneController.text.trim();
    if (l.selectedGender != null) data['gender'] = l.selectedGender;
    if (l.selectedEmergencyRelationship != null)
      data['emergency_contact_relationship'] = l.selectedEmergencyRelationship;
    if (l.selectedEducationLevel != null)
      data['highest_qualification'] = l.selectedEducationLevel;
    if (l.selectedCountry != null) data['country'] = l.selectedCountry!.id;
    if (l.selectedState != null) data['state'] = l.selectedState!.id;
    if (l.selectedCity != null) data['city'] = l.selectedCity!.id;
    if (data.isNotEmpty) await ApiClient.updateStudentProfile(data);
  }

  void _initializeIndustryTools() {
    // Set appropriate AI tools based on industry
    final industryToolsMap = {
      'finance': [
        'Python/R',
        'Tableau/Power BI',
        'AWS/Azure ML',
        'Google Analytics'
      ],
      'healthcare': ['Python/R', 'TensorFlow/PyTorch', 'AWS/Azure ML'],
      'tech': [
        'ChatGPT/OpenAI',
        'GitHub Copilot',
        'Python/R',
        'TensorFlow/PyTorch',
        'AWS/Azure ML'
      ],
      'marketing': ['ChatGPT/OpenAI', 'Midjourney/DALL-E', 'Google Analytics'],
      'management': [
        'ChatGPT/OpenAI',
        'Tableau/Power BI',
        'CRM Systems',
        'ERP Systems'
      ],
    };

    final industryKey = widget.industry.toLowerCase();
    final defaultTools =
        industryToolsMap[industryKey] ?? ['ChatGPT/OpenAI', 'Python/R'];

    // Initialize each learner with default tools
    for (var learner in _learners) {
      learner.selectedAiTools = List<String>.from(defaultTools);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyRegistrationController.dispose();
    _companyTaxNumberController.dispose();
    _companyContactPersonController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyWebsiteController.dispose();
    _companyAddressController.dispose();
    _companyPostalCodeController.dispose();
    _billingContactNameController.dispose();
    _billingContactEmailController.dispose();
    _billingContactPhoneController.dispose();
    _companyIndustryController.dispose();
    _poNumberController.dispose();

    for (var learner in _learners) {
      learner.dispose();
    }

    CurrencyService.instance.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _nextStep() async {
    final formKey = _currentStep == 0
        ? _formKey0
        : (_currentStep == 1
            ? _formKey1
            : (_currentStep == 2 ? _formKey2 : null));
    if (formKey != null && !(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_validateCurrentStep()) {
      // If we are on learner info step (step 2), validate email existence
      if (_currentStep == 2) {
        setState(() => _isProcessing = true);
        try {
          final learner = _learners[_currentLearnerIndex];
          final email = learner.emailController.text.trim().toLowerCase();
          final exists = await ApiClient.checkEmailExists(email);
          if (exists) {
            if (mounted) {
              _showError(
                  'Learner email "$email" is already registered. Please sign in or use a different email.');
            }
            setState(() => _isProcessing = false);
            return;
          }
        } catch (e) {
          debugPrint('Error checking email: $e');
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      }

      if (_currentStep == 2 && _currentLearnerIndex < _quantity - 1) {
        setState(() {
          _currentLearnerIndex++;
        });
        return;
      }

      setState(() {
        _currentStep++;
      });

      // Sync stream type to all learners whenever moving forward
      final streamType = _getStreamTypeForIndustry();
      for (var learner in _learners) {
        learner.selectedStreamType = streamType;
      }
      
      _saveMetadata();
    }
  }

  void _saveMetadata() {
    // In Industry Training, we don't currently persist partial progress to SharedPreferences
    // like in Custom Selection, but we keep the method for consistency and future-proofing.
  }

  void _previousStep() {
    if (_currentStep == 2 && _currentLearnerIndex > 0) {
      setState(() {
        _currentLearnerIndex--;
      });
      return;
    }
    setState(() {
      _currentStep--;
    });
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Quantity & Experience Level
        return true;

      case 1: // Type + Corporate details
        if (_isCorporate) {
          if (_companyNameController.text.trim().isEmpty) {
            _showError('Company Name is required');
            return false;
          }
          if (_companyRegistrationController.text.trim().isEmpty) {
            _showError('Company Registration Number is required');
            return false;
          }
          if (_companyTaxNumberController.text.trim().isEmpty) {
            _showError('Tax/VAT Number is required for invoicing');
            return false;
          }
          if (_companyEmailController.text.trim().isEmpty) {
            _showError('Company Email is required');
            return false;
          }
          if (_companyPhoneController.text.trim().isEmpty) {
            _showError('Company Phone is required');
            return false;
          }
          if (_companyAddressController.text.trim().isEmpty) {
            _showError('Company Address is required for invoicing');
            return false;
          }
          if (_selectedCompanyCountry == null) {
            _showError('Company Country is required');
            return false;
          }
          if (_companyPostalCodeController.text.trim().isEmpty) {
            _showError('Company Postal Code is required for invoicing');
            return false;
          }
          if (_billingContactNameController.text.trim().isEmpty) {
            _showError('Billing Contact Name is required');
            return false;
          }
          if (_billingContactEmailController.text.trim().isEmpty) {
            _showError('Billing Contact Email is required');
            return false;
          }
          if (_billingContactPhoneController.text.trim().isEmpty) {
            _showError('Billing Contact Phone is required');
            return false;
          }
        }

        while (_learners.length < _quantity) {
          _learners.add(AicertsLearnerFormData());
        }
        while (_learners.length > _quantity) {
          _learners.removeLast().dispose();
        }

        return true;

      case 2: // Learner details
        final learner = _learners[_currentLearnerIndex];
        if (!learner.validate()) {
          if (learner.firstNameController.text.trim().isEmpty ||
              learner.lastNameController.text.trim().isEmpty) {
            _showError('First and Last Name are required');
          } else if (learner.emailController.text.trim().isEmpty) {
            _showError('Email is required');
          } else if (learner.phoneController.text.trim().isEmpty) {
            _showError('Phone is required');
          } else if (learner.idNumberController.text.trim().isEmpty) {
            _showError('ID / Passport number is required');
          } else if (learner.dobController.text.trim().isEmpty) {
            _showError('Date of Birth is required');
          } else if (learner.selectedGender == null) {
            _showError('Gender is required');
          } else if (learner.selectedCountry == null) {
            _showError('Country is required');
          } else if (learner.selectedExperienceLevel == null) {
            _showError('Please select your experience level');
          } else if (!learner.termsAccepted) {
            _showError('Please accept the terms and conditions');
          } else if (!learner.aicertsPlatformAgreement) {
            _showError('Please accept the AICERTS platform agreement');
          } else {
            _showError('Please check for errors in the form');
          }
          return false;
        }
        return true;

      case 3: // Review
        return true;

      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Calculate total price for industry training courses
  /// Uses actual course.price from API (which reads price_usd) to ensure price persistence
  double _calculateTotalPrice() {
    double total = 0.0;
    for (final course in widget.courses) {
      // Use database price if available, otherwise use constants based on stream type
      final streamType = _getStreamTypeForIndustry();
      final coursePrice = (course.price == null || course.price == 0.0)
          ? PricingConstants.getAICertsPrice(streamType: streamType)
          : course.price!;
      total += coursePrice;
    }
    return total * _quantity;
  }

  String _getStreamTypeForIndustry() {
    // Map industries to stream types
    const technicalIndustries = {
      'tech',
      'engineering',
      'data',
      'cybersecurity',
      'ai',
      'blockchain'
    };
    const professionalIndustries = {
      'finance',
      'healthcare',
      'marketing',
      'management',
      'sales',
      'hr'
    };

    final industry = widget.industry.toLowerCase();

    if (technicalIndustries.contains(industry)) {
      return 'technical';
    } else if (professionalIndustries.contains(industry)) {
      return 'professional';
    }

    // Default based on course content or learner selection
    if (_learners.isNotEmpty && _learners.first.selectedStreamType != null) {
      return _learners.first.selectedStreamType!;
    }

    // Check course titles for keywords
    for (final course in widget.courses) {
      final title = course.title.toLowerCase();
      if (title.contains('technical') ||
          title.contains('engineering') ||
          title.contains('development')) {
        return 'technical';
      }
      if (title.contains('professional') ||
          title.contains('management') ||
          title.contains('business')) {
        return 'professional';
      }
    }

    return 'professional'; // Default fallback
  }

  Future<void> _proceedToPayment() async {
    if (_isProcessing || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Prepare enrollment data
      // Get localized amount for payment flow
      final currencySvc = CurrencyService.instance;
      final totalUSD = _calculateTotalPrice();
      final localizedAmount = currencySvc.convertFromUSD(totalUSD);
      final userCurrency = currencySvc.userCurrency;
      final country = _learners.isNotEmpty ? (_learners.first.selectedCountryName ?? currencySvc.countryCode) : currencySvc.countryCode;

      final enrollmentData = {
        'courses': widget.courses.map((c) => c.id).toList(),
        'is_corporate': _isCorporate,
        'quantity': _quantity,
        'amount': localizedAmount, // Localized amount (e.g. ZAR 3000)
        'amount_usd': totalUSD,      // Reference USD amount (e.g. 150.0)
        'currency': userCurrency,
        'country': country,
        'industry': widget.industry,
        'role': widget.role,
        'stream_type': _getStreamTypeForIndustry(),
        'enrollment_type': 'industry_training',
        'experience_level': _selectedExperienceLevel,
        if (_isCorporate) ..._buildCompanyData(),
        'learners': _learners.map((learner) => learner.toJson()).toList(),
      };

      // Cascade form data back to student profile (best-effort)
      if (!_isCorporate && _learners.isNotEmpty) {
        await _cascadeProfileUpdate(_learners.first);
      }

      // Show payment modal with LOCALISED values
      await PaymentProviderSelectionPage.show(
        context,
        reference: 'AICERTS-IT-${DateTime.now().millisecondsSinceEpoch}',
        amount: localizedAmount,
        currency: userCurrency,
        country: country,
        programId: widget.courses.first.id,
        programType:
            widget.courses.length > 1 ? 'role_training' : 'industry_training',
        paymentMetadata: {
          ...enrollmentData,
          'course_count': widget.courses.length,
          'learner_count': _quantity,
        },
        enrollmentPayload: enrollmentData,
      );
    } catch (e) {
      _showError('Error proceeding to payment: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Map<String, dynamic> _buildCompanyData() {
    return {
      'company_name': _companyNameController.text.trim(),
      'company_registration': _companyRegistrationController.text.trim(),
      'company_tax_number': _companyTaxNumberController.text.trim(),
      'company_contact_person': _companyContactPersonController.text.trim(),
      'company_email': _companyEmailController.text.trim(),
      'company_phone': _companyPhoneController.text.trim(),
      'company_phone_iso': _companyPhoneIsoCode,
      'company_website': _companyWebsiteController.text.trim(),
      'company_address': _companyAddressController.text.trim(),
      'company_postal_code': _companyPostalCodeController.text.trim(),
      'company_country_id': _selectedCompanyCountry?.id,
      'company_state_id': _selectedCompanyState?.id,
      'company_city_id': _selectedCompanyCity?.id,
      'company_industry': _companyIndustryController.text.trim(),
      'billing_contact_name': _billingContactNameController.text.trim(),
      'billing_contact_email': _billingContactEmailController.text.trim(),
      'billing_contact_phone': _billingContactPhoneController.text.trim(),
      'billing_phone_iso': _billingPhoneIsoCode,
      'payment_terms': _selectedPaymentTerms,
      'po_number': _poNumberController.text.trim(),
    };
  }

  Widget _buildIndustryInfoBanner() {
    final industryName =
        widget.industry[0].toUpperCase() + widget.industry.substring(1);
    final roleText = widget.role != null ? ' (${widget.role})' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business_rounded,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$industryName$roleText Industry Training',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.courses.length} AICERTS-powered courses tailored for $industryName industry professionals. '
            'Develop AI skills specifically for your industry context.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;
    final isNarrow = sw < 480;
    final hInset = isNarrow ? 0.0 : (sw < 700 ? 12.0 : 20.0);
    final vInset = isNarrow ? 0.0 : 20.0;
    final contentPad = isNarrow ? 16.0 : 24.0;

    final industryName =
        widget.industry[0].toUpperCase() + widget.industry.substring(1);
    final roleText = widget.role != null ? ' (${widget.role})' : '';

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: hInset, vertical: vInset),
      shape: isNarrow
          ? const RoundedRectangleBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: isNarrow ? sh : sh * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(contentPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$industryName$roleText Industry Training',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: (sw * 0.045).clamp(14.0, 20.0),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        Text(
                          '${widget.courses.length} industry-specific AI courses',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: (sw * 0.03).clamp(10.0, 13.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Industry Information Banner
              _buildIndustryInfoBanner(),
              const SizedBox(height: 12),

              // Persistent Price Summary Bar
              _buildPriceBar(theme, colors),
              const SizedBox(height: 12),

              // Stepper
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Stepper(
                        currentStep: _currentStep,
                        onStepContinue: _nextStep,
                        onStepCancel: _previousStep,
                        onStepTapped: (step) {
                          if (step < _currentStep) {
                            setState(() => _currentStep = step);
                          }
                        },
                        controlsBuilder: (context, details) {
                          return const SizedBox
                              .shrink(); // Custom buttons below
                        },
                        steps: [
                          // Step 0: Experience Level & Quantity
                          Step(
                            title: const Text('Experience & Quantity'),
                            content: Form(
                              key: _formKey0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Experience Level Selection
                                  Text(
                                    'Industry Experience Level',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _buildExperienceCard(
                                        level: 'beginner',
                                        title: 'Beginner',
                                        description:
                                            'New to $industryName industry',
                                        icon: Icons.person_add,
                                      ),
                                      _buildExperienceCard(
                                        level: 'intermediate',
                                        title: 'Intermediate',
                                        description:
                                            '1-3 years $industryName experience',
                                        icon: Icons.person,
                                      ),
                                      _buildExperienceCard(
                                        level: 'advanced',
                                        title: 'Advanced',
                                        description:
                                            '3+ years $industryName experience',
                                        icon: Icons.person_outline,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Quantity Selection
                                  Text(
                                    'Number of Learners',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          if (_quantity > 1) {
                                            setState(() => _quantity--);
                                          }
                                        },
                                      ),
                                      Container(
                                        width: 60,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: colors.outline),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _quantity.toString(),
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          setState(() => _quantity++);
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'learner${_quantity > 1 ? 's' : ''}',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Step 1: Enrollment Type & Corporate Details
                          Step(
                            title: const Text('Enrollment Type'),
                            content: Form(
                              key: _formKey1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Enrollment Type Selection
                                  Text(
                                    'Who is enrolling?',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildEnrollmentTypeCard(
                                          icon: Icons.person,
                                          title: 'Individual',
                                          subtitle:
                                              'For personal career development',
                                          isSelected: !_isCorporate,
                                          onTap: () {
                                            setState(
                                                () => _isCorporate = false);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildEnrollmentTypeCard(
                                          icon: Icons.business,
                                          title: 'Corporate',
                                          subtitle: 'For team upskilling',
                                          isSelected: _isCorporate,
                                          onTap: () {
                                            setState(() => _isCorporate = true);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Corporate Form (conditionally shown)
                                  if (_isCorporate) ...[
                                    const SizedBox(height: 24),
                                    _buildCorporateForm(),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Step 2: Learner Information
                          Step(
                            title: Text(
                                'Learner ${_currentLearnerIndex + 1} of $_quantity'),
                            content: Form(
                              key: _formKey2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Industry-specific AI Tools
                                  Text(
                                    'Relevant AI Tools Experience',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAiToolsSelection(
                                      _learners[_currentLearnerIndex]),
                                  const SizedBox(height: 24),

                                  // Learner Form
                                  _buildLearnerForm(
                                      _learners[_currentLearnerIndex]),
                                ],
                              ),
                            ),
                          ),

                          // Step 3: Review & Payment
                          Step(
                            title: const Text('Review & Payment'),
                            content: Form(
                              key: _formKey3,
                              child: _buildReviewStep(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Navigation
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colors.outline),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _currentStep > 0 ? _previousStep : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                    Row(
                      children: [
                        if (_currentStep < 3) ...[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _nextStep,
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(),
                                  )
                                : Text(_currentStep == 2
                                    ? 'Next Learner'
                                    : 'Continue'),
                          ),
                        ] else ...[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _proceedToPayment,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(),
                                  )
                                : const Icon(Icons.payment),
                            label: Text(_isSubmitting
                                ? 'Processing...'
                                : 'Proceed to Payment'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceCard({
    required String level,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelected = _selectedExperienceLevel == level;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedExperienceLevel = level;
          // Also set experience level for all learners
          for (var learner in _learners) {
            learner.selectedExperienceLevel = level;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer
              : colors.surfaceContainerLowest,
          border: Border.all(
            color: isSelected ? colors.primary : colors.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? colors.primary : colors.onSurface),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colors.primary : colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer
              : colors.surfaceContainerLowest,
          border: Border.all(
            color: isSelected ? colors.primary : colors.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? colors.primary : colors.onSurface),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colors.primary : colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiToolsSelection(AicertsLearnerFormData learner) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableAiTools.map((tool) {
        final isSelected = learner.selectedAiTools.contains(tool);
        return FilterChip(
          label: Text(tool),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                learner.selectedAiTools.add(tool);
              } else {
                learner.selectedAiTools.remove(tool);
              }
            });
          },
          checkmarkColor: Theme.of(context).colorScheme.onPrimary,
          selectedColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildCorporateForm() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Information for Billing',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Company Name
          TextFormField(
            controller: _companyNameController,
            decoration: const InputDecoration(
              labelText: 'Company Name *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Company Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Registration Number
          TextFormField(
            controller: _companyRegistrationController,
            decoration: const InputDecoration(
              labelText: 'Registration Number *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Registration Number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Tax/VAT Number
          TextFormField(
            controller: _companyTaxNumberController,
            decoration: const InputDecoration(
              labelText: 'Tax/VAT Number *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tax/VAT Number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Company Email
          TextFormField(
            controller: _companyEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Company Email *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Company Email is required';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Company Phone
          _buildPhoneField(
            controller: _companyPhoneController,
            label: 'Company Phone *',
            currentIso: _companyPhoneIsoCode,
            onIsoChanged: (String newIso) {
              setState(() => _companyPhoneIsoCode = newIso);
            },
          ),
          const SizedBox(height: 16),

          // Company Address
          TextFormField(
            controller: _companyAddressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Company Address *',
              border: OutlineInputBorder(),
              hintText: 'Street address, building, etc.',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Company Address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Location Dropdowns
          BlocProvider(
            create: (context) => LocationBloc(),
            child: CascadingLocationDropdowns(
              key: const ValueKey('company_location_dropdown'),
              onLocationChanged: (country, state, city) {
                setState(() {
                  _selectedCompanyCountry = country;
                  _selectedCompanyState = state;
                  _selectedCompanyCity = city;
                  if (country != null) {
                    _companyPhoneIsoCode = country.code;
                    _billingPhoneIsoCode = country.code;
                  }
                });
              },
              initialCountry: _selectedCompanyCountry,
              initialState: _selectedCompanyState,
              initialCity: _selectedCompanyCity,
              isRequired: true,
              countryLabel: 'Company Country *',
              stateLabel: 'Company State/Province',
              cityLabel: 'Company City',
            ),
          ),
          const SizedBox(height: 16),

          // Postal Code
          TextFormField(
            controller: _companyPostalCodeController,
            decoration: const InputDecoration(
              labelText: 'Postal Code *',
              border: OutlineInputBorder(),
              hintText: 'Required for invoicing',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Postal Code is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Industry
          TextFormField(
            controller: _companyIndustryController,
            decoration: const InputDecoration(
              labelText: 'Industry',
              border: OutlineInputBorder(),
            ),
            readOnly: widget.industry.isNotEmpty && widget.industry != 'all',
          ),
          const SizedBox(height: 16),

          // Billing Contact Information Section
          Text(
            'Billing Contact Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Billing Contact Name
          TextFormField(
            controller: _billingContactNameController,
            decoration: const InputDecoration(
              labelText: 'Billing Contact Name *',
              border: OutlineInputBorder(),
              hintText: 'Person responsible for invoices',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Billing Contact Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Billing Contact Email
          TextFormField(
            controller: _billingContactEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Billing Contact Email *',
              border: OutlineInputBorder(),
              hintText: 'Email for invoice delivery',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Billing Contact Email is required';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Billing Contact Phone
          _buildPhoneField(
            controller: _billingContactPhoneController,
            label: 'Billing Contact Phone *',
            currentIso: _billingPhoneIsoCode,
            onIsoChanged: (String newIso) {
              setState(() => _billingPhoneIsoCode = newIso);
            },
          ),
          const SizedBox(height: 24),

          // Contact Person Name *
          TextFormField(
            controller: _companyContactPersonController,
            decoration: const InputDecoration(
              labelText: 'Contact Person Name *',
              border: OutlineInputBorder(),
              hintText: 'Primary contact person for this enrollment',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Contact Person Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Payment Terms Dropdown *
          DropdownButtonFormField<String>(
            value: (_selectedPaymentTerms ?? '').isEmpty
                ? null
                : _selectedPaymentTerms,
            decoration: const InputDecoration(
              labelText: 'Payment Terms *',
              border: OutlineInputBorder(),
              hintText: 'Select payment terms',
            ),
            items: const [
              DropdownMenuItem(
                  value: 'immediate', child: Text('Immediate Payment')),
              DropdownMenuItem(value: 'net7', child: Text('Net 7 Days')),
              DropdownMenuItem(value: 'net15', child: Text('Net 15 Days')),
              DropdownMenuItem(value: 'net30', child: Text('Net 30 Days')),
              DropdownMenuItem(value: 'net60', child: Text('Net 60 Days')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPaymentTerms = value ?? 'immediate';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Payment Terms is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // PO Number *
          TextFormField(
            controller: _poNumberController,
            decoration: const InputDecoration(
              labelText: 'PO Number *',
              border: OutlineInputBorder(),
              hintText: 'Purchase Order number',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'PO Number is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLearnerForm(AicertsLearnerFormData learner) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Details
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: learner.firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: learner.lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: learner.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        ContactOtpField(
          contactController: learner.emailController,
          contactType: 'email',
          onVerifiedChanged: (verified) =>
              setState(() => learner.emailVerified = verified),
        ),
        if (learner.emailVerified) ...[
          const SizedBox(height: 16),

        // Phone with country code
        _buildPhoneField(
          label: 'Phone',
          controller: learner.phoneController,
          currentIso: learner.phoneIsoCode,
          onIsoChanged: (iso) {
            setState(() => learner.phoneIsoCode = iso);
          },
        ),
        const SizedBox(height: 16),

        // Location
        BlocProvider(
          create: (context) => LocationBloc(),
          child: CascadingLocationDropdowns(
            onLocationChanged: (country, state, city) {
              setState(() {
                learner.selectedCountry = country;
                learner.selectedCountryName = country?.name;
                learner.selectedState = state;
                learner.selectedCity = city;
              });
            },
            initialCountry: learner.selectedCountry,
            initialState: learner.selectedState,
            initialCity: learner.selectedCity,
            countryLabel: 'Country',
            stateLabel: 'State/Province',
            cityLabel: 'City',
          ),
        ),
        const SizedBox(height: 16),

        // AICERTS Platform Agreement (also sets termsAccepted)
        CheckboxListTile(
          value: learner.aicertsPlatformAgreement,
          onChanged: (value) {
            setState(() {
              learner.aicertsPlatformAgreement = value!;
              learner.termsAccepted = value;
            });
          },
          title: Text(
            'I agree to the Hosi Academy & AICERTS platform terms of service',
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            'By checking this box, I acknowledge that course access will be provided through the AICERTS platform',
            style: theme.textTheme.bodySmall,
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    ],
    );
  }

  Widget _buildPhoneField({
    required String label,
    required TextEditingController controller,
    required String currentIso,
    required ValueChanged<String> onIsoChanged,
  }) {
    final info = AfricanPhoneValidator.getInfoForCountry(currentIso);
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: DropdownButtonFormField<String>(
            value: currentIso,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: AfricanPhoneValidator.supportedCountries.map((iso) {
              final countryInfo = AfricanPhoneValidator.getInfoForCountry(iso);
              return DropdownMenuItem<String>(
                value: iso,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      'https://flagcdn.com/w20/${iso.toLowerCase()}.png',
                      width: 20,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.flag, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      countryInfo?.countryCode ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onIsoChanged(val);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(info?.maxDigits ?? 15),
            ],
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              errorStyle: const TextStyle(fontSize: 10),
              counterText: "",
            ),
            maxLength: info?.maxDigits,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final phoneInfo =
                  AfricanPhoneValidator.getInfoForCountry(currentIso);
              if (phoneInfo != null) {
                final digits = value.replaceAll(RegExp(r'\D'), '');
                if (digits.length < phoneInfo.minDigits) {
                  return 'Minimum ${phoneInfo.minDigits} digits required';
                }
                if (digits.length > phoneInfo.maxDigits) {
                  return 'Maximum ${phoneInfo.maxDigits} digits exceeded';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currency = CurrencyService.instance;
    final totalPrice = _calculateTotalPrice();
    final industryName =
        widget.industry[0].toUpperCase() + widget.industry.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Industry Training Summary',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Industry & Course Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Industry: $industryName',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.role != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Role: ${widget.role}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Included Courses',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.courses.map((course) {
                  return ListTile(
                    leading: SizedBox(
                      width: 80,
                      child: AICERTSCourseCardImage(
                        featureImageUrl: course.featureImageUrl,
                        height: 45,
                        width: 80,
                        showBadge: false,
                      ),
                    ),
                    title: const SizedBox.shrink(), // Title is in the SVG image
                    subtitle: Text(course.description ?? ''),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pricing Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pricing Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_quantity} learner${_quantity > 1 ? 's' : ''} × ${widget.courses.length} courses',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      currency.formatUSDAmount(totalPrice),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Experience Level: ${_selectedExperienceLevel.toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Stream: ${_getStreamTypeForIndustry().toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Important Notes
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: colors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Industry Training Benefits',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Industry-specific AI applications\n'
                '• Real-world case studies from $industryName industry\n'
                '• Certificate of completion from AICERTS\n'
                '• Access to industry-focused AI tools\n'
                '• Progress tracking through AICERTS platform\n'
                '• Support from industry experts',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBar(ThemeData theme, ColorScheme colors) {
    final currencySvc = CurrencyService.instance;
    final totalUSD = _calculateTotalPrice();
    final localizedTotal = currencySvc.convertFromUSD(totalUSD);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Total Enrollment Cost:',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${currencySvc.userCurrency} ${currencySvc.formatPrice(localizedTotal)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
