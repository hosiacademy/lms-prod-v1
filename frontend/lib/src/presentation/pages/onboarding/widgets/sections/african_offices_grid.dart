import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AfricanOfficesGrid extends StatelessWidget {
  const AfricanOfficesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final offices = [
      const _OfficeData(
        flag: '🇿🇦',
        country: 'South Africa',
        city: 'Johannesburg',
        address: 'Montecasino Blvd, Fourways',
        phone: '+27 (0) 11 023 1995',
        hours: 'Mon–Fri 9AM–5PM',
        mapsUrl: 'https://maps.google.com/?q=Montecasino+Blvd,+Fourways,+Johannesburg',
      ),
      const _OfficeData(
        flag: '🇰🇪',
        country: 'Kenya',
        city: 'Nairobi',
        address: 'The Oval House, Ring Rd, Westlands',
        phone: '+254 20 514 1000',
        hours: 'Mon–Fri 9AM–5PM',
        mapsUrl: 'https://maps.google.com/?q=The+Oval+House,+Ring+Rd,+Westlands,+Nairobi',
      ),
      const _OfficeData(
        flag: '🇿🇼',
        country: 'Zimbabwe',
        city: 'Harare',
        address: '100 Liberation Legacy Way',
        phone: '+263 242 700 000',
        hours: 'Mon–Fri 8:30AM–5PM',
        mapsUrl: 'https://maps.google.com/?q=100+Liberation+Legacy+Way,+Harare',
      ),
      const _OfficeData(
        flag: '🇿🇲',
        country: 'Zambia',
        city: 'Lusaka',
        address: 'Cairo Rd, Central Business District',
        phone: '+260 211 222 000',
        hours: 'Mon–Fri 9AM–5PM',
        mapsUrl: 'https://maps.google.com/?q=Cairo+Rd,+Central+Business+District,+Lusaka',
      ),
    ];

    return Container(
      width: double.infinity,
      color: isDarkMode 
          ? AppTheme.hosiMidnight 
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      padding: EdgeInsets.symmetric(
        vertical: 64,
        horizontal: screenWidth < 1200 ? 24 : screenWidth * 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Visit Our African Offices',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.hosiPeach, // Gold/orange
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 600 ? 24 : 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a card to open directions in Google Maps',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDarkMode ? Colors.grey[400] : theme.colorScheme.onSurface.withValues(alpha: 0.6), // Responsive grey
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 48),

          // Grid Layout
          screenWidth > 900
              ? Row(
                  children: offices
                      .map((o) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _OfficeCard(data: o),
                            ),
                          ))
                      .toList(),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth > 600 ? 2 : 1,
                    childAspectRatio: screenWidth > 600 ? 1.1 : 1.4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: offices.length,
                  itemBuilder: (context, index) => _OfficeCard(data: offices[index]),
                ),
        ],
      ),
    );
  }
}

class _OfficeData {
  final String flag;
  final String country;
  final String city;
  final String address;
  final String phone;
  final String hours;
  final String mapsUrl;

  const _OfficeData({
    required this.flag,
    required this.country,
    required this.city,
    required this.address,
    required this.phone,
    required this.hours,
    required this.mapsUrl,
  });
}

class _OfficeCard extends StatelessWidget {
  final _OfficeData data;

  const _OfficeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _launchURL(data.mapsUrl),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF0F1B2B) 
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode 
                ? Colors.white.withValues(alpha: 0.05)
                : theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3), // Soft shadow for depth
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Text(data.flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.country,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        data.city,
                        style: TextStyle(
                          color: isDarkMode 
                              ? Colors.white.withValues(alpha: 0.5)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.location_on_rounded,
                    color: Colors.redAccent, size: 20), // Red accent pin
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              color: isDarkMode 
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
              thickness: 1,
            ),
            const SizedBox(height: 16),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.map_outlined, color: Colors.white38, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.address,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contact + Hours Row
            Row(
              children: [
                // Phone (Clickable)
                GestureDetector(
                  onTap: () => _launchURL('tel:${data.phone.replaceAll(RegExp(r'[^\d+]'), '')}'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_outlined, color: AppTheme.hosiPeach, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        data.phone,
                        style: const TextStyle(
                          color: AppTheme.hosiPeach, // Highlighted in gold/orange
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Hours
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.grey, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      data.hours,
                      style: const TextStyle(color: Colors.grey, fontSize: 13), // Muted grey text
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 16),

            // CTA Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF79150), AppTheme.hosiPeach], // Orange -> gold gradient
                ),
                borderRadius: BorderRadius.circular(50), // Rounded pill button
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Get Directions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
