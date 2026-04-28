import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Hosi AI Pathfinder Intelligence Overlay - Cross-Platform (Mobile & Web)
class NativeAIAssistant extends StatefulWidget {
  static final GlobalKey<NativeAIAssistantState> globalKey =
      GlobalKey<NativeAIAssistantState>();

  static bool enabled = true;

  final double width;
  final double height;

  const NativeAIAssistant({
    super.key,
    this.width = 600,
    this.height = 44,
  });

  /// Static helper to trigger AI prompt from anywhere
  static void setPrompt(BuildContext context, String prompt) {
    if (!enabled) return;
    globalKey.currentState?.setPromptAndRespond(prompt);
  }

  // Backwards compatibility for the typo
  static void setSetPrompt(BuildContext context, String prompt) =>
      setPrompt(context, prompt);

  @override
  State<NativeAIAssistant> createState() => NativeAIAssistantState();
}

class NativeAIAssistantState extends State<NativeAIAssistant> {
  bool _isWebScriptInjected = false;
  bool _isAIExpanded = false;
  bool get isAIExpanded => _isAIExpanded;
  StreamSubscription<web.MessageEvent>? _aiMessageSubscription;
  StreamController<web.MessageEvent>? _messageController;
  JSFunction? _messageListener;
  final List<String> _aiResponses = [];
  bool _isListening = false;

  // Mobile WebView Controller
  WebViewController? _webViewController;
  final String _aiUrl = '/concierge/';

  @override
  void initState() {
    super.initState();
    // Web uses ConciergeManager exclusively — no auto-injection here.
    // Mobile still auto-injects on first use (triggered lazily via expandAI/setPromptAndRespond).
  }

