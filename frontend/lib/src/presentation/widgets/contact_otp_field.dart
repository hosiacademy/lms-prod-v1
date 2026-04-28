// lib/src/presentation/widgets/contact_otp_field.dart
//
// Inline OTP verification widget for enrollment form email / phone fields.
// Sits directly below the field — no popup.  Shows:
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
  /// The controller whose text is the contact value (email or phone).
  final TextEditingController contactController;

  /// 'email' or 'phone' — determines which icon/label to show and which
  /// backend endpoint is called.
  final String contactType;

  /// Called whenever the verified state changes.  Parent uses this to
  /// enable/disable the form submit button.
  final ValueChanged<bool> onVerifiedChanged;

  /// Optional prefix to prepend to phone number before sending (e.g. country
  /// code from the iso selector).  Pass null for email.
  /// Country code prefix e.g. '+27' to prepend to phone digits before sending.
  final String? phoneDialCode; // corresponds to PhoneValidationInfo.countryCode

  const ContactOtpField({
    super.key,
    required this.contactController,
    required this.contactType,
    required this.onVerifiedChanged,
    this.phoneDialCode,
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

  bool get _isEmail => widget.contactType == 'email';
  bool get _isVerified => _otpState == _OtpState.verified;

  /// The contact value to send to the backend.  For phone we prepend the dial code.
  String get _contact {
    final raw = widget.contactController.text.trim();
    if (!_isEmail && widget.phoneDialCode != null) {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      return '${widget.phoneDialCode}$digits';
    }
    return raw;
  }

  bool get _hasContent => widget.contactController.text.trim().isNotEmpty;

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
    } else if (_otpState != _OtpState.idle) {
      // Reset if user edits the field mid-flow
      setState(() {
        _otpState = _OtpState.idle;
        _otpController.clear();
        _errorMsg = null;
      });
    }
  }

  Future<void> _sendCode() async {
    if (!_hasContent) return;
    setState(() {
      _otpState = _OtpState.sending;
      _errorMsg = null;
    });
    try {
      await ApiClient.sendContactOTP(
        contact: _contact,
        contactType: widget.contactType,
      );
      setState(() {
        _otpState = _OtpState.waiting;
        _resendCooldown = 120;
      });
      _startTimer();
    } catch (e) {
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
    setState(() {
      _otpState = _OtpState.verifying;
      _errorMsg = null;
    });
    try {
      await ApiClient.verifyContactOTP(
        contact: _contact,
        contactType: widget.contactType,
        otp: code,
      );
      _timer?.cancel();
      setState(() => _otpState = _OtpState.verified);
      widget.onVerifiedChanged(true);
    } catch (e) {
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
        contactType: widget.contactType,
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
    final colors = Theme.of(context).colorScheme;

    if (_otpState == _OtpState.verified) return _buildVerifiedBadge(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_otpState == _OtpState.idle || _otpState == _OtpState.error)
          _buildSendButton(colors),
        if (_otpState == _OtpState.waiting || _otpState == _OtpState.verifying)
          _buildOtpInput(colors),
        if (_otpState == _OtpState.sending)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
              const SizedBox(width: 10),
              Text('Sending code…', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
            ]),
          ),
        if (_errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: colors.error),
              const SizedBox(width: 6),
              Expanded(child: Text(_errorMsg!, style: TextStyle(color: colors.error, fontSize: 12))),
            ]),
          ),
      ],
    );
  }

  Widget _buildSendButton(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton.icon(
        onPressed: _hasContent ? _sendCode : null,
        icon: Icon(_isEmail ? Icons.mark_email_unread_outlined : Icons.sms_outlined, size: 16),
        label: Text(
          _isEmail ? 'Send email verification code' : 'Send SMS verification code',
          style: const TextStyle(fontSize: 13),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          foregroundColor: colors.primary,
        ),
      ),
    );
  }

  Widget _buildOtpInput(ColorScheme colors) {
    final label = _isEmail
        ? 'Enter code sent to ${widget.contactController.text.trim()}'
        : 'Enter code sent to $_contact';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 300;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isNarrow ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: isNarrow ? 4 : 6,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        hintText: '------',
                        hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.4), letterSpacing: isNarrow ? 4 : 6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(vertical: isNarrow ? 10 : 12, horizontal: 8),
                        isDense: true,
                      ),
                      onChanged: (v) { if (v.length == 6) _verifyCode(); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: isNarrow ? 40 : 44,
                    child: ElevatedButton(
                      onPressed: _otpState == _OtpState.verifying ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 16),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _otpState == _OtpState.verifying
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isNarrow ? 12 : 14)),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text("Didn't get it? ", style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
              _resendCooldown > 0
                  ? Text('Resend in ${_formatTimer()}', style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant.withValues(alpha: 0.5)))
                  : GestureDetector(
                      onTap: _resend,
                      child: Text('Resend', style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w600)),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18),
        const SizedBox(width: 6),
        Text(
          _isEmail ? 'Email verified' : 'Phone number verified',
          style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ]),
    );
  }
}
