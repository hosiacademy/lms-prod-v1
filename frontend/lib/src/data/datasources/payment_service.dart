// payment_service.dart - ALIGNED WITH UPDATED MODELS
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../presentation/pages/onboarding/models/order_models.dart';
import '../../presentation/pages/onboarding/models/payment_enums.dart';
import '../../presentation/pages/onboarding/models/payment_transaction_models.dart';

// ENVIRONMENT FIX: Import environment configuration
import '../../core/config/environment.dart';

class PaymentService {
  // ENVIRONMENT FIX: Use Environment.apiBaseUrl instead of hardcoded URL
  static String get _baseUrl => '${Environment.apiBaseUrl}/api';

  final http.Client client;
  final String? authToken;

  PaymentService({required this.client, this.authToken});

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  // Get available payment methods for a country
  Future<List<PaymentMethod>> getAvailablePaymentMethods(
      String countryCode) async {
    try {
      // Use PaymentConstants from payment_enums.dart
      return PaymentConstants.getPaymentMethodsForCountry(countryCode);
    } catch (e) {
      debugPrint('Get payment methods error: $e');
      return [PaymentMethod.creditCard, PaymentMethod.payPal];
    }
  }

  // Check if payment method is available in country
  Future<bool> isPaymentMethodAvailable(
      String countryCode, PaymentMethod method) async {
    try {
      return PaymentConstants.isPaymentMethodAvailable(countryCode, method);
    } catch (e) {
      debugPrint('Check payment method availability error: $e');
      return false;
    }
  }

  // Create order with masterclass support
  Future<Order> createOrder({
    required String userId,
    required String userEmail,
    required String userName,
    required List<Map<String, dynamic>>
        items, // Can be courses or masterclasses
    required PaymentMethod paymentMethod,
    String? userPhone,
    String? userCountry,
    String? paymentProvider,
    bool isCorporate = false,
    String? companyName,
    String? notes,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/orders/create'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'user_email': userEmail,
          'user_name': userName,
          'user_phone': userPhone,
          'user_country': userCountry,
          'items': items,
          'payment_method':
              paymentMethod.value, // Use .value instead of .toString()
          'payment_provider': paymentProvider,
          'is_corporate': isCorporate,
          'company_name': companyName,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Create order error: $e');
      rethrow;
    }
  }

