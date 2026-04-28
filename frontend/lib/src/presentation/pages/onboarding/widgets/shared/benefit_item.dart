import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BenefitItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? cardColor;

  const BenefitItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.cardColor,
  });

  @override
  State<BenefitItem> createState() => _BenefitItemState();
}

class _BenefitItemState extends State<BenefitItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    final baseColor = widget.cardColor ?? colors.primary;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _isHovered = true);
              _controller.forward();
            }
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _isHovered = false);
              _controller.reverse();
            }
          });
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: isSmallScreen ? double.infinity : null,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _isHovered ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: baseColor.withValues(alpha: _isHovered ? 0.7 : 0.4),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Decorative Pattern Overlay
                Positioned(
                  right: -30,
                  top: -30,
                  child: Opacity(
                    opacity: 0.07,
                    child: Icon(
                      widget.icon,
                      size: 150,
                      color: baseColor,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Icon with backdrop
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 28,
                          color: baseColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Title
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          height: 1.2,
                          letterSpacing: 0.3,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      Flexible(
                        child: Text(
                          widget.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.8),
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Shine effect on hover
                if (_isHovered)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }
}
