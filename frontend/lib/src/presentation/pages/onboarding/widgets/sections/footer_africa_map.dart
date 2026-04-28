import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

// ── Contact data ──────────────────────────────────────────────────────────────

class _Office {
  final String flag;
  final String country;
  final String city;
  final String? email;
  final String? phone;
  /// Normalized position on the ChatGPT Africa map image (0–1).
  final double nx;
  final double ny;

  const _Office({
    required this.flag,
    required this.country,
    required this.city,
    this.email,
    this.phone,
    required this.nx,
    required this.ny,
  });
}

/// Calibrated for full-Africa map (AfricaMap.png, 1024×1536 px, white background).
/// Geographic extent: ~20°W–52°E lon, ~37°N–35°S lat (8 % margin each side).
/// Projection: nx = 0.01083 * lon + 0.327 ; ny = 0.01208 * (37 − lat) + 0.065
const _kOffices = [
  _Office(
    flag: '🇿🇦', country: 'South Africa', city: 'Johannesburg',
    email: 'info@hosiacademy.com', phone: '+27 (0) 11 023 1995',
    nx: 0.630, ny: 0.826,  // 28°E, 26°S
  ),
  _Office(
    flag: '🇰🇪', country: 'Kenya', city: 'Nairobi',
    email: 'info@hosiacademy.com', phone: '+27 (0) 11 023 1995',
    nx: 0.728, ny: 0.528,  // 37°E,  1°S
  ),
  _Office(
    flag: '🇿🇲', country: 'Zambia', city: 'Lusaka',
    email: 'info@hosiacademy.com', phone: '+27 (0) 11 023 1995',
    nx: 0.633, ny: 0.698,  // 28°E, 15°S
  ),
  _Office(
    flag: '🇿🇼', country: 'Zimbabwe', city: 'Harare',
    email: 'info@hosiacademy.com', phone: '+27 (0) 11 023 1995',
    nx: 0.664, ny: 0.727,  // 31°E, 18°S
  ),
  _Office(
    flag: '🇧🇼', country: 'Botswana', city: 'Gaborone',
    email: 'info@hosiacademy.com', phone: '+27 (0) 11 023 1995',
    nx: 0.607, ny: 0.809,  // 26°E, 25°S
  ),
];

// ── Widget ────────────────────────────────────────────────────────────────────

/// Embedded interactive Africa contacts map for the onboarding footer.
/// Shows the ChatGPT-generated Africa map image with tappable country dots.
/// Tapping a dot reveals the office contact card on the right / below.
class FooterAfricaMap extends StatefulWidget {
  const FooterAfricaMap({super.key});

  @override
  State<FooterAfricaMap> createState() => _FooterAfricaMapState();
}

class _FooterAfricaMapState extends State<FooterAfricaMap>
    with SingleTickerProviderStateMixin {
  _Office _selected = _kOffices.first; // SA selected by default
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _pick(_Office office) {
    if (office == _selected) return;
    _anim.reverse().then((_) {
      if (mounted) {
        setState(() => _selected = office);
        _anim.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    // Use AppTheme colors
    final hosiPeach = AppTheme.hosiPeach;
    final hosiMidnight = AppTheme.hosiMidnight;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 36,
        horizontal: screenWidth < 600 ? 20 : 48,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? hosiMidnight : colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: isDarkMode 
                  ? colorScheme.outline.withValues(alpha: 0.1)
                  : colorScheme.outline.withValues(alpha: 0.15), 
              width: 1),
          bottom: BorderSide(
              color: isDarkMode 
                  ? colorScheme.outline.withValues(alpha: 0.1)
                  : colorScheme.outline.withValues(alpha: 0.15), 
              width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hosiPeach.withValues(alpha: isDarkMode ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.language_rounded,
                    color: hosiPeach, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our African Offices',
                    style: TextStyle( 
                      color: isDarkMode ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: screenWidth < 600 ? 16 : 20,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Tap a country to see contact details',
                    style: TextStyle(
                      color: isDarkMode 
                          ? colorScheme.onSurface.withValues(alpha: 0.5)
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Map + info ────────────────────────────────────────────────
          isMobile ? _buildMobileLayout(colorScheme, isDarkMode, hosiPeach) : _buildDesktopLayout(colorScheme, isDarkMode, hosiPeach),

          const SizedBox(height: 20),

          // ── Country chips (quick-select) ──────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kOffices.map((o) {
              final sel = o == _selected;
              return GestureDetector(
                onTap: () => _pick(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? hosiPeach.withValues(alpha: isDarkMode ? 0.18 : 0.15)
                        : (isDarkMode ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.1) : colorScheme.outline.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? hosiPeach
                          : isDarkMode 
                              ? colorScheme.outline.withValues(alpha: 0.15)
                              : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(o.flag,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        o.country,
                        style: TextStyle(
                          color: sel
                              ? hosiPeach
                              : isDarkMode 
                                  ? colorScheme.onSurface.withValues(alpha: 0.7)
                                  : colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Layouts ───────────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(ColorScheme colorScheme, bool isDarkMode, Color hosiPeach) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map — 58 %
        Expanded(
          flex: 58,
          child: SizedBox(height: 340, child: _buildMap()),
        ),
        const SizedBox(width: 32),
        // Contact card — 42 %
        Expanded(
          flex: 42,
          child: _buildContactCard(colorScheme, isDarkMode, hosiPeach),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ColorScheme colorScheme, bool isDarkMode, Color hosiPeach) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: _buildMap(),
        ),
        const SizedBox(height: 20),
        _buildContactCard(colorScheme, isDarkMode, hosiPeach),
      ],
    );
  }

  // ── Interactive map ───────────────────────────────────────────────────────

  // Image native aspect ratio: 1024 / 1536 = 0.6667
  static const double _kImgAspect = 1024.0 / 1536.0;

  Widget _buildMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerW = constraints.maxWidth;
        final containerH = constraints.maxHeight;

        // Compute actual rendered image bounds under BoxFit.contain
        final double renderedW, renderedH;
        if (containerW / containerH > _kImgAspect) {
          renderedH = containerH;
          renderedW = containerH * _kImgAspect;
        } else {
          renderedW = containerW;
          renderedH = containerW / _kImgAspect;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Map image - no pins/dots overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/social/africa_contacts_map.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3347),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.map_outlined,
                          color: Color(0x44FFFFFF), size: 60),
                    ),
                  ),
                ),
              ),
            ),

            // Note: Country pins/dots have been removed as per design requirements
            // Users can still select countries via the chip buttons below the map
          ],
        );
      },
    );
  }

  // ── Contact card ──────────────────────────────────────────────────────────

  Widget _buildContactCard(ColorScheme colorScheme, bool isDarkMode, Color hosiPeach) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hosiPeach.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flag + country
            Row(
              children: [
                Text(_selected.flag,
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected.country,
                        style: TextStyle( 
                          color: isDarkMode ? Colors.white : colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        _selected.city,
                        style: TextStyle(
                          color: isDarkMode 
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Divider(
              color: isDarkMode 
                  ? colorScheme.outline.withValues(alpha: 0.15)
                  : colorScheme.outline.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 14),

            if (_selected.email != null)
              _InfoRow(
                icon: Icons.email_outlined,
                text: _selected.email!,
                color: hosiPeach,
              ),
            if (_selected.phone != null) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.phone_outlined,
                text: _selected.phone!,
                color: isDarkMode 
                    ? colorScheme.onSurface.withValues(alpha: 0.7)
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: hosiPeach.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Active Office',
                style: TextStyle(
                  color: hosiPeach,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(color: color, fontSize: 13)),
        ),
      ],
    );
  }
}
