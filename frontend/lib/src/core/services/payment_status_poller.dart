// lib/src/core/services/payment_status_poller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import './currency_service.dart';

/// Payment Status Poller Service
/// 
/// Polls payment status for providers that don't use redirect flows:
/// - Mobile Money (M-Pesa STK Push, MTN MoMo, Airtel Money, Orange Money)
/// - EFT / Bank Transfer
/// - QR Code Payments
/// - Cash/In-Person Payment reservations
/// 
/// Usage:
/// ```dart
/// final poller = PaymentStatusPoller(
///   reference: 'ENR-ABC123',
///   onStatusChange: (status) {
///     if (status == 'successful') {
///       // Handle successful payment
///     }
///   },
///   onError: (error) {
///     // Handle polling error
///   },
/// );
/// 
/// await poller.start();
/// 
/// // Later, stop polling
/// poller.stop();
/// ```
class PaymentStatusPoller {
  final String reference;
  final Function(String status, Map<String, dynamic>? data) onStatusChange;
  final Function(String error)? onError;
  final Function()? onComplete;
  final Duration pollingInterval;
  final Duration timeout;
  final Set<String> _terminalStatuses;

  Timer? _pollingTimer;
  bool _isPolling = false;
  String _lastKnownStatus = 'pending';
  int _pollCount = 0;
  final int _maxPollCount;

  // Terminal statuses that should stop polling
  static const Set<String> defaultTerminalStatuses = {
    'successful',
    'completed',
    'confirmed',
    'failed',
    'cancelled',
    'rejected',
    'refunded',
    'expired',
  };

  PaymentStatusPoller({
    required this.reference,
    required this.onStatusChange,
    this.onError,
    this.onComplete,
    this.pollingInterval = const Duration(seconds: 5),
    this.timeout = const Duration(minutes: 10),
    Set<String>? terminalStatuses,
  })  : _terminalStatuses = terminalStatuses ?? defaultTerminalStatuses,
        _maxPollCount = (timeout.inMilliseconds / pollingInterval.inMilliseconds).ceil();

  /// Start polling payment status
  Future<void> start() async {
    if (_isPolling) {
      debugPrint('⚠️ PaymentStatusPoller: Already polling for $reference');
      return;
    }

    debugPrint('🔄 PaymentStatusPoller: Starting polling for $reference');
    _isPolling = true;
    _pollCount = 0;

    // First poll immediately
    await _pollStatus();

    // Then poll at intervals
    _pollingTimer = Timer.periodic(pollingInterval, (timer) async {
      _pollCount++;

      // Check if we've exceeded max polls
      if (_pollCount >= _maxPollCount) {
        debugPrint('⏰ PaymentStatusPoller: Timeout reached for $reference');
        stop();
        onError?.call('Payment verification timeout. Please check your payment status.');
        return;
      }

      await _pollStatus();
    });
  }

  /// Poll payment status from backend
  Future<void> _pollStatus() async {
    try {
      final response = await ApiClient.verifyPaymentStatus(reference);
      
      final status = response['status'] as String? ?? 'pending';
      final data = response['transaction'] as Map<String, dynamic>?;
      
      debugPrint('📊 PaymentStatusPoller: $reference - Status: $status (Poll #$_pollCount)');

      // Check if status changed
      if (status != _lastKnownStatus) {
        debugPrint('✅ PaymentStatusPoller: Status changed from $_lastKnownStatus → $status');
        _lastKnownStatus = status;
        
        // Notify status change
        onStatusChange(status, data);

        // Check if terminal status
        if (_terminalStatuses.contains(status.toLowerCase())) {
          debugPrint('🛑 PaymentStatusPoller: Terminal status reached: $status');
          stop();
          onComplete?.call();
        }
      }
    } catch (e) {
      debugPrint('❌ PaymentStatusPoller: Error polling status: $e');
      // Don't stop polling on network errors, but notify
      onError?.call('Failed to check payment status: $e');
    }
  }

  /// Stop polling
  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ PaymentStatusPoller: Stopped polling for $reference');
  }

  /// Check if currently polling
  bool get isPolling => _isPolling;

  /// Get last known status
  String get lastKnownStatus => _lastKnownStatus;

  /// Get poll count
  int get pollCount => _pollCount;
}


