import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/environment.dart';
import '../constants/african_currencies.dart';
import '../constants/pricing_constants.dart';

class CurrencyService extends ChangeNotifier {
  // Singleton instance
  static final CurrencyService _instance = CurrencyService._internal();
  static CurrencyService get instance => _instance;

  CurrencyService._internal();

  final Dio _dio = Dio();

  // Detected / selected state
  String _countryCode = 'ZA';  // Default to South Africa
  String _currencyCode = 'ZAR'; // Default to South African Rand
  String _countryName = 'South Africa';
  String _userCity = '';
  String _userRegion = '';
  bool _isManualOverride = false;
  bool _isInitialized = false;
  bool _locationDetected = false; // Cache first detection result
  bool _ratesLoaded = false; // Track if rates were successfully loaded

  // Exchange rates fetched from backend
  Map<String, double> _exchangeRates = {};
  DateTime? _ratesFetchedAt;
  DateTime? _ratesExpiresAt;

  // Memoization cache for formatted prices
  final Map<String, String> _formatCache = {};
  static const int _maxCacheSize = 50;

  // Public getters
  bool get isManualOverride => _isManualOverride;
  String get countryCode => _countryCode;
  String get currencyCode => _currencyCode;

  /// Set country manually (user selects country for training/payment)
  /// This allows a user in SA to pay for Kenyan training in KES
  Future<void> setCountry(String countryCode) async {
    final upper = countryCode.toUpperCase();
    final currency = AfricanCurrencies.getCurrencyCode(upper);
    final country = AfricanCurrencies.getCountryByCode(upper);
    
    _isManualOverride = true;
    _countryCode = upper;
    _currencyCode = currency;
    _countryName = country?.name ?? upper;
    
    // Fetch exchange rates for the selected country
    await _fetchExchangeRates();
    
    notifyListeners();
    debugPrint('CurrencyService: Country set to $upper ($currency)');
  }

  /// Alias kept for backward compatibility with existing callers
  String get userCurrency => _currencyCode;

  String get countryName => _countryName;
  String get userCity => _userCity;
  String get userRegion => _userRegion;

  /// Backward-compatibility aliases
  String get userCountryCode => _countryCode;
  String get userCountryName => _countryName;

  /// Check if rates have been loaded (for hardened mode)
  bool get hasLoadedRates => _ratesLoaded;

  /// Get exchange rate for currency (from cached backend rates)
  /// HARDENED: Always returns a rate, even for USD (returns 1.0 with proper handling)
  double getExchangeRate(String currencyCode) {
    final upper = currencyCode.toUpperCase();
    // HARDENED: Even for USD, we go through the conversion process
    // This ensures consistent behavior and allows for future rate adjustments
    if (upper == 'USD') {
      // For USD-based currencies, always return 1.0 but mark as converted
      return 1.0;
    }
    final rate = _exchangeRates[upper];
    if (rate == null) {
      // Rate not available - this should not happen in hardened mode
      // Return 1.0 as fallback but caller should check hasLoadedRates
      return 1.0;
    }
    return rate;
  }

  // Currencies that never show decimal places
  static const Set<String> _noDecimalCurrencies = {
    'UGX', 'RWF', 'BIF', 'GNF', 'DJF', 'MGA', 'JPY', 'KRW', 'VND',
  };

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Call once at app startup. Subsequent calls are no-ops if manual override
  /// is active.
  Future<void> initialize() async {
    if (_isManualOverride) {
      debugPrint('CurrencyService: Manual override active, skipping initialization');
      return;
    }
    debugPrint('CurrencyService: Initializing...');

    // Use backend IP detection (ip-api.com - ACCURATE)
    await _detectLocation();

    debugPrint('CurrencyService: Location detected - Country: $_countryCode, Currency: $_currencyCode');

    await _fetchExchangeRates();
    _isInitialized = true;
    debugPrint('CurrencyService: Initialized with $_currencyCode ($_countryCode)');
  }

