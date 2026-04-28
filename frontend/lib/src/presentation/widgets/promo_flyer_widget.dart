import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/promotion.dart';
import '../../core/services/promotion_service.dart';
import '../../core/services/currency_service.dart';

/// Animated promotional flyer that "drops in" from the top of the screen.
/// Shows the highest-priority active promotion for the user's country.
/// Auto-dismisses after 8 seconds or when the user closes it.
class PromoFlyerWidget extends StatefulWidget {
  /// Called when user taps the CTA button — passes the promotion back.
  final void Function(Promotion promo)? onCtaTap;
  final String countryCode;

  const PromoFlyerWidget({
    super.key,
    this.onCtaTap,
    this.countryCode = 'ZA',
  });

  @override
  State<PromoFlyerWidget> createState() => _PromoFlyerWidgetState();
}

class _PromoFlyerWidgetState extends State<PromoFlyerWidget>
    with SingleTickerProviderStateMixin {
  Promotion? _promo;
  bool _visible = false;
  bool _dismissed = false;
  Timer? _autoClose;

  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _loadPromo();
  }

  Future<void> _loadPromo() async {
    final promos = await PromotionService.instance.fetchForOnboarding(
      countryCode: widget.countryCode,
    );
    if (!mounted || promos.isEmpty) return;
    setState(() {
      _promo = promos.first;
      _visible = true;
    });
    // Short delay so page renders first, then drop in
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _ctrl.forward();
    _autoClose = Timer(const Duration(seconds: 9), _dismiss);
  }

  void _dismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
    _autoClose?.cancel();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _autoClose?.cancel();
    super.dispose();
  }

  Color _hexColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.deepOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _promo == null) return const SizedBox.shrink();
    final promo = _promo!;
    final bg = _hexColor(promo.backgroundColor);
    final fg = _hexColor(promo.textColor);
    final screenWidth = MediaQuery.of(context).size.width;
    final flyerWidth = (screenWidth * 0.9).clamp(280.0, 460.0);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: flyerWidth,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -24,
                    top: -24,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fg.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -16,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fg.withValues(alpha: 0.06),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: icon + days remaining + close
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon + discount badge
                            Column(
                              children: [
                                Text(
                                  promo.icon.isNotEmpty ? promo.icon : '🎉',
                                  style: const TextStyle(fontSize: 36),
                                ),
                                if (promo.discountPercentage != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: fg.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${promo.discountPercentage!.toStringAsFixed(0)}% OFF',
                                      style: TextStyle(
                                        color: fg,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(width: 14),
                            // Title + description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promo.title,
                                    style: TextStyle(
                                      color: fg,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    promo.description,
                                    style: TextStyle(
                                      color: fg.withValues(alpha: 0.88),
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Close button
                            GestureDetector(
                              onTap: _dismiss,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.close_rounded,
                                    color: fg.withValues(alpha: 0.7), size: 20),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Bottom row: days remaining + CTA
                        Row(
                          children: [
                            // Days remaining chip
                            if (promo.daysRemaining > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: fg.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_outlined,
                                        color: fg, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${promo.daysRemaining}d left',
                                      style: TextStyle(
                                        color: fg,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            const Spacer(),
                            // CTA button
                            GestureDetector(
                              onTap: () {
                                widget.onCtaTap?.call(promo);
                                _dismiss();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: fg,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  promo.ctaText,
                                  style: TextStyle(
                                    color: bg,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
