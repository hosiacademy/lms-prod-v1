// lib/src/presentation/widgets/modals/multi_step_learnership_enrollment_modal.dart
//
// CORRECT Learnership Enrollment Pathway
//
// Business Logic:
// 1. Individual Enrollment:
//    - Learner completes full enrollment form
//    - Uploads prerequisite evidence
//    - Pays initial deposit or full amount
//    - Enrollment goes to admin review
//
// 2. Corporate Enrollment:
//    - Company enters ONLY: name + email for each learner
//    - System sends email invitation links to learners
//    - Learners click link to complete their own enrollment
//    - Company pays deposit for all learners
//    - Each learner uploads their own evidence
//    - Admin reviews each learner separately

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/learnership.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/constants/pricing_constants.dart';
import '../../../core/utils/african_phone_validator.dart';
import '../../blocs/student_portal/location_bloc.dart';
import '../../widgets/student_portal/cascading_location_dropdowns.dart';
import '../../widgets/enrollment/company_enrollment_form.dart';
import '../../../data/models/location.dart' as location_models;
import '../../../data/models/coupon.dart';
import '../../pages/payment/payment_provider_selection_page.dart';
import '../contact_otp_field.dart';

class MultiStepLearnershipEnrollmentModal extends StatefulWidget {
  final Learnership learnership;
  final VoidCallback? onEnrollmentComplete;
  final bool allowPrefill; // NEW: Control pre-population from profile

  const MultiStepLearnershipEnrollmentModal({
    super.key,
    required this.learnership,
    this.onEnrollmentComplete,
    this.allowPrefill = true, // Default true for backward compatibility
  });

  @override
  State<MultiStepLearnershipEnrollmentModal> createState() =>
      _MultiStepLearnershipEnrollmentModalState();
}

