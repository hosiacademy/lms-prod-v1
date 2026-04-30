// lib/src/presentation/widgets/contact_otp_field.dart
//
// Inline OTP verification widget for enrollment form email fields.
// Sits directly below the field — no popup. Shows:
//   1. "Send verification code" button (enabled once field has content)
//   2. 6-digit OTP input + Verify button (after code is sent)
//   3. Green ✓ Verified badge (after successful verification)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

enum _OtpState { idle, sending, waiting, verifying, verified, error }

class ContactOtpField extends StatefulWidget {
  /// The controller whose text is the contact value (email).
  final TextEditingController contactController;

  /// 'email' — determines which icon/label to show.
  final String contactType;

  /// Called whenever the verified state changes. Parent uses this to
  /// enable/disable the form submit button.
  final ValueChanged<bool> onVerifiedChanged;

  const ContactOtpField({
    super.key,
    required this.contactController,
    this.contactType = 'email',
    required this.onVerifiedChanged,
  });

  @override
  State<ContactOtpField> createState() => _ContactOtpFieldState();
}

class _ContactOtpFieldState extends State<ContactOtpField> {
  final _otpController = TextEditingController();
  _OtpState _otpState = _OtpState.idle;
  String? _errorMsg;
  int _resendCooldown = 0;
  Timer? _timer;

  bool get _isVerified => _otpState == _OtpState.verified;

  String get _contact => widget.contactController.text.trim();

  bool get _hasContent {
    final text = widget.contactController.text.trim();
    // Basic email validation to enable button
    return text.isNotEmpty && text.contains('@') && text.contains('.');
  }

  @override
  void initState() {
    super.initState();
    widget.contactController.addListener(_onContactChanged);
  }

  @override
  void dispose() {
    widget.contactController.removeListener(_onContactChanged);
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onContactChanged() {
    // If the contact value changes after verification, reset.
    if (_isVerified) {
      setState(() {
        _otpState = _OtpState.idle;
        _otpController.clear();
        _errorMsg = null;
      });
      widget.onVerifiedChanged(false);
    } else {
      // Force rebuild to re-evaluate _hasContent and enable/disable buttons
      if (mounted) setState(() {});
    }
  }

  Future<void> _sendCode() async {
    if (!_hasContent) return;
    
    debugPrint('📧 OTP: Initiating code send to $_contact');
    
    setState(() {
      _otpState = _OtpState.sending;
      _errorMsg = null;
    });
    
    try {
      final response = await ApiClient.sendContactOTP(
        contact: _contact,
        contactType: 'email',
      );
      
      debugPrint('📧 OTP: Send response: $response');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your email.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      setState(() {
        _otpState = _OtpState.waiting;
        _resendCooldown = 120;
      });
      _startTimer();
    } catch (e) {
      debugPrint('❌ OTP: Send failed: $e');
      setState(() {
        _otpState = _OtpState.error;
        _errorMsg = _friendlyError(e.toString());
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMsg = 'Enter the full 6-digit code');
      return;
    }
    
    debugPrint('📧 OTP: Verifying code $code for $_contact');
    
    setState(() {
      _otpState = _OtpState.verifying;
      _errorMsg = null;
    });
    
    try {
      await ApiClient.verifyContactOTP(
        contact: _contact,
        contactType: 'email',
        otp: code,
      );
      
      debugPrint('✅ OTP: Verification successful');
      
      _timer?.cancel();
      setState(() => _otpState = _OtpState.verified);
      widget.onVerifiedChanged(true);
    } catch (e) {
      debugPrint('❌ OTP: Verification failed: $e');
      setState(() {
        _otpState = _OtpState.waiting;   // stay in waiting so user can re-enter
        _errorMsg = _friendlyError(e.toString());
      });
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() {
      _otpState = _OtpState.sending;
      _errorMsg = null;
      _otpController.clear();
    });
    try {
      await ApiClient.resendContactOTP(
        contact: _contact,
        contactType: 'email',
      );
      setState(() {
        _otpState = _OtpState.waiting;
        _resendCooldown = 120;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _otpState = _OtpState.waiting;
        _errorMsg = _friendlyError(e.toString());
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String _friendlyError(String raw) {
    if (raw.contains('OTP_EXPIRED') || raw.contains('expired')) return 'Code expired — request a new one';
    if (raw.contains('INVALID_OTP') || raw.contains('Invalid')) return 'Incorrect code, please try again';
    if (raw.contains('429') || raw.contains('wait')) return 'Please wait before requesting another code';
    return 'Something went wrong. Please try again.';
  }

  String _formatTimer() {
    final m = _resendCooldown ~/ 60;
    final s = _resendCooldown % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sw = MediaQuery.of(context).size.width;

    if (_otpState == _OtpState.verified) return _buildVerifiedBadge(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_otpState == _OtpState.idle || _otpState == _OtpState.error)
          _buildSendButton(colors, theme, sw),
        if (_otpState == _OtpState.waiting || _otpState == _OtpState.verifying)
          _buildOtpInput(colors),
        if (_otpState == _OtpState.sending)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
              const SizedBox(width: 12),
              Text('Sending verification code…', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600, fontSize: (sw * 0.035).clamp(11.0, 13.0))),
            ]),
          ),
        if (_errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, size: 16, color: colors.error),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMsg!, style: TextStyle(color: colors.error, fontSize: (sw * 0.035).clamp(11.0, 12.0), fontWeight: FontWeight.w500))),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildSendButton(ColorScheme colors, ThemeData theme, double sw) {
    final bool canSend = _hasContent;
    
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              if (_hasContent) {
                _sendCode();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address first.'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: Icon(Icons.mark_email_unread_outlined, size: (sw * 0.05).clamp(16.0, 20.0)),
            label: Text(
              'SEND VERIFICATION CODE',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5, fontSize: (sw * 0.035).clamp(11.0, 14.0)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (!canSend)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Enter a valid email address to enable verification',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOtpInput(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code sent to: ${widget.contactController.text.trim()}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.2), letterSpacing: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: colors.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          isDense: true,
                        ),
                        onChanged: (v) { if (v.length == 6) _verifyCode(); },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _otpState == _OtpState.verifying ? null : () => _verifyCode(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: _otpState == _OtpState.verifying
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('VERIFY', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 4),
              Text("Didn't receive the email? ", style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
              _resendCooldown > 0
                  ? Text('Resend in ${_formatTimer()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary))
                  : GestureDetector(
                      onTap: _resend,
                      child: Text('Resend Now', style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, color: AppTheme.successGreen, size: 20),
            SizedBox(width: 10),
            Text(
              'Email Verified Successfully',
              style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
