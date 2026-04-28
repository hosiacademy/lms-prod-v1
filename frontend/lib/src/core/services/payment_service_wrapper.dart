// lib/src/core/services/payment_service_wrapper.dart
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'payment_status_poller.dart';
import 'auth_service.dart';

/// Payment Service Wrapper
/// 
/// Provides a unified interface for all payment operations across
/// different enrollment pathways (Masterclass, Learnerships, Industry Training, Custom Selection)
/// 
/// Usage Example:
/// ```dart
/// // Initiate payment
/// final paymentService = PaymentServiceWrapper();
/// 
/// final result = await paymentService.initiatePayment(
///   programId: '123',
///   programType: 'masterclass',
///   amount: 299.00,
///   currency: 'USD',
///   country: 'ZA',
///   metadata: {
///     'enrollment_type': 'masterclass',
///     'individual_details': {
///       'email': 'student@example.com',
///       'full_name': 'John Doe',
///     },
///   },
/// );
/// 
/// // Start polling for payment status
/// await paymentService.startPaymentPolling(
///   reference: result['reference'],
///   onStatusChange: (status, data) {
///     if (status == 'successful') {
///       // Handle successful payment
///     }
///   },
/// );
/// ```
class PaymentServiceWrapper {
  PaymentStatusPoller? _activePoller;

  /// Initiate payment for any enrollment type
  /// 
  /// This is the main entry point for all payment flows.
  /// It handles both Stage 1 (reference generation) and Stage 2 (payment initiation).
  Future<Map<String, dynamic>> initiatePayment({
    required String programId,
    required String programType,
    required double amount,
    required String currency,
    required String country,
    Map<String, dynamic>? metadata,
    String? provider,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      debugPrint('💳 Initiating payment: $programType - $amount $currency');

      final response = await ApiClient.initiatePayment(
        programId: programId,
        type: programType,
        amount: amount,
        metadata: metadata ?? {},
        provider: provider,
        country: country,
        currency: currency,
        phoneNumber: phoneNumber,
        email: email,
      );

      debugPrint('✅ Payment initiated: ${response['reference']}');
      
      return response;
    } catch (e) {
      debugPrint('❌ Payment initiation failed: $e');
      rethrow;
    }
  }

  /// Get available payment providers for a country
  Future<List<Map<String, dynamic>>> getAvailableProviders({
    required String country,
    double? amount,
    String? currency,
  }) async {
    try {
      final response = await ApiClient.getAvailablePaymentProviders(
        country: country,
        amount: amount,
        currency: currency,
      );

      final providers = List<Map<String, dynamic>>.from(
        response['available_providers'] ?? [],
      );

      debugPrint('🏦 Available providers for $country: ${providers.length}');
      
      return providers;
    } catch (e) {
      debugPrint('❌ Failed to get providers: $e');
      return [];
    }
  }

  /// Start polling payment status
  /// 
  /// Returns the poller instance for manual control
  PaymentStatusPoller startPaymentPolling({
    required String reference,
    required Function(String status, Map<String, dynamic>? data) onStatusChange,
    Function(String error)? onError,
    Function()? onComplete,
    Duration pollingInterval = const Duration(seconds: 5),
    Duration timeout = const Duration(minutes: 10),
  }) {
    // Stop any existing poller
    _activePoller?.stop();

    // Create new poller
    _activePoller = PaymentStatusPoller(
      reference: reference,
      onStatusChange: onStatusChange,
      onError: onError,
      onComplete: onComplete,
      pollingInterval: pollingInterval,
      timeout: timeout,
    );

    // Start polling
    _activePoller!.start();

    debugPrint('🔄 Started polling for reference: $reference');
    
    return _activePoller!;
  }

  /// Stop active payment polling
  void stopPaymentPolling() {
    _activePoller?.stop();
    _activePoller = null;
    debugPrint('⏹️ Stopped payment polling');
  }

