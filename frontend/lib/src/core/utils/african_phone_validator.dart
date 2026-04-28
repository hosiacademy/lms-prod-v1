// lib/src/core/utils/african_phone_validator.dart

import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class AfricanPhoneValidator {
  // Map of African country codes to validation info
  static final Map<String, PhoneValidationInfo> africanPhoneInfo = {
    'ZA': PhoneValidationInfo('South Africa', '+27', 9, 9),
    'NG': PhoneValidationInfo('Nigeria', '+234', 10, 10),
    'KE': PhoneValidationInfo('Kenya', '+254', 9, 9),
    'GH': PhoneValidationInfo('Ghana', '+233', 9, 9),
    'EG': PhoneValidationInfo('Egypt', '+20', 10, 10),
    'ET': PhoneValidationInfo('Ethiopia', '+251', 9, 9),
    'TZ': PhoneValidationInfo('Tanzania', '+255', 9, 9),
    'UG': PhoneValidationInfo('Uganda', '+256', 9, 9),
    'MW': PhoneValidationInfo('Malawi', '+265', 9, 9),
    'MZ': PhoneValidationInfo('Mozambique', '+258', 9, 9),
    'DZ': PhoneValidationInfo('Algeria', '+213', 9, 9),
    'AO': PhoneValidationInfo('Angola', '+244', 9, 9),
    'BJ': PhoneValidationInfo('Benin', '+229', 8, 8),
    'BW': PhoneValidationInfo('Botswana', '+267', 8, 8),
    'BF': PhoneValidationInfo('Burkina Faso', '+226', 8, 8),
    'BI': PhoneValidationInfo('Burundi', '+257', 8, 8),
    'CV': PhoneValidationInfo('Cape Verde', '+238', 7, 7),
    'CM': PhoneValidationInfo('Cameroon', '+237', 9, 9),
    'CF': PhoneValidationInfo('Central African Republic', '+236', 8, 8),
    'TD': PhoneValidationInfo('Chad', '+235', 8, 8),
    'KM': PhoneValidationInfo('Comoros', '+269', 7, 7),
    'CG': PhoneValidationInfo('Congo', '+242', 9, 9),
    'CD': PhoneValidationInfo('DR Congo', '+243', 9, 9),
    'CI': PhoneValidationInfo('Ivory Coast', '+225', 8, 8),
    'DJ': PhoneValidationInfo('Djibouti', '+253', 8, 8),
    'GQ': PhoneValidationInfo('Equatorial Guinea', '+240', 9, 9),
    'ER': PhoneValidationInfo('Eritrea', '+291', 7, 7),
    'SZ': PhoneValidationInfo('Eswatini', '+268', 8, 8),
    'GA': PhoneValidationInfo('Gabon', '+241', 8, 8),
    'GM': PhoneValidationInfo('Gambia', '+220', 7, 7),
    'GN': PhoneValidationInfo('Guinea', '+224', 9, 9),
    'GW': PhoneValidationInfo('Guinea-Bissau', '+245', 7, 7),
    'LS': PhoneValidationInfo('Lesotho', '+266', 8, 8),
    'LR': PhoneValidationInfo('Liberia', '+231', 8, 8),
    'LY': PhoneValidationInfo('Libya', '+218', 9, 9),
    'MG': PhoneValidationInfo('Madagascar', '+261', 9, 9),
    'ML': PhoneValidationInfo('Mali', '+223', 8, 8),
    'MR': PhoneValidationInfo('Mauritania', '+222', 8, 8),
    'MU': PhoneValidationInfo('Mauritius', '+230', 8, 8),
    'MA': PhoneValidationInfo('Morocco', '+212', 9, 9),
    'NA': PhoneValidationInfo('Namibia', '+264', 9, 9),
    'NE': PhoneValidationInfo('Niger', '+227', 8, 8),
    'RW': PhoneValidationInfo('Rwanda', '+250', 9, 9),
    'ST': PhoneValidationInfo('Sao Tome and Principe', '+239', 7, 7),
    'SN': PhoneValidationInfo('Senegal', '+221', 9, 9),
    'SC': PhoneValidationInfo('Seychelles', '+248', 7, 7),
    'SL': PhoneValidationInfo('Sierra Leone', '+232', 8, 8),
    'SO': PhoneValidationInfo('Somalia', '+252', 8, 8),
    'SS': PhoneValidationInfo('South Sudan', '+211', 9, 9),
    'SD': PhoneValidationInfo('Sudan', '+249', 9, 9),
    'TG': PhoneValidationInfo('Togo', '+228', 8, 8),
    'TN': PhoneValidationInfo('Tunisia', '+216', 8, 8),
    'ZM': PhoneValidationInfo('Zambia', '+260', 9, 9),
    'ZW': PhoneValidationInfo('Zimbabwe', '+263', 9, 9),
  };

  // Get validation info for a country
  static PhoneValidationInfo? getInfoForCountry(String countryCode) {
    return africanPhoneInfo[countryCode.toUpperCase()];
  }

  // List of supported country codes
  static List<String> get supportedCountries {
    return africanPhoneInfo.keys.toList();
  }

  // Get phone number pattern for validation - SIMPLE VERSION
  static String? getPhonePattern(String countryCode) {
    final info = getInfoForCountry(countryCode);
    if (info == null) return null;

    // Simple regex pattern - escape the $ with backslash
    return '^[0-9]{${info.minDigits},${info.maxDigits}}\$';
  }

  // Validate phone number for a specific country
  static bool validatePhoneNumber(String phoneNumber, String countryCode) {
    final info = getInfoForCountry(countryCode);
    if (info == null) return false;

    // Remove country code if present
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Simple length check
    if (digitsOnly.length < info.minDigits ||
        digitsOnly.length > info.maxDigits) {
      return false;
    }

    return true;
  }

  // Format phone number with country code
  static String formatWithCountryCode(String phoneNumber, String countryCode) {
    final info = getInfoForCountry(countryCode);
    if (info == null) return phoneNumber;

    // Remove any existing country code
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure we don't duplicate the country code
    if (digitsOnly.startsWith(info.countryCode.replaceAll('+', ''))) {
      return '+$digitsOnly';
    }

    // Add country code
    return '${info.countryCode}$digitsOnly';
  }

  // Get initial phone number value based on country
  static PhoneNumber getInitialPhoneNumber(String countryCode) {
    final info = getInfoForCountry(countryCode);
    return PhoneNumber(
      isoCode: countryCode.toUpperCase(),
      dialCode: info?.countryCode ?? '+1',
    );
  }
}

class PhoneValidationInfo {
  final String countryName;
  final String countryCode; // e.g., +27
  final int minDigits;
  final int maxDigits;

  PhoneValidationInfo(
      this.countryName, this.countryCode, this.minDigits, this.maxDigits);
}
