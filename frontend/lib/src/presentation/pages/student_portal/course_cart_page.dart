// lib/src/presentation/pages/student_portal/course_cart_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/student_portal/cart_bloc.dart';
import '../../../data/models/course_cart.dart';
import '../../../data/models/course_catalog.dart';
import '../../../data/models/masterclass.dart';
import '../../../data/models/course.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/content_type_utils.dart';
import '../../widgets/panels/enhanced_enrollment_panel.dart';
import '../../../core/services/currency_service.dart';

class CourseCartPage extends StatefulWidget {
  final bool embedMode;
  const CourseCartPage({Key? key, this.embedMode = false}) : super(key: key);

  @override
  State<CourseCartPage> createState() => _CourseCartPageState();
}

class _CourseCartPageState extends State<CourseCartPage> {
  bool _usePreviousCompanyDetails = false;
  bool _isCorporateEnrollment = false;
  CourseCart? _currentCart; // Store current cart for checkout

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(LoadActiveCart());
    CurrencyService.instance.initialize();
    CurrencyService.instance.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    CurrencyService.instance.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  /// Format a cart item's price, converting from USD when the item currency is USD.
  String _formatItemPrice(CourseCartItem item) {
    final price = double.tryParse(item.price) ?? 0.0;
    if (item.currency.toUpperCase() == 'USD') {
      return CurrencyService.instance.formatUSDAmount(price);
    }
    return CurrencyService.instance.formatPrice(price, currencyCode: item.currency);
  }

