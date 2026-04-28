// lib/src/presentation/blocs/course/corporate/components/masterclass_filters.dart
import 'package:flutter/material.dart';

class MasterclassFilters extends StatelessWidget {
  final String selectedType;
  final String? selectedCountry;
  final String? selectedCity;
  final String? selectedVenue;
  final List<String> countries;
  final List<String> cities;
  final List<String> venues;
  final Function(String) onTypeChanged;
  final Function(String?) onCountryChanged;
  final Function(String?) onCityChanged;
  final Function(String?) onVenueChanged;
  final VoidCallback? onResetAllFilters; // New callback for "ALL" button

  const MasterclassFilters({
    super.key,
    required this.selectedType,
    required this.selectedCountry,
    required this.selectedCity,
    required this.selectedVenue,
    required this.countries,
    required this.cities,
    required this.venues,
    required this.onTypeChanged,
    required this.onCountryChanged,
    required this.onCityChanged,
    required this.onVenueChanged,
    this.onResetAllFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isSmallMobile = constraints.maxWidth < 400; // Extra small screens

        // Type filter bar with better mobile spacing
        final typeBar = Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ), // Increased padding
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypeButton(label: 'All', type: 'all', context: context),
                const SizedBox(width: 10), // Increased spacing
                _buildTypeButton(
                  label: 'Technical',
                  type: 'technical',
                  context: context,
                ),
                const SizedBox(width: 10),
                _buildTypeButton(
                  label: 'Professional',
                  type: 'professional',
                  context: context,
                ),
              ],
            ),
          ),
        );

        final locationBar = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildCompactDropdown(
                  label: 'Country',
                  icon: Icons.public,
                  value: selectedCountry,
                  items: countries,
                  onChanged: onCountryChanged,
                  context: context,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactDropdown(
                  label: 'City',
                  icon: Icons.location_on,
                  value: selectedCity,
                  items: cities,
                  onChanged: onCityChanged,
                  enabled: selectedCountry != null,
                  context: context,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactDropdown(
                  label: 'Venue',
                  icon: Icons.apartment,
                  value: selectedVenue,
                  items: venues,
                  onChanged: onVenueChanged,
                  enabled: selectedCity != null,
                  context: context,
                ),
              ),
            ],
          ),
        );

        // Mobile: dropdowns stacked vertically for usability with improved spacing
        final mobileLocationBar = Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12), // Increased padding
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCompactDropdown(
                label: 'Country',
                icon: Icons.public,
                value: selectedCountry,
                items: countries,
                onChanged: onCountryChanged,
                context: context,
              ),
              const SizedBox(height: 12), // Increased from 8
              _buildCompactDropdown(
                label: 'City',
                icon: Icons.location_on,
                value: selectedCity,
                items: cities,
                onChanged: onCityChanged,
                enabled: selectedCountry != null,
                context: context,
              ),
              const SizedBox(height: 12),
              _buildCompactDropdown(
                label: 'Venue',
                icon: Icons.apartment,
                value: selectedVenue,
                items: venues,
                onChanged: onVenueChanged,
                enabled: selectedCity != null,
                context: context,
              ),
            ],
          ),
        );

        if (isMobile) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [typeBar, const SizedBox(height: 8), mobileLocationBar],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Flexible(flex: 0, child: typeBar),
              const SizedBox(width: 16),
              Expanded(child: locationBar),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String type,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = selectedType == type;

    return GestureDetector(
      onTap: () {
        if (type == 'all') {
          if (onResetAllFilters != null) {
            onResetAllFilters!();
          } else {
            // Fallback if not provided
            onTypeChanged(type);
            onCountryChanged(null);
            onCityChanged(null);
            onVenueChanged(null);
          }
        } else {
          onTypeChanged(type);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required BuildContext context,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Ensure unique values for dropdown
    final uniqueItems = <String>[];
    final itemCounts = <String, int>{};

    for (final item in items) {
      itemCounts[item] = (itemCounts[item] ?? 0) + 1;
    }

    for (final item in items) {
      if (itemCounts[item]! > 1) {
        final indices = items
            .asMap()
            .entries
            .where((entry) => entry.value == item)
            .map((entry) => entry.key + 1)
            .toList();

        final index = items.indexOf(item);
        if (indices.first == index + 1) {
          uniqueItems.add(item);
        } else {
          uniqueItems.add('$item (${indices.indexOf(index + 1) + 1})');
        }
      } else {
        uniqueItems.add(item);
      }
    }

    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      value: value,
      hint: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16, color: colorScheme.onSurface.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      items: [
        // "All" option that resets the filter
        DropdownMenuItem<String>(
          value: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'All',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...uniqueItems.map((item) {
          return DropdownMenuItem<String>(
            value: item.contains('(') ? item.split('(')[0].trim() : item,
            child: Text(
              item,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ],
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),  // Increased padding
        filled: true,
        fillColor: enabled
            ? colorScheme.surface
            : colorScheme.surface.withValues(alpha: 0.5),
        isDense: false,  // Changed to false for better touch targets
        constraints: const BoxConstraints(minHeight: 52),  // Increased min height
      ),
      isExpanded: true,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurface,
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        size: 24,
        color: colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(6),
      alignment: AlignmentDirectional.centerStart,  // Ensure alignment
    );
  }
}
