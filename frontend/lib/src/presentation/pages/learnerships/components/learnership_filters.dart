// lib/src/presentation/pages/learnerships/components/learnership_filters.dart
import 'package:flutter/material.dart';

class LearnershipFilters extends StatelessWidget {
  final String selectedSpecialization;
  final String? selectedCountry;
  final String? selectedCity;
  final List<String> countries;
  final List<String> cities;
  final List<String> specializations;
  final Function(String) onSpecializationChanged;
  final Function(String?) onCountryChanged;
  final Function(String?) onCityChanged;

  const LearnershipFilters({
    super.key,
    required this.selectedSpecialization,
    required this.selectedCountry,
    required this.selectedCity,
    required this.countries,
    required this.cities,
    required this.specializations,
    required this.onSpecializationChanged,
    required this.onCountryChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final specializationBar = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSpecializationButton(
                  label: 'All',
                  type: 'all',
                  context: context,
                ),
                ...specializations.expand((spec) => [
                  const SizedBox(width: 6),
                  _buildSpecializationButton(
                    label: spec,
                    type: spec,
                    context: context,
                  ),
                ]),
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
              children: [
                specializationBar,
                const SizedBox(height: 8),
                locationBar,
              ],
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
              Flexible(flex: 0, child: specializationBar),
              const SizedBox(width: 16),
              Expanded(child: locationBar),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecializationButton({
    required String label,
    required String type,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = selectedSpecialization == type;

    return GestureDetector(
      onTap: () => onSpecializationChanged(type),
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
      value: value, // Keep value for selected item
      hint: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: colorScheme.onSurface.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.9),
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
        color: colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