  // Create masterclass-specific order
  Future<Order> createMasterclassOrder({
    required String userId,
    required String userEmail,
    required String userName,
    required int masterclassId,
    required String masterclassTitle,
    required double price,
    required String currency,
    required PaymentMethod paymentMethod,
    int quantity = 1,
    String? userPhone,
    String? userCountry,
    String? paymentProvider,
    bool isCorporate = false,
    String? companyName,
    String? notes,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/masterclass/orders/create'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'user_email': userEmail,
          'user_name': userName,
          'masterclass_id': masterclassId,
          'masterclass_title': masterclassTitle,
          'price': price,
          'currency': currency,
          'quantity': quantity,
          'payment_method': paymentMethod.value,
          'user_phone': userPhone,
          'user_country': userCountry,
          'payment_provider': paymentProvider,
          'is_corporate': isCorporate,
          'company_name': companyName,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else {
        throw Exception(
            'Failed to create masterclass order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Create masterclass order error: $e');
      rethrow;
    }
  }

  // Process payment with enhanced details
  Future<PaymentTransaction> processPayment({
    required String orderId,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? paymentDetails,
    String? paymentProvider,
    String? mobileNumber,
    String? mobileProvider,
    String? cardLastFour,
    String? cardHolderName,
    String? cardExpiry,
    bool isCorporate = false,
    String? companyName,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/payments/process'),
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
          'payment_method': paymentMethod.value,
          'payment_details': paymentDetails,
          'payment_provider': paymentProvider,
          'mobile_number': mobileNumber,
          'mobile_provider': mobileProvider,
          'card_last_four': cardLastFour,
          'card_holder_name': cardHolderName,
          'card_expiry': cardExpiry,
          'is_corporate': isCorporate,
          'company_name': companyName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentTransaction.fromJson(data['transaction']);
      } else {
        throw Exception('Failed to process payment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Process payment error: $e');
      rethrow;
    }
  }

  // Process mobile money payment
  Future<PaymentTransaction> processMobileMoneyPayment({
    required String orderId,
    required String mobileNumber,
    required String mobileProvider,
    required PaymentMethod paymentMethod,
    String? countryCode,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/payments/mobile-money/process'),
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
          'mobile_number': mobileNumber,
          'mobile_provider': mobileProvider,
          'payment_method': paymentMethod.value,
          'country_code': countryCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentTransaction.fromJson(data['transaction']);
      } else {
        throw Exception(
            'Failed to process mobile money payment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Process mobile money payment error: $e');
      rethrow;
    }
  }

  // Process card payment
  Future<PaymentTransaction> processCardPayment({
    required String orderId,
    required String cardToken, // From payment gateway
    required PaymentMethod paymentMethod,
    String? cardLastFour,
    String? cardHolderName,
    String? cardExpiry,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/payments/card/process'),
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
          'card_token': cardToken,
          'payment_method': paymentMethod.value,
          'card_last_four': cardLastFour,
          'card_holder_name': cardHolderName,
          'card_expiry': cardExpiry,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentTransaction.fromJson(data['transaction']);
      } else {
        throw Exception(
            'Failed to process card payment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Process card payment error: $e');
      rethrow;
    }
  }

  // Verify payment
  Future<PaymentTransaction> verifyPayment({
    required String transactionId,
    required String reference,
    PaymentMethod? paymentMethod,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/payments/verify'),
        headers: _headers,
        body: jsonEncode({
          'transaction_id': transactionId,
          'reference': reference,
          if (paymentMethod != null) 'payment_method': paymentMethod.value,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentTransaction.fromJson(data['transaction']);
      } else {
        throw Exception('Failed to verify payment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Verify payment error: $e');
      rethrow;
    }
  }

  // Get order by ID
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/orders/$orderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else {
        throw Exception('Failed to get order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get order error: $e');
      rethrow;
    }
  }

  // Get user orders with filters
  Future<List<Order>> getUserOrders({
    required String userId,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCorporate,
  }) async {
    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status.value;
      if (paymentMethod != null) params['payment_method'] = paymentMethod.value;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();
      if (isCorporate != null) params['is_corporate'] = isCorporate.toString();

      final uri = Uri.parse('$_baseUrl/orders/user/$userId').replace(
        queryParameters: params.isNotEmpty ? params : null,
      );

      final response = await client.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ordersJson = data['orders'];
        return ordersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get user orders: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get user orders error: $e');
      rethrow;
    }
  }

  // Get user transactions with filters
  Future<List<PaymentTransaction>> getUserTransactions({
    required String userId,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCorporate,
  }) async {
    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status.value;
      if (paymentMethod != null) params['payment_method'] = paymentMethod.value;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();
      if (isCorporate != null) params['is_corporate'] = isCorporate.toString();

      final uri = Uri.parse('$_baseUrl/payments/user/$userId').replace(
        queryParameters: params.isNotEmpty ? params : null,
      );

      final response = await client.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> transactionsJson = data['transactions'];
        return transactionsJson
            .map((json) => PaymentTransaction.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to get user transactions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get user transactions error: $e');
      rethrow;
    }
  }

  // Get transaction by ID
  Future<PaymentTransaction> getTransactionById(String transactionId) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/payments/transaction/$transactionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentTransaction.fromJson(data['transaction']);
      } else {
        throw Exception('Failed to get transaction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get transaction error: $e');
      rethrow;
    }
  }

  // Get transactions for order
  Future<List<PaymentTransaction>> getTransactionsForOrder(
      String orderId) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/payments/order/$orderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> transactionsJson = data['transactions'];
        return transactionsJson
            .map((json) => PaymentTransaction.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to get order transactions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get order transactions error: $e');
      rethrow;
    }
  }

  // Check payment status
  Future<PaymentStatus> checkPaymentStatus({
    required String transactionId,
    required String reference,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/payments/status'),
        headers: _headers,
        body: jsonEncode({
          'transaction_id': transactionId,
          'reference': reference,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statusValue = data['status'] as String;
        return PaymentStatus.fromValue(statusValue);
      } else {
        throw Exception(
            'Failed to check payment status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Check payment status error: $e');
      rethrow;
    }
  }

  // Get payment provider configuration
  Future<Map<String, dynamic>> getPaymentProviderConfig({
    required PaymentMethod paymentMethod,
    required String countryCode,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/payments/provider/config'),
        headers: _headers,
        body: jsonEncode({
          'payment_method': paymentMethod.value,
          'country_code': countryCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['config'] as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to get provider config: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get provider config error: $e');
      return {};
    }
  }

  // Initialize payment (for gateways that require pre-authorization)
  Future<Map<String, dynamic>> initializePayment({
    required String orderId,
    required PaymentMethod paymentMethod,
    required double amount,
    required String currency,
    String? returnUrl,
    String? cancelUrl,
    String? callbackUrl,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/payments/initialize'),
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
          'payment_method': paymentMethod.value,
          'amount': amount,
          'currency': currency,
          'return_url': returnUrl,
          'cancel_url': cancelUrl,
          'callback_url': callbackUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['initialization'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to initialize payment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Initialize payment error: $e');
      rethrow;
    }
  }

  // Cancel payment/order
  Future<bool> cancelPayment({
    required String orderId,
    String? reason,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/payments/cancel'),
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
          'reason': reason,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Cancel payment error: $e');
      return false;
    }
  }

  // Request refund
  Future<PaymentTransaction> requestRefund({
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/payments/refund'),
        headers: _headers,
        body: jsonEncode({
          'transaction_id': transactionId,
          'amount': amount,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentTransaction.fromJson(data['refund_transaction']);
      } else {
        throw Exception('Failed to request refund: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Request refund error: $e');
      rethrow;
    }
  }
}
