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
    final box = _conciergeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final pos = box.localToGlobal(Offset.zero);
    ConciergeManager.toggle(buttonRect: pos & box.size);
  }

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
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
    SlideInPanel.show(context, title: 'My Wishlist', child: const WishlistPanel());
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added ? '"$itemName" added to wishlist' : '"$itemName" is already in wishlist'),
        backgroundColor: added ? const Color(0xFFF79150) : null,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _showCartPanel(BuildContext context) {
    SlideInPanel.show(context, title: 'My Cart', child: const CartPanel());
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added ? '"$itemName" added to cart' : '"$itemName" is already in cart'),
        backgroundColor: added ? Colors.green : null,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  void dispose() {
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
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(width: 3, color: colors.primary.withValues(alpha: 0.15))),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: screenWidth < 1050
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/logo.png', height: 32, errorBuilder: (_, __, ___) => Icon(Icons.school, size: 32, color: colors.primary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (widget.subtitle.isNotEmpty) Text(widget.subtitle, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (widget.showBackButton) IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16), onPressed: widget.onBack ?? () => context.pop()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCartIcon(colors),
                            const SizedBox(width: 8),
                            _buildWishlistIcon(colors),
                            const SizedBox(width: 8),
                            _buildThemeToggle(themeService, colors),
                            const SizedBox(width: 8),
                            _buildConciergeToggle(),
                            if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!],
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Image.asset('assets/images/logo.png', height: 50, errorBuilder: (_, __, ___) => Icon(Icons.school, size: 50, color: colors.primary)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (widget.subtitle.isNotEmpty) Text(widget.subtitle, style: theme.textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Spacer(),
                      _buildCartIcon(colors),
                      const SizedBox(width: 12),
                      _buildWishlistIcon(colors),
                      const SizedBox(width: 12),
                      _buildThemeToggle(themeService, colors),
                      const SizedBox(width: 12),
                      _buildConciergeToggle(),
                      const SizedBox(width: 12),
                      if (widget.showBackButton) IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22), onPressed: widget.onBack ?? () => context.pop()),
                      if (widget.trailing != null) ...[const SizedBox(width: 12), widget.trailing!],
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCartIcon(ColorScheme colors) {
    return Tooltip(
      message: 'My Cart',
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (details) => details.data is Course || details.data is Learnership || details.data is Masterclass,
        onAcceptWithDetails: (details) => _handleCartDrop(details.data, context),
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(color: isHovering ? Colors.green.withValues(alpha: 0.3) : colors.primaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
                child: IconButton(icon: Icon(isHovering ? Icons.add_shopping_cart : Icons.shopping_cart_outlined, color: Colors.green, size: 22), onPressed: () => _showCartPanel(context)),
              ),
              if (_cartCount > 0) Positioned(right: -4, top: -4, child: _buildBadge('$_cartCount', Colors.green)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWishlistIcon(ColorScheme colors) {
    return Tooltip(
      message: 'My Wishlist',
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (details) => details.data is Course || details.data is Learnership || details.data is Masterclass,
        onAcceptWithDetails: (details) => _handleWishlistDrop(details.data, context),
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(color: isHovering ? const Color(0xFFF79150).withValues(alpha: 0.3) : colors.primaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
                child: IconButton(icon: Icon(isHovering ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFFF79150), size: 22), onPressed: () => _showWishlistPanel(context)),
              ),
              if (_wishlistCount > 0) Positioned(right: -4, top: -4, child: _buildBadge('$_wishlistCount', const Color(0xFFF79150))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeToggle(ThemeService themeService, ColorScheme colors) {
    return IconButton(icon: Icon(themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: const Color(0xFFF79150), size: 22), onPressed: () => themeService.toggleTheme(), style: IconButton.styleFrom(backgroundColor: colors.primaryContainer.withValues(alpha: 0.3)));
  }

  Widget _buildConciergeToggle() {
    return ValueListenableBuilder<bool>(
      valueListenable: ConciergeManager.isOpen,
      builder: (context, isOpen, _) => SizedBox(key: _conciergeButtonKey, child: _ConciergeToggleButton(isOpen: isOpen, onTap: _toggleConcierge)),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }
}

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
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: active ? [AppTheme.hosiBrown, AppTheme.hosiPeach] : [AppTheme.hosiMidnight, AppTheme.hosiBrown.withValues(alpha: 0.85)]),
            shape: BoxShape.circle,
            boxShadow: active ? [BoxShadow(color: AppTheme.hosiPeach.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Icon(widget.isOpen ? Icons.close_rounded : Icons.support_agent_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class PortalStyleBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const PortalStyleBackButton({super.key, this.onPressed, this.label = 'Back'});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton(onPressed: onPressed ?? () => Navigator.of(context).pop(), child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.primary)), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), backgroundColor: colors.primaryContainer.withValues(alpha: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: colors.primary.withValues(alpha: 0.3)))) );
  }
}
