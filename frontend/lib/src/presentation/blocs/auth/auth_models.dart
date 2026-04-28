// Add to your auth state/model
class User {
  // ... existing fields ...
  
  // Payment-related fields from Django model
  final String? country;
  final String? currency;
  final double? balance;
  final String? phone;
  final String? payoutMethod;
  final String? payoutEmail;
  final bool emailVerified;
  final bool phoneVerified;
  
  // Payment preferences
  final String? preferredPaymentMethod;
  final List<String>? savedPaymentMethods;
  
  User({
    // ... existing fields ...
    this.country,
    this.currency,
    this.balance = 0.0,
    this.phone,
    this.payoutMethod,
    this.payoutEmail,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.preferredPaymentMethod,
    this.savedPaymentMethods,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // ... existing fields ...
      country: json['country'],
      currency: json['currency'] ?? json['currency_id']?.toString(),
      balance: (json['balance'] ?? 0.0).toDouble(),
      phone: json['phone'] ?? json['phone1'],
      payoutMethod: json['payout_method'] ?? json['payout'],
      payoutEmail: json['payout_email'],
      emailVerified: json['email_verified'] ?? (json['email_verified_at'] != null),
      phoneVerified: json['phone_verified'] ?? (json['mobile_verified_at'] != null),
      preferredPaymentMethod: json['preferred_payment_method'],
      savedPaymentMethods: json['saved_payment_methods'] != null
          ? List<String>.from(json['saved_payment_methods'])
          : null,
    );
  }
}
