// payment_provider_models.dart - MINIMAL WORKING VERSION

// Simple CountryCode class
class CountryCode {
  final String code;
  final String name;
  
  const CountryCode(this.code, this.name);
  
  // Key African countries only
  static const CountryCode KE = CountryCode('KE', 'Kenya');
  static const CountryCode NG = CountryCode('NG', 'Nigeria');
  static const CountryCode GH = CountryCode('GH', 'Ghana');
  static const CountryCode ZA = CountryCode('ZA', 'South Africa');
  static const CountryCode TZ = CountryCode('TZ', 'Tanzania');
  static const CountryCode UG = CountryCode('UG', 'Uganda');
  
  static CountryCode fromString(String code) {
    final upperCode = code.toUpperCase();
    switch (upperCode) {
      case 'KE': return KE;
      case 'NG': return NG;
      case 'GH': return GH;
      case 'ZA': return ZA;
      case 'TZ': return TZ;
      case 'UG': return UG;
      default: return CountryCode(upperCode, upperCode);
    }
  }
}

// Simple ProviderCategory
class ProviderCategory {
  final String name;
  const ProviderCategory(this.name);
  
  static const ProviderCategory gateway = ProviderCategory('gateway');
  static const ProviderCategory mobileMoney = ProviderCategory('mobile_money');
  
  static ProviderCategory fromString(String name) {
    return ProviderCategory(name.toLowerCase().replaceAll(' ', '_'));
  }
}

// Keep only essential models - remove broken ones

class PaymentProviderModel {
  final String code;
  final String name;
  final ProviderCategory category;
  
  PaymentProviderModel({
    required this.code,
    required this.name,
    required this.category,
  });
}

// REMOVE all other broken classes for now
