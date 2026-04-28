import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BBBPartnershipWidget extends StatefulWidget {
  final double size;
  final bool showLabel;

  const BBBPartnershipWidget({
    super.key,
    this.size = 100,
    this.showLabel = true,
  });

  @override
  State<BBBPartnershipWidget> createState() => _BBBPartnershipWidgetState();
}

class _BBBPartnershipWidgetState extends State<BBBPartnershipWidget> {
  bool _isHovered = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay() {
    _removeOverlay(); // safety

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Calculate desired position (below the widget, centered)
    final left = position.dx + (size.width / 2) - 150; // 300/2 = 150
    final top = position.dy + size.height + 10;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: MouseRegion(
          // Optional: keep tooltip open when hovering it
          onEnter: (_) => {}, // do nothing or keep alive
          onExit: (_) => _removeOverlay(),
          child: GestureDetector(
            // Optional: tap outside to close (but usually not needed for hover)
            onTap: _removeOverlay,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                    width: 2,
                  ),
                  // boxShadow is now handled by Material elevation
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF0E70D8), Color(0xFF0A5BA8)],
                            ),
                          ),
                          child: const Icon(
                            Icons.video_library_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Big Blue Button Partnership',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '🎥 Virtual Classroom Excellence',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We partner with Big Blue Button (BBB), the world\'s leading open-source virtual classroom platform, to deliver exceptional online learning experiences.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildFeatureChip('Live Video', Icons.videocam),
                        _buildFeatureChip('Screen Share', Icons.screen_share),
                        _buildFeatureChip('Whiteboard', Icons.draw),
                        _buildFeatureChip(
                            'Recording', Icons.fiber_manual_record),
                        _buildFeatureChip('Breakout Rooms', Icons.meeting_room),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'For courses without partner integration, we default to BBB for seamless delivery.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 300))
                  .slideY(
                    begin: -0.2,
                    end: 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _isHovered = true);
              _showOverlay();
            }
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _isHovered = false);
              // Optional: delay removal if you want to allow hovering the tooltip itself
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && !_isHovered) _removeOverlay();
              });
            }
          });
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Logo Container (unchanged)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.surface, colors.surfaceContainerHighest],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? colors.primary
                    : colors.outline.withValues(alpha: 0.2),
                width: _isHovered ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? colors.primary.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: _isHovered ? 20 : 10,
                  spreadRadius: _isHovered ? 2 : 0,
                  offset: Offset(0, _isHovered ? 5 : 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: (widget.size - 24) * 0.7,
                        height: (widget.size - 24) * 0.7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0E70D8), Color(0xFF0A5BA8)],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.video_library_rounded,
                        size: (widget.size - 24) * 0.4,
                        color: Colors.white,
                      ),
                    ],
                  )
                      .animate(
                        onPlay: (controller) => _isHovered
                            ? controller.repeat()
                            : controller.stop(),
                      )
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.05, 1.05),
                        duration: const Duration(milliseconds: 1000),
                      ),
                ),
                if (widget.showLabel) ...[
                  const SizedBox(height: 4),
                  Text(
                    'BBB',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Keep the small "Partner" badge in local Stack — it's fine here
          if (_isHovered)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  '🤝 Partner',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 200))
                  .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0)),
            ),
        ],
      ),
    );
  }
}
