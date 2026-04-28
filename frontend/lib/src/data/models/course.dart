import '../../core/config/environment.dart';

class Course {
  final String id;
  final String title;
  final String? featureImageUrl;
  final String? featureImageJpgUrl;
  final String? certificateBadgeUrl;
  final String? certificateImageJpgUrl;
  final List<Map<String, dynamic>> aiTools;
  final String? description;
  final String? industry;
  final String? certificationLevel;
  final String? roleType;
  final String? country;
  final String? countryCode;
  final String? city;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final double? price;
  final int? durationHours;
  final bool? active;
  final String? streamType; // 'professional' or 'technical'
  final String? externalId;

  // Course type for enrollment routing
  final String?
      courseType; // 'masterclass', 'learnership', 'industry_training', 'custom_selection'

  // New fields for enhanced UI
  final double? rating;
  final int? studentCount;
  final String? instructorName;
  final String? instructorAvatar;
  final bool isWishlisted;
  final bool isInCart;

  Course({
    required this.id,
    required this.title,
    this.externalId,
    this.featureImageUrl,
    this.featureImageJpgUrl,
    this.certificateBadgeUrl,
    this.certificateImageJpgUrl,
    this.aiTools = const [],
    this.description,
    this.industry,
    this.certificationLevel,
    this.roleType,
    this.country,
    this.countryCode,
    this.city,
    this.startDate,
    this.endDate,
    this.status,
    this.price,
    this.durationHours,
    this.active,
    this.streamType,
    this.courseType,
    this.rating,
    this.studentCount,
    this.instructorName,
    this.instructorAvatar,
    this.isWishlisted = false,
    this.isInCart = false,
    this.localPrice,
    this.localCurrency,
    this.pricePackage,
    this.packageName,
    this.isInPackage = false,
  });

  // Localized pricing
  final String? localPrice;
  final String? localCurrency;

  // Package info
  final double? pricePackage;
  final String? packageName;
  final bool isInPackage;

