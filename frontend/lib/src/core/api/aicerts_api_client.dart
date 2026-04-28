// lib/src/core/api/aicerts_api_client.dart

import 'package:dio/dio.dart';
import '../config/environment.dart';

/// AICERTS External API Client
/// Handles direct integration with AICERTS API endpoints
///
/// **CORS Note**: This client calls AICERTS API endpoints directly.
/// AICERTS team must configure CORS headers to allow requests from:
/// - Production: https://hosi.africa
/// - Staging: https://staging.hosi.africa
/// - Development: http://localhost:* (for testing)
class AICERTSApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://www.aicerts.ai/wp-json/aicerts-api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Get all available AICERTS courses
  /// Endpoint: GET https://www.aicerts.ai/wp-json/aicerts-api/v1/courses
  static Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      final response = await _dio.get('/courses');

      if (response.statusCode == 200) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }

      throw Exception('Failed to fetch AICERTS courses');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('AICERTS API timeout - please check connectivity');
      } else if (e.response?.statusCode == 403 ||
          e.error.toString().contains('CORS')) {
        throw Exception(
            'CORS ERROR: AICERTS server must add CORS headers to allow '
            '${Environment.frontendBaseUrl} domain. Contact AICERTS support.');
      }
      throw Exception('AICERTS API error: ${e.message}');
    }
  }

  /// Create a test student account in AICERTS LMS
  /// This calls AICERTS API endpoint to provision a test learner
  ///
  /// **Usage**: For testing enrolled student functionality
  /// **Response**: Returns student credentials and LMS access URL
  static Future<Map<String, dynamic>> createTestStudent({
    required String email,
    required String firstName,
    required String lastName,
    String? courseId,
  }) async {
    try {
      final response = await _dio.post(
        '/test-users/student',
        data: {
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'course_id': courseId,
          'source': 'hosi_africa',
          'environment': Environment.environment,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to create test student');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception(
            'AICERTS API endpoint not found. Please ask AICERTS team to implement:\n'
            'POST /wp-json/aicerts-api/v1/test-users/student');
      } else if (e.error.toString().contains('CORS')) {
        throw Exception(
            'CORS ERROR: AICERTS must enable CORS for ${Environment.frontendBaseUrl}');
      }
      throw Exception('Failed to create test student: ${e.message}');
    }
  }

  /// Create a test instructor account in AICERTS LMS
  /// This calls AICERTS API endpoint to provision a test instructor
  ///
  /// **Usage**: For testing instructor functionality
  /// **Response**: Returns instructor credentials and LMS admin access URL
  static Future<Map<String, dynamic>> createTestInstructor({
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post(
        '/test-users/instructor',
        data: {
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'source': 'hosi_africa',
          'environment': Environment.environment,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to create test instructor');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception(
            'AICERTS API endpoint not found. Please ask AICERTS team to implement:\n'
            'POST /wp-json/aicerts-api/v1/test-users/instructor');
      } else if (e.error.toString().contains('CORS')) {
        throw Exception(
            'CORS ERROR: AICERTS must enable CORS for ${Environment.frontendBaseUrl}');
      }
      throw Exception('Failed to create test instructor: ${e.message}');
    }
  }

  /// Get test user credentials
  /// Retrieves existing test account information from AICERTS
  ///
  /// **Parameters**:
  /// - userType: 'student' or 'instructor'
  /// - email: Test user email
  static Future<Map<String, dynamic>> getTestUserCredentials({
    required String userType,
    required String email,
  }) async {
    try {
      final response = await _dio.get(
        '/test-users/$userType',
        queryParameters: {'email': email},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Test user not found');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception(
            'Test user not found. Create one first using create methods.');
      }
      throw Exception('Failed to get test user: ${e.message}');
    }
  }

  /// Download course badge image (with CORS handling)
  ///
  /// **CORS Workaround**: Downloads image through proxy or returns local fallback
  /// **Note**: If CORS is not configured, this will fail
  static Future<List<int>?> downloadCourseBadge(String badgeUrl) async {
    try {
      final response = await _dio.get(
        badgeUrl,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        return response.data as List<int>;
      }

      return null;
    } on DioException catch (e) {
      if (e.error.toString().contains('CORS')) {
        print('⚠️ CORS ERROR: Cannot download image from $badgeUrl');
        print('   AICERTS must add Access-Control-Allow-Origin header');
        return null;
      }
      print('⚠️ Failed to download badge: ${e.message}');
      return null;
    }
  }

  /// Health check for AICERTS API
  /// Tests if AICERTS API is reachable and CORS is configured
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      await _dio.get('/courses', queryParameters: {'limit': 1});

      return {
        'status': 'healthy',
        'cors_enabled': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } on DioException catch (e) {
      return {
        'status': 'unhealthy',
        'cors_enabled': !e.error.toString().contains('CORS'),
        'error': e.message,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
