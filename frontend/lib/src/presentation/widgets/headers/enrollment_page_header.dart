import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/concierge_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../common/slide_in_panel.dart';
import '../panels/wishlist_panel.dart';
import '../panels/cart_panel.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../data/models/course.dart';
import '../../../data/models/learnership.dart';
import '../../../data/models/masterclass.dart';

/// Unified Enrollment Page Header
/// Matches Instructor/Learner/Admin portal header styling exactly
///
/// Layout (from left to right):
/// - Logo (50px height)
/// - Title/Subtitle (under logo like user info)
/// - Spacer
/// - AI Search Bubble
/// - Theme Toggle
/// - Back Arrow to Onboarding
class EnrollmentPageHeader extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double verticalPadding;
  final Widget? trailing;
  final TextEditingController? searchController;
  const EnrollmentPageHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.showBackButton = true,
    this.onBack,
    this.verticalPadding = 12.0,
    this.trailing,
    this.searchController,
  });

  @override
  State<EnrollmentPageHeader> createState() => _EnrollmentPageHeaderState();
}

class _EnrollmentPageHeaderState extends State<EnrollmentPageHeader> {
  late TextEditingController _searchController;
  int _wishlistCount = 0;
  int _cartCount = 0;
  final GlobalKey _conciergeButtonKey = GlobalKey();

  void _toggleConcierge() {
    if (!kIsWeb) return;
    final box = _conciergeButtonKey.currentContext?.findRenderObject()
        as RenderBox?;
    if (box == null || !box.hasSize) return;
    final pos = box.localToGlobal(Offset.zero);
    ConciergeManager.toggle(buttonRect: pos & box.size);
  }

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();

    // Close any concierge from the previous page when this header mounts.
    if (kIsWeb) ConciergeManager.closeAny();

    wishlistService.wishlistCountStream.listen((count) {
      if (mounted) setState(() => _wishlistCount = count);
    });
    _wishlistCount = wishlistService.itemCount;

