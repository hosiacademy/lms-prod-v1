import 'package:flutter/material.dart';

/// Slide-in panel that covers 85% of screen width
/// Animates from left to right (drifts in from left side)
/// Allows downward scroll for content
class SlideInPanel extends StatelessWidget {
  final Widget child;
  final String title;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const SlideInPanel({
    super.key,
    required this.child,
    required this.title,
    this.onClose,
    this.actions,
  });

  /// Show slide-in panel with animation
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    required String title,
    List<Widget>? actions,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Transparent background
        barrierDismissible: true,
        barrierColor: Colors.black54,
        pageBuilder: (context, animation, secondaryAnimation) {
          return SlideInPanel(
            title: title,
            actions: actions,
            child: child,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0); // Slide from left
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.85; // 85% of screen width
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside panel
            child: Container(
              width: panelWidth,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(10, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Premium Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF172E3D), // hosiMidnight
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Back',
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title.toUpperCase(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (actions != null) ...actions!,
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: Colors.white.withValues(alpha: 0.5)),
                              onPressed:
                                  onClose ?? () => Navigator.of(context).pop(),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Branding line
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF79150), // hosiPeach
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
