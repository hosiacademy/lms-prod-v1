import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/currency_service.dart';
import '../../../data/models/course.dart';
import '../../blocs/student_portal/location_bloc.dart';
import '../../widgets/enrollment/enrollment_form_widget.dart';

/// Bulk enrollment panel for multiple courses (simplified 3-step)
class BulkEnrollmentPanel extends StatefulWidget {
  final List<Course> courses;
  final VoidCallback? onEnrollmentComplete;

  const BulkEnrollmentPanel({
    super.key,
    required this.courses,
    this.onEnrollmentComplete,
  });

  @override
  State<BulkEnrollmentPanel> createState() => _BulkEnrollmentPanelState();
}

class _BulkEnrollmentPanelState extends State<BulkEnrollmentPanel> {
  int _currentStep = 0;
  bool _isProcessing = false;

  // Step 0: Profile Verification
  Map<String, dynamic>? _studentProfile;
  bool _isLoadingProfile = true;
  bool _profileComplete = false;
  bool _useExistingProfile = true;

  // Step 1: Enrollment Type
  String _enrollmentType = 'individual'; // 'individual' or 'corporate'

  // Step 2: Payment
  String? _selectedPaymentMethod;
  String? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    try {
      final profile = await ApiClient.checkExistingStudent();
      if (mounted) {
        setState(() {
          _studentProfile = profile;
          _isLoadingProfile = false;
          // Check if profile has enough data (e.g., country/city/address)
          _profileComplete = profile['country'] != null &&
              profile['city'] != null &&
              profile['address'] != null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _profileComplete = false;
        });
      }
    }
  }

  double get _total {
    return widget.courses.fold(0.0, (sum, course) => sum + (course.price ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => LocationBloc(),
      child: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
          ),

          const SizedBox(height: 24),

          // Step Title
          Text(
            _getStepTitle(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Step Content
          Expanded(
            child: _isLoadingProfile
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: IndexedStack(
                      index: _currentStep,
                      children: [
                        _buildStep0(), // Profile Verification
                        _buildStep1(), // Enrollment Type
                        _buildStep2(), // Payment Method
                        _buildStep3(), // Review & Confirm
                      ],
                    ),
                  ),
          ),

          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 3
                            ? 'Complete Enrollment'
                            : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Step 1: Verify Your Information';
      case 1:
        return 'Step 2: Enrollment Type';
      case 2:
        return 'Step 3: Payment Method';
      case 3:
        return 'Step 4: Review & Confirm';
      default:
        return '';
    }
  }

  Widget _buildStep0() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (!_useExistingProfile || _studentProfile == null || !_profileComplete) {
      return EnrollmentFormWidget(
        enrollmentType: 'masterclass', // Default for courses
        trainingId: int.tryParse(widget.courses.first.id) ?? 0,
        trainingTitle: widget.courses.length > 1
            ? 'Bulk Enrollment (${widget.courses.length} courses)'
            : widget.courses.first.displayTitle,
        enrollmentFee: _total,
        currency: 'USD',
        onSubmit: (data) {
          setState(() {
            _studentProfile = data;
            _profileComplete = true;
            _useExistingProfile = true;
            _currentStep = 1; // Move to next step manually on submit
          });
        },
        onCancel: _studentProfile != null
            ? () => setState(() => _useExistingProfile = true)
            : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'We have your details on file. Is this information still correct?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow('Full Name:',
                      _studentProfile!['full_name'] ?? 'Not specified'),
                  _buildSummaryRow(
                      'Email:', _studentProfile!['email'] ?? 'Not specified'),
                  _buildSummaryRow('Country:',
                      _studentProfile!['country_name'] ?? 'Not specified'),
                  _buildSummaryRow('City:',
                      _studentProfile!['city_name'] ?? 'Not specified'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: _useExistingProfile,
                onChanged: (val) => setState(() => _useExistingProfile = val!),
              ),
              const Text('Yes, use this information'),
            ],
          ),
          Row(
            children: [
              Radio<bool>(
                value: false,
                groupValue: _useExistingProfile,
                onChanged: (val) => setState(() => _useExistingProfile = val!),
              ),
              const Text('No, I need to update my details'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enrollment Type Selection
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                'Individual',
                Icons.person,
                _enrollmentType == 'individual',
                () => setState(() => _enrollmentType = 'individual'),
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTypeCard(
                'Corporate',
                Icons.business,
                _enrollmentType == 'corporate',
                () => setState(() => _enrollmentType = 'corporate'),
                colors,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Courses List
        Text(
          'Courses (${widget.courses.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...widget.courses.map((course) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: course.featureImageUrl != null
                        ? Image.network(
                            course.featureImageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(color: colors.surfaceContainerHighest),
                  ),
                ),
                title: Text(
                  course.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle:
                    Text(CurrencyService.instance.formatPrice(course.price ?? 0.0)),
              ),
            )),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment method selection will go here'),
        const SizedBox(height: 16),
        const Text('TODO: Integrate with existing payment provider selection'),
      ],
    );
  }

  Widget _buildStep3() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildSummaryRow('Enrollment Type:', _enrollmentType),
                _buildSummaryRow(
                    'Number of Courses:', widget.courses.length.toString()),
                _buildSummaryRow(
                    'Payment Method:', _selectedProvider ?? 'Not selected'),
                const Divider(),
                _buildSummaryRow(
                  'Total:',
                  CurrencyService.instance.formatPrice(_total),
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    ColorScheme colors,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer : colors.surface,
          border: Border.all(
            color: isSelected ? colors.primary : colors.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? colors.primary : colors.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? colors.primary : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Process enrollment
      setState(() => _isProcessing = true);
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pop();
        _showSuccessDialog();
        widget.onEnrollmentComplete?.call();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Enrollment Successful!'),
          ],
        ),
        content: Text(
          'You have successfully enrolled in ${widget.courses.length} course${widget.courses.length > 1 ? 's' : ''}!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to dashboard
            },
            child: const Text('Go to My Courses'),
          ),
        ],
      ),
    );
  }
}