  /// Upload proof of payment for EFT/Bank Transfer
  Future<Map<String, dynamic>> uploadProofOfPayment({
    required String reference,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      debugPrint('📎 Uploading proof of payment: $reference');

      final response = await ApiClient.uploadProofOfPayment(
        reference: reference,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      debugPrint('✅ Proof of payment uploaded successfully');
      
      return response;
    } catch (e) {
      debugPrint('❌ Failed to upload proof of payment: $e');
      rethrow;
    }
  }

  /// Check EFT payment status
  Future<Map<String, dynamic>> checkEFTStatus(String reference) async {
    try {
      final response = await ApiClient.checkEFTStatus(reference);
      debugPrint('📊 EFT Status for $reference: ${response['status']}');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to check EFT status: $e');
      rethrow;
    }
  }

  /// Create cash/on-site payment reservation
  Future<Map<String, dynamic>> createCashPaymentReservation({
    required String programId,
    required String programType,
    required Map<String, dynamic> userData,
    required double amount,
    String paymentMethod = 'cash',
  }) async {
    try {
      debugPrint('💵 Creating cash payment reservation: $programType');

      final response = await ApiClient.createOnSiteEnrollment(
        programId: programId,
        type: programType,
        userData: userData,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      debugPrint('✅ Cash payment reservation created: ${response['reference_code']}');
      
      return response;
    } catch (e) {
      debugPrint('❌ Failed to create cash reservation: $e');
      rethrow;
    }
  }

  /// Settle cash payment (for admin use)
  Future<Map<String, dynamic>> settleCashPayment(String referenceCode) async {
    try {
      final response = await ApiClient.settleOnSitePayment(referenceCode);
      debugPrint('✅ Cash payment settled: $referenceCode');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to settle cash payment: $e');
      rethrow;
    }
  }

  /// Verify payment status (one-time check, not polling)
  Future<Map<String, dynamic>> verifyPaymentStatus(String reference) async {
    try {
      final response = await ApiClient.verifyPaymentStatus(reference);
      debugPrint('📊 Payment status for $reference: ${response['status']}');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to verify payment: $e');
      rethrow;
    }
  }

  /// Finalize enrollment after successful payment
  Future<Map<String, dynamic>> finalizeEnrollment({
    required String reference,
    required String programType,
    required int programId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      debugPrint('🎓 Finalizing enrollment: $reference');

      final response = await ApiClient.finalizeEnrollment(
        reference: reference,
        programType: programType,
        programId: programId,
        metadata: metadata,
      );

      debugPrint('✅ Enrollment finalized: ${response['enrollment_id']}');
      
      return response;
    } catch (e) {
      debugPrint('❌ Failed to finalize enrollment: $e');
      rethrow;
    }
  }

  /// Get user's payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    String? userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // This would need a new backend endpoint
      // For now, return empty list
      debugPrint('⚠️ getPaymentHistory not yet implemented');
      return [];
    } catch (e) {
      debugPrint('❌ Failed to get payment history: $e');
      return [];
    }
  }

  /// Dispose - cleanup resources
  void dispose() {
    stopPaymentPolling();
  }
}


/// Payment Flow Helper
/// 
/// Simplifies common payment flow patterns
class PaymentFlowHelper {
  final PaymentServiceWrapper _paymentService;

  PaymentFlowHelper() : _paymentService = PaymentServiceWrapper();

  /// Complete payment flow with provider selection
  /// 
  /// This is the standard flow used by most enrollment pathways:
  /// 1. Generate reference
  /// 2. Show payment provider selection
  /// 3. Initiate payment with selected provider
  /// 4. Poll for payment completion
  /// 5. Finalize enrollment
  Future<Map<String, dynamic>> completePaymentFlow({
    required String programId,
    required String programType,
    required double amount,
    required String currency,
    required String country,
    required Map<String, dynamic> enrollmentData,
    String? providerCode,
  }) async {
    try {
      // Step 1: Generate reference (Stage 1)
      debugPrint('📝 Stage 1: Generating reference...');
      final referenceResponse = await _paymentService.initiatePayment(
        programId: programId,
        programType: programType,
        amount: amount,
        currency: currency,
        country: country,
        metadata: enrollmentData,
        // No provider = Stage 1 (reference generation)
      );

      final reference = referenceResponse['reference'];
      debugPrint('✅ Reference generated: $reference');

      // Step 2: If provider already selected, initiate payment (Stage 2)
      if (providerCode != null && providerCode.isNotEmpty) {
        debugPrint('💳 Stage 2: Initiating payment with $providerCode...');
        
        final paymentResponse = await _paymentService.initiatePayment(
          programId: programId,
          programType: programType,
          amount: amount,
          currency: currency,
          country: country,
          metadata: {
            ...enrollmentData,
            'reference': reference,
          },
          provider: providerCode,
        );

        debugPrint('✅ Payment initiated: ${paymentResponse['checkout_url']}');
        
        return {
          'reference': reference,
          'checkout_url': paymentResponse['checkout_url'],
          'status': 'payment_initiated',
        };
      }

      // Return reference for provider selection
      return {
        'reference': reference,
        'status': 'reference_generated',
      };
    } catch (e) {
      debugPrint('❌ Payment flow failed: $e');
      rethrow;
    }
  }

  /// Handle payment result
  /// 
  /// Call this after payment provider redirects back
  Future<bool> handlePaymentResult({
    required String reference,
    required String programType,
    required int programId,
    required Map<String, dynamic> enrollmentPayload,
  }) async {
    try {
      // Verify payment status
      final paymentStatus = await _paymentService.verifyPaymentStatus(reference);
      final status = paymentStatus['status'] as String;

      if (status == 'successful' || status == 'completed' || status == 'confirmed') {
        // Finalize enrollment
        await _paymentService.finalizeEnrollment(
          reference: reference,
          programType: programType,
          programId: programId,
          metadata: enrollmentPayload,
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Failed to handle payment result: $e');
      return false;
    }
  }

  /// Cleanup
  void dispose() {
    _paymentService.dispose();
  }
}