    cartService.cartUpdatedStream.listen((_) {
      if (mounted) setState(() => _cartCount = cartService.itemCount);
    });
    _cartCount = cartService.itemCount;
  }

  void _showWishlistPanel(BuildContext context) {
    SlideInPanel.show(
      context,
      title: 'My Wishlist',
      child: const WishlistPanel(),
    );
  }

  Future<void> _handleWishlistDrop(dynamic item, BuildContext context) async {
    bool added = false;
    String itemName = '';

    if (item is Course) {
      added = await wishlistService.addCourse(item);
      itemName = item.displayTitle;
    } else if (item is Learnership) {
      added = await wishlistService.addLearnership(item);
      itemName = item.title;
    } else if (item is Masterclass) {
      final data = item.toJson();
      data['price'] ??= item.priceUsd;
      added = await wishlistService.addMasterclass(item.id.toString(), data);
      itemName = item.title;
    }

    if (itemName.isNotEmpty && mounted) {
      if (added) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$itemName" added to wishlist'),
            backgroundColor: const Color(0xFFF79150),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$itemName" is already in wishlist'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showCartPanel(BuildContext context) {
    SlideInPanel.show(
      context,
      title: 'My Cart',
      child: const CartPanel(),
    );
  }

  Future<void> _handleCartDrop(dynamic item, BuildContext context) async {
    bool added = false;
    String itemName = '';

    if (item is Course) {
      added = await cartService.addCourse(item);
      itemName = item.displayTitle;
    } else if (item is Learnership) {
      added = await cartService.addLearnership(item);
      itemName = item.title;
    } else if (item is Masterclass) {
      final data = item.toJson();
      data['price'] ??= item.priceUsd;
      added = await cartService.addMasterclass(item.id.toString(), data);
      itemName = item.title;
    }

    if (itemName.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(added
              ? '"$itemName" added to cart'
              : '"$itemName" is already in cart'),
          backgroundColor: added ? Colors.green : null,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Remove the concierge when this enrollment page is dismissed.
    if (kIsWeb) ConciergeManager.closeAny();
    if (widget.searchController == null) _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Header Container (without AI bubble)
            Container(
              width: double.infinity, // 100% page width (matches portal)
              decoration: BoxDecoration(
                color: colors.surface, // Use theme surface color
                border: Border(
                  bottom: BorderSide(
                    width: 3,
                    color: colors.primary.withValues(alpha: 0.15),
                  ),
                ),
                boxShadow: [
                  // Primary shadow for depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                  // Secondary shadow for enhanced separation
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02, // 2% padding (matches portal)
                  vertical: widget.verticalPadding,
                ),
                child: Row(
                  children: [
                    // Logo & Title Section (aligned horizontally)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: screenWidth < 768 ? 40 : 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.school,
                            size: 50,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title/Subtitle next to logo
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.subtitle.isNotEmpty)
                              Text(
                                widget.subtitle,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSurface,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Cart with Drag & Drop
                    Tooltip(
                      message: 'My Cart (Drag items here)',
                      child: DragTarget<Object>(
                        onWillAcceptWithDetails: (details) {
                          return details.data is Course ||
                              details.data is Learnership ||
                              details.data is Masterclass;
                        },
                        onAcceptWithDetails: (details) {
                          _handleCartDrop(details.data, context);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isHovering = candidateData.isNotEmpty;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isHovering
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : colors.primaryContainer
                                          .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: isHovering
                                      ? Border.all(
                                          color: Colors.green,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isHovering
                                        ? Icons.add_shopping_cart
                                        : Icons.shopping_cart_outlined,
                                    color: Colors.green,
                                    size: 26,
                                  ),
                                  onPressed: () => _showCartPanel(context),
                                ),
                              ),
                              if (_cartCount > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                        minWidth: 16, minHeight: 16),
                                    child: Text(
                                      '$_cartCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Wishlist with Drag & Drop
                    Tooltip(
                      message: 'My Wishlist (Drag items here)',
                      child: DragTarget<Object>(
                        onWillAcceptWithDetails: (details) {
                          return details.data is Course ||
                              details.data is Learnership ||
                              details.data is Masterclass;
                        },
                        onAcceptWithDetails: (details) {
                          _handleWishlistDrop(details.data, context);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isHovering = candidateData.isNotEmpty;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isHovering
                                      ? const Color(0xFFF79150)
                                          .withValues(alpha: 0.3)
                                      : colors.primaryContainer
                                          .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: isHovering
                                      ? Border.all(
                                          color: const Color(0xFFF79150),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isHovering
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color:
                                        const Color(0xFFF79150), // Hosi Peach
                                    size: 26,
                                  ),
                                  onPressed: () => _showWishlistPanel(context),
                                ),
                              ),
                              if (_wishlistCount > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF79150), // Hosi Peach
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                        minWidth: 16, minHeight: 16),
                                    child: Text(
                                      '$_wishlistCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Theme Toggle (matches portal styling)
                    Tooltip(
                      message: themeService.isDarkMode
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode',
                      child: IconButton(
                        icon: Icon(
                          themeService.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: const Color(0xFFF79150), // Hosi Peach
                          size: 26,
                        ),
                        onPressed: () => themeService.toggleTheme(),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colors.primaryContainer.withValues(alpha: 0.3),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Ask Academy Concierge toggle button
                    ValueListenableBuilder<bool>(
                      valueListenable: ConciergeManager.isOpen,
                      builder: (context, isOpen, _) {
                        return SizedBox(
                          key: _conciergeButtonKey,
                          child: _ConciergeToggleButton(
                            isOpen: isOpen,
                            onTap: _toggleConcierge,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    // Back arrow — always present for mobile/small screen navigation
                    if (widget.showBackButton)
                      Tooltip(
                        message: 'Back',
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: colors.onSurface,
                            size: screenWidth < 600 ? 18 : 22,
                          ),
                          onPressed: widget.onBack ??
                              () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.go('/onboarding');
                                }
                              },
                          style: IconButton.styleFrom(
                            backgroundColor: colors.primaryContainer.withValues(alpha: 0.3),
                          ),
                        ),
                      ),

                    // Custom trailing widget if provided
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 12),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),

          ],
        );
      },
    );
  }
}

// ─── Concierge toggle button (shared style) ──────────────────────────────────
class _ConciergeToggleButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const _ConciergeToggleButton({required this.isOpen, required this.onTap});
  @override
  State<_ConciergeToggleButton> createState() => _ConciergeToggleButtonState();
}

class _ConciergeToggleButtonState extends State<_ConciergeToggleButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.isOpen || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10), // Padding for circular feel
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? [AppTheme.hosiBrown, AppTheme.hosiPeach]
                  : [AppTheme.hosiMidnight, AppTheme.hosiBrown.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle, // Circular icon-only button
            boxShadow: active
                ? [BoxShadow(color: AppTheme.hosiPeach.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Icon(widget.isOpen ? Icons.close_rounded : Icons.support_agent_rounded,
                  color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

/// Portal-Style Back Button Widget (for pages that need it in body)
class PortalStyleBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const PortalStyleBackButton({
    super.key,
    this.onPressed,
    this.label = 'Back',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.primary,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: colors.primaryContainer.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: colors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
}
