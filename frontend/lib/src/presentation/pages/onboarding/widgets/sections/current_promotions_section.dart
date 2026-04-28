import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/services/currency_service.dart';

class _PromoData {
  final int id;
  final String code;
  final String name;
  final String description;
  final String discountLabel;
  final String pathwayLabel;
  final String pathway;
  final String? countryLabel;
  final int daysRemaining;
  final bool isAutoApplied;
  final bool showCode;

  const _PromoData({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discountLabel,
    required this.pathwayLabel,
    required this.pathway,
    this.countryLabel,
    required this.daysRemaining,
    required this.isAutoApplied,
    required this.showCode,
  });

  factory _PromoData.fromJson(Map<String, dynamic> j) => _PromoData(
        id: j['id'] as int,
        code: j['code'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        discountLabel: j['discount_label'] as String,
        pathwayLabel: j['pathway_label'] as String,
        pathway: j['pathway'] as String? ?? '',
        countryLabel: j['country_label'] as String?,
        daysRemaining: j['days_remaining'] as int? ?? 0,
        isAutoApplied: j['is_auto_applied'] as bool? ?? false,
        showCode: j['show_code'] as bool? ?? true,
      );
}

/// Horizontal scrollable "Current Promotions" strip shown on the onboarding page.
class CurrentPromotionsSection extends StatefulWidget {
  /// Called when user taps "Enroll →" on an event-specific (non-auto) promo card.
  /// Receives the promo pathway string (e.g. 'masterclass').
  final void Function(String pathway)? onEnrollTap;

  const CurrentPromotionsSection({super.key, this.onEnrollTap});

  @override
  State<CurrentPromotionsSection> createState() =>
      _CurrentPromotionsSectionState();
}

class _CurrentPromotionsSectionState extends State<CurrentPromotionsSection> {
  List<_PromoData> _promos = [];
  bool _loaded = false;

  static const List<Color> _palette = [
    Color(0xFF172E3D), // hosiMidnight
    Color(0xFF8C4928), // hosiBrown
    Color(0xFF1B5E20), // deep green
    Color(0xFF1A237E), // deep indigo
    Color(0xFF4A148C), // deep purple
    Color(0xFF880E4F), // deep pink
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final country = CurrencyService.instance.countryCode ?? 'ZA';
      final resp = await ApiClient.get(
        '/api/v1/payments/coupons/public/',
        queryParameters: {'country': country},
      );
      final list = resp.data as List<dynamic>;
      if (mounted) {
        setState(() {
          _promos = list
              .map((e) => _PromoData.fromJson(e as Map<String, dynamic>))
              .toList();
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _promos.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = screenWidth < 768 ? 20.0 : 64.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? colors.surface
            : const Color(0xFFF8F9FA),
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Row(
              children: [
                const Text('🏷️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(
                  'PROMOTIONS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: screenWidth < 768 ? 16 : 18,
                    letterSpacing: 1.2,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${_promos.length} Active',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: hPad, right: hPad - 14),
              itemCount: _promos.length,
              itemBuilder: (context, i) => _PromoCard(
                promo: _promos[i],
                bg: _palette[i % _palette.length],
                onEnrollTap: widget.onEnrollTap != null
                    ? () => widget.onEnrollTap!(_promos[i].pathway)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatefulWidget {
  final _PromoData promo;
  final Color bg;
  final VoidCallback? onEnrollTap;

  const _PromoCard({required this.promo, required this.bg, this.onEnrollTap});

  @override
  State<_PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<_PromoCard> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.promo.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promo;
    final bg = widget.bg;
    const fg = Colors.white;

    return Container(
      width: 268,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle top-right
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Discount badge row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        promo.discountLabel,
                        style: const TextStyle(
                          color: fg,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (promo.isAutoApplied)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'AUTO',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Name
                Text(
                  promo.name,
                  style: const TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Pathway + country
                Row(
                  children: [
                    Icon(Icons.category_outlined,
                        size: 11, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        promo.pathwayLabel +
                            (promo.countryLabel != null
                                ? ' · ${promo.countryLabel}'
                                : ''),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Bottom action — code (auto) or enroll button (event)
                if (promo.showCode) _buildCodeRow(fg) else _buildEnrollRow(fg),
                if (promo.daysRemaining > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${promo.daysRemaining} day${promo.daysRemaining == 1 ? '' : 's'} remaining',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeRow(Color fg) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.promo.code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _copy,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 16,
              color: _copied ? Colors.green.shade300 : fg,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollRow(Color fg) {
    return GestureDetector(
      onTap: widget.onEnrollTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            const Text(
              'I have a code — Enroll',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded,
                size: 13, color: Colors.white.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}
