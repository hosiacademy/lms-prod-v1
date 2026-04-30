// lib/src/presentation/widgets/payment/payment_otp_verification.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class PaymentOTPVerification extends StatefulWidget {
  final String email;
  final double amount;
  final String currency;
  final String country;
  final Function(String paymentToken) onVerified;
  final Function(String error) onError;

  const PaymentOTPVerification({
    super.key,
    required this.email,
    required this.amount,
    required this.currency,
    required this.country,
    required this.onVerified,
    required this.onError,
  });

  @override
  State<PaymentOTPVerification> createState() => _PaymentOTPVerificationState();
}

class _PaymentOTPVerificationState extends State<PaymentOTPVerification> {
  final _otpController = TextEditingController(text: '');
  bool _isLoading = false;
  bool _otpSent = false;
  int _resendCooldown = 0;
  String? _errorMessage;
  String? _debugOtp; // Only populated in dev when backend returns debug_otp
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await ApiClient.sendPaymentOTP(
        email: widget.email,
        amount: widget.amount,
        currency: widget.currency,
        country: widget.country,
      );
      setState(() { _otpSent = true; _isLoading = false; _resendCooldown = 120; });
      
      // Dev convenience: auto-fill OTP if server returns it (DEBUG mode only)
      final devOtp = result['debug_otp'] as String?;
      if (devOtp != null && devOtp.isNotEmpty) {
        setState(() => _debugOtp = devOtp);
        _otpController.text = devOtp;
      }
      
      _startCooldownTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('OTP sent to ${widget.email}'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = e.toString(); });
      widget.onError(e.toString());
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await ApiClient.verifyPaymentOTP(
        email: widget.email,
        otp: _otpController.text.trim(),
      );
      widget.onVerified(result['payment_token'] as String);
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = e.toString(); });
      widget.onError(e.toString());
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCooldown > 0) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiClient.resendPaymentOTP(email: widget.email);
      setState(() { _isLoading = false; _resendCooldown = 120; });
      _startCooldownTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('OTP resent to ${widget.email}'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatCooldown() {
    final m = _resendCooldown ~/ 60;
    final s = _resendCooldown % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final w = MediaQuery.of(context).size.width;
    final pad = w < 400 ? 16.0 : 24.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.security, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verify Your Email',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: (w * 0.045).clamp(14.0, 20.0),
                        )),
                    Text('Enter the 6-digit code sent to your email',
                        style: TextStyle(
                          fontSize: (w * 0.03).clamp(10.0, 13.0),
                          color: colors.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ]),
            SizedBox(height: pad * 0.8),

            // Email display
            Container(
              padding: EdgeInsets.all(w < 400 ? 12 : 16),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.email_outlined, color: colors.onSurfaceVariant, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verification code sent to',
                          style: TextStyle(
                            fontSize: (w * 0.028).clamp(10.0, 12.0),
                            color: colors.onSurfaceVariant,
                          )),
                      Text(widget.email,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: (w * 0.038).clamp(12.0, 16.0),
                          ),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            ),
            SizedBox(height: pad * 0.8),

            // OTP Input
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (w * 0.06).clamp(18.0, 28.0),
                fontWeight: FontWeight.bold,
                letterSpacing: (w * 0.02).clamp(4.0, 10.0),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: 'Enter 6-digit OTP',
                hintText: '□□□□□□',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                contentPadding: EdgeInsets.symmetric(vertical: w < 400 ? 14 : 20),
              ),
              onChanged: (v) { if (v.length == 6) _verifyOTP(); },
            ),
            const SizedBox(height: 14),

            // Dev-only OTP banner
            if (_debugOtp != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  border: Border.all(color: Colors.amber.shade700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.developer_mode, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text('[DEV] OTP auto-filled: $_debugOtp',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 10),
            ],

            // Error
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline, color: colors.onErrorContainer, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: TextStyle(
                          color: colors.onErrorContainer,
                          fontSize: (w * 0.032).clamp(11.0, 13.0),
                        )),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
            ],

            // Verify button
            SizedBox(
              width: double.infinity,
              height: (w * 0.14).clamp(48.0, 58.0),
              child: ElevatedButton(
                onPressed: (_isLoading || !_otpSent) ? null : () => _verifyOTP(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text('Verify & Continue to Payment',
                        style: TextStyle(
                          fontSize: (w * 0.038).clamp(13.0, 16.0),
                          fontWeight: FontWeight.bold,
                        )),
              ),
            ),
            const SizedBox(height: 14),

            // Resend row — wraps on narrow screens
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text("Didn't receive the code?",
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: (w * 0.032).clamp(11.0, 14.0),
                    )),
                _resendCooldown > 0
                    ? Text('Resend in ${_formatCooldown()}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: (w * 0.032).clamp(11.0, 14.0),
                        ))
                    : TextButton(
                        onPressed: _isLoading ? null : () => _resendOTP(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Resend',
                            style: TextStyle(
                              fontSize: (w * 0.032).clamp(11.0, 14.0),
                            ))),
              ],
            ),
            const SizedBox(height: 12),

            // Security notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, size: 15, color: colors.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This OTP will expire in 10 minutes. Do not share it with anyone.',
                    style: TextStyle(
                      fontSize: (w * 0.028).clamp(10.0, 12.0),
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
