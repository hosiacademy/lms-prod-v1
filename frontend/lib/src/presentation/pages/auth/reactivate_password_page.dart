// lib/src/presentation/pages/auth/reactivate_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

class ReactivatePasswordPage extends StatefulWidget {
  final String uid;
  final String token;

  const ReactivatePasswordPage({
    super.key,
    required this.uid,
    required this.token,
  });

  @override
  State<ReactivatePasswordPage> createState() => _ReactivatePasswordPageState();
}

class _ReactivatePasswordPageState extends State<ReactivatePasswordPage> {
  bool _isLoading = true;
  bool _success = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleReactivation();
  }

  Future<void> _handleReactivation() async {
    try {
      final success = await AuthService.reactivatePassword(widget.uid, widget.token);
      setState(() {
        _isLoading = false;
        _success = success;
        if (!success) {
          _errorMessage = 'The reactivation link is invalid or has expired.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _success = false;
        _errorMessage = 'An error occurred during reactivation: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/images/logo.png', height: 60)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(delay: 200.ms),
              const SizedBox(height: 48),

              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Verifying Security Token...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ] else if (_success) ...[
                const Icon(Icons.verified_user, color: Colors.green, size: 64)
                    .animate()
                    .scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                const Text(
                  'Password Login Reactivated!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your account security has been updated. You can now sign in using your email and password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go to Sign In'),
                ),
              ] else ...[
                const Icon(Icons.error_outline, color: Colors.red, size: 64)
                    .animate()
                    .shake(duration: 500.ms),
                const SizedBox(height: 24),
                const Text(
                  'Reactivation Failed',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'This link is no longer valid.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => context.go('/onboarding'),
                  child: const Text('Return to Home'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
