// lib/src/presentation/pages/student_portal/course_catalog_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/student_portal/catalog_bloc.dart';
import '../../blocs/student_portal/cart_bloc.dart';
import '../../blocs/student_portal/wishlist_bloc.dart';
import '../../widgets/student_portal/course_catalog_card.dart';
import '../../../core/services/concierge_service.dart';
import '../../../data/models/course_catalog.dart';
import '../../widgets/panels/course_details_panel.dart';
import '../../widgets/common/slide_in_panel.dart';
import '../../widgets/modals/marketing/wishlist_lead_modal.dart';
import '../../../core/utils/responsive_utils.dart';

class CourseCatalogPage extends StatefulWidget {
  final bool embedMode;
  const CourseCatalogPage({Key? key, this.embedMode = false}) : super(key: key);

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  String? _selectedTrainingType;
  bool _showOnlyFeatured = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Parse query params using BuildContext (after frame) or rely on GoRouterState if accessible (not here easily without passing it)
    // Actually, we can't easily access GoRouterState here unless passed in constructor or using context.read.
    // Standard approach: Post-frame callback or check if route args exist.

    // However, usually we can get it from GoRouter.of(context).
    // Let's rely on addPostFrameCallback to handle initial load with params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialParams();
    });
  }

  void _handleInitialParams() {
    // Attempt to get query params from current route
    try {
      final state = GoRouterState.of(context);
      final type = state.uri.queryParameters['type'];
      if (type != null) {
        setState(() {
          _selectedTrainingType = type;
        });
        context.read<CatalogBloc>().add(FilterCatalog(trainingType: type));
      } else {
        context.read<CatalogBloc>().add(const LoadCatalog());
      }
    } catch (e) {
      // Fallback if GoRouterState not available or other error
      context.read<CatalogBloc>().add(const LoadCatalog());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedMode) {
      return _buildMainContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Catalog'),
        actions: [
          // Cart icon with badge
          IconButton(
            icon: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state is CartLoaded) {
                  return Badge(
                    label: Text('${state.itemCount}'),
                    child: const Icon(Icons.shopping_cart),
                  );
                }
                return const Icon(Icons.shopping_cart);
              },
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
          // Wishlist icon
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.pushNamed(context, '/wishlist');
            },
          ),
        ],
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Filters and search
        _buildFiltersBar(),

        // Catalog grid
        Expanded(
          child: BlocBuilder<CatalogBloc, CatalogState>(
            builder: (context, state) {
              if (state is CatalogLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CatalogError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<CatalogBloc>().add(const LoadCatalog());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is CatalogLoaded) {
                if (state.items.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildCatalogGrid(state.items);
              }

              return const SizedBox.shrink();
            },
          ),
        ),

        // Cart drop zone (fixed at bottom)
        _buildCartDropZone(),
      ],
    );
  }

  Widget _buildFiltersBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search courses...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<CatalogBloc>().add(const LoadCatalog());
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.read<CatalogBloc>().add(SearchCatalog(value));
              } else {
                context.read<CatalogBloc>().add(const LoadCatalog());
              }
            },
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Training type filters
                FilterChip(
                  label: const Text('All Courses'),
                  selected: _selectedTrainingType == null,
                  onSelected: (selected) {
                    setState(() => _selectedTrainingType = null);
                    context.read<CatalogBloc>().add(const LoadCatalog());
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Masterclass'),
                  selected: _selectedTrainingType == 'masterclass',
                  onSelected: (selected) {
                    setState(() => _selectedTrainingType =
                        selected ? 'masterclass' : null);
                    context.read<CatalogBloc>().add(
                          FilterCatalog(trainingType: _selectedTrainingType),
                        );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Learnership'),
                  selected: _selectedTrainingType == 'learnership',
                  onSelected: (selected) {
                    setState(() => _selectedTrainingType =
                        selected ? 'learnership' : null);
                    context.read<CatalogBloc>().add(
                          FilterCatalog(trainingType: _selectedTrainingType),
                        );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Industry Training'),
                  selected: _selectedTrainingType == 'industry_training',
                  onSelected: (selected) {
                    setState(() => _selectedTrainingType =
                        selected ? 'industry_training' : null);
                    context.read<CatalogBloc>().add(
                          FilterCatalog(trainingType: _selectedTrainingType),
                        );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Featured Only'),
                  selected: _showOnlyFeatured,
                  onSelected: (selected) {
                    setState(() => _showOnlyFeatured = selected);
                    context.read<CatalogBloc>().add(
                          FilterCatalog(
                            trainingType: _selectedTrainingType,
                            featured: _showOnlyFeatured ? true : null,
                          ),
                        );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogGrid(List<CourseCatalogItem> items) {
    // Responsive grid columns based on screen size and orientation
    final crossAxisCount = context.responsiveValue(
      mobile: context.isLandscape ? 3 : 2,
      tablet: context.isLandscape ? 4 : 3,
      desktop: context.isLandscape ? 5 : 4,
    );

    // Responsive spacing
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    final padding = ResponsiveUtils.getResponsivePadding(context);

    // Responsive aspect ratio
    final aspectRatio = ResponsiveUtils.getCardAspectRatio(context);

    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return CourseCatalogCard(
          item: item,
          onTap: () {
            _showCourseDetails(item);
          },
          onAddToWishlist: () {
            _addToWishlist(item);
          },
          onAddToCart: () {
            _addToCart(item);
          },
        );
      },
    );
  }

  Widget _buildCartDropZone() {
    final theme = Theme.of(context);
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        return DragTarget<CourseCatalogItem>(
          onAcceptWithDetails: (details) {
            final item = details.data;
            _addToCart(item);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.title} added to cart'),
                action: SnackBarAction(
                  label: 'View Cart',
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
              ),
            );
          },
          builder: (context, candidateData, rejectedData) {
            final bool isHovering = candidateData.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isHovering ? 120 : 80,
              decoration: BoxDecoration(
                color: isHovering
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(
                    color: isHovering
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: isHovering ? 3 : 1,
                  ),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      size: isHovering ? 48 : 32,
                      color: isHovering
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isHovering
                          ? 'Drop here to add to cart'
                          : 'Drag courses here to add to cart',
                      style: TextStyle(
                        color: isHovering
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            isHovering ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (state is CartLoaded && state.itemCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${state.itemCount} item(s) in cart - R ${state.totalAmount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No courses found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedTrainingType = null;
                _showOnlyFeatured = false;
                _searchController.clear();
              });
              context.read<CatalogBloc>().add(const LoadCatalog());
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  void _showCourseDetails(CourseCatalogItem item) {
    // Trigger AI Architect when showing interest
    ConciergeService.setPrompt('Tell me more about the course: ${item.title}');

    // Show slide-in panel with CourseDetailsPanel for integrated enrollment
    SlideInPanel.show(
      context,
      title: item.title,
      child: CourseDetailsPanel(course: item.toCourse()),
    );
  }

  void _addToWishlist(CourseCatalogItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WishlistLeadModal(
        course: item.toCourse(),
        trainingType: item.trainingType,
        onComplete: (interest, timing, notes) {
          // Add to local wishlist state via bloc after form completion
          context.read<WishlistBloc>().add(
                AddToWishlistEvent(
                  contentTypeId: item.contentTypeId,
                  objectId: item.objectId,
                  trainingType: item.trainingType,
                  interestLevel: interest,
                  intendedStart: timing,
                  notes: notes,
                ),
              );
        },
      ),
    );
  }

  void _addToCart(CourseCatalogItem item) {
    context.read<CartBloc>().add(
          AddToCartEvent(
            contentTypeId: item.contentTypeId,
            objectId: item.objectId,
            trainingType: item.trainingType,
          ),
        );
  }
}
