import 'package:flutter/material.dart';
import 'training_options_modal.dart';

/// Training menu button - shows training options modal when tapped
class AnimatedTrainingMenu extends StatefulWidget {
  final String title;
  final bool isHovered;
  final Function(String, bool) onHover;
  final Function(String) onOptionClick;
  final Function(bool)? onMenuVisibilityChanged;
  final bool isCybersecurity;
  final VoidCallback? onPathwaysTap;

  const AnimatedTrainingMenu({
    super.key,
    required this.title,
    required this.isHovered,
    required this.onHover,
    required this.onOptionClick,
    this.onMenuVisibilityChanged,
    this.isCybersecurity = false,
    this.onPathwaysTap,
  });

  @override
  State<AnimatedTrainingMenu> createState() => _AnimatedTrainingMenuState();
}

class _AnimatedTrainingMenuState extends State<AnimatedTrainingMenu> {
  void _showTrainingOptionsModal() {
    final context = this.context;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return TrainingOptionsModal(
          onOptionSelected: (route) {
            widget.onOptionClick(route);
          },
          isCybersecurity: widget.isCybersecurity,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _showTrainingOptionsModal,  // Show training options modal
      child: MouseRegion(
        onEnter: (_) {
          if (mounted) widget.onHover(widget.title, true);
        },
        onExit: (_) {
          if (mounted) widget.onHover(widget.title, false);
        },
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isHovered
                ? (widget.isCybersecurity
                    ? Colors.red.shade700
                    : colorScheme.primary)
                : (widget.isCybersecurity
                    ? Colors.red.shade900
                    : colorScheme.primary.withValues(alpha: 0.8)),
            borderRadius: BorderRadius.circular(25),
            boxShadow: widget.isHovered
                ? [
                    BoxShadow(
                      color: (widget.isCybersecurity
                              ? Colors.red
                              : colorScheme.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isCybersecurity
                    ? Icons.security_rounded
                    : Icons.psychology_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
