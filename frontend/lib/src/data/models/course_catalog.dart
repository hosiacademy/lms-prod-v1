import 'course.dart';

class CourseCatalogItem {
  final int id;
  final int contentTypeId;
  final int objectId;
  final String trainingType;
  final int providerId;
  final String? providerName;
  final String title;
  final String? description;
  final String price;
  final String currency;
  final bool isActive;
  final bool isFeatured;
  final int displayOrder;
  final int totalEnrollments;
  final int totalWishlistAdds;
  final Map<String, dynamic>? courseDetails;
  final bool inWishlist;
  final bool inCart;

  CourseCatalogItem({
    required this.id,
    required this.contentTypeId,
    required this.objectId,
    required this.trainingType,
    required this.providerId,
    this.providerName,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'USD',
    this.isActive = true,
    this.isFeatured = false,
    this.displayOrder = 0,
    this.totalEnrollments = 0,
    this.totalWishlistAdds = 0,
    this.courseDetails,
    this.inWishlist = false,
    this.inCart = false,
  });

  factory CourseCatalogItem.fromJson(Map<String, dynamic> json) {
    return CourseCatalogItem(
      id: json['id'] as int,
      contentTypeId: json['content_type'] as int,
      objectId: json['object_id'] as int,
      trainingType: json['training_type'] as String,
      providerId: json['provider'] as int,
      providerName: json['provider_name'] as String?,
      title: _decodeHtml(json['title'] as String?) ?? '',
      description: _decodeHtml(json['description'] as String?) ?? '',
      price: json['price'].toString(),
      currency: json['currency'] as String? ?? 'USD',
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      displayOrder: json['display_order'] as int? ?? 0,
      totalEnrollments: json['total_enrollments'] as int? ?? 0,
      totalWishlistAdds: json['total_wishlist_adds'] as int? ?? 0,
      courseDetails: json['course_details'] as Map<String, dynamic>?,
      inWishlist: json['in_wishlist'] as bool? ?? false,
      inCart: json['in_cart'] as bool? ?? false,
    );
  }

  /// Decode HTML entities and fix common text issues in course descriptions
  static String? _decodeHtml(String? html) {
    if (html == null || html.isEmpty) return html;

    // Fix common encoding/OCR issues in course descriptions
    String cleaned = html
        // Fix split words (e.g., "Durati on" → "Duration")
        .replaceAll(RegExp(r'(\w+)\s+([a-z])(?=\s|$)'), r'$1$2')
        // Fix common OCR/copy-paste errors
        .replaceAll(RegExp(r'\s+([,.!?;:])'), r'$1') // Remove space before punctuation
        .replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2') // Add space before capital letters in run-on text
        // Replace common block tags with newlines to preserve some structure
        .replaceAll(RegExp(r'<li>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');

    final htmlTagRegExp =
        RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);

    cleaned = cleaned
        .replaceAll(htmlTagRegExp, '') // Remove remaining tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&#8211;', '-') // En-dash
        .replaceAll('&#8212;', '--') // Em-dash
        .replaceAll('&#8216;', "'") // Left single quote
        .replaceAll('&#8217;', "'") // Right single quote
        .replaceAll('&#8220;', '"') // Left double quote
        .replaceAll('&#8221;', '"') // Right double quote
        .replaceAll('&trade;', '™')
        .replaceAll('&reg;', '®')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Collapse excessive newlines
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    return cleaned;
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

  String? get duration => courseDetails?['duration'] as String?;
  String? get level => courseDetails?['level'] as String?;
  String? get thumbnailUrl => courseDetails?['thumbnail_url'] as String?;
  List<String> get prerequisites {
    if (courseDetails?['prerequisites'] != null) {
      return List<String>.from(courseDetails!['prerequisites'] as List);
    }
    return [];
  }

  CourseCatalogItem copyWith({
    bool? inWishlist,
    bool? inCart,
  }) {
    return CourseCatalogItem(
      id: id,
      contentTypeId: contentTypeId,
      objectId: objectId,
      trainingType: trainingType,
      providerId: providerId,
      providerName: providerName,
      title: title,
      description: description,
      price: price,
      currency: currency,
      isActive: isActive,
      isFeatured: isFeatured,
      displayOrder: displayOrder,
      totalEnrollments: totalEnrollments,
      totalWishlistAdds: totalWishlistAdds,
      courseDetails: courseDetails,
      inWishlist: inWishlist ?? this.inWishlist,
      inCart: inCart ?? this.inCart,
    );
  }

  Course toCourse() {
    return Course(
      id: objectId.toString(),
      title: title,
      description: description,
      price: double.tryParse(price),
      courseType: trainingType,
      featureImageUrl: thumbnailUrl,
      active: isActive,
      isWishlisted: inWishlist,
      isInCart: inCart,
    );
  }
}

class CourseProvider {
  final int id;
  final String name;
  final String code;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final int displayOrder;
  final int? activeCoursesCount;

  CourseProvider({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.logoUrl,
    this.isActive = true,
    this.displayOrder = 0,
    this.activeCoursesCount,
  });

  factory CourseProvider.fromJson(Map<String, dynamic> json) {
    return CourseProvider(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      activeCoursesCount: json['active_courses_count'] as int?,
    );
  }
}
