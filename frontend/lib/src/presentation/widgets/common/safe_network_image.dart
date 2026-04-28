import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/environment.dart';

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final double? width;
  final double? height;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  bool get _isSvg =>
      imageUrl.toLowerCase().endsWith('.svg') ||
      imageUrl.contains('format=svg');

  /// Detects if this is reaching out to AICerts directly and needs a proxy
  bool get _isAICertsRaw =>
      imageUrl.contains('aicerts.ai') && !imageUrl.contains('proxy/image');

  String get _effectiveUrl {
    if (!_isAICertsRaw) return imageUrl;

    final absoluteUrl = imageUrl.startsWith('http')
        ? imageUrl
        : 'https://www.aicerts.ai${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';

    final proxyBase = Environment.apiBaseUrl;
    var proxied =
        '$proxyBase/api/v1/courses/masterclasses/proxy/image/?url=${Uri.encodeComponent(absoluteUrl)}';

    if (absoluteUrl.toLowerCase().endsWith('.svg')) {
      proxied += '&format=svg';
    }
    return proxied;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = _effectiveUrl;

    // Use specialized authenticated fetch for AICerts SVGs
    if (_isSvg &&
        (effectiveUrl.contains('aicerts.ai') ||
            effectiveUrl.contains('proxy/image'))) {
      // Extract original URL if already proxied
      String targetUrl = effectiveUrl;
      if (effectiveUrl.contains('url=')) {
        final uri = Uri.parse(effectiveUrl);
        targetUrl = uri.queryParameters['url'] ?? effectiveUrl;
      }

      return AuthenticatedSvgImage(
        originalUrl: targetUrl,
        fit: fit ?? BoxFit.contain,
        width: width,
        height: height,
      );
    }

    if (_isSvg) {
      return SvgPicture.network(
        effectiveUrl,
        fit: fit ?? BoxFit.contain,
        width: width,
        height: height,
        placeholderBuilder: (context) => _buildPlaceholder(context),
        errorBuilder: (context, error, stackTrace) => _buildError(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: effectiveUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder ?? (context, url) => _buildPlaceholder(context),
      errorWidget: errorWidget ?? (context, url, error) => _buildError(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!(context, imageUrl);
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.primary,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    if (errorWidget != null) return errorWidget!(context, imageUrl, 'Error');
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported,
        size: 32,
        color: colors.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

// ─── SVG cache shared across all AuthenticatedSvgImage instances ─────────────
final Map<String, Uint8List> _svgBytesCache = {};

/// Fetches an AICERTS SVG image through the authenticated proxy endpoint,
/// using [ApiClient] so the Bearer token is included automatically.
/// Results are cached in memory for the session lifetime.
class AuthenticatedSvgImage extends StatefulWidget {
  final String originalUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AuthenticatedSvgImage({
    super.key,
    required this.originalUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  State<AuthenticatedSvgImage> createState() => _AuthenticatedSvgImageState();
}

class _AuthenticatedSvgImageState extends State<AuthenticatedSvgImage> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_svgBytesCache.containsKey(widget.originalUrl)) {
      if (mounted) {
        setState(() {
          _bytes = _svgBytesCache[widget.originalUrl];
          _loading = false;
        });
      }
      return;
    }

    try {
      final response = await ApiClient.get(
        '/api/v1/courses/masterclasses/proxy/image/',
        queryParameters: {'url': widget.originalUrl},
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        Uint8List bytes;
        final data = response.data;
        if (data is Uint8List) {
          bytes = data;
        } else if (data is List) {
          bytes = Uint8List.fromList(List<int>.from(data));
        } else if (data is String) {
          bytes = Uint8List.fromList(utf8.encode(data));
        } else {
          throw Exception('Unexpected response type: ${data.runtimeType}');
        }
        _svgBytesCache[widget.originalUrl] = bytes;
        if (mounted)
          setState(() {
            _bytes = bytes;
            _loading = false;
          });
      } else {
        if (mounted)
          setState(() {
            _failed = true;
            _loading = false;
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _failed = true;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_loading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    if (_failed || _bytes == null) {
      return Center(
        child: Icon(
          Icons.school_rounded,
          size: 48,
          color: colors.primary.withValues(alpha: 0.3),
        ),
      );
    }

    return SvgPicture.memory(
      _bytes!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
    );
  }
}
