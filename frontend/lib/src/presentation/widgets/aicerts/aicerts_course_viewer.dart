// lib/src/presentation/widgets/aicerts/aicerts_course_viewer.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/aicerts_config.dart';

/// AICERTS Course Viewer
///
/// Displays AICERTS course content inline using iFrame/WebView
/// with SSO authentication for seamless user experience.
///
/// **Features**:
/// - Embedded mode (no AICERTS header/footer)
/// - SSO authentication (no additional login)
/// - Progress tracking via postMessage
/// - Full-screen course display within HOSI portal
///
/// **Usage**:
/// ```dart
/// AICERTSCourseViewer(
///   courseId: 123,
///   userId: 'user@example.com',
///   onProgressUpdate: (progress) {
///     print('Course progress: $progress%');
///   },
/// )
/// ```
class AICERTSCourseViewer extends StatefulWidget {
  final int courseId;
  final String userId; // AICERTS user ID or email
  final String? userName;
  final Function(double progress)? onProgressUpdate;
  final Function()? onCourseComplete;
  final Function()? onBack;

  const AICERTSCourseViewer({
    super.key,
    required this.courseId,
    required this.userId,
    this.userName,
    this.onProgressUpdate,
    this.onCourseComplete,
    this.onBack,
  });

  @override
  State<AICERTSCourseViewer> createState() => _AICERTSCourseViewerState();
}

class _AICERTSCourseViewerState extends State<AICERTSCourseViewer> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _error;
  double _progress = 0.0;

  // AICERTS Partner Credentials (from centralized config)
  static final String _partnerId = AICERTSConfig.partnerId;
  static final String _wsToken = AICERTSConfig.wsToken;
  static final String _secretKey = AICERTSConfig.secretKey;
  static final String _aicertsLmsUrl = AICERTSConfig.lmsUrl;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    final ssoUrl = _generateSSOUrl();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Inject JavaScript to listen for progress updates
            _webViewController.runJavaScript('''
              // Listen for AICERTS progress updates
              window.addEventListener('message', function(event) {
                if (event.origin === '$_aicertsLmsUrl') {
                  if (event.data.type === 'progress') {
                    window.flutter_inappwebview.callHandler('progressUpdate', event.data.progress);
                  } else if (event.data.type === 'complete') {
                    window.flutter_inappwebview.callHandler('courseComplete');
                  }
                }
              });

              // Notify AICERTS that we're ready for messages
              if (window.parent) {
                window.parent.postMessage({type: 'ready'}, '$_aicertsLmsUrl');
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = 'Failed to load course: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'progressUpdate',
        onMessageReceived: (JavaScriptMessage message) {
          final progress = double.tryParse(message.message) ?? 0.0;
          setState(() {
            _progress = progress;
          });
          widget.onProgressUpdate?.call(progress);
        },
      )
      ..addJavaScriptChannel(
        'courseComplete',
        onMessageReceived: (JavaScriptMessage message) {
          widget.onCourseComplete?.call();
        },
      )
      ..loadRequest(Uri.parse(ssoUrl));
  }

  /// Generate SSO URL with authentication token
  ///
  /// Format: https://learn.aicerts.io/webservice/rest/server.php
  ///         ?wsfunction=local_myauthplugin_authenticate_user
  ///         &username={userId}
  ///         &timestamp={timestamp}
  ///         &signature={hmac_signature}
  ///         &partner_id=262
  ///         &courseid={courseId}
  ///         &embedded=true
  String _generateSSOUrl() {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signature = _generateHMACSignature(widget.userId, timestamp);

    // Build SSO URL
    final queryParams = {
      'wsfunction': 'local_myauthplugin_authenticate_user',
      'username': widget.userId,
      'timestamp': timestamp.toString(),
      'signature': signature,
      'partner_id': _partnerId,
      'courseid': widget.courseId.toString(),
      'embedded': 'true', // Tell AICERTS to hide header/footer
      'moodlewsrestformat': 'json',
    };

    final uri = Uri.parse('$_aicertsLmsUrl/webservice/rest/server.php')
        .replace(queryParameters: queryParams);

    return uri.toString();
  }

  /// Generate HMAC SHA256 signature
  ///
  /// Format: HMAC_SHA256("{email}:{timestamp}", SECRET_KEY)
  String _generateHMACSignature(String userId, int timestamp) {
    final message = '$userId:$timestamp';
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(message);

    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header with back button and progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.onSurface),
                  onPressed: widget.onBack ??
                      () {
                        Navigator.of(context).pop();
                      },
                  tooltip: 'Back to Dashboard',
                ),
                const SizedBox(width: 12),

                // Course info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AICERTS Course',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      if (widget.userName != null)
                        Text(
                          'Student: ${widget.userName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                    ],
                  ),
                ),

                // Progress indicator
                if (_progress > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_progress.toInt()}%',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Full-screen button
                IconButton(
                  icon: Icon(Icons.fullscreen, color: colors.onSurface),
                  onPressed: () {
                    // TODO: Implement full-screen mode
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Full-screen mode coming soon'),
                      ),
                    );
                  },
                  tooltip: 'Full Screen',
                ),
              ],
            ),
          ),

          // WebView content
          Expanded(
            child: Stack(
              children: [
                // WebView or Web Platform Alternative
                if (_error == null)
                  kIsWeb
                      ? _buildWebPlatformView(theme, colors)
                      : ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: WebViewWidget(controller: _webViewController),
                        ),

                // Error state
                if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to Load Course',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _error = null;
                                _isLoading = true;
                              });
                              _initializeWebView();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loading indicator
                if (_isLoading && _error == null)
                  Container(
                    color: colors.surface.withValues(alpha: 0.9),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: colors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Loading AICERTS course...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info banner (for testing/development)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AICERTS content is displayed via secure embedded frame. '
                    'Your progress syncs automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebPlatformView(ThemeData theme, ColorScheme colors) {
    final ssoUrl = _generateSSOUrl();

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.open_in_new,
                size: 64,
                color: colors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Open AICERTS Course',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'WebView is not supported on web platform. Click the button below to open the course in a new tab.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(ssoUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    // Error handled silently since we're in a widget
                  }
                },
                icon: const Icon(Icons.launch),
                label: const Text('Open Course in New Tab'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Dashboard'),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: colors.onSurface),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: For inline course viewing, use the mobile or desktop app.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // WebViewController automatically disposed by Flutter
    super.dispose();
  }
}
