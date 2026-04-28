// lib/src/presentation/blocs/course/learnerships/components/learnership_filters.dart
import 'package:flutter/material.dart';

class LearnershipFilters extends StatelessWidget {
  final String selectedRole;
  final String? selectedCountry;
  final String? selectedCity;
  final List<String> roles;
  final List<String> countries;
  final List<String> cities;
  final Function(String) onRoleChanged;
  final Function(String?) onCountryChanged;
  final Function(String?) onCityChanged;
  final VoidCallback onResetFilters;

  const LearnershipFilters({
    super.key,
    required this.selectedRole,
    required this.selectedCountry,
    required this.selectedCity,
    required this.roles,
    required this.countries,
    required this.cities,
    required this.onRoleChanged,
    required this.onCountryChanged,
    required this.onCityChanged,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role filters (top row)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRoleButton(
                    label: 'All',
                    role: 'all',
                    context: context,
                  ),
                  const SizedBox(width: 6),
                  _buildRoleButton(
                    label: 'AI Engineer',
                    role: 'ai_engineer_ai_architect',
                    context: context,
                  ),
                  const SizedBox(width: 6),
                  _buildRoleButton(
                    label: 'Data Scientist',
                    role: 'data_scientist_data_analyst',
                    context: context,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Location filters (bottom row)
          Row(
            children: [
              Expanded(
                child: Container(
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
                      const SizedBox(width: 12),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Reset filters button
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: onResetFilters,
                tooltip: 'Reset Filters',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required String label,
    required String role,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = selectedRole == role;

    return GestureDetector(
      onTap: () => onRoleChanged(role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      initialValue: value,
      hint: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
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
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        filled: true,
        fillColor: enabled
            ? colorScheme.surface
            : colorScheme.surface.withValues(alpha: 0.5),
        isCollapsed: true,
        constraints: const BoxConstraints(
          minHeight: 32,
        ),
      ),
      isExpanded: true,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurface,
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        size: 16,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
