// lib/src/core/services/bbb_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/bbb_config.dart';

/// Service for BigBlueButton (BBB) integration
/// Handles authentication and session management using credentials from environment
class BBBService {
  // Use configuration from BBBConfig
  static String get _bbbApiUrl => BBBConfig.apiUrl;
  static String get _bbbSecret => BBBConfig.apiSecret;
  static String get _bbbEmail => BBBConfig.email;
  static String get _bbbPassword => BBBConfig.password;

  /// Get BBB API URL
  static String get apiUrl => _bbbApiUrl;

  /// Get BBB credentials for authentication
  static Map<String, String> getCredentials() {
    return {
      'email': _bbbEmail,
      'password': _bbbPassword,
    };
  }

  /// Generate join URL for instructor
  /// This creates a signed BBB join URL with proper authentication
  static String generateInstructorJoinUrl({
    required String meetingId,
    required String userName,
    required String moderatorPassword,
  }) {
    final params = {
      'meetingID': meetingId,
      'fullName': userName,
      'password': moderatorPassword,
      'redirect': 'true',
    };

    final queryString = _buildQueryString(params);
    final checksum = _generateChecksum('join', queryString);

    return '$_bbbApiUrl/join?$queryString&checksum=$checksum';
  }

  /// Generate BBB instructor portal URL
  /// This returns the main BBB portal URL for instructors
  static String generateInstructorPortalUrl({String? userName}) {
    final name = userName ?? 'Instructor';
    // For demo/development, we'll use a mock meeting ID
    // In production, this should come from the backend API
    final meetingId = 'instructor-portal-${DateTime.now().millisecondsSinceEpoch}';
    final moderatorPassword = 'mod-${DateTime.now().millisecondsSinceEpoch}';

    return generateInstructorJoinUrl(
      meetingId: meetingId,
      userName: name,
      moderatorPassword: moderatorPassword,
    );
  }

  /// Generate join URL for student/learner
  /// This creates a signed BBB join URL with attendee privileges
  static String generateStudentJoinUrl({
    required String sessionId,
    required String userName,
    String? attendeePassword,
  }) {
    final password = attendeePassword ?? 'attendee-${DateTime.now().millisecondsSinceEpoch}';

    final params = {
      'meetingID': sessionId,
      'fullName': userName,
      'password': password,
      'redirect': 'true',
    };

    final queryString = _buildQueryString(params);
    final checksum = _generateChecksum('join', queryString);

    return '$_bbbApiUrl/join?$queryString&checksum=$checksum';
  }

  /// Build query string from parameters
  static String _buildQueryString(Map<String, String> params) {
    final sortedKeys = params.keys.toList()..sort();
    return sortedKeys
        .map((key) => '$key=${Uri.encodeComponent(params[key]!)}')
        .join('&');
  }

  /// Generate checksum for BBB API call
  static String _generateChecksum(String apiCall, String queryString) {
    final data = '$apiCall$queryString$_bbbSecret';
    final bytes = utf8.encode(data);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Get BBB base URL (without API path)
  static String get baseUrl => BBBConfig.baseUrl;

  /// Check if BBB is enabled
  static bool get isEnabled => BBBConfig.enabled;

  /// Get maximum participants allowed
  static int get maxParticipants => BBBConfig.maxParticipants;

  /// Check if recording is enabled by default
  static bool get recordByDefault => BBBConfig.recordByDefault;
}
