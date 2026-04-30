import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/utils/african_phone_validator.dart';
import '../../../../widgets/contact_otp_field.dart';

class InstructorApplicationModal extends StatefulWidget {
  const InstructorApplicationModal({Key? key}) : super(key: key);

  @override
  State<InstructorApplicationModal> createState() =>
      _InstructorApplicationModalState();
}

class _InstructorApplicationModalState
    extends State<InstructorApplicationModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _headlineController = TextEditingController();
  final _specializationController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _motivationController = TextEditingController();

  PlatformFile? _cvFile;
  PlatformFile? _certificatesFile;
  List<PlatformFile> _additionalFiles = [];

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isSuccess = false;

  bool _emailVerified = false;
  bool _phoneVerified = true;
  String _phoneIsoCode = 'ZA';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _headlineController.dispose();
    _specializationController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_emailVerified) {
      setState(() => _errorMessage = 'Please verify your email address first');
      return;
    }
    if (!_phoneVerified) {
      setState(() => _errorMessage = 'Please verify your phone number first');
      return;
    }

    // Validate CV is uploaded
    if (_cvFile == null) {
      setState(() {
        _errorMessage = 'Please upload your CV/Resume';
      });
      return;
    }

    // Validate additional files (max 5)
    if (_additionalFiles.length > 5) {
      setState(() {
        _errorMessage = 'Maximum 5 additional attachments allowed';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final formData = FormData.fromMap({
        'applicant_name': _nameController.text.trim(),
        'applicant_email': _emailController.text.trim(),
        'applicant_phone': AfricanPhoneValidator.formatWithCountryCode(
            _phoneController.text.trim(), _phoneIsoCode),
        'professional_headline': _headlineController.text.trim(),
        'areas_of_expertise': _specializationController.text.trim(),
        'top_qualifications': _qualificationsController.text.trim(),
        'years_of_experience': int.tryParse(_experienceController.text) ?? 0,
        'motivation_letter': _motivationController.text.trim(),
      });

      // Add CV
      if (_cvFile != null) {
        if (_cvFile!.bytes != null) {
          formData.files.add(MapEntry(
            'cv_file',
            MultipartFile.fromBytes(_cvFile!.bytes!, filename: _cvFile!.name),
          ));
        } else if (_cvFile!.path != null) {
          formData.files.add(MapEntry(
            'cv_file',
            await MultipartFile.fromFile(_cvFile!.path!,
                filename: _cvFile!.name),
          ));
        }
      }

      // Add certificates
      if (_certificatesFile != null) {
        if (_certificatesFile!.bytes != null) {
          formData.files.add(MapEntry(
            'certificates_file',
            MultipartFile.fromBytes(_certificatesFile!.bytes!,
                filename: _certificatesFile!.name),
          ));
        } else if (_certificatesFile!.path != null) {
          formData.files.add(MapEntry(
            'certificates_file',
            await MultipartFile.fromFile(_certificatesFile!.path!,
                filename: _certificatesFile!.name),
          ));
        }
      }

      // Add additional attachments (max 5)
      for (int i = 0; i < _additionalFiles.length && i < 5; i++) {
        final file = _additionalFiles[i];
        if (file.bytes != null) {
          formData.files.add(MapEntry(
            'additional_attachment_${i + 1}',
            MultipartFile.fromBytes(file.bytes!, filename: file.name),
          ));
        } else if (file.path != null) {
          formData.files.add(MapEntry(
            'additional_attachment_${i + 1}',
            await MultipartFile.fromFile(file.path!, filename: file.name),
          ));
        }
      }

      final response = await ApiClient.post(
        '/api/v1/instructors/applications/',
        data: formData,
      );

      if (response.statusCode == 201) {
        setState(() {
          _isSuccess = true;
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Submission failed. Please try again later.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please check your connection.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _isSuccess
                ? _buildSuccessState(theme)
                : _buildFormState(theme, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 80,
        ),
        const SizedBox(height: 24),
        Text(
          'Application Submitted!',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Thank you for your interest in joining Hosi Academy. Our team will review your qualifications and contact you soon via email.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormState(ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Apply to be an Instructor',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Join our community of world-class certified trainers.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          _buildSectionTitle('Personal Information'),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'e.g. John Doe',
            icon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Full name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
              if (!_emailVerified) return 'Please verify your email first';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'john@example.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey[50]!,
            ),
          ),
          ContactOtpField(
            contactController: _emailController,
            contactType: 'email',
            onVerifiedChanged: (verified) => setState(() => _emailVerified = verified),
          ),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 24),
          _buildSectionTitle('Professional Details'),
          _buildTextField(
            controller: _headlineController,
            label: 'Professional Headline',
            hint: 'e.g. Senior AI Architect & Blockchain Developer',
            icon: Icons.work_outline,
            validator: (v) => v!.isEmpty ? 'Headline is required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _specializationController,
            label: 'Areas of Expertise',
            hint: 'e.g. Generative AI, Ethereum, Prompt Engineering',
            icon: Icons.psychology_outlined,
            validator: (v) =>
                v!.isEmpty ? 'Expertise labels are required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _qualificationsController,
                  label: 'Top Qualifications',
                  hint: 'e.g. PhD in Computer Science, AICerts Certified',
                  icon: Icons.school_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: _experienceController,
                  label: 'Years Exp.',
                  hint: '5',
                  icon: Icons.history_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Motivation Letter'),
          _buildTextField(
            controller: _motivationController,
            label: 'Why do you want to teach at Hosi Academy?',
            hint: 'Tell us about your passion for teaching and what you hope to contribute...',
            icon: Icons.favorite_outline,
            validator: (v) => v!.isEmpty ? 'Motivation letter is required' : null,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Supporting Documents'),
          _buildFilePicker(
            label: 'Upload CV / Resume (Required)',
            file: _cvFile,
            onPick: () => _pickFile('cv'),
            onRemove: () => setState(() => _cvFile = null),
          ),
          const SizedBox(height: 16),
          _buildFilePicker(
            label: 'Certificates (PDF/ZIP)',
            file: _certificatesFile,
            onPick: () => _pickFile('certificates'),
            onRemove: () => setState(() => _certificatesFile = null),
          ),
          const SizedBox(height: 16),
          _buildAdditionalAttachmentsSection(theme, isDark),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Submit Application',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    final colors = Theme.of(context).colorScheme;
    final validatorCountries = AfricanPhoneValidator.africanPhoneInfo.keys.toList();
    final info = AfricanPhoneValidator.getInfoForCountry(_phoneIsoCode);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 130,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _phoneIsoCode,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: validatorCountries.map((iso) {
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
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            maxLength: info?.maxDigits,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Phone is required';
              final phoneInfo = AfricanPhoneValidator.getInfoForCountry(_phoneIsoCode);
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor:
            isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey[50]!,
      ),
    );
  }

  Future<void> _pickFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        if (type == 'cv') {
          _cvFile = result.files.first;
        } else if (type == 'certificates') {
          _certificatesFile = result.files.first;
        } else if (type == 'additional' && _additionalFiles.length < 5) {
          _additionalFiles.add(result.files.first);
        }
      });
    }
  }

  void _removeAdditionalFile(int index) {
    setState(() {
      _additionalFiles.removeAt(index);
    });
  }

  Widget _buildAdditionalAttachmentsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Additional Attachments (Max 5)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            if (_additionalFiles.length < 5)
              TextButton.icon(
                onPressed: () => _pickFile('additional'),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add File'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_additionalFiles.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Optional: Upload additional supporting documents such as portfolios, reference letters, transcripts, etc. (Max 5 files)',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ..._additionalFiles.asMap().entries.map((entry) {
                int index = entry.key;
                PlatformFile file = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file,
                          color: theme.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${index + 1}. ${file.name}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.grey),
                        onPressed: () => _removeAdditionalFile(index),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
      ],
    );
  }

  Widget _buildFilePicker({
    required String label,
    required PlatformFile? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            )),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  file != null ? Icons.attach_file : Icons.upload_file,
                  color: file != null ? theme.primaryColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file != null ? file.name : 'Choose file...',
                    style: TextStyle(
                      color: file != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: onRemove,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
