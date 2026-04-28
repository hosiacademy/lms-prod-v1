// lib/src/data/models/student_profile.dart

class StudentProfile {
  final int id;
  final int userId;
  final String? userEmail;
  final String? userFullName;

  // Previous company details for reuse
  final String? lastUsedCompanyName;
  final String? lastUsedCompanyEmail;
  final String? lastUsedCompanyPhone;
  final String? lastUsedCompanyAddress;
  final String? lastUsedVatNumber;
  final bool hasCompanyPaymentHistory;

  // Location preferences
  final int? preferredCountryId;
  final String? preferredCountryName;
  final int? preferredStateId;
  final String? preferredStateName;
  final int? preferredCityId;
  final String? preferredCityName;

  final CompanyDetails? companyDetails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentProfile({
    required this.id,
    required this.userId,
    this.userEmail,
    this.userFullName,
    this.lastUsedCompanyName,
    this.lastUsedCompanyEmail,
    this.lastUsedCompanyPhone,
    this.lastUsedCompanyAddress,
    this.lastUsedVatNumber,
    this.hasCompanyPaymentHistory = false,
    this.preferredCountryId,
    this.preferredCountryName,
    this.preferredStateId,
    this.preferredStateName,
    this.preferredCityId,
    this.preferredCityName,
    this.companyDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int,
      userId: json['user'] as int,
      userEmail: json['user_email'] as String?,
      userFullName: json['user_full_name'] as String?,
      lastUsedCompanyName: json['last_used_company_name'] as String?,
      lastUsedCompanyEmail: json['last_used_company_email'] as String?,
      lastUsedCompanyPhone: json['last_used_company_phone'] as String?,
      lastUsedCompanyAddress: json['last_used_company_address'] as String?,
      lastUsedVatNumber: json['last_used_vat_number'] as String?,
      hasCompanyPaymentHistory: json['has_company_payment_history'] as bool? ?? false,
      preferredCountryId: json['preferred_country'] as int?,
      preferredCountryName: json['preferred_country_name'] as String?,
      preferredStateId: json['preferred_state'] as int?,
      preferredStateName: json['preferred_state_name'] as String?,
      preferredCityId: json['preferred_city'] as int?,
      preferredCityName: json['preferred_city_name'] as String?,
      companyDetails: json['company_details'] != null
          ? CompanyDetails.fromJson(json['company_details'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'last_used_company_name': lastUsedCompanyName,
      'last_used_company_email': lastUsedCompanyEmail,
      'last_used_company_phone': lastUsedCompanyPhone,
      'last_used_company_address': lastUsedCompanyAddress,
      'last_used_vat_number': lastUsedVatNumber,
      'preferred_country': preferredCountryId,
      'preferred_state': preferredStateId,
      'preferred_city': preferredCityId,
    };
  }

  StudentProfile copyWith({
    int? id,
    int? userId,
    String? userEmail,
    String? userFullName,
    String? lastUsedCompanyName,
    String? lastUsedCompanyEmail,
    String? lastUsedCompanyPhone,
    String? lastUsedCompanyAddress,
    String? lastUsedVatNumber,
    bool? hasCompanyPaymentHistory,
    int? preferredCountryId,
    String? preferredCountryName,
    int? preferredStateId,
    String? preferredStateName,
    int? preferredCityId,
    String? preferredCityName,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userFullName: userFullName ?? this.userFullName,
      lastUsedCompanyName: lastUsedCompanyName ?? this.lastUsedCompanyName,
      lastUsedCompanyEmail: lastUsedCompanyEmail ?? this.lastUsedCompanyEmail,
      lastUsedCompanyPhone: lastUsedCompanyPhone ?? this.lastUsedCompanyPhone,
      lastUsedCompanyAddress: lastUsedCompanyAddress ?? this.lastUsedCompanyAddress,
      lastUsedVatNumber: lastUsedVatNumber ?? this.lastUsedVatNumber,
      hasCompanyPaymentHistory: hasCompanyPaymentHistory ?? this.hasCompanyPaymentHistory,
      preferredCountryId: preferredCountryId ?? this.preferredCountryId,
      preferredCountryName: preferredCountryName ?? this.preferredCountryName,
      preferredStateId: preferredStateId ?? this.preferredStateId,
      preferredStateName: preferredStateName ?? this.preferredStateName,
      preferredCityId: preferredCityId ?? this.preferredCityId,
      preferredCityName: preferredCityName ?? this.preferredCityName,
      companyDetails: companyDetails,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class CompanyDetails {
  final String? companyName;
  final String? companyEmail;
  final String? companyPhone;
  final String? companyAddress;
  final String? vatNumber;

  CompanyDetails({
    this.companyName,
    this.companyEmail,
    this.companyPhone,
    this.companyAddress,
    this.vatNumber,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      companyName: json['company_name'] as String?,
      companyEmail: json['company_email'] as String?,
      companyPhone: json['company_phone'] as String?,
      companyAddress: json['company_address'] as String?,
      vatNumber: json['vat_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'company_email': companyEmail,
      'company_phone': companyPhone,
      'company_address': companyAddress,
      'vat_number': vatNumber,
    };
  }
}
