// lib/src/presentation/pages/onboarding/widgets/login_side_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import 'forgot_password_dialog.dart';

class LoginSideSheet extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onLoginSuccess;

  const LoginSideSheet({
    super.key,
    required this.onClose,
    required this.onLoginSuccess,
  });

  @override
  State<LoginSideSheet> createState() => _LoginSideSheetState();
}

class _LoginSideSheetState extends State<LoginSideSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _usePassword = false; // Toggle between OTP and Password login
  bool _isPasswordVisible = false;
  String? _errorMessage;

  Future<void> _handleInitialSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_usePassword) {
      // Password Login Flow
      try {
        final success = await AuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (success) {
          _onLoginSuccess();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Invalid email or password. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Login failed. Please try again later.';
        });
      }
    } else {
      // OTP Login Flow
      try {
        final success =
            await AuthService.sendLoginOTP(_emailController.text.trim());

        if (success) {
          setState(() {
            _isOtpSent = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'No account found with this email. Please check your spelling or enrol now.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to send verification code. Please try again.';
        });
      }
    }
  }

  void _onLoginSuccess() async {
    final savedRole = await AuthService.getUserRole();
    final userName = await AuthService.getUserName();
    final firstName = userName?.split(' ').first ?? 'User';

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onClose();
      widget.onLoginSuccess();
      AuthService.fetchPostLoginData();

      String normalizedRole = savedRole?.toLowerCase().replaceAll(' ', '_').replaceAll(',', '').replaceAll('&', 'and') ?? '';
      
      String welcomePath;
      if (normalizedRole.contains('system_admin') || normalizedRole == 'admin') {
        welcomePath = '/welcome/admin'; // Fallback for side sheet without superuser context
      } else if (normalizedRole.contains('executive')) {
        welcomePath = '/welcome/executive-admin';
      } else if (normalizedRole.contains('hr_admin') || normalizedRole == 'hr_admin') {
        welcomePath = '/welcome/hr-admin';
      } else if (normalizedRole.contains('sales_and_marketing') || normalizedRole.contains('payment_sales')) {
        welcomePath = '/welcome/payment-admin';
      } else if (normalizedRole.contains('marketing')) {
        welcomePath = '/welcome/marketing-admin';
      } else if (normalizedRole.contains('payment')) {
        welcomePath = '/welcome/payment-admin';
      } else if (normalizedRole.contains('instructor') || normalizedRole.contains('facilitator')) {
        welcomePath = '/welcome/instructor';
      } else {
        welcomePath = '/welcome/student';
      }
      context.go(welcomePath, extra: firstName);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() =>
          _errorMessage = 'Please enter the 6-digit code sent to your email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService.loginWithOTP(
        email: _emailController.text.trim(),
        otp: otp,
      );

      if (!success) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid or expired code. Please try again.';
        });
        return;
      }

      _onLoginSuccess();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed: $e';
      });
    }
  }

  void _handleLogin() {
    if (_isOtpSent) {
      _handleVerifyOtp();
    } else {
      _handleInitialSubmit();
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => ForgotPasswordDialog(
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final sheetWidth = screenWidth > 500 ? 400.0 : screenWidth * 0.85;

    return Container(
      width: sheetWidth,
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with logo & close button
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? colorScheme.outline.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 36,
                    width: 116,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isOtpSent ? 'Verify Your Email' : 'Welcome Back!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOtpSent 
                          ? 'We\'ve sent a 6-digit code to ${_emailController.text}'
                          : 'Sign in to continue your learning journey',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Blockchain Security Badge
                      _buildBlockchainBadge(),
                      const SizedBox(height: 24),

                      // Error message display
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.red.shade900.withValues(alpha: 0.2)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.red.shade300
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: isDark
                                    ? Colors.red.shade300
                                    : Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.red.shade200
                                        : Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (!_isOtpSent) ...[
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        if (_usePassword) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(() =>
                                    _isPasswordVisible = !_isPasswordVisible),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Login Method Toggle
                        Row(
                          children: [
                            Text(
                              _usePassword
                                  ? 'Login with code instead'
                                  : 'Login with password instead',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _usePassword,
                              onChanged: (val) =>
                                  setState(() => _usePassword = val),
                              activeColor: colorScheme.primary,
                            ),
                          ],
                        ),
                      ] else ...[
                        // OTP field
                        TextFormField(
                          controller: _otpController,
                          decoration: InputDecoration(
                            labelText: '6-Digit Code',
                            prefixIcon: const Icon(Icons.lock_person_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            counterText: '',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),

                      // Submit/Login button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isOtpSent 
                                  ? 'Verify & Sign In' 
                                  : (_usePassword ? 'Sign In' : 'Send Verification Code'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                      ),

                      if (_isOtpSent) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() => _isOtpSent = false),
                          child: const Text('Change Email'),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Social Media Section (Silent/Transparent as requested)
                      Opacity(
                        opacity: 0.0,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: colorScheme.outline
                                            .withValues(alpha: 0.5))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'Follow Hosi Academy',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: colorScheme.outline
                                            .withValues(alpha: 0.5))),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSocialButton(
                                  label: 'X',
                                  icon: Icons.tag,
                                  color: Colors.black,
                                  url: 'https://x.com/hosiacademy',
                                ),
                                _buildSocialButton(
                                  label: 'Instagram',
                                  icon: Icons.camera_alt,
                                  color: const Color(0xFFE4405F),
                                  url: 'https://instagram.com/hosiacademy',
                                ),
                                _buildSocialButton(
                                  label: 'Facebook',
                                  icon: Icons.facebook,
                                  color: const Color(0xFF1877F2),
                                  url: 'https://facebook.com/hosiacademy',
                                ),
                                _buildSocialButton(
                                  label: 'LinkedIn',
                                  icon: Icons.business,
                                  color: const Color(0xFF0A66C2),
                                  url:
                                      'https://linkedin.com/company/hosiacademy',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Enrol now link (optional redirect to register)
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                            GestureDetector(
                              onTap: () {
                                widget.onClose();
                                context.go('/register');
                              },
                              child: Text(
                                'Enrol now',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                        .animate(interval: 50.ms)
                        .slideX(begin: 0.2, duration: 300.ms)
                        .fadeIn(duration: 300.ms),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSocialUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildBlockchainBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // THEME FIX: Use theme primary color instead of hardcoded purple
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // THEME FIX: Use theme primary color
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.security,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Blockchain Secured',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        // THEME FIX: Use theme primary color
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        // THEME FIX: Use theme tertiary or success color (green indicator)
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your credentials are encrypted & verified on-chain',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        // THEME FIX: Use theme primary color for shimmer effect
        .shimmer(
            duration: 2000.ms,
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2));
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () => _launchSocialUrl(url),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
