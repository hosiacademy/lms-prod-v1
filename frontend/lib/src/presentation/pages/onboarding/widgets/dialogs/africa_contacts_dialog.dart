import 'package:flutter/material.dart';

// ── Contact data ──────────────────────────────────────────────────────────────

class _Office {
  final String flag;
  final String country;
  final String city;
  final String? email;
  final String? phone;
  /// Normalized x/y position on the africa_map.png image (0‑1).
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

/// Image-space coordinates: fraction of the actual 1024×1536 map image dimensions.
/// Full-Africa map (AfricaMap.png, 1024×1536 px, white background).
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
    email: 'info@hosiacademy.com', phone: '+254 20 514 1000',
    nx: 0.728, ny: 0.528,  // 37°E,  1°S
  ),
  _Office(
    flag: '🇿🇲', country: 'Zambia', city: 'Lusaka',
    email: 'info@hosiacademy.com', phone: '+260 211 222 000',
    nx: 0.633, ny: 0.698,  // 28°E, 15°S
  ),
  _Office(
    flag: '🇿🇼', country: 'Zimbabwe', city: 'Harare',
    email: 'info@hosiacademy.com', phone: '+263 242 700 000',
    nx: 0.664, ny: 0.727,  // 31°E, 18°S
  ),
  _Office(
    flag: '🇧🇼', country: 'Botswana', city: 'Gaborone',
    email: 'info@hosiacademy.com', phone: '+27 (0) 11 023 1995',
    nx: 0.607, ny: 0.809,  // 26°E, 25°S
  ),
];

// ── Dialog ────────────────────────────────────────────────────────────────────

class AfricaContactsDialog extends StatefulWidget {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const AfricaContactsDialog(),
    );
  }

  const AfricaContactsDialog({super.key});

  @override
  State<AfricaContactsDialog> createState() => _AfricaContactsDialogState();
}

class _AfricaContactsDialogState extends State<AfricaContactsDialog>
    with SingleTickerProviderStateMixin {
  _Office? _selected;
  late AnimationController _anim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    // Default: select South Africa
    _selected = _kOffices.first;
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _selectOffice(_Office office) {
    if (_selected == office) return;
    _anim.reverse().then((_) {
      if (mounted) {
        setState(() => _selected = office);
        _anim.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isSmall ? 12 : 40),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmall ? double.infinity : 880,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2030),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF79150).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language_rounded,
                        color: Color(0xFFF79150), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Our African Offices',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'Click a country on the map to see contact details',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.6)),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            Divider(
                color: Colors.white.withValues(alpha: 0.08),
                height: 20,
                indent: 24,
                endIndent: 24),

            // ── Body ───────────────────────────────────────────────────────
            Flexible(
              child: isSmall
                  ? _buildSmallBody()
                  : _buildLargeBody(),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Large (side-by-side) ──────────────────────────────────────────────────

  Widget _buildLargeBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Map — left 60 %
          Expanded(
            flex: 6,
            child: SizedBox(
              height: 380,
              child: _buildInteractiveMap(),
            ),
          ),
          const SizedBox(width: 28),
          // Contact card — right 40 %
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildContactCard(),
                const SizedBox(height: 24),
                _buildOfficeChips(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Small (stacked) ───────────────────────────────────────────────────────

  Widget _buildSmallBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: _buildInteractiveMap(),
          ),
          const SizedBox(height: 16),
          _buildContactCard(),
          const SizedBox(height: 16),
          _buildOfficeChips(),
        ],
      ),
    );
  }

  // ── Interactive map ───────────────────────────────────────────────────────

  /// Africa map image actual dimensions: 1024 × 1536 px (portrait 2 : 3 ratio).
  /// All office nx/ny values are image-space fractions (0‑1 relative to the
  /// full image), NOT container-space fractions.  We correct for the margins
  /// introduced by BoxFit.contain at render time.
  static const double _kImgAspect = 1024.0 / 1536.0; // ≈ 0.6667

  Widget _buildInteractiveMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerW = constraints.maxWidth;
        final containerH = constraints.maxHeight;
        const r = 14.0;

        // ── Compute rendered image size under BoxFit.contain ───────────────
        final double renderedW, renderedH;
        if (containerW / containerH > _kImgAspect) {
          // Container is wider than the image ratio → height fills, width < container
          renderedH = containerH;
          renderedW = containerH * _kImgAspect;
        } else {
          // Container is taller (or equal) → width fills, height < container
          renderedW = containerW;
          renderedH = containerW / _kImgAspect;
        }

        // Centring offsets (image is centred by Alignment.center)
        final offsetX = (containerW - renderedW) / 2;
        final offsetY = (containerH - renderedH) / 2;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Africa map image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/social/africa_contacts_map.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A4A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.map_outlined,
                          color: Color(0x55FFFFFF), size: 60),
                    ),
                  ),
                ),
              ),
            ),

            // Interactive dots
            ..._kOffices.map((office) {
              final isSelected = office == _selected;
              // nx/ny are fractions of the original image (0-1).
              // We map them to the rendered size and apply the letterbox offsets.
              final x = offsetX + (office.nx * renderedW) - r;
              final y = offsetY + (office.ny * renderedH) - r;

              return Positioned(
                left: x,
                top: y,
                child: GestureDetector(
                  onTap: () => _selectOffice(office),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: _buildDot(office, r, isSelected),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildDot(_Office office, double r, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: r * 2,
      height: r * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? const Color(0xFFF79150)
            : const Color(0xFFF79150).withValues(alpha: 0.45),
        border: Border.all(
          color: Colors.white,
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFFF79150).withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
    );
  }

  // ── Contact card ──────────────────────────────────────────────────────────

  Widget _buildContactCard() {
    if (_selected == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFF79150).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(_selected!.flag,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected!.country,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _selected!.city,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_selected!.email != null) ...[
              const SizedBox(height: 16),
              _ContactRow(
                icon: Icons.email_outlined,
                text: _selected!.email!,
                color: const Color(0xFFF79150),
              ),
            ],
            if (_selected!.phone != null) ...[
              const SizedBox(height: 8),
              _ContactRow(
                icon: Icons.phone_outlined,
                text: _selected!.phone!,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF79150).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Active Office',
                style: TextStyle(
                  color: Color(0xFFF79150),
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

  // ── Office chips (quick‑select) ───────────────────────────────────────────

  Widget _buildOfficeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kOffices.map((office) {
        final isSelected = office == _selected;
        return GestureDetector(
          onTap: () => _selectOffice(office),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF79150).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF79150)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(office.flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  office.country,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFF79150)
                        : Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Contact row helper ────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ContactRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
