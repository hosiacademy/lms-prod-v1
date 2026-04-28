import 'package:flutter/material.dart';
import '../../../data/models/course.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/currency_service.dart';
import 'package:go_router/go_router.dart';

/// Enhanced enrollment panel for all 4 training types
/// Supports existing students (skips personal info) and new students
class EnhancedEnrollmentPanel extends StatefulWidget {
  final List<Course> courses;
  final bool isExistingStudent;
  final Map<String, dynamic>? existingStudentData;

  const EnhancedEnrollmentPanel({
    super.key,
    required this.courses,
    this.isExistingStudent = false,
    this.existingStudentData,
  });

  @override
  State<EnhancedEnrollmentPanel> createState() =>
      _EnhancedEnrollmentPanelState();
}

class _EnhancedEnrollmentPanelState extends State<EnhancedEnrollmentPanel> {
  int _currentStep = 0;
  bool _isProcessing = false;

  // Enrollment Architecture Selection
  String _enrollmentArchitecture = 'individual'; // 'individual' or 'corporate'

  // Corporate details (if corporate enrollment)
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();

  // Personal info controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Course-specific preferences
  final Map<String, String> _coursePreferences = {};

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  double get _total {
    return widget.courses.fold(0.0, (sum, course) => sum + (course.price ?? 0));
  }

