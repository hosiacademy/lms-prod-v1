// lib/src/data/models/course_cart.dart

class CourseCart {
  final int id;
  final int userId;
  final String? userEmail;
  final String status;
  final bool usePreviousCompanyDetails;
  final bool isCorporateEnrollment;
  final int totalCourses;
  final String totalAmount;
  final String currency;
  final List<CourseCartItem> items;
  final Map<String, dynamic>? previousCompanyDetails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseCart({
    required this.id,
    required this.userId,
    this.userEmail,
    required this.status,
    this.usePreviousCompanyDetails = false,
    this.isCorporateEnrollment = false,
    this.totalCourses = 0,
    required this.totalAmount,
    this.currency = 'USD',
    this.items = const [],
    this.previousCompanyDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseCart.fromJson(Map<String, dynamic> json) {
    return CourseCart(
      id: json['id'] as int,
      userId: json['user'] as int,
      userEmail: json['user_email'] as String?,
      status: json['status'] as String,
      usePreviousCompanyDetails: json['use_previous_company_details'] as bool? ?? false,
      isCorporateEnrollment: json['is_corporate_enrollment'] as bool? ?? false,
      totalCourses: json['total_courses'] as int? ?? 0,
      totalAmount: json['total_amount'].toString(),
      currency: json['currency'] as String? ?? 'USD',
      items: json['items'] != null
          ? (json['items'] as List).map((item) => CourseCartItem.fromJson(item as Map<String, dynamic>)).toList()
          : [],
      previousCompanyDetails: json['previous_company_details'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'use_previous_company_details': usePreviousCompanyDetails,
      'is_corporate_enrollment': isCorporateEnrollment,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Active';
      case 'checkout':
        return 'In Checkout';
      case 'completed':
        return 'Completed';
      case 'abandoned':
        return 'Abandoned';
      default:
        return status;
    }
  }

  bool get isEmpty => totalCourses == 0;

  bool get hasPreviousCompanyDetails => previousCompanyDetails != null && previousCompanyDetails!.isNotEmpty;

  CourseCart copyWith({
    int? id,
    int? userId,
    String? userEmail,
    String? status,
    bool? usePreviousCompanyDetails,
    bool? isCorporateEnrollment,
    int? totalCourses,
    String? totalAmount,
    List<CourseCartItem>? items,
  }) {
    return CourseCart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      status: status ?? this.status,
      usePreviousCompanyDetails: usePreviousCompanyDetails ?? this.usePreviousCompanyDetails,
      isCorporateEnrollment: isCorporateEnrollment ?? this.isCorporateEnrollment,
      totalCourses: totalCourses ?? this.totalCourses,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency,
      items: items ?? this.items,
      previousCompanyDetails: previousCompanyDetails,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class CourseCartItem {
  final int id;
  final int cartId;
  final int contentTypeId;
  final int objectId;
  final String? courseTitle;
  final Map<String, dynamic>? courseDetails;
  final String trainingType;
  final String price;
  final String currency;
  final bool prerequisitesMet;
  final bool addedFromWishlist;
  final DateTime? createdAt;

  CourseCartItem({
    required this.id,
    required this.cartId,
    required this.contentTypeId,
    required this.objectId,
    this.courseTitle,
    this.courseDetails,
    required this.trainingType,
    required this.price,
    this.currency = 'USD',
    this.prerequisitesMet = true,
    this.addedFromWishlist = false,
    this.createdAt,
  });

  factory CourseCartItem.fromJson(Map<String, dynamic> json) {
    return CourseCartItem(
      id: json['id'] as int,
      cartId: json['cart'] as int,
      contentTypeId: json['content_type'] as int,
      objectId: json['object_id'] as int,
      courseTitle: json['course_title'] as String?,
      courseDetails: json['course_details'] as Map<String, dynamic>?,
      trainingType: json['training_type'] as String,
      price: json['price'].toString(),
      currency: json['currency'] as String? ?? 'USD',
      prerequisitesMet: json['prerequisites_met'] as bool? ?? true,
      addedFromWishlist: json['added_from_wishlist'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_type_id': contentTypeId,
      'object_id': objectId,
      'training_type': trainingType,
      'from_wishlist': addedFromWishlist,
    };
  }

  String get trainingTypeDisplay {
    switch (trainingType) {
      case 'masterclass':
        return 'Masterclass';
      case 'learnership':
        return 'Learnership';
      case 'industry_training':
        return 'Industry Training';
      case 'custom_selection':
        return 'Custom Selection';
      default:
        return trainingType;
    }
  }
}
