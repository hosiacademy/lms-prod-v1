import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_theme.dart';

class LearningPathwaysCompact extends StatelessWidget {
  final Function(String route) onPathSelected;

  const LearningPathwaysCompact({
    super.key,
    required this.onPathSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pathways = [
      _Pathway(
        title: 'Corporate Training',
        icon: Icons.business_rounded,
        color: AppTheme.hosiBrown,
        route: '/enroll/corporate',
      ),
      _Pathway(
        title: 'Learnerships',
        icon: Icons.school_rounded,
        color: AppTheme.successGreen,
        route: '/enroll/learnerships',
      ),
      _Pathway(
        title: 'Industry Specific & Role-based',
        icon: Icons.engineering_rounded,
        color: const Color(0xFF1E88E5),
        route: '/enroll/industry',
      ),
      _Pathway(
        title: 'Custom Selection',
        icon: Icons.dashboard_customize_rounded,
        color: AppTheme.hosiPeach,
        route: '/enroll/custom',
      ),
      _Pathway(
        title: 'Expert Trainers',
        icon: Icons.person_rounded,
        color: const Color(0xFFF79150), // hosiPeach or secondary
        route: 'trainers', // Special key
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;

          // Use Row with equal spacing for horizontal alignment
          if (!isNarrow) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: pathways.map((path) {
                return Expanded(
                  flex: 1, // Equal width distribution
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _PathwayTile(
                      pathway: path,
                      isNarrow: false,
                      onTap: () => onPathSelected(path.route),
                    ),
                  ),
                );
              }).toList(),
            );
          }

          // Wrap for narrow screens
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: pathways.map((path) {
              return _PathwayTile(
                pathway: path,
                isNarrow: isNarrow,
                onTap: () => onPathSelected(path.route),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _Pathway {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _Pathway({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _PathwayTile extends StatefulWidget {
  final _Pathway pathway;
  final bool isNarrow;
  final VoidCallback onTap;

  const _PathwayTile({
    required this.pathway,
    required this.isNarrow,
    required this.onTap,
  });

  @override
  State<_PathwayTile> createState() => _PathwayTileState();
}

class _PathwayTileState extends State<_PathwayTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(
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
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: widget.isNarrow
                ? double.infinity
                : null, // Let Expanded control width on desktop
            height: widget.isNarrow ? 120 : 140, // Fixed height on desktop and mobile for perfect alignment
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.pathway.color,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.pathway.color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.pathway.icon,
                  size: 36,
                  color: widget.pathway.color,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    widget.pathway.title,
                    style: TextStyle( 
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: widget.isNarrow ? 14 : 15,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
}
