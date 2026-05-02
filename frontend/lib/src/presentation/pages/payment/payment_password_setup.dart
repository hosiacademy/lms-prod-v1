// lib/src/presentation/pages/payment/payment_password_setup.dart
// Shared password creation dialog â€” shown immediately after any payment is confirmed.

import 'package:flutter/material.dart';
import 'cash_payment_instructions_page.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/auth_service.dart';

/// Extract email from any payment metadata/payload map.
/// Checks both individual_details.email and corporate_details.contact_email.
String extractEmailFromPayload(Map<String, dynamic>? payload) {
  if (payload == null) return '';
  final individual = payload['individual_details'];
  if (individual is Map) {
    final e = individual['email']?.toString() ?? '';
    if (e.isNotEmpty) return e;
  }
  final corporate = payload['corporate_details'];
  if (corporate is Map) {
    final e = corporate['contact_email']?.toString() ?? '';
    if (e.isNotEmpty) return e;
  }
  // Flat email key fallback
  return payload['email']?.toString() ?? '';
}

/// Shows the "Create Your Password" dialog immediately after any payment is confirmed.
///
/// [reference]  â€” payment/provisional reference used to identify the user on backend.
/// [email]      â€” the email the user enrolled with; displayed as their login email.
/// [onDone]     â€” called after password is saved OR skipped (navigate away).
Future<void> showPasswordSetupDialog(
  BuildContext context, {
  required String reference,
  String email = '',
  VoidCallback? onDone,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PasswordSetupDialog(
      reference: reference,
      email: email,
      onDone: onDone ?? () => _navigateToDashboard(ctx),
    ),
  );
}

Future<void> _navigateToDashboard(BuildContext context) async {
  final role = await AuthService.getUserRole();
  if (!context.mounted) return;
  String path;
  switch (role) {
    case 'admin': path = '/welcome/admin'; break;
    case 'payment_admin': path = '/welcome/payment-admin'; break;
    case 'marketing_admin': path = '/welcome/marketing-admin'; break;
    case 'payment_sales_marketing_admin': path = '/welcome/payment-admin'; break;
    case 'hr_admin': path = '/welcome/hr-admin'; break;
    case 'executive_admin': path = '/welcome/executive-admin'; break;
    case 'instructor':
    case 'facilitator': path = '/welcome/instructor'; break;
    case 'learner':
    default: path = '/welcome/student'; break;
  }
  context.go(path);
}

class _PasswordSetupDialog extends StatefulWidget {
  final String reference;
  final String email;
  final VoidCallback onDone;

  const _PasswordSetupDialog({
    required this.reference,
    required this.email,
    required this.onDone,
  });

  @override
  State<_PasswordSetupDialog> createState() => _PasswordSetupDialogState();
}

class _PasswordSetupDialogState extends State<_PasswordSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  bool _hasAgreedToTerms = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_hasAgreedToTerms) {
      setState(() { _error = 'Please read and accept the Terms and Conditions to continue.'; });
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await ApiClient.post('/api/v1/auth/set-password/', data: {
        'new_password': _passwordController.text,
        'reference_code': widget.reference,
      });
      if (mounted) Navigator.pop(context);
      widget.onDone();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not save password. Please try again, or use "Forgot Password" on the login page.';
      });
    }
  }

  void _showTermsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome to Hosi Academy. By enrolling and setting up your account, you agree to the following terms:\n'),
              const Text('1. Code of Conduct', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Students are expected to maintain professionalism, respect peers and instructors, and adhere to the academic integrity guidelines.\n'),
              const Text('2. Payment and Refunds', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('All payments are subject to the academy\'s standard refund policy. Provisional enrollments via EFT must be settled within the designated timeframe to retain access.\n'),
              const Text('3. Intellectual Property', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('All course materials, lectures, and resources are the intellectual property of Hosi Academy and its partners. Unauthorized distribution is prohibited.\n'),
              const Text('4. Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Your personal data will be processed in accordance with our Privacy Policy to facilitate your learning experience and manage your enrollment.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _hasAgreedToTerms = true;
                _error = null;
              });
              Navigator.pop(ctx);
            },
            child: const Text('I Agree'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasEmail = widget.email.isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: colors.primary),
          const SizedBox(width: 8),
          const Text('Create Your Password'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your enrollment is confirmed! Set a password to access your student portal.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),

            // Email display â€” prominent, this is their login identity
            if (hasEmail) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your login email',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Use this email + password to sign in',
                      style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Minimum 8 characters';
                if (!v.contains(RegExp(r'[A-Z]'))) return 'Include at least one uppercase letter';
                if (!v.contains(RegExp(r'[0-9]'))) return 'Include at least one number';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmController,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _hasAgreedToTerms,
                    onChanged: (val) {
                      setState(() {
                        _hasAgreedToTerms = val ?? false;
                        if (_hasAgreedToTerms) _error = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showTermsModal(context),
                    child: Text.rich(
                      TextSpan(
                        text: 'I have read and agree to the ',
                        style: const TextStyle(fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _isLoading ? null : _save,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create Password & Continue'),
        ),
      ],
    );
  }
}
