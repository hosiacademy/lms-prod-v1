// lib/src/presentation/pages/splash/splash_modal.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

/// Afrocentric first splash modal.
/// Dismisses when [heroReady] becomes true OR after 8 s timeout.
class SplashModal extends StatefulWidget {
  final VoidCallback onComplete;
  final ValueListenable<bool>? heroReady;

  const SplashModal({
    super.key,
    required this.onComplete,
    this.heroReady,
  });

  @override
  State<SplashModal> createState() => _SplashModalState();
}

class _SplashModalState extends State<SplashModal> with SingleTickerProviderStateMixin {
  Timer? _fallbackTimer;
  bool _dismissed = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    widget.heroReady?.addListener(_onHeroReady);
    // Fallback: dismiss after 8 seconds even if carousel hasn't loaded
    _fallbackTimer = Timer(const Duration(seconds: 8), _dismiss);
  }

  void _onHeroReady() {
    if (widget.heroReady?.value == true) _dismiss();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _fallbackTimer?.cancel();
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _rotationController.dispose();
    widget.heroReady?.removeListener(_onHeroReady);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 768;
    final modalWidth = isSmall ? screenWidth * 0.92 : 480.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark semi-transparent overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF050C14).withValues(alpha: 0.82),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // Modal card
          Center(
            child: Container(
              width: modalWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 60,
                  ),
                  BoxShadow(
                    color: AppTheme.hosiBrown.withValues(alpha: 0.15),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Afrocentric Kente-pattern background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _KentePainter(),
                      ),
                    ),
                    // Dark overlay on the pattern for readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.hosiMidnight.withValues(alpha: 0.88),
                              AppTheme.hosiMidnight.withValues(alpha: 0.96),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isSmall ? 28 : 44,
                        isSmall ? 40 : 48,
                        isSmall ? 28 : 44,
                        isSmall ? 36 : 44,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── LOGO & CIRCLING TRIANGLE ──
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Circling Triangle
                              RotationTransition(
                                turns: _rotationController,
                                child: SizedBox(
                                  width: isSmall ? 180 : 220,
                                  height: isSmall ? 180 : 220,
                                  child: CustomPaint(
                                    painter: _CirclingTrianglePainter(
                                      color: AppTheme.hosiPeach,
                                    ),
                                  ),
                                ),
                              ),
                              // Logo
                              Image.asset(
                                'assets/images/logo.png',
                                height: isSmall ? 100 : 130,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.school_rounded,
                                  color: AppTheme.hosiPeach,
                                  size: 64,
                                ),
                              ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn(duration: 600.ms),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // ── The Future of Learning (Tagline) ──
                          Text(
                            'The Future of Learning',
                            textAlign: TextAlign.center,
                            style: TextStyle( 
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 1.2,
                            ),
                          ).animate().fadeIn(delay: 600.ms),

                          const SizedBox(height: 40),

                          // Loading progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: SizedBox(
                              width: 160,
                              height: 3,
                              child: LinearProgressIndicator(
                                backgroundColor: AppTheme.hosiPeach.withValues(alpha: 0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.hosiPeach),
                              ),
                            ),
                          ).animate().fadeIn(delay: 800.ms),

                          const SizedBox(height: 12),

                          Text(
                            'Loading your learning experience...',
                            style: TextStyle( 
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ).animate().fadeIn(delay: 1000.ms),
                        ],
                      ),
                    ),

                    // Skip button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: TextButton(
                        onPressed: _dismiss,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 2000.ms),
                  ],
                ),
              ),
            ),
          ).animate().scale(duration: 480.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}

class _CirclingTrianglePainter extends CustomPainter {
  final Color color;

  _CirclingTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Radius allows it to orbit the logo comfortably
    final radius = size.width / 2 - 5;

    // Triangle dimensions
    const side = 20.0;
    const height = 18.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // Draw the orbit path (subtle)
    final orbitPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset.zero, radius, orbitPaint);

    // Position the triangle on the orbit
    canvas.translate(0, -radius);
    
    // Create a rounded triangle path
    final path = Path()
      ..moveTo(-side / 2, height / 3)
      ..lineTo(side / 2, height / 3)
      ..lineTo(0, -height * 2 / 3)
      ..close();

    // Draw the triangle with rounded corners effect using strokeJoin
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Add a pulsing glow behind the triangle
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(const Offset(0, 0), 12, glowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KentePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.hosiMidnight,
    );
    _drawKenteStripes(canvas, size);
    _drawAdinkraCorners(canvas, size);
  }

  void _drawKenteStripes(Canvas canvas, Size size) {
    final colors = [
      AppTheme.hosiPeach.withValues(alpha: 0.12),
      AppTheme.hosiBrown.withValues(alpha: 0.10),
      AppTheme.hosiPeach.withValues(alpha: 0.06),
      Colors.white.withValues(alpha: 0.04),
    ];
    const stripeWidth = 32.0;
    const step = stripeWidth * 2.5;
    final paint = Paint()..style = PaintingStyle.fill;

    for (double x = -size.height; x < size.width + size.height; x += step) {
      for (int i = 0; i < colors.length; i++) {
        paint.color = colors[i % colors.length];
        final path = Path();
        final offset = x + i * stripeWidth * 0.8;
        path.moveTo(offset, 0);
        path.lineTo(offset + stripeWidth * 0.6, 0);
        path.lineTo(offset + stripeWidth * 0.6 + size.height, size.height);
        path.lineTo(offset + size.height, size.height);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawAdinkraCorners(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.hosiPeach.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final corners = [
      Offset(24, 24),
      Offset(size.width - 24, 24),
      Offset(24, size.height - 24),
      Offset(size.width - 24, size.height - 24),
    ];

    for (final c in corners) {
      canvas.drawRect(Rect.fromCenter(center: c, width: 20, height: 20), paint);
      canvas.drawRect(Rect.fromCenter(center: c, width: 12, height: 12), paint);
    }
  }

  @override
  bool shouldRepaint(_KentePainter oldDelegate) => false;
}
