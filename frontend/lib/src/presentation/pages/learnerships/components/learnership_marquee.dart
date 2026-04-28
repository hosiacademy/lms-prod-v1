// lib/src/presentation/pages/learnerships/components/learnership_marquee.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/models/learnership.dart';

class LearnershipMarquee extends StatefulWidget {
  final List<Learnership> enrollmentOpen;
  final List<Learnership> upcoming;
  final Function(Learnership) onMarqueeItemTap;

  const LearnershipMarquee({
    super.key,
    required this.enrollmentOpen,
    required this.upcoming,
    required this.onMarqueeItemTap,
  });

  @override
  State<LearnershipMarquee> createState() => _LearnershipMarqueeState();
}

class _LearnershipMarqueeState extends State<LearnershipMarquee> {
  late ScrollController _scrollController;
  late Timer _timer;
  bool _isHovering = false;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Start auto-scroll after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
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
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Combine all learnerships
    final allLearnerships = [...widget.enrollmentOpen, ...widget.upcoming];

    if (allLearnerships.isEmpty) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovering = true);
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovering = false);
          });
        }
      },
      child: Container(
        height: 48,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              const SizedBox(width: 20),

              // Generate marquee items
              ...allLearnerships.expand((learnership) {
                final isOpen = widget.enrollmentOpen.contains(learnership);
                return [
                  _buildMarqueeItem(learnership, isOpen, theme, colorScheme),
                  const SizedBox(width: 40),
                ];
              }).toList(),

              // Add duplicates for seamless looping
              ...allLearnerships.expand((learnership) {
                final isOpen = widget.enrollmentOpen.contains(learnership);
                return [
                  _buildMarqueeItem(learnership, isOpen, theme, colorScheme),
                  const SizedBox(width: 40),
                ];
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarqueeItem(
    Learnership learnership,
    bool isOpen,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => widget.onMarqueeItemTap(learnership),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOpen
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.secondary.withValues(alpha: 0.4),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen ? colorScheme.primary : colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),

            // Studentship title (shortened)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                learnership.specialization,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            const SizedBox(width: 10),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isOpen
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isOpen ? 'ENROLLING' : 'UPCOMING',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isOpen ? colorScheme.primary : colorScheme.secondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Duration info
            if (learnership.durationMonths != null) ...[
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${learnership.durationMonths}mo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
