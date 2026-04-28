// lib/src/presentation/pages/student_portal/wishlist_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/student_portal/wishlist_bloc.dart';

import '../../../data/models/wishlist.dart';
import '../../../core/utils/responsive_utils.dart';

class WishlistPage extends StatefulWidget {
  final bool embedMode;
  const WishlistPage({Key? key, this.embedMode = false}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  String? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    context.read<WishlistBloc>().add(LoadWishlist());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedMode) {
      return _buildBody();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Pathways shortcuts
        _buildPathwaysShortcuts(),

        // Filter tabs
        _buildFilterTabs(),

        // Wishlist content
        Expanded(
          child: BlocConsumer<WishlistBloc, WishlistState>(
            listener: (context, state) {
              if (state is WishlistItemAdded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to wishlist')),
                );
              }
              if (state is WishlistItemRemoved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Removed from wishlist')),
                );
              }
              if (state is WishlistItemMovedToCart) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Moved to cart'),
                    action: SnackBarAction(
                      label: 'View Cart',
                      onPressed: () {
                        Navigator.pushNamed(context, '/cart');
                      },
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is WishlistLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is WishlistError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<WishlistBloc>().add(LoadWishlist());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is WishlistLoaded) {
                if (state.items.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildWishlistContent(state);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPathwaysShortcuts() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enrollment Pathways',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPathwayCard(
                  title: 'Masterclasses',
                  icon: Icons.school,
                  color: Colors.blue,
                  route: '/catalog?type=masterclass',
                ),
                const SizedBox(width: 12),
                _buildPathwayCard(
                  title: 'Learnerships',
                  icon: Icons.card_membership,
                  color: Colors.orange,
                  route: '/catalog?type=learnership',
                ),
                const SizedBox(width: 12),
                _buildPathwayCard(
                  title: 'Industry Training',
                  icon: Icons.business,
                  color: Colors.green,
                  route: '/catalog?type=industry_training',
                ),
                const SizedBox(width: 12),
                _buildPathwayCard(
                  title: 'Custom Selection',
                  icon: Icons.dashboard_customize,
                  color: Colors.purple,
                  route: '/catalog',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathwayCard({
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Browse',
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final theme = Theme.of(context);
    final isDesktop = context.isDesktop;

    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context)
          .copyWith(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isDesktop
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildFilterChips(),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildFilterChips(),
              ),
            ),
    );
  }

  List<Widget> _buildFilterChips() {
    return [
      FilterChip(
        label: const Text('All'),
        selected: _selectedTypeFilter == null,
        onSelected: (selected) {
          setState(() => _selectedTypeFilter = null);
          context.read<WishlistBloc>().add(LoadWishlist());
        },
      ),
      const SizedBox(width: 8),
      FilterChip(
        label: const Text('Masterclass'),
        selected: _selectedTypeFilter == 'masterclass',
        onSelected: (selected) {
          setState(() => _selectedTypeFilter = selected ? 'masterclass' : null);
          if (_selectedTypeFilter != null) {
            context
                .read<WishlistBloc>()
                .add(LoadWishlistByType(_selectedTypeFilter!));
          } else {
            context.read<WishlistBloc>().add(LoadWishlist());
          }
        },
      ),
      const SizedBox(width: 8),
      FilterChip(
        label: const Text('Learnership'),
        selected: _selectedTypeFilter == 'learnership',
        onSelected: (selected) {
          setState(() => _selectedTypeFilter = selected ? 'learnership' : null);
          if (_selectedTypeFilter != null) {
            context
                .read<WishlistBloc>()
                .add(LoadWishlistByType(_selectedTypeFilter!));
          } else {
            context.read<WishlistBloc>().add(LoadWishlist());
          }
        },
      ),
      const SizedBox(width: 8),
      FilterChip(
        label: const Text('Industry Training'),
        selected: _selectedTypeFilter == 'industry_training',
        onSelected: (selected) {
          setState(() =>
              _selectedTypeFilter = selected ? 'industry_training' : null);
          if (_selectedTypeFilter != null) {
            context
                .read<WishlistBloc>()
                .add(LoadWishlistByType(_selectedTypeFilter!));
          } else {
            context.read<WishlistBloc>().add(LoadWishlist());
          }
        },
      ),
    ];
  }

  Widget _buildWishlistContent(WishlistLoaded state) {
    final itemsByType = state.itemsByType;
    final padding = ResponsiveUtils.getResponsivePadding(context);

    // Responsive max width
    final maxWidth = context.responsiveValue(
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1200.0,
    );

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: padding,
          children: [
            // High priority items section
            if (state.highPriorityItems.isNotEmpty) ...[
              _buildSectionHeader(
                  'High Priority', Icons.priority_high, Colors.red),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              ...state.highPriorityItems
                  .map((item) => _buildWishlistCard(item)),
              SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
            ],

            // Items by training type
            ...itemsByType.entries.map((entry) {
              final type = entry.key;
              final items = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    _getTrainingTypeDisplay(type),
                    _getTrainingTypeIcon(type),
                    _getTrainingTypeColor(type),
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getResponsiveSpacing(context)),
                  ...items.map((item) => _buildWishlistCard(item)),
                  SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 2),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color? color) {
    final theme = Theme.of(context);
    final sectionColor = color ?? theme.colorScheme.primary;
    return Row(
      children: [
        Icon(icon, color: sectionColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: sectionColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistCard(Wishlist item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);

    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Training Type Indicator Column
              Container(
                width: 6,
                color: _getTrainingTypeColor(item.trainingType),
              ),

              // Course Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildBadge(
                            item.trainingTypeDisplay,
                            _getTrainingTypeColor(item.trainingType),
                          ),
                          const SizedBox(width: 8),
                          _buildInterestBadge(item),
                          const Spacer(),
                          if (item.daysInWishlist != null)
                            Text(
                              '${item.daysInWishlist}d ago',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.courseTitle ?? 'Unknown Course',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notes,
                                  size: 14, color: colors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.notes!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.event_available,
                              size: 14, color: colors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            "Intended start: ${item.intendedStartDisplay}",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions Column
              Container(
                width: 150,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  border: Border(
                    left: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!item.convertedToCart && !item.convertedToEnrollment)
                      TextButton.icon(
                        onPressed: () => _moveToCart(item),
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Add to Cart'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    if (item.convertedToCart || item.convertedToEnrollment)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.check_circle,
                            color: colors.primary, size: 32),
                      ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    TextButton.icon(
                      onPressed: () => _confirmRemove(item),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.error,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInterestBadge(Wishlist item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Color color;
    IconData icon;

    switch (item.interestLevel) {
      case 'high':
        color = colors.error;
        icon = Icons.whatshot;
        break;
      case 'medium':
        color = colors.secondary;
        icon = Icons.star;
        break;
      default:
        color = colors.outline;
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            item.interestLevelDisplay,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 80,
                color: colors.primary.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your wishlist is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Courses you are interested in will appear here. Start exploring the catalog to find your next goal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/catalog'),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Explore Courses'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moveToCart(Wishlist item) {
    context.read<WishlistBloc>().add(MoveToCartEvent(item.id));
  }

  void _confirmRemove(Wishlist item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Wishlist'),
        content: Text('Remove "${item.courseTitle}" from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<WishlistBloc>()
                  .add(RemoveFromWishlistEvent(item.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _getTrainingTypeDisplay(String type) {
    switch (type) {
      case 'masterclass':
        return 'Masterclass';
      case 'learnership':
        return 'Learnership';
      case 'industry_training':
        return 'Industry Training';
      case 'custom_selection':
        return 'Custom Selection';
      default:
        return type;
    }
  }

  IconData _getTrainingTypeIcon(String type) {
    switch (type) {
      case 'masterclass':
        return Icons.school;
      case 'learnership':
        return Icons.card_membership;
      case 'industry_training':
        return Icons.business;
      case 'custom_selection':
        return Icons.dashboard_customize;
      default:
        return Icons.book;
    }
  }

  Color _getTrainingTypeColor(String type) {
    final theme = Theme.of(context);
    switch (type) {
      case 'masterclass':
        return theme.colorScheme.primary;
      case 'learnership':
        return theme.colorScheme.secondary;
      case 'industry_training':
        return const Color(0xFF10B981); // successGreen
      case 'custom_selection':
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.outline;
    }
  }
}
