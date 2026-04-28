// lib/src/presentation/pages/payment/eft_payment_result_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/api/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/currency_service.dart';

/// EFT Payment Result Page - Shows pending payment status for EFT/Bank Transfer
/// Displays bank details and monitors payment verification (24-72 hours)
class EftPaymentResultPage extends StatefulWidget {
  final String reference;
  final String programId;
  final String programType;
  final double amount;
  final String currency;
  final String programTitle;

  const EftPaymentResultPage({
    super.key,
    required this.reference,
    required this.programId,
    required this.programType,
    required this.amount,
    required this.currency,
    required this.programTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String reference,
    required String programId,
    required String programType,
    required double amount,
    required String currency,
    required String programTitle,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EftPaymentResultPage(
          reference: reference,
          programId: programId,
          programType: programType,
          amount: amount,
          currency: currency,
          programTitle: programTitle,
        ),
      ),
    );
  }

  @override
  State<EftPaymentResultPage> createState() => _EftPaymentResultPageState();
}

class _EftPaymentResultPageState extends State<EftPaymentResultPage> {
  bool _isLoading = true;
  bool _paymentVerified = false;
  String _statusMessage = 'Waiting for payment...';
  Map<String, dynamic>? _paymentData;
  
  Timer? _verificationTimer;
  int _verificationAttempts = 0;
  static const int _maxAttempts = 288; // 24 hours at 5-minute intervals
  static const Duration _verificationInterval = Duration(minutes: 5);

  // Bank details: use API response when available, fallback to ZA defaults
  Map<String, String> get _companyBankDetails {
    final apiBank = _paymentData?['bank_details'] as Map<String, dynamic>?;
    if (apiBank != null) {
      return {
        'bank_name': apiBank['bank_name']?.toString() ?? 'FNB Business',
        'account_number': apiBank['account_number']?.toString() ?? '',
        'account_name': apiBank['account_name']?.toString() ?? '',
        'branch_code': apiBank['branch_code']?.toString() ?? '',
        'account_type': apiBank['account_type']?.toString() ?? 'Current Account',
        'swift_code': apiBank['swift_code']?.toString() ?? '',
        'currency': apiBank['currency']?.toString() ?? widget.currency,
        'reference': apiBank['reference']?.toString() ?? widget.reference,
      };
    }
    return {
      'bank_name': 'FNB Business',
      'account_number': '123456789',
      'account_name': 'HosiTech LMS (Pty) Ltd',
      'branch_code': '250655',
      'account_type': 'Current Account',
      'reference': widget.reference,
    };
  }