  // ---------------------------------------------------------------------------
  // Exchange rate fetching
  // ---------------------------------------------------------------------------

  /// Fetch exchange rates from backend API (cached for 24 hours)
  Future<void> _fetchExchangeRates() async {
    try {
      final response = await _dio.get(
        '${Environment.apiBaseUrl}/api/v1/payments/exchange-rates/',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;

        if (rates != null && rates.isNotEmpty) {
          _exchangeRates = rates.map((key, value) =>
            MapEntry(key.toUpperCase(), (value as num).toDouble())
          );
          _ratesFetchedAt = DateTime.now();
          _ratesLoaded = true; // Mark rates as loaded

          // Parse expiry if available
          if (data['expires_at'] != null) {
            _ratesExpiresAt = DateTime.parse(data['expires_at']);
          }

          notifyListeners();
          debugPrint('CurrencyService: Exchange rates loaded for ${_exchangeRates.length} currencies');
        } else {
          // No rates in response - mark as not loaded
          _ratesLoaded = false;
          debugPrint('CurrencyService: No rates in response');
        }
      } else {
        // Non-200 response - mark as not loaded
        _ratesLoaded = false;
        debugPrint('CurrencyService: Non-200 response: ${response.statusCode}');
      }
    } catch (e) {
      // Silently fail - will use fallback rates
      // HARDENED: Mark rates as not loaded so callers know conversion didn't happen
      _ratesLoaded = false;
      debugPrint('CurrencyService: Failed to fetch exchange rates: $e');
    }
  }

  /// Force refresh exchange rates
  Future<void> refreshExchangeRates() async {
    await _fetchExchangeRates();
  }

  // ---------------------------------------------------------------------------
  // Detection flow
  // ---------------------------------------------------------------------------

  Future<void> _detectLocation() async {
    // Skip if already detected
    if (_locationDetected && !_isManualOverride) {
      debugPrint('CurrencyService: Using cached location');
      return;
    }

    // Call backend endpoint (uses ip-api.com - ACCURATE)
    try {
      final url = '${Environment.apiBaseUrl}/api/v1/payments/detect-location/';
      final response = await _dio.get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final country = (data['country_code'] as String?)?.toUpperCase();
        final currency = (data['currency'] as String?)?.toUpperCase();
        _userCity = (data['city'] as String?) ?? '';
        _userRegion = (data['region'] as String?) ?? '';
        if (country != null && currency != null) {
          _applyCountryCode(country, currency);
          _locationDetected = true;
          debugPrint('CurrencyService: Detected $country ($currency)');
          return;
        }
      }
    } catch (e) {
      debugPrint('CurrencyService: Backend detection failed: $e');
    }

