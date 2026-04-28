// lib/src/presentation/pages/enrollment/complete_enrollment_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

import '../../widgets/enrollment/enrollment_form_widget.dart';
import '../payment/payment_provider_selection_page.dart';
import '../../widgets/headers/enrollment_page_header.dart';
import '../../../core/services/currency_service.dart';

/// Complete Enrollment Page
/// Handles full enrollment flow for individual learners
class CompleteEnrollmentPage extends StatefulWidget {
  final String
      enrollmentType; // 'learnership', 'industry_training', 'masterclass'
  final int trainingId;
  final String trainingTitle;
  final double enrollmentFee;
  final String currency;
  final String? trainingDescription;
  final String? trainingDuration;

  const CompleteEnrollmentPage({
    super.key,
    required this.enrollmentType,
    required this.trainingId,
    required this.trainingTitle,
    required this.enrollmentFee,
    required this.currency,
    this.trainingDescription,
    this.trainingDuration,
  });

  @override
  State<CompleteEnrollmentPage> createState() => _CompleteEnrollmentPageState();
}

class _CompleteEnrollmentPageState extends State<CompleteEnrollmentPage> {
  bool _isCreatingEnrollment = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          // Header with back button
          EnrollmentPageHeader(
            title: 'Complete Enrollment',
            subtitle: _formatEnrollmentType(widget.enrollmentType),
            showBackButton: false,
            onBack: () => context.go('/onboarding'),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course information card
                    _buildCourseHeader(),
                    const SizedBox(height: 24),

                    // Enrollment form
                    EnrollmentFormWidget(
                      enrollmentType: widget.enrollmentType,
                      trainingId: widget.trainingId,
                      trainingTitle: widget.trainingTitle,
                      enrollmentFee: widget.enrollmentFee,
                      currency: widget.currency,
                      onSubmit: _handleEnrollmentSubmit,
                      onCancel: () => context.pop(),
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

  Widget _buildCourseHeader() {
    final theme = Theme.of(context);

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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatEnrollmentType(widget.enrollmentType),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.trainingTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (widget.trainingDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.trainingDescription!,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (widget.trainingDuration != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${widget.trainingDuration}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleEnrollmentSubmit(
      Map<String, dynamic> enrollmentData) async {
    setState(() => _isCreatingEnrollment = true);

    try {
      // Resolve country code from the selected country ID — no backend enrollment yet
      final countryId = enrollmentData['selected_country']?.toString() ?? '';
      String countryCode = 'ZA';
      try {
        final countries = await ApiClient.getAfricanCountries();
        final selectedCountry = countries.firstWhere(
          (country) => country['id'].toString() == countryId,
          orElse: () => {'code': 'ZA'},
        );
        countryCode = selectedCountry['code'] as String? ?? 'ZA';
      } catch (e) {
        debugPrint('Error getting country code: $e');
      }

      setState(() => _isCreatingEnrollment = false);
      if (!mounted) return;

      // Open payment selection — provisional enrollment is created AFTER payment commitment
      await PaymentProviderSelectionPage.show(
        context,
        reference: 'REF-${widget.trainingId}-${DateTime.now().millisecondsSinceEpoch}',
        amount: widget.enrollmentFee,
        currency: widget.currency,
        country: countryCode,
        programId: widget.trainingId.toString(),
        programType: _mapEnrollmentType(widget.enrollmentType),
        paymentMetadata: {'training_title': widget.trainingTitle},
        enrollmentPayload: enrollmentData,
      );
    } catch (e) {
      setState(() => _isCreatingEnrollment = false);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
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

  String _formatEnrollmentType(String type) {
    switch (type) {
      case 'learnership':
        return 'LEARNERSHIP';
      case 'industry_training':
        return 'INDUSTRY TRAINING';
      case 'masterclass':
        return 'MASTERCLASS';
      default:
        return type.toUpperCase();
    }
  }

  String _mapEnrollmentType(String type) {
    // Map frontend enrollment type to backend API type
    switch (type) {
      case 'learnership':
        return 'learnership';
      case 'industry_training':
        return 'industry';
      case 'masterclass':
        return 'masterclass';
      default:
        return 'course';
    }
  }
}

/// Corporate Bulk Enrollment Page (stub - placeholder implementation)
class CorporateBulkEnrollmentPage extends StatefulWidget {
  final String enrollmentType;
  final int trainingId;
  final String trainingTitle;
  final double enrollmentFeePerLearner;
  final String currency;

  const CorporateBulkEnrollmentPage({
    super.key,
    required this.enrollmentType,
    required this.trainingId,
    required this.trainingTitle,
    required this.enrollmentFeePerLearner,
    required this.currency,
  });

  @override
  State<CorporateBulkEnrollmentPage> createState() =>
      _CorporateBulkEnrollmentPageState();
}

class _CorporateBulkEnrollmentPageState
    extends State<CorporateBulkEnrollmentPage> {
  final List<Map<String, dynamic>> _learners = [];
  bool _isCreatingEnrollment = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          EnrollmentPageHeader(
            title: 'Bulk Enrollment',
            subtitle: 'Corporate Training',
            showBackButton: false,
            onBack: () => context.go('/onboarding'),
            trailing: IconButton(
              icon: Icon(Icons.upload_file, color: colors.onSurface, size: 24),
              onPressed: _uploadCSV,
              tooltip: 'Upload CSV',
              style: IconButton.styleFrom(
                backgroundColor:
                    colors.surfaceContainerHighest.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                // Summary bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colors.primaryContainer.withValues(alpha: 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Learners: ${_learners.length}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total: ${CurrencyService.instance.formatUSDAmount(_learners.length * widget.enrollmentFeePerLearner)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Learners list or empty state
                Expanded(
                  child: _learners.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _learners.length,
                          itemBuilder: (context, index) {
                            return _buildLearnerCard(_learners[index], index);
                          },
                        ),
                ),

                // Bottom action bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addLearner,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Learner'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              _learners.isEmpty ? null : _proceedToPayment,
                          icon: const Icon(Icons.payment),
                          label: const Text('Proceed to Payment'),
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No learners added yet',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add learners manually or upload a CSV file',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnerCard(Map<String, dynamic> learner, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          learner['name'] ?? 'Learner ${index + 1}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          learner['email'] ?? '',
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete,
            color: AppTheme.errorRed,
          ),
          onPressed: () {
            setState(() => _learners.removeAt(index));
          },
        ),
      ),
    );
  }

  void _addLearner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add learner functionality coming soon')),
    );
  }

  void _uploadCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV upload functionality coming soon')),
    );
  }

  Future<void> _proceedToPayment() async {
    setState(() => _isCreatingEnrollment = true);

    // Resolve country code — no backend enrollment created yet
    String countryCode = 'ZA';
    try {
      final countries = await ApiClient.getAfricanCountries();
      if (countries.isNotEmpty) {
        countryCode = countries.firstWhere(
              (country) => country['code'] == 'ZA',
              orElse: () => countries.first,
            )['code'] as String? ??
            'ZA';
      }
    } catch (e) {
      debugPrint('Error getting country code: $e');
    }

    setState(() => _isCreatingEnrollment = false);
    if (!mounted) return;

    // Open payment selection — enrollment is created AFTER payment commitment
    await PaymentProviderSelectionPage.show(
      context,
      reference: 'CORP-${widget.trainingId}-${DateTime.now().millisecondsSinceEpoch}',
      amount: _learners.length * widget.enrollmentFeePerLearner,
      currency: widget.currency,
      country: countryCode,
      programId: widget.trainingId.toString(),
      programType: _mapEnrollmentType(widget.enrollmentType),
      paymentMetadata: {
        'company_enrollment': true,
        'learners_count': _learners.length,
        'training_title': widget.trainingTitle,
      },
      enrollmentPayload: {
        'company_enrollment': true,
        'learners': _learners,
      },
    );
  }

  String _mapEnrollmentType(String type) {
    // Map frontend enrollment type to backend API type
    switch (type) {
      case 'learnership':
        return 'learnership';
      case 'industry_training':
        return 'industry';
      case 'masterclass':
        return 'masterclass';
      default:
        return 'course';
    }
  }
}
