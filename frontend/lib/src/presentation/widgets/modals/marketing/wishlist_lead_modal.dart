// lib/src/presentation/widgets/modals/marketing/wishlist_lead_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/course.dart';
import '../../../../core/utils/african_phone_validator.dart';
import '../../contact_otp_field.dart';

class WishlistLeadModal extends StatefulWidget {
  final Course course;
  final String trainingType;
  final Function(String interestLevel, String timing, String? notes) onComplete;

  const WishlistLeadModal({
    super.key,
    required this.course,
    this.trainingType = 'course',
    required this.onComplete,
  });

  @override
  State<WishlistLeadModal> createState() => _WishlistLeadModalState();
}

class _WishlistLeadModalState extends State<WishlistLeadModal> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _emailVerified = false;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Country/Phone state
  String _phoneIsoCode = 'ZA';

  // Feedback Dropdown Values
  String? _selectedGoal;
  String? _selectedStatus;
  String? _selectedTiming;
  String? _selectedExpectation;

  // Options
  final List<String> _goalOptions = [
    'Career Advancement',
    'Skill Acquisition',
    'Professional Certification',
    'Personal Interest',
    'Employer Requirement'
  ];

  final List<String> _statusOptions = [
    'Student',
    'Entry-level Professional',
    'Mid-level Professional',
    'Senior Professional',
    'Executive',
    'Self-employed',
    'Seeking Opportunity'
  ];

  final List<String> _timingOptions = [
    'Immediately',
    'Within 1 month',
    'Within 3 months',
    'In 6+ months',
    'Just exploring'
  ];

  final List<String> _expectationOptions = [
    'Industry-recognized certification',
    'Hands-on technical projects',
    'Expert mentorship & support',
    'Flexible learning schedule',
    'Job placement assistance'
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (!_emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email address to continue.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    setState(() => _currentStep++);
  }

  void _previousStep() {
    setState(() => _currentStep--);
  }

  Future<void> _submitLead() async {
    if (_selectedGoal == null ||
        _selectedStatus == null ||
        _selectedTiming == null ||
        _selectedExpectation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all survey questions.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final phoneInfo = AfricanPhoneValidator.getInfoForCountry(_phoneIsoCode);
      final formattedPhone = AfricanPhoneValidator.formatWithCountryCode(
          _phoneController.text.trim(), _phoneIsoCode);

      await ApiClient.post('/api/v1/marketing/leads/', data: {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': formattedPhone,
        'country_iso': _phoneIsoCode,
        'training_type': widget.trainingType,
        'object_id': widget.course.id,
        'title': widget.course.title,
        'goals': _selectedGoal,
        'professional_status': _selectedStatus,
        'planned_start': _selectedTiming,
        'expectations': _selectedExpectation,
        'is_wishlist': true,
      });

      if (mounted) {
        widget.onComplete(
          _selectedGoal ?? 'Career Advancement',
          _selectedTiming ?? 'Immediately',
          _selectedExpectation,
        );
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully added to wishlist! We\'ll keep you updated on specials.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save interest: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 800),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(colors, theme),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 0
                        ? _buildContactStep(colors, theme)
                        : _buildSurveyStep(colors, theme),
                  ),
                ),
              ),
              _buildFooter(colors, theme),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildHeader(ColorScheme colors, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Keep in Touch',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add "${widget.course.title}" to your wishlist and unlock exclusive promotions, launch specials, and career insights.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep(ColorScheme colors, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('contact_step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'you@example.com',
            ),
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!)) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 8),
          ContactOtpField(
            contactController: _emailController,
            onVerifiedChanged: (verified) {
              setState(() => _emailVerified = verified);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Mobile Contact',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPhoneField(colors),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We\'ll use your contacts to notify you about early-bird discounts and regional masterclasses.',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyStep(ColorScheme colors, ThemeData theme) {
    return Column(
      key: const ValueKey('survey_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help us tailor your journey',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Your feedback helps us quantify regional demand and optimize our certification pathways.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _buildDropdown(
          label: 'What is your primary learning goal?',
          value: _selectedGoal,
          items: _goalOptions,
          icon: Icons.flag_outlined,
          onChanged: (v) => setState(() => _selectedGoal = v),
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Current professional status?',
          value: _selectedStatus,
          items: _statusOptions,
          icon: Icons.work_outline,
          onChanged: (v) => setState(() => _selectedStatus = v),
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'When do you plan to start?',
          value: _selectedTiming,
          items: _timingOptions,
          icon: Icons.calendar_today_outlined,
          onChanged: (v) => setState(() => _selectedTiming = v),
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Key expectation from Hosi Academy?',
          value: _selectedExpectation,
          items: _expectationOptions,
          icon: Icons.stars_outlined,
          onChanged: (v) => setState(() => _selectedExpectation = v),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          hint: const Text('Select an option'),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPhoneField(ColorScheme colors) {
    final info = AfricanPhoneValidator.getInfoForCountry(_phoneIsoCode);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: DropdownButtonFormField<String>(
            value: _phoneIsoCode,
            decoration: const InputDecoration(
              labelText: 'Country',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: AfricanPhoneValidator.supportedCountries.map((iso) {
              final countryInfo = AfricanPhoneValidator.getInfoForCountry(iso);
              return DropdownMenuItem<String>(
                value: iso,
                child: Row(
                  children: [
                    Image.network(
                      'https://flagcdn.com/w20/${iso.toLowerCase()}.png',
                      width: 20,
                      errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(countryInfo?.countryCode ?? ''),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _phoneIsoCode = val);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(info?.maxDigits ?? 15),
            ],
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              hintText: 'e.g. ${'0' * (info?.minDigits ?? 9)}',
              counterText: "",
            ),
            maxLength: info?.maxDigits,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (info != null) {
                if (value.length < info.minDigits) return 'Too short';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme colors, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: _isSubmitting ? null : (_currentStep == 0 ? _nextStep : _submitLead),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_currentStep == 0 ? 'Continue' : 'Add to Wishlist'),
          ),
        ],
      ),
    );
  }
}
