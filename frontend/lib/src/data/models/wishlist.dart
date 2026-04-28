// lib/src/data/models/wishlist.dart

class Wishlist {
  final int id;
  final int userId;
  final String? userEmail;
  final int contentTypeId;
  final int objectId;
  final String? courseTitle;
  final CourseDetails? courseDetails;
  final String trainingType;
  final String interestLevel;
  final String intendedStart;
  final String? notes;
  final bool marketingContacted;
  final DateTime? marketingContactedAt;
  final String? marketingNotes;
  final int? contactedById;
  final bool convertedToCart;
  final bool convertedToEnrollment;
  final int? daysInWishlist;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Wishlist({
    required this.id,
    required this.userId,
    this.userEmail,
    required this.contentTypeId,
    required this.objectId,
    this.courseTitle,
    this.courseDetails,
    required this.trainingType,
    required this.interestLevel,
    required this.intendedStart,
    this.notes,
    this.marketingContacted = false,
    this.marketingContactedAt,
    this.marketingNotes,
    this.contactedById,
    this.convertedToCart = false,
    this.convertedToEnrollment = false,
    this.daysInWishlist,
    this.createdAt,
    this.updatedAt,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'] as int,
      userId: json['user'] as int,
      userEmail: json['user_email'] as String?,
      contentTypeId: json['content_type'] as int,
      objectId: json['object_id'] as int,
      courseTitle: json['course_title'] as String?,
      courseDetails: json['course_details'] != null
          ? CourseDetails.fromJson(json['course_details'] as Map<String, dynamic>)
          : null,
      trainingType: json['training_type'] as String,
      interestLevel: json['interest_level'] as String,
      intendedStart: json['intended_start'] as String,
      notes: json['notes'] as String?,
      marketingContacted: json['marketing_contacted'] as bool? ?? false,
      marketingContactedAt: json['marketing_contacted_at'] != null
          ? DateTime.parse(json['marketing_contacted_at'] as String)
          : null,
      marketingNotes: json['marketing_notes'] as String?,
      contactedById: json['contacted_by'] as int?,
      convertedToCart: json['converted_to_cart'] as bool? ?? false,
      convertedToEnrollment: json['converted_to_enrollment'] as bool? ?? false,
      daysInWishlist: json['days_in_wishlist'] as int?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_type': contentTypeId,
      'object_id': objectId,
      'training_type': trainingType,
      'interest_level': interestLevel,
      'intended_start': intendedStart,
      'notes': notes,
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

  String get interestLevelDisplay {
    switch (interestLevel) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return interestLevel;
    }
  }

  String get intendedStartDisplay {
    switch (intendedStart) {
      case 'this_month':
        return 'This Month';
      case 'next_month':
        return 'Next Month';
      case '3_months':
        return 'In 3 Months';
      case '6_months':
        return 'In 6 Months';
      case 'later':
        return 'Later';
      default:
        return intendedStart;
    }
  }
}

class CourseDetails {
  final int id;
  final String type;
  final String? title;
  final String? description;
  final String? price;
  final String? duration;
  final List<String>? prerequisites;
  final String? thumbnailUrl;

  CourseDetails({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.price,
    this.duration,
    this.prerequisites,
    this.thumbnailUrl,
  });

  factory CourseDetails.fromJson(Map<String, dynamic> json) {
    return CourseDetails(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      price: json['price'] as String?,
      duration: json['duration'] as String?,
      prerequisites: json['prerequisites'] != null
          ? List<String>.from(json['prerequisites'] as List)
          : null,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}
