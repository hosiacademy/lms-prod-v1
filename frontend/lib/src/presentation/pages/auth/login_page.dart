// lib/src/presentation/pages/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth_service.dart';
import '../onboarding/widgets/forgot_password_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPassword = false;
  bool _isOtpMode = false;
  bool _otpSent = false;
  int _resendCooldown = 0;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      bool success = false;

      if (_isOtpMode) {
        final otp = _otpController.text.trim();
        success = await AuthService.loginWithOTP(
          email: email,
          otp: otp,
        );
      } else {
        final password = _passwordController.text.trim();
        success = await AuthService.login(
          email: email,
          password: password,
        );
      }

      if (!success) {
        setState(() {
          _isLoading = false;
          _errorMessage = _isOtpMode 
              ? 'Invalid or expired OTP. Please try again.' 
              : 'Invalid email or password. Please try again.';
        });
        return;
      }

      final savedRole = await AuthService.getUserRole();
      final userName = await AuthService.getUserName();
      final firstName = userName?.split(' ').first ?? 'User';
      
      setState(() => _isLoading = false);

      if (context.mounted) {
        final prefs = await SharedPreferences.getInstance();
        final isSuperuser = prefs.getBool('is_superuser') ?? false;
        
        String welcomePath;
        switch (savedRole) {
          case 'admin': 
            welcomePath = isSuperuser ? '/welcome/universal' : '/welcome/admin'; 
            break;
          case 'payment_admin': welcomePath = '/welcome/payment-admin'; break;
          case 'hr_admin': welcomePath = '/welcome/hr-admin'; break;
          case 'executive_admin': welcomePath = '/welcome/executive-admin'; break;
          case 'instructor':
          case 'facilitator': welcomePath = '/welcome/instructor'; break;
          case 'marketing_admin': welcomePath = '/welcome/marketing-admin'; break;
          case 'payment_sales_marketing_admin': welcomePath = '/welcome/payment-admin'; break;
          case 'learner':
          default: welcomePath = '/welcome/student'; break;
        }
        context.go(welcomePath, extra: firstName);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  Future<void> _handleSendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService.sendLoginOTP(email);

    setState(() {
      _isLoading = false;
      if (success) {
        _otpSent = true;
        _successMessage = 'Verification code sent to $email';
        _startResendTimer();
      } else {
        _errorMessage = 'Failed to send OTP. Please ensure the email is correct or use your password.';
      }
    });
  }

  void _startResendTimer() {
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: Row(
        children: [
          // Left Side: Branding (Desktop)
          if (MediaQuery.of(context).size.width > 900)
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    opacity: 0.05,
                    scale: 0.5,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(64.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hosi Academy Family',
                          style: TextStyle( 
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome back to your specialized learning environment. Sign in to access your customized dashboard and resume your journey.',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Right Side: Login Form
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 480 ? 20 : 48,
                  vertical: 24,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.go('/onboarding'),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back to Home'),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        if (MediaQuery.of(context).size.width <= 900) ...[
                          Center(
                            child: Image.asset('assets/images/logo.png', height: 80),
                          ),
                          const SizedBox(height: 32),
                        ],

                        Text(
                          'Sign In',
                          style: TextStyle( 
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isOtpMode 
                            ? 'Enter your email to receive a secure login code.'
                            : 'Enter your credentials to access the family portal.',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 32),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        
                        // Success Message
                        if (_successMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'your@email.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Password or OTP Field
                        if (!_isOtpMode) ...[
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '6-Digit Login Code',
                              hintText: '123456',
                              prefixIcon: const Icon(Icons.pin_outlined),
                              suffixIcon: TextButton(
                                onPressed: (_resendCooldown > 0 || _isLoading) ? null : _handleSendOTP,
                                child: Text(_resendCooldown > 0 ? '${_resendCooldown}s' : (_otpSent ? 'Resend' : 'Send')),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : (v!.length != 6 ? 'Must be 6 digits' : null),
                          ),
                        ],
                        
                        const SizedBox(height: 12),

                        // Forgot Password / Toggle Mode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpMode = !_isOtpMode;
                                  _errorMessage = null;
                                  _successMessage = null;
                                });
                              },
                              child: Text(_isOtpMode ? 'Use Password instead' : 'Login with OTP code'),
                            ),
                            if (!_isOtpMode)
                              TextButton(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (c) => ForgotPasswordDialog(onClose: () => Navigator.pop(c)),
                                ),
                                child: const Text('Forgot Password?'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_isOtpMode ? 'Verify and Sign In' : 'Sign In to Family Portal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        
                        const SizedBox(height: 48),
                        _buildBlockchainBadge(colorScheme),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Blockchain Secured', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Credentials verified on-chain', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
