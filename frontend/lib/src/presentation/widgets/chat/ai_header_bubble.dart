import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

class AIHeaderBubble extends StatefulWidget {
  final String? initialPrompt;
  final bool showPulse;
  final bool isMobile;

  const AIHeaderBubble({
    super.key,
    this.initialPrompt,
    this.showPulse = true,
    this.isMobile = false,
  });

  @override
  State<AIHeaderBubble> createState() => _AIHeaderBubbleState();
}

class _AIHeaderBubbleState extends State<AIHeaderBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _activateAI() {
    if (kIsWeb) {
      _activateWebAI();
    } else {
      _showNativeNotification();
    }
    _showAIActivatedNotification();
  }

  void _activateWebAI() {
    if (!kIsWeb) return;

    final script = '''
    (function() {
      if (window.hosiAILoaded && document.getElementById('hosi-ai-pathfinder-container')) {
        const container = document.getElementById('hosi-ai-pathfinder-container');
        const iframe = container.querySelector('iframe');
        iframe.contentWindow.postMessage('hosi-expanded', '*');
        ${widget.initialPrompt != null ? '''
        iframe.contentWindow.postMessage({
          type: 'setPrompt',
          value: '${widget.initialPrompt}'
        }, '*');
        ''' : ''}
        return;
      }
      
      const container = document.createElement('div');
      container.id = 'hosi-ai-pathfinder-container';
      container.style.cssText = 'position:fixed;top:0;right:0;width:100%;height:100%;z-index:2147483647;pointer-events:auto;overflow:hidden;';

      const iframe = document.createElement('iframe');
      iframe.src = '/concierge/index.html';
      iframe.style.cssText = 'width:100%;height:100%;border:none;background:transparent;';
      iframe.allow = 'microphone';

      window.addEventListener('message', (event) => {
        if (event.data === 'hosi-expanded') {
          container.style.pointerEvents = 'auto';
        } else if (event.data === 'hosi-collapsed') {
          container.style.pointerEvents = 'none';
        }
      });

      container.appendChild(iframe);
      document.body.appendChild(container);
      window.hosiAILoaded = true;
      
      iframe.onload = () => {
        setTimeout(() => {
          iframe.contentWindow.postMessage('hosi-expanded', '*');
          ${widget.initialPrompt != null ? '''
          iframe.contentWindow.postMessage({
            type: 'setPrompt',
            value: '${widget.initialPrompt}'
          }, '*');
          ''' : ''}
        }, 300);
      };
    })();
    ''';

    // Execute script
    globalContext.callMethod('eval'.toJS, script.toJS);
  }

  void _showNativeNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI Assistant - Native version'),
        backgroundColor: Color(0xFFF79150),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAIActivatedNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (kIsWeb) const Icon(Icons.mic, color: Colors.white, size: 20),
            if (kIsWeb) const SizedBox(width: 8),
            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kIsWeb ? 'Hosi AI Pathfinder' : 'AI Assistant',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    kIsWeb ? 'Voice commands ready' : 'Ready to assist',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF79150),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return _buildMobileBubble();
    }
    return _buildDesktopBubble();
  }

  Widget _buildMobileBubble() {
    return IconButton(
      icon: Stack(
        children: [
          Icon(
            Icons.auto_awesome,
            color: const Color(0xFFF79150),
            size: 24,
          ),
          if (kIsWeb)
            Positioned(
              right: 0,
              top: 0,
              child: Icon(
                Icons.mic,
                color: Colors.green,
                size: 12,
              ),
            ),
        ],
      ),
      onPressed: _activateAI,
      tooltip: kIsWeb ? 'Hosi AI with Voice' : 'AI Assistant',
    );
  }

  Widget _buildDesktopBubble() {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = false);
          });
        }
      },
      child: GestureDetector(
        onTap: _activateAI,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF79150),
                Color(0xFFFFB347),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF79150)
                    .withValues(alpha: _isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  if (kIsWeb)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              const Text(
                'Ask AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (kIsWeb) ...[
                const SizedBox(width: 4),
                const Icon(Icons.mic, color: Colors.white, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
