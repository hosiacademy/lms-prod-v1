// african_currencies.dart
// Simplified version with essential data

class AfricanCountry {
  final String code; // ISO 3166-1 alpha-2
  final String name;
  final String currencyCode; // ISO 4217
  final String currencySymbol;
  final String currencyName;
  final String phoneCode;
  final String? region;
  
  const AfricanCountry({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyName,
    required this.phoneCode,
    this.region,
  });
}

class AfricanCurrencies {
  // Essential African countries (subset for testing, can expand later)
  static const List<AfricanCountry> countries = [
    // East Africa
    AfricanCountry(
      code: 'KE',
      name: 'Kenya',
      currencyCode: 'KES',
      currencySymbol: 'KSh',
      currencyName: 'Kenyan Shilling',
      phoneCode: '+254',
      region: 'Eastern Africa',
    ),
    AfricanCountry(
      code: 'TZ',
      name: 'Tanzania',
      currencyCode: 'TZS',
      currencySymbol: 'TSh',
      currencyName: 'Tanzanian Shilling',
      phoneCode: '+255',
      region: 'Eastern Africa',
    ),
    AfricanCountry(
      code: 'UG',
      name: 'Uganda',
      currencyCode: 'UGX',
      currencySymbol: 'USh',
      currencyName: 'Ugandan Shilling',
      phoneCode: '+256',
      region: 'Eastern Africa',
    ),
    AfricanCountry(
      code: 'RW',
      name: 'Rwanda',
      currencyCode: 'RWF',
      currencySymbol: 'RF',
      currencyName: 'Rwandan Franc',
      phoneCode: '+250',
      region: 'Eastern Africa',
    ),
    AfricanCountry(
      code: 'ET',
      name: 'Ethiopia',
      currencyCode: 'ETB',
      currencySymbol: 'Br',
      currencyName: 'Ethiopian Birr',
      phoneCode: '+251',
      region: 'Eastern Africa',
    ),
    
    // West Africa
    AfricanCountry(
      code: 'NG',
      name: 'Nigeria',
      currencyCode: 'NGN',
      currencySymbol: '₦',
      currencyName: 'Nigerian Naira',
      phoneCode: '+234',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'GH',
      name: 'Ghana',
      currencyCode: 'GHS',
      currencySymbol: 'GH₵',
      currencyName: 'Ghanaian Cedi',
      phoneCode: '+233',
      region: 'Western Africa',
    ),
    
    // Southern Africa
    AfricanCountry(
      code: 'ZA',
      name: 'South Africa',
      currencyCode: 'ZAR',
      currencySymbol: 'R',
      currencyName: 'South African Rand',
      phoneCode: '+27',
      region: 'Southern Africa',
    ),
    AfricanCountry(
      code: 'ZM',
      name: 'Zambia',
      currencyCode: 'ZMW',
      currencySymbol: 'ZK',
      currencyName: 'Zambian Kwacha',
      phoneCode: '+260',
      region: 'Southern Africa',
    ),
    AfricanCountry(
      code: 'ZW',
      name: 'Zimbabwe',
      currencyCode: 'ZWL',
      currencySymbol: '\$',
      currencyName: 'Zimbabwean Dollar',
      phoneCode: '+263',
      region: 'Southern Africa',
    ),

    // Southern Africa (expanded)
    AfricanCountry(
      code: 'BW',
      name: 'Botswana',
      currencyCode: 'BWP',
      currencySymbol: 'P',
      currencyName: 'Botswana Pula',
      phoneCode: '+267',
      region: 'Southern Africa',
    ),
    AfricanCountry(
      code: 'MZ',
      name: 'Mozambique',
      currencyCode: 'MZN',
      currencySymbol: 'MT',
      currencyName: 'Mozambican Metical',
      phoneCode: '+258',
      region: 'Southern Africa',
    ),
    AfricanCountry(
      code: 'MW',
      name: 'Malawi',
      currencyCode: 'MWK',
      currencySymbol: 'MK',
      currencyName: 'Malawian Kwacha',
      phoneCode: '+265',
      region: 'Southern Africa',
    ),
    AfricanCountry(
      code: 'NA',
      name: 'Namibia',
      currencyCode: 'NAD',
      currencySymbol: 'N\$',
      currencyName: 'Namibian Dollar',
      phoneCode: '+264',
      region: 'Southern Africa',
    ),
    AfricanCountry(
      code: 'LS',
      name: 'Lesotho',
      currencyCode: 'LSL',
      currencySymbol: 'L',
      currencyName: 'Lesotho Loti',
      phoneCode: '+266',
      region: 'Southern Africa',
    ),
    AfricanCountry(
      code: 'SZ',
      name: 'Eswatini',
      currencyCode: 'SZL',
      currencySymbol: 'E',
      currencyName: 'Swazi Lilangeni',
      phoneCode: '+268',
      region: 'Southern Africa',
    ),

    // North Africa
    AfricanCountry(
      code: 'EG',
      name: 'Egypt',
      currencyCode: 'EGP',
      currencySymbol: '£',
      currencyName: 'Egyptian Pound',
      phoneCode: '+20',
      region: 'Northern Africa',
    ),
    AfricanCountry(
      code: 'MA',
      name: 'Morocco',
      currencyCode: 'MAD',
      currencySymbol: 'MAD',
      currencyName: 'Moroccan Dirham',
      phoneCode: '+212',
      region: 'Northern Africa',
    ),

    // West Africa (CFA zone)
    AfricanCountry(
      code: 'CI',
      name: 'Ivory Coast',
      currencyCode: 'XOF',
      currencySymbol: 'CFA',
      currencyName: 'West African CFA Franc',
      phoneCode: '+225',
      region: 'Western Africa',
    ),

    // Central Africa (CFA zone)
    AfricanCountry(
      code: 'CM',
      name: 'Cameroon',
      currencyCode: 'XAF',
      currencySymbol: 'CFA',
      currencyName: 'Central African CFA Franc',
      phoneCode: '+237',
      region: 'Central Africa',
    ),

    // East Africa (extra)
    AfricanCountry(
      code: 'SO',
      name: 'Somalia',
      currencyCode: 'USD',
      currencySymbol: '\$',
      currencyName: 'US Dollar',
      phoneCode: '+252',
      region: 'Eastern Africa',
    ),
  ];

  // Get country by code
  static AfricanCountry? getCountryByCode(String countryCode) {
    for (var country in countries) {
      if (country.code.toLowerCase() == countryCode.toLowerCase()) {
        return country;
      }
    }
    return null;
  }

  // Get currency by country code
  static String getCurrencyCode(String countryCode) {
    final country = getCountryByCode(countryCode);
    return country?.currencyCode ?? 'USD';
  }

  static String getCurrencySymbol(String countryCode) {
    final country = getCountryByCode(countryCode);
    return country?.currencySymbol ?? '\$';
  }

  static String getCurrencyName(String countryCode) {
    final country = getCountryByCode(countryCode);
    return country?.currencyName ?? 'US Dollar';
  }

  static String getPhoneCode(String countryCode) {
    final country = getCountryByCode(countryCode);
    return country?.phoneCode ?? '+1';
  }

  // Format currency amount
  static String formatAmount(double amount, String countryCode, {int decimalPlaces = 2}) {
    final currency = getCurrencySymbol(countryCode);
    final formattedAmount = amount.toStringAsFixed(decimalPlaces);
    return '$currency$formattedAmount';
  }
}