  @override
  void initState() {
    super.initState();
    _verifyPaymentStatus();
    _startPeriodicVerification();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyPaymentStatus() async {
    setState(() => _isLoading = true);

    try {
      final verification = await ApiClient.verifyPaymentStatus(widget.reference);
      final status = verification['status']?.toString().toLowerCase();

      setState(() {
        _paymentData = verification;
        _isLoading = false;

        if (status == 'completed' || status == 'successful') {
          _paymentVerified = true;
          _statusMessage = 'Payment Verified!';
          _verificationTimer?.cancel();
        } else if (status == 'failed' || status == 'cancelled') {
          _statusMessage = 'Payment ${status ?? 'Failed'}';
          _verificationTimer?.cancel();
        } else if (status == 'pending') {
          _statusMessage = 'Payment Pending Verification';
        } else {
          _statusMessage = 'Waiting for payment...';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Unable to verify payment status';
      });
    }
  }

  void _startPeriodicVerification() {
    _verificationTimer = Timer.periodic(_verificationInterval, (timer) async {
      if (_verificationAttempts >= _maxAttempts) {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment verification timeout. Please contact support.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      await _verifyPaymentStatus();
      _verificationAttempts++;
    });
  }

  Future<void> _copyBankDetails() async {
    final details = _companyBankDetails;
    final bankDetailsText = '''
Bank Transfer Details
=====================
Bank: ${details['bank_name']}
Account Number: ${details['account_number']}
Account Name: ${details['account_name']}
Branch Code: ${details['branch_code']}
Account Type: ${details['account_type']}
Reference: ${details['reference']}
=====================
Amount: ${CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency)}
Program: ${widget.programTitle}
''';

    await Clipboard.setData(ClipboardData(text: bankDetailsText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Bank details copied! Complete your transfer now.'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyReference() async {
    await Clipboard.setData(ClipboardData(text: widget.reference));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reference number copied!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showManualVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text('Submit Proof of Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have you already made the payment? Upload your proof of payment (POP) to expedite verification.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Upload POP here',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'PDF, JPG, or PNG (Max 5MB)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement file picker and upload
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upload feature coming soon')),
              );
              Navigator.pop(context);
            },
            icon: Icon(Icons.upload),
            label: Text('Upload POP'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.support_agent, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help with your payment?'),
            SizedBox(height: 16),
            _buildContactItem(
              Icons.email,
              'Email',
              'support@hosiacademy.africa',
            ),
            _buildContactItem(
              Icons.phone,
              'Phone',
              '+27 12 345 6789',
            ),
            _buildContactItem(
              Icons.access_time,
              'Support Hours',
              'Mon-Fri: 8:00 AM - 5:00 PM SAST',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final details = _companyBankDetails;

    return Scaffold(
      appBar: AppBar(
        title: Text('EFT Payment Status'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _verifyPaymentStatus,
            tooltip: 'Refresh Status',
          ),
          IconButton(
            icon: Icon(Icons.support),
            onPressed: _contactSupport,
            tooltip: 'Contact Support',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colors.primary),
                  SizedBox(height: 24),
                  Text(
                    'Checking payment status...',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _verifyPaymentStatus,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      
                      // Status Card
                      _buildStatusCard(theme, colors),
                      SizedBox(height: 24),

                      // Program Details
                      _buildProgramCard(theme, colors),
                      SizedBox(height: 24),

                      // Bank Details Card
                      _buildBankDetailsCard(theme, colors, details),
                      SizedBox(height: 24),

                      // Payment Timeline
                      _buildTimelineCard(theme, colors),
                      SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(theme, colors),
                      SizedBox(height: 24),

                      // Important Notice
                      _buildImportantNoticeCard(theme, colors),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _paymentVerified
              ? [Colors.green.shade400, Colors.green.shade600]
              : [colors.primary.withOpacity(0.7), colors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _paymentVerified ? Colors.green.withOpacity(0.3) : colors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _paymentVerified ? Icons.check_circle : Icons.access_time,
            size: 64,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            _statusMessage,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _paymentVerified
                ? 'Your enrollment has been confirmed!'
                : 'Verification typically takes 24-72 hours',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.school, color: colors.primary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Program Details',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        widget.programTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow('Reference', widget.reference, Icons.tag, onCopy: _copyReference),
            Divider(),
            _buildInfoRow(
              'Amount',
              CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency),
              Icons.attach_money,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailsCard(ThemeData theme, ColorScheme colors, Map<String, String> details) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance, color: colors.primary),
                SizedBox(width: 12),
                Text(
                  'Bank Transfer Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                FilledButton.icon(
                  onPressed: _copyBankDetails,
                  icon: Icon(Icons.copy, size: 18),
                  label: Text('Copy All'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBankDetailRow('Bank Name', details['bank_name']!, Icons.account_balance),
                Divider(),
                _buildBankDetailRow('Account Number', details['account_number']!, Icons.numbers, onCopy: () {
                  Clipboard.setData(ClipboardData(text: details['account_number']!));
                  _showCopyFeedback('Account number copied!');
                }),
                Divider(),
                _buildBankDetailRow('Account Name', details['account_name']!, Icons.person, onCopy: () {
                  Clipboard.setData(ClipboardData(text: details['account_name']!));
                  _showCopyFeedback('Account name copied!');
                }),
                Divider(),
                _buildBankDetailRow('Branch Code', details['branch_code']!, Icons.business, onCopy: () {
                  Clipboard.setData(ClipboardData(text: details['branch_code']!));
                  _showCopyFeedback('Branch code copied!');
                }),
                Divider(),
                _buildBankDetailRow('Account Type', details['account_type']!, Icons.work),
                if ((details['swift_code'] ?? '').isNotEmpty) ...[
                  Divider(),
                  _buildBankDetailRow('SWIFT Code', details['swift_code']!, Icons.language),
                ],
                Divider(),
                // Reference - Highlighted
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REFERENCE (MUST INCLUDE)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              details['reference']!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: colors.primary),
                        onPressed: _copyReference,
                        tooltip: 'Copy reference',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value, IconData icon, {VoidCallback? onCopy}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey.shade700),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: Icon(Icons.copy, size: 18),
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {VoidCallback? onCopy}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: Icon(Icons.copy, size: 18),
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildTimelineCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: colors.primary),
                SizedBox(width: 12),
                Text(
                  'Payment Verification Timeline',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildTimelineItem(
              'Payment Initiated',
              'Reference number generated',
              true,
              colors,
            ),
            _buildTimelineItem(
              'Bank Transfer',
              'Complete transfer within 24 hours',
              !_paymentVerified,
              colors,
            ),
            _buildTimelineItem(
              'Verification',
              '24-72 hours for confirmation',
              !_paymentVerified,
              colors,
            ),
            _buildTimelineItem(
              'Enrollment Confirmed',
              'Access granted to course',
              !_paymentVerified,
              colors,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, bool isActive, ColorScheme colors, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? colors.primary : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isActive ? colors.primary.withOpacity(0.3) : Colors.grey.shade300,
              ),
          ],
        ),
        SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? colors.onSurface : Colors.grey,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _verifyPaymentStatus,
            icon: Icon(Icons.refresh),
            label: Text('Check Payment Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showManualVerificationDialog,
                icon: Icon(Icons.upload_file),
                label: Text('Upload POP'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _contactSupport,
                icon: Icon(Icons.support),
                label: Text('Support'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        if (_paymentVerified) ...[
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToDashboard(),
              icon: Icon(Icons.dashboard),
              label: Text('Go to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _navigateToDashboard() async {
    final role = await AuthService.getUserRole();
    if (!mounted) return;
    String path;
    switch (role) {
      case 'admin': path = '/welcome/admin'; break;
      case 'payment_admin': path = '/welcome/payment-admin'; break;
      case 'hr_admin': path = '/welcome/hr-admin'; break;
      case 'executive_admin': path = '/welcome/executive-admin'; break;
      case 'instructor':
      case 'facilitator': path = '/welcome/instructor'; break;
      default: path = '/welcome/student'; break;
    }
    context.go(path);
  }


  Widget _buildImportantNoticeCard(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Always include the reference number when making payment\n'
                  '• Payment must be made within 72 hours\n'
                  '• Seats are allocated only after payment confirmation\n'
                  '• Keep your proof of payment for verification',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCopyFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
