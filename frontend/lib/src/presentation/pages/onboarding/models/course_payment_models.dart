// course_payment_models.dart - INTEGRATED VERSION

// ─── CORE PAYMENT MODELS ───────────────────────────────────────────

class CoursePaymentRequest {
  final int masterclassId;
  final String masterclassTitle;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String currency;
  final String paymentMethod;
  final String? providerName;
  final UserPaymentDetails? userDetails;
  final bool isCorporate;
  final String? countryCode;
  final String? countryName;
  final CorporateDetails? corporateDetails;
  final IndividualDetails? individualDetails;
  final DateTime createdAt;

  CoursePaymentRequest({
    required this.masterclassId,
    required this.masterclassTitle,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.currency,
    required this.paymentMethod,
    this.providerName,
    this.userDetails,
    required this.isCorporate,
    this.countryCode,
    this.countryName,
    this.corporateDetails,
    this.individualDetails,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'masterclass_id': masterclassId,
      'masterclass_title': masterclassTitle,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'currency': currency,
      'payment_method': paymentMethod,
      if (providerName != null) 'provider_name': providerName,
      if (userDetails != null) 'user_details': userDetails!.toJson(),
      'is_corporate': isCorporate,
      if (countryCode != null) 'country_code': countryCode,
      if (countryName != null) 'country_name': countryName,
      if (corporateDetails != null)
        'corporate_details': corporateDetails!.toJson(),
      if (individualDetails != null)
        'individual_details': individualDetails!.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CorporateDetails {
  final String companyName;
  final String contactEmail;
  final String contactPhone;
  final String? companyAddress;
  final String? vatNumber;

  CorporateDetails({
    required this.companyName,
    required this.contactEmail,
    required this.contactPhone,
    this.companyAddress,
    this.vatNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      if (companyAddress != null) 'company_address': companyAddress,
      if (vatNumber != null) 'vat_number': vatNumber,
    };
  }
}

class IndividualDetails {
  final String fullName;
  final String email;
  final String? phone;

  IndividualDetails({
    required this.fullName,
    required this.email,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      if (phone != null) 'phone': phone,
    };
  }
}

class UserPaymentDetails {
  final String? id;
  final String? userId;
  final String paymentMethod;
  final String? providerName;
  final String? cardLastFour;
  final String? cardHolderName;
  final String? expiryDate;
  final String? mobileNumber;
  final String? mobileProvider;
  final bool isDefault;
  final DateTime createdAt;

  UserPaymentDetails({
    this.id,
    this.userId,
    required this.paymentMethod,
    this.providerName,
    this.cardLastFour,
    this.cardHolderName,
    this.expiryDate,
    this.mobileNumber,
    this.mobileProvider,
    this.isDefault = false,
    required this.createdAt,
  });

  factory UserPaymentDetails.fromJson(Map<String, dynamic> json) {
    return UserPaymentDetails(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      paymentMethod: json['payment_method'] as String,
      providerName: json['provider_name'] as String?,
      cardLastFour: json['card_last_four'] as String?,
      cardHolderName: json['card_holder_name'] as String?,
      expiryDate: json['expiry_date'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      mobileProvider: json['mobile_provider'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'payment_method': paymentMethod,
      if (providerName != null) 'provider_name': providerName,
      if (cardLastFour != null) 'card_last_four': cardLastFour,
      if (cardHolderName != null) 'card_holder_name': cardHolderName,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (mobileProvider != null) 'mobile_provider': mobileProvider,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ─── COURSE PAYMENT ITEM (Your Original Model) ─────────────────────

class CoursePaymentItem {
  final String courseId;
  final String courseTitle;
  final String? courseCode;
  final String? instructorName;
  final String? category;
  final String? thumbnailUrl;

  // Pricing
  final double originalPrice;
  final double discountedPrice;
  final double taxAmount;
  final double finalPrice;

  // Discount information
  final bool hasDiscount;
  final double discountPercentage;
  final String? discountCode;
  final DateTime? discountValidUntil;

  // Course details for receipt
  final Duration? courseDuration;
  final String? courseLevel;
  final List<String>? includedFeatures;
  final bool? hasCertificate;
  final DateTime? accessStartDate;
  final DateTime? accessEndDate;

  // Subscription info
  final bool isSubscription;
  final String? subscriptionPeriod; // monthly, yearly, lifetime
  final bool autoRenew;

  // Licensing info (for corporate/enterprise)
  final bool isEnterpriseLicense;
  final int? licenseSeats;
  final String? licenseType;

  // Masterclass specific fields
  final bool isMasterclass;
  final int? masterclassId;
  final DateTime? masterclassStartDate;
  final DateTime? masterclassEndDate;
  final String? masterclassLocation;
  final int? maxParticipants;
  final int? currentParticipants;

  CoursePaymentItem({
    required this.courseId,
    required this.courseTitle,
    this.courseCode,
    this.instructorName,
    this.category,
    this.thumbnailUrl,
    required this.originalPrice,
    required this.discountedPrice,
    this.taxAmount = 0.0,
    required this.finalPrice,
    this.hasDiscount = false,
    this.discountPercentage = 0.0,
    this.discountCode,
    this.discountValidUntil,
    this.courseDuration,
    this.courseLevel,
    this.includedFeatures,
    this.hasCertificate = false,
    this.accessStartDate,
    this.accessEndDate,
    this.isSubscription = false,
    this.subscriptionPeriod,
    this.autoRenew = false,
    this.isEnterpriseLicense = false,
    this.licenseSeats,
    this.licenseType,
    this.isMasterclass = false,
    this.masterclassId,
    this.masterclassStartDate,
    this.masterclassEndDate,
    this.masterclassLocation,
    this.maxParticipants,
    this.currentParticipants,
  });

  double get savings => originalPrice - discountedPrice;

  bool get isMasterclassFull {
    if (!isMasterclass ||
        maxParticipants == null ||
        currentParticipants == null) {
      return false;
    }
    return currentParticipants! >= maxParticipants!;
  }

  int get seatsRemaining {
    if (!isMasterclass ||
        maxParticipants == null ||
        currentParticipants == null) {
      return 0;
    }
    return (maxParticipants! - currentParticipants!).clamp(0, maxParticipants!);
  }

  bool get isMasterclassUpcoming {
    if (!isMasterclass || masterclassStartDate == null) return false;
    return masterclassStartDate!.isAfter(DateTime.now());
  }

  bool get isMasterclassOngoing {
    if (!isMasterclass ||
        masterclassStartDate == null ||
        masterclassEndDate == null) return false;
    final now = DateTime.now();
    return (now.isAfter(masterclassStartDate!) ||
            now.isAtSameMomentAs(masterclassStartDate!)) &&
        (now.isBefore(masterclassEndDate!) ||
            now.isAtSameMomentAs(masterclassEndDate!));
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'course_title': courseTitle,
      'course_code': courseCode,
      'instructor_name': instructorName,
      'category': category,
      'thumbnail_url': thumbnailUrl,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'tax_amount': taxAmount,
      'final_price': finalPrice,
      'has_discount': hasDiscount,
      'discount_percentage': discountPercentage,
      'discount_code': discountCode,
      'discount_valid_until': discountValidUntil?.toIso8601String(),
      'course_duration': courseDuration?.inHours,
      'course_level': courseLevel,
      'included_features': includedFeatures,
      'has_certificate': hasCertificate,
      'access_start_date': accessStartDate?.toIso8601String(),
      'access_end_date': accessEndDate?.toIso8601String(),
      'is_subscription': isSubscription,
      'subscription_period': subscriptionPeriod,
      'auto_renew': autoRenew,
      'is_enterprise_license': isEnterpriseLicense,
      'license_seats': licenseSeats,
      'license_type': licenseType,
      'is_masterclass': isMasterclass,
      'masterclass_id': masterclassId,
      'masterclass_start_date': masterclassStartDate?.toIso8601String(),
      'masterclass_end_date': masterclassEndDate?.toIso8601String(),
      'masterclass_location': masterclassLocation,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
    };
  }

  factory CoursePaymentItem.fromJson(Map<String, dynamic> json) {
    return CoursePaymentItem(
      courseId: json['course_id'] ?? '',
      courseTitle: json['course_title'] ?? '',
      courseCode: json['course_code'],
      instructorName: json['instructor_name'],
      category: json['category'],
      thumbnailUrl: json['thumbnail_url'],
      originalPrice: (json['original_price'] ?? 0.0).toDouble(),
      discountedPrice: (json['discounted_price'] ?? 0.0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0.0).toDouble(),
      finalPrice: (json['final_price'] ?? 0.0).toDouble(),
      hasDiscount: json['has_discount'] ?? false,
      discountPercentage: (json['discount_percentage'] ?? 0.0).toDouble(),
      discountCode: json['discount_code'],
      discountValidUntil: json['discount_valid_until'] != null
          ? DateTime.tryParse(json['discount_valid_until'])
          : null,
      courseDuration: json['course_duration'] != null
          ? Duration(hours: json['course_duration'])
          : null,
      courseLevel: json['course_level'],
      includedFeatures: json['included_features'] != null
          ? List<String>.from(json['included_features'])
          : null,
      hasCertificate: json['has_certificate'] ?? false,
      accessStartDate: json['access_start_date'] != null
          ? DateTime.tryParse(json['access_start_date'])
          : null,
      accessEndDate: json['access_end_date'] != null
          ? DateTime.tryParse(json['access_end_date'])
          : null,
      isSubscription: json['is_subscription'] ?? false,
      subscriptionPeriod: json['subscription_period'],
      autoRenew: json['auto_renew'] ?? false,
      isEnterpriseLicense: json['is_enterprise_license'] ?? false,
      licenseSeats: json['license_seats'],
      licenseType: json['license_type'],
      isMasterclass: json['is_masterclass'] ?? false,
      masterclassId: json['masterclass_id'],
      masterclassStartDate: json['masterclass_start_date'] != null
          ? DateTime.tryParse(json['masterclass_start_date'])
          : null,
      masterclassEndDate: json['masterclass_end_date'] != null
          ? DateTime.tryParse(json['masterclass_end_date'])
          : null,
      masterclassLocation: json['masterclass_location'],
      maxParticipants: json['max_participants'],
      currentParticipants: json['current_participants'],
    );
  }

  CoursePaymentItem copyWith({
    String? courseId,
    String? courseTitle,
    String? courseCode,
    String? instructorName,
    String? category,
    String? thumbnailUrl,
    double? originalPrice,
    double? discountedPrice,
    double? taxAmount,
    double? finalPrice,
    bool? hasDiscount,
    double? discountPercentage,
    String? discountCode,
    DateTime? discountValidUntil,
    Duration? courseDuration,
    String? courseLevel,
    List<String>? includedFeatures,
    bool? hasCertificate,
    DateTime? accessStartDate,
    DateTime? accessEndDate,
    bool? isSubscription,
    String? subscriptionPeriod,
    bool? autoRenew,
    bool? isEnterpriseLicense,
    int? licenseSeats,
    String? licenseType,
    bool? isMasterclass,
    int? masterclassId,
    DateTime? masterclassStartDate,
    DateTime? masterclassEndDate,
    String? masterclassLocation,
    int? maxParticipants,
    int? currentParticipants,
  }) {
    return CoursePaymentItem(
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      courseCode: courseCode ?? this.courseCode,
      instructorName: instructorName ?? this.instructorName,
      category: category ?? this.category,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      taxAmount: taxAmount ?? this.taxAmount,
      finalPrice: finalPrice ?? this.finalPrice,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountCode: discountCode ?? this.discountCode,
      discountValidUntil: discountValidUntil ?? this.discountValidUntil,
      courseDuration: courseDuration ?? this.courseDuration,
      courseLevel: courseLevel ?? this.courseLevel,
      includedFeatures: includedFeatures ?? this.includedFeatures,
      hasCertificate: hasCertificate ?? this.hasCertificate,
      accessStartDate: accessStartDate ?? this.accessStartDate,
      accessEndDate: accessEndDate ?? this.accessEndDate,
      isSubscription: isSubscription ?? this.isSubscription,
      subscriptionPeriod: subscriptionPeriod ?? this.subscriptionPeriod,
      autoRenew: autoRenew ?? this.autoRenew,
      isEnterpriseLicense: isEnterpriseLicense ?? this.isEnterpriseLicense,
      licenseSeats: licenseSeats ?? this.licenseSeats,
      licenseType: licenseType ?? this.licenseType,
      isMasterclass: isMasterclass ?? this.isMasterclass,
      masterclassId: masterclassId ?? this.masterclassId,
      masterclassStartDate: masterclassStartDate ?? this.masterclassStartDate,
      masterclassEndDate: masterclassEndDate ?? this.masterclassEndDate,
      masterclassLocation: masterclassLocation ?? this.masterclassLocation,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
    );
  }

  // Create CoursePaymentItem from Masterclass
  factory CoursePaymentItem.fromMasterclass(
      Map<String, dynamic> masterclassData) {
    return CoursePaymentItem(
      courseId: masterclassData['id'].toString(),
      courseTitle: masterclassData['title'] ?? 'Masterclass',
      originalPrice: (masterclassData['price_usd'] ?? 0.0).toDouble(),
      discountedPrice: (masterclassData['price_usd'] ?? 0.0).toDouble(),
      finalPrice: (masterclassData['price_usd'] ?? 0.0).toDouble(),
      isMasterclass: true,
      masterclassId: masterclassData['id'] as int?,
      masterclassStartDate: masterclassData['start_date'] != null
          ? DateTime.tryParse(masterclassData['start_date'])
          : null,
      masterclassEndDate: masterclassData['end_date'] != null
          ? DateTime.tryParse(masterclassData['end_date'])
          : null,
      masterclassLocation: masterclassData['location_display'] ??
          masterclassData['city'] ??
          masterclassData['country'],
      maxParticipants: masterclassData['max_participants'],
      currentParticipants: masterclassData['current_participants'],
    );
  }
}

// ─── CART SUMMARY ─────────────────────────────────────────────────

class CartSummary {
  final List<CoursePaymentItem> items;
  final double subtotal;
  final double totalDiscount;
  final double totalTax;
  final double grandTotal;
  final String currency;
  final int totalItems;
  final double? walletBalanceUsed;
  final double? couponDiscount;
  final String? appliedCouponCode;

  // Masterclass specific totals
  final int masterclassCount;
  final int regularCourseCount;
  final double masterclassSubtotal;
  final double regularCourseSubtotal;

  CartSummary({
    required this.items,
    required this.subtotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.grandTotal,
    this.currency = 'USD',
    required this.totalItems,
    this.walletBalanceUsed = 0.0,
    this.couponDiscount = 0.0,
    this.appliedCouponCode,
    this.masterclassCount = 0,
    this.regularCourseCount = 0,
    this.masterclassSubtotal = 0.0,
    this.regularCourseSubtotal = 0.0,
  });

  // Get masterclass items
  List<CoursePaymentItem> get masterclassItems =>
      items.where((item) => item.isMasterclass).toList();

  // Get regular course items
  List<CoursePaymentItem> get regularCourseItems =>
      items.where((item) => !item.isMasterclass).toList();

  // Check if cart contains masterclasses
  bool get hasMasterclasses => masterclassCount > 0;

  // Check if cart contains regular courses
  bool get hasRegularCourses => regularCourseCount > 0;

  // Check if any masterclass is full
  bool get hasFullMasterclasses =>
      masterclassItems.any((item) => item.isMasterclassFull);

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'total_discount': totalDiscount,
      'total_tax': totalTax,
      'grand_total': grandTotal,
      'currency': currency,
      'total_items': totalItems,
      'wallet_balance_used': walletBalanceUsed,
      'coupon_discount': couponDiscount,
      'applied_coupon_code': appliedCouponCode,
      'masterclass_count': masterclassCount,
      'regular_course_count': regularCourseCount,
      'masterclass_subtotal': masterclassSubtotal,
      'regular_course_subtotal': regularCourseSubtotal,
    };
  }

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((item) => CoursePaymentItem.fromJson(item))
            .toList() ??
        [];

    final masterclassCount = items.where((item) => item.isMasterclass).length;
    final regularCourseCount = items.length - masterclassCount;

    final masterclassSubtotal = items
        .where((item) => item.isMasterclass)
        .fold(0.0, (sum, item) => sum + item.finalPrice);

    final regularCourseSubtotal = items
        .where((item) => !item.isMasterclass)
        .fold(0.0, (sum, item) => sum + item.finalPrice);

    return CartSummary(
      items: items,
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      totalDiscount: (json['total_discount'] ?? 0.0).toDouble(),
      totalTax: (json['total_tax'] ?? 0.0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      totalItems: json['total_items'] ?? 0,
      walletBalanceUsed: (json['wallet_balance_used'] ?? 0.0).toDouble(),
      couponDiscount: (json['coupon_discount'] ?? 0.0).toDouble(),
      appliedCouponCode: json['applied_coupon_code'],
      masterclassCount: masterclassCount,
      regularCourseCount: regularCourseCount,
      masterclassSubtotal: masterclassSubtotal,
      regularCourseSubtotal: regularCourseSubtotal,
    );
  }
}