class _MultiStepLearnershipEnrollmentModalState
    extends State<MultiStepLearnershipEnrollmentModal> {
  int _currentStep = 0;
  bool _isCorporate = false;
  bool _isSubmitting = false;
  bool _showFormErrors = false; // Highlight incomplete required fields

  // Payment option: 'upfront' or 'installments'
  String _paymentOption = 'upfront';

  // Coupon
  CouponValidation? _activeCoupon;
  String? _couponError;
  final TextEditingController _couponController = TextEditingController();
  bool _isCouponValidating = false;

  // Corporate data
  Map<String, dynamic>? _companyData;

  // Company location for auto-filling learner location
  Map<String, dynamic>? _companyLocation;

  // Individual learner data (for individual enrollment)
  final _individualLearnerData = LearnerFormData();

  // Corporate learners - ONLY name and email
  final List<CorporateLearnerData> _corporateLearners = [];

  // Uploaded evidence files (individual only)
  final List<EvidenceUploadData> _uploadedEvidence = [];

  String? _prefillEmail;

  @override
  void initState() {
    super.initState();
    _corporateLearners.add(CorporateLearnerData());

    if (widget.learnership.prerequisites != null &&
        widget.learnership.prerequisites!.isNotEmpty) {
      for (var prereq in widget.learnership.prerequisites!) {
        _uploadedEvidence.add(EvidenceUploadData(prerequisiteName: prereq));
      }
    }

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
      final l = _individualLearnerData;
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
      _fillString(l.bankNameController, p['bank_name']);
      _fillString(l.bankAccountNumberController, p['bank_account_number']);
      _fillString(l.bankBranchCodeController, p['bank_branch_code']);
      _fillString(l.bankAccountTypeController, p['bank_account_type']);
      _fillString(
          l.bankAccountHolderNameController, p['bank_account_holder_name']);
      if ((p['gender'] as String? ?? '').isNotEmpty)
        l.selectedGender = p['gender'] as String;
      if ((p['emergency_contact_relationship'] as String? ?? '').isNotEmpty)
        l.selectedEmergencyRelationship =
            p['emergency_contact_relationship'] as String;
      if ((p['highest_qualification'] as String? ?? '').isNotEmpty)
        l.selectedEducationLevel = p['highest_qualification'] as String;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _fillString(TextEditingController ctrl, dynamic value) {
    final s = (value as String? ?? '').trim();
    if (s.isNotEmpty) ctrl.text = s;
  }

  Future<void> _cascadeProfileUpdate() async {
    final l = _individualLearnerData;
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
    if (l.bankNameController.text.trim().isNotEmpty)
      data['bank_name'] = l.bankNameController.text.trim();
    if (l.bankAccountNumberController.text.trim().isNotEmpty)
      data['bank_account_number'] = l.bankAccountNumberController.text.trim();
    if (l.bankBranchCodeController.text.trim().isNotEmpty)
      data['bank_branch_code'] = l.bankBranchCodeController.text.trim();
    if (l.bankAccountTypeController.text.trim().isNotEmpty)
      data['bank_account_type'] = l.bankAccountTypeController.text.trim();
    if (l.bankAccountHolderNameController.text.trim().isNotEmpty)
      data['bank_account_holder_name'] =
          l.bankAccountHolderNameController.text.trim();
    if (data.isNotEmpty) await ApiClient.updateStudentProfile(data);
  }

  @override
  void dispose() {
    _individualLearnerData.dispose();
    for (var learner in _corporateLearners) {
      learner.dispose();
    }
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mq = MediaQuery.of(context);
    final keyboardH = mq.viewInsets.bottom;
    final sw = mq.size.width;
    final sh = mq.size.height;
    // Horizontal inset: tighter on small phones
    final hInset = sw < 380 ? 6.0 : (sw < 600 ? 10.0 : 16.0);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        // Bottom inset = keyboard height so dialog shifts above keyboard
        insetPadding: EdgeInsets.fromLTRB(hInset, 16, hInset, keyboardH + 8),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 900,
            // Shrink with keyboard so navigation buttons stay visible
            maxHeight: sh - keyboardH - 40,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildHeader(theme, colors),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildLearnershipInfoBanner(),
              ),
              const SizedBox(height: 12),
              _buildProgressIndicator(colors),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final hPad = (w * 0.05).clamp(10.0, 24.0);
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 20),
                      child: _buildStepContent(theme, colors, w),
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

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 8, top: 20, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + subtitle (matches Industry Training header layout)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learnership Enrollment',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.learnership.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Currency switcher chip
          ListenableBuilder(
            listenable: CurrencyService.instance,
            builder: (context, _) => PopupMenuButton<String>(
              tooltip: 'Change currency',
              onSelected: CurrencyService.instance.setCurrency,
              itemBuilder: (_) => [
                for (final c in ['USD', 'ZAR', 'EUR', 'GBP', 'NGN', 'KES'])
                  PopupMenuItem(value: c, child: Text(c)),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: Chip(
                  avatar: const Icon(Icons.currency_exchange, size: 16),
                  label: Text(CurrencyService.instance.currencyCode),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildLearnershipInfoBanner() {
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
                Icons.school_rounded,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Comprehensive Learnership Programme',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A structured work-based learning programme that leads to an NQF registered qualification. '
            'Designed to develop essential skills and practical experience.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colors) {
    final totalSteps = _isCorporate ? 4 : 5;
    final stepLabels = _isCorporate
        ? ['Type', 'Company', 'Learners', 'Payment']
        : [
            'Type',
            'Personal Info',
            'Prerequisites',
            'Payment Option',
            'Review'
          ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
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
                          color: isCompleted
                              ? colors.primary
                              : isActive
                                  ? colors.primary
                                  : colors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? colors.primary : colors.outline,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.check,
                                  color: colors.onPrimary, size: 18)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? colors.onPrimary
                                        : colors.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stepLabels[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? colors.primary : colors.onSurface,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index < totalSteps - 1)
                  SizedBox(
                    width: 16,
                    child: Container(
                      height: 2,
                      color: isCompleted && _currentStep > index + 1
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme, ColorScheme colors, double w) {
    if (_isCorporate) {
      // Corporate Enrollment Steps
      switch (_currentStep) {
        case 0:
          return _buildEnrollmentTypeSelection(theme, colors);
        case 1:
          return _buildCompanyForm(theme, colors);
        case 2:
          return _buildCorporateLearnersList(theme, colors);
        case 3:
          return _buildCorporatePaymentSelection(theme, colors);
        default:
          return const SizedBox.shrink();
      }
    } else {
      // Individual Enrollment Steps
      switch (_currentStep) {
        case 0:
          return _buildEnrollmentTypeSelection(theme, colors);
        case 1:
          return _buildIndividualLearnerInformation(theme, colors);
        case 2:
          return _buildPrerequisitesEvidenceUpload(theme, colors);
        case 3:
          return _buildPaymentOptionSelection(theme, colors);
        case 4:
          return _buildReviewAndSubmit(theme, colors);
        default:
          return const SizedBox.shrink();
      }
    }
  }

  // ============================================================================
  // STEP 0: Enrollment Type Selection (Common for both)
  // ============================================================================
  Widget _buildEnrollmentTypeSelection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enrollment Type',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select whether you are enrolling as an individual or on behalf of a company.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // Cost summary — shown from the very first step, reactive to currency changes
        ListenableBuilder(
          listenable: CurrencyService.instance,
          builder: (context, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payments_outlined,
                      color: colors.onPrimary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Programme Cost',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyService.instance
                            .formatPrice(_learnershipPrice),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
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
                      'Deposit from',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      CurrencyService.instance
                          .formatPrice(_learnershipPrice * 0.30),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildEnrollmentTypeCard(
          title: 'Individual Enrollment',
          subtitle: 'Enroll yourself in this learnership programme',
          icon: Icons.person,
          isSelected: !_isCorporate,
          onTap: () => setState(() => _isCorporate = false),
          colors: colors,
        ),
        const SizedBox(height: 16),
        _buildEnrollmentTypeCard(
          title: 'Corporate Enrollment',
          subtitle:
              'Enroll multiple employees - they will complete their own details via email',
          icon: Icons.business,
          isSelected: _isCorporate,
          onTap: () => setState(() => _isCorporate = true),
          colors: colors,
        ),
        if (_isCorporate) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How Corporate Enrollment Works',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1. Enter company details\n'
                        '2. Add learner names and emails only\n'
                        '3. Each learner receives an email link to complete their enrollment\n'
                        '4. Company pays deposit for all learners\n'
                        '5. Each learner uploads their own prerequisite evidence',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnrollmentTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer
              : colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? colors.onPrimary : colors.onSurface,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? colors.onPrimaryContainer.withValues(alpha: 0.7)
                          : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colors.primary, size: 28),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // CORPORATE ENROLLMENT STEPS
  // ============================================================================

  Widget _buildCompanyForm(ThemeData theme, ColorScheme colors) {
    return CompanyEnrollmentForm(
      programmeId: widget.learnership.id,
      programmeTitle: widget.learnership.title,
      onSubmit: (companyData) {
        setState(() {
          _companyData = companyData;

          // Extract and store company location for auto-filling learner forms
          _companyLocation = {
            'country_id': companyData['selected_country'],
            'state_id': companyData['selected_state'],
            'city_id': companyData['selected_city'],
            'country_code': companyData['country_code'],
          };

          _currentStep++;
        });
      },
      onCancel: () => setState(() => _currentStep--),
    );
  }

  Widget _buildCorporateLearnersList(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Learners',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the name and email address for each learner. They will receive an email link to complete their enrollment.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.email_outlined, color: colors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Each learner will receive an email with a secure link to complete their personal information, upload prerequisites, and select their payment option.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ..._corporateLearners.asMap().entries.map((entry) {
          final index = entry.key;
          final learner = entry.value;
          return _buildCorporateLearnerCard(learner, index, theme, colors);
        }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _corporateLearners.add(CorporateLearnerData());
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Another Learner'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildCorporateLearnerCard(
    CorporateLearnerData learner,
    int index,
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Learner ${index + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_corporateLearners.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colors.error),
                    onPressed: () {
                      setState(() {
                        _corporateLearners.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: learner.firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      hintText: 'Enter first name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: learner.lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      hintText: 'Enter last name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: learner.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                hintText: 'your@email.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorporatePaymentSelection(ThemeData theme, ColorScheme colors) {
    final depositAmount = _calculateDeposit();
    final totalAmount = _calculateTotalAmount();
    final monthlyInstallment = _calculateMonthlyInstallment();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Summary',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review the payment breakdown for all learners.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildCouponInput(colors),
        const SizedBox(height: 24),
        _buildLearnershipInfoCard(colors),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              _buildPaymentRow(
                'Total Programme Fee',
                CurrencyService.instance.formatPrice(totalAmount),
                colors,
              ),
              const SizedBox(height: 12),
              _buildPaymentRow(
                'Number of Learners',
                '${_corporateLearners.length}',
                colors,
              ),
              const SizedBox(height: 12),
              _buildPaymentRow(
                'Deposit Required (${_getDepositPercentage()}%)',
                CurrencyService.instance.formatPrice(depositAmount),
                colors,
                isBold: true,
              ),
              const Divider(height: 24),
              _buildPaymentRow(
                'Monthly Installment (per learner)',
                CurrencyService.instance.formatPrice(monthlyInstallment),
                colors,
              ),
              const SizedBox(height: 8),
              Text(
                'Billed monthly for ${widget.learnership.durationMonths} months',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Payment Process',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Pay the deposit amount now to secure enrollment\n'
                '2. Monthly installments will be billed automatically\n'
                '3. Each learner will select their payment method in their enrollment email',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // INDIVIDUAL ENROLLMENT STEPS
  // ============================================================================

  Widget _buildIndividualLearnerInformation(
      ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please provide complete information for your learnership enrollment.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        LearnerInformationForm(
          learnerData: _individualLearnerData,
          companyLocation: _isCorporate ? _companyLocation : null,
          showErrors: _showFormErrors,
        ),
      ],
    );
  }

  Widget _buildPrerequisitesEvidenceUpload(
      ThemeData theme, ColorScheme colors) {
    final prerequisites = widget.learnership.prerequisites ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prerequisites Evidence',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload documents to prove you meet the prerequisites for this learnership. '
          'Your enrollment will be confirmed after payment is honoured AND prerequisites are validated.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        if (prerequisites.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: colors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This learnership has no prerequisites. You can proceed to payment selection.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: colors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Required Prerequisites',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'This learnership requires the following prerequisites. Upload evidence for each:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  prerequisites.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            prerequisites[index],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...prerequisites.asMap().entries.map((entry) {
            final index = entry.key;
            final prereq = entry.value;
            return _buildEvidenceUploadCard(
              prereq,
              index,
              theme,
              colors,
            );
          }),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Review Process',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Upload evidence for all prerequisites\n'
                '2. Admin will review your documents\n'
                '3. You will be notified once prerequisites are validated\n'
                '4. Full enrollment requires both payment AND prerequisites validated',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceUploadCard(
    String prerequisite,
    int index,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final evidenceData = _uploadedEvidence[index];
    final isUploaded = evidenceData.isUploaded;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUploaded ? Icons.check_circle : Icons.upload_file,
                  color: isUploaded ? colors.primary : colors.onSurface,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prerequisite,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Upload evidence document',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isUploaded) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file,
                        color: colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        evidenceData.fileName ?? 'File uploaded',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: colors.error, size: 20),
                      onPressed: () {
                        setState(() {
                          evidenceData.filePath = null;
                          evidenceData.fileBytes = null;
                          evidenceData.fileName = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              TextField(
                controller: evidenceData.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Briefly describe this document',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _uploadEvidenceFile(index),
                icon: const Icon(Icons.attach_file),
                label: const Text('Upload Document'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _uploadEvidenceFile(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: true, // Required on web to get bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        setState(() {
          _uploadedEvidence[index].fileName = file.name;
          if (file.path != null) {
            // Mobile/desktop: path available
            _uploadedEvidence[index].filePath = file.path;
          } else if (file.bytes != null) {
            // Flutter Web: only bytes available
            _uploadedEvidence[index].fileBytes = file.bytes;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get learnership price - Prioritize dynamic value from model
  double get _learnershipPrice {
    return widget.learnership.calculatedPriceUsd;
  }

  /// Dollar discount from applied coupon (0 if none)
  double get _couponDiscountAmount {
    if (_activeCoupon == null || !_activeCoupon!.valid) return 0.0;
    return _activeCoupon!.discountAmount ?? 0.0;
  }

  /// Learnership price after coupon discount
  double get _discountedLearnershipPrice =>
      (_learnershipPrice - _couponDiscountAmount).clamp(0.0, double.infinity);

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
          'amount': _learnershipPrice,
          'enrollment_type': 'learnership',
          'country': CurrencyService.instance.countryCode ?? 'ZA',
          'email': _individualLearnerData.emailController.text.trim(),
        },
      );
      final validation =
          CouponValidation.fromJson(response.data as Map<String, dynamic>);
      setState(() {
        if (validation.valid) {
          _activeCoupon = validation;
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

  Widget _buildPaymentOptionSelection(ThemeData theme, ColorScheme colors) {
    // Coupon-aware amounts
    final totalAmount = _discountedLearnershipPrice;
    final depositAmount = _calculateDeposit();
    final monthlyInstallment = _calculateMonthlyInstallment();
    final adminFee = _calculateAdminFee();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Option',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you want to pay for your learnership. Your enrollment will be confirmed once payment is honoured AND prerequisites are validated.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        _buildLearnershipInfoCard(colors),
        const SizedBox(height: 16),
        _buildCouponInput(colors),
        const SizedBox(height: 24),
        // Option 1: Full Upfront Payment
        _buildPaymentOptionCard(
          title: 'Pay in Full',
          subtitle: 'One-time payment',
          icon: Icons.account_balance_wallet,
          isSelected: _paymentOption == 'upfront',
          onTap: () {
            setState(() => _paymentOption = 'upfront');
            _fetchPaymentPlan();
          },
          colors: colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CurrencyService.instance.formatPrice(totalAmount),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Full payment before course start',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Option 2: Deposit + Debit Order
        _buildPaymentOptionCard(
          title: 'Deposit + Monthly Debit Order',
          subtitle: 'Pay over the duration of the learnership',
          icon: Icons.calendar_month,
          isSelected: _paymentOption == 'installments',
          onTap: () {
            setState(() => _paymentOption = 'installments');
            _fetchPaymentPlan();
          },
          colors: colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Fee',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        CurrencyService.instance.formatPrice(adminFee),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.add, size: 16, color: colors.onSurface),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deposit',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        CurrencyService.instance.formatPrice(depositAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.add, size: 16, color: colors.onSurface),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        CurrencyService.instance
                            .formatUSDAmount(monthlyInstallment),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '× ${widget.learnership.durationMonths} months (debit order)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Total: ${CurrencyService.instance.formatPrice(adminFee + depositAmount + (monthlyInstallment * (widget.learnership.durationMonths ?? 12)))}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Option 3: Cash at Office
        _buildPaymentOptionCard(
          title: 'Pay Cash at Office',
          subtitle: 'Make payment at our office within 14 days',
          icon: Icons.payments,
          isSelected: _paymentOption == 'cash',
          onTap: () {
            setState(() => _paymentOption = 'cash');
            _fetchPaymentPlan();
          },
          colors: colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CurrencyService.instance.formatPrice(totalAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Payment due within 14 days at our office',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: colors.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enrollment remains provisional until cash payment is received',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Payment & Enrollment Terms',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _paymentOption == 'upfront'
                    ? 'Full payment is due before the learnership start date. You can upload prerequisites while payment is being processed.'
                    : _paymentOption == 'cash'
                        ? 'You have 14 days to make payment at our office. Your enrollment will be provisional until payment is received. You can upload prerequisites during this period.'
                        : 'Admin fee and deposit are due now. A debit order will be set up for monthly installments. You can upload prerequisites while debit order is being processed.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ Full enrollment requires BOTH: (1) Payment honoured, AND (2) Prerequisites validated',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildPaymentOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colors,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer
              : colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? colors.onPrimary : colors.onSurface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? colors.onPrimaryContainer.withValues(alpha: 0.7)
                              : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: colors.primary, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildReviewAndSubmit(ThemeData theme, ColorScheme colors) {
    final totalAmount = _calculateTotalAmount();
    final depositAmount = _calculateDeposit();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Submit',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please review your enrollment details before submitting.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        _buildLearnershipInfoCard(colors),
        const SizedBox(height: 16),
        _buildCertificationTrackBreakdown(theme, colors),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              _buildReviewRow('Name',
                  '${_individualLearnerData.firstNameController.text} ${_individualLearnerData.lastNameController.text}'),
              _buildReviewRow(
                  'Email', _individualLearnerData.emailController.text),
              _buildReviewRow(
                  'Phone', _individualLearnerData.phoneController.text),
              _buildReviewRow(
                  'ID Number', _individualLearnerData.idNumberController.text),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildReviewRow(
                'Payment Option',
                _paymentOption == 'upfront'
                    ? 'Full Payment'
                    : 'Monthly Installments',
              ),
              _buildReviewRow(
                'Amount Due Now',
                _paymentOption == 'upfront'
                    ? CurrencyService.instance.formatPrice(totalAmount)
                    : CurrencyService.instance.formatPrice(depositAmount),
              ),
              if (_paymentOption == 'installments') ...[
                _buildReviewRow(
                  'Monthly Installment',
                  CurrencyService.instance
                      .formatUSDAmount(_calculateMonthlyInstallment()),
                ),
                _buildReviewRow(
                  'Duration',
                  '${widget.learnership.durationMonths} months',
                ),
              ],
            ],
          ),
        ),
        if (_uploadedEvidence.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prerequisites Evidence',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ..._uploadedEvidence.map((evidence) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          evidence.isUploaded
                              ? Icons.check_circle
                              : Icons.warning,
                          color: evidence.isUploaded
                              ? colors.primary
                              : colors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            evidence.prerequisiteName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLearnershipInfoCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.learnership.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (widget.learnership.nqfLevel != null &&
              widget.learnership.nqfLevel!.isNotEmpty)
            Text('NQF Level: ${widget.learnership.nqfLevel}'),
          if (widget.learnership.displayLocation.isNotEmpty)
            Text('Location: ${widget.learnership.displayLocation}'),
        ],
      ),
    );
  }

  Widget _buildCertificationTrackBreakdown(
      ThemeData theme, ColorScheme colors) {
    final track = widget.learnership.certificationTrack;
    if (track == null) return const SizedBox.shrink();

    final currencyService = CurrencyService.instance;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.school, color: colors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certification Pathway',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        track.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              colors.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Phase breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhaseSection(
                  theme,
                  colors,
                  currencyService,
                  'Phase 1 – Foundation',
                  'phase_1_foundation',
                  track,
                ),
                const SizedBox(height: 16),
                _buildPhaseSection(
                  theme,
                  colors,
                  currencyService,
                  'Phase 2 – Vendor Spec',
                  'phase_2_vendor_spec',
                  track,
                ),
                const SizedBox(height: 16),
                _buildPhaseSection(
                  theme,
                  colors,
                  currencyService,
                  'Phase 3 – Practical/Readiness',
                  'phase_3_practical',
                  track,
                ),
              ],
            ),
          ),

          // Cost summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(
                top: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                _buildCostRow(
                  theme,
                  colors,
                  'Total Certification Cost',
                  track.formattedTotalCertCost ??
                      currencyService.formatPrice(track.totalCertCost),
                ),
                const SizedBox(height: 8),
                _buildCostRow(
                  theme,
                  colors,
                  'Platform Access (12 months)',
                  track.formattedPlatformCost ??
                      currencyService.formatPrice(track.platformCost),
                ),
                _buildCostRow(
                  theme,
                  colors,
                  'Instructor Support (12 months)',
                  track.formattedInstructorCost ??
                      currencyService.formatPrice(track.instructorCost),
                ),
                const Divider(height: 24),
                _buildCostRow(
                  theme,
                  colors,
                  'Total Cost (50% markup)',
                  track.formattedSalesPrice ??
                      currencyService.formatPrice(track.salesPrice),
                  isTotal: true,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Payment:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        track.formattedMonthlyPrice ??
                            currencyService.formatPrice(track.monthlyPrice),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
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
    );
  }

  Widget _buildPhaseSection(
    ThemeData theme,
    ColorScheme colors,
    CurrencyService currencyService,
    String phaseTitle,
    String phaseKey,
    CertificationTrack track,
  ) {
    final items = track.getPhaseItems(phaseKey);
    if (items.isEmpty) return const SizedBox.shrink();

    final phaseTotal = track.getPhaseTotal(phaseKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              phaseTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            Text(
              currencyService.formatPrice(phaseTotal),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (item.description.isNotEmpty)
                          Text(
                            item.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    item.formattedCertCost ??
                        currencyService.formatPrice(item.certCost),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCostRow(
    ThemeData theme,
    ColorScheme colors,
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? colors.primary : colors.onSurface,
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? colors.primary : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponInput(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🏷️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'Have a coupon code?',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: colors.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter code (e.g. EARLYBIRD-ZA)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isCouponValidating ? null : _validateCoupon,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: _isCouponValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Apply'),
            ),
          ],
        ),
        if (_activeCoupon != null && _activeCoupon!.valid) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_activeCoupon!.summaryLabel} applied — saving ${CurrencyService.instance.formatPrice(_couponDiscountAmount)}',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_couponError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 14, color: colors.error),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(_couponError!,
                      style: TextStyle(color: colors.error, fontSize: 12))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    String value,
    ColorScheme colors, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: colors.onSurface,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isBold ? colors.primary : colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(ColorScheme colors) {
    final totalSteps = _isCorporate ? 4 : 5;
    final isLastStep = _currentStep == totalSteps - 1;
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _isSubmitting ? null : _previousStep,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 10 : 16,
                  vertical: isNarrow ? 10 : 12,
                ),
                textStyle: TextStyle(
                  fontSize: isNarrow ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleNextButton,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isLastStep ? Icons.check : Icons.arrow_forward,
                    size: isNarrow ? 16 : 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isLastStep ? 'Proceed to Payment' : 'Next',
                maxLines: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: Size(isNarrow ? 100 : 120, isNarrow ? 42 : 48),
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 16,
                vertical: isNarrow ? 10 : 12,
              ),
              textStyle: TextStyle(
                fontSize: isNarrow ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _handleNextButton() {
    if (_isCorporate) {
      _handleCorporateNext();
    } else {
      _handleIndividualNext();
    }
  }

  void _handleCorporateNext() {
    switch (_currentStep) {
      case 0: // Enrollment type
        setState(() => _currentStep = 1);
        break;
      case 1: // Company form (handled by CompanyEnrollmentForm callback)
        break;
      case 2: // Learners list
        if (!_validateCorporateLearners()) {
          _showError(
              'Please add at least one learner with valid name and email');
          return;
        }
        setState(() => _currentStep = 3);
        break;
      case 3: // Payment
        _submitCorporateEnrollment();
        break;
    }
  }

  void _handleIndividualNext() {
    switch (_currentStep) {
      case 0: // Enrollment type
        setState(() => _currentStep = 1);
        break;
      case 1: // Personal info
        if (!_individualLearnerData.validate()) {
          setState(() => _showFormErrors = true);
          _showError(
              'Please complete all required fields (highlighted in red)');
          return;
        }
        // Check OTP verification for email and phone
        if (!_individualLearnerData.emailVerified ||
            !_individualLearnerData.phoneVerified) {
          _showError(
              'Please complete both email and phone verification before proceeding.');
          return;
        }
        setState(() {
          _showFormErrors = false;
          _currentStep = 2;
        });
        break;
      case 2: // Prerequisites
        // Check if all required evidence is uploaded
        final prerequisites = widget.learnership.prerequisites ?? [];
        if (prerequisites.isNotEmpty) {
          final missingEvidence =
              _uploadedEvidence.where((e) => !e.isUploaded).length;
          if (missingEvidence > 0) {
            _showError('Please upload evidence for all prerequisites');
            return;
          }
        }
        setState(() => _currentStep = 3);
        break;
      case 3: // Payment option
        setState(() => _currentStep = 4);
        break;
      case 4: // Review
        _submitIndividualEnrollment();
        break;
    }
  }

  bool _validateCorporateLearners() {
    if (_corporateLearners.isEmpty) return false;

    for (var learner in _corporateLearners) {
      if (learner.firstNameController.text.trim().isEmpty ||
          learner.lastNameController.text.trim().isEmpty ||
          learner.emailController.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  int _getDepositPercentage() {
    return _paymentPlan?['breakdown']?['deposit_percentage'] ?? 30;
  }

  Map<String, dynamic>? _paymentPlan;
  bool _isLoadingPlan = false;

  Future<void> _fetchPaymentPlan() async {
    setState(() => _isLoadingPlan = true);
    try {
      final plan = await ApiClient.calculateLearnershipPaymentPlan(
        programmeId: widget.learnership.id,
        paymentOption: _paymentOption,
        isCorporate: _isCorporate,
        learnerCount: _isCorporate ? _corporateLearners.length : 1,
        currency: CurrencyService.instance.currencyCode,
      );
      setState(() {
        _paymentPlan = plan;
        _isLoadingPlan = false;
      });
    } catch (e) {
      setState(() => _isLoadingPlan = false);
      _showError('Failed to calculate payment plan: $e');
    }
  }

  double _calculateDeposit() {
    if (_paymentPlan != null) {
      return (_paymentPlan!['calculated_prices']['deposit_amount'] as num).toDouble();
    }
    return _calculateTotalAmount() * 0.30;
  }

  double _calculateAdminFee() {
    if (_paymentPlan != null) {
      return (_paymentPlan!['calculated_prices']['admin_fee'] as num).toDouble();
    }
    return _calculateDeposit() * 0.05;
  }

  double _calculateTotalAmount() {
    if (_paymentPlan != null) {
      return (_paymentPlan!['calculated_prices']['total_amount'] as num).toDouble();
    }
    return _discountedLearnershipPrice * (_isCorporate ? _corporateLearners.length : 1);
  }

  double _calculateMonthlyInstallment() {
    if (_paymentPlan != null) {
      return (_paymentPlan!['calculated_prices']['monthly_installment'] as num).toDouble();
    }
    final totalAmount = _calculateTotalAmount();
    final deposit = _calculateDeposit();
    final remainingAmount = totalAmount - deposit;
    final durationMonths = (widget.learnership.durationMonths ?? 0) > 0
        ? widget.learnership.durationMonths!
        : 12;
    return remainingAmount / durationMonths;
  }

  Future<void> _submitCorporateEnrollment() async {
    setState(() => _isSubmitting = true);

    try {
      // Prepare learners data (name + email only)
      final learnersData = _corporateLearners.map((learner) {
        return {
          'first_name': learner.firstNameController.text.trim(),
          'last_name': learner.lastNameController.text.trim(),
          'full_name':
              '${learner.firstNameController.text.trim()} ${learner.lastNameController.text.trim()}',
          'email': learner.emailController.text.trim(),
        };
      }).toList();

      // Calculate payment amounts (corporate always uses installments)
      final totalAmount = _calculateTotalAmount();
      final depositAmount = _calculateDeposit();
      final adminFee = depositAmount * 0.05; // 5% admin fee on deposit
      final paymentAmount = depositAmount + adminFee; // Initial payment

      // Build corporate enrollment data for payment metadata
      final enrollmentData = {
        'enrollment_type': 'learnership',
        'programme_id': widget.learnership.id,
        'is_corporate': true,
        'company': _companyData,
        'learners': learnersData,
        'payment_option': 'installments', // Corporate always uses installments
        'payment_plan_type': 'deposit_debit',
        'payment_status': 'partial_paid',
        'total_amount': totalAmount,
        'deposit_amount': depositAmount,
        'admin_fee': adminFee,
        'monthly_installment': _calculateMonthlyInstallment(),
        'installments_remaining': widget.learnership.durationMonths,
        'currency': widget.learnership.currency ?? 'USD',
        if (_activeCoupon != null) ...{
          'coupon_code': _activeCoupon!.code,
          'coupon_id': _activeCoupon!.couponId,
          'discount_amount': _couponDiscountAmount,
          'original_amount': _learnershipPrice * _corporateLearners.length,
        },
      };

      // Build metadata for payment initiation
      final metadata = {
        'programme_id': widget.learnership.id.toString(),
        'programme_title': widget.learnership.title,
        'programme_role': widget.learnership.role ?? 'SOC Analyst',
        'enrollment_data': enrollmentData,
        'payment_option': 'installments',
        'is_corporate': true,
        'learner_count': _corporateLearners.length,
        'currency': widget.learnership.currency ?? 'USD',
      };

      // Initiate payment flow
      final response = await ApiClient.initiatePayment(
        programId: widget.learnership.id.toString(),
        type: 'learnership',
        amount: paymentAmount,
        metadata: metadata,
      );

      if (!mounted) return;

      // Navigate to payment selection page
      await PaymentProviderSelectionPage.show(
        context,
        reference: response['reference'] as String,
        amount: paymentAmount,
        currency: widget.learnership.currency ?? 'USD',
        country: 'ZA', // Default, could be from company country
        programId: widget.learnership.id.toString(),
        programType: 'learnership',
        paymentMetadata: {'programme_id': widget.learnership.id.toString()},
        enrollmentPayload: metadata,
      );

      // Close modal after payment flow starts
      Navigator.of(context).pop();
      widget.onEnrollmentComplete?.call();
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to start payment: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitIndividualEnrollment() async {
    setState(() => _isSubmitting = true);

    try {
      // Prepare evidence data
      final evidenceData = _uploadedEvidence.map((evidence) {
        return {
          'prerequisite_key': evidence.prerequisiteName,
          'prerequisite_name': evidence.prerequisiteName,
          'description': evidence.descriptionController.text,
          'file_path': evidence.filePath,
          'file_name': evidence.fileName,
          'has_file': evidence.isUploaded,
        };
      }).toList();

      // Use discounted price if coupon applied
      final totalAmount = _calculateTotalAmount();
      final depositAmount = _calculateDeposit();
      final adminFee = _calculateAdminFee();
      final monthlyInstallment = _calculateMonthlyInstallment();

      // Determine payment plan type and status
      String paymentPlanType;
      String paymentStatus;
      double? amountPaid;

      switch (_paymentOption) {
        case 'upfront':
          paymentPlanType = 'full';
          paymentStatus = 'pending';
          amountPaid = totalAmount;
          break;
        case 'installments':
          paymentPlanType = 'deposit_debit';
          paymentStatus = 'partial_paid';
          amountPaid = adminFee + depositAmount;
          break;
        case 'cash':
          paymentPlanType = 'cash_office';
          paymentStatus = 'cash_promise';
          amountPaid = 0;
          break;
        default:
          paymentPlanType = 'full';
          paymentStatus = 'pending';
          amountPaid = totalAmount;
      }

      // Build enrollment data for payment metadata
      final enrollmentData = {
        'enrollment_type': 'individual',
        'programme': widget.learnership.id,
        'is_corporate': false,
        'payment_plan_type': paymentPlanType,
        'payment_option': _paymentOption,
        'payment_status': paymentStatus,
        'amount_paid': amountPaid,
        'total_amount': totalAmount,
        'deposit_paid': _paymentOption == 'installments' ? depositAmount : null,
        'currency': CurrencyService.instance.currencyCode,

        // Debit order details (if installments)
        if (_paymentOption == 'installments') ...{
          'debit_order_amount': monthlyInstallment,
          'installments_remaining': widget.learnership.durationMonths,
        },

        // ===== LEARNER PERSONAL INFORMATION =====
        'learner_first_name':
            _individualLearnerData.firstNameController.text.trim(),
        'learner_last_name':
            _individualLearnerData.lastNameController.text.trim(),
        'learner_full_name':
            '${_individualLearnerData.firstNameController.text.trim()} ${_individualLearnerData.lastNameController.text.trim()}',
        'learner_email': _individualLearnerData.emailController.text.trim(),
        'learner_phone': _individualLearnerData.phoneController.text.trim(),
        'learner_id_number':
            _individualLearnerData.idNumberController.text.trim(),
        'learner_dob': _individualLearnerData.dobController.text.trim(),
        'learner_gender': _individualLearnerData.selectedGender ?? '',
        'learner_address': _individualLearnerData.addressController.text.trim(),
        'learner_city': _individualLearnerData.selectedCity?.name ?? '',
        'learner_country': _individualLearnerData.selectedCountry?.code ?? 'ZA',
        'learner_postal_code':
            _individualLearnerData.postalCodeController.text.trim(),

        // ===== PROFESSIONAL/EDUCATIONAL INFORMATION =====
        'current_occupation':
            _individualLearnerData.occupationController.text.trim(),
        'education_level': _individualLearnerData.selectedEducationLevel ?? '',
        'institution': _individualLearnerData.institutionController.text.trim(),

        // ===== SETA COMPLIANCE FIELDS (Required for Learnerships) =====
        'race': _individualLearnerData.selectedRace ?? '',
        'disability': _individualLearnerData.selectedDisability ?? '',
        'nationality': _individualLearnerData.selectedNationality ?? 'ZA',

        // ===== EMERGENCY CONTACT =====
        'emergency_contact_name':
            _individualLearnerData.emergencyNameController.text.trim(),
        'emergency_contact_phone':
            _individualLearnerData.emergencyPhoneController.text.trim(),
        'emergency_contact_relationship':
            _individualLearnerData.selectedEmergencyRelationship ?? '',
        'highest_qualification':
            _individualLearnerData.highestQualificationController.text.trim(),
        'qualification_institution': _individualLearnerData
            .qualificationInstitutionController.text
            .trim(),
        'qualification_year':
            _individualLearnerData.qualificationYearController.text.trim(),
        'employer': _individualLearnerData.employerController.text.trim(),
        'job_title': _individualLearnerData.jobTitleController.text.trim(),
        'employment_status':
            _individualLearnerData.employmentStatusController.text.trim(),
        'monthly_income':
            _individualLearnerData.monthlyIncomeController.text.trim(),
        'existing_skills': _individualLearnerData.skillsController.text.trim(),

        // ===== NEXT OF KIN (Separate from Emergency Contact) =====
        'next_of_kin_name':
            _individualLearnerData.nextOfKinNameController.text.trim(),
        'next_of_kin_phone':
            _individualLearnerData.nextOfKinPhoneController.text.trim(),
        'next_of_kin_relationship':
            _individualLearnerData.selectedNextOfKinRelationship ?? '',
        'next_of_kin_email':
            _individualLearnerData.nextOfKinEmailController.text.trim(),
        'next_of_kin_address':
            _individualLearnerData.nextOfKinAddressController.text.trim(),

        // ===== MEDICAL & ACCESSIBILITY =====
        'medical_conditions':
            _individualLearnerData.medicalConditionsController.text.trim(),
        'allergies': _individualLearnerData.allergiesController.text.trim(),
        'medications': _individualLearnerData.medicationsController.text.trim(),
        'accessibility_needs':
            _individualLearnerData.accessibilityController.text.trim(),
        'dietary_requirements':
            _individualLearnerData.dietaryController.text.trim(),

        // ===== LEARNING SUPPORT =====
        'requires_learning_support':
            _individualLearnerData.requiresLearningSupport ?? '',
        'learning_support_details':
            _individualLearnerData.learningSupportDetailsController.text.trim(),
        'has_previous_learnership_experience':
            _individualLearnerData.hasPreviousLearnershipExperience ?? '',
        'previous_learnership_details': _individualLearnerData
            .previousLearnershipDetailsController.text
            .trim(),

        // ===== DOCUMENTATION CHECKLIST =====
        'has_id_copy': _individualLearnerData.hasIDCopy == 'Yes',
        'has_qualification_certificates':
            _individualLearnerData.hasQualificationCertificates == 'Yes',
        'has_proof_of_residence':
            _individualLearnerData.hasProofOfResidence == 'Yes',
        'has_cv': _individualLearnerData.hasCV == 'Yes',
        'has_motivational_letter':
            _individualLearnerData.hasMotivationalLetter == 'Yes',

        // ===== PAYMENT & FUNDING =====
        'funding_source': _individualLearnerData.fundingSource ?? 'self_funded',
        'company_vat_number':
            _individualLearnerData.companyVATController.text.trim(),
        'purchase_order_number':
            _individualLearnerData.purchaseOrderNumberController.text.trim(),
        if (_activeCoupon != null) ...{
          'coupon_code': _activeCoupon!.code,
          'coupon_id': _activeCoupon!.couponId,
          'discount_amount': _activeCoupon!.discountAmount,
          'original_amount': _learnershipPrice,
        },

        // ===== DEBIT ORDER BANKING DETAILS =====
        'requires_debit_order': _individualLearnerData.requiresDebitOrder ?? '',
        'bank_name': _individualLearnerData.bankNameController.text.trim(),
        'bank_account_number':
            _individualLearnerData.bankAccountNumberController.text.trim(),
        'bank_branch_code':
            _individualLearnerData.bankBranchCodeController.text.trim(),
        'bank_account_type':
            _individualLearnerData.bankAccountTypeController.text.trim(),
        'bank_account_holder_name':
            _individualLearnerData.bankAccountHolderNameController.text.trim(),

        // ===== LEGAL DECLARATIONS =====
        'terms_accepted': _individualLearnerData.termsAccepted,
        'data_protection_accepted':
            _individualLearnerData.dataProtectionAccepted,
        'certification_declaration_accepted':
            _individualLearnerData.certificationDeclarationAccepted,
        'seta_declaration_accepted':
            _individualLearnerData.setaDeclarationAccepted,

        // ===== ADDITIONAL INFORMATION =====
        'referral_source':
            _individualLearnerData.referralSourceController.text.trim(),
        'additional_notes':
            _individualLearnerData.additionalNotesController.text.trim(),

        // Prerequisites evidence
        'evidence': evidenceData,
      };

      // Calculate payment amount based on option
      double paymentAmount = 0.0;
      if (_paymentOption == 'upfront') {
        paymentAmount = totalAmount;
      } else if (_paymentOption == 'installments') {
        paymentAmount = depositAmount + adminFee; // Deposit + admin fee
      }
      // Cash: paymentAmount remains 0

      // Build metadata for payment initiation
      final metadata = {
        'programme_id': widget.learnership.id.toString(),
        'programme_title': widget.learnership.title,
        'programme_role': widget.learnership.role ?? 'SOC Analyst',
        'enrollment_data': enrollmentData,
        'payment_option': _paymentOption,
        'is_corporate': false,
        'currency': widget.learnership.currency ?? 'USD',
      };

      // Cascade form data back to student profile (best-effort)
      await _cascadeProfileUpdate();

      // Initiate payment flow
      final response = await ApiClient.initiatePayment(
        programId: widget.learnership.id.toString(),
        type: 'learnership',
        amount: paymentAmount,
        metadata: metadata,
      );

      if (!mounted) return;

      // Navigate to payment selection page
      await PaymentProviderSelectionPage.show(
        context,
        reference: response['reference'] as String,
        amount: paymentAmount,
        currency: widget.learnership.currency ?? 'USD',
        country: _individualLearnerData.selectedCountry?.code ?? 'ZA',
        programId: widget.learnership.id.toString(),
        programType: 'learnership',
        paymentMetadata: {'programme_id': widget.learnership.id.toString()},
        enrollmentPayload: metadata,
      );

      // Close modal after payment flow starts
      Navigator.of(context).pop();
      widget.onEnrollmentComplete?.call();
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to start payment: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class LearnerFormData {
  // ===== PERSONAL DETAILS =====
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final idNumberController = TextEditingController();
  final idTypeController =
      TextEditingController(); // ID/Passport/Asylum/Refugee
  final dobController = TextEditingController();
  DateTime? selectedDob; // For date picker
  String? selectedGender;
  String? selectedRace; // For employment equity
  String? selectedDisability; // Yes/No
  String? selectedNationality;

  // ===== PHYSICAL ADDRESS =====
  final addressController = TextEditingController();
  final suburbController = TextEditingController();
  location_models.Country? selectedCountry;
  location_models.State? selectedState;
  location_models.City? selectedCity;
  String phoneIsoCode = 'ZA';
  final postalCodeController = TextEditingController();
  final postalAddressController = TextEditingController();
  final postalSuburbController = TextEditingController();
  final postalPostalCodeController = TextEditingController();
  bool sameAsPhysical = true;

  // ===== ACADEMIC INFORMATION =====
  final highestQualificationController = TextEditingController();
  final qualificationInstitutionController = TextEditingController();
  final qualificationYearController = TextEditingController();
  String? selectedEducationLevel;
  final occupationController = TextEditingController();
  final institutionController =
      TextEditingController(); // For current institution
  final employerController = TextEditingController();
  final jobTitleController = TextEditingController();
  final employmentStatusController =
      TextEditingController(); // Employed/Unemployed/Student
  final monthlyIncomeController = TextEditingController(); // For SETA reporting
  final skillsController = TextEditingController(); // Existing skills

  // ===== EMERGENCY CONTACT =====
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  String? selectedEmergencyRelationship;
  String emergencyPhoneIsoCode = 'ZA';
  final emergencyAddressController = TextEditingController();

  // ===== NEXT OF KIN (Separate from Emergency) =====
  final nextOfKinNameController = TextEditingController();
  final nextOfKinPhoneController = TextEditingController();
  String? selectedNextOfKinRelationship;
  final nextOfKinEmailController = TextEditingController();
  final nextOfKinAddressController = TextEditingController();

  // ===== MEDICAL & ACCESSIBILITY =====
  final medicalConditionsController = TextEditingController();
  final allergiesController = TextEditingController();
  final medicationsController = TextEditingController();
  final accessibilityController = TextEditingController();
  final dietaryController = TextEditingController();

  // ===== LEARNING SUPPORT =====
  String? requiresLearningSupport; // Yes/No
  final learningSupportDetailsController = TextEditingController();
  String? hasPreviousLearnershipExperience; // Yes/No
  final previousLearnershipDetailsController = TextEditingController();

  // ===== ADDITIONAL NOTES =====
  final notesController = TextEditingController();

  // ===== DOCUMENTATION =====
  String? hasIDCopy; // Checkbox
  String? hasQualificationCertificates; // Checkbox
  String? hasProofOfResidence; // Checkbox
  String? hasCV; // Checkbox
  String? hasMotivationalLetter; // Checkbox

  // ===== PAYMENT & FUNDING =====
  String? fundingSource; // Self-funded/Company-funded/SETA/NSFAS/Other
  final companyNameController = TextEditingController(); // If company-funded
  final companyRegistrationController = TextEditingController();
  final companyVATController = TextEditingController();
  final purchaseOrderNumberController =
      TextEditingController(); // If company-funded
  String? requiresDebitOrder; // Yes/No
  final bankNameController = TextEditingController();
  final bankAccountNumberController = TextEditingController();
  final bankBranchCodeController = TextEditingController();
  final bankAccountTypeController = TextEditingController(); // Savings/Cheque
  final bankAccountHolderNameController = TextEditingController();

  // ===== DECLARATIONS =====
  bool termsAccepted = false;
  bool dataProtectionAccepted = false;
  bool certificationDeclarationAccepted = false;
  bool setaDeclarationAccepted = false; // For SETA-funded learnerships

  // ===== ADDITIONAL =====
  final additionalNotesController = TextEditingController();
  final referralSourceController =
      TextEditingController(); // How did you hear about us?

  // ===== OTP VERIFICATION =====
  bool emailVerified = false;
  bool phoneVerified = false;

  bool validate() {
    // Personal Details (required — rendered in form)
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        idNumberController.text.isEmpty ||
        dobController.text.isEmpty ||
        selectedGender == null ||
        selectedRace == null ||
        selectedDisability == null ||
        selectedNationality == null) {
      return false;
    }

    // Address (required — rendered in form)
    if (addressController.text.isEmpty ||
        selectedCountry == null ||
        postalCodeController.text.isEmpty) {
      return false;
    }

    // Professional (required — rendered in form)
    if (selectedEducationLevel == null || occupationController.text.isEmpty) {
      return false;
    }

    // Emergency Contact (required — rendered in form)
    if (emergencyNameController.text.isEmpty ||
        emergencyPhoneController.text.isEmpty ||
        selectedEmergencyRelationship == null) {
      return false;
    }

    // Contact verification
    if (!emailVerified || !phoneVerified) return false;

    // Terms (required — rendered in form)
    if (!termsAccepted) {
      return false;
    }

    return true;
  }

  void dispose() {
    // Personal
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    idNumberController.dispose();
    idTypeController.dispose();
    dobController.dispose();

    // Address
    addressController.dispose();
    suburbController.dispose();
    postalCodeController.dispose();
    postalAddressController.dispose();
    postalSuburbController.dispose();
    postalPostalCodeController.dispose();

    // Academic
    highestQualificationController.dispose();
    qualificationInstitutionController.dispose();
    qualificationYearController.dispose();
    occupationController.dispose();
    institutionController.dispose();
    employerController.dispose();
    jobTitleController.dispose();
    employmentStatusController.dispose();
    monthlyIncomeController.dispose();
    skillsController.dispose();

    // Emergency & Next of Kin
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    emergencyAddressController.dispose();
    nextOfKinNameController.dispose();
    nextOfKinPhoneController.dispose();
    nextOfKinEmailController.dispose();
    nextOfKinAddressController.dispose();

    // Medical
    medicalConditionsController.dispose();
    allergiesController.dispose();
    medicationsController.dispose();
    accessibilityController.dispose();
    dietaryController.dispose();

    // Learning Support
    learningSupportDetailsController.dispose();
    previousLearnershipDetailsController.dispose();

    // Additional Notes
    notesController.dispose();

    // Payment & Bank
    companyNameController.dispose();
    companyRegistrationController.dispose();
    companyVATController.dispose();
    purchaseOrderNumberController.dispose();
    bankNameController.dispose();
    bankAccountNumberController.dispose();
    bankBranchCodeController.dispose();
    bankAccountTypeController.dispose();
    bankAccountHolderNameController.dispose();

    // Additional
    additionalNotesController.dispose();
    referralSourceController.dispose();
  }
}

class CorporateLearnerData {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
  }
}

class EvidenceUploadData {
  final String prerequisiteName;
  String? filePath;
  String? fileName;
  List<int>? fileBytes; // For Flutter Web where path is null
  final descriptionController = TextEditingController();

  EvidenceUploadData({required this.prerequisiteName});

  bool get isUploaded => filePath != null || fileBytes != null;

  void dispose() {
    descriptionController.dispose();
  }
}

// ============================================================================
// LEARNER INFORMATION FORM (Learnership-specific)
// ============================================================================

class LearnerInformationForm extends StatefulWidget {
  final LearnerFormData learnerData;
  final Map<String, dynamic>? companyLocation; // Company location for auto-fill
  final bool showErrors; // Highlight empty required fields

  const LearnerInformationForm({
    super.key,
    required this.learnerData,
    this.companyLocation,
    this.showErrors = false,
  });

  @override
  State<LearnerInformationForm> createState() => _LearnerInformationFormState();
}

class _LearnerInformationFormState extends State<LearnerInformationForm> {
  bool _companyLocationApplied = false;

  @override
  void initState() {
    super.initState();

    // Auto-fill location from company if provided
    if (widget.companyLocation != null && !_companyLocationApplied) {
      _applyCompanyLocation();
    }
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
        widget.learnerData.selectedCountry = location_models.Country(
          id: countryId,
          name: '',
          code: countryCode ?? '',
        );
      }
      if (stateId != null) {
        widget.learnerData.selectedState = location_models.State(
          id: stateId!,
          name: '',
          countryId: countryId!,
        );
      }
      if (cityId != null) {
        widget.learnerData.selectedCity = location_models.City(
          id: cityId!,
          name: '',
          stateId: stateId!,
        );
      }

      // Update phone ISO code based on company's country
      if (countryCode != null && countryCode.isNotEmpty) {
        widget.learnerData.phoneIsoCode = countryCode;
        widget.learnerData.emergencyPhoneIsoCode = countryCode;
      }

      _companyLocationApplied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final learnerData = widget.learnerData;
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Personal Information', Icons.person, colors),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: learnerData.firstNameController,
                label: 'First Name *',
                icon: Icons.person_outline,
                colors: colors,
                required: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: learnerData.lastNameController,
                label: 'Last Name *',
                icon: Icons.person_outline,
                colors: colors,
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: learnerData.emailController,
          label: 'Email Address *',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          colors: colors,
          required: true,
        ),
        ContactOtpField(
          contactController: learnerData.emailController,
          contactType: 'email',
          onVerifiedChanged: (verified) =>
              setState(() => learnerData.emailVerified = verified),
        ),
        const SizedBox(height: 12),
        _buildPhoneField(
          controller: learnerData.phoneController,
          label: 'Phone Number *',
          currentIso: learnerData.phoneIsoCode,
          onIsoChanged: (String newIso) {
            setState(() => learnerData.phoneIsoCode = newIso);
          },
          colors: colors,
        ),
        ContactOtpField(
          contactController: learnerData.phoneController,
          contactType: 'phone',
          phoneDialCode:
              AfricanPhoneValidator.getInfoForCountry(learnerData.phoneIsoCode)
                  ?.countryCode,
          onVerifiedChanged: (verified) =>
              setState(() => learnerData.phoneVerified = verified),
        ),
        if (learnerData.emailVerified && learnerData.phoneVerified) ...[
          const SizedBox(height: 12),
          _buildTextField(
            controller: learnerData.idNumberController,
            label: 'ID / Passport Number *',
            icon: Icons.badge_outlined,
            colors: colors,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildDatePickerField(
            controller: learnerData.dobController,
            label: 'Date of Birth *',
            icon: Icons.calendar_today_outlined,
            hint: 'Select your date of birth',
            colors: colors,
            onDateSelected: (DateTime picked) {
              setState(() {
                learnerData.selectedDob = picked;
              });
            },
            selectedDate: learnerData.selectedDob,
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            value: learnerData.selectedGender,
            label: 'Gender *',
            icon: Icons.wc_outlined,
            items: ['Male', 'Female', 'Other', 'Prefer not to say'],
            onChanged: (value) {
              setState(() {
                learnerData.selectedGender = value;
              });
            },
            colors: colors,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Address Information', Icons.location_on, colors),
          const SizedBox(height: 16),
          _buildTextField(
            controller: learnerData.addressController,
            label: 'Physical Address *',
            icon: Icons.home_outlined,
            maxLines: 2,
            colors: colors,
            required: true,
          ),
          const SizedBox(height: 12),
          BlocProvider(
            create: (context) => LocationBloc(),
            child: CascadingLocationDropdowns(
              key: ObjectKey(learnerData),
              isRequired: true,
              initialCountry: learnerData.selectedCountry,
              initialState: learnerData.selectedState,
              initialCity: learnerData.selectedCity,
              onLocationChanged: (country, state, city) {
                setState(() {
                  learnerData.selectedCountry = country;
                  learnerData.selectedState = state;
                  learnerData.selectedCity = city;
                  if (country != null) {
                    learnerData.phoneIsoCode = country.code;
                    learnerData.emergencyPhoneIsoCode = country.code;
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: learnerData.postalCodeController,
            label: 'Postal Code *',
            icon: Icons.markunread_mailbox_outlined,
            colors: colors,
            required: true,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Professional Information', Icons.work, colors),
          const SizedBox(height: 16),
          _buildTextField(
            controller: learnerData.occupationController,
            label: 'Current Occupation *',
            icon: Icons.work_outline,
            colors: colors,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            value: learnerData.selectedEducationLevel,
            label: 'Education Level *',
            icon: Icons.school_outlined,
            items: [
              'High School',
              'Some College',
              'Associate Degree',
              'Bachelor\'s Degree',
              'Master\'s Degree',
              'Doctorate',
              'Other',
            ],
            onChanged: (value) {
              setState(() {
                learnerData.selectedEducationLevel = value;
              });
            },
            colors: colors,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: learnerData.institutionController,
            label: 'Institution/Current Company *',
            icon: Icons.business_outlined,
            colors: colors,
            required: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  value: learnerData.selectedRace,
                  label: 'Race (Employment Equity) *',
                  icon: Icons.groups_outlined,
                  items: ['African', 'Coloured', 'Indian', 'White', 'Other'],
                  onChanged: (value) {
                    setState(() {
                      learnerData.selectedRace = value;
                    });
                  },
                  colors: colors,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  value: learnerData.selectedDisability,
                  label: 'Disability Status *',
                  icon: Icons.accessible_outlined,
                  items: ['Yes', 'No'],
                  onChanged: (value) {
                    setState(() {
                      learnerData.selectedDisability = value;
                    });
                  },
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller:
                TextEditingController(text: learnerData.selectedNationality),
            label: 'Nationality *',
            icon: Icons.flag_outlined,
            colors: colors,
            hint: 'e.g. South African',
            required: true,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
              'Academic & Employment History', Icons.school, colors),
          const SizedBox(height: 16),
          _buildTextField(
            controller: learnerData.highestQualificationController,
            label: 'Highest Qualification *',
            icon: Icons.history_edu,
            colors: colors,
            required: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: learnerData.qualificationInstitutionController,
                  label: 'Qualification Institution *',
                  icon: Icons.account_balance,
                  colors: colors,
                  required: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: learnerData.qualificationYearController,
                  label: 'Year Obtained *',
                  icon: Icons.event_available,
                  colors: colors,
                  required: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: learnerData.employerController,
                  label: 'Current Employer',
                  icon: Icons.business,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: learnerData.jobTitleController,
                  label: 'Job Title',
                  icon: Icons.badge,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  value: learnerData.employmentStatusController.text.isNotEmpty
                      ? learnerData.employmentStatusController.text
                      : null,
                  label: 'Employment Status *',
                  icon: Icons.work_history,
                  items: ['Employed', 'Unemployed', 'Student', 'Self Employed'],
                  onChanged: (value) {
                    setState(() {
                      learnerData.employmentStatusController.text = value ?? '';
                    });
                  },
                  colors: colors,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: learnerData.monthlyIncomeController,
                  label: 'Monthly Income',
                  icon: Icons.payments,
                  colors: colors,
                  hint: 'Optional (SETA reporting)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: learnerData.skillsController,
            label: 'Existing Skills',
            icon: Icons.auto_awesome,
            maxLines: 2,
            colors: colors,
            hint: 'List your main professional skills',
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Emergency Contact', Icons.emergency, colors),
          const SizedBox(height: 16),
          _buildTextField(
            controller: learnerData.emergencyNameController,
            label: 'Emergency Contact Name *',
            icon: Icons.person_outline,
            colors: colors,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildPhoneField(
            controller: learnerData.emergencyPhoneController,
            label: 'Emergency Contact Phone *',
            currentIso: learnerData.emergencyPhoneIsoCode,
            onIsoChanged: (String newIso) {
              setState(() => learnerData.emergencyPhoneIsoCode = newIso);
            },
            colors: colors,
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            value: learnerData.selectedEmergencyRelationship,
            label: 'Relationship to Emergency Contact *',
            icon: Icons.family_restroom_outlined,
            items: ['Parent', 'Spouse', 'Sibling', 'Friend', 'Other'],
            onChanged: (value) {
              setState(() {
                learnerData.selectedEmergencyRelationship = value;
              });
            },
            colors: colors,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
              'Additional Information (Optional)', Icons.info_outline, colors),
          const SizedBox(height: 16),
          _buildTextField(
            controller: learnerData.dietaryController,
            label: 'Dietary Requirements',
            icon: Icons.restaurant_outlined,
            maxLines: 2,
            colors: colors,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: learnerData.accessibilityController,
            label: 'Accessibility Needs',
            icon: Icons.accessible_outlined,
            maxLines: 2,
            colors: colors,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: learnerData.notesController,
            label: 'Additional Notes',
            icon: Icons.note_outlined,
            maxLines: 3,
            colors: colors,
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            value: learnerData.termsAccepted,
            onChanged: (value) {
              setState(() {
                learnerData.termsAccepted = value ?? false;
              });
            },
            title: const Text('I accept the terms and conditions *'),
            subtitle: Text(
              'Required to complete enrollment',
              style: theme.textTheme.bodySmall,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: colors.primary,
          ),
        ] else ...[
          _buildContactsLockedNotice(colors, learnerData),
        ],
      ],
    );
  }

  Widget _buildContactsLockedNotice(
      ColorScheme colors, LearnerFormData learnerData) {
    final emailDone = learnerData.emailVerified;
    final phoneDone = learnerData.phoneVerified;
    return Container(
      margin: const EdgeInsets.only(top: 12),
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
                  'Verify your contact details to continue',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: colors.onSurface),
                ),
                const SizedBox(height: 4),
                if (!emailDone)
                  Text('• Email address not yet verified',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant)),
                if (!phoneDone)
                  Text('• Phone number not yet verified',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant)),
              ],
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
    required ColorScheme colors,
  }) {
    final validatorCountries =
        AfricanPhoneValidator.africanPhoneInfo.keys.toList();
    final info = AfricanPhoneValidator.getInfoForCountry(currentIso);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 130,
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

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colors) {
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    required ColorScheme colors,
    bool required = false,
  }) {
    final isRequiredAndEmpty =
        required && widget.showErrors && controller.text.trim().isEmpty;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: isRequiredAndEmpty ? 'Required' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isRequiredAndEmpty
            ? colors.errorContainer.withValues(alpha: 0.2)
            : colors.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ColorScheme colors,
    bool required = false,
  }) {
    final isRequiredAndEmpty =
        required && widget.showErrors && (value == null || value.isEmpty);

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        errorText: isRequiredAndEmpty ? 'Required' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isRequiredAndEmpty
            ? colors.errorContainer.withValues(alpha: 0.2)
            : colors.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.arrow_drop_down),
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    required ColorScheme colors,
    Function(DateTime)? onDateSelected,
    DateTime? selectedDate,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ??
                  DateTime.now().subtract(const Duration(days: 365 * 25)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              helpText: 'Select Date of Birth',
              cancelText: 'Cancel',
              confirmText: 'OK',
            );
            if (picked != null) {
              controller.text = DateFormat('yyyy-MM-dd').format(picked);
              if (onDateSelected != null) {
                onDateSelected(picked);
              }
              // Validate age (must be at least 16 years old)
              final age = DateTime.now().difference(picked).inDays ~/ 365;
              if (age < 16) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('You must be at least 16 years old to enroll'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          },
        ),
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ??
              DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          helpText: 'Select Date of Birth',
          cancelText: 'Cancel',
          confirmText: 'OK',
        );
        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
          if (onDateSelected != null) {
            onDateSelected(picked);
          }
          // Validate age (must be at least 16 years old)
          final age = DateTime.now().difference(picked).inDays ~/ 365;
          if (age < 16) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You must be at least 16 years old to enroll'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your date of birth';
        }
        // Validate date format
        try {
          final parsedDate = DateFormat('yyyy-MM-dd').parse(value);
          final age = DateTime.now().difference(parsedDate).inDays ~/ 365;
          if (age < 16) {
            return 'You must be at least 16 years old to enroll';
          }
          if (age > 120) {
            return 'Please enter a valid date of birth';
          }
        } catch (e) {
          return 'Please use the format YYYY-MM-DD (e.g., 1990-01-15)';
        }
        return null;
      },
    );
  }
}
