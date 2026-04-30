import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AfricanOfficesSection extends StatelessWidget {
  const AfricanOfficesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.005; // Exactly 0.5% each side = 99% content width

    return Container(
      // Background adapts to theme
      color: isDark 
          ? const Color(0xFF0B1C2C) 
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 48),
      width: screenWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Section Header ──
          Text(
            "Visit Our African Offices",
            style: TextStyle(
              color: isDark ? const Color(0xFFFFA726) : colorScheme.primary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // ── Cards Wrap (Responsive Grid) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              // On large screens, 4 cards. On medium, 2. On small, 1.
              int crossAxisCount = 4;
              if (availableWidth < 600) {
                crossAxisCount = 1;
              } else if (availableWidth < 1000) {
                crossAxisCount = 2;
              }
              
              const spacing = 12.0; // Tighter spacing for collective presence
              final cardWidth = (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: [
                  _buildOfficeCard(
                    context,
                    country: "South Africa",
                    city: "Johannesburg",
                    address: "Montecasino Blvd, Fourways",
                    phone: "+27 11 023 1995",
                    hours: "Mon–Fri 9AM–5PM",
                    flag: "🇿🇦",
                    googleMapsUrl: "https://maps.google.com/?q=Montecasino+Blvd+Fourways+Johannesburg",
                    cardWidth: cardWidth,
                  ),
                  _buildOfficeCard(
                    context,
                    country: "Kenya",
                    city: "Nairobi",
                    address: "The Oval House, Ring Rd, Westlands",
                    phone: "+254 20 221 2701",
                    hours: "Mon–Fri 8AM–5PM",
                    flag: "🇰🇪",
                    googleMapsUrl: "https://maps.google.com/?q=The+Oval+House+Westlands+Nairobi",
                    cardWidth: cardWidth,
                  ),
                  _buildOfficeCard(
                    context,
                    country: "Zimbabwe",
                    city: "Harare",
                    address: "100 Liberation Legacy Way",
                    phone: "+263 242 700 000",
                    hours: "Mon–Fri 8:30AM–4:30PM",
                    flag: "🇿🇼",
                    googleMapsUrl: "https://maps.google.com/?q=100+Liberation+Legacy+Way+Harare",
                    cardWidth: cardWidth,
                  ),
                  _buildOfficeCard(
                    context,
                    country: "Zambia",
                    city: "Lusaka",
                    address: "Cairo Rd, Central Business District",
                    phone: "+260 211 234 567",
                    hours: "Mon–Fri 8AM–5PM",
                    flag: "🇿🇲",
                    googleMapsUrl: "https://maps.google.com/?q=Cairo+Rd+Lusaka",
                    cardWidth: cardWidth,
                  ),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeCard(
    BuildContext context, {
    required String country,
    required String city,
    required String address,
    required String phone,
    required String hours,
    required String flag,
    required String googleMapsUrl,
    required double cardWidth,
  }) {
    return OfficeCard(
      country: country,
      city: city,
      address: address,
      phone: phone,
      hours: hours,
      flag: flag,
      googleMapsUrl: googleMapsUrl,
      width: cardWidth,
    );
  }
}

class OfficeCard extends StatelessWidget {
  final String country;
  final String city;
  final String address;
  final String phone;
  final String hours;
  final String flag;
  final String googleMapsUrl;
  final double width;

  const OfficeCard({
    super.key,
    required this.country,
    required this.city,
    required this.address,
    required this.phone,
    required this.hours,
    required this.flag,
    required this.googleMapsUrl,
    required this.width,
  });

  Future<void> _launchMap() async {
    final uri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10263A) : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1) 
              : colorScheme.outline.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country,
                      style: TextStyle(
                        color: isDark ? Colors.white : colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      city,
                      style: TextStyle(
                        color: isDark 
                            ? const Color(0xFF8E9AAF) 
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            address,
            style: TextStyle(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.7) 
                  : colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.phone_android_rounded, 
                size: 14, 
                color: isDark ? const Color(0xFFFFA726) : colorScheme.primary
              ),
              const SizedBox(width: 6),
              Text(
                phone,
                style: TextStyle(
                  color: isDark ? const Color(0xFFFFA726) : colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: _launchMap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [const Color(0xFFFFA726), const Color(0xFFFF7043)]
                        : [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "GET DIRECTIONS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
