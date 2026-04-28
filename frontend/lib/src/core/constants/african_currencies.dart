// african_currencies.dart
// Complete list of ALL 54 African countries with currencies
// South Africa listed FIRST for prominence

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
  // ALL 54 AFRICAN COUNTRIES - South Africa FIRST
  static const List<AfricanCountry> countries = [
    // ==================== SOUTHERN AFRICA ====================
    // SOUTH AFRICA FIRST - Primary market
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
      code: 'ZW',
      name: 'Zimbabwe',
      currencyCode: 'USD',
      currencySymbol: 'US\$',
      currencyName: 'US Dollar',
      phoneCode: '+263',
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
      code: 'BW',
      name: 'Botswana',
      currencyCode: 'BWP',
      currencySymbol: 'P',
      currencyName: 'Botswana Pula',
      phoneCode: '+267',
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
      name: 'Eswatini (Swaziland)',
      currencyCode: 'SZL',
      currencySymbol: 'E',
      currencyName: 'Swazi Lilangeni',
      phoneCode: '+268',
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
      code: 'AO',
      name: 'Angola',
      currencyCode: 'AOA',
      currencySymbol: 'Kz',
      currencyName: 'Angolan Kwanza',
      phoneCode: '+244',
      region: 'Southern Africa',
    ),

    // ==================== EAST AFRICA ====================
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
      code: 'BI',
      name: 'Burundi',
      currencyCode: 'BIF',
      currencySymbol: 'FBu',
      currencyName: 'Burundian Franc',
      phoneCode: '+257',
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
    AfricanCountry(
      code: 'SO',
      name: 'Somalia',
      currencyCode: 'SOS',
      currencySymbol: 'Sh',
      currencyName: 'Somali Shilling',
      phoneCode: '+252',
      region: 'Eastern Africa',
    ),
    AfricanCountry(
      code: 'DJ',
      name: 'Djibouti',
      currencyCode: 'DJF',
      currencySymbol: 'Fdj',
      currencyName: 'Djiboutian Franc',
      phoneCode: '+253',
      region: 'Eastern Africa',
    ),
    AfricanCountry(
      code: 'ER',
      name: 'Eritrea',
      currencyCode: 'ERN',
      currencySymbol: 'Nfk',
      currencyName: 'Eritrean Nakfa',
      phoneCode: '+291',
      region: 'Eastern Africa',
    ),
    AfricanCountry(
      code: 'SS',
      name: 'South Sudan',
      currencyCode: 'SSP',
      currencySymbol: '£',
      currencyName: 'South Sudanese Pound',
      phoneCode: '+211',
      region: 'Eastern Africa',
    ),

    // ==================== WEST AFRICA ====================
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
    AfricanCountry(
      code: 'CI',
      name: 'Ivory Coast (Côte d\'Ivoire)',
      currencyCode: 'XOF',
      currencySymbol: 'CFA',
      currencyName: 'West African CFA Franc',
      phoneCode: '+225',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'SN',
      name: 'Senegal',
      currencyCode: 'XOF',
      currencySymbol: 'CFA',
      currencyName: 'West African CFA Franc',
      phoneCode: '+221',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'ML',
      name: 'Mali',
      currencyCode: 'XOF',
      currencySymbol: 'CFA',
      currencyName: 'West African CFA Franc',
      phoneCode: '+223',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'BF',
      name: 'Burkina Faso',
      currencyCode: 'XOF',
      currencySymbol: 'CFA',
      currencyName: 'West African CFA Franc',
      phoneCode: '+226',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'NE',
      name: 'Niger',
      currencyCode: 'XOF',
      currencySymbol: 'CFA',
      currencyName: 'West African CFA Franc',
      phoneCode: '+227',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'GW',
      name: 'Guinea-Bissau',
      currencyCode: 'XOF',
      currencySymbol: 'CFA',
      currencyName: 'West African CFA Franc',
      phoneCode: '+245',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'GN',
      name: 'Guinea',
      currencyCode: 'GNF',
      currencySymbol: 'FG',
      currencyName: 'Guinean Franc',
      phoneCode: '+224',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'SL',
      name: 'Sierra Leone',
      currencyCode: 'SLL',
      currencySymbol: 'Le',
      currencyName: 'Sierra Leonean Leone',
      phoneCode: '+232',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'LR',
      name: 'Liberia',
      currencyCode: 'LRD',
      currencySymbol: '\$',
      currencyName: 'Liberian Dollar',
      phoneCode: '+231',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'TG',
      name: 'Togo',
      currencyCode: 'XOF',
      currencySymbol: 'CFA',
      currencyName: 'West African CFA Franc',
      phoneCode: '+228',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'BJ',
      name: 'Benin',
      currencyCode: 'XOF',
      currencySymbol: 'CFA',
      currencyName: 'West African CFA Franc',
      phoneCode: '+229',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'MR',
      name: 'Mauritania',
      currencyCode: 'MRU',
      currencySymbol: 'UM',
      currencyName: 'Mauritanian Ouguiya',
      phoneCode: '+222',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'GM',
      name: 'Gambia',
      currencyCode: 'GMD',
      currencySymbol: 'D',
      currencyName: 'Gambian Dalasi',
      phoneCode: '+220',
      region: 'Western Africa',
    ),
    AfricanCountry(
      code: 'CV',
      name: 'Cape Verde',
      currencyCode: 'CVE',
      currencySymbol: '\$',
      currencyName: 'Cape Verdean Escudo',
      phoneCode: '+238',
      region: 'Western Africa',
    ),

    // ==================== CENTRAL AFRICA ====================
    AfricanCountry(
      code: 'CM',
      name: 'Cameroon',
      currencyCode: 'XAF',
      currencySymbol: 'FCFA',
      currencyName: 'Central African CFA Franc',
      phoneCode: '+237',
      region: 'Central Africa',
    ),
    AfricanCountry(
      code: 'GA',
      name: 'Gabon',
      currencyCode: 'XAF',
      currencySymbol: 'FCFA',
      currencyName: 'Central African CFA Franc',
      phoneCode: '+241',
      region: 'Central Africa',
    ),
    AfricanCountry(
      code: 'CG',
      name: 'Republic of the Congo',
      currencyCode: 'XAF',
      currencySymbol: 'FCFA',
      currencyName: 'Central African CFA Franc',
      phoneCode: '+242',
      region: 'Central Africa',
    ),
    AfricanCountry(
      code: 'CD',
      name: 'Democratic Republic of the Congo (DRC)',
      currencyCode: 'CDF',
      currencySymbol: 'FC',
      currencyName: 'Congolese Franc',
      phoneCode: '+243',
      region: 'Central Africa',
    ),
    AfricanCountry(
      code: 'CF',
      name: 'Central African Republic',
      currencyCode: 'XAF',
      currencySymbol: 'FCFA',
      currencyName: 'Central African CFA Franc',
      phoneCode: '+236',
      region: 'Central Africa',
    ),
    AfricanCountry(
      code: 'TD',
      name: 'Chad',
      currencyCode: 'XAF',
      currencySymbol: 'FCFA',
      currencyName: 'Central African CFA Franc',
      phoneCode: '+235',
      region: 'Central Africa',
    ),
    AfricanCountry(
      code: 'GQ',
      name: 'Equatorial Guinea',
      currencyCode: 'XAF',
      currencySymbol: 'FCFA',
      currencyName: 'Central African CFA Franc',
      phoneCode: '+240',
      region: 'Central Africa',
    ),
    AfricanCountry(
      code: 'ST',
      name: 'São Tomé and Príncipe',
      currencyCode: 'STN',
      currencySymbol: 'Db',
      currencyName: 'São Tomé and Príncipe Dobra',
      phoneCode: '+239',
      region: 'Central Africa',
    ),

    // ==================== NORTH AFRICA ====================
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
    AfricanCountry(
      code: 'DZ',
      name: 'Algeria',
      currencyCode: 'DZD',
      currencySymbol: 'دج',
      currencyName: 'Algerian Dinar',
      phoneCode: '+213',
      region: 'Northern Africa',
    ),
    AfricanCountry(
      code: 'TN',
      name: 'Tunisia',
      currencyCode: 'TND',
      currencySymbol: 'دت',
      currencyName: 'Tunisian Dinar',
      phoneCode: '+216',
      region: 'Northern Africa',
    ),
    AfricanCountry(
      code: 'LY',
      name: 'Libya',
      currencyCode: 'LYD',
      currencySymbol: 'ل.د',
      currencyName: 'Libyan Dinar',
      phoneCode: '+218',
      region: 'Northern Africa',
    ),
    AfricanCountry(
      code: 'SD',
      name: 'Sudan',
      currencyCode: 'SDG',
      currencySymbol: 'ج.س.',
      currencyName: 'Sudanese Pound',
      phoneCode: '+249',
      region: 'Northern Africa',
    ),

    // ==================== ISLAND NATIONS ====================
    AfricanCountry(
      code: 'MU',
      name: 'Mauritius',
      currencyCode: 'MUR',
      currencySymbol: '₨',
      currencyName: 'Mauritian Rupee',
      phoneCode: '+230',
      region: 'Eastern Africa (Island)',
    ),
    AfricanCountry(
      code: 'SC',
      name: 'Seychelles',
      currencyCode: 'SCR',
      currencySymbol: '₨',
      currencyName: 'Seychellois Rupee',
      phoneCode: '+248',
      region: 'Eastern Africa (Island)',
    ),
    AfricanCountry(
      code: 'MG',
      name: 'Madagascar',
      currencyCode: 'MGA',
      currencySymbol: 'Ar',
      currencyName: 'Malagasy Ariary',
      phoneCode: '+261',
      region: 'Eastern Africa (Island)',
    ),
    AfricanCountry(
      code: 'KM',
      name: 'Comoros',
      currencyCode: 'KMF',
      currencySymbol: 'CF',
      currencyName: 'Comorian Franc',
      phoneCode: '+269',
      region: 'Eastern Africa (Island)',
    ),
  ];

  // Get country by code (case-insensitive)
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

  // Get country by currency code
  static List<AfricanCountry> getCountriesByCurrency(String currencyCode) {
    return countries
        .where((country) => country.currencyCode == currencyCode)
        .toList();
  }

  // Get countries by region
  static List<AfricanCountry> getCountriesByRegion(String region) {
    return countries
        .where((country) => country.region?.toLowerCase() == region.toLowerCase())
        .toList();
  }

  // Format currency amount
  static String formatAmount(double amount, String countryCode, {int decimalPlaces = 0}) {
    final currency = getCurrencySymbol(countryCode);
    final formattedAmount = amount.round().toString();
    return '$currency$formattedAmount';
  }

  // Format with currency name
  static String formatWithCurrency(double amount, String countryCode) {
    final country = getCountryByCode(countryCode);
    if (country == null) return '\$${amount.round()}';
    return '${country.currencySymbol}${amount.round()} ${country.currencyCode}';
  }

  // Search countries by name
  static List<AfricanCountry> searchCountries(String query) {
    final lowerQuery = query.toLowerCase();
    return countries
        .where((country) =>
            country.name.toLowerCase().contains(lowerQuery) ||
            country.code.toLowerCase().contains(lowerQuery) ||
            country.currencyName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Get all country codes
  static List<String> getAllCountryCodes() {
    return countries.map((country) => country.code).toList();
  }

  // Check if country is supported
  static bool isCountrySupported(String countryCode) {
    return getCountryByCode(countryCode) != null;
  }
}
