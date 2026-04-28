// lib/src/presentation/pages/instructor/bbb_session_viewer.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import '../../../core/api/api_client.dart';

/// Displays BigBlueButton session within the instructor portal
/// Session is shown in an embedded webview instead of opening externally
class BBBSessionViewer extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;
  final String? joinUrl;

  const BBBSessionViewer({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
    this.joinUrl,
  });

  @override
  State<BBBSessionViewer> createState() => _BBBSessionViewerState();
}

class _BBBSessionViewerState extends State<BBBSessionViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _loadingProgress = 0.0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Initialize for both web and native platforms
    _fetchJoinUrlAndInitialize();
  }

  Future<void> _fetchJoinUrlAndInitialize() async {
    String joinUrl = '';
    
    if (widget.joinUrl != null && widget.joinUrl!.isNotEmpty) {
      joinUrl = widget.joinUrl!;
    } else {
      // Fetch join URL from backend API
      try {
        final response = await ApiClient.get(
          '/api/v1/bbb/sessions/${widget.sessionId}/join/',
        );

        if (response.data != null && response.data['join_url'] != null) {
          joinUrl = response.data['join_url'] as String;
        } else {
          if (!_isDisposed && mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Failed to get session join URL from server';
              _isLoading = false;
            });
          }
          return;
        }
      } catch (e) {
        if (!_isDisposed && mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Error connecting to session: ${e.toString()}';
            _isLoading = false;
          });
        }
        return;
      }
    }

    // Convert HTTP to HTTPS for web to avoid mixed content issues
    if (kIsWeb && joinUrl.startsWith('http://')) {
      joinUrl = joinUrl.replaceFirst('http://', 'https://');
    }

    // On web, open BBB in a new window/tab and navigate back to sessions list
    if (kIsWeb) {
      // Open BBB session in new window/tab
      html.window.open(joinUrl, '_blank');
      
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Get theme colors for the snackbar
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'BBB session opened in new tab: ${widget.sessionTitle}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: colors.primary,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: colors.onPrimary,
              onPressed: () {
                // Navigate back to sessions page
                Navigator.of(context).pop(); // Close BBB viewer
              },
            ),
          ),
        );
        
        // Auto-navigate back after short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!_isDisposed && mounted) {
            Navigator.of(context).pop(); // Close BBB viewer and return to sessions
          }
        });
      }
    } else {
      // Native platforms use embedded WebView
      if (!_isDisposed && mounted) {
        _initializeWebView(joinUrl);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _initializeWebView(String joinUrl) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!_isDisposed && mounted) {
              setState(() {
                _loadingProgress = progress / 100;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (!_isDisposed && mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (!_isDisposed && mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (!_isDisposed && mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation within BBB
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(joinUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
          tooltip: 'Leave Session',
        ),
        actions: [
          // Session Controls
          if (!_hasError) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
              tooltip: 'Reload',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More Options',
              onSelected: (value) {
                switch (value) {
                  case 'fullscreen':
                    _toggleFullscreen();
                    break;
                  case 'settings':
                    _showSettings();
                    break;
                  case 'help':
                    _showHelp();
                    break;
                  case 'leave':
                    _handleBack(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'fullscreen',
                  child: Row(
                    children: [
                      Icon(Icons.fullscreen),
                      SizedBox(width: 12),
                      Text('Fullscreen'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'help',
                  child: Row(
                    children: [
                      Icon(Icons.help_outline),
                      SizedBox(width: 12),
                      Text('Help'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Leave Session',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Loading Progress Bar
          if (_isLoading && !_hasError)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),

          // Main Content
          Expanded(
            child: _hasError
                ? _buildErrorView()
                : kIsWeb
                    ? _buildWebPlatformView()
                    : Stack(
                        children: [
                          // WebView for BBB Session
                          WebViewWidget(controller: _controller),

                          // Loading Overlay
                          if (_isLoading)
                        Container(
                          color: colors.surface,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: _loadingProgress > 0 ? _loadingProgress : null,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading session...',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_loadingProgress * 100).toInt()}%',
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

          // Session Info Bar (Optional)
          if (!_hasError)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    size: 12,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.videocam,
                    size: 16,
                    color: colors.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Recording',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Session ID: ${widget.sessionId}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              'Failed to Load Session',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isEmpty
                  ? 'Unable to connect to the live session. Please check your connection and try again.'
                  : _errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                    });
                    _controller.reload();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPlatformView() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Fetch join URL from backend for web platform
    return FutureBuilder<String>(
      future: _getJoinUrl(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Preparing session...', style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: colors.error),
                const SizedBox(height: 16),
                Text('Failed to load session', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(snapshot.error?.toString() ?? 'Unknown error'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        final joinUrl = snapshot.data!;
        return _buildWebPlatformContent(theme, colors, joinUrl);
      },
    );
  }

  Future<String> _getJoinUrl() async {
    if (widget.joinUrl != null && widget.joinUrl!.isNotEmpty) {
      return widget.joinUrl!;
    }

    final response = await ApiClient.get('/api/v1/bbb/sessions/${widget.sessionId}/join/');

    if (response.data != null && response.data['join_url'] != null) {
      return response.data['join_url'] as String;
    }

    throw Exception('Failed to get session join URL from server');
  }

  Widget _buildWebPlatformContent(ThemeData theme, ColorScheme colors, String joinUrl) {

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.open_in_new,
              size: 64,
              color: colors.primary,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(joinUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open URL: $joinUrl'),
                        backgroundColor: colors.error,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.launch),
              label: const Text('Open Session in New Tab'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Session?'),
        content: const Text(
          'Are you sure you want to leave this session? '
          'Your students will be notified that you have left.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close BBB session modal
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _toggleFullscreen() {
    // TODO: Implement fullscreen mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fullscreen mode coming soon')),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Microphone'),
              trailing: Switch(value: true, onChanged: (val) {}),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Camera'),
              trailing: Switch(value: true, onChanged: (val) {}),
            ),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Speaker'),
              trailing: Switch(value: true, onChanged: (val) {}),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BigBlueButton Controls:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Use the microphone icon to mute/unmute'),
              Text('• Click the camera icon to start/stop video'),
              Text('• Use the chat panel to message participants'),
              Text('• Share your screen using the share button'),
              Text('• Record the session for later viewing'),
              SizedBox(height: 16),
              Text(
                'Troubleshooting:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Refresh the page if you encounter issues'),
              Text('• Check your microphone permissions'),
              Text('• Ensure stable internet connection'),
              Text('• Contact support if problems persist'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
