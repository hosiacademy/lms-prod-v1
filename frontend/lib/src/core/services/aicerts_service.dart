import 'package:dio/dio.dart';
import '../../data/models/course.dart';
import 'currency_service.dart';
import 'aicerts_image_service.dart';
import '../config/environment.dart';
import '../constants/pricing_constants.dart';

class AICertsService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: Environment.apiBaseUrl,
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 45),
  ));

  static List<AICertsCourse>? _cachedCourses;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(hours: 1);

  static Future<List<Course>> fetchCourses({int retries = 3}) async {
    if (_cachedCourses != null && _cacheTime != null && DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedToCourseList(_cachedCourses!);
    }
    int attempts = 0;
    while (attempts < retries) {
      try {
        attempts++;
        // Use backend API to avoid CORS issues
        final response = await _dio.get('/api/v1/courses/courses/',
          queryParameters: {
            'format': 'json',
            'cb': DateTime.now().millisecondsSinceEpoch.toString(),
          });
        if (response.statusCode == 200) {
          final List<dynamic> rawData = response.data is List ? response.data : [];
          if (rawData.isNotEmpty) {
            final courses = rawData.map((json) {
              try { return AICertsCourse.fromBackendJson(json); } catch (e) { return null; }
            }).where((c) => c != null).cast<AICertsCourse>().toList();
            if (courses.isNotEmpty) {
              _cachedCourses = courses;
              _cacheTime = DateTime.now();
            }
            return _cachedToCourseList(courses);
          }
        }
      } catch (e) {
        if (attempts >= retries) break;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    return _cachedToCourseList(_cachedCourses ?? []);
  }

  /// HARDENED: Convert AICERTS courses to Course list with proper pricing
  /// Prices are calculated from PricingConstants, never from backend
  static List<Course> _cachedToCourseList(List<AICertsCourse> aicertsCourses) {
    return aicertsCourses.map((ac) {
      // Prioritize client-side localization using CurrencyService
      final localPrice = ac.price != null 
          ? CurrencyService.instance.formatUSDAmount(ac.price!)
          : ac.formattedPrice;
      
      return Course(
        id: 'aicerts_${ac.id}',
        title: ac.title,
        externalId: ac.id.toString(),
        description: ac.description,
        featureImageUrl: AICERTSImageService.getFeatureImageUrl(ac.imageUrl),
        certificateBadgeUrl: AICERTSImageService.getCertificateBadgeUrl(ac.certificateImageUrl),
        price: ac.price, 
        localPrice: localPrice,
        localCurrency: CurrencyService.instance.userCurrency,
        courseType: 'aicerts',
        industry: ac.streamType,
      );

    }).toList();
  }

  static Course? findMatchingCourse({
    required String masterclassName,
    required List<Course> courses,
  }) {
    if (masterclassName.isEmpty || courses.isEmpty) return null;
    final normalizedSearch = _normalizeName(masterclassName);
    final masterclassKeywords = _extractKeywords(normalizedSearch);
    Course? bestMatch;
    String? matchedImageUrl;
    String? matchedBadgeUrl;
    int highestMatchCount = 0;
    
    final aicertsList = _cachedCourses ?? [];
    
    for (var course in courses) {
      final matchCount = _countMatchingKeywords(masterclassKeywords, _extractKeywords(_normalizeName(course.title)));
      if (matchCount > highestMatchCount) {
        highestMatchCount = matchCount;
        bestMatch = course;
        
        final acMatch = aicertsList.fold<AICertsCourse?>(null, (p, ac) => p ?? (_normalizeName(ac.title) == _normalizeName(masterclassName) ? ac : null));
        if (acMatch != null) {
          matchedImageUrl = AICERTSImageService.getFeatureImageUrl(acMatch.imageUrl);
          matchedBadgeUrl = AICERTSImageService.getCertificateBadgeUrl(acMatch.certificateImageUrl);
        }
      }
    }
    
    if (highestMatchCount >= 1 && bestMatch != null) {
      if (matchedImageUrl != null) {
        return bestMatch.copyWith();
      }
      return bestMatch;
    }
    return null;
  }

  static String _normalizeName(String name) => name.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');
  static List<String> _extractKeywords(String text) {
    const stopWords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'masterclass', 'course', 'training', 'certification'};
    return text.split(' ').where((w) => w.length > 2 && !stopWords.contains(w)).toList();
  }
  static int _countMatchingKeywords(List<String> list1, List<String> list2) => list1.where((k) => list2.contains(k)).length;
}