  int get _totalSteps {
    // For existing students: Architecture -> Course Preferences -> Review -> Payment
    // For new students: Architecture -> Personal Info -> Course Preferences -> Review -> Payment
    if (widget.isExistingStudent) {
      return _enrollmentArchitecture == 'corporate' ? 4 : 3;
    } else {
      return _enrollmentArchitecture == 'corporate' ? 5 : 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        // Progress Indicator
        LinearProgressIndicator(
          value: (_currentStep + 1) / _totalSteps,
        ),

        const SizedBox(height: 24),

        // Step Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Step Title
                Text(
                  _getStepTitle(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Existing student indicator
                if (widget.isExistingStudent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user,
                            size: 16, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Welcome back! Using your existing profile',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Step Content
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildCurrentStep(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Navigation Buttons
        _buildNavigationButtons(colors),
      ],
    );
  }

  String _getStepTitle() {
    if (!widget.isExistingStudent) {
      // New student flow
      switch (_currentStep) {
        case 0:
          return 'Step 1: Enrollment Type';
        case 1:
          return 'Step 2: Your Information';
        case 2:
          return _enrollmentArchitecture == 'corporate'
              ? 'Step 3: Company Details'
              : 'Step 3: Course Preferences';
        case 3:
          return _enrollmentArchitecture == 'corporate'
              ? 'Step 4: Course Preferences'
              : 'Step 4: Review & Confirm';
        case 4:
          return 'Step 5: Review & Confirm';
        default:
          return '';
      }
    } else {
      // Existing student flow (skip personal info)
      switch (_currentStep) {
        case 0:
          return 'Step 1: Enrollment Type';
        case 1:
          return _enrollmentArchitecture == 'corporate'
              ? 'Step 2: Company Details'
              : 'Step 2: Course Preferences';
        case 2:
          return _enrollmentArchitecture == 'corporate'
              ? 'Step 3: Course Preferences'
              : 'Step 3: Review & Confirm';
        case 3:
          return 'Step 4: Review & Confirm';
        default:
          return '';
      }
    }
  }

  Widget _buildCurrentStep() {
    if (!widget.isExistingStudent) {
      // New student flow
      switch (_currentStep) {
        case 0:
          return _buildEnrollmentArchitectureStep();
        case 1:
          return _buildPersonalInfoStep();
        case 2:
          return _enrollmentArchitecture == 'corporate'
              ? _buildCorporateDetailsStep()
              : _buildCoursePreferencesStep();
        case 3:
          return _enrollmentArchitecture == 'corporate'
              ? _buildCoursePreferencesStep()
              : _buildReviewStep();
        case 4:
          return _buildReviewStep();
        default:
          return const SizedBox();
      }
    } else {
      // Existing student flow
      switch (_currentStep) {
        case 0:
          return _buildEnrollmentArchitectureStep();
        case 1:
          return _enrollmentArchitecture == 'corporate'
              ? _buildCorporateDetailsStep()
              : _buildCoursePreferencesStep();
        case 2:
          return _enrollmentArchitecture == 'corporate'
              ? _buildCoursePreferencesStep()
              : _buildReviewStep();
        case 3:
          return _buildReviewStep();
        default:
          return const SizedBox();
      }
    }
  }

  Widget _buildEnrollmentArchitectureStep() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to enroll?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Architecture Selection Cards
        Row(
          children: [
            Expanded(
              child: _buildArchitectureCard(
                'Individual',
                Icons.person,
                'Enroll as an individual learner',
                _enrollmentArchitecture == 'individual',
                () => setState(() => _enrollmentArchitecture = 'individual'),
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildArchitectureCard(
                'Corporate',
                Icons.business,
                'Company-sponsored enrollment',
                _enrollmentArchitecture == 'corporate',
                () => setState(() => _enrollmentArchitecture = 'corporate'),
                colors,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Courses Summary
        _buildCoursesListSummary(theme, colors),
      ],
    );
  }

  Widget _buildArchitectureCard(
    String title,
    IconData icon,
    String description,
    bool isSelected,
    VoidCallback onTap,
    ColorScheme colors,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
              size: 48,
              color: isSelected ? colors.primary : colors.onSurface,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? colors.primary : colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                    isSelected ? colors.onPrimaryContainer : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTextField(_fullNameController, 'Full Name *', Icons.person),
          const SizedBox(height: 16),
          _buildTextField(_emailController, 'Email Address *', Icons.email,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField(_phoneController, 'Phone Number *', Icons.phone,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(
              _idNumberController, 'ID/Passport Number *', Icons.badge),
          const SizedBox(height: 16),
          _buildTextField(_addressController, 'Physical Address *', Icons.home),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      _cityController, 'City *', Icons.location_city)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildTextField(_postalCodeController, 'Postal Code *',
                      Icons.markunread_mailbox)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildCorporateDetailsStep() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyNameController,
          decoration: const InputDecoration(
            labelText: 'Company Name *',
            hintText: 'Enter company name',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyEmailController,
          decoration: const InputDecoration(
            labelText: 'Company Email *',
            hintText: 'company@example.com',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyPhoneController,
          decoration: const InputDecoration(
            labelText: 'Company Phone *',
            hintText: 'Enter phone number',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildCoursePreferencesStep() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course-Specific Preferences',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your preferences for each course',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 24),

        // List each course with its specific options
        ...widget.courses
            .map((course) => _buildCoursePreferenceCard(course, theme, colors)),
      ],
    );
  }

  Widget _buildCoursePreferenceCard(
      Course course, ThemeData theme, ColorScheme colors) {
    final courseType = course.courseType ?? 'custom_selection';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (course.featureImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      course.featureImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: colors.surfaceContainerHighest,
                        child: Icon(Icons.school, color: colors.onSurface),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.displayTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCourseTypeLabel(courseType),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Course-type specific options
            _buildCourseTypeOptions(course, courseType, theme, colors),
          ],
        ),
      ),
    );
  }

  String _getCourseTypeLabel(String courseType) {
    switch (courseType) {
      case 'masterclass':
        return 'Masterclass';
      case 'learnership':
        return 'Learnership';
      case 'industry_training':
        return 'Industry-Based Training';
      case 'custom_selection':
        return 'Custom Selection';
      default:
        return 'Course';
    }
  }

  Widget _buildCourseTypeOptions(
      Course course, String courseType, ThemeData theme, ColorScheme colors) {
    switch (courseType) {
      case 'masterclass':
        return _buildMasterclassOptions(course, theme, colors);
      case 'learnership':
        return _buildLearnershipOptions(course, theme, colors);
      case 'industry_training':
        return _buildIndustryTrainingOptions(course, theme, colors);
      case 'custom_selection':
        return _buildCustomSelectionOptions(course, theme, colors);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMasterclassOptions(
      Course course, ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masterclass Options',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _coursePreferences['${course.id}_live_session'] == 'true',
          onChanged: (value) {
            setState(() {
              _coursePreferences['${course.id}_live_session'] =
                  value.toString();
            });
          },
          title: const Text('Attend live sessions'),
          subtitle: const Text('Join interactive sessions with the instructor'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: _coursePreferences['${course.id}_recording_access'] == 'true',
          onChanged: (value) {
            setState(() {
              _coursePreferences['${course.id}_recording_access'] =
                  value.toString();
            });
          },
          title: const Text('Access to recordings'),
          subtitle: const Text('Watch session recordings at your own pace'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildLearnershipOptions(
      Course course, ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learnership Options',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Preferred Start Date',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'immediate', child: Text('Immediate')),
            DropdownMenuItem(value: 'next_month', child: Text('Next Month')),
            DropdownMenuItem(
                value: 'next_quarter', child: Text('Next Quarter')),
          ],
          onChanged: (value) {
            setState(() {
              _coursePreferences['${course.id}_start_date'] = value ?? '';
            });
          },
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value:
              _coursePreferences['${course.id}_workplace_training'] == 'true',
          onChanged: (value) {
            setState(() {
              _coursePreferences['${course.id}_workplace_training'] =
                  value.toString();
            });
          },
          title: const Text('Include workplace training'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildIndustryTrainingOptions(
      Course course, ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Industry Training Options',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Training Mode',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'online', child: Text('Online')),
            DropdownMenuItem(value: 'in_person', child: Text('In-Person')),
            DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
          ],
          onChanged: (value) {
            setState(() {
              _coursePreferences['${course.id}_training_mode'] = value ?? '';
            });
          },
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _coursePreferences['${course.id}_certification'] == 'true',
          onChanged: (value) {
            setState(() {
              _coursePreferences['${course.id}_certification'] =
                  value.toString();
            });
          },
          title: const Text('Include industry certification'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildCustomSelectionOptions(
      Course course, ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Options',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _coursePreferences['${course.id}_certificate'] == 'true',
          onChanged: (value) {
            setState(() {
              _coursePreferences['${course.id}_certificate'] = value.toString();
            });
          },
          title: const Text('Certificate of completion'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enrollment Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enrollment Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildSummaryRow(
                    'Enrollment Type:',
                    _enrollmentArchitecture == 'individual'
                        ? 'Individual'
                        : 'Corporate'),
                if (widget.isExistingStudent)
                  _buildSummaryRow(
                      'Student:',
                      widget.existingStudentData?['name'] ??
                          'Existing Student'),
                if (_enrollmentArchitecture == 'corporate' &&
                    _companyNameController.text.isNotEmpty)
                  _buildSummaryRow('Company:', _companyNameController.text),
                _buildSummaryRow(
                    'Number of Courses:', widget.courses.length.toString()),
                const Divider(),
                _buildSummaryRow(
                  'Total Amount:',
                  CurrencyService.instance.formatUSDAmount(_total),
                  isBold: true,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Courses List
        Text(
          'Courses',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        ...widget.courses.map((course) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: course.featureImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          course.featureImageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: colors.surfaceContainerHighest,
                        child: Icon(Icons.school, color: colors.onSurface),
                      ),
                title: Text(course.displayTitle),
                subtitle: Text(_getCourseTypeLabel(
                    course.courseType ?? 'custom_selection')),
                trailing: Text(
                  CurrencyService.instance.formatUSDAmount(course.price ?? 0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
            )),
      ],
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

  Widget _buildCoursesListSummary(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Courses (${widget.courses.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.courses.map((course) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: course.featureImageUrl != null
                      ? Image.network(
                          course.featureImageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          color: colors.surfaceContainerHighest,
                        ),
                ),
                title: Text(
                  course.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_getCourseTypeLabel(
                    course.courseType ?? 'custom_selection')),
                trailing:
                    Text(CurrencyService.instance.formatUSDAmount(course.price ?? 0)),
              ),
            )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              Text(
                CurrencyService.instance.formatUSDAmount(_total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(ColorScheme colors) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isProcessing ? null : () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
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
                  : Text(isLastStep ? 'Proceed to Payment' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Final step - proceed to payment
      await _proceedToPayment();
    }
  }

  Future<void> _proceedToPayment() async {
    setState(() => _isProcessing = true);

    try {
      final isCorporate = _enrollmentArchitecture == 'corporate';
      final trainingType = widget.courses.length > 1
          ? 'custom_selection'
          : (widget.courses.first.courseType ?? 'industry_training');

      Map<String, dynamic> result;

      if (isCorporate) {
        // Bulk enrollment for company
        final List<Map<String, dynamic>> learners = [
          if (!widget.isExistingStudent)
            {
              'full_name': _fullNameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _phoneController.text.trim(),
              'id_number': _idNumberController.text.trim(),
              'address': _addressController.text.trim(),
              'city': _cityController.text.trim(),
              'country': 'South Africa', // Default or get from dropdown
              'postal_code': _postalCodeController.text.trim(),
              'dob': '1990-01-01', // Placeholder or add picker
              'gender': 'Other',
              'occupation': 'Employee',
              'education_level': 'Degree',
              'institution': _companyNameController.text.trim(),
              'emergency_contact_name': 'Emergency',
              'emergency_contact_phone': _phoneController.text.trim(),
              'emergency_contact_relationship': 'Family',
            }
          // In a real bulk flow, we'd add more learners here
        ];

        final bulkData = {
          'company_name': _companyNameController.text.trim(),
          'contact_email': _companyEmailController.text.trim(),
          'contact_phone': _companyPhoneController.text.trim(),
          'training_id': int.parse(widget.courses.first.id),
          'enrollment_type': trainingType,
          'learners': learners,
          'total_amount': _total,
          'currency': 'USD',
        };

        final bulkResponse = await ApiClient.createBulkEnrollment(bulkData);
        result = await ApiClient.proceedToPayment(
          enrollmentId: bulkResponse['id'],
          isBulk: true,
        );
      } else {
        // Individual enrollment
        final enrollmentData = {
          'training_id': int.parse(widget.courses.first.id),
          'enrollment_type': trainingType,
          'learner_full_name': _fullNameController.text.trim(),
          'learner_email': _emailController.text.trim(),
          'learner_phone': _phoneController.text.trim(),
          'learner_id_number': _idNumberController.text.trim(),
          'learner_address': _addressController.text.trim(),
          'learner_city': _cityController.text.trim(),
          'learner_country': 'South Africa',
          'learner_postal_code': _postalCodeController.text.trim(),
          'learner_dob': '1990-01-01',
          'learner_gender': 'Other',
          'current_occupation': 'Student',
          'education_level': 'Matric',
          'institution': 'None',
          'emergency_contact_name': 'Emergency',
          'emergency_contact_phone': _phoneController.text.trim(),
          'emergency_contact_relationship': 'Family',
          'terms_accepted': true,
          'metadata': {
            'selected_course_ids':
                widget.courses.map((c) => int.parse(c.id)).toList(),
          },
        };

        final enrollmentResponse =
            await ApiClient.createEnrollment(enrollmentData);
        result = await ApiClient.proceedToPayment(
          enrollmentId: enrollmentResponse['id'],
          isBulk: false,
        );
      }

      if (mounted) {
        setState(() => _isProcessing = false);

        // Close enrollment panel/modal
        Navigator.of(context).pop();

        // Navigate to payment selection page
        context.push(
          '/payment',
          extra: {
            'orderId': result['order_id'],
            'amount': result['amount'],
            'currency': result['currency'] ?? 'USD',
            'programId': widget.courses.first.id,
            'programType': trainingType,
            'metadata': {
              'is_corporate': isCorporate,
              'enrollment_id': result['enrollment_id'] ?? result['id'],
              'training_type': trainingType,
            },
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
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
