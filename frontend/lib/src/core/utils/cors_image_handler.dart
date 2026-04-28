// lib/src/core/utils/cors_image_handler.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// CORS-Aware Image Handler
///
/// Handles image loading with CORS error handling and fallbacks
/// **Use Case**: Loading images from external domains that may have CORS restrictions
///
/// **Problem**: When loading images from aicerts.ai or other external domains,
/// browser CORS policy may block the request if proper headers are not configured
///
/// **Solution**: This utility provides fallback mechanisms:
/// 1. Try to load from external URL (requires CORS headers)
/// 2. Fall back to local cached asset if available
/// 3. Fall back to themed placeholder icon
class CORSImageHandler {
  /// Load image with CORS handling and fallbacks
  ///
  /// **Parameters**:
  /// - imageUrl: External image URL (may be blocked by CORS)
  /// - localAssetPath: Optional local fallback asset path
  /// - fallbackIcon: Icon to show if both external and local fail
  /// - fallbackColor: Color for fallback icon
  ///
  /// **Example**:
  /// ```dart
  /// CORSImageHandler.loadImage(
  ///   imageUrl: 'https://www.aicerts.ai/badges/ai-cert.svg',
  ///   localAssetPath: 'assets/images/courses/ai-cert.png',
  ///   fallbackIcon: Icons.school,
  /// )
  /// ```
  static Widget loadImage({
    String? imageUrl,
    String? localAssetPath,
    IconData fallbackIcon = Icons.school,
    Color? fallbackColor,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    // Priority 1: Try local asset first (no CORS issues)
    if (localAssetPath != null) {
      return _buildLocalImage(
        assetPath: localAssetPath,
        fallbackIcon: fallbackIcon,
        fallbackColor: fallbackColor,
        fit: fit,
        width: width,
        height: height,
      );
    }

    // Priority 2: Try external URL (may have CORS issues)
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return _buildNetworkImage(
        imageUrl: imageUrl,
        fallbackIcon: fallbackIcon,
        fallbackColor: fallbackColor,
        fit: fit,
        width: width,
        height: height,
      );
    }

    // Priority 3: Fallback icon
    return _buildFallbackIcon(
      icon: fallbackIcon,
      color: fallbackColor,
      size: height ?? width ?? 48,
    );
  }

  /// Build local asset image with fallback
  static Widget _buildLocalImage({
    required String assetPath,
    required IconData fallbackIcon,
    Color? fallbackColor,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: (context) => _buildFallbackIcon(
          icon: fallbackIcon,
          color: fallbackColor,
          size: height ?? width ?? 48,
        ),
      );
    }
    return Image.asset(
      assetPath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        // Local asset not found, show fallback
        return _buildFallbackIcon(
          icon: fallbackIcon,
          color: fallbackColor,
          size: height ?? width ?? 48,
        );
      },
    );
  }

  /// Build network image with CORS error handling
  static Widget _buildNetworkImage({
    required String imageUrl,
    required IconData fallbackIcon,
    Color? fallbackColor,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    final isSvg = imageUrl.toLowerCase().endsWith('.svg') ||
        imageUrl.contains('format=svg');

    if (isSvg) {
      return SvgPicture.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: (context) => _buildFallbackIcon(
          icon: fallbackIcon,
          color: fallbackColor,
          size: height ?? width ?? 48,
        ),
      );
    }

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          width: width,
          height: height,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            // Check if error is CORS-related
            final isCORSError = error.toString().contains('CORS') ||
                error.toString().contains('XMLHttpRequest') ||
                error.toString().contains('cross-origin');

            if (isCORSError) {
              print('⚠️ CORS ERROR: Cannot load image from $url');
              print('   AICERTS team must configure CORS headers.');
            }

            // Show fallback icon with CORS warning indicator
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCORSError
                      ? colors.error.withValues(alpha: 0.3)
                      : colors.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    fallbackIcon,
                    size: (height ?? width ?? 48) * 0.6,
                    color: fallbackColor ?? colors.onSurface,
                  ),
                  if (isCORSError) ...[
                    const SizedBox(height: 4),
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: colors.error,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build fallback icon
  static Widget _buildFallbackIcon({
    required IconData icon,
    Color? color,
    required double size,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.6,
              color: color ?? colors.onSurface,
            ),
          ),
        );
      },
    );
  }

  /// Check if image URL is from external domain (may have CORS issues)
  static bool isExternalUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    // Check if URL is from external domain
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Check if image URL is from AICERTS domain
  static bool isAICERTSUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    return url.contains('aicerts.ai');
  }

  /// Get local asset path for AICERTS course badge (if exists)
  ///
  /// **Example**:
  /// ```dart
  /// final localPath = CORSImageHandler.getLocalAICERTSBadge(
  ///   'https://www.aicerts.ai/badges/ai-context-engineering.svg'
  /// );
  /// // Returns: 'assets/images/courses/ai-context-engineering.png'
  /// ```
  static String? getLocalAICERTSBadge(String aicertsUrl) {
    // Extract course name from URL
    // Example: https://www.aicerts.ai/wp-content/uploads/.../AIC_AI-Context-Engineering.svg
    // Or proxied: .../proxy/image/?url=https%3A%2F%2Fwww.aicerts.ai%2F...%2FAIC_AI-Context-Engineering.svg

    String decodedUrl = aicertsUrl;
    if (aicertsUrl.contains('url=')) {
      final parts = aicertsUrl.split('url=');
      if (parts.length > 1) {
        decodedUrl = Uri.decodeComponent(parts[1].split('&').first);
      }
    }

    final filename = decodedUrl.split('/').last.split('.').first;

    // Convert to local asset path
    // Map AICERTS filenames (from URL) to local asset names (in assets/images/courses/)
    final courseNameMap = {
      // 10 Fixed SVGs from user
      'AIC_AI-Agent': 'ai-agent',
      'AIC_AI-Context-Engineering': 'ai-context-engineering',
      'AIC_AI-Healthcare-Administrator': 'ai-healthcare-administrator',
      'AIC_AI-Pharma': 'ai-pharma',
      'AIC_AI-Program-Director': 'ai-program-director-8211-practitioner',
      'AIC_AI-Project-Management-Practitioner':
          'ai-project-management-practitioner',
      'AIC_AI-Real-Estate': 'ai-real-estate',
      'AIC_AI-Sustainability': 'ai-sustainability',
      'AIC_AI-Vibe-Coder': 'ai-vibe-coder',
      'AIC_Practitioners-Playbook-for-RSAIF':
          'practitioners-playbook-for-rsaif-',

      // Additional/Legacy mappings
      'AIC_AI-Marketing': 'ai-marketing',
      'AIC_Blockchain-Fundamentals': 'blockchain-fundamentals',
      'AIC_AI-Executive-Leadership': 'ai-executive-leadership',
      'AIC_Ethical-Hacker': 'ethical-hacker',
      'AIC_AI-Product-Management': 'ai-product-management',
      'AIC_Data-Science': 'data-science',
      'AIC_AI-Sales': 'ai-sales',
      'AIC_RSAIF-Playbook': 'practitioners-playbook-for-rsaif-',
      'AIC_RSAIF': 'practitioners-playbook-for-rsaif-',
    };

    final localName = courseNameMap[filename] ??
        courseNameMap[filename.replaceAll('AIC_', '')];
    if (localName != null) {
      // Prefer SVG since they are fixed, then fallback to PNG
      return 'assets/images/courses/$localName.svg';
    }

    return null;
  }
}
