// lib/src/presentation/pages/learnerships/learnership_complete_enrollment_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/pricing_constants.dart';
import '../../../core/services/currency_service.dart';
import '../../widgets/enrollment/enrollment_type_selection.dart';
import '../../widgets/enrollment/company_enrollment_form.dart';
import '../../widgets/enrollment/enrollment_form_widget.dart';
import '../../widgets/headers/enrollment_page_header.dart';
import '../../pages/payment/payment_provider_selection_page.dart';

/// Complete Learnership Enrollment Page
/// Collects all required data → initiates payment → no enrollment until payment success
class LearnershipCompleteEnrollmentPage extends StatefulWidget {
  final int programmeId;
  final String programmeTitle;
  final String? programmeDescription;
  final String? programmeDuration;
  final String? programmeRole; // Role/specialization for pricing
  // HARDENED: programmeFee is now deprecated - price is calculated from role
  final double? programmeFee;

  const LearnershipCompleteEnrollmentPage({
    super.key,
    required this.programmeId,
    required this.programmeTitle,
    this.programmeDescription,
    this.programmeDuration,
    this.programmeRole,
    this.programmeFee,
  });

  @override
  State<LearnershipCompleteEnrollmentPage> createState() =>
      _LearnershipCompleteEnrollmentPageState();
}

class _LearnershipCompleteEnrollmentPageState
    extends State<LearnershipCompleteEnrollmentPage> {
  String? _selectedEnrollmentType;
  bool _isProcessing = false;
  bool _showIndividualForm = false;

  // Collected data from child forms
  Map<String, dynamic>? _collectedData;
  
  // Store company location for auto-filling learner forms
  Map<String, dynamic>? _companyLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          EnrollmentPageHeader(
            title: 'Learnership Enrollment',
            subtitle: 'Complete your enrollment',
            showBackButton: true,
            onBack: () => context.go('/onboarding'),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgrammeHeader(theme, colors),
                    const SizedBox(height: 24),
                    if (_selectedEnrollmentType == null)
                      EnrollmentTypeSelection(
                        trainingTitle: widget.programmeTitle,
                        onTypeSelected: (type) {
                          setState(() => _selectedEnrollmentType = type);
                        },
                      )
                    else if (_selectedEnrollmentType == 'company')
                      CompanyEnrollmentForm(
                        programmeId: widget.programmeId,
                        programmeTitle: widget.programmeTitle,
                        onSubmit: _handleCompanyDataCollected,
                        onCancel: () =>
                            setState(() => _selectedEnrollmentType = null),
                      )
                    else if (_selectedEnrollmentType == 'individual' &&
                        !_showIndividualForm)
                      _buildIndividualEnrollmentMessage(colors)
                    else if (_selectedEnrollmentType == 'individual' &&
                        _showIndividualForm)
                      EnrollmentFormWidget(
                        enrollmentType: 'learnership',
                        trainingId: widget.programmeId,
                        trainingTitle: widget.programmeTitle,
                        // HARDENED: Calculate fee from role, fallback to programmeFee or calculated price
                        enrollmentFee: widget.programmeFee ?? 0.0,
                        currency: CurrencyService.instance.userCurrency,
                        isCompanyEnrollment: false,
                        onSubmit: _handleIndividualDataCollected,
                        onCancel: () =>
                            setState(() => _showIndividualForm = false),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgrammeHeader(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LEARNERSHIP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.programmeTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (widget.programmeDescription != null) ...[
              const SizedBox(height: 8),
              Text(widget.programmeDescription!,
                  style: TextStyle(color: colors.onSurface)),
            ],
            if (widget.programmeDuration != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${widget.programmeDuration}',
                    style: TextStyle(color: colors.onSurface, fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualEnrollmentMessage(ColorScheme colors) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'Individual Enrollment',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              'Individual learnership enrollments require prerequisite evidence submission and admin approval after payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurface),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: colors.outline.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next Steps:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface)),
                  const SizedBox(height: 12),
                  _buildStep('1. Complete payment to reserve your spot'),
                  _buildStep('2. Your enrollment will be provisional'),
                  _buildStep('3. Upload prerequisite evidence'),
                  _buildStep('4. Admin reviews evidence'),
                  _buildStep('5. Status updates to Confirmed once approved'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _selectedEnrollmentType = null),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _showIndividualForm = true),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue to Form'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _handleIndividualDataCollected(Map<String, dynamic> learnerData) {
    setState(() => _collectedData = {
          'enrollment_type': 'individual',
          ...learnerData,
        });

    _proceedToPayment();
  }

  void _handleCompanyDataCollected(Map<String, dynamic> companyData) {
    setState(() {
      _collectedData = {
        'enrollment_type': 'company',
        ...companyData,
      };
      
      // Extract and store company location for auto-filling learner forms
      _companyLocation = {
        'country_id': companyData['selected_country'],
        'state_id': companyData['selected_state'],
        'city_id': companyData['selected_city'],
        'country_code': companyData['country_code'],
      };
    });

    _proceedToPayment();
  }

  Future<void> _proceedToPayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Build metadata from collected form data
      final metadata = {
        ...?_collectedData,
        'programme_id': widget.programmeId.toString(),
        'programme_title': widget.programmeTitle,
        'programme_role': widget.programmeRole ?? 'SOC Analyst',
        'currency': CurrencyService.instance.userCurrency,
      };

      final amount = widget.programmeFee ?? 0.0;
      final quantity = (_collectedData?['number_of_learners'] as int?) ?? 1;
      final totalAmount = amount * quantity;

      // Initiate payment
      final response = await ApiClient.initiatePayment(
        programId: widget.programmeId.toString(),
        type: 'learnership',
        amount: totalAmount,
        metadata: metadata,
      );

      if (!mounted) return;

      // Navigate to payment selection page
      await PaymentProviderSelectionPage.show(
        context,
        reference: response['reference'] as String,
        amount: totalAmount,
        currency: 'ZAR',
        country: 'ZA',
        programId: widget.programmeId.toString(),
        programType: 'learnership',
        paymentMetadata: {'programme_id': widget.programmeId.toString()},
        enrollmentPayload: metadata,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
