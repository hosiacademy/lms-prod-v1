// lib/src/presentation/pages/industry_training/components/industry_training_filters.dart
import 'package:flutter/material.dart';

class IndustryTrainingFilters extends StatelessWidget {
  final String selectedIndustry;
  final String selectedLevel;
  final String selectedRole;
  final String? selectedCountry;
  final String? selectedCity;
  final List<String> countries;
  final List<String> cities;
  final Function(String) onIndustryChanged;
  final Function(String) onLevelChanged;
  final Function(String) onRoleChanged;
  final Function(String?) onCountryChanged;
  final Function(String?) onCityChanged;

  const IndustryTrainingFilters({
    super.key,
    required this.selectedIndustry,
    required this.selectedLevel,
    required this.selectedRole,
    required this.selectedCountry,
    required this.selectedCity,
    required this.countries,
    required this.cities,
    required this.onIndustryChanged,
    required this.onLevelChanged,
    required this.onRoleChanged,
    required this.onCountryChanged,
    required this.onCityChanged,
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
      child: Row(
        children: [
          // Industry/Level/Role filters - wrapped in Flexible to prevent overflow
          Flexible(
            flex: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterButton(
                    label: 'All',
                    type: 'all',
                    isActive: selectedIndustry == 'all',
                    onTap: () => onIndustryChanged('all'),
                    context: context,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterButton(
                    label: 'Healthcare',
                    type: 'healthcare',
                    isActive: selectedIndustry == 'healthcare',
                    onTap: () => onIndustryChanged('healthcare'),
                    context: context,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterButton(
                    label: 'Business',
                    type: 'business',
                    isActive: selectedIndustry == 'business',
                    onTap: () => onIndustryChanged('business'),
                    context: context,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterButton(
                    label: 'Technical',
                    type: 'technical',
                    isActive: selectedIndustry == 'technical',
                    onTap: () => onIndustryChanged('technical'),
                    context: context,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Location filters - expands to fill remaining space
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
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required String type,
    required bool isActive,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
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

    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      hint: Row(
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
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
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
        ...items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
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
