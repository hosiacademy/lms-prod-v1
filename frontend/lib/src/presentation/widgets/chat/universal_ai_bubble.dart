import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../ai/native_ai_assistant.dart';

class UniversalAIBubble extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isActive;
  final String? customLabel;
  final double size;
  final bool showMicIcon;

  const UniversalAIBubble({
    super.key,
    this.onPressed,
    this.isActive = false,
    this.customLabel,
    this.size = 32.0,
    this.showMicIcon = true,
  });

  @override
  State<UniversalAIBubble> createState() => _UniversalAIBubbleState();
}

class _UniversalAIBubbleState extends State<UniversalAIBubble> {
  bool _isExpanded = false;
  bool _isLoading = false;

  void _handleAIActivation() {
    setState(() {
      _isLoading = true;
    });

    // Trigger global AI assistant
    final isExpanded =
        NativeAIAssistant.globalKey.currentState?.isAIExpanded ?? false;
    if (isExpanded) {
      NativeAIAssistant.globalKey.currentState?.collapseAI();
    } else {
      NativeAIAssistant.globalKey.currentState?.expandAI();
    }

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              !isExpanded ? Icons.auto_awesome : Icons.close,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(!isExpanded
                ? 'AI Assistant activated'
                : 'AI Assistant closed - normal functionality restored'),
          ],
        ),
        backgroundColor:
            !isExpanded ? const Color(0xFFF79150) : Colors.grey.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Reset loading state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => setState(() => _isExpanded = true));
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => setState(() => _isExpanded = false));
        }
      },
      child: GestureDetector(
        onTap: _handleAIActivation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 16 : 12,
            vertical: _isExpanded ? 10 : 8,
          ),
          decoration: BoxDecoration(
            gradient: widget.isActive
                ? const LinearGradient(
                    colors: [
                      Color(0xFFF79150),
                      Color(0xFFFFB347),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
                  ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: widget.isActive
                    ? const Color(0xFFF79150).withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: _isExpanded ? 2 : 0,
              ),
            ],
            border: Border.all(
              color: widget.isActive
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isActive ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.auto_awesome,
                  size: widget.size * 0.6,
                  color: widget.isActive ? Colors.white : Colors.grey.shade600,
                ),
              if (_isExpanded) ...[
                const SizedBox(width: 8),
                Text(
                  widget.customLabel ?? 'Ask AI',
                  style: TextStyle(
                    color:
                        widget.isActive ? Colors.white : Colors.grey.shade700,
                    fontSize: widget.size * 0.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.showMicIcon && kIsWeb) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.mic,
                    size: widget.size * 0.3,
                    color:
                        widget.isActive ? Colors.white : Colors.grey.shade600,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
