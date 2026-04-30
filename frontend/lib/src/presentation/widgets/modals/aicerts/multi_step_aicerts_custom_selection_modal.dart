// lib/src/presentation/widgets/modals/aicerts/multi_step_aicerts_custom_selection_modal.dart
// AICERTS Custom Selection Pathway Enrollment Modal

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/masterclass.dart';
import '../../../../data/models/course.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/constants/pricing_constants.dart';
import '../../../../core/utils/african_phone_validator.dart';
import '../../../pages/payment/payment_provider_selection_page.dart';
import '../../student_portal/cascading_location_dropdowns.dart';
import '../../../blocs/student_portal/location_bloc.dart';
import '../../../../data/models/location.dart' as location_models;
import '../../contact_otp_field.dart';
import '../../aicerts/aicerts_image_widget.dart';
import 'shared/aicerts_form_data.dart';

/// AICERTS Custom Selection Enrollment Modal
/// For enrolling learners in AICERTS-powered custom selection courses
class MultiStepAICERTSCustomSelectionModal extends StatefulWidget {
  final List<Course> courses; // AICERTS courses for custom selection
  final VoidCallback? onEnrollmentComplete;
  final bool allowPrefill; // NEW: Control pre-population from profile

  const MultiStepAICERTSCustomSelectionModal({
    super.key,
    required this.courses,
    this.onEnrollmentComplete,
    this.allowPrefill = true, // Default true for backward compatibility
  });

  @override
  State<MultiStepAICERTSCustomSelectionModal> createState() =>
      _MultiStepAICERTSCustomSelectionModalState();
}

