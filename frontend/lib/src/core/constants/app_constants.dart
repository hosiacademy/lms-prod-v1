// lib/src/core/constants/app_constants.dart

// ENVIRONMENT FIX: Import environment configuration
import '../config/environment.dart';

class AppConstants {
  // ── API Configuration ───────────────────────────────────────────────────────
  // ENVIRONMENT FIX: Use Environment.apiBaseUrl instead of hardcoded URL
  // Automatically handles dev/staging/prod environments
  static String get apiBaseUrl => '${Environment.apiBaseUrl}/api/v1';

  static Duration get apiTimeout => Duration(seconds: Environment.apiTimeout);
  static const int maxUploadSizeMB = 50;

  // ── Debug & Development Flags ───────────────────────────────────────────────
  static const bool isDebug = true; // Set to false in release builds

  // ── App Metadata ────────────────────────────────────────────────────────────
  static const String appName = 'AfroLearn';
  static const String appVersion = '1.0.0';

  // ── Shared Preferences Keys ─────────────────────────────────────────────────
  static const String prefDarkMode = 'user_dark_mode_preference';
  static const String prefAuthToken = 'auth_access_token';
  static const String prefRefreshToken = 'auth_refresh_token';
  static const String prefFirstLaunch = 'first_launch';
  static const String prefUserCountryCode =
      'user_country_code'; // For future localization

  // ── Backend Endpoints ───────────────────────────────────────────────────────
  // Theme & Appearance (from frontend_manage)
  static const String endpointFrontendConfig = '/frontend/config/';
  static const String endpointCurrentTheme =
      '/frontend/theme/'; // Current appearance
  static const String endpointAppAppearance =
      '/frontend/appearance/'; // Full appearance details

  // Themes/Templates (installed/custom themes)
  static const String endpointThemes = '/frontend/themes/';
  static const String endpointActiveTheme = '/frontend/themes/active/';

  // Localization & Country-specific (from localization app)
  static const String endpointLanguages = '/localization/languages/';
  static const String endpointCountryOverrides =
      '/localization/country-overrides/'; // Future: holidays, greetings, colors per country

  // Other useful endpoints (add more as your backend grows)
  static const String endpointUserProfile = '/users/profile/';
  static const String endpointNotifications = '/notifications/';
}