class AICertsCourse {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? certificateImageUrl;
  final String? streamType; // 'technical' or 'professional'
  // Price from backend (localized) or external API
  final double? price;
  final String? formattedPrice;

  AICertsCourse({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.certificateImageUrl,
    this.streamType,
    this.price,
    this.formattedPrice,
  });

  /// Parse from external AICERTS API (www.aicerts.ai/wp-json/aicerts-api/v1/courses)
  factory AICertsCourse.fromJson(Map<String, dynamic> json) {
    String? extractImageUrl(Map<String, dynamic> j) {
      return j['feature_image_url'] as String? ??
             j['image_url'] as String? ??
             j['featured_media_url'] as String? ??
             j['featured_image_url'] as String?;
    }

    String? extractBadgeUrl(Map<String, dynamic> j) {
      return j['badge_url'] as String? ??
             j['certificate_badge_url'] as String? ??
             j['certificate_url'] as String?;
    }

    final htmlTagRegExp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    
    // Extract stream type from course data
    String? streamType = json['stream_type'] as String?;
    if (streamType == null) {
      // Try to infer from course title/tags
      final titleLower = json['title']?.toString().toLowerCase() ?? '';
      if (titleLower.contains('technical') || 
          titleLower.contains('developer') ||
          titleLower.contains('engineering')) {
        streamType = 'technical';
      } else if (titleLower.contains('professional') ||
                 titleLower.contains('business') ||
                 titleLower.contains('management')) {
        streamType = 'professional';
      } else {
        streamType = 'professional'; // Default
      }
    }
    
    return AICertsCourse(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: (json['title']['rendered'] as String).replaceAll('&amp;', '&').replaceAll('&quot;', '"').replaceAll('&#039;', "'"),
      description: (json['content']['rendered'] as String).replaceAll(htmlTagRegExp, '').trim(),
      imageUrl: extractImageUrl(json),
      certificateImageUrl: extractBadgeUrl(json),
      streamType: streamType,
      price: null, 
      formattedPrice: null,
    );
  }

  /// Parse from backend Django API (/api/v1/courses/courses/)
  factory AICertsCourse.fromBackendJson(Map<String, dynamic> json) {
    // Extract stream type - check various field names
    String? streamType = json['stream_type'] as String? ?? 
                         json['type'] as String? ??
                         json['category'] as String?;
    
    if (streamType == null) {
      // Try to infer from title
      final titleLower = (json['title'] as String? ?? '').toLowerCase();
      if (titleLower.contains('technical') || 
          titleLower.contains('developer') ||
          titleLower.contains('engineering')) {
        streamType = 'technical';
      } else {
        streamType = 'professional'; // Default
      }
    }
    
    return AICertsCourse(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? json['shortname'] as String? ?? 'Unknown Course',
      description: (json['description'] as String? ?? json['summary'] as String? ?? '').replaceAll(RegExp(r'<[^>]*>'), ''),
      imageUrl: json['feature_image_url'] as String? ?? json['certificate_badge_url'] as String?,
      certificateImageUrl: json['certificate_badge_url'] as String?,
      streamType: streamType,
      price: json['our_price_usd'] != null ? double.tryParse(json['our_price_usd'].toString()) :
             json['price_usd'] != null ? double.tryParse(json['price_usd'].toString()) :
             json['price_individual'] != null ? double.tryParse(json['price_individual'].toString()) : null,
      formattedPrice: json['formatted_price'] as String?,
    );
  }
}
