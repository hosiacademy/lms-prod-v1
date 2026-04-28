// lib/src/core/config/aicerts_config.dart

/// AICERTS Integration Configuration
///
/// Stores partner credentials and configuration for AICERTS API integration
///
/// **Setup**:
/// 1. Get credentials from AICERTS team (partner_id, ws_token, secret_key)
/// 2. Add to environment variables or config file
/// 3. Use AICERTSConfig throughout the app
///
/// **Environment Variables** (for production):
/// ```bash
/// flutter build apk --dart-define=AICERTS_PARTNER_ID=262 \
///                   --dart-define=AICERTS_WS_TOKEN=your_token \
///                   --dart-define=AICERTS_SECRET_KEY=your_secret
/// ```
class AICERTSConfig {
  /// Partner ID assigned by AICERTS
  /// Default: 262 (HOSI Technologies Africa)
  static const String partnerId = String.fromEnvironment(
    'AICERTS_PARTNER_ID',
    defaultValue: '262',
  );

  /// Web Service Token for API authentication
  /// Get this from AICERTS team
  static const String wsToken = String.fromEnvironment(
    'AICERTS_WS_TOKEN',
    defaultValue: '', // Contact AICERTS for production token
  );

  /// Secret Key for HMAC signature generation
  /// Get this from AICERTS team
  static const String secretKey = String.fromEnvironment(
    'AICERTS_SECRET_KEY',
    defaultValue: '', // Contact AICERTS for production secret
  );

  /// AICERTS LMS Base URL
  static const String lmsUrl = String.fromEnvironment(
    'AICERTS_LMS_URL',
    defaultValue: 'https://learn.aicerts.io',
  );

  /// AICERTS API Base URL
  static const String apiUrl = String.fromEnvironment(
    'AICERTS_API_URL',
    defaultValue: 'https://www.aicerts.ai/wp-json/aicerts-api/v1',
  );

  /// Check if AICERTS credentials are configured
  static bool get isConfigured {
    return wsToken.isNotEmpty && secretKey.isNotEmpty;
  }

  /// Print configuration status (for debugging)
  static void printConfig() {
    print('=== AICERTS Configuration ===');
    print('Partner ID: $partnerId');
    print('WS Token: ${wsToken.isNotEmpty ? '✓ Set (${wsToken.length} chars)' : '✗ Not set'}');
    print('Secret Key: ${secretKey.isNotEmpty ? '✓ Set (${secretKey.length} chars)' : '✗ Not set'}');
    print('LMS URL: $lmsUrl');
    print('API URL: $apiUrl');
    print('Configured: ${isConfigured ? '✓ YES' : '✗ NO'}');
    print('=============================');
  }

  /// Validate configuration
  static String? validateConfig() {
    if (wsToken.isEmpty) {
      return 'AICERTS WS Token not configured. '
          'Contact AICERTS team for credentials.';
    }
    if (secretKey.isEmpty) {
      return 'AICERTS Secret Key not configured. '
          'Contact AICERTS team for credentials.';
    }
    return null; // All good
  }
}

/// AICERTS Configuration Instructions for Deployment
///
/// **Development**:
/// 1. Get credentials from AICERTS team
/// 2. Create `.env` file in project root:
///    ```
///    AICERTS_PARTNER_ID=262
///    AICERTS_WS_TOKEN=your_token_here
///    AICERTS_SECRET_KEY=your_secret_key_here
///    ```
/// 3. Run: `flutter run --dart-define-from-file=.env`
///
/// **Staging**:
/// ```bash
/// flutter build apk \
///   --dart-define=ENV=staging \
///   --dart-define=AICERTS_PARTNER_ID=262 \
///   --dart-define=AICERTS_WS_TOKEN=staging_token \
///   --dart-define=AICERTS_SECRET_KEY=staging_secret
/// ```
///
/// **Production**:
/// ```bash
/// flutter build apk --release \
///   --dart-define=ENV=production \
///   --dart-define=AICERTS_PARTNER_ID=262 \
///   --dart-define=AICERTS_WS_TOKEN=prod_token \
///   --dart-define=AICERTS_SECRET_KEY=prod_secret
/// ```
///
/// **CI/CD** (GitHub Actions, GitLab CI):
/// Store credentials as repository secrets and pass via --dart-define:
/// ```yaml
/// - name: Build APK
///   run: |
///     flutter build apk --release \
///       --dart-define=AICERTS_PARTNER_ID=${{ secrets.AICERTS_PARTNER_ID }} \
///       --dart-define=AICERTS_WS_TOKEN=${{ secrets.AICERTS_WS_TOKEN }} \
///       --dart-define=AICERTS_SECRET_KEY=${{ secrets.AICERTS_SECRET_KEY }}
/// ```
///
/// **Testing Credentials**:
/// For local testing without real credentials:
/// 1. Use mock/test mode (see AICERTSCourseViewer)
/// 2. Contact AICERTS for sandbox credentials
/// 3. Never commit actual credentials to version control
