// lib/src/core/config/bbb_config.dart
/// BigBlueButton configuration
/// Reads from environment variables or uses defaults
class BBBConfig {
  // BBB API URL - defaults to production URL
  static const String apiUrl = String.fromEnvironment(
    'BBB_API_URL',
    defaultValue: 'https://bbb.hosi.academy/bigbluebutton/api/',
  );

  // BBB API Secret Key
  static const String apiSecret = String.fromEnvironment(
    'BBB_SECRET',
    defaultValue: '',
  );

  // BBB Instructor Email Credential
  static const String email = String.fromEnvironment(
    'BBB_EMAIL',
    defaultValue: '',
  );

  // BBB Instructor Password Credential
  static const String password = String.fromEnvironment(
    'BBB_PASSWORD',
    defaultValue: '',
  );

  // BBB Enabled Flag
  static const String enabledStr = String.fromEnvironment(
    'BBB_ENABLED',
    defaultValue: 'true',
  );
  static bool get enabled => enabledStr.toLowerCase() == 'true';

  // Max Participants
  static const String maxParticipantsStr = String.fromEnvironment(
    'BBB_MAX_PARTICIPANTS',
    defaultValue: '100',
  );
  static int get maxParticipants => int.tryParse(maxParticipantsStr) ?? 100;

  // Record by Default
  static const String recordStr = String.fromEnvironment(
    'BBB_RECORD_BY_DEFAULT',
    defaultValue: 'true',
  );
  static bool get recordByDefault => recordStr.toLowerCase() == 'true';

  // Get base URL (without /api/ path)
  static String get baseUrl {
    return apiUrl.replaceAll('/bigbluebutton/api/', '');
  }

  // Get credentials as a map
  static Map<String, String> get credentials {
    return {
      'email': email,
      'password': password,
    };
  }

  /// Get full BBB portal URL
  static String getPortalUrl() {
    return baseUrl;
  }

  /// Get BBB login URL with credentials pre-filled
  static String getLoginUrl() {
    // For demo purposes, return the base portal URL
    // In production, this would include proper authentication
    return '$baseUrl/';
  }
}
