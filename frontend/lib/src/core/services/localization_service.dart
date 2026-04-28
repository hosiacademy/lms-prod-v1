// lib/src/core/services/localization_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class GreetingData {
  final String countryCode;
  final String countryName;
  final String flag;
  final String officialLanguage;
  final String officialGreeting;
  final String localLanguage;
  final String localGreeting;

  const GreetingData({
    required this.countryCode,
    required this.countryName,
    required this.flag,
    required this.officialLanguage,
    required this.officialGreeting,
    required this.localLanguage,
    required this.localGreeting,
  });

  factory GreetingData.fallback() => const GreetingData(
        countryCode: 'ZA',
        countryName: 'South Africa',
        flag: '🇿🇦',
        officialLanguage: 'English',
        officialGreeting: 'Welcome!',
        localLanguage: 'Zulu',
        localGreeting: 'Sawubona!',
      );

  factory GreetingData.fromJson(Map<String, dynamic> json) => GreetingData(
        countryCode: json['country_code'] ?? '',
        countryName: json['country_name'] ?? 'Africa',
        flag: json['flag'] ?? '🌍',
        officialLanguage: json['official_language'] ?? 'English',
        officialGreeting: json['official_greeting'] ?? 'Welcome!',
        localLanguage: json['local_language'] ?? 'Zulu',
        localGreeting: json['local_greeting'] ?? 'Sawubona!',
      );
}

class LocalizationService {
  static GreetingData? _cached;

  /// Detect country code from the platform locale (e.g. 'en_KE' → 'KE').
  static String _detectCountryCode() {
    try {
      // PlatformDispatcher.instance.locale is available on all platforms
      final locale = PlatformDispatcher.instance.locale;
      final country = locale.countryCode;
      if (country != null && country.length == 2) {
        return country.toUpperCase();
      }
    } catch (_) {}
    return 'ZA';
  }

  static Future<GreetingData> fetchGreeting() async {
    if (_cached != null) return _cached!;
    final country = _detectCountryCode();
    try {
      final base = Environment.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$base/api/v1/localization/greeting/?country=$country');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _cached = GreetingData.fromJson(json);
        return _cached!;
      }
    } catch (_) {}
    _cached = GreetingData.fallback();
    return _cached!;
  }
}
