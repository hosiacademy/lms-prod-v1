// user_payment_details.dart

class UserPaymentDetails {
  final String userId;
  final String email;
  final String fullName;
  final String? phone;
  final String? country;
  final String? city;
  final String? address;
  final String? zipCode;
  
  // Billing specific fields
  final String? billingName;
  final String? billingAddress;
  final String? billingCity;
  final String? billingCountry;
  final String? billingZipCode;
  final String? vatNumber;
  
  // Payment method preferences
  final String? defaultPaymentMethod;
  final String? payoutMethod; // PayPal, bank transfer, etc.
  final String? payoutEmail; // For PayPal payouts
  final String? bankName;
  final String? bankAccountNumber;
  final String? accountHolderName;
  
  // Currency preferences
  final String preferredCurrency;
  final double? balance; // User wallet balance
  
  // Verification status
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  
  UserPaymentDetails({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    this.country,
    this.city,
    this.address,
    this.zipCode,
    this.billingName,
    this.billingAddress,
    this.billingCity,
    this.billingCountry,
    this.billingZipCode,
    this.vatNumber,
    this.defaultPaymentMethod,
    this.payoutMethod,
    this.payoutEmail,
    this.bankName,
    this.bankAccountNumber,
    this.accountHolderName,
    this.preferredCurrency = 'USD',
    this.balance = 0.0,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'country': country,
      'city': city,
      'address': address,
      'zip_code': zipCode,
      'billing_name': billingName,
      'billing_address': billingAddress,
      'billing_city': billingCity,
      'billing_country': billingCountry,
      'billing_zip_code': billingZipCode,
      'vat_number': vatNumber,
      'default_payment_method': defaultPaymentMethod,
      'payout_method': payoutMethod,
      'payout_email': payoutEmail,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'account_holder_name': accountHolderName,
      'preferred_currency': preferredCurrency,
      'balance': balance,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
    };
  }
  
  factory UserPaymentDetails.fromJson(Map<String, dynamic> json) {
    return UserPaymentDetails(
      userId: json['user_id'] ?? json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? json['username'] ?? '',
      phone: json['phone'] ?? json['phone1'],
      country: json['country'],
      city: json['city'],
      address: json['address'],
      zipCode: json['zip_code'] ?? json['zip'],
      billingName: json['billing_name'] ?? json['full_name'] ?? json['name'],
      billingAddress: json['billing_address'] ?? json['address'],
      billingCity: json['billing_city'] ?? json['city'],
      billingCountry: json['billing_country'] ?? json['country'],
      billingZipCode: json['billing_zip_code'] ?? json['zip_code'] ?? json['zip'],
      vatNumber: json['vat_number'],
      defaultPaymentMethod: json['default_payment_method'],
      payoutMethod: json['payout_method'] ?? json['payout'],
      payoutEmail: json['payout_email'],
      bankName: json['bank_name'],
      bankAccountNumber: json['bank_account_number'],
      accountHolderName: json['account_holder_name'],
      preferredCurrency: json['preferred_currency'] ?? 'USD',
      balance: (json['balance'] ?? 0.0).toDouble(),
      emailVerified: json['email_verified'] ?? (json['email_verified_at'] != null),
      phoneVerified: json['phone_verified'] ?? (json['mobile_verified_at'] != null),
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.tryParse(json['email_verified_at']) 
          : null,
      phoneVerifiedAt: json['phone_verified_at'] ?? json['mobile_verified_at'] != null
          ? DateTime.tryParse(json['phone_verified_at'] ?? json['mobile_verified_at'])
          : null,
    );
  }
  
  UserPaymentDetails copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? phone,
    String? country,
    String? city,
    String? address,
    String? zipCode,
    String? billingName,
    String? billingAddress,
    String? billingCity,
    String? billingCountry,
    String? billingZipCode,
    String? vatNumber,
    String? defaultPaymentMethod,
    String? payoutMethod,
    String? payoutEmail,
    String? bankName,
    String? bankAccountNumber,
    String? accountHolderName,
    String? preferredCurrency,
    double? balance,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? emailVerifiedAt,
    DateTime? phoneVerifiedAt,
  }) {
    return UserPaymentDetails(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      city: city ?? this.city,
      address: address ?? this.address,
      zipCode: zipCode ?? this.zipCode,
      billingName: billingName ?? this.billingName,
      billingAddress: billingAddress ?? this.billingAddress,
      billingCity: billingCity ?? this.billingCity,
      billingCountry: billingCountry ?? this.billingCountry,
      billingZipCode: billingZipCode ?? this.billingZipCode,
      vatNumber: vatNumber ?? this.vatNumber,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      payoutEmail: payoutEmail ?? this.payoutEmail,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      balance: balance ?? this.balance,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
    );
  }
}
