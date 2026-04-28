import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificateVerificationModal extends StatefulWidget {
  const CertificateVerificationModal({super.key});

  @override
  State<CertificateVerificationModal> createState() =>
      _CertificateVerificationModalState();
}

class _CertificateVerificationModalState
    extends State<CertificateVerificationModal> {
  final _formKey = GlobalKey<FormState>();
  final _certificateIdController = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _certificateIdController.dispose();
    super.dispose();
  }

  Future<void> _verifyOnline() async {
    final url = 'https://verify.hosi.academy';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _verifyCertificate() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isVerifying = true);

      // Simulate verification (in production, this would call an API)
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isVerifying = false);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Verification Result'),
              content: const Text(
                'Please visit verify.hosi.academy with your certificate ID for full blockchain verification.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _verifyOnline();
                  },
                  child: const Text('Verify Online'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Certificate Verification',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blockchain Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary.withValues(alpha: 0.1),
                              colors.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 64,
                              color: colors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Blockchain-Verified Certificates',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tamper-proof • Instantly verifiable • Globally recognized',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verification Form
                    Text(
                      'Verify a Certificate',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _certificateIdController,
                            decoration: InputDecoration(
                              labelText: 'Certificate ID',
                              hintText: 'e.g., HA-2026-AI-12345',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.badge),
                              helperText: 'Find this on your certificate',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter certificate ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isVerifying ? null : _verifyCertificate,
                              icon: _isVerifying
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.search),
                              label: Text(_isVerifying ? 'Verifying...' : 'Verify Certificate'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _verifyOnline,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Verify on verify.hosi.academy'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // How It Works
                    Text(
                      'How Blockchain Verification Works',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Complete your course and pass assessments'),
                    _buildStep('2', 'Certificate issued and recorded on blockchain'),
                    _buildStep('3', 'Unique ID generated for your certificate'),
                    _buildStep('4', 'Anyone can verify authenticity using the ID'),
                    const SizedBox(height: 24),

                    // What Can Be Verified
                    Text(
                      'What Employers Can Verify',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildVerificationPoint(colors, 'Student name and credentials'),
                    _buildVerificationPoint(colors, 'Course title and completion date'),
                    _buildVerificationPoint(colors, 'Skills and competencies achieved'),
                    _buildVerificationPoint(colors, 'Issuing institution details'),
                    _buildVerificationPoint(colors, 'Certificate authenticity status'),
                    const SizedBox(height: 24),

                    // Benefits
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, color: colors.primary, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Why Blockchain?',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildBenefit('Cannot be forged or altered'),
                          _buildBenefit('Instant verification in seconds'),
                          _buildBenefit('No need to contact institution'),
                          _buildBenefit('Permanent record that never expires'),
                          _buildBenefit('Globally accessible 24/7'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sample Certificate Preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sample Certificate ID Format',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'HA-2026-AI-12345\nHA-2026-BC-67890\nHA-2026-CS-54321',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationPoint(ColorScheme colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
