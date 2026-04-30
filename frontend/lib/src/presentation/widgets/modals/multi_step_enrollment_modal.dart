// lib/src/presentation/widgets/modals/multi_step_enrollment_modal.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/masterclass.dart';
import '../../../data/models/course.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/constants/pricing_constants.dart';
import '../../../core/utils/african_phone_validator.dart';
import '../../pages/payment/payment_provider_selection_page.dart';
import '../student_portal/cascading_location_dropdowns.dart';
import '../../blocs/student_portal/location_bloc.dart';
import '../../../data/models/location.dart' as location_models;
import '../../../data/models/promotion.dart';
import '../../../core/services/promotion_service.dart';
import '../contact_otp_field.dart';
import '../../../data/models/coupon.dart';
import '../payment/payment_otp_verification.dart';
// REMOVED: auth_service import - no longer pre-populating user data

class MultiStepEnrollmentModal extends StatefulWidget {
  final Masterclass? masterclass;
  final List<Course>? courses;
  final String? industry;
  final String? role;
  final VoidCallback? onEnrollmentComplete;

  const MultiStepEnrollmentModal({
    super.key,
    this.masterclass,
    this.courses,
    this.industry,
    this.role,
    this.onEnrollmentComplete,
    this.allowPrefill = true, // NEW: Control pre-population from profile
  }) : assert(masterclass != null || courses != null,
            'Either masterclass or courses must be provided');

  final bool
      allowPrefill; // NEW: If false, no pre-population from profile (for onboarding enrollments)

  @override
  State<MultiStepEnrollmentModal> createState() =>
      _MultiStepEnrollmentModalState();
}

class _MultiStepEnrollmentModalState extends State<MultiStepEnrollmentModal> {
  int _currentStep = 0;
  int _quantity = 1;
  bool _isCorporate = false;
  bool _isOnline = false;
  bool _isProcessing = false;
  Promotion? _activePromo; // Applied promo — persists through all payment steps
  CouponValidation? _activeCoupon; // Applied coupon code
  bool _isCouponValidating = false;
  String? _couponError;
  final TextEditingController _couponController = TextEditingController();

  String get _enrollmentType {
    if (widget.masterclass != null) return 'masterclass';
    if (widget.industry != null && widget.industry != 'all')
      return 'industry_training';
    if (widget.courses?.length == 1 &&
        widget.courses!.first.courseType == 'industry_training')
      return 'industry_training';
    return 'custom_selection';
  }

  final _formKey0 = GlobalKey<FormState>(); // Step 0 Form
  final _formKey1 = GlobalKey<FormState>(); // Step 1 Form
  final _formKey2 = GlobalKey<FormState>(); // Step 2 Form

  // Corporate controllers
  final _companyNameController = TextEditingController();
  final _companyRegistrationController = TextEditingController();
  final _companyTaxNumberController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyWebsiteController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPostalCodeController = TextEditingController();
  final _billingContactNameController = TextEditingController();
  final _billingContactEmailController = TextEditingController();
  final _billingContactPhoneController = TextEditingController();
  final _companyIndustryController = TextEditingController();

  // Company location
  location_models.Country? _selectedCompanyCountry;
  location_models.State? _selectedCompanyState;
  location_models.City? _selectedCompanyCity;
  String _companyPhoneIsoCode = 'ZA';
  String _billingContactPhoneIsoCode = 'ZA';

  String? _selectedCompanySize = '1-10';
  String? _selectedPaymentTerms = 'immediate';

  // Learners data
  List<LearnerFormData> _learners = [];
  int _currentLearnerIndex = 0;
  String? _prefillEmail; // skip duplicate-email check for the signed-in user