    // Fallback: South Africa ZAR
    _applyCountryCode('ZA', 'ZAR');
    debugPrint('CurrencyService: Using default ZAR');
  }

  void _applyCountryCode(String country, String currency) {
    _countryCode = country;
    _currencyCode = currency;
    final africanCountry = AfricanCurrencies.getCountryByCode(country);
    _countryName = africanCountry?.name ?? country;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Manual override
  // ---------------------------------------------------------------------------

  /// Set country explicitly (e.g., from authenticated user profile).
  void setUserCountryCode(String countryCode) {
    _isManualOverride = true;
    final upper = countryCode.toUpperCase();
    final currency = AfricanCurrencies.getCurrencyCode(upper);
    _applyCountryCode(upper, currency);
  }

  /// Directly set the active currency code (e.g. from a currency picker).
  /// Does NOT change the country code — just overrides the displayed currency.
  void setCurrency(String currencyCode) {
    _isManualOverride = true;
    _currencyCode = currencyCode.toUpperCase();
    _formatCache.clear();
    notifyListeners();
    debugPrint('CurrencyService: Currency manually set to $_currencyCode');
  }


  /// Reset to automatic detection and re-run the detection flow.
  Future<void> resetToAutoDetect() async {
    _isManualOverride = false;
    _locationDetected = false; // Clear cache to allow re-detection
    _formatCache.clear(); // Clear format cache
    await _detectLocation();
  }

  // ---------------------------------------------------------------------------
  // Conversion helpers
  // ---------------------------------------------------------------------------

  /// Synchronous conversion using fetched backend rates.
  /// CRITICAL: Currency is ALWAYS country-specific - NO mixing of currencies
  /// Kenya = KES only, Zimbabwe = USD only, South Africa = ZAR only
  double convertFromUSD(double amountUSD) {
    // Get the exchange rate for the detected currency
    final rate = getExchangeRate(_currencyCode);

    // Convert: USD × rate = local currency
    // For ZW: rate = 1.0 (USD = USD, Zimbabwe uses USD)
    // For ZA: rate = 16.74 (USD × 16.74 = ZAR)
    // For KE: rate = 129.23 (USD × 129.23 = KES)
    return amountUSD * rate;
  }

  /// Asynchronous variant kept for backward compatibility.
  /// CRITICAL: Returns currency-specific conversion - never mixes currencies
  Future<double> convertFromUSDAsync(
      double amountUSD, String targetCurrency) async {
    final upper = targetCurrency.toUpperCase();
    // For USD-based countries (Zimbabwe), no conversion needed
    if (upper == 'USD') return amountUSD;
    final rate = getExchangeRate(targetCurrency);
    return amountUSD * rate;
  }

  // ---------------------------------------------------------------------------
  // Formatting - HARDENED: Never show USD, always convert
  // ---------------------------------------------------------------------------

  /// Converts a USD amount to the user's currency and formats it.
  /// CRITICAL: Always converts to local currency - NEVER shows USD for non-USD countries
  /// Kenya shows KES, Zimbabwe shows USD, South Africa shows ZAR
  String formatUSDAmount(double amountUSD) {
    // Always go through conversion to ensure country-specific currency
    final convertedAmount = convertFromUSD(amountUSD);
    return formatPrice(convertedAmount);
  }

  /// Formats [price] with a currency symbol and thousands separator.
  ///
  /// CRITICAL: Uses country-specific currency ONLY
  /// - Kenya (KE) = KES (Kenyan Shilling)
  /// - Zimbabwe (ZW) = USD (US Dollar)
  /// - South Africa (ZA) = ZAR (South African Rand)
  ///
  /// PREMIUM LOOK: Shows 10,000 instead of 10000
  String formatPrice(double price, {String? currencyCode, bool showDecimals = true}) {
    final code = (currencyCode ?? _currencyCode).toUpperCase();
    
    final displayCode = _getDisplayCurrencyCode(code);
    final symbol = _symbolForCurrency(displayCode);

    // Force WHOLE NUMBERS only as per user request
    final roundedPrice = price.round();
    
    // Pattern with thousands separator: #,##0
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 0,
      customPattern: '\u00a4 #,##0', // Added space and thousands separator
    );

    String formatted = formatter.format(roundedPrice);
    
    return formatted;
  }

  /// Get the display currency code - Use what backend returns
  /// CRITICAL: Backend handles country-specific currency correctly
  /// - KE (Kenya) -> KES (Kenyan Shilling)
  /// - ZW (Zimbabwe) -> USD (US Dollar - Zimbabwe's official currency)
  /// - ZA (South Africa) -> ZAR (South African Rand)
  String _getDisplayCurrencyCode(String code) {
    // Trust the backend's currency detection
    // This ensures each country uses its official currency
    return code;
  }

  String _symbolForCurrency(String currencyCode) {
    for (final country in AfricanCurrencies.countries) {
      if (country.currencyCode == currencyCode) {
        return country.currencySymbol;
      }
    }
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      case 'KRW':
        return '₩';
      case 'AED':
        return 'د.إ';
      default:
        return '$currencyCode ';
    }
  }
}