/// Payment Status Tracker Widget
/// 
/// A widget that displays payment status and polls for updates
/// 
/// Usage:
/// ```dart
/// PaymentStatusTracker(
///   reference: 'ENR-ABC123',
///   amount: 299.00,
///   currency: 'USD',
///   onPaymentComplete: () {
///     // Navigate to success page
///   },
/// )
/// ```
import 'package:flutter/material.dart';

class PaymentStatusTracker extends StatefulWidget {
  final String reference;
  final double amount;
  final String currency;
  final VoidCallback? onPaymentComplete;
  final VoidCallback? onPaymentFailed;
  final String? providerCode;

  const PaymentStatusTracker({
    super.key,
    required this.reference,
    required this.amount,
    required this.currency,
    this.onPaymentComplete,
    this.onPaymentFailed,
    this.providerCode,
  });

  @override
  State<PaymentStatusTracker> createState() => _PaymentStatusTrackerState();
}

class _PaymentStatusTrackerState extends State<PaymentStatusTracker> {
  PaymentStatusPoller? _poller;
  String _currentStatus = 'pending';
  bool _isChecking = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  void _startPolling() {
    setState(() => _isChecking = true);

    _poller = PaymentStatusPoller(
      reference: widget.reference,
      pollingInterval: const Duration(seconds: 3),
      timeout: const Duration(minutes: 15),
      onStatusChange: (status, data) {
        if (!mounted) return;
        
        setState(() {
          _currentStatus = status;
          _isChecking = false;
        });

        // Handle terminal statuses
        if (status == 'successful' || status == 'completed' || status == 'confirmed') {
          widget.onPaymentComplete?.call();
        } else if (status == 'failed' || status == 'cancelled' || status == 'rejected') {
          widget.onPaymentFailed?.call();
        }
      },
      onError: (error) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment check error: $error'),
            backgroundColor: Colors.orange,
          ),
        );
      },
      onComplete: () {
        if (!mounted) return;
        setState(() => _isChecking = false);
      },
    );

    _poller?.start();
  }

  @override
  void dispose() {
    _poller?.stop();
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor() {
    switch (_currentStatus.toLowerCase()) {
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'successful':
      case 'completed':
      case 'confirmed':
        return Colors.green;
      case 'failed':
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus.toLowerCase()) {
      case 'pending':
      case 'processing':
        return Icons.hourglass_empty;
      case 'successful':
      case 'completed':
      case 'confirmed':
        return Icons.check_circle;
      case 'failed':
      case 'cancelled':
      case 'rejected':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getStatusMessage() {
    switch (_currentStatus.toLowerCase()) {
      case 'pending':
        return 'Waiting for payment confirmation...';
      case 'processing':
        return 'Processing your payment...';
      case 'successful':
      case 'completed':
      case 'confirmed':
        return 'Payment successful!';
      case 'failed':
        return 'Payment failed. Please try again.';
      case 'cancelled':
        return 'Payment was cancelled.';
      case 'rejected':
        return 'Payment was rejected.';
      default:
        return 'Checking payment status...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Icon
            Icon(
              _getStatusIcon(),
              size: 64,
              color: _getStatusColor(),
            ),
            const SizedBox(height: 16),

            // Status Text
            Text(
              _getStatusMessage(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Reference Number
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Payment Reference',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    widget.reference,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payments, size: 20),
                const SizedBox(width: 8),
                Text(
                  CurrencyService.instance.formatPrice(widget.amount, currencyCode: widget.currency),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Elapsed: ${_formatTime(_secondsElapsed)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Loading Indicator
            if (_isChecking)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Checking payment status...'),
                ],
              ),

            // Retry Button
            if (_currentStatus.toLowerCase() == 'failed' ||
                _currentStatus.toLowerCase() == 'rejected')
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStatus = 'pending';
                    _secondsElapsed = 0;
                  });
                  _startPolling();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check Again'),
              ),
          ],
        ),
      ),
    );
  }
}
