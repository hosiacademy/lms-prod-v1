// lib/src/presentation/blocs/course/corporate/components/masterclass_marquee.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/src/data/models/masterclass.dart';

class MasterclassMarquee extends StatefulWidget {
  final List<Masterclass> running;
  final List<Masterclass> upcoming;
  final Function(Masterclass) onMarqueeItemTap;

  const MasterclassMarquee({
    super.key,
    required this.running,
    required this.upcoming,
    required this.onMarqueeItemTap,
  });

  @override
  State<MasterclassMarquee> createState() => _MasterclassMarqueeState();
}

class _MasterclassMarqueeState extends State<MasterclassMarquee> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _isHovering = false;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Start auto-scroll after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isHovering && _scrollController.hasClients) {
        setState(() {
          _scrollOffset += 0.5;
          if (_scrollOffset >=
              _scrollController.position.maxScrollExtent + 200) {
            _scrollOffset = 0;
          }
          _scrollController.jumpTo(_scrollOffset);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Combine all masterclasses
    final allMasterclasses = [...widget.running, ...widget.upcoming];

    if (allMasterclasses.isEmpty) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      child: Container(
        height: 48,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) => true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                // Add some padding at the start
                const SizedBox(width: 20),

                // Generate marquee items
                ...allMasterclasses.expand((masterclass) {
                  final isRunning = widget.running.contains(masterclass);
                  return [
                    _buildMarqueeItem(
                        masterclass, isRunning, theme, colorScheme),
                    const SizedBox(width: 40), // Spacing between items
                  ];
                }).toList(),

                // Add duplicates for seamless looping
                ...allMasterclasses.expand((masterclass) {
                  final isRunning = widget.running.contains(masterclass);
                  return [
                    _buildMarqueeItem(
                        masterclass, isRunning, theme, colorScheme),
                    const SizedBox(width: 40),
                  ];
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarqueeItem(
    Masterclass masterclass,
    bool isRunning,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => widget.onMarqueeItemTap(masterclass),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRunning
                ? colorScheme.error.withValues(alpha: 0.4)
                : colorScheme.primary.withValues(alpha: 0.4),
            width: 1,
          ),
          gradient: LinearGradient(
            colors: [
              colorScheme.surface.withValues(alpha: 0.9),
              colorScheme.surface.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRunning ? colorScheme.error : colorScheme.primary,
              ),
            ),

            // Title
            Text(
              masterclass.title,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 12),

            // Stream type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: masterclass.streamType.toLowerCase() == 'technical'
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                masterclass.streamType.toUpperCase(),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: masterclass.streamType.toLowerCase() == 'technical'
                      ? colorScheme.primary
                      : colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isRunning
                    ? colorScheme.error.withValues(alpha: 0.1)
                    : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isRunning ? 'LIVE' : 'UPCOMING',
                style: theme.textTheme.labelSmall!.copyWith(
                  color: isRunning ? colorScheme.error : colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
