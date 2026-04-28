// lib/src/presentation/widgets/aicerts/aicerts_image_widget.dart

import 'package:flutter/material.dart';
import '../../../core/services/aicerts_image_service.dart';
import '../../pages/onboarding/widgets/sections/safe_network_image.dart';

/// AICERTS Image Widget
///
/// Specialized image widget for rendering AICERTS course images with:
/// - Automatic proxy URL conversion for CORS bypass
/// - SVG support for certificate badges
/// - Graceful loading and error states
/// - Customizable placeholders
///
/// **Usage**:
/// ```dart
/// AICERTSImageWidget(
///   imageUrl: course.featureImageUrl,
///   imageType: AICERTSImageType.course,
///   width: 300,
///   height: 200,
/// )
/// ```
enum AICERTSImageType {
  course,
  certificate,
  tool,
  thumbnail,
}

class AICERTSImageWidget extends StatelessWidget {
  /// The original AICERTS image URL (will be proxied automatically)
  final String? imageUrl;
  
  /// Type of image for appropriate placeholder and styling
  final AICERTSImageType imageType;
  
  /// Width constraint (optional)
  final double? width;
  
  /// Height constraint (optional)
  final double? height;
  
  /// How to fit the image within bounds
  final BoxFit fit;
  
  /// Custom placeholder widget (overrides default)
  final Widget? placeholder;
  
  /// Custom error widget (overrides default)
  final Widget? errorWidget;
  
  /// Whether to force SVG rendering
  final bool forceSvg;
  
  /// Border radius for rounded corners
  final BorderRadius? borderRadius;
  
  /// Border to apply
  final Border? border;
  
  /// Shadow to apply
  final List<BoxShadow>? shadows;
  
  /// Callback when image loads successfully
  final VoidCallback? onLoad;
  
  /// Callback when image fails to load
  final VoidCallback? onError;

  const AICERTSImageWidget({
    super.key,
    this.imageUrl,
    this.imageType = AICERTSImageType.course,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.forceSvg = false,
    this.borderRadius,
    this.border,
    this.shadows,
    this.onLoad,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    // Get proxied URL
    final proxiedUrl = AICERTSImageService.proxyImageUrl(
      imageUrl,
      forceSvg: forceSvg || imageType == AICERTSImageType.certificate,
    );

    // Check if it's an SVG
    final isSvg = (proxiedUrl?.toLowerCase().endsWith('.svg') ?? false) ||
                  (proxiedUrl?.contains('format=svg') ?? false);

    // Create container with constraints and styling
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border,
        boxShadow: shadows,
        color: Colors.transparent,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(proxiedUrl, isSvg, context),
    );
  }

  Widget _buildImage(String? url, bool isSvg, BuildContext context) {
    if (url == null || url.isEmpty) {
      return _buildPlaceholder(context);
    }

    if (isSvg || forceSvg) {
      // Use AuthenticatedSvgImage to fetch SVG bytes via Dio then render with
      // SvgPicture.memory — more reliable than SvgPicture.network for SVGs that
      // use CSS class selectors in <style> blocks (as AICerts SVGs do).
      return AuthenticatedSvgImage(
        originalUrl: url,
        fit: fit,
        width: width,
        height: height,
      );
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          onLoad?.call();
          return child;
        }
        return placeholder ?? _buildLoadingIndicator(context, loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        onError?.call();
        return errorWidget ?? _buildErrorWidget(context, error);
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) {
      return placeholder!;
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final iconSize = width != null ? width! * 0.3 : 48.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPlaceholderIcon(),
            size: iconSize,
            color: colors.primary.withValues(alpha: 0.3),
          ),
          if (imageType == AICERTSImageType.course || 
              imageType == AICERTSImageType.certificate)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _getPlaceholderText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(
    BuildContext context, 
    ImageChunkEvent loadingProgress
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 3,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    if (errorWidget != null) {
      return errorWidget!;
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: colors.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPlaceholderIcon() {
    switch (imageType) {
      case AICERTSImageType.course:
        return Icons.school;
      case AICERTSImageType.certificate:
        return Icons.verified;
      case AICERTSImageType.tool:
        return Icons.build;
      case AICERTSImageType.thumbnail:
        return Icons.image;
    }
  }

  String _getPlaceholderText() {
    switch (imageType) {
      case AICERTSImageType.course:
        return 'Course Image';
      case AICERTSImageType.certificate:
        return 'Certificate Badge';
      case AICERTSImageType.tool:
        return 'Tool Logo';
      case AICERTSImageType.thumbnail:
        return 'Thumbnail';
    }
  }
}

/// AICERTS Course Card Image
///
/// Specialized widget for displaying course card images with
/// certificate badge overlay support
class AICERTSCourseCardImage extends StatelessWidget {
  final String? featureImageUrl;
  final String? certificateBadgeUrl;
  final double width;
  final double height;
  final bool showBadge;
  final BoxFit fit;

  const AICERTSCourseCardImage({
    super.key,
    this.featureImageUrl,
    this.certificateBadgeUrl,
    this.width = 340,
    this.height = 200,
    this.showBadge = true,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AICERTSImageWidget(
              imageUrl: featureImageUrl,
              imageType: AICERTSImageType.course,
              width: width,
              height: height,
              fit: fit,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        
        // Certificate badge overlay (top-right corner)
        if (showBadge && certificateBadgeUrl != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              padding: EdgeInsets.zero,
              child: AICERTSImageWidget(
                imageUrl: certificateBadgeUrl,
                imageType: AICERTSImageType.certificate,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                forceSvg: true,
              ),
            ),
          ),
      ],
    );
  }
}

/// AICERTS Certificate Badge Widget
///
/// Displays certificate badge with proper SVG rendering
class AICERTSCertificateBadge extends StatelessWidget {
  final String? badgeUrl;
  final double size;
  final bool showTooltip;

  const AICERTSCertificateBadge({
    super.key,
    this.badgeUrl,
    this.size = 64,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: showTooltip ? 'AICERTS Certified Course' : '',
      child: AICERTSImageWidget(
        imageUrl: badgeUrl,
        imageType: AICERTSImageType.certificate,
        width: size,
        height: size,
        fit: BoxFit.contain,
        forceSvg: true,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// AICERTS AI Tool Logo Widget
///
/// Displays AI tool logos from course data
class AICERTSAIToolLogo extends StatelessWidget {
  final String? toolImageUrl;
  final double size;
  final String? toolName;

  const AICERTSAIToolLogo({
    super.key,
    this.toolImageUrl,
    this.size = 40,
    this.toolName,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: toolName ?? 'AI Tool',
      child: AICERTSImageWidget(
        imageUrl: toolImageUrl,
        imageType: AICERTSImageType.tool,
        width: size,
        height: size,
        fit: BoxFit.contain,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
