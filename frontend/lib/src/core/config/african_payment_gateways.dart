// lib/src/core/config/african_payment_gateways.dart
// Unified payment gateway configurations

class AfricanPaymentGateway {
  final String code;
  final String name;
  final String country;
  final List<String> paymentMethods;
  final String? hostedCheckoutUrl;
  final String? apiEndpoint;
  final Map<String, String> credentials;

  const AfricanPaymentGateway({
    required this.code,
    required this.name,
    required this.country,
    required this.paymentMethods,
    this.hostedCheckoutUrl,
    this.apiEndpoint,
    this.credentials = const {},
  });
}

class AfricanPaymentGateways {
  static const AfricanPaymentGateway smatpayGateway = AfricanPaymentGateway(
    code: 'smatpay',
    name: 'SmatPay Card',
    country: 'ALL',
    paymentMethods: ['card'],
    hostedCheckoutUrl: 'https://checkout.smatpay.com/pay',
    apiEndpoint: 'https://api.smatpay.com/v1',
  );

  static const AfricanPaymentGateway eftGateway = AfricanPaymentGateway(
    code: 'eft',
    name: 'Bank Transfer (EFT)',
    country: 'ALL',
    paymentMethods: ['bank_transfer'],
  );

  static const AfricanPaymentGateway cashGateway = AfricanPaymentGateway(
    code: 'cash',
    name: 'In-store (Cash)',
    country: 'ALL',
    paymentMethods: ['cash'],
  );

  static Map<String, List<AfricanPaymentGateway>> getGatewaysByCountry() {
    return {
      'DEFAULT': [smatpayGateway, eftGateway, cashGateway],
    };
  }

  static List<AfricanPaymentGateway> getGatewaysForCountry(String countryCode) {
    return [smatpayGateway, eftGateway, cashGateway];
  }

  static AfricanPaymentGateway? getGatewayByCode(String code) {
    if (code == 'smatpay') return smatpayGateway;
    if (code == 'eft') return eftGateway;
    if (code == 'cash') return cashGateway;
    return smatpayGateway;
  }

  static bool hasHostedCheckout(String gatewayCode) {
    return gatewayCode == 'smatpay';
  }

  static String? getHostedCheckoutUrl(String gatewayCode) {
    return gatewayCode == 'smatpay' ? smatpayGateway.hostedCheckoutUrl : null;
  }
}
