// lib/src/core/api/api_client.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data' show Uint8List;

import '../config/environment.dart';
import '../services/auth_service.dart';
import '../../data/models/masterclass.dart';
import '../../data/models/course.dart';
import '../../data/models/learnership.dart';
import '../../presentation/widgets/bbb/create_session_modal.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiBaseUrl, // Aligned with Port Table (Port 7001)
      connectTimeout: Duration(seconds: Environment.apiTimeout),
      receiveTimeout: Duration(seconds: Environment.apiTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static void initialize() {
    // Add Authentication Interceptor with Token Refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip auth header for login and token refresh endpoints
          if (!options.path.contains('/auth/login') &&
              !options.path.contains('/auth/refresh')) {
            final token = await AuthService.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401/403 errors by attempting token refresh
          if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
            final errorCode = error.response?.data?['code'];
            final isTokenNotValid = errorCode == 'token_not_valid' ||
                                    errorCode == 'token_expired' ||
                                    (error.response?.data?['detail']?.contains('expired') ?? false);

            if (isTokenNotValid) {
              try {
                print('🔄 Token expired, attempting refresh...');
                final refreshToken = await AuthService.getRefreshToken();

                if (refreshToken != null && refreshToken.isNotEmpty) {
                  // Call token refresh endpoint
                  final refreshResponse = await _dio.post(
                    '/api/v1/auth/refresh/',
                    data: {'refresh': refreshToken},
                  );
                  
                  if (refreshResponse.statusCode == 200) {
                    final newAccessToken = refreshResponse.data['access'];
                    if (newAccessToken != null) {
                      // Save new access token
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('access_token', newAccessToken);
                      
                      // Retry original request with new token
                      error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                      print('✅ Token refreshed successfully, retrying request...');
                      
                      final response = await _dio.fetch(error.requestOptions);
                      return handler.resolve(response);
                    }
                  }
                }
              } catch (refreshError) {
                print('❌ Token refresh failed: $refreshError');
                // Clear auth state and redirect to login
                await AuthService.logout();
                // Note: Navigation should be handled by auth provider
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Add logging interceptor (production-safe)
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
        // Mask sensitive data in logs
        logPrint: (obj) {
          // Redact Bearer tokens from logs
          final sanitized = obj.toString().replaceAll(
            RegExp(r'Bearer\s+[A-Za-z0-9\-_\.]+'),
            'Bearer [REDACTED]'
          );
          print(sanitized);
        },
      ),
    );
  }

  // Generic GET
  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      print('GET $path failed: ${e.message}');
      if (e.response != null) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // Generic POST
  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      print('POST $path failed: ${e.message}');
      rethrow;
    }
  }

  // Generic DELETE
  static Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      print('DELETE $path failed: ${e.message}');
      if (e.response != null) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // ==============================
  // PAYMENT & ENROLLMENT METHODS
  // ==============================

  static Future<Map<String, dynamic>> getAvailablePaymentProviders({
    String? country,
    double? amount,
    String? currency,
  }) async {
    final queryParams = <String, dynamic>{};
    if (country != null) queryParams['country'] = country;
    if (amount != null) queryParams['amount'] = amount;
    if (currency != null) queryParams['currency'] = currency;

    final response = await get(
      '/api/v1/payments/providers/',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> initiatePayment({
    required String programId,
    required String type,
    required double amount,
    required Map<String, dynamic> metadata,
    String? orderId,
    String? provider,
    String? country,
    String? currency,
    String? phoneNumber,
    String? email,
  }) async {
    // Backend expects email in metadata.individual_details.email
    final emailToUse = email ?? 'mazandotakawira@gmail.com';
    final updatedMetadata = {
      ...metadata,
      'individual_details': {
        ...metadata['individual_details'] ?? {},
        'email': emailToUse,
      },
    };
    
    final payload = {
      'program_id': programId,
      'type': type,
      'amount': amount,
      'email': emailToUse, // Also send at top level for payment_views.py
      'metadata': updatedMetadata,
      if (orderId != null) 'order_id': orderId,
      if (provider != null) 'provider_code': provider,
      if (country != null) 'country': country,
      if (currency != null) 'currency': currency,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };

    final response = await post('/api/v1/payments/initiate/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createEnrollment(
      Map<String, dynamic> data) async {
    final response = await post('/api/v1/payments/enrollments/', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createBulkEnrollment(
      Map<String, dynamic> data) async {
    final response =
        await post('/api/v1/payments/bulk-enrollments/', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> proceedToPayment({
    required int enrollmentId,
    bool isBulk = false,
  }) async {
    final path = isBulk
        ? '/api/v1/payments/bulk-enrollments/$enrollmentId/proceed_to_payment/'
        : '/api/v1/payments/enrollments/$enrollmentId/proceed_to_payment/';
    final response = await post(path, data: {});
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createProvisionalEnrollment({
    required String programId,
    required String type,
    required Map<String, dynamic> userData,
    required String method,
    required double amount,
  }) async {
    final payload = {
      'program_id': programId,
      'type': type,
      'method': method,
      'amount': amount,
      'user_data': userData,
      'status': 'provisional',
    };

    final response =
        await post('/api/v1/enrollments/provisional/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> finalizeEnrollment({
    required String reference,
    required String programType,
    required int programId,
    required Map<String, dynamic> metadata,
  }) async {
    final payload = {
      'reference': reference,
      'program_type': programType,
      'program_id': programId,
      'metadata': metadata,
    };

    final response =
        await post('/api/v1/payments/enrollments/finalize/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getCashPaymentInstructions({
    required String enrollmentType,
    required String programId,
    required String programTitle,
  }) async {
    final response = await get(
      '/api/v1/payments/enrollments/cash-payment-instructions/',
      queryParameters: {
        'enrollment_type': enrollmentType,
        'program_id': programId,
        'program_title': programTitle,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyPaymentStatus(
      String reference) async {
    final response = await get('/api/v1/payments/verify/$reference/');
    return response.data;
  }

  static Future<void> submitBankDetails({
    required String reference,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    required String branchCode,
  }) async {
    final payload = {
      'reference': reference,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder': accountHolder,
      'branch_code': branchCode,
    };
    await post('/api/v1/payments/eft/submit-bank-details/', data: payload);
  }

  static Future<Map<String, dynamic>> uploadProofOfPayment({
    required String reference,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Environment.apiBaseUrl}/api/v1/payments/eft/upload-pop/$reference/'),
    );

    // Add authentication header if available
    // TODO: Implement proper token retrieval
    // final token = await AuthService.getJwtToken();
    // if (token != null) {
    //   request.headers['Authorization'] = 'Bearer $token';
    // }
    
    // Add file
    request.files.add(http.MultipartFile.fromBytes(
      'proof_of_payment',
      fileBytes,
      filename: fileName,
    ));
    
    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to upload proof of payment: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> checkEFTStatus(String reference) async {
    final response = await get('/api/v1/payments/eft/status/$reference/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getPendingEFTPayments() async {
    final response = await get('/api/v1/payments/eft/admin/pending/');
    return response.data as Map<String, dynamic>;
  }

  // ==============================
  // CASH / ON-SITE PAYMENT METHODS
  // ==============================

  static Future<Map<String, dynamic>> createOnSiteEnrollment({
    required String programId,
    required String type,
    required Map<String, dynamic> userData,
    required double amount,
    required String paymentMethod,
  }) async {
    final payload = {
      'program_id': programId,
      'type': type,
      'user_data': userData,
      'amount': amount,
      'payment_method': paymentMethod,
    };
    final response = await post('/api/v1/payments/on-site/create/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOnSiteEnrollment(String referenceCode) async {
    final response = await get('/api/v1/payments/on-site/$referenceCode/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> settleOnSitePayment(String referenceCode) async {
    final response = await post('/api/v1/payments/on-site/$referenceCode/settle/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getPendingOnSitePayments() async {
    final response = await get('/api/v1/payments/on-site/admin/pending/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> initiatePaystackPayment({
    required double amount,
    required String email,
    required String reference,
  }) async {
    final payload = {
      'amount': amount,
      'email': email,
      'reference': reference,
    };
    final response = await post('/api/v1/payments/initiate/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> simulatePaymentSuccess(
      String transactionId) async {
    final response = await post(
        '/api/v1/payments/simulate-success/$transactionId/',
        data: {});
    return response.data as Map<String, dynamic>;
  }

  // ==============================
  // NEW METHODS – added to support EnrollmentService
  // ==============================

  /// Creates a new user (via apps.users.urls)
  static Future<Map<String, dynamic>> createUser({
    required String firstName,
    required String lastName,
    required String email,
    String? username,
    String? password,
    String? idNumber,
    String? phone,
  }) async {
    final payload = {
      'first_name': firstName,
      'last_name': lastName,
      'name': '$firstName $lastName'.trim(),
      'email': email,
      'username': username ?? email,
      'password': password ??
          'Hosi@${DateTime.now().millisecondsSinceEpoch}', // Default password if none provided
      if (idNumber != null) 'id_number': idNumber,
      if (phone != null) 'phone': phone,
    };

    final response = await post(
      '/api/v1/users/create/',
      data: payload,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Initiate EFT/Bank Transfer payment
  static Future<Map<String, dynamic>> initiateEftPayment({
    required String programId,
    required String type,
    required double amount,
    required String currency,
    required String country,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? individualDetails,
    Map<String, dynamic>? corporateDetails,
  }) async {
    final payload = {
      'program_id': programId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'country': country,
      'metadata': metadata ?? {},
      if (individualDetails != null) 'individual_details': individualDetails,
      if (corporateDetails != null) 'corporate_details': corporateDetails,
    };
    
    final response = await post('/api/v1/payments/eft/initiate/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  /// Get current user's enrollments
  static Future<List<Map<String, dynamic>>> getMyEnrollments() async {
    final response = await get('/api/v1/payments/enrollments/');
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else if (response.data is Map && response.data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(response.data['results']);
    }
    return [];
  }

  /// Get SSO URL for an enrollment
  static Future<String?> getEnrollmentSSOUrl(int enrollmentId) async {
    final response =
        await get('/api/v1/payments/enrollments/$enrollmentId/get_sso_url/');
    return response.data['sso_url'] as String?;
  }

  /// Get AICerts specific enrollments
  static Future<List<Map<String, dynamic>>> getAICertsEnrollments() async {
    final response = await get('/api/v1/aicerts/enrollments/');
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else if (response.data is Map && response.data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(response.data['results']);
    }
    return [];
  }

  /// Get SSO URL for an AICerts course enrollment
  static Future<String?> getAICertsSSOUrl(int enrollmentId) async {
    final response =
        await get('/api/v1/aicerts/enrollments/$enrollmentId/sso-url/');
    return response.data['sso_url'] as String?;
  }

  /// Get Learnership enrollments with prerequisite status
  static Future<List<Map<String, dynamic>>> getLearnershipEnrollments() async {
    final response = await get('/api/v1/learnerships/enrollments/');
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else if (response.data is Map && response.data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(response.data['results']);
    }
    return [];
  }

  /// Get prerequisite status for a learnership enrollment
  static Future<Map<String, dynamic>> getPrerequisitesStatus(
      int learnershipEnrollmentId) async {
    final response = await get(
        '/api/v1/learnerships/enrollments/$learnershipEnrollmentId/prerequisites_status/');
    return response.data as Map<String, dynamic>;
  }

  /// Upload prerequisite evidence
  static Future<Map<String, dynamic>> uploadPrerequisiteEvidence({
    required int enrollmentId,
    required String prerequisiteKey,
    required String prerequisiteName,
    required dynamic file, // MultipartFile or similar
    String? description,
  }) async {
    final formData = FormData.fromMap({
      'enrollment': enrollmentId,
      'prerequisite_key': prerequisiteKey,
      'prerequisite_name': prerequisiteName,
      'evidence_file': file,
      if (description != null) 'evidence_description': description,
    });

    final response =
        await post('/api/v1/learnerships/evidence/', data: formData);
    return response.data as Map<String, dynamic>;
  }

  /// Checks if an email exists (via apps.users.urls)
  static Future<bool> checkEmailExists(String email) async {
    final response = await get(
      '/api/v1/users/check-email/',
      queryParameters: {'email': email},
    );
    final data = response.data as Map<String, dynamic>;
    return data['exists'] as bool;
  }

  /// Creates a provisional learnership enrollment record
  static Future<Map<String, dynamic>> createProvisionalLearnershipEnrollment({
    required int programId,
    required String userId,
    required String transactionReference,
    required int expiresInDays,
    required bool isCorporate,
    Map<String, dynamic>? companyData,
  }) async {
    final payload = {
      'program_id': programId,
      'user_id': userId,
      'transaction_reference': transactionReference,
      'expires_in_days': expiresInDays,
      'is_corporate': isCorporate,
      if (companyData != null) 'company': companyData,
    };

    final response = await post(
      '/api/v1/enrollments/provisional/learnership/', // matches your apps.enrollments.urls
      data: payload,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Confirms a provisional learnership enrollment (admin verification)
  static Future<Map<String, dynamic>> confirmProvisionalLearnershipEnrollment(
    int provisionalId,
  ) async {
    final response = await post(
      '/api/v1/enrollments/provisional/$provisionalId/confirm/',
      data: {},
    );

    return response.data as Map<String, dynamic>;
  }

   /// Retrieves details of a provisional learnership enrollment
  static Future<Map<String, dynamic>> getProvisionalLearnershipEnrollment(
    int provisionalId,
  ) async {
    final response = await get(
      '/api/v1/enrollments/provisional/$provisionalId/',
    );

    return response.data as Map<String, dynamic>;
  }

  /// Calculate learnership payment plan breakdown
  static Future<Map<String, dynamic>> calculateLearnershipPaymentPlan({
    required int programmeId,
    String paymentOption = 'upfront',
    bool isCorporate = false,
    int learnerCount = 1,
    String currency = 'USD',
  }) async {
    final payload = {
      'programme_id': programmeId,
      'payment_option': paymentOption,
      'is_corporate': isCorporate,
      'learner_count': learnerCount,
      'currency': currency,
    };

    final response = await post(
      '/api/v1/payments/calculate-learnership-plan/',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Validate learnership payment details before initiating payment
  static Future<Map<String, dynamic>> validateLearnershipPayment({
    required int programmeId,
    required String paymentOption,
    required double paymentAmount,
    bool isCorporate = false,
    int learnerCount = 1,
  }) async {
    final payload = {
      'programme_id': programmeId,
      'payment_option': paymentOption,
      'payment_amount': paymentAmount,
      'is_corporate': isCorporate,
      'learner_count': learnerCount,
    };

    final response = await post(
      '/api/v1/payments/validate-learnership-payment/',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Triggers a reimbursement/refund for a payment
  static Future<Map<String, dynamic>> reimbursePayment(
    String transactionReference,
  ) async {
    final payload = {
      'transaction_reference': transactionReference,
      // Optional: add reason or amount if your backend requires it
      // 'reason': 'Learnership prerequisites not met',
    };

    final response = await post(
      '/api/v1/payments/reimburse/', // matches path("api/v1/payments/", include("apps.payments.urls"))
      data: payload,
    );

    return response.data as Map<String, dynamic>;
  }

  // ==============================
  // LOCATION DATA METHODS
  // ==============================

  static Future<List<Map<String, dynamic>>> getAfricanCountries() async {
    final response = await get('/api/v1/localization/countries/');
    final items = _extractList(response.data);
    return List<Map<String, dynamic>>.from(items);
  }

  static Future<List<Map<String, dynamic>>> getAfricanCities(
      int countryId) async {
    final response = await get(
      '/api/v1/localization/cities/',
      queryParameters: {'country_id': countryId},
    );
    final items = _extractList(response.data);
    return List<Map<String, dynamic>>.from(items);
  }

  // ==============================
  // ADMIN METHODS
  // ==============================

  static Future<Map<String, dynamic>> submitPartnerApplication(Map<String, dynamic> data) async {
    final response = await post('/api/v1/referrals/program/apply/', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getPartnerApplications() async {
    final response = await get('/api/v1/referrals/applications/');
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else if (response.data is Map && response.data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(response.data['results']);
    }
    return [];
  }

  static Future<void> updatePartnerApplicationStatus(int id, String action) async {
    await post('/api/v1/referrals/applications/$id/$action/');
  }

  static Future<Map<String, dynamic>> getAdminPayments({
    String? status,
    String? filter,
    String? searchQuery,
  }) async {
    final query = <String, dynamic>{};

    if (status != null) query['status'] = status;
    if (filter != null) query['filter'] = filter;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query['search'] = searchQuery;
    }

    final response = await get(
      '/api/v1/payments/admin/payments/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get staff directory for chat and internal management.
  static Future<List<Map<String, dynamic>>> getStaffDirectory({String? searchQuery}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }

      final response = await get(
        '/api/v1/staff/directory/',
        queryParameters: queryParams,
      );

      final items = _extractList(response.data);
      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      print('ApiClient.getStaffDirectory error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String status,
    String? notes,
  }) async {
    final payload = {
      'status': status,
      if (notes != null) 'notes': notes,
    };

    final response = await post(
      '/api/v1/payments/admin/payments/$paymentId/verify/',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOperationalAdminData({
    String? searchQuery,
    Map<String, dynamic>? queryParams,
  }) async {
    final query = <String, dynamic>{};
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query['search'] = searchQuery;
    }
    if (queryParams != null) {
      query.addAll(queryParams);
    }

    final response = await get(
      '/api/v1/payments/admin/operations/data/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMarketingAnalytics({
    int limit = 50,
    Map<String, dynamic>? queryParams,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (queryParams != null) {
      query.addAll(queryParams);
    }

    final response = await get(
      '/api/v1/payments/admin/marketing/analytics/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getPaymentAdminSalesAnalytics({
    Map<String, dynamic>? queryParams,
  }) async {
    final query = <String, dynamic>{};
    if (queryParams != null) {
      query.addAll(queryParams);
    }

    final response = await get(
      '/api/v1/payments/admin/sales/analytics/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getExecutiveDashboardAnalytics({
    String? period,
    String? country,
    Map<String, dynamic>? queryParams,
  }) async {
    final query = <String, dynamic>{};
    if (period != null) query['period'] = period;
    if (country != null) query['country'] = country;
    if (queryParams != null) query.addAll(queryParams);

    final response = await get(
      '/api/v1/payments/admin/executive/dashboard/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getExecutiveFinancialInsights({
    String? period,
    String? country,
  }) async {
    final query = <String, dynamic>{};
    if (period != null) query['period'] = period;
    if (country != null) query['country'] = country;

    final response = await get(
      '/api/v1/payments/admin/executive/financial-insights/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getExecutiveCountryComparison({
    String? period,
  }) async {
    final query = <String, dynamic>{};
    if (period != null) query['period'] = period;

    final response = await get(
      '/api/v1/payments/admin/executive/country-comparison/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyProvisionalEnrollment({
    required int enrollmentId,
    required String status,
    String? notes,
  }) async {
    final payload = {
      'status': status,
      if (notes != null) 'notes': notes,
    };

    final response = await post(
      '/api/v1/payments/admin/operations/provisional/$enrollmentId/verify/',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getHRDashboardData() async {
    final response = await get('/api/v1/payments/admin/hr/dashboard/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getExecutiveAnalytics({
    String? period,
  }) async {
    final query = <String, dynamic>{};
    if (period != null) query['period'] = period;

    final response = await get(
      '/api/v1/payments/admin/executive/analytics/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getSalesMarketingAnalytics({
    String? period,
  }) async {
    final query = <String, dynamic>{};
    if (period != null) query['period'] = period;

    final response = await get(
      '/api/v1/payments/admin/sales-marketing/analytics/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getInstructorPayrollData() async {
    final response =
        await get('/api/v1/payments/admin/hr/payroll/instructors/');
    return response.data as Map<String, dynamic>;
  }

  // ==================== FAILED PROVISIONING ADMIN APIs ====================

  /// Get failed provisioning data for admin review
  static Future<Map<String, dynamic>> getFailedProvisioningData({
    String status = 'all',  // all, pending_review, retry_failed, resolved
    String days = '30',    // 7, 30, 90, all
  }) async {
    final response = await get(
      '/api/v1/payments/admin/failed-provisioning/',
      queryParameters: {
        'status': status,
        'days': days,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Retry provisioning for a failed transaction
  static Future<Map<String, dynamic>> retryProvisioning({
    required String transactionId,
    String? notes,
  }) async {
    final payload = {
      if (notes != null) 'notes': notes,
    };

    final response = await post(
      '/api/v1/payments/admin/failed-provisioning/$transactionId/retry/',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Mark provisioning as resolved manually
  static Future<Map<String, dynamic>> markProvisioningResolved({
    required String transactionId,
    String? notes,
  }) async {
    final payload = {
      if (notes != null) 'notes': notes,
    };

    final response = await post(
      '/api/v1/payments/admin/failed-provisioning/$transactionId/mark-resolved/',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateInstructorRate({
    required int userId,
    required double hourlyRate,
  }) async {
    final payload = {'hourly_rate': hourlyRate};
    final response = await post(
      '/api/v1/payments/admin/hr/payroll/instructors/$userId/rate/',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  // ==================== QUOTATION METHODS ====================

  static Future<Map<String, dynamic>> getQuotations({
    String? country,
    String? status,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (country != null) query['country'] = country;
    if (status != null) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await get(
      '/api/v1/payments/quotations/',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createQuotation(
      Map<String, dynamic> data) async {
    final response = await post('/api/v1/payments/quotations/', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getQuotationDetail(
      String quotationNumber) async {
    final response =
        await get('/api/v1/payments/quotations/$quotationNumber/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> convertQuotationToEnrollment(
      String quotationNumber) async {
    final response = await post(
      '/api/v1/payments/quotations/$quotationNumber/convert/',
      data: {},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getQuotationTrainingTypes() async {
    final response = await get('/api/v1/payments/quotations/training-types/');
    return response.data['types'] as List<dynamic>;
  }

  static Future<List<dynamic>> getQuotationTrainingItems(String type,
      {String? country, String? currency}) async {
    final query = <String, dynamic>{};
    if (country != null) query['country'] = country;
    if (currency != null) query['currency'] = currency;
    final response = await get('/api/v1/payments/quotations/$type/',
        queryParameters: query);
    return response.data['items'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getQuotationPricing({
    required String type,
    required dynamic itemId,
    required String country,
    required String currency,
  }) async {
    final response = await post('/api/v1/payments/quotations/get-pricing/', data: {
      'training_type': type,
      'item_id': itemId,
      'country': country,
      'currency': currency,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> sendQuotationEmail(int quotationId) async {
    final response =
        await post('/api/v1/payments/quotations/$quotationId/send-email/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> sendQuotationSMS(int quotationId) async {
    final response =
        await post('/api/v1/payments/quotations/$quotationId/send-sms/');
    return response.data as Map<String, dynamic>;
  }

  // ==================== ADMIN ROLE ASSIGNMENT ====================

  static Future<Map<String, dynamic>> getAdminRoleAssignment() async {
    final response = await get('/api/v1/admin/role-assignment/');
    return response.data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getUsersByRole(int roleId) async {
    final response = await get(
      '/api/v1/profiles/',
      queryParameters: {'role_id': roleId},
    );
    final items = _extractList(response.data);
    return List<Map<String, dynamic>>.from(items);
  }

  // ==============================
  // FACILITATOR / INSTRUCTOR METHODS
  // ==============================

  // ==============================
  // CHAT METHODS
  // ==============================

  static Future<List<Map<String, dynamic>>> getChatRooms() async {
    final response = await get('/api/v1/chat/rooms/');
    final items = _extractList(response.data);
    return List<Map<String, dynamic>>.from(items);
  }

  static Future<List<Map<String, dynamic>>> getChatMessages(String roomId) async {
    final response = await get('/api/v1/chat/rooms/$roomId/messages/');
    final items = _extractList(response.data);
    return List<Map<String, dynamic>>.from(items);
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String content,
    String type = 'text',
    List<String> attachments = const [],
  }) async {
    final payload = {
      'content': content,
      'type': type,
      'attachments': attachments,
    };
    final response = await post('/api/v1/chat/rooms/$roomId/send/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getStaffMembers() async {
    // Alias for getStaffDirectory for ChatPage compatibility
    return getStaffDirectory();
  }

  static Future<Map<String, dynamic>> createDirectChat(int targetUserId) async {
    final response = await post('/api/v1/chat/rooms/create_direct/', data: {
      'target_user_id': targetUserId,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Fetch instructor dashboard data from backend
  static Future<Map<String, dynamic>> getInstructorDashboard() async {
    final response = await get('/api/v1/instructors/profiles/dashboard/');
    return response.data as Map<String, dynamic>;
  }

  /// Get all students enrolled in instructor's courses
  static Future<Map<String, dynamic>> getInstructorStudents() async {
    final response = await get('/api/v1/instructors/profiles/my_students/');
    return response.data as Map<String, dynamic>;
  }

  /// Get detailed course analytics for instructor
  static Future<Map<String, dynamic>> getInstructorCourseAnalytics() async {
    final response = await get('/api/v1/instructors/profiles/course_analytics/');
    return response.data as Map<String, dynamic>;
  }

  /// Get session logs and insights
  static Future<Map<String, dynamic>> getInstructorSessionInsights({
    String period = 'all',
  }) async {
    final response = await get(
      '/api/v1/instructors/profiles/session_insights/',
      queryParameters: {'period': period},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get instructor performance metrics
  static Future<Map<String, dynamic>> getInstructorPerformanceMetrics() async {
    final response = await get('/api/v1/instructors/profiles/performance_metrics/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMyInstructorProfile() async {
    final response = await get('/api/v1/instructors/profiles/me/');
    return response.data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>>
      getFacilitatorOvertimeRequests() async {
    // MOCKED: Backend support removed temporarily
    return [];
  }

  static Future<Map<String, dynamic>> createOvertimeRequest({
    required int assignmentId,
    required String date,
    required double hours,
    required String reason,
  }) async {
    // MOCKED: Backend support removed temporarily
    return {'status': 'submitted', 'message': 'Request logged (mock)'};
  }

  static Future<List<Map<String, dynamic>>> getFacilitatorEarnings() async {
    // MOCKED: Backend support removed temporarily
    return [];
  }

  static Future<Map<String, dynamic>> approveOvertime(int requestId,
      {String? notes}) async {
    // MOCKED
    return {'success': true};
  }

  static Future<Map<String, dynamic>> rejectOvertime(int requestId,
      {String? notes}) async {
    // MOCKED
    return {'success': true};
  }

  static Future<Map<String, dynamic>> toggleFacilitatorSuspension(
      int profileId) async {
    // MOCKED
    return {'success': true, 'is_suspended': false};
  }

  static Future<Map<String, dynamic>> updateFacilitatorRate(
      int profileId, double rate) async {
    // MOCKED
    return {'success': true, 'hourly_rate': rate};
  }

  // ==============================
  // LISTING METHODS
  // ==============================

  static Future<List<Masterclass>> getMasterclasses({
    String? streamType,
    String? tier,
    String? focusArea,
    double? minPrice,
    double? maxPrice,
  }) async {
    // Fetch ALL masterclasses by using large page_size
    // This avoids pagination issues in the frontend
    final query = <String, dynamic>{
      'page': 1,
      'page_size': 500, // Fetch all in one request
    };

    if (streamType != null) query['stream_type'] = streamType;
    if (tier != null) query['tier'] = tier;
    if (focusArea != null) query['focus_area'] = focusArea;
    if (minPrice != null) query['min_price'] = minPrice;
    if (maxPrice != null) query['max_price'] = maxPrice;

    final response =
        await get('/api/v1/courses/masterclasses/', queryParameters: query);
    final items = _extractList(response.data);
    final masterclasses = items.map((e) => Masterclass.fromJson(e)).toList();

    // Deduplicate by ID (in case of backend data issues)
    final seenIds = <dynamic>{};
    return masterclasses.where((m) {
      if (seenIds.contains(m.id)) return false;
      seenIds.add(m.id);
      return true;
    }).toList();
  }

  static Future<List<Course>> getIndustryTraining({
    String? industry,
    String? roleType,
    String? certificationLevel,
    String? country,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (industry != null) query['industry'] = industry;
    if (roleType != null) query['role_type'] = roleType;
    if (certificationLevel != null)
      query['certification_level'] = certificationLevel;
    if (country != null) query['country'] = country;

    final response = await get('/api/v1/industry-training/active-courses/',
        queryParameters: query);
    final items = _extractList(response.data);
    final courses = items.map((e) => Course.fromJson(e)).toList();
    
    // Deduplicate by course_id or id (in case of backend data issues)
    final seenIds = <String>{};
    return courses.where((c) {
      final uniqueId = c.externalId ?? c.id;
      if (seenIds.contains(uniqueId)) return false;
      seenIds.add(uniqueId);
      return true;
    }).toList();
  }

  static Future<List<Learnership>> getLearnerships({
    String? specialization,
    String? category,
    String? country,
    String? status,
    String? nqfLevel,
    String? deliveryMode,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (specialization != null) query['specialization'] = specialization;
    if (category != null) query['category'] = category;
    if (country != null) query['country'] = country;
    if (status != null) query['status'] = status;
    if (nqfLevel != null) query['nqf_level'] = nqfLevel;
    if (deliveryMode != null) query['delivery_mode'] = deliveryMode;

    final response =
        await get('/api/v1/learnerships/programmes/', queryParameters: query);
    final items = _extractList(response.data);
    final learnerships = items.map((e) => Learnership.fromJson(e)).toList();

    // Deduplicate by ID
    final seenIds = <dynamic>{};
    return learnerships.where((l) {
      if (seenIds.contains(l.id)) return false;
      seenIds.add(l.id);
      return true;
    }).toList();
  }

  /// Get cybersecurity learnerships from dedicated API endpoint
  static Future<List<Learnership>> getCybersecurityLearnerships() async {
    final response = await get('/api/v1/learnerships/programmes/cybersecurity/');
    final items = _extractList(response.data);
    return items.map((e) => Learnership.fromJson(e)).toList();
  }

  /// Get AI & Blockchain learnerships from dedicated API endpoint
  static Future<List<Learnership>> getAIBlockchainLearnerships() async {
    final response = await get('/api/v1/learnerships/programmes/ai-blockchain/');
    final items = _extractList(response.data);
    return items.map((e) => Learnership.fromJson(e)).toList();
  }

  // ==============================
  // STUDENT PROFILE METHODS
  // ==============================

  /// Check if the current user is an existing student with prior enrollments
  /// Returns student data to skip personal information collection
  static Future<Map<String, dynamic>> checkExistingStudent() async {
    final response =
        await get('/api/v1/student-portal/profile/check_existing_student/');
    return response.data as Map<String, dynamic>;
  }

  static Future<void> enrollUserInCourse({
    required String userId,
    required int courseId,
  }) async {
    final payload = {
      'user_id': userId,
      'course_id': courseId,
    };
    await post('/api/v1/enrollments/enroll/', data: payload);
  }

  static Future<Map<String, dynamic>> getFacilitatorMe() async {
    final response = await get('/api/v1/instructors/profiles/me/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> clockIn({
    required int profileId,
    required int assignmentId,
    String type = 'onsite',
    double? latitude,
    double? longitude,
  }) async {
    final payload = {
      'assignment_id': assignmentId,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
    };
    final response = await post(
      '/api/v1/instructors/profiles/$profileId/clock_in/',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> clockOut({
    required int profileId,
    String? justification,
  }) async {
    final payload = {'justification': justification};
    final response = await post(
      '/api/v1/instructors/profiles/$profileId/clock_out/',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getAttendanceLogs() async {
    final response = await get('/api/v1/instructors/attendance/');
    return List<Map<String, dynamic>>.from(_extractList(response.data));
  }

  static Future<Map<String, dynamic>> getExecutiveInsights() async {
    final response =
        await get('/api/v1/instructors/analytics/executive-insights/');
    return Map<String, dynamic>.from(response.data);
  }

  static List<dynamic> _extractList(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('results')) return body['results'] as List<dynamic>;
      if (body.containsKey('data')) return body['data'] as List<dynamic>;
      if (body.containsKey('countries'))
        return body['countries'] as List<dynamic>;
      if (body.containsKey('states')) return body['states'] as List<dynamic>;
      if (body.containsKey('cities')) return body['cities'] as List<dynamic>;
    }
    if (body is List<dynamic>) return body;
    return [];
  }

  static Future<List<Map<String, dynamic>>> getPublicInstructors() async {
    final response = await get(
      '/api/v1/instructors/profiles/public_list/',
      queryParameters: {'limit': 20, 'offset': 0},
    );
    final items = _extractList(response.data);
    return List<Map<String, dynamic>>.from(items);
  }

  // ==============================
  // BBB SESSION METHODS
  // ==============================

  /// Get course options for BBB session creation (with enrolled students)
  static Future<List<CourseOption>> getBBBCourseOptions() async {
    final response = await get('/api/v1/bbb/sessions/course_options/');
    final data = response.data as Map<String, dynamic>;
    
    final options = <CourseOption>[];
    
    // Parse learnerships
    final learnerships = data['learnerships'] as List<dynamic>? ?? [];
    for (final l in learnerships) {
      options.add(LearnershipOption.fromJson(l as Map<String, dynamic>));
    }
    
    // Parse masterclasses
    final masterclasses = data['masterclasses'] as List<dynamic>? ?? [];
    for (final m in masterclasses) {
      options.add(MasterclassOption.fromJson(m as Map<String, dynamic>));
    }
    
    // Parse AICERTS courses
    final courses = data['courses'] as List<dynamic>? ?? [];
    for (final c in courses) {
      options.add(AICertsOption.fromJson(c as Map<String, dynamic>));
    }
    
    return options;
  }

  /// Create a new BBB session
  static Future<Map<String, dynamic>> createBBBSession({
    required int courseId,
    required String courseType,
    required String title,
    String? description,
    required String scheduledStart,
    required String scheduledEnd,
    bool record = true,
    bool autoStartRecording = true,
    int maxParticipants = 100,
  }) async {
    final response = await post(
      '/api/v1/bbb/sessions/',
      data: {
        'course_id': courseId,
        'course_type': courseType,
        'title': title,
        'description': description,
        'scheduled_start': scheduledStart,
        'scheduled_end': scheduledEnd,
        'record': record,
        'auto_start_recording': autoStartRecording,
        'max_participants': maxParticipants,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Auto-invite enrolled students to a session
  static Future<void> autoInviteStudentsToSession(int sessionId) async {
    await post('/api/v1/bbb/sessions/$sessionId/auto_invite/');
  }

  /// Get instructor's BBB sessions from backend
  static Future<Map<String, dynamic>> getInstructorBBBSessions() async {
    final response = await get('/api/v1/bbb/sessions/my_sessions/');
    return response.data as Map<String, dynamic>;
  }

  /// Get student's BBB sessions from backend
  static Future<Map<String, dynamic>> getStudentBBBSessions() async {
    final response = await get('/api/v1/bbb/student/my_sessions/');
    return response.data as Map<String, dynamic>;
  }

  // ==============================
  // TEST USER METHODS
  // ==============================

  static Future<List<Map<String, dynamic>>> getTestUsers() async {
    try {
      final response = await get('/api/v1/users/test-users/');
      return List<Map<String, dynamic>>.from(_extractList(response.data));
    } catch (e) {
      // Return empty list if endpoint not implemented yet
      return [];
    }
  }

  static Future<Map<String, dynamic>> createTestStudent({
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final payload = {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': 'learner',
    };
    final response =
        await post('/api/v1/users/test-users/hosi-student/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createTestInstructor({
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final payload = {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': 'instructor',
    };
    final response =
        await post('/api/v1/users/test-users/hosi-instructor/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deleteTestUser(String email) async {
    try {
      await _dio.delete(
        '/api/v1/users/test-users/',
        queryParameters: {'email': email},
      );
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // ==============================
  // STUDENT PORTAL METHODS
  // ==============================

  static Future<Map<String, dynamic>> getContentTypes() async {
    final response = await get('/api/v1/student-portal/content-types/');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getStudentProfile() async {
    final response = await get('/api/v1/student-portal/profile/me/');
    return response.data as Map<String, dynamic>;
  }

  static Future<void> updateStudentProfile(Map<String, dynamic> data) async {
    try {
      await post('/api/v1/student-portal/profile/update/', data: data);
    } catch (_) {
      // Profile update is best-effort — never block enrollment flow
    }
  }

  // --- Wishlist ---

  static Future<List<dynamic>> getWishlist({String? trainingType}) async {
    final query = <String, dynamic>{};
    if (trainingType != null) query['type'] = trainingType;

    final response =
        await get('/api/v1/student-portal/wishlist/', queryParameters: query);
    return _extractList(response.data);
  }

  static Future<Map<String, dynamic>> addToWishlist({
    required int contentTypeId,
    required int objectId,
    required String trainingType,
    String? notes,
  }) async {
    // Note: The backend view logic for 'add_to_wishlist' is on the catalog item viewset,
    // but the serializers expect a straight POST to wishlist endpoint or a detail action.
    // Let's use the catalog action if possible, or standard POST.
    // Based on backend code:
    // CourseCatalogViewSet has an action `add_to_wishlist` on detail route.
    // BUT we need the ID of the catalog item.
    // Alternatively, WishlistViewSet has a standard create. Let's use standard create.

    final payload = {
      'content_type': contentTypeId,
      'object_id': objectId,
      'training_type': trainingType,
      if (notes != null) 'notes': notes,
    };

    // Using standard POST to wishlist endpoint
    // Check if backend supports raw create on WishlistViewSet (it seems so, serializer has fields)
    // Wait, WishlistSerializer has read_only fields for content_type/object_id in Meta? No.
    // Let's try standard POST. If fails, we might need to use catalog endpoint.

    final response =
        await post('/api/v1/student-portal/wishlist/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> removeFromWishlist(int wishlistId) async {
    await _dio.delete('/api/v1/student-portal/wishlist/$wishlistId/');
  }

  static Future<Map<String, dynamic>> moveWishlistItemToCart(
      int wishlistId) async {
    final response = await post(
        '/api/v1/student-portal/wishlist/$wishlistId/move_to_cart/',
        data: {});
    return response.data as Map<String, dynamic>;
  }

  // --- Cart ---

  static Future<Map<String, dynamic>> getActiveCart() async {
    final response = await get('/api/v1/student-portal/cart/active/');
    return response.data as Map<String, dynamic>;
  }

  // ==============================
  // MARKETING ASSET METHODS
  // ==============================

  static Future<List<Map<String, dynamic>>> getMarketingAssets() async {
    final response = await get('/api/v1/marketing/assets/');
    final items = _extractList(response.data);
    return List<Map<String, dynamic>>.from(items);
  }

  static Future<Map<String, dynamic>> uploadMarketingAsset({
    required String title,
    required String description,
    required String assetType,
    required Uint8List fileBytes,
    required String fileName,
    String? suggestedCaption,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      'asset_type': assetType,
      'suggested_caption': suggestedCaption ?? '',
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    final response = await post('/api/v1/marketing/assets/', data: formData);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deleteMarketingAsset(int id) async {
    await delete('/api/v1/marketing/assets/$id/');
  }

  static Future<void> logAssetShare({
    required int assetId,
    required String platform,
    required String referralLink,
  }) async {
    await post('/api/v1/marketing/assets/$assetId/log-share/', data: {
      'platform': platform,
      'referral_link': referralLink,
    });
  }

  static Future<Map<String, dynamic>> addToCart({
    required int cartId,
    required int contentTypeId,
    required int objectId,
    required String trainingType,
    bool fromWishlist = false,
  }) async {
    final payload = {
      'content_type_id': contentTypeId,
      'object_id': objectId,
      'training_type': trainingType,
      'from_wishlist': fromWishlist,
    };

    final response = await post('/api/v1/student-portal/cart/$cartId/add_item/',
        data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> removeFromCart(int cartId, int itemId) async {
    await _dio.delete(
      '/api/v1/student-portal/cart/$cartId/remove_item/',
      data: {
        'item_id': itemId
      }, // Using delete with body as per view implementation
    );
  }

  static Future<void> clearCart(int cartId) async {
    await post('/api/v1/student-portal/cart/$cartId/clear/', data: {});
  }

  static Future<Map<String, dynamic>> checkoutCart({
    required int cartId,
    bool usePreviousDetails = false,
    bool isCorporate = false,
  }) async {
    final payload = {
      'use_previous_company_details': usePreviousDetails,
      'is_corporate_enrollment': isCorporate,
    };

    final response = await post('/api/v1/student-portal/cart/$cartId/checkout/',
        data: payload);
    return response.data as Map<String, dynamic>;
  }

  // ==============================
  // AFRICAN BANKS & PAYMENT METHODS
  // ==============================

  /// Get African banks for a specific country
  static Future<List<Map<String, dynamic>>> getAfricanBanks({
    required String countryCode,
    String? category,
    String? type,
    bool recommendedOnly = false,
  }) async {
    try {
      final response = await get('/api/v1/payments/african-banks/', 
        queryParameters: {
          'country': countryCode,
          if (category != null) 'category': category,
          if (type != null) 'type': type,
          'recommended': recommendedOnly.toString(),
        }
      );
      return List<Map<String, dynamic>>.from(response.data['banks'] ?? []);
    } catch (e) {
      print('Error fetching African banks: $e');
      return [];
    }
  }

  /// Get African payment providers for a specific country
  static Future<List<Map<String, dynamic>>> getAfricanPaymentProviders({
    required String countryCode,
    String? category,
    bool recommendedOnly = false,
  }) async {
    try {
      final response = await get('/api/v1/payments/african-banks/', 
        queryParameters: {
          'country': countryCode,
          if (category != null) 'category': category,
          'type': 'payment_provider',
          'recommended': recommendedOnly.toString(),
        }
      );
      return List<Map<String, dynamic>>.from(response.data['payment_providers'] ?? []);
    } catch (e) {
      print('Error fetching African payment providers: $e');
      return [];
    }
  }

  /// Get all African countries with banks
  static Future<List<Map<String, dynamic>>> getAfricanCountriesWithBanks() async {
    try {
      final response = await get('/api/v1/payments/african-countries/');
      return List<Map<String, dynamic>>.from(response.data['countries'] ?? []);
    } catch (e) {
      print('Error fetching African countries: $e');
      return [];
    }
  }

  // ========== PAYMENT OTP VERIFICATION ==========

  /// Send OTP to email for payment verification
  static Future<Map<String, dynamic>> sendPaymentOTP({
    required String email,
    required double amount,
    required String currency,
    required String country,
  }) async {
    final payload = {
      'email': email,
      'amount': amount,
      'currency': currency,
      'country': country,
    };
    final response = await post('/api/v1/payments/send-otp/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  /// Verify OTP for payment
  static Future<Map<String, dynamic>> verifyPaymentOTP({
    required String email,
    required String otp,
  }) async {
    final payload = {
      'email': email,
      'otp': otp,
    };
    final response = await post('/api/v1/payments/verify-otp/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  /// Resend OTP
  static Future<Map<String, dynamic>> resendPaymentOTP({
    required String email,
  }) async {
    final payload = {'email': email};
    final response = await post('/api/v1/payments/resend-otp/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  // ========== LOGIN OTP ==========

  static Future<Map<String, dynamic>> sendLoginOTP({
    required String email,
  }) async {
    final payload = {'identifier': email};
    final response = await post('/api/v1/auth/otp/send/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> loginWithOTP({
    required String email,
    required String otp,
  }) async {
    final payload = {'identifier': email, 'otp': otp};
    final response = await post('/api/v1/auth/otp/login/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  // ========== CONTACT VERIFICATION OTP (enrollment forms) ==========

  /// Send OTP to an email address or phone number for contact verification.
  /// [contactType] must be 'email' or 'phone'.
  static Future<Map<String, dynamic>> sendContactOTP({
    required String contact,
    required String contactType,
  }) async {
    final response = await post('/api/v1/payments/contact-otp/send/', data: {
      'contact': contact,
      'contact_type': contactType,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Verify the OTP code the user entered for a contact.
  static Future<Map<String, dynamic>> verifyContactOTP({
    required String contact,
    required String contactType,
    required String otp,
  }) async {
    final response = await post('/api/v1/payments/contact-otp/verify/', data: {
      'contact': contact,
      'contact_type': contactType,
      'otp': otp,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Resend a contact OTP (subject to 2-minute cooldown).
  static Future<Map<String, dynamic>> resendContactOTP({
    required String contact,
    required String contactType,
  }) async {
    final response = await post('/api/v1/payments/contact-otp/resend/', data: {
      'contact': contact,
      'contact_type': contactType,
    });
    return response.data as Map<String, dynamic>;
  }

}