  factory Course.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }

    // Route SVG through Django proxy (same-origin = no CORS).
    // AICERTSImageWidget detects &format=svg → AuthenticatedSvgImage → SvgPicture.memory
    String? rawImageUrl = (json['feature_image_url'] ?? json['image_url'] ?? json['image']) as String?;
    String? proxiedImageUrl = rawImageUrl;

    // Helper: make a relative proxy path absolute using the API base URL
    String? _makeAbsolute(String? url) {
      if (url == null || url.isEmpty) return url;
      // Already absolute
      if (url.startsWith('http://') || url.startsWith('https://')) return url;
      // Relative proxy path — prepend the API origin
      if (url.startsWith('/')) {
        return '${Environment.apiBaseUrl}$url';
      }
      return url;
    }

    if (proxiedImageUrl != null &&
        proxiedImageUrl.contains('aicerts.ai') &&
        !proxiedImageUrl.contains('proxy/image')) {
      final absoluteUrl = proxiedImageUrl.startsWith('http')
          ? proxiedImageUrl
          : 'https://www.aicerts.ai${proxiedImageUrl.startsWith('/') ? '' : '/'}$proxiedImageUrl';
      final proxyBase = Environment.apiBaseUrl;
      proxiedImageUrl =
          '$proxyBase/api/v1/courses/masterclasses/proxy/image/?url=${Uri.encodeComponent(absoluteUrl)}';
      if (absoluteUrl.toLowerCase().endsWith('.svg')) {
        proxiedImageUrl += '&format=svg';
      }
    } else {
      // Already a proxy path — just make it absolute
      proxiedImageUrl = _makeAbsolute(proxiedImageUrl);
    }

    // Also fix the certificate badge URL
    final rawBadgeUrl = json['certificate_badge_url'] as String?;
    final fixedBadgeUrl = _makeAbsolute(rawBadgeUrl);

    final aiToolsRaw = json['ai_tools'] as List<dynamic>? ?? [];
    final aiTools = aiToolsRaw.whereType<Map<String, dynamic>>().toList();

    return Course(
      id: json['id']?.toString() ?? json['lms_course_id']?.toString() ?? '',
      title: json['title'] as String? ??
          json['name'] as String? ??
          'Untitled Course',
      externalId: json['external_id']?.toString(),
      featureImageUrl: proxiedImageUrl,
      featureImageJpgUrl: json['feature_image_jpg_url'] as String?,
      certificateBadgeUrl: fixedBadgeUrl,
      certificateImageJpgUrl: json['certificate_image_jpg_url'] as String?,
      aiTools: aiTools,
      description: _decodeHtml(json['description'] as String?),
      industry: json['industry'] as String?,
      certificationLevel: json['certification_level'] as String?,
      roleType: json['role_type'] as String?,
      country: json['country'] as String?,
      countryCode: json['country_code'] as String?,
      city: json['city'] as String?,
      startDate: parseDate(json['start_date'] as String?),
      endDate: parseDate(json['end_date'] as String?),
      status: json['status'] as String?,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : json['price_usd'] != null
              ? double.tryParse(json['price_usd'].toString())
              : json['our_price_usd'] != null
                  ? double.tryParse(json['our_price_usd'].toString())
                  : null,
      durationHours: json['duration_hours'] as int? ?? json['duration'] as int?,
      active: json['active'] as bool?,
      streamType: json['stream_type'] as String? ?? json['stream'] as String?,
      courseType:
          json['course_type'] as String? ?? json['training_type'] as String?,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      studentCount:
          json['student_count'] as int? ?? json['students_count'] as int?,
      instructorName:
          json['instructor_name'] as String? ?? json['instructor'] as String?,
      instructorAvatar: json['instructor_avatar'] as String?,
      isWishlisted: json['is_wishlisted'] as bool? ?? false,
      isInCart: json['is_in_cart'] as bool? ?? false,
      localPrice: json['local_price']?.toString() ??
          json['formatted_price']?.toString(),
      localCurrency:
          json['local_currency']?.toString() ?? json['currency']?.toString(),
      pricePackage: json['price_package'] != null
          ? double.tryParse(json['price_package'].toString())
          : null,
      packageName: json['package_name'] as String?,
      isInPackage: json['is_in_package'] as bool? ?? false,
    );
  }

  // Helper getters
  String get displayTitle => _decodeHtml(title);

  static String _decodeHtml(String? html) {
    if (html == null || html.isEmpty) return html ?? '';

    // First: Fix common encoding/OCR issues in course descriptions
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

  bool get isUpcoming {
    if (startDate == null) return false;
    return startDate!.isAfter(DateTime.now());
  }

  bool get isEnrollmentOpen {
    if (status == 'closed') return false;
    if (endDate != null && endDate!.isBefore(DateTime.now())) return false;
    return status == 'open' || status == null;
  }

  // Copy with method for updating wishlist/cart status
  Course copyWith({
    bool? isWishlisted,
    bool? isInCart,
    double? rating,
    int? studentCount,
    String? localPrice,
    String? localCurrency,
  }) {
    return Course(
      id: id,
      title: title,
      externalId: externalId,
      featureImageUrl: featureImageUrl,
      featureImageJpgUrl: featureImageJpgUrl,
      certificateBadgeUrl: certificateBadgeUrl,
      certificateImageJpgUrl: certificateImageJpgUrl,
      aiTools: aiTools,
      description: description,
      industry: industry,
      certificationLevel: certificationLevel,
      roleType: roleType,
      country: country,
      countryCode: countryCode,
      city: city,
      startDate: startDate,
      endDate: endDate,
      status: status,
      price: price,
      durationHours: durationHours,
      active: active,
      streamType: streamType,
      courseType: courseType,
      rating: rating ?? this.rating,
      studentCount: studentCount ?? this.studentCount,
      instructorName: instructorName,
      instructorAvatar: instructorAvatar,
      isWishlisted: isWishlisted ?? this.isWishlisted,
      isInCart: isInCart ?? this.isInCart,
      localPrice: localPrice ?? this.localPrice,
      localCurrency: localCurrency ?? this.localCurrency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'external_id': externalId,
      'feature_image_url': featureImageUrl,
      'certificate_badge_url': certificateBadgeUrl,
      'description': description,
      'industry': industry,
      'certification_level': certificationLevel,
      'role_type': roleType,
      'country': country,
      'country_code': countryCode,
      'city': city,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'price': price,
      'duration_hours': durationHours,
      'active': active,
      'stream_type': streamType,
      'course_type': courseType,
      'rating': rating,
      'student_count': studentCount,
      'instructor_name': instructorName,
      'instructor_avatar': instructorAvatar,
      'is_wishlisted': isWishlisted,
      'is_in_cart': isInCart,
      'local_price': localPrice,
      'local_currency': localCurrency,
    };
  }

  // Optional: add toString() for easier debugging
  @override
  String toString() {
    return 'Course(id: $id, title: $title, image: $featureImageUrl)';
  }
}
