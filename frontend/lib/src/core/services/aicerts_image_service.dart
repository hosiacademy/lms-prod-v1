// lib/src/core/services/aicerts_image_service.dart

import '../config/environment.dart';

/// AICERTS Image Service
///
/// Handles image URL processing and proxying for AICERTS course images.
/// Solves CORS issues by routing images through the backend proxy.
///
/// **Usage**:
/// ```dart
/// final imageUrl = AICERTSImageService.proxyImageUrl(
///   'https://www.aicerts.ai/badges/ai-foundations.png',
/// );
/// ```
class AICERTSImageService {
  /// Base URL for AICERTS CDN
  static const String _aicertsCdnBase = 'https://www.aicerts.ai';
  
  /// Alternative AICERTS CDN domain
  static const String _aicertsCdnAlt = 'https://cdn.aicerts.ai';

  /// Proxy an AICERTS image URL through the backend
  ///
  /// This bypasses CORS restrictions by routing requests through
  /// the HOSI backend which fetches the image server-side.
  ///
  /// **Parameters**:
  /// - [url]: The original AICERTS image URL
  /// - [forceSvg]: If true, requests SVG format explicitly
  ///
  /// **Returns**: Proxied URL or original URL if not an AICERTS image
  static String? proxyImageUrl(String? url, {bool forceSvg = false}) {
    if (url == null || url.isEmpty) return null;

    // Already proxied - return as is (prevent double-proxying)
    if (url.contains('/proxy/image/')) {
      return url;
    }

    // Already uses alternative proxy like wsrv.nl
    if (url.contains('wsrv.nl')) {
      return url;
    }

    // Check if it's an AICERTS URL
    final isAicertsUrl = url.contains('aicerts.ai');
    if (!isAicertsUrl) {
      return url;
    }

    // Convert to absolute URL if relative
    final absoluteUrl = _toAbsoluteUrl(url);

    // Build proxy URL
    final encodedUrl = Uri.encodeComponent(absoluteUrl);
    var proxiedUrl = '${Environment.apiBaseUrl}/api/v1/courses/masterclasses/proxy/image/?url=$encodedUrl';

    // Add SVG format hint if needed
    if (forceSvg || absoluteUrl.toLowerCase().endsWith('.svg')) {
      proxiedUrl += '&format=svg';
    }

    return proxiedUrl;
  }

  /// Convert relative URL to absolute URL
  static String _toAbsoluteUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // Handle protocol-relative URLs
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    
    // Handle relative URLs
    if (url.startsWith('/')) {
      return '$_aicertsCdnBase$url';
    }
    
    return '$_aicertsCdnBase/$url';
  }

  /// Get feature image URL with proxy
  static String? getFeatureImageUrl(String? url) {
    return proxyImageUrl(url);
  }

  /// Get certificate badge URL with proxy
  static String? getCertificateBadgeUrl(String? url) {
    return proxyImageUrl(url, forceSvg: url?.toLowerCase().endsWith('.svg') ?? false);
  }

  /// Get AI tool logo URL with proxy
  static String? getToolImageUrl(String? url) {
    return proxyImageUrl(url);
  }

  /// Check if URL is from AICERTS domain
  static bool isAicertsUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('aicerts.ai');
  }

  /// Extract image format from URL
  static String getImageFormat(String? url) {
    if (url == null || url.isEmpty) return 'unknown';
    
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.svg') || lowerUrl.contains('format=svg')) {
      return 'svg';
    }
    if (lowerUrl.endsWith('.png')) {
      return 'png';
    }
    if (lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg')) {
      return 'jpeg';
    }
    if (lowerUrl.endsWith('.gif')) {
      return 'gif';
    }
    if (lowerUrl.endsWith('.webp')) {
      return 'webp';
    }
    
    return 'unknown';
  }

  /// Get placeholder image path based on type
  static String getPlaceholderPath(String type) {
    switch (type) {
      case 'certificate':
        return 'assets/images/aicerts/certificate_placeholder.png';
      case 'course':
        return 'assets/images/aicerts/course_placeholder.png';
      case 'tool':
        return 'assets/images/aicerts/tool_placeholder.png';
      default:
        return 'assets/images/default_avatar.png';
    }
  }
}
