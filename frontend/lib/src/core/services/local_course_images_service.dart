// lib/src/core/services/local_course_images_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

/// Service to manage local course images (avoids CORS issues with remote SVGs)
class LocalCourseImagesService {
  static Map<String, CourseImageMapping>? _imageCache;
  static bool _isInitialized = false;

  /// Initialize the service by loading the JSON mapping file
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Loading local course images mapping...');
      final String jsonString = await rootBundle.loadString('assets/data/course_images.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      _imageCache = {};
      final courses = data['courses'] as List;

      for (var course in courses) {
        final mapping = CourseImageMapping.fromJson(course);
        _imageCache![mapping.sourceName.toLowerCase()] = mapping;

        // Also cache by slug (normalized title)
        final slug = _normalizeTitle(mapping.sourceName);
        _imageCache![slug] = mapping;
      }

      _isInitialized = true;
      print('Loaded ${courses.length} course image mappings');
    } catch (e) {
      print('Error loading course images mapping: $e');
      _imageCache = {};
    }
  }

  /// Get local image path for a course by its title
  /// Returns PNG path by default, or SVG if useSvg=true
  static String? getLocalImagePath(String courseTitle, {bool useSvg = false}) {
    if (!_isInitialized || _imageCache == null) {
      print('Warning: LocalCourseImagesService not initialized');
      return null;
    }

    // Try exact match first
    final normalized = courseTitle.toLowerCase();
    CourseImageMapping? mapping = _imageCache![normalized];

    // Try slug match
    if (mapping == null) {
      final slug = _normalizeTitle(courseTitle);
      mapping = _imageCache![slug];
    }

    // Try fuzzy match
    if (mapping == null) {
      mapping = _findBestMatch(courseTitle);
    }

    if (mapping != null) {
      final path = useSvg ? mapping.localSvg : mapping.localPng;
      print('Found local image for "$courseTitle": $path');
      return path;
    }

    print('No local image found for "$courseTitle"');
    return null;
  }

  /// Find best matching course by comparing keywords
  static CourseImageMapping? _findBestMatch(String title) {
    if (_imageCache == null || _imageCache!.isEmpty) return null;

    final keywords = _extractKeywords(title);
    CourseImageMapping? bestMatch;
    int highestScore = 0;

    for (var mapping in _imageCache!.values) {
      final mappingKeywords = _extractKeywords(mapping.sourceName);
      final score = _countMatchingKeywords(keywords, mappingKeywords);

      if (score > highestScore) {
        highestScore = score;
        bestMatch = mapping;
      }
    }

    // Require at least 2 matching keywords
    return highestScore >= 2 ? bestMatch : null;
  }

  /// Normalize title to slug format
  static String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  /// Extract keywords from title
  static Set<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toSet();
  }

  /// Count matching keywords
  static int _countMatchingKeywords(Set<String> keywords1, Set<String> keywords2) {
    return keywords1.intersection(keywords2).length;
  }

  /// Get all available course image mappings
  static List<CourseImageMapping> getAllMappings() {
    if (!_isInitialized || _imageCache == null) return [];
    return _imageCache!.values.toSet().toList();
  }

  /// Clear cache and force reload
  static void clearCache() {
    _imageCache = null;
    _isInitialized = false;
  }
}

/// Model for course image mapping
class CourseImageMapping {
  final String sourceName;
  final String sourceUrl;
  final String localSvg;
  final String localPng;

  CourseImageMapping({
    required this.sourceName,
    required this.sourceUrl,
    required this.localSvg,
    required this.localPng,
  });

  factory CourseImageMapping.fromJson(Map<String, dynamic> json) {
    return CourseImageMapping(
      sourceName: json['source_name'] as String,
      sourceUrl: json['source_url'] as String,
      localSvg: json['local_svg'] as String,
      localPng: json['local_png'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_name': sourceName,
      'source_url': sourceUrl,
      'local_svg': localSvg,
      'local_png': localPng,
    };
  }
}
