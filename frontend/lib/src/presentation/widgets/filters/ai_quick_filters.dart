import 'package:flutter/material.dart';

/// AI-powered quick filter chips for course discovery
class AiQuickFilters extends StatefulWidget {
  final Function(String filter) onFilterSelected;
  final String? selectedFilter;

  const AiQuickFilters({
    super.key,
    required this.onFilterSelected,
    this.selectedFilter,
  });

  @override
  State<AiQuickFilters> createState() => _AiQuickFiltersState();
}

class _AiQuickFiltersState extends State<AiQuickFilters> {
  final List<QuickFilter> _filters = [
    QuickFilter(
      id: 'recommended',
      label: 'Recommended for me',
      icon: Icons.auto_awesome,
      description: 'AI-curated courses based on your profile',
    ),
    QuickFilter(
      id: 'trending',
      label: 'Trending this week',
      icon: Icons.trending_up,
      description: 'Most popular courses right now',
    ),
    QuickFilter(
      id: 'quick_complete',
      label: 'Quick to complete',
      icon: Icons.flash_on,
      description: 'Short courses you can finish quickly',
    ),
    QuickFilter(
      id: 'highly_rated',
      label: 'Highly rated',
      icon: Icons.star,
      description: 'Top-rated courses by students',
    ),
    QuickFilter(
      id: 'starting_soon',
      label: 'Starting soon',
      icon: Icons.schedule,
      description: 'Courses with upcoming start dates',
    ),
    QuickFilter(
      id: 'new_arrivals',
      label: 'New arrivals',
      icon: Icons.fiber_new,
      description: 'Recently added courses',
    ),
    QuickFilter(
      id: 'best_sellers',
      label: 'Best sellers',
      icon: Icons.local_fire_department,
      description: 'Most enrolled courses',
    ),
    QuickFilter(
      id: 'free_courses',
      label: 'Free courses',
      icon: Icons.card_giftcard,
      description: 'Courses with no cost',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.psychology, size: 20, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'AI Quick Filters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: _filters.map((filter) {
              final isSelected = widget.selectedFilter == filter.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(filter, isSelected, theme, colors),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    QuickFilter filter,
    bool isSelected,
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Tooltip(
      message: filter.description,
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              size: 16,
              color: isSelected ? colors.onPrimary : colors.onSurface,
            ),
            const SizedBox(width: 6),
            Text(filter.label),
          ],
        ),
        onSelected: (selected) {
          widget.onFilterSelected(selected ? filter.id : '');
        },
        backgroundColor: colors.surface,
        selectedColor: colors.primary,
        checkmarkColor: colors.onPrimary,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? colors.onPrimary : colors.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outline,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// Model for quick filter data
class QuickFilter {
  final String id;
  final String label;
  final IconData icon;
  final String description;

  QuickFilter({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}
