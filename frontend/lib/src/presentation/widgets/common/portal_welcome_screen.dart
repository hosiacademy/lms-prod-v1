// lib/src/presentation/widgets/common/portal_welcome_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';

/// Portal-specific welcome flash screen shown on successful sign-in
///
/// Displays for 2.5 seconds then navigates to the appropriate portal dashboard
class PortalWelcomeScreen extends StatefulWidget {
  final String
      portalName; // "Student Portal", "Instructor Portal", "Admin Portal"
  final String userFirstName; // User's first name for personalization
  final VoidCallback onComplete; // Callback when animation completes
  final Color? primaryColor; // Optional theme color override

  const PortalWelcomeScreen({
    Key? key,
    required this.portalName,
    required this.userFirstName,
    required this.onComplete,
    this.primaryColor,
  }) : super(key: key);

  @override
  State<PortalWelcomeScreen> createState() => _PortalWelcomeScreenState();
}

class _PortalWelcomeScreenState extends State<PortalWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Start animation
    _controller.forward();

    // Auto-navigate after 2.5 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    // Theme integration
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use theme colors or defaults
    // In dark mode: Surface is dark (e.g. 0xFF1F2937), Primary is Peach
    // In light mode: Surface is white, Primary is Brown
    final backgroundColor = colorScheme.surface;
    final primaryColor = widget.primaryColor ?? colorScheme.primary;
    final onSurfaceColor = colorScheme.onSurface;

    // Balanced modal dimensions - reduced by 40% for smaller, catchier appearance
    final modalWidth = isSmallScreen ? screenWidth * 0.9 : 330.0; // was 550.0
    final modalHeight = isSmallScreen ? 300.0 : 330.0; // was 500.0/550.0

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Deep focus overlay - Slightly lighter in light mode
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),

          // Symmetrical Welcome Modal
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: modalWidth,
                      height: modalHeight,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 60,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            // Perfectly Symmetrical Background
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 1.0,
                                    colors: isDark
                                        ? [
                                            // Dark mode gradient
                                            const Color(0xFF244359),
                                            backgroundColor,
                                          ]
                                        : [
                                            // Light mode gradient - subtle
                                            colorScheme.surfaceContainerHighest,
                                            backgroundColor,
                                          ],
                                  ),
                                ),
                              ),
                            ),

                            // Centered Content Area
                            Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24), // reduced from 40
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Hosi Academy Logo - The focal point
                                    Container(
                                      padding: const EdgeInsets.all(16), // reduced from 24
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.05)
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.15),
                                            blurRadius: 30,
                                            offset: const Offset(0, 15),
                                          ),
                                        ],
                                        border: isDark
                                            ? null
                                            : Border.all(
                                                color: colorScheme.outline
                                                    .withValues(alpha: 0.1)),
                                      ),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: isSmallScreen ? 60 : 84, // reduced 40% from 100/140
                                        height: isSmallScreen ? 60 : 84,
                                        fit: BoxFit.contain,
                                      ),
                                    ),

                                    const SizedBox(height: 28), // reduced from 48

                                    // Welcome Text
                                    Text(
                                      'Welcome to the',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: onSurfaceColor.withValues(
                                            alpha: 0.7),
                                        fontSize: 14, // reduced 40% from 18
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 6), // reduced from 8

                                    Text(
                                      widget.portalName.toUpperCase(),
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                        color: primaryColor,
                                        fontSize: isSmallScreen ? 18 : 22, // reduced 40% from 28/36
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                        shadows: [
                                          Shadow(
                                            color: primaryColor.withValues(
                                                alpha: 0.3),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 16), // reduced from 24

                                    // Personalization
                                    Text(
                                      widget.userFirstName,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: onSurfaceColor,
                                        fontSize: isSmallScreen ? 14 : 18, // reduced 40% from 22/28
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 32), // reduced from 56

                                    // Premium loading line
                                    Container(
                                      width: 84, // reduced 40% from 140
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: onSurfaceColor.withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Stack(
                                        children: [
                                          AnimatedBuilder(
                                            animation: _controller,
                                            builder: (context, child) {
                                              return FractionallySizedBox(
                                                widthFactor: _controller.value,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: primaryColor
                                                            .withValues(
                                                                alpha: 0.8),
                                                        blurRadius: 10,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Symmetrical skip button
                            Positioned(
                              top: 20,
                              right: 20,
                              child: IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: onSurfaceColor.withValues(alpha: 0.5),
                                  size: 24,
                                ),
                                onPressed: widget.onComplete,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Helper function to show portal welcome screen and navigate
Future<void> showPortalWelcome({
  required BuildContext context,
  required String portalName,
  required String userFirstName,
  required String destinationRoute,
  Color? primaryColor,
}) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return PortalWelcomeScreen(
          portalName: portalName,
          userFirstName: userFirstName,
          primaryColor: primaryColor,
          onComplete: () {
            Navigator.of(context).pushReplacementNamed(destinationRoute);
          },
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}

/// Determine portal name and route based on user role
Map<String, String> getPortalInfoForRole(String role) {
  switch (role.toLowerCase()) {
    case 'student':
      return {
        'portalName': 'Student Portal',
        'route': '/student/dashboard',
      };
    case 'instructor':
      return {
        'portalName': 'Instructor Portal',
        'route': '/instructor/dashboard',
      };
    case 'admin':
      return {
        'portalName': 'Admin Portal',
        'route': '/admin/dashboard',
      };
    case 'facilitator':
      return {
        'portalName': 'Facilitator Portal',
        'route': '/facilitator/dashboard',
      };
    default:
      return {
        'portalName': 'Portal',
        'route': '/dashboard',
      };
  }
}
