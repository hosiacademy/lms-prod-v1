/// Environment Configuration Service
///
/// Provides centralized configuration for API URLs, Socket.IO endpoints,
/// AICERTS Moodle REST API, and other environment-specific settings.
///
/// Usage:
/// ```dart
/// final apiUrl = Environment.apiBaseUrl;
/// final aicertsUrl = Environment.aicertsBaseUrl;
/// final wsToken = Environment.aicertsWsToken;
/// ```
///
/// Configuration Priority:
/// 1. Environment variables (via --dart-define)
/// 2. Default values (for development)

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

class Environment {
  // Private constructor to prevent instantiation
  Environment._();

  /// Current environment mode
  static const String _environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// Is production environment
  static bool get isProduction => _environment == 'production';

  /// Is development environment
  static bool get isDevelopment => _environment == 'development';

  /// Is staging environment
  static bool get isStaging => _environment == 'staging';

  /// Get current environment as string
  static String get environment => _environment;

  // ========== API Configuration (your main backend) ==========

  /// Base API URL for your own backend (without trailing slash).
  /// Cached after first access so the origin lookup + log runs once only.
  static String? _cachedApiBaseUrl;
  
  static String get apiBaseUrl {
    if (_cachedApiBaseUrl != null) return _cachedApiBaseUrl!;

    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      _cachedApiBaseUrl = envUrl;
      print('🌐 API URL (from env): $_cachedApiBaseUrl');
      return _cachedApiBaseUrl!;
    }