  @override
  void initState() {
    super.initState();
    CurrencyService.instance.initialize();
    CurrencyService.instance.addListener(_onCurrencyChanged);
    _learners.add(LearnerFormData());

    final initialIso = widget.masterclass?.countryCode ??
        (widget.courses?.isNotEmpty == true
            ? widget.courses![0].countryCode
            : null) ??
        'ZA';
    _companyPhoneIsoCode = initialIso;
    _billingContactPhoneIsoCode = initialIso;
    for (var learner in _learners) {
      learner.phoneIsoCode = initialIso;
      learner.emergencyPhoneIsoCode = initialIso;
    }

    _isOnline = false;
    if (widget.courses != null) _isOnline = true;

    // NEW: Only pre-fill from profile if allowPrefill is true
    // For onboarding enrollments (not from dashboard), allowPrefill should be false
    if (widget.allowPrefill) {
      _prefillFromProfile();
    }

    // Auto-apply AICERTS10 for AICERTS / Custom / Industry enrollments
    if (_enrollmentType == 'custom_selection' ||
        _enrollmentType == 'industry_training') {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _autoApplyCoupon('AICERTS10'));
    }
  }

  /// Silently validates and applies a coupon code without user interaction.
  Future<void> _autoApplyCoupon(String code) async {
    try {
      final response = await ApiClient.post(
        '/api/v1/payments/coupons/validate/',
        data: {
          'code': code,
          'amount': _baseAmount,
          'enrollment_type': _enrollmentType,
          'country': CurrencyService.instance.countryCode ?? 'ZA',
        },
      );
      final validation =
          CouponValidation.fromJson(response.data as Map<String, dynamic>);
      if (validation.valid && mounted) {
        setState(() {
          _activeCoupon = validation;
          _couponController.text = code;
        });
      }
    } catch (_) {
      // Silent fail — auto-apply is best-effort
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

        // Pre-fill location cascading dropdowns
        final countryId = p['country'] as int?;
        final stateId = p['state'] as int?;
        final cityId = p['city'] as int?;
        final countryName = p['country_name'] as String? ?? '';
        final stateName = p['state_name'] as String? ?? '';
        final cityName = p['city_name'] as String? ?? '';

        if (countryId != null && countryId > 0) {
          l.selectedCountry = location_models.Country(
              id: countryId, name: countryName, code: '');
          context.read<LocationBloc>().add(SelectCountry(l.selectedCountry!));
        }
        if (stateId != null && stateId > 0 && countryId != null) {
          l.selectedState = location_models.State(
              id: stateId, name: stateName, countryId: countryId);
          context.read<LocationBloc>().add(SelectState(l.selectedState!));
        }
        if (cityId != null && cityId > 0 && stateId != null) {
          l.selectedCity = location_models.City(
              id: cityId, name: cityName, stateId: stateId);
          context.read<LocationBloc>().add(SelectCity(l.selectedCity!));
        }
      }
      // Pre-fill company fields from profile history
      _fillString(_companyNameController, p['last_used_company_name']);
      _fillString(_companyEmailController, p['last_used_company_email']);
      _fillString(_companyPhoneController, p['last_used_company_phone']);
      _fillString(_companyAddressController, p['last_used_company_address']);
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Error pre-filling from profile: $e');
    }
  }

  void _fillString(TextEditingController ctrl, dynamic value) {
    final s = (value as String? ?? '').trim();
    if (s.isNotEmpty) ctrl.text = s;
  }

  /// Called after successful enrollment to cascade any changed data back to profile
  Future<void> _cascadeProfileUpdate(LearnerFormData l) async {
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

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyRegistrationController.dispose();
    _companyTaxNumberController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyWebsiteController.dispose();
    _companyAddressController.dispose();
    _companyPostalCodeController.dispose();
    _billingContactNameController.dispose();
    _billingContactEmailController.dispose();
    _billingContactPhoneController.dispose();
    _companyIndustryController.dispose();

    for (var learner in _learners) {
      learner.dispose();
    }

    _couponController.dispose();
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
          final isOwnEmail =
              _prefillEmail != null && email == _prefillEmail!.toLowerCase();
          if (!isOwnEmail) {
            final exists = await ApiClient.checkEmailExists(email);
            if (exists) {
              if (mounted) {
                _showError(
                    'Learner email "$email" is already registered. Please sign in or use a different email.');
              }
              setState(() => _isProcessing = false);
              return;
            }
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
    }
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
      case 0: // Quantity
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
          _learners.add(LearnerFormData());
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
          } else if (learner.selectedState == null) {
            _showError('State/Region is required');
          } else if (!learner.termsAccepted) {
            _showError('Please accept the terms and conditions');
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

  /// Show OTP dialog and return the payment token on success, null on cancel.
  Future<String?> _showOTPDialog({
    required String email,
    required double amount,
    required String currency,
    required String country,
  }) async {
    if (!mounted) return null;
    final completer = Completer<String?>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PaymentOTPVerification(
                email: email,
                amount: amount,
                currency: currency,
                country: country,
                onVerified: (token) {
                  Navigator.of(ctx).pop();
                  if (!completer.isCompleted) completer.complete(token);
                },
                onError: (error) {
                  // Dialog stays open so user can retry
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (!completer.isCompleted) completer.complete(null);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );

    return completer.future;
  }

  Future<void> _proceedToPayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final metadata = _collectAllFormData();

      final firstLearner = _learners.first;
      final programId = widget.masterclass?.id.toString() ??
          widget.courses?.map((c) => c.id).join(',') ??
          'custom_bundle';

      final finalAmount = _totalAmount;
      final currency = CurrencyService.instance.userCurrency;
      final country = _isCorporate
          ? (_selectedCompanyCountry?.code ?? 'ZA')
          : (_learners.first.selectedCountry?.code ?? 'ZA');
      final type = _enrollmentType;

      // Localized amount for the backend and display
      final localizedAmount = CurrencyService.instance.convertFromUSD(finalAmount);
      final displayAmount = localizedAmount;

      // 1. Minimal Metadata for Payment Intent (to create Order/User)
      final paymentMetadata = {
        'enrollment_type': type,
        'program_id': programId,
        'is_corporate': _isCorporate,
        'country': country,
        'currency': currency,
        'amount': localizedAmount, // Use localized amount
        'industry': widget.industry,
        'role': widget.role,
        if (_activeCoupon != null) ...{
          'coupon_code': _activeCoupon!.code,
          'coupon_id': _activeCoupon!.couponId,
          'discount_amount': _activeCoupon!.discountAmount,
        },
        // Backend needs email to find/create user
        if (_isCorporate)
          'corporate_details': {
            'contact_email': _companyEmailController.text.trim(),
            'company_name': _companyNameController.text.trim(),
          }
        else
          'individual_details': {
            'email': firstLearner.emailController.text.trim(),
            'first_name': firstLearner.firstNameController.text.trim(),
            'last_name': firstLearner.lastNameController.text.trim(),
            'full_name':
                '${firstLearner.firstNameController.text.trim()} ${firstLearner.lastNameController.text.trim()}',
          }
      };

      // 2. Full Payload for Enrollment Finalization (sent AFTER payment)
      final enrollmentPayload = {
        ...paymentMetadata, // Fixed from 'metadata'
        'enrollment_type': type,
        'program_id': programId,
        'is_corporate': _isCorporate,
        'country': country,
        'currency': currency,
        'amount': localizedAmount, // Use localized amount
        'amount_usd': finalAmount,   // Keep USD for reference
        'industry': widget.industry,
        'role': widget.role,
        if (_activeCoupon != null) ...{
          'coupon_code': _activeCoupon!.code,
          'coupon_id': _activeCoupon!.couponId,
          'discount_amount': _activeCoupon!.discountAmount,
        },
      };

      // OTP verification before payment removed per user request
      
      // Cascade form data back to student profile (best-effort)
      if (!_isCorporate && _learners.isNotEmpty) {
        await _cascadeProfileUpdate(_learners.first);
      }

      final response = await ApiClient.initiatePayment(
        programId: programId,
        type: type,
        amount: displayAmount,
        metadata: paymentMetadata,
      );

      if (!mounted) return;

      await PaymentProviderSelectionPage.show(
        context,
        reference: response['reference'] as String,
        amount: displayAmount,
        currency: currency,
        country: country,
        programId: programId,
        programType: type,
        paymentMetadata: paymentMetadata,
        enrollmentPayload: enrollmentPayload,
      );
    } catch (e) {
      if (mounted) {
        _showError('Failed to start payment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Get base amount using masterclass price based on attendance mode (online/physical)
  /// CRITICAL: Returns price in USD. Conversion to local currency happens in _proceedToPayment and formatting helpers.
  double get _baseAmount {
    if (widget.masterclass != null) {
      final mc = widget.masterclass!;
      if (_isOnline) {
        // Online mode: use priceOnlineUsd OR onlinePrice (localized)
        // If priceOnlineUsd is available, it's USD. If not, we use onlinePrice.
        final onlinePrice = mc.priceOnlineUsd ?? mc.onlinePrice;
        if (onlinePrice != null && onlinePrice > 0) {
          return onlinePrice;
        }
        // Fallback to constants if DB values are missing
        return PricingConstants.getMasterclassPrice(
          streamType: mc.streamType ?? 'professional',
          isOnline: true,
        );
      } else {
        // Physical mode: use pricePhysicalUsd OR physicalPrice (localized)
        final physicalPrice = mc.pricePhysicalUsd ?? mc.physicalPrice;
        if (physicalPrice != null && physicalPrice > 0) {
          return physicalPrice;
        }
        // Fallback to constants if DB values are missing
        return PricingConstants.getMasterclassPrice(
          streamType: mc.streamType ?? 'professional',
          isOnline: false,
        );
      }
    }

    // Custom selection or industry training
    return widget.courses?.fold<double>(0.0, (sum, c) {
          // Courses prices are in USD
          return sum + (c.price ?? 0.0);
        }) ??
        0.0;
  }

  /// Discounted base amount (applies coupon first, then promo if no coupon)
  double get _discountedBaseAmount {
    final base = _baseAmount;
    // Coupon takes priority
    if (_activeCoupon != null &&
        _activeCoupon!.valid &&
        _activeCoupon!.discountAmount != null) {
      return (base - _activeCoupon!.discountAmount!).clamp(0, double.infinity);
    }
    // Fallback: legacy promo
    if (_activePromo?.discountPercentage != null &&
        _activePromo!.discountPercentage! > 0) {
      return base * (1 - _activePromo!.discountPercentage! / 100);
    }
    return base;
  }

  /// Validate a coupon code against the backend
  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _isCouponValidating = true;
      _couponError = null;
    });
    try {
      final response = await ApiClient.post(
        '/api/v1/payments/coupons/validate/',
        data: {
          'code': code,
          'amount': _baseAmount,
          'enrollment_type': _enrollmentType,
          'country': CurrencyService.instance.countryCode ?? 'ZA',
          'email': _learners.isNotEmpty
              ? _learners.first.emailController.text.trim()
              : '',
        },
      );
      final validation =
          CouponValidation.fromJson(response.data as Map<String, dynamic>);
      setState(() {
        if (validation.valid) {
          _activeCoupon = validation;
          _activePromo = null; // coupon replaces promo
          _couponError = null;
        } else {
          _activeCoupon = null;
          _couponError = validation.message;
        }
      });
    } catch (e) {
      setState(() {
        _couponError = 'Could not validate coupon. Try again.';
      });
    } finally {
      setState(() => _isCouponValidating = false);
    }
  }

  /// Calculate total amount: discounted base × quantity
  double get _totalAmount {
    return _discountedBaseAmount * _quantity;
  }

  /// Get unit price label showing attendance mode
  String get _unitPriceLabel {
    return _isOnline
        ? 'Online Price per Participant'
        : 'Physical Price per Participant';
  }

  Future<void> _showPromoSheet() async {
    final promos = await PromotionService.instance.fetchForOnboarding(
      countryCode: CurrencyService.instance.countryCode,
    );
    if (!mounted) return;
    if (promos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No active promotions available right now.')),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        final w = MediaQuery.of(ctx).size.width;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Promotions',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 16),
              ...promos.map((p) {
                final isSelected = _activePromo?.id == p.id;
                Color bg = Colors.deepOrange;
                try {
                  final h = p.backgroundColor.replaceAll('#', '');
                  bg = Color(int.parse('FF$h', radix: 16));
                } catch (_) {}
                return GestureDetector(
                  onTap: () {
                    setState(() => _activePromo = isSelected ? null : p);
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primaryContainer
                          : colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? colors.primary : colors.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(p.icon.isNotEmpty ? p.icon : '🎉',
                              style: TextStyle(fontSize: (w * 0.05).clamp(16.0, 22.0))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: (w * 0.037).clamp(12.0, 15.0))),
                              if (p.discountPercentage != null)
                                Text(
                                  '${p.discountPercentage!.toStringAsFixed(0)}% off your total',
                                  style: TextStyle(
                                      color: colors.primary,
                                      fontSize: (w * 0.033).clamp(11.0, 13.0),
                                      fontWeight: FontWeight.w600),
                                ),
                              Text(p.description,
                                  style: TextStyle(
                                      color: colors.onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: (w * 0.03).clamp(10.0, 12.0)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              color: colors.primary),
                      ],
                    ),
                  ),
                );
              }),
              if (_activePromo != null)
                TextButton(
                  onPressed: () {
                    setState(() => _activePromo = null);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Remove Promo'),
                ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _collectAllFormData() {
    final learners = _learners.map((learner) {
      return {
        'first_name': learner.firstNameController.text.trim(),
        'last_name': learner.lastNameController.text.trim(),
        'full_name':
            '${learner.firstNameController.text.trim()} ${learner.lastNameController.text.trim()}',
        'email': learner.emailController.text.trim(),
        'phone': AfricanPhoneValidator.formatWithCountryCode(
            learner.phoneController.text.trim(), learner.phoneIsoCode),
        'id_number': learner.idNumberController.text.trim(),
        'dob': learner.dobController.text.trim(),
        'gender': learner.selectedGender,
        'address': learner.addressController.text.trim(),
        'state': learner.selectedState?.name,
        'city':
            learner.selectedCity?.name ?? learner.cityController.text.trim(),
        'country': learner.selectedCountry?.name ?? learner.selectedCountryName,
        'country_code': learner.selectedCountry?.code,
        'postal_code': learner.postalCodeController.text.trim(),
        'occupation': learner.occupationController.text.trim(),
        'education_level': learner.selectedEducationLevel,
        'institution': learner.institutionController.text.trim(),
        'emergency_contact_name': learner.emergencyNameController.text.trim(),
        'emergency_contact_phone': AfricanPhoneValidator.formatWithCountryCode(
            learner.emergencyPhoneController.text.trim(),
            learner.emergencyPhoneIsoCode),
        'emergency_contact_relationship': learner.selectedEmergencyRelationship,
        'dietary_requirements': learner.dietaryController.text.trim().isEmpty
            ? 'n/a'
            : learner.dietaryController.text.trim(),
        'accessibility_needs':
            learner.accessibilityController.text.trim().isEmpty
                ? 'n/a'
                : learner.accessibilityController.text.trim(),
        'additional_notes': learner.notesController.text.trim().isEmpty
            ? 'n/a'
            : learner.notesController.text.trim(),
        'terms_accepted': learner.termsAccepted,
      };
    }).toList();

    final baseAmountUsd = _baseAmount;
    final discountAmountUsd = _activeCoupon?.discountAmount ?? 0.0;
    final discountedBaseUsd =
        (baseAmountUsd - discountAmountUsd).clamp(0.0, double.infinity);

    // Convert to user's currency for the payload
    final localizedBase = CurrencyService.instance.convertFromUSD(discountedBaseUsd);

    final data = {
      'quantity': _quantity,
      'is_corporate': _isCorporate,
      'attendance_mode': _isOnline ? 'online' : 'physical',
      'learners': learners,
      'currency': CurrencyService.instance.userCurrency,
      'original_amount_usd': baseAmountUsd,
      'discount_amount_usd': discountAmountUsd,
      'final_price_per_unit_usd': discountedBaseUsd,
      'total_amount_usd': discountedBaseUsd * _quantity,
      'final_price_per_unit': localizedBase, // Localized
      'total_amount': localizedBase * _quantity, // Localized
      if (_activeCoupon != null) ...{
        'coupon_code': _activeCoupon!.code,
        'coupon_id': _activeCoupon!.couponId,
      },
    };

    if (_isCorporate) {
      data['company'] = {
        'name': _companyNameController.text.trim(),
        'registration_number': _companyRegistrationController.text.trim(),
        'tax_number': _companyTaxNumberController.text.trim(),
        'email': _companyEmailController.text.trim(),
        'phone': _companyPhoneController.text.trim(),
        'website': _companyWebsiteController.text.trim(),
        'address': _companyAddressController.text.trim(),
        'state': _selectedCompanyState?.name,
        'city': _selectedCompanyCity?.name,
        'country': _selectedCompanyCountry?.name,
        'country_code': _selectedCompanyCountry?.code,
        'postal_code': _companyPostalCodeController.text.trim(),
        'billing_contact_name': _billingContactNameController.text.trim(),
        'billing_contact_email': _billingContactEmailController.text.trim(),
        'billing_contact_phone': _billingContactPhoneController.text.trim(),
        'industry': _companyIndustryController.text.trim(),
        'company_size': _selectedCompanySize,
        'payment_terms': _selectedPaymentTerms,
      };
    }

    return data;
  }

  Future<void> _selectDate(
      BuildContext context, LearnerFormData learner) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        learner.dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final mq = MediaQuery.of(context);
    final keyboardH = mq.viewInsets.bottom;
    final sw = mq.size.width;
    final sh = mq.size.height;
    final hInset = sw < 380 ? 6.0 : (sw < 600 ? 10.0 : 16.0);

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: EdgeInsets.fromLTRB(hInset, 16, hInset, keyboardH + 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: sh - keyboardH - 40,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: colors.outline.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            children: [
              _buildHeader(colors),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final hPad = (w * 0.05).clamp(10.0, 24.0);
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 20),
                      child: _buildStepContent(colors, w),
                    );
                  },
                ),
              ),
              _buildNavigationButtons(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    final steps = ['Details', 'Type', 'Learner Info', 'Review'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back arrow — steps back or closes on step 0
              IconButton(
                onPressed: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: _currentStep > 0 ? 'Back' : 'Close',
                color: colors.onSurface,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.masterclass != null
                          ? 'Enroll in ${widget.masterclass!.title}'
                          : 'Enroll in Course Bundle (${widget.courses!.length} items)',
                      style: TextStyle(
                        fontSize: (MediaQuery.of(context).size.width * 0.048)
                            .clamp(14.0, 20.0),
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Step ${_currentStep + 1} of ${steps.length}',
                      style: TextStyle(
                        fontSize: (MediaQuery.of(context).size.width * 0.034)
                            .clamp(11.0, 14.0),
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < steps.length - 1) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(ColorScheme colors, double w) {
    switch (_currentStep) {
      case 0:
        return Form(key: _formKey0, child: _buildQuantityStep(colors, w));
      case 1:
        return Form(key: _formKey1, child: _buildEnrollmentTypeStep(colors, w));
      case 2:
        return Form(key: _formKey2, child: _buildLearnerInfoStep(colors, w));
      case 3:
        return _buildReviewStep(colors, w);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuantityStep(ColorScheme colors, double w) {
    final isCustomSelection = widget.courses != null;
    final streamType = widget.masterclass?.streamType ??
        (widget.courses?.isNotEmpty == true
            ? (widget.courses!.first.industry ?? 'professional')
            : 'professional');
    final isTechnical = streamType == 'technical';

    // Get prices based on course type with robust fallbacks
    final double onlinePrice;
    final double physicalPrice;

    if (widget.masterclass != null) {
      final mc = widget.masterclass!;
      // Use the same strict logic as _baseAmount - no fallback to priceUsd
      onlinePrice = mc.priceOnlineUsd ?? mc.onlinePrice ?? 
          PricingConstants.getMasterclassPrice(streamType: streamType, isOnline: true);
      physicalPrice = mc.pricePhysicalUsd ?? mc.physicalPrice ?? 
          PricingConstants.getMasterclassPrice(streamType: streamType, isOnline: false);
    } else if (widget.courses != null) {
      // Calculate total for custom selection with robust fallbacks per course
      onlinePrice = widget.courses!.fold<double>(0.0, (sum, c) {
        final stream = (c.streamType ?? c.industry ?? 'professional').toLowerCase();
        final effectivePrice = (c.price == null || c.price == 0.0)
            ? PricingConstants.getAICertsPrice(streamType: stream)
            : c.price!;
        return sum + effectivePrice;
      });
      physicalPrice = 0.0; // Courses are online only for custom selection
    } else {
      onlinePrice = 0.0;
      physicalPrice = 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.masterclass != null)
          _buildMasterclassInfoCard(colors, w)
        else
          _buildCoursesInfoCard(colors, w),
        const SizedBox(height: 24),

        // Attendance Mode Selection with Costs
        Card(
          child: Padding(
            padding: EdgeInsets.all((w * 0.054).clamp(12.0, 20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Attendance Mode',
                  style: TextStyle(
                    fontSize: (w * 0.052).clamp(13.0, 18.0),
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCustomSelection
                      ? 'Choose how you want to attend this ${isTechnical ? 'Technical' : 'Professional'} course.'
                      : 'Choose how you want to attend this ${isTechnical ? 'Technical' : 'Professional'} masterclass.',
                  style: TextStyle(
                    fontSize: (w * 0.038).clamp(11.0, 14.0),
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),

                // Online vs Physical buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildAttendanceModeButton(
                        title: 'Online',
                        icon: Icons.laptop,
                        subtitle: isCustomSelection
                            ? 'Self-paced online learning'
                            : 'Live virtual classes',
                        price: onlinePrice,
                        isSelected: _isOnline,
                        onTap: () => setState(() => _isOnline = true),
                        colors: colors,
                        w: w,
                      ),
                    ),
                    // Only show Physical option for masterclasses (not custom selection)
                    if (!isCustomSelection &&
                        (widget.masterclass?.hasOnlineOption ?? true)) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAttendanceModeButton(
                          title: 'Physical',
                          icon: Icons.apartment,
                          subtitle: 'In-person at venue',
                          price: physicalPrice,
                          isSelected: !_isOnline,
                          onTap: () => setState(() => _isOnline = false),
                          colors: colors,
                          w: w,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: colors.outline.withValues(alpha: 0.3)),
                const SizedBox(height: 12),

                // Selected option summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected:',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              '${_isOnline ? 'Online' : 'Physical'} - ${isTechnical ? 'Technical' : 'Professional'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _unitPriceLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            CurrencyService.instance
                                .formatUSDAmount(_baseAmount),
                            style: TextStyle(
                              fontSize: (w * 0.05).clamp(12.0, 18.0),
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Coupon Code Input ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏷️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Have a coupon code?',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: colors.onSurface)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter code (e.g. BLACKFRI30)',
                        hintStyle: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.4),
                            fontSize: 13),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: colors.outline.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: colors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: colors.surface,
                        suffixIcon: _activeCoupon != null
                            ? GestureDetector(
                                onTap: () => setState(() {
                                  _activeCoupon = null;
                                  _couponController.clear();
                                  _couponError = null;
                                }),
                                child: const Icon(Icons.close_rounded,
                                    size: 18, color: Colors.grey),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _validateCoupon(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isCouponValidating ? null : _validateCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isCouponValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text('Apply',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              // Error message
              if (_couponError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 14, color: colors.error),
                    const SizedBox(width: 6),
                    Text(_couponError!,
                        style: TextStyle(color: colors.error, fontSize: 12)),
                  ],
                ),
              ],
              // Success banner
              if (_activeCoupon != null && _activeCoupon!.valid) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_activeCoupon!.name} — ${_activeCoupon!.summaryLabel}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.green.shade800),
                            ),
                            if (_activeCoupon!.daysRemaining != null &&
                                _activeCoupon!.daysRemaining! > 0)
                              Text(
                                'Expires in ${_activeCoupon!.daysRemaining} day(s)',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.green.shade600),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quantity Selection
        Card(
          child: Padding(
            padding: EdgeInsets.all((w * 0.054).clamp(12.0, 20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number of Participants',
                  style: TextStyle(
                    fontSize: (w * 0.052).clamp(13.0, 18.0),
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$_quantity',
                      style: TextStyle(
                        fontSize: (w * 0.09).clamp(20.0, 32.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurface,
                          ),
                        ),
                        if (_activeCoupon != null ||
                            _activePromo?.discountPercentage != null) ...[
                          // Strikethrough original price
                          Text(
                            CurrencyService.instance
                                .formatUSDAmount(_baseAmount * _quantity),
                            style: TextStyle(
                              fontSize: (w * 0.045).clamp(12.0, 16.0),
                              decoration: TextDecoration.lineThrough,
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        Text(
                            CurrencyService.instance
                                .formatUSDAmount(_totalAmount),
                          style: TextStyle(
                            fontSize: (w * 0.068).clamp(16.0, 24.0),
                            fontWeight: FontWeight.bold,
                            color: (_activeCoupon != null ||
                                    _activePromo?.discountPercentage != null)
                                ? Colors.green.shade700
                                : colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_quantity > 1) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$_unitPriceLabel: ${CurrencyService.instance.formatUSDAmount(_discountedBaseAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total for $_quantity participants: ${CurrencyService.instance.formatUSDAmount(_totalAmount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Attendance Mode Summary (read-only since already selected above)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isOnline ? Icons.laptop : Icons.apartment,
                      color: colors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Mode',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '${_isOnline ? 'Online' : 'Physical'} - ${isTechnical ? 'Technical' : 'Professional'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _unitPriceLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          CurrencyService.instance.formatUSDAmount(_baseAmount),
                          style: TextStyle(
                            fontSize: (w * 0.05).clamp(12.0, 18.0),
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.courses != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: colors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: Custom selection courses are online only.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceModeButton({
    required String title,
    required IconData icon,
    required String subtitle,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colors,
    required double w,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : colors.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.5),
                  size: (w * 0.065).clamp(18.0, 24.0),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colors.primary,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: (w * 0.040).clamp(12.0, 14.0),
                fontWeight: FontWeight.w600,
                color: isSelected ? colors.primary : colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: (w * 0.030).clamp(10.0, 11.0),
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyService.instance.formatUSDAmount(price),
                style: TextStyle(
                  fontSize: (w * 0.05).clamp(13.0, 18.0),
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colors.primary : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterclassInfoCard(ColorScheme colors, double w) {
    final mc = widget.masterclass;

    // Check if this is the $5 masterclass
    final isFiveDollarMasterclass = mc?.priceOnlineUsd != null &&
        (mc!.priceOnlineUsd! == 5.0 || mc.priceOnlineUsd! == 5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (mc?.streamType == 'professional')
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    mc!.streamType.toUpperCase(),
                    style: TextStyle(
                      color: mc.streamType == 'professional'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                // SPECIAL $5 BADGE
                if (isFiveDollarMasterclass)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_rounded,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'SPECIAL PRICE',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mc.title,
              style: TextStyle(
                fontSize: (w * 0.045).clamp(14.0, 18.0),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (mc.focusArea != null) ...[
              const SizedBox(height: 8),
              Text(
                mc.focusArea!,
                style: TextStyle(
                  fontSize: (w * 0.035).clamp(12.0, 14.0),
                  color: colors.onSurface,
                ),
              ),
            ],
            // SPECIAL $5 PRICE DISPLAY
            if (isFiveDollarMasterclass) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.2),
                      Colors.orange.withValues(alpha: 0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration_rounded,
                        color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'ONLY \$5 USD',
                      style: TextStyle(
                        fontSize: (w * 0.06).clamp(18.0, 24.0),
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.celebration_rounded,
                        color: Colors.amber, size: 24),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (widget.masterclass != null &&
                    widget.masterclass!.startDate != null)
                  _buildInfoChip(
                    Icons.calendar_today,
                    DateFormat('dd MMM yyyy')
                        .format(widget.masterclass!.startDate!),
                  ),
                if (widget.masterclass != null &&
                    widget.masterclass!.city != null)
                  _buildInfoChip(
                    Icons.location_on,
                    '${widget.masterclass!.city}, ${widget.masterclass!.country ?? ""}',
                  ),
                if (widget.masterclass != null &&
                    widget.masterclass!.venue != null)
                  _buildInfoChip(Icons.business, widget.masterclass!.venue!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesInfoCard(ColorScheme colors, double w) {
    final totalCourses = widget.courses?.length ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'COURSE BUNDLE',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Custom Selection ($totalCourses Courses)',
              style: TextStyle(
                fontSize: (w * 0.045).clamp(14.0, 18.0),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.courses!.take(3).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.title,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
            if (totalCourses > 3)
              Text(
                '+ ${totalCourses - 3} more courses',
                style: TextStyle(fontSize: 12, color: colors.primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEnrollmentTypeStep(ColorScheme colors, double w) {
    return BlocProvider(
      create: (context) => LocationBloc(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Enrollment Type',
            style: TextStyle(
              fontSize: (w * 0.055).clamp(14.0, 20.0),
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTypeCard(
                  'Individual',
                  Icons.person,
                  'For individual learners',
                  !_isCorporate,
                  () => setState(() => _isCorporate = false),
                  colors,
                  w,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTypeCard(
                  'Corporate',
                  Icons.business,
                  'For company enrollments',
                  _isCorporate,
                  () => setState(() => _isCorporate = true),
                  colors,
                  w,
                ),
              ),
            ],
          ),
          if (_isCorporate) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all((w * 0.054).clamp(12.0, 20.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Information for Billing',
                      style: TextStyle(
                        fontSize: (w * 0.052).clamp(13.0, 18.0),
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyRegistrationController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildPhoneField(
                      controller: _companyPhoneController,
                      label: 'Company Phone *',
                      currentIso: _companyPhoneIsoCode,
                      onIsoChanged: (String newIso) {
                        setState(() => _companyPhoneIsoCode = newIso);
                      },
                      w: w,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyAddressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BlocProvider(
                      create: (context) => LocationBloc(),
                      child: CascadingLocationDropdowns(
                        key: const ValueKey('company_location_dropdown'),
                        initialCountry: _selectedCompanyCountry,
                        initialState: _selectedCompanyState,
                        initialCity: _selectedCompanyCity,
                        onLocationChanged: (country, state, city) {
                          setState(() {
                            _selectedCompanyCountry = country;
                            _selectedCompanyState = state;
                            _selectedCompanyCity = city;
                            if (country != null) {
                              _companyPhoneIsoCode = country.code;
                              _billingContactPhoneIsoCode = country.code;
                            }
                          });
                        },
                        isRequired: true,
                        countryLabel: 'Company Country *',
                        cityLabel: 'Company City',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyPostalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code *',
                        border: OutlineInputBorder(),
                        hintText: 'Required for invoicing',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyTaxNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Tax/VAT Number *',
                        border: OutlineInputBorder(),
                        hintText: 'Required for invoicing and tax purposes',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyWebsiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'https://',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Billing Contact Information',
                      style: TextStyle(
                        fontSize: (w * 0.046).clamp(12.0, 16.0),
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _billingContactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Billing Contact Name *',
                        border: OutlineInputBorder(),
                        hintText: 'Person responsible for invoices',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _billingContactEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Billing Contact Email *',
                        border: OutlineInputBorder(),
                        hintText: 'Email for invoice delivery',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPhoneField(
                      controller: _billingContactPhoneController,
                      label: 'Billing Contact Phone *',
                      currentIso: _billingContactPhoneIsoCode,
                      onIsoChanged: (String newIso) {
                        setState(() => _billingContactPhoneIsoCode = newIso);
                      },
                      w: w,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Additional Company Details',
                      style: TextStyle(
                        fontSize: (w * 0.046).clamp(12.0, 16.0),
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyIndustryController,
                      decoration: const InputDecoration(
                        labelText: 'Industry (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Technology, Finance, Healthcare',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('company_size_$_selectedCompanySize'),
                      value: (_selectedCompanySize ?? '').isEmpty
                          ? null
                          : _selectedCompanySize,
                      decoration: const InputDecoration(
                        labelText: 'Company Size',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: '1-10', child: Text('1-10 employees')),
                        DropdownMenuItem(
                            value: '11-50', child: Text('11-50 employees')),
                        DropdownMenuItem(
                            value: '51-200', child: Text('51-200 employees')),
                        DropdownMenuItem(
                            value: '201-500', child: Text('201-500 employees')),
                        DropdownMenuItem(
                            value: '500+', child: Text('500+ employees')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCompanySize = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('payment_terms_$_selectedPaymentTerms'),
                      value: (_selectedPaymentTerms ?? '').isEmpty
                          ? null
                          : _selectedPaymentTerms,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Payment Terms',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'immediate',
                            child: Text('Immediate Payment')),
                        DropdownMenuItem(
                            value: 'net7', child: Text('Net 7 Days')),
                        DropdownMenuItem(
                            value: 'net15', child: Text('Net 15 Days')),
                        DropdownMenuItem(
                            value: 'net30', child: Text('Net 30 Days')),
                        DropdownMenuItem(
                            value: 'net60', child: Text('Net 60 Days')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedPaymentTerms = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeCard(
    String title,
    IconData icon,
    String description,
    bool selected,
    VoidCallback onTap,
    ColorScheme colors,
    double w,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all((w * 0.054).clamp(12.0, 20.0)),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surface,
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: (w * 0.13).clamp(32.0, 48.0),
              color: selected ? colors.primary : colors.onSurface,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: (w * 0.052).clamp(13.0, 18.0),
                fontWeight: FontWeight.bold,
                color: selected ? colors.primary : colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (w * 0.034).clamp(11.0, 12.0),
                color: colors.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnerInfoStep(ColorScheme colors, double w) {
    final learner = _learners[_currentLearnerIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_quantity > 1) ...[
          Text(
            'Learner ${_currentLearnerIndex + 1} of $_quantity',
            style: TextStyle(
              fontSize: (w * 0.055).clamp(14.0, 20.0),
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: EdgeInsets.all((w * 0.054).clamp(12.0, 24.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First/Last name: side-by-side on wide screens, stacked on narrow
                if (w >= 360) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: learner.firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name *',
                            border: OutlineInputBorder(),
                            hintText: 'First name',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: learner.lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name *',
                            border: OutlineInputBorder(),
                            hintText: 'Last name',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Required';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextFormField(
                    controller: learner.firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                      hintText: 'First name',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: learner.lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                      hintText: 'Last name',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: learner.emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    border: OutlineInputBorder(),
                    hintText: 'your@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Required';
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Enter a valid email';
                    }
                    if (!learner.emailVerified)
                      return 'Please verify your email first';
                    return null;
                  },
                ),
                ContactOtpField(
                  contactController: learner.emailController,
                  contactType: 'email',
                  onVerifiedChanged: (verified) =>
                      setState(() => learner.emailVerified = verified),
                ),
                const SizedBox(height: 16),
                _buildPhoneField(
                  controller: learner.phoneController,
                  label: 'Phone Number *',
                  currentIso: learner.phoneIsoCode,
                  onIsoChanged: (String newIso) {
                    setState(() => learner.phoneIsoCode = newIso);
                  },
                  w: w,
                ),
                if (learner.emailVerified) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: learner.idNumberController,
                    decoration: const InputDecoration(
                      labelText: 'ID / Passport Number *',
                      border: OutlineInputBorder(),
                      hintText: 'Enter ID or passport number',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: learner.dobController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, learner),
                      ),
                    ),
                    readOnly: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                        'learner_gender_${_currentLearnerIndex}_${learner.selectedGender}'),
                    value: (learner.selectedGender ?? '').isEmpty
                        ? null
                        : learner.selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                      DropdownMenuItem(
                        value: 'Prefer not to say',
                        child: Text('Prefer not to say'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => learner.selectedGender = value);
                    },
                    validator: (val) {
                      if (val == null) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  BlocProvider(
                    key:
                        ValueKey('learner_location_bloc_$_currentLearnerIndex'),
                    create: (context) => LocationBloc(),
                    child: CascadingLocationDropdowns(
                      key: ValueKey('learner_location_$_currentLearnerIndex'),
                      initialCountry: learner.selectedCountry,
                      initialState: learner.selectedState,
                      initialCity: learner.selectedCity,
                      onLocationChanged: (country, state, city) {
                        setState(() {
                          learner.selectedCountry = country;
                          learner.selectedState = state;
                          learner.selectedCity = city;
                          learner.selectedCountryName = country?.name;
                          if (country != null) {
                            learner.phoneIsoCode = country.code;
                            learner.emergencyPhoneIsoCode = country.code;
                          }
                        });
                        // Persist location change
                        final programId = widget.masterclass?.id ?? 0;
                        learner.saveToStorage('enrollment_progress_${programId}_$_currentLearnerIndex');
                      },
                      isRequired: true,
                      countryLabel: 'Country *',
                      cityLabel: 'City',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: learner.addressController,
                    decoration: const InputDecoration(
                      labelText: 'Physical Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: learner.postalCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postal Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: learner.occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Occupation / Job Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                        'learner_edu_${_currentLearnerIndex}_${learner.selectedEducationLevel}'),
                    value: (learner.selectedEducationLevel ?? '').isEmpty
                        ? null
                        : learner.selectedEducationLevel,
                    decoration: const InputDecoration(
                      labelText: 'Highest Education Level',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'High School',
                        child: Text('High School'),
                      ),
                      DropdownMenuItem(
                          value: 'Diploma', child: Text('Diploma')),
                      DropdownMenuItem(
                        value: 'Bachelor’s Degree',
                        child: Text('Bachelor’s Degree'),
                      ),
                      DropdownMenuItem(
                        value: 'Honours Degree',
                        child: Text('Honours Degree'),
                      ),
                      DropdownMenuItem(
                        value: 'Master’s Degree',
                        child: Text('Master’s Degree'),
                      ),
                      DropdownMenuItem(value: 'PhD', child: Text('PhD')),
                    ],
                    onChanged: (value) {
                      setState(() => learner.selectedEducationLevel = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: learner.institutionController,
                    decoration: const InputDecoration(
                      labelText: 'Institution (if applicable)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Emergency Contact',
                    style: TextStyle(
                      fontSize: (w * 0.046).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: learner.emergencyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPhoneField(
                    controller: learner.emergencyPhoneController,
                    label: 'Emergency Contact Phone *',
                    currentIso: learner.emergencyPhoneIsoCode,
                    onIsoChanged: (String newIso) {
                      setState(() => learner.emergencyPhoneIsoCode = newIso);
                    },
                    w: w,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                        'learner_rel_${_currentLearnerIndex}_${learner.selectedEmergencyRelationship}'),
                    value: (learner.selectedEmergencyRelationship ?? '').isEmpty
                        ? null
                        : learner.selectedEmergencyRelationship,
                    decoration: const InputDecoration(
                      labelText: 'Relationship to Emergency Contact',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                      DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                      DropdownMenuItem(
                          value: 'Sibling', child: Text('Sibling')),
                      DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                      DropdownMenuItem(
                          value: 'Colleague', child: Text('Colleague')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(
                        () => learner.selectedEmergencyRelationship = value,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: learner.dietaryController,
                    decoration: const InputDecoration(
                      labelText: 'Dietary Requirements (if any)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: learner.accessibilityController,
                    decoration: const InputDecoration(
                      labelText: 'Accessibility / Special Needs',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: learner.notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: learner.termsAccepted,
                        onChanged: (value) {
                          setState(() {
                            learner.termsAccepted = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'I accept the terms and conditions and privacy policy',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildContactsLockedNotice(colors, learner),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsLockedNotice(
      ColorScheme colors, LearnerFormData learner) {
    final emailDone = learner.emailVerified;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: colors.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your email address to continue',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: colors.onSurface),
                ),
                const SizedBox(height: 4),
                if (!emailDone)
                  Text('• Email address not yet verified',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(ColorScheme colors, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Enrollment',
          style: TextStyle(
            fontSize: (w * 0.055).clamp(14.0, 20.0),
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enrollment Summary',
                  style: TextStyle(
                    fontSize: (w * 0.052).clamp(13.0, 18.0),
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const Divider(),
                _buildReviewRow(
                    'Program',
                    widget.masterclass?.title ??
                        'Course Bundle (${widget.courses?.length ?? 0} items)'),
                _buildReviewRow('Participants', '$_quantity'),
                _buildReviewRow(
                  'Total Amount',
                  CurrencyService.instance.formatUSDAmount(_totalAmount),
                ),
                const SizedBox(height: 16),
                Text(
                  _isCorporate
                      ? 'Corporate Enrollment'
                      : 'Individual Enrollment',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_isCorporate) ...[
                  const Divider(),
                  _buildReviewRow('Company', _companyNameController.text),
                  _buildReviewRow(
                    'Country',
                    _selectedCompanyCountry?.name ?? '—',
                  ),
                  _buildReviewRow(
                    'Billing Contact',
                    _billingContactNameController.text,
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Learners:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ..._learners.asMap().entries.map((entry) {
                  final index = entry.key;
                  final learner = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${index + 1}. ${learner.firstNameController.text} ${learner.lastNameController.text} (${learner.emailController.text})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ✅ NEW: Business Rules for Provisional Enrollment (Cash/EFT)
        if (widget.masterclass != null)
          Card(
            color: colors.primaryContainer.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: colors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Masterclass Enrollment Rules',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRuleRow(colors, 'Provisional Booking', 'Your booking is provisional until payment is confirmed.'),
                  _buildRuleRow(colors, 'Payment Deadline', 'Payment must be settled within 14 days or at least 3 days before the Masterclass start date.'),
                  _buildRuleRow(colors, 'Payment Methods', 'We accept Cash, POS/Swipe, or EFT at our physical offices.'),
                  _buildRuleRow(colors, 'Reference Code', 'A unique reference code will be generated for your visit to our office.'),
                  _buildRuleRow(colors, 'Confirmation', 'Full enrollment access will be granted immediately after payment settlement.'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRuleRow(ColorScheme colors, String label, String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: colors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: colors.onSurface),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: rule),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ColorScheme colors) {
    final sw = MediaQuery.of(context).size.width;
    final isNarrow = sw < 400;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12 : 20,
        vertical: isNarrow ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _previousStep,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 10 : 16,
                  vertical: isNarrow ? 10 : 12,
                ),
              ),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: _isProcessing
                ? null
                : (_currentStep == 3 ? _proceedToPayment : _nextStep),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(isNarrow ? 100 : 120, isNarrow ? 42 : 48),
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 16,
                vertical: isNarrow ? 10 : 12,
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _currentStep == 3 ? 'Proceed to Payment' : 'Next',
                      maxLines: 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required String label,
    required String currentIso,
    required Function(String) onIsoChanged,
    double w = 400,
  }) {
    final colors = Theme.of(context).colorScheme;
    final validatorCountries =
        AfricanPhoneValidator.africanPhoneInfo.keys.toList();
    final info = AfricanPhoneValidator.getInfoForCountry(currentIso);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: (w * 0.30).clamp(90.0, 130.0),
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentIso,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: validatorCountries.map((iso) {
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
              counterText: "", // Hide counter
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
}

class LearnerFormData {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  String phoneIsoCode = 'ZA';
  String? formattedPhoneNumber;
  bool isPhoneValid = false;
  bool emailVerified = false;
  bool phoneVerified = true;

  // ✅ REMOVED: isExistingStudent - NO MORE "ENROLLING AS" CRAP
  // All users manually enter their details - no assumptions

  final idNumberController = TextEditingController();
  final dobController = TextEditingController();
  String? selectedGender;

  final addressController = TextEditingController();
  final postalCodeController = TextEditingController();
  final cityController = TextEditingController();

  location_models.Country? selectedCountry;
  location_models.State? selectedState;
  location_models.City? selectedCity;
  String? selectedCountryName;

  final occupationController = TextEditingController();
  String? selectedEducationLevel;
  final institutionController = TextEditingController();

  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  String emergencyPhoneIsoCode = 'ZA';
  String? formattedEmergencyPhone;
  bool isEmergencyPhoneValid = false;

  String? selectedEmergencyRelationship;

  final dietaryController = TextEditingController(text: 'n/a');
  final accessibilityController = TextEditingController(text: 'n/a');
  final notesController = TextEditingController(text: 'n/a');

  bool termsAccepted = false;

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    idNumberController.dispose();
    dobController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    cityController.dispose();
    occupationController.dispose();
    institutionController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    dietaryController.dispose();
    accessibilityController.dispose();
    notesController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'phoneIsoCode': phoneIsoCode,
      'idNumber': idNumberController.text,
      'dob': dobController.text,
      'gender': selectedGender,
      'address': addressController.text,
      'postalCode': postalCodeController.text,
      'occupation': occupationController.text,
      'education': selectedEducationLevel,
      'institution': institutionController.text,
      'country': selectedCountry?.toJson(),
      'state': selectedState?.toJson(),
      'city': selectedCity?.toJson(),
      'emailVerified': emailVerified,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    firstNameController.text = json['firstName'] ?? '';
    lastNameController.text = json['lastName'] ?? '';
    emailController.text = json['email'] ?? '';
    phoneController.text = json['phone'] ?? '';
    phoneIsoCode = json['phoneIsoCode'] ?? 'ZA';
    idNumberController.text = json['idNumber'] ?? '';
    dobController.text = json['dob'] ?? '';
    selectedGender = json['gender'];
    addressController.text = json['address'] ?? '';
    postalCodeController.text = json['postalCode'] ?? '';
    occupationController.text = json['occupation'] ?? '';
    selectedEducationLevel = json['education'];
    institutionController.text = json['institution'] ?? '';
    emailVerified = json['emailVerified'] ?? false;
    
    if (json['country'] != null) {
      selectedCountry = location_models.Country.fromJson(json['country']);
    }
    if (json['state'] != null) {
      selectedState = location_models.State.fromJson(json['state']);
    }
    if (json['city'] != null) {
      selectedCity = location_models.City.fromJson(json['city']);
    }
  }

  Future<void> saveToStorage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(toJson()));
  }

  Future<void> loadFromStorage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data != null) {
      fromJson(jsonDecode(data));
    }
  }

  bool validate() {
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty) return false;
    if (emailController.text.trim().isEmpty) return false;
    if (phoneController.text.trim().isEmpty) return false;

    // Digit length validation
    final info = AfricanPhoneValidator.getInfoForCountry(phoneIsoCode);
    if (info != null) {
      final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < info.minDigits || digits.length > info.maxDigits)
        return false;
    }

    if (!emailVerified) return false;
    if (idNumberController.text.trim().isEmpty) return false;
    if (dobController.text.trim().isEmpty) return false;
    if (selectedGender == null) return false;
    if (selectedCountry == null) return false;
    if (selectedState == null) return false;
    if (!termsAccepted) return false;

    return true;
  }
}