class _MultiStepAICERTSCustomSelectionModalState
    extends State<MultiStepAICERTSCustomSelectionModal> {
  int _currentStep = 0;
  int _currentLearnerIndex = 0;
  int _quantity = 1;
  bool _isCorporate = false;
  bool _isProcessing = false;
  bool _isSubmitting = false;
  
  // Stream type detection (Technical vs Professional)
  String _streamType = 'technical'; // Default
  
  // Form keys for validation
  final _formKey0 = GlobalKey<FormState>();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Company details controllers (for corporate enrollment)
  final _companyNameController = TextEditingController();
  final _companyRegistrationController = TextEditingController();
  final _companyTaxNumberController = TextEditingController();
  final _companyContactPersonController = TextEditingController(); // Contact Person
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
  String? _selectedCompanySize;

  // AICERTS-specific learner form data
  final List<AicertsLearnerFormData> _learners = [AicertsLearnerFormData()];

  // AICERTS course selection state
  List<bool> _selectedCourses = [];

  String? _prefillEmail;

  @override
  void initState() {
    super.initState();

    _selectedCourses = List<bool>.filled(widget.courses.length, true);
    _detectStreamType();
    CurrencyService.instance.addListener(_onCurrencyChanged);
    
    // Initialize with stored progress
    _loadStoredProgress().then((_) {
      if (widget.allowPrefill) {
        _prefillFromProfile();
      }
      _setupListeners();
    });
  }

  Future<void> _loadStoredProgress() async {
    final programId = widget.courses.map((c) => c.id).join('_').hashCode;
    final prefs = await SharedPreferences.getInstance();
    
    // Load step and metadata
    _currentStep = prefs.getInt('aicerts_step_$programId') ?? 0;
    _isCorporate = prefs.getBool('aicerts_is_corporate_$programId') ?? false;
    _quantity = prefs.getInt('aicerts_quantity_$programId') ?? 1;
    
    // Load course selections
    final selectedStr = prefs.getStringList('aicerts_selected_courses_$programId');
    if (selectedStr != null && selectedStr.length == _selectedCourses.length) {
      _selectedCourses = selectedStr.map((s) => s == 'true').toList();
    }

    // Load learner data
    while (_learners.length < _quantity) {
      _learners.add(AicertsLearnerFormData());
    }
    
    for (int i = 0; i < _learners.length; i++) {
      await _learners[i].loadFromStorage('aicerts_learner_${programId}_$i');
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveMetadata() async {
    final programId = widget.courses.map((c) => c.id).join('_').hashCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('aicerts_step_$programId', _currentStep);
    await prefs.setBool('aicerts_is_corporate_$programId', _isCorporate);
    await prefs.setInt('aicerts_quantity_$programId', _quantity);
    await prefs.setStringList('aicerts_selected_courses_$programId', 
        _selectedCourses.map((b) => b.toString()).toList());
    
    // Ensure all learners have the detected stream type
    for (var learner in _learners) {
      learner.selectedStreamType = _streamType;
    }
  }

  void _setupListeners() {
    final programId = widget.courses.map((c) => c.id).join('_').hashCode;
    
    // Metadata listeners (can be triggered manually)

    // Learner listeners
    for (int i = 0; i < _learners.length; i++) {
      final learner = _learners[i];
      final key = 'aicerts_learner_${programId}_$i';
      
      void saveLearner() => learner.saveToStorage(key);
      
      learner.firstNameController.addListener(saveLearner);
      learner.lastNameController.addListener(saveLearner);
      learner.emailController.addListener(saveLearner);
      learner.phoneController.addListener(saveLearner);
      learner.idNumberController.addListener(saveLearner);
      learner.addressController.addListener(saveLearner);
      learner.postalCodeController.addListener(saveLearner);
      learner.occupationController.addListener(saveLearner);
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
        if ((p['gender'] as String? ?? '').isNotEmpty) l.selectedGender = p['gender'] as String;
        if ((p['emergency_contact_relationship'] as String? ?? '').isNotEmpty)
          l.selectedEmergencyRelationship = p['emergency_contact_relationship'] as String;
        if ((p['highest_qualification'] as String? ?? '').isNotEmpty)
          l.selectedEducationLevel = p['highest_qualification'] as String;
      }
      _fillString(_companyNameController, p['last_used_company_name']);
      _fillString(_companyEmailController, p['last_used_company_email']);
      _fillString(_companyPhoneController, p['last_used_company_phone']);
      _fillString(_companyAddressController, p['last_used_company_address']);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _fillString(TextEditingController ctrl, dynamic value) {
    final s = (value as String? ?? '').trim();
    if (s.isNotEmpty) ctrl.text = s;
  }

  Future<void> _cascadeProfileUpdate(AicertsLearnerFormData l) async {
    final data = <String, dynamic>{};
    if (l.phoneController.text.trim().isNotEmpty) data['phone'] = l.phoneController.text.trim();
    if (l.idNumberController.text.trim().isNotEmpty) data['id_number'] = l.idNumberController.text.trim();
    if (l.dobController.text.trim().isNotEmpty) data['date_of_birth'] = l.dobController.text.trim();
    if (l.addressController.text.trim().isNotEmpty) data['address'] = l.addressController.text.trim();
    if (l.postalCodeController.text.trim().isNotEmpty) data['postal_code'] = l.postalCodeController.text.trim();
    if (l.occupationController.text.trim().isNotEmpty) data['job_title'] = l.occupationController.text.trim();
    if (l.institutionController.text.trim().isNotEmpty) data['qualification_institution'] = l.institutionController.text.trim();
    if (l.emergencyNameController.text.trim().isNotEmpty) data['emergency_contact_name'] = l.emergencyNameController.text.trim();
    if (l.emergencyPhoneController.text.trim().isNotEmpty) data['emergency_contact_phone'] = l.emergencyPhoneController.text.trim();
    if (l.selectedGender != null) data['gender'] = l.selectedGender;
    if (l.selectedEmergencyRelationship != null) data['emergency_contact_relationship'] = l.selectedEmergencyRelationship;
    if (l.selectedEducationLevel != null) data['highest_qualification'] = l.selectedEducationLevel;
    if (l.selectedCountry != null) data['country'] = l.selectedCountry!.id;
    if (l.selectedState != null) data['state'] = l.selectedState!.id;
    if (l.selectedCity != null) data['city'] = l.selectedCity!.id;
    if (data.isNotEmpty) await ApiClient.updateStudentProfile(data);
  }

  void _detectStreamType() {
    // Try to detect stream type from courses
    for (final course in widget.courses) {
      final industry = (course.industry ?? '').toLowerCase();
      final streamType = (course.streamType ?? '').toLowerCase();
      final categories = (course.categories ?? '').toLowerCase();
      
      if (industry.contains('technical') || 
          streamType.contains('technical') || 
          categories.contains('technical')) {
        _streamType = 'technical';
        break;
      } else if (industry.contains('professional') || 
                 streamType.contains('professional') || 
                 categories.contains('professional')) {
        _streamType = 'professional';
        break;
      }
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
        _saveMetadata();
        return;
      }

      setState(() {
        _currentStep++;
      });
      
      // Sync stream type to all learners whenever moving forward
      for (var learner in _learners) {
        learner.selectedStreamType = _streamType;
      }
      
      _saveMetadata();
    }
  }

  void _previousStep() {
    if (_currentStep == 2 && _currentLearnerIndex > 0) {
      setState(() {
        _currentLearnerIndex--;
      });
      _saveMetadata();
      return;
    }
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _saveMetadata();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Quantity & Course Selection
        // Ensure at least one course is selected
        if (!_selectedCourses.contains(true)) {
          _showError('Please select at least one AICERTS course');
          return false;
        }
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
        // Auto-assign stream type if not set (since we removed manual selection)
        if (learner.selectedStreamType == null) {
          learner.selectedStreamType = _streamType;
        }
        if (!learner.validate()) {
          if (learner.firstNameController.text.trim().isEmpty || learner.lastNameController.text.trim().isEmpty) {
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

  /// Calculate total price for selected AICERTS courses
  /// Uses actual course.price from API (which reads price_usd) to ensure price persistence
  double _calculateTotalPrice() {
    double total = 0.0;
    for (int i = 0; i < widget.courses.length; i++) {
      if (_selectedCourses[i]) {
        final course = widget.courses[i];
        // Detect stream type for this specific course or use overall selection
        String stream = _streamType;
        final industry = (course.industry ?? '').toLowerCase();
        final streamType = (course.streamType ?? '').toLowerCase();
        final categories = (course.categories ?? '').toLowerCase();
        
        if (industry.contains('technical') || streamType.contains('technical') || categories.contains('technical')) {
          stream = 'technical';
        } else if (industry.contains('professional') || streamType.contains('professional') || categories.contains('professional')) {
          stream = 'professional';
        }
        
        final coursePrice = (course.price == null || course.price == 0.0)
            ? PricingConstants.getAICertsPrice(streamType: stream)
            : course.price!;
        total += coursePrice;
      }
    }
    return total * _quantity;
  }

  Future<void> _proceedToPayment() async {
    if (_isProcessing || _isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      // Get selected courses
      final selectedCourses = <Course>[];
      for (int i = 0; i < widget.courses.length; i++) {
        if (_selectedCourses[i]) {
          selectedCourses.add(widget.courses[i]);
        }
      }
      
      if (selectedCourses.isEmpty) {
        _showError('Please select at least one AICERTS course');
        setState(() => _isSubmitting = false);
        return;
      }
      
      // Get localized amount for payment flow
      final currencySvc = CurrencyService.instance;
      final totalUSD = _calculateTotalPrice();
      final localizedAmount = currencySvc.convertFromUSD(totalUSD);
      final userCurrency = currencySvc.userCurrency;
      final country = _learners.isNotEmpty ? (_learners.first.selectedCountryName ?? currencySvc.countryCode) : currencySvc.countryCode;

      // Prepare enrollment data with BOTH amounts for backend transparency
      final enrollmentData = {
        'courses': selectedCourses.map((c) => c.id).toList(),
        'is_corporate': _isCorporate,
        'quantity': _quantity,
        'amount': localizedAmount, // Localized amount (e.g. ZAR 3000)
        'amount_usd': totalUSD,      // Reference USD amount (e.g. 150.0)
        'currency': userCurrency,
        'country': country,
        'stream_type': _streamType,
        'enrollment_type': 'custom_selection',

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
        reference: 'AICERTS-CS-${DateTime.now().millisecondsSinceEpoch}',
        amount: localizedAmount,
        currency: userCurrency,
        country: country,
        programId: widget.courses.first.id,
        programType: 'custom_selection',
        paymentMetadata: {
          ...enrollmentData, // Pass everything in metadata
          'course_count': selectedCoursesCount(),
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

  Widget _buildAicertsInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AICERTS-Powered Training',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These courses are delivered through the AICERTS platform with AI-powered learning tools, certificate issuance, and progress tracking.',
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(contentPad, contentPad, contentPad, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AICERTS Custom Selection Enrollment',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: (sw * 0.045).clamp(16.0, 22.0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Step ${_currentStep + 1} of 4: ${_getStepTitle()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
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
            ),

            // Step Indicator
            _buildProgressIndicator(colors),

            // Persistent Price Summary Bar
            _buildPriceBar(theme, colors),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(contentPad),
                child: Column(
                  children: [
                    _buildAicertsInfoBanner(),
                    const SizedBox(height: 24),
                    _buildStepContent(theme, colors, sw),
                  ],
                ),
              ),
            ),

            // Sticky Footer
            _buildFooter(theme, colors),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Courses & Quantity';
      case 1: return 'Enrollment Type';
      case 2: return 'Learner Information';
      case 3: return 'Review & Payment';
      default: return '';
    }
  }

  Widget _buildPriceBar(ThemeData theme, ColorScheme colors) {
    final currencySvc = CurrencyService.instance;
    final totalUSD = _calculateTotalPrice();
    final localizedTotal = currencySvc.convertFromUSD(totalUSD);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: colors.primary.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart_outlined, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Total Enrollment Cost:',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
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

  Widget _buildProgressIndicator(ColorScheme colors) {
    final stepLabels = ['Courses', 'Type', 'Learners', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: List.generate(stepLabels.length, (index) {
          final isActive = _currentStep == index;
          final isCompleted = _currentStep > index;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCompleted ? colors.primary : (isActive ? colors.primary : colors.surfaceContainerHighest),
                          shape: BoxShape.circle,
                          border: Border.all(color: isActive ? colors.primary : colors.outline, width: 2),
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.check, color: colors.onPrimary, size: 18)
                              : Text('${index + 1}', style: TextStyle(color: isActive ? colors.onPrimary : colors.onSurface, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stepLabels[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? colors.primary : colors.onSurface,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < stepLabels.length - 1)
                  SizedBox(
                    width: 20,
                    child: Divider(color: isCompleted ? colors.primary : colors.outlineVariant, thickness: 2),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme, ColorScheme colors, double sw) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Content(theme, colors);
      case 1:
        return _buildStep1Content(theme, colors);
      case 2:
        return _buildStep2Content(theme, colors);
      case 3:
        return _buildStep3Content(theme, colors);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _currentStep == 3 ? _proceedToPayment : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Text(_currentStep == 3 ? 'Proceed to Payment' : 'Continue'),
          ),
        ],
      ),
    );
  }
  Widget _buildStep0Content(ThemeData theme, ColorScheme colors) {
    return Form(
      key: _formKey0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Selection
          Text(
            'Selected AICERTS Courses',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...widget.courses.map((course) {
            final index = widget.courses.indexOf(course);
            return CheckboxListTile(
              value: _selectedCourses[index],
              onChanged: (value) {
                setState(() {
                  _selectedCourses[index] = value!;
                });
              },
              title: const SizedBox.shrink(), // Title is in the SVG image
              subtitle: Text('Stream: ${course.industry ?? 'N/A'}', style: theme.textTheme.bodySmall),
              secondary: SizedBox(
                width: 120,
                child: AICERTSCourseCardImage(
                  featureImageUrl: course.featureImageUrl,
                  certificateBadgeUrl: course.certificateBadgeUrl,
                  height: 60,
                  width: 100,
                  showBadge: false,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
          
          const SizedBox(height: 32),
          
          // Quantity Selection
          Text(
            'Number of Learners',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() => _quantity--);
                      while (_learners.length > _quantity) {
                        _learners.removeLast().dispose();
                      }
                    }
                  },
                ),
                const SizedBox(width: 24),
                Text(
                  _quantity.toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                ),
                const SizedBox(width: 24),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _quantity++;
                      if (_learners.length < _quantity) {
                        _learners.add(AicertsLearnerFormData());
                      }
                    });
                  },
                ),
                const Spacer(),
                Text(
                  'learner${_quantity > 1 ? 's' : ''} total',
                  style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Content(ThemeData theme, ColorScheme colors) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who is enrolling?',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnrollmentTypeCard(
                  icon: Icons.person,
                  title: 'Individual',
                  subtitle: 'For personal learning',
                  isSelected: !_isCorporate,
                  onTap: () => setState(() => _isCorporate = false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnrollmentTypeCard(
                  icon: Icons.business,
                  title: 'Corporate',
                  subtitle: 'For team training',
                  isSelected: _isCorporate,
                  onTap: () => setState(() => _isCorporate = true),
                ),
              ),
            ],
          ),
          if (_isCorporate) ...[
            const SizedBox(height: 32),
            _buildCorporateForm(),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2Content(ThemeData theme, ColorScheme colors) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Learner ${_currentLearnerIndex + 1} of $_quantity',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: colors.primary),
              ),
              if (_quantity > 1)
                Text(
                  'Profile ${_currentLearnerIndex + 1}/$_quantity',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLearnerForm(_learners[_currentLearnerIndex]),
        ],
      ),
    );
  }

  Widget _buildStep3Content(ThemeData theme, ColorScheme colors) {
    return Form(
      key: _formKey3,
      child: _buildReviewStep(),
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

  Widget _buildStreamCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Expanded(
      child: InkWell(
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
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
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

          // Tax/VAT Number
          TextFormField(
            controller: _companyTaxNumberController,
            decoration: const InputDecoration(
              labelText: 'Tax/VAT Number *',
              border: OutlineInputBorder(),
              hintText: 'Required for invoicing and tax purposes',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tax/VAT Number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Website (Optional)
          TextFormField(
            controller: _companyWebsiteController,
            decoration: const InputDecoration(
              labelText: 'Website (Optional)',
              border: OutlineInputBorder(),
              hintText: 'https://',
            ),
          ),
          const SizedBox(height: 24),

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

          // Additional Company Details Section
          Text(
            'Additional Company Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Industry (Optional)
          TextFormField(
            controller: _companyIndustryController,
            decoration: const InputDecoration(
              labelText: 'Industry (Optional)',
              border: OutlineInputBorder(),
              hintText: 'e.g., Technology, Finance, Healthcare',
            ),
          ),
          const SizedBox(height: 16),

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
            value: (_selectedPaymentTerms ?? '').isEmpty ? null : _selectedPaymentTerms,
            decoration: const InputDecoration(
              labelText: 'Payment Terms *',
              border: OutlineInputBorder(),
              hintText: 'Select payment terms',
            ),
            items: const [
              DropdownMenuItem(value: 'immediate', child: Text('Immediate Payment')),
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
          const SizedBox(height: 16),

          // Company Size Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCompanySize?.isEmpty ?? true ? null : _selectedCompanySize,
            decoration: const InputDecoration(
              labelText: 'Company Size',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '1-10', child: Text('1-10 employees')),
              DropdownMenuItem(value: '11-50', child: Text('11-50 employees')),
              DropdownMenuItem(value: '51-200', child: Text('51-200 employees')),
              DropdownMenuItem(value: '201-500', child: Text('201-500 employees')),
              DropdownMenuItem(value: '500+', child: Text('500+ employees')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCompanySize = value;
              });
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
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
            ),
            items: AfricanPhoneValidator.supportedCountries.map((iso) {
              final countryInfo =
                  AfricanPhoneValidator.getInfoForCountry(iso);
              return DropdownMenuItem<String>(
                value: iso,
                child: Row(
                  children: [
                    Image.network(
                      'https://flagcdn.com/w20/${iso.toLowerCase()}.png',
                      width: 20,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.flag, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(countryInfo?.countryCode ?? ''),
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

  int selectedCoursesCount() {
    return _selectedCourses.where((b) => b).length;
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currencySvc = CurrencyService.instance;
    final totalUSD = _calculateTotalPrice();
    final localizedTotal = currencySvc.convertFromUSD(totalUSD);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Final Review',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Please verify your enrollment details before proceeding to secure payment.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        
        // Selections Summary Card
        _buildReviewCard(
          title: 'Enrollment Selections',
          icon: Icons.list_alt_rounded,
          content: Column(
            children: [
              _buildReviewRow('Type', _isCorporate ? 'Corporate Enrollment' : 'Individual Enrollment'),
              _buildReviewRow('Total Learners', '$_quantity learner${_quantity > 1 ? 's' : ''}'),
              _buildReviewRow('Courses Selected', '${selectedCoursesCount()} AI Pathways'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cost Breakdown Card
        _buildReviewCard(
          title: 'Financial Summary',
          icon: Icons.receipt_long_rounded,
          content: Column(
            children: [
              ...widget.courses.asMap().entries.where((e) => _selectedCourses[e.key]).map((e) {
                final course = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            AICERTSCourseCardImage(
                              featureImageUrl: course.featureImageUrl,
                              height: 40,
                              width: 70,
                              showBadge: false,
                            ),
                            const SizedBox(width: 8),
                            // Title removed as requested (elaborately written in SVG)
                          ],
                        ),
                      ),
                      Text(
                        currencySvc.formatUSDAmount(course.price ?? 150.0),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(height: 24),
              _buildReviewRow('Subtotal (USD)', currencySvc.formatUSDAmount(totalUSD / _quantity)),
              _buildReviewRow('Total Reference (USD)', currencySvc.formatUSDAmount(totalUSD), isTotal: true),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'TOTAL DUE (${currencySvc.userCurrency})',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: colors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencySvc.formatPrice(localizedTotal),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: colors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (_isCorporate) ...[
          const SizedBox(height: 16),
          _buildReviewCard(
            title: 'Billing Information',
            icon: Icons.business_rounded,
            content: Column(
              children: [
                _buildReviewRow('Company', _companyNameController.text),
                _buildReviewRow('Reg No.', _companyRegistrationController.text),
                _buildReviewRow('VAT/Tax No.', _companyTaxNumberController.text),
                _buildReviewRow('Billing Email', _billingContactEmailController.text),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Secure checkout powered by Hosi Academy. Your data is protected.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard({required String title, required IconData icon, required Widget content}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: colors.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