  /// Format the cart total, converting from USD when the cart currency is USD.
  String _formatCartTotal(CourseCart cart) {
    final total = double.tryParse(cart.totalAmount) ?? 0.0;
    if (cart.currency.toUpperCase() == 'USD') {
      return CurrencyService.instance.formatUSDAmount(total);
    }
    return CurrencyService.instance.formatPrice(total, currencyCode: cart.currency);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedMode) {
      return _buildBody();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, '/wishlist');
            },
          ),
        ],
      ),
      body: _buildBody(),
      // Drag target for catalog items
      bottomNavigationBar: _buildDragTarget(),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartItemAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added to cart')),
          );
        }
        if (state is CartItemRemoved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from cart')),
          );
        }
        if (state is CartCleared) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cart cleared')),
          );
        }
        if (state is CartCheckoutReady) {
          // Navigate to payment with cart details
          _proceedToPayment(state);
        }
      },
      builder: (context, state) {
        if (state is CartLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CartError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<CartBloc>().add(LoadActiveCart());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is CartLoaded) {
          // Store cart for checkout
          _currentCart = state.cart;

          if (state.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              // Cart items
              Expanded(
                child: _buildCartItems(state.cart),
              ),

              // Bottom bar with total and checkout
              _buildCheckoutBar(state.cart),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCartItems(CourseCart cart) {
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isMobileLandscape = context.isMobile && context.isLandscape;

    // Responsive max width
    final maxWidth = context.responsiveValue(
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1200.0,
    );

    // Use grid layout for mobile landscape, otherwise use list
    if (isMobileLandscape) {
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: GridView.builder(
            padding: padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context),
              mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context),
            ),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return _buildCartItemCard(item);
            },
          ),
        ),
      );
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView.builder(
          padding: padding,
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            final item = cart.items[index];
            return _buildCartItemCard(item);
          },
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CourseCartItem item) {
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
              // Image/Icon Area
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: _getTrainingTypeColor(item.trainingType)
                      .withValues(alpha: 0.08),
                  border: Border(
                    right: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getTrainingTypeIcon(item.trainingType),
                    color: _getTrainingTypeColor(item.trainingType),
                    size: 40,
                  ),
                ),
              ),

              // Details Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrainingTypeBadge(item.trainingType),
                      const SizedBox(height: 8),
                      Text(
                        item.courseTitle ?? 'Course',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatItemPrice(item),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.addedFromWishlist)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.pink.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.favorite,
                                      size: 12, color: Colors.pink),
                                  SizedBox(width: 4),
                                  Text(
                                    'WISHLIST',
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                width: 60,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  border: Border(
                    left: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colors.error,
                  onPressed: () => _confirmRemove(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(CourseCart cart) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: padding.copyWith(top: 20, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Corporate Enrollment Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildToggleItem(
                        label: 'Individual',
                        isSelected: !_isCorporateEnrollment,
                        onTap: () =>
                            setState(() => _isCorporateEnrollment = false),
                        colors: colors,
                      ),
                    ),
                    Expanded(
                      child: _buildToggleItem(
                        label: 'Corporate',
                        isSelected: _isCorporateEnrollment,
                        onTap: () =>
                            setState(() => _isCorporateEnrollment = true),
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Total',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${cart.totalCourses} Courses',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatCartTotal(cart),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Checkout Now',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              // Helper links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _confirmClearCart,
                    child: Text(
                      'Clear Cart',
                      style:
                          TextStyle(color: colors.error.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragTarget() {
    return Stack(
      children: [
        // Accept CourseCatalogItem
        DragTarget<CourseCatalogItem>(
          onAcceptWithDetails: (details) {
            final item = details.data;
            context.read<CartBloc>().add(
                  AddToCartEvent(
                    contentTypeId: item.contentTypeId,
                    objectId: item.objectId,
                    trainingType: item.trainingType,
                  ),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.title} added to cart')),
            );
          },
          builder: (context, candidateData, rejectedData) {
            if (candidateData.isEmpty) return const SizedBox.shrink();

            return Container(
              height: 80,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              child: Center(
                child: Text(
                  'Drop here to add to cart',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        // Accept Masterclass
        DragTarget<Masterclass>(
          onAcceptWithDetails: (details) {
            final masterclass = details.data;
            // Get content type ID for masterclass
            final contentTypeId =
                ContentTypeUtils.getContentTypeIdWithFallback('masterclass');

            context.read<CartBloc>().add(
                  AddToCartEvent(
                    contentTypeId: contentTypeId,
                    objectId: masterclass.id,
                    trainingType: 'masterclass',
                  ),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${masterclass.title} added to cart')),
            );
          },
          builder: (context, candidateData, rejectedData) {
            if (candidateData.isEmpty) return const SizedBox.shrink();

            return Container(
              height: 80,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Drop masterclass here to add to cart',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your learning cart is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Discover new skills and add courses to your cart to begin your journey.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildEmptyStateButton(
                  label: 'Masterclasses',
                  icon: Icons.school_rounded,
                  color: theme.colorScheme.primary,
                  onTap: () => Navigator.pushNamed(context, '/masterclasses'),
                ),
                _buildEmptyStateButton(
                  label: 'Learnerships',
                  icon: Icons.card_membership,
                  color: theme.colorScheme.secondary,
                  onTap: () => Navigator.pushNamed(context, '/learnerships'),
                ),
                _buildEmptyStateButton(
                  label: 'Industry Training',
                  icon: Icons.business,
                  color: const Color(0xFF10B981),
                  onTap: () =>
                      Navigator.pushNamed(context, '/industry-training'),
                ),
                _buildEmptyStateButton(
                  label: 'Custom Selection',
                  icon: Icons.dashboard_customize,
                  color: theme.colorScheme.tertiary,
                  onTap: () => Navigator.pushNamed(context, '/catalog'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Tip: Long press on any course to drag it to your cart',
                      style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildTrainingTypeBadge(String trainingType) {
    final color = _getTrainingTypeColor(trainingType);
    final display = _getTrainingTypeDisplay(trainingType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _checkout() {
    context.read<CartBloc>().add(
          CheckoutCartEvent(
            usePreviousCompanyDetails: _usePreviousCompanyDetails,
            isCorporateEnrollment: _isCorporateEnrollment,
          ),
        );
  }

  Future<void> _proceedToPayment(CartCheckoutReady state) async {
    // Check if we have cart data
    if (_currentCart == null || _currentCart!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is an existing student
    try {
      final existingStudentData = await ApiClient.checkExistingStudent();
      final isExistingStudent =
          existingStudentData['is_existing_student'] as bool? ?? false;

      // Convert cart items to Course objects for EnhancedEnrollmentPanel
      final courses = _currentCart!.items.map((item) {
        return Course(
          id: item.objectId.toString(),
          title: item.courseTitle ?? 'Course',
          price: double.tryParse(item.price.toString()),
          courseType: item.trainingType,
          featureImageUrl: null, // Cart items may not have images
        );
      }).toList();

      if (!mounted) return;

      // Show EnhancedEnrollmentPanel for existing students (skips personal info)
      // or new students (collects personal info)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => EnhancedEnrollmentPanel(
          courses: courses,
          isExistingStudent: isExistingStudent,
          existingStudentData: isExistingStudent ? existingStudentData : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmRemove(CourseCartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Cart'),
        content: Text('Remove "${item.courseTitle}" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartBloc>().add(RemoveFromCartEvent(item.id));
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

  void _confirmClearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartBloc>().add(ClearCartEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
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

  Widget _buildEmptyStateButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