    // On web, backend is served from the same origin via nginx proxy
    try {
      final origin = html.window.location.origin;
      if (origin.isNotEmpty) {
        // UNIVERSAL FIX: If on port 7000 (frontend), use port 7001 for API
        if (origin.contains(':7000')) {
          _cachedApiBaseUrl = origin.replaceFirst(':7000', ':7001');
          print('🌐 API URL (auto-corrected from port 7000 to 7001): $_cachedApiBaseUrl');
          return _cachedApiBaseUrl!;
        }
        
        // Handle localhost development
        if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
          _cachedApiBaseUrl = 'http://localhost:7001';
          print('🌐 API URL (localhost): $_cachedApiBaseUrl');
          return _cachedApiBaseUrl!;
        }

        // Production: use origin as-is (will work on any domain with proper nginx proxy)
        print('🌐 API URL (from origin): $origin');
        _cachedApiBaseUrl = origin;
        return _cachedApiBaseUrl!;
      }
    } catch (e) {
      print('❌ Failed to get window.location.origin: $e');
    }

    // Fallback values
    if (isProduction) {
      _cachedApiBaseUrl = 'https://hosiacademy.africa';
    } else if (isStaging) {
      _cachedApiBaseUrl = 'https://staging.hosiacademy.africa';
    } else {
      _cachedApiBaseUrl = 'http://localhost:7001';
    }
    print('🌐 API URL (fallback): $_cachedApiBaseUrl');
    return _cachedApiBaseUrl!;
  }

  /// API timeout in seconds
  static int get apiTimeout {
    const envTimeout = String.fromEnvironment('API_TIMEOUT');
    return envTimeout.isNotEmpty ? int.tryParse(envTimeout) ?? 60 : 60;
  }

  // ========== AICERTS Moodle REST API Configuration ==========

  /// NEW: Base URL for AICERTS Moodle REST API
  /// Used for core_user_create_users, enrol_manual_enrol_users, etc.
  static String get aicertsBaseUrl {
    const envUrl = String.fromEnvironment('AICERTS_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // Production (real AICERTS instance)
    if (isProduction) {
      return 'https://learn.aicerts.ai/webservice/rest';
    }
    // Staging / Test instance (if you have one)
    if (isStaging) {
      return 'https://staging-learn.aicerts.ai/webservice/rest';
    }
    // Local/development fallback (use mock or real test instance)
    return 'https://learn.aicerts.ai/webservice/rest';
  }

  /// NEW: AICERTS Web Service Token (required for all authenticated calls)
  /// This is wstoken in the API docs
  static String get aicertsWsToken {
    const token = String.fromEnvironment('AICERTS_WS_TOKEN');
    if (token.isEmpty) {
      // In development you can use a test token or mock
      // Never commit real tokens!
      return 'your_test_token_here_replace_with_real_one';
    }
    return token;
  }

  /// NEW: Partner ID (used in create user and enrol calls)
  /// Appears as partner_id in AICERTS API requests
  static int get aicertsPartnerId {
    const partnerStr = String.fromEnvironment('AICERTS_PARTNER_ID');
    return partnerStr.isNotEmpty ? int.tryParse(partnerStr) ?? 1 : 1;
  }

  /// NEW: AICERTS create user endpoint path (relative)
  static String get aicertsUserCreatePath => 'server.php';

  /// NEW: AICERTS enrol user endpoint path (relative)
  static String get aicertsEnrolPath => 'server.php';

  // ========== Socket.IO Configuration ==========

  static String get socketUrl {
    const envUrl = String.fromEnvironment('SOCKET_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // On web, socket.io is proxied through the same origin via nginx
    // This ensures WebSocket connections use the same protocol as the frontend
    try {
      final origin = html.window.location.origin;
      if (origin.isNotEmpty) {
        // UNIVERSAL FIX: If on port 7000 (frontend), use port 7002 for Socket.IO
        if (origin.contains(':7000')) {
          final corrected = origin.replaceFirst(':7000', ':7002');
          print('🔌 Socket URL (auto-corrected): $corrected');
          return corrected;
        }
        
        // Handle localhost
        if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
          print('🔌 Socket URL (localhost): http://localhost:7002');
          return 'http://localhost:7002';
        }
        
        print('🔌 Socket URL (from origin): $origin');
        return origin;
      }
    } catch (e) {
      print('❌ Failed to get window.location.origin for Socket: $e');
    }

    // Fallback based on environment
    if (isProduction) {
      print('🔌 Socket URL (production fallback): https://hosiacademy.africa');
      return 'https://hosiacademy.africa';
    } else if (isStaging) {
      print('🔌 Socket URL (staging fallback): https://staging.hosiacademy.africa');
      return 'https://staging.hosiacademy.africa';
    }

    // Development fallback
    print('🔌 Socket URL (development fallback): http://localhost:7002');
    return 'http://localhost:7002';
  }

  static int get socketTimeout {
    const envTimeout = String.fromEnvironment('SOCKET_TIMEOUT');
    return envTimeout.isNotEmpty ? int.tryParse(envTimeout) ?? 5000 : 5000;
  }

  static bool get socketReconnection {
    const envReconnection = String.fromEnvironment('SOCKET_RECONNECTION');
    return envReconnection.isNotEmpty
        ? envReconnection == 'true'
        : (isProduction || isStaging);
  }

  static bool get socketEnabled {
    const envEnabled = String.fromEnvironment('SOCKET_ENABLED');
    return envEnabled.isNotEmpty ? envEnabled == 'true' : true;
  }

  // ========== Frontend Configuration ==========

  static String get frontendBaseUrl {
    const envUrl = String.fromEnvironment('FRONTEND_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (isProduction) {
      return 'https://hosiacademy.africa';
    } else if (isStaging) {
      return 'https://staging.hosiacademy.africa';
    } else {
      return 'http://localhost:7000';
    }
  }

  // ========== Feature Flags ==========

  static bool get enableDebugLogs {
    const envDebug = String.fromEnvironment('DEBUG_LOGS');
    return envDebug.isNotEmpty ? envDebug == 'true' : isDevelopment;
  }

  static bool get enableAnalytics {
    const envAnalytics = String.fromEnvironment('ENABLE_ANALYTICS');
    return envAnalytics.isNotEmpty ? envAnalytics == 'true' : isProduction;
  }

  static bool get enableCrashReporting {
    const envCrash = String.fromEnvironment('ENABLE_CRASH_REPORTING');
    return envCrash.isNotEmpty ? envCrash == 'true' : isProduction;
  }



  // ========== App Metadata ==========

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static const String buildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: '1',
  );

  // ========== Helper Methods ==========

  static String getApiUrl(String path) {
    final cleanPath = path.startsWith('/') ? path : '/';
    return '$apiBaseUrl$cleanPath';
  }

  static String getAicertsUrl(String function,
      {Map<String, dynamic>? extraParams}) {
    final params = <String, dynamic>{
      'wstoken': aicertsWsToken,
      'wsfunction': function,
      'moodlewsrestformat': 'json',
    };

    if (extraParams != null) {
      params.addAll(extraParams);
    }

    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$aicertsBaseUrl?$query';
  }

  static void printConfig() {
    if (!enableDebugLogs) return;

    print('===========================================');
    print('Environment Configuration');
    print('===========================================');
    print('Environment:          $environment');
    print('API Base URL:         $apiBaseUrl');
    print('AICERTS Base URL:     $aicertsBaseUrl');
    print('AICERTS WS Token:     ... (hidden)');
    print('AICERTS Partner ID:   $aicertsPartnerId');
    print('Socket URL:           $socketUrl');
    print('Frontend URL:         $frontendBaseUrl');
    print('API Timeout:          ${apiTimeout}s');
    print('Socket Timeout:       ${socketTimeout}ms');
    print('Debug Logs:           $enableDebugLogs');
    print('App Version:          $appVersion ($buildNumber)');
    print('===========================================');
  }
}

/// Extension for easy URL building
extension EnvironmentUrlBuilder on String {
  String get toApiUrl => Environment.getApiUrl(this);
  String get toAicertsUrl => Environment.getAicertsUrl(this);
}