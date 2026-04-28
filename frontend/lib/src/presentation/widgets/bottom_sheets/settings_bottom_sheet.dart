// lib/src/presentation/widgets/bottom_sheets/settings_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/constants/african_currencies.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final themeService = context.watch<ThemeService>();
    final currencyService = context.watch<CurrencyService>();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 6,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Header with Refresh Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Settings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Theme from Server',
                onPressed: () async {
                  await themeService.initialize();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Theme refreshed from server'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Dark Mode Switch
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: Text(isDark ? 'Enabled' : 'Disabled'),
            secondary: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: colorScheme.primary,
            ),
            value: isDark,
            onChanged: (value) {
              themeService.toggleTheme();
            },
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.primary;
              }
              return null;
            }),
          ),

          const Divider(height: 40),

          // Accent Color Preview
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.tertiary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor, width: 2),
              ),
            ),
            title: const Text('Accent Color (from server)'),
            subtitle: Text(colorScheme.tertiary.toString()),
          ),

          const Divider(height: 40),

          // Language Selector (placeholder)
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('Language'),
            subtitle: const Text('English (South Africa)'), // TODO: dynamic
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language selection coming soon')),
              );
            },
          ),

          const Divider(height: 8),

          // Currency Selector
          ListTile(
            leading: const Icon(Icons.attach_money_rounded),
            title: const Text('Currency'),
            subtitle: Text(
              '${currencyService.userCurrency}'
              ' (Auto-detected)',
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () => _showCurrencyPicker(context, currencyService),
          ),

          const SizedBox(height: 24),

          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(
      BuildContext context, CurrencyService currencyService) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color:
                            theme.dividerColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Text(
                    'Select Currency',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Auto-detect option
                        ListTile(
                          leading: const Icon(Icons.my_location_rounded),
                          title: const Text('Auto-detect from location'),
                          subtitle: const Text('Uses your IP address'),
                          selected: !currencyService.isManualOverride,
                          selectedColor: theme.colorScheme.primary,
                          onTap: () async {
                            Navigator.pop(ctx);
                            await currencyService.resetToAutoDetect();
                          },
                        ),
                        const Divider(),
                        // Country list
                        ...AfricanCurrencies.countries.map((country) {
                          final isSelected =
                              currencyService.isManualOverride &&
                                  currencyService.userCountryCode ==
                                      country.code;
                          return ListTile(
                            title: Text(country.name),
                            subtitle: Text(
                                '${country.currencyCode} — ${country.currencyName}'),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary)
                                : null,
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primary,
                            onTap: () async {
                              Navigator.pop(ctx);
                              currencyService
                                  .setUserCountryCode(country.code);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