  void _initMobileWebView() {
    if (_webViewController != null || !NativeAIAssistant.enabled) return;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            _sendMobileInit();
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterAIChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMobileMessage(message.message);
        },
      );

    // Platform-specific configuration
    if (_webViewController!.platform is AndroidWebViewController) {
      (_webViewController!.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController!.loadRequest(Uri.parse(_aiUrl));
  }

  void _handleMobileMessage(String message) {
    try {
      if (message == 'hosi-expanded') {
        setState(() => _isAIExpanded = true);
      } else if (message == 'hosi-collapsed') {
        setState(() => _isAIExpanded = false);
      } else {
        final data = jsonDecode(message);
        if (data['type'] == 'ai-message') {
          setState(() {
            _aiResponses.add(data['text']);
            if (_aiResponses.length > 10) _aiResponses.removeAt(0);
          });
        }
      }
    } catch (e) {
      debugPrint('Error parsing mobile AI message: $e');
    }
  }

  void _sendMobileInit() {
    _webViewController?.runJavaScript('''
      window.addEventListener('message', (event) => {
        if (window.FlutterAIChannel) {
          window.FlutterAIChannel.postMessage(
            typeof event.data === 'string' ? event.data : JSON.stringify(event.data)
          );
        }
      });
      console.log('Mobile AI Bridge Initialized');
    ''');
  }

  @override
  void dispose() {
    _aiMessageSubscription?.cancel();
    if (kIsWeb && _messageListener != null) {
      web.window.removeEventListener('message', _messageListener);
    }
    _messageController?.close();
    super.dispose();
  }

  void _injectAndConnectToAI() {
    if (_isWebScriptInjected || !kIsWeb) return;

    // Inject the real Hosi AI Pathfinder
    final scriptElement = web.HTMLScriptElement()
      ..text = '''
      (function() {
        if (document.getElementById('hosi-ai-pathfinder-container')) return;

      const container = document.createElement('div');
      container.id = 'hosi-ai-pathfinder-container';
      container.style.cssText =
        'position:fixed; top:0; right:0; width:100%; height:100%; z-index:2147483646; pointer-events:none; overflow:hidden; transition:all 0.3s ease;';

      const iframe = document.createElement('iframe');
      iframe.src = '$_aiUrl';
      iframe.style.cssText =
        'width:100%; height:100%; border:none; background:transparent; opacity:1; transition:opacity 0.3s ease; ';

      iframe.allow = 'microphone';
      iframe.allowFullscreen = true;

      // Close Button
      const closeBtn = document.createElement('button');
      closeBtn.innerHTML = '×';
      closeBtn.style.cssText = 'position:fixed; top:20px; right:20px; z-index:2147483648; background:#F79150; border:none; color:white; width:44px; height:44px; border-radius:50%; cursor:pointer; font-size:28px; font-weight:bold; box-shadow:0 4px 12px rgba(0,0,0,0.3); display:none; align-items:center; justify-content:center;';

      closeBtn.onclick = () => {
        window.postMessage('hosi-collapsed', '*');
      };

      window.addEventListener('message', (event) => {
        if (event.data === 'hosi-expanded') {
          container.style.pointerEvents = 'auto';
          container.style.zIndex = '2147483647';
          iframe.style.opacity = '1';
          closeBtn.style.display = 'flex';
        } else if (event.data === 'hosi-collapsed') {
          container.style.pointerEvents = 'none';
          container.style.zIndex = '2147483646';
          iframe.style.opacity = '0';
          closeBtn.style.display = 'none';
          // Also notify flutter
          window.postMessage({type: 'ai-closed-internal'}, '*');
        }

        if (event.data && typeof event.data === 'object') {
          if (event.data.type === 'ai-response') {
            window.postMessage({ type: 'ai-message', text: event.data.text }, '*');
          }
        }
      });

      iframe.onload = () => {
        setTimeout(() => iframe.contentWindow.postMessage({type: 'init'}, '*'), 500);
      };

      container.appendChild(iframe);
      container.appendChild(closeBtn);
      document.body.appendChild(container);
      })();
      ''';

    web.document.head?.append(scriptElement);
    _isWebScriptInjected = true;
    _setupAIMessageListener();
  }

  void _setupAIMessageListener() {
    if (!kIsWeb) return;
    _messageController = StreamController<web.MessageEvent>.broadcast();

    _messageListener = ((JSAny? rawEvent) {
      if (rawEvent != null) {
        _messageController?.add(rawEvent as web.MessageEvent);
      }
    }).toJS;

    web.window.addEventListener('message', _messageListener);

    _aiMessageSubscription =
        _messageController!.stream.listen((web.MessageEvent event) {
      if (!mounted) return;
      final data = event.data;
      if (data == null) return;
      if (data.typeofEquals('object')) {
        try {
          final dynamic dartData = data.dartify();
          if (dartData is Map && dartData['type'] == 'ai-message') {
            setState(() {
              _aiResponses.add(dartData['text']?.toString() ?? '');
              if (_aiResponses.length > 10) _aiResponses.removeAt(0);
            });
          }
        } catch (_) {}
      } else if (data.typeofEquals('string')) {
        final str = (data as JSString).toDart;
        if (str == 'hosi-expanded') {
          setState(() => _isAIExpanded = true);
        } else if (str == 'hosi-collapsed') {
          setState(() => _isAIExpanded = false);
        }
      }
    });
  }

  void expandAI() {
    if (!NativeAIAssistant.enabled) return;

    if (kIsWeb) {
      _injectAndConnectToAI();
      Future.delayed(const Duration(milliseconds: 100), () {
        web.window.postMessage('hosi-expanded'.toJS, '*'.toJS);
        setState(() => _isAIExpanded = true);
      });
    } else {
      if (_webViewController == null) _initMobileWebView();
      _webViewController
          ?.runJavaScript("window.postMessage('hosi-expanded', '*')");
      setState(() => _isAIExpanded = true);
    }
  }

  void setPromptAndRespond(String prompt) {
    if (!NativeAIAssistant.enabled) return;

    if (kIsWeb) {
      _injectAndConnectToAI();
      web.window.postMessage(
          {'type': 'user-prompt', 'text': prompt}.jsify(), '*'.toJS);
      expandAI();
    } else {
      if (_webViewController == null) _initMobileWebView();
      final jsonPrompt = jsonEncode({'type': 'user-prompt', 'text': prompt});
      _webViewController?.runJavaScript("window.postMessage($jsonPrompt, '*')");
      expandAI();
    }
  }

  void collapseAI() {
    if (kIsWeb) {
      web.window.postMessage('hosi-collapsed'.toJS, '*'.toJS);
    } else {
      _webViewController
          ?.runJavaScript("window.postMessage('hosi-collapsed', '*')");
    }
    setState(() => _isAIExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!NativeAIAssistant.enabled || kIsWeb) return const SizedBox.shrink();

    // Mobile implementation - render WebView as a floating layer
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: _isAIExpanded ? 0 : MediaQuery.of(context).size.height,
          left: 0,
          right: 0,
          bottom: 0,
          child: Visibility(
            visible: _isAIExpanded,
            maintainState: true,
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: _webViewController != null
                  ? Stack(
                      children: [
                        WebViewWidget(controller: _webViewController!),
                        Positioned(
                          top: 40,
                          right: 20,
                          child: FloatingActionButton.small(
                            onPressed: collapseAI,
                            backgroundColor: const Color(0xFFF79150),
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}
