// payment_config.dart
// CLEANED-UP PAYMENT CONFIGURATION (10 adapters - down from 28)
// Aligned with backend adapter cleanup - March 16, 2026

// ENVIRONMENT FIX: Import environment configuration
import 'environment.dart';

class PaymentConfig {
  // ENVIRONMENT FIX: Use Environment configuration for base URL
  static String get baseUrl => '${Environment.apiBaseUrl}/api';

  // ENVIRONMENT FIX: Use Environment.isProduction
  static bool get isProduction => Environment.isProduction;

  // ==========================================
  // ACTIVE PAYMENT PROVIDERS
  // ==========================================
  
  // SmatPay - Primary global gateway (Visa, Mastercard, ZimSwitch)
  static const String smatpayMerchantId = String.fromEnvironment(
    'SMATPAY_MERCHANT_ID',
    defaultValue: '',
  );

  static const String smatpayApiKey = String.fromEnvironment(
    'SMATPAY_MERCHANT_API_KEY',
    defaultValue: '3X0NgDdl4J3xlcaQ9SHRz',
  );

  // ==========================================
  // PAYMENT GATEWAY CONFIGURATION
  // ==========================================

  static const Map<String, Map<String, String>> paymentProviders = {
    'smatpay': {
      'name': 'SmatPay',
      'supportedCountries': 'ZA,KE,NG,GH,UG,TZ,RW,ZM,ZW,MW,BW,NA,MZ,ET,EG,MU',
      'apiVersion': 'v1',
      'methods': 'card,mobile_money,bank_transfer',
      'priority': '1',
    },
    'cash': {
      'name': 'Cash / In-Person Payment',
      'supportedCountries': 'ZA,ZW,KE,NG,GH,UG,TZ',
      'apiVersion': 'v1',
      'methods': 'cash,bank_transfer',
      'priority': '2',
    },
  };
  // Get provider configuration
  static Map<String, String>? getProviderConfig(String providerId) {
    return paymentProviders[providerId];
  }

  // Check if provider supports a country
  static bool isProviderSupported(String providerId, String countryCode) {
    final config = getProviderConfig(providerId);
    if (config == null) return false;

    final supportedCountries = config['supportedCountries']?.split(',') ?? [];
    return supportedCountries.contains(countryCode.toUpperCase());
  }

  // Get all providers for a country
  static List<String> getProvidersForCountry(String countryCode) {
    return paymentProviders.keys
        .where((provider) => isProviderSupported(provider, countryCode))
        .toList();
  }

  // Get primary provider for country
  static String getPrimaryProviderForCountry(String countryCode) {
    return 'smatpay';
  }

  // ==========================================
  // CURRENCY CONVERSION API
  // ==========================================
  static const String exchangeRateApi = String.fromEnvironment(
    'EXCHANGE_RATE_API',
    defaultValue: 'https://api.exchangerate-api.com/v4/latest/USD',
  );

  // ==========================================
  // TIMEOUT CONFIGURATIONS
  // ==========================================
  static const int paymentTimeoutSeconds = 120; // 2 minutes for card payments
  static const int verificationTimeoutSeconds = 300; // 5 minutes for verification
  static const int eftVerificationHours = 72; // 72 hours for EFT verification

  // ==========================================
  // RETRY CONFIGURATIONS
  // ==========================================
  static const int maxPaymentRetries = 3;
  static const int retryDelaySeconds = 5;

  // ==========================================
  // WEBHOOK/CALLBACK URLs
  // ==========================================
  static String getBaseUrl() => baseUrl;
  
  static String getCallbackUrl(String transactionId) {
    return '${getBaseUrl()}/payments/callback/$transactionId';
  }

  static String getWebhookUrl(String provider) {
    return '${getBaseUrl()}/payments/webhook/$provider';
  }

  // ==========================================
  // PRODUCTION VALIDATION
  // ==========================================
  static void validateProductionKeys() {
    if (isProduction) {
      final errors = <String>[];

      // Validate SmatPay key
      if (smatpayApiKey.isEmpty) {
        errors.add('SmatPay API key not configured for production');
      }

      if (errors.isNotEmpty) {
        throw Exception('Payment configuration errors:\n${errors.join('\n')}');
      }
    }
  }

  // Get checkout URL for provider
  static String getCheckoutUrl(String provider, String transactionId) {
    if (provider.toLowerCase() == 'smatpay') {
      return 'https://live.smatpay.africa/checkout/$transactionId';
    }
    return '${getBaseUrl()}/payments/checkout/$provider/$transactionId';
  }
}

// Environment helper
class PaymentEnvironment {
  static bool get isDebug {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }

  static bool get isRelease => !isDebug;

  static bool get isTest {
    return bool.fromEnvironment('IS_TEST', defaultValue: false);
  }

  static String get environmentName {
    if (isTest) return 'test';
    if (isDebug) return 'debug';
    if (PaymentConfig.isProduction) return 'production';
    return 'development';
  }

  // Get appropriate API URL based on environment
  static String getApiUrl(String endpoint) {
    final baseUrl = PaymentConfig.getBaseUrl();

    // In debug/test environments, you might want to log requests
    if (isDebug || isTest) {
      print('[DEBUG] API Request: $baseUrl/$endpoint');
    }

    return '$baseUrl/$endpoint';
  }
}
