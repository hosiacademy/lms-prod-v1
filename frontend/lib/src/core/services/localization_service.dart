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

  static const List<GreetingData> allAfricanGreetings = [
    // South Africa
    GreetingData(
      countryCode: 'ZA',
      countryName: 'South Africa',
      flag: '🇿🇦',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Zulu',
      localGreeting: 'Sawubona!',
    ),
    GreetingData(
      countryCode: 'ZA',
      countryName: 'South Africa',
      flag: '🇿🇦',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Xhosa',
      localGreeting: 'Molo!',
    ),
    GreetingData(
      countryCode: 'ZA',
      countryName: 'South Africa',
      flag: '🇿🇦',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Sotho',
      localGreeting: 'Dumela!',
    ),
    GreetingData(
      countryCode: 'ZA',
      countryName: 'South Africa',
      flag: '🇿🇦',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Afrikaans',
      localGreeting: 'Welkom!',
    ),
    // Nigeria
    GreetingData(
      countryCode: 'NG',
      countryName: 'Nigeria',
      flag: '🇳🇬',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Yoruba',
      localGreeting: 'Ẹ káàbọ̀!',
    ),
    GreetingData(
      countryCode: 'NG',
      countryName: 'Nigeria',
      flag: '🇳🇬',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Igbo',
      localGreeting: 'Nnọọ!',
    ),
    GreetingData(
      countryCode: 'NG',
      countryName: 'Nigeria',
      flag: '🇳🇬',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Hausa',
      localGreeting: 'Sannu!',
    ),
    // Kenya / East Africa
    GreetingData(
      countryCode: 'KE',
      countryName: 'Kenya',
      flag: '🇰🇪',
      officialLanguage: 'Swahili',
      officialGreeting: 'Karibu!',
      localLanguage: 'Kikuyu',
      localGreeting: 'Wimwega!',
    ),
    GreetingData(
      countryCode: 'TZ',
      countryName: 'Tanzania',
      flag: '🇹🇿',
      officialLanguage: 'Swahili',
      officialGreeting: 'Karibu!',
      localLanguage: 'Swahili',
      localGreeting: 'Habari!',
    ),
    // Ethiopia
    GreetingData(
      countryCode: 'ET',
      countryName: 'Ethiopia',
      flag: '🇪🇹',
      officialLanguage: 'Amharic',
      officialGreeting: 'Inkuan Dehna Metah!',
      localLanguage: 'Amharic',
      localGreeting: 'Selam!',
    ),
    // Ghana
    GreetingData(
      countryCode: 'GH',
      countryName: 'Ghana',
      flag: '🇬🇭',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Twi',
      localGreeting: 'Akwaaba!',
    ),
    // Rwanda
    GreetingData(
      countryCode: 'RW',
      countryName: 'Rwanda',
      flag: '🇷🇼',
      officialLanguage: 'Kinyarwanda',
      officialGreeting: 'Murakaza neza!',
      localLanguage: 'Kinyarwanda',
      localGreeting: 'Muraho!',
    ),
    // Senegal
    GreetingData(
      countryCode: 'SN',
      countryName: 'Senegal',
      flag: '🇸🇳',
      officialLanguage: 'French',
      officialGreeting: 'Bienvenue!',
      localLanguage: 'Wolof',
      localGreeting: 'Na nga deef!',
    ),
    // Uganda
    GreetingData(
      countryCode: 'UG',
      countryName: 'Uganda',
      flag: '🇺🇬',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Luganda',
      localGreeting: 'Ki kati!',
    ),
    // Zimbabwe
    GreetingData(
      countryCode: 'ZW',
      countryName: 'Zimbabwe',
      flag: '🇿🇼',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Shona',
      localGreeting: 'Mhoro!',
    ),
    GreetingData(
      countryCode: 'ZW',
      countryName: 'Zimbabwe',
      flag: '🇿🇼',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Ndebele',
      localGreeting: 'Salibonani!',
    ),
    // Egypt / North Africa
    GreetingData(
      countryCode: 'EG',
      countryName: 'Egypt',
      flag: '🇪🇬',
      officialLanguage: 'Arabic',
      officialGreeting: 'Ahlan wa Sahlan!',
      localLanguage: 'Arabic',
      localGreeting: 'Marhaban!',
    ),
    // Botswana
    GreetingData(
      countryCode: 'BW',
      countryName: 'Botswana',
      flag: '🇧🇼',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Setswana',
      localGreeting: 'Dumela!',
    ),
    // Namibia
    GreetingData(
      countryCode: 'NA',
      countryName: 'Namibia',
      flag: '🇳🇦',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Oshiwambo',
      localGreeting: 'Wa lala po!',
    ),
    // Mali
    GreetingData(
      countryCode: 'ML',
      countryName: 'Mali',
      flag: '🇲🇱',
      officialLanguage: 'French',
      officialGreeting: 'Bienvenue!',
      localLanguage: 'Bambara',
      localGreeting: 'I ni ce!',
    ),
    // Madagascar
    GreetingData(
      countryCode: 'MG',
      countryName: 'Madagascar',
      flag: '🇲🇬',
      officialLanguage: 'Malagasy',
      officialGreeting: 'Tongasoa!',
      localLanguage: 'Malagasy',
      localGreeting: 'Manao ahoana!',
    ),
    // Angola
    GreetingData(
      countryCode: 'AO',
      countryName: 'Angola',
      flag: '🇦🇴',
      officialLanguage: 'Portuguese',
      officialGreeting: 'Bem-vindo!',
      localLanguage: 'Umbundu',
      localGreeting: 'Waliapo!',
    ),
    // Mozambique
    GreetingData(
      countryCode: 'MZ',
      countryName: 'Mozambique',
      flag: '🇲🇿',
      officialLanguage: 'Portuguese',
      officialGreeting: 'Bem-vindo!',
      localLanguage: 'Makhuwa',
      localGreeting: 'Salama!',
    ),
    // Morocco
    GreetingData(
      countryCode: 'MA',
      countryName: 'Morocco',
      flag: '🇲🇦',
      officialLanguage: 'Arabic',
      officialGreeting: 'Marhaban!',
      localLanguage: 'Tamazight',
      localGreeting: 'Azul!',
    ),
    // Sudan
    GreetingData(
      countryCode: 'SD',
      countryName: 'Sudan',
      flag: '🇸🇩',
      officialLanguage: 'Arabic',
      officialGreeting: 'Marhaban!',
      localLanguage: 'Dinka',
      localGreeting: 'Ci bak!',
    ),
    // Ivory Coast
    GreetingData(
      countryCode: 'CI',
      countryName: 'Ivory Coast',
      flag: '🇨🇮',
      officialLanguage: 'French',
      officialGreeting: 'Bienvenue!',
      localLanguage: 'Baoulé',
      localGreeting: 'Mo!',
    ),
    // Cameroon
    GreetingData(
      countryCode: 'CM',
      countryName: 'Cameroon',
      flag: '🇨🇲',
      officialLanguage: 'French/English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Bamileke',
      localGreeting: 'Aa-te!',
    ),
    // Malawi
    GreetingData(
      countryCode: 'MW',
      countryName: 'Malawi',
      flag: '🇲🇼',
      officialLanguage: 'English',
      officialGreeting: 'Welcome!',
      localLanguage: 'Chewa',
      localGreeting: 'Moni!',
    ),
    // Burkina Faso
    GreetingData(
      countryCode: 'BF',
      countryName: 'Burkina Faso',
      flag: '🇧🇫',
      officialLanguage: 'French',
      officialGreeting: 'Bienvenue!',
      localLanguage: 'Mossi',
      localGreeting: 'Ne y windiga!',
    ),
  ];

  /// Detect country code from the platform locale (e.g. 'en_KE' → 'KE').
  static String _detectCountryCode() {
    try {
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
    
    // First try to find in our comprehensive local list
    try {
      final matching = allAfricanGreetings.where((g) => g.countryCode == country).toList();
      if (matching.isNotEmpty) {
        _cached = matching.first;
        return _cached!;
      }
    } catch (_) {}

    // Fallback to API if not in local list
    try {
      final base = Environment.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$base/api/v1/localization/greeting/?country=$country');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
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
