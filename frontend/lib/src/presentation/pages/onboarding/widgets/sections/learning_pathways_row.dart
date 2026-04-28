import 'package:flutter/material.dart';

class LearningPathwaysRow extends StatelessWidget {
  final Function(String route) onPathSelected;

  const LearningPathwaysRow({
    super.key,
    required this.onPathSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pathways = [
      _PathwayItem(
        title: "AI & Blockchain",
        icon: Icons.psychology_rounded,
        color: Colors.deepPurple,
        route: '/enroll/ai-blockchain',
      ),
      _PathwayItem(
        title: "Cybersecurity",
        icon: Icons.security_rounded,
        color: Colors.red.shade700,
        route: '/enroll/cybersecurity',
      ),
      _PathwayItem(
        title: "Learnerships",
        icon: Icons.school_rounded,
        color: Colors.teal,
        route: '/enroll/learnerships',
      ),
      _PathwayItem(
        title: "Custom Selection",
        icon: Icons.dashboard_customize_rounded,
        color: Colors.amber.shade800,
        route: '/enroll/custom',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: pathways.map((path) {
              return _PathwayCard(
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

class _PathwayItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _PathwayItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _PathwayCard extends StatefulWidget {
  final _PathwayItem pathway;
  final bool isNarrow;
  final VoidCallback onTap;

  const _PathwayCard({
    required this.pathway,
    required this.isNarrow,
    required this.onTap,
  });

  @override
  State<_PathwayCard> createState() => _PathwayCardState();
}

class _PathwayCardState extends State<_PathwayCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
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
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: widget.isNarrow ? double.infinity : 260,
            constraints: const BoxConstraints(minHeight: 140),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.pathway.color.withValues(alpha: 0.9),
                  widget.pathway.color.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.pathway.color.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.pathway.icon,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.pathway.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Start now",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
