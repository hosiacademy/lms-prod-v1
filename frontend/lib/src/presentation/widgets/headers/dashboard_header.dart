import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/services/concierge_manager.dart';
import '../../../data/models/course.dart';
import '../../../data/models/learnership.dart';
import '../../../data/models/masterclass.dart';
import '../../widgets/partnerships/bbb_partnership_widget.dart';
import '../common/slide_in_panel.dart';
import '../panels/wishlist_panel.dart';
import '../panels/cart_panel.dart';
import '../../../core/services/cart_service.dart';
import '../ai/native_ai_assistant.dart';
import '../../../core/theme/app_theme.dart';

class DashboardHeader extends StatefulWidget {
  final String userName;
  final String userDesignation;
  final String? userImageUrl;
  final bool isAdmin;
  final int notificationCount;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;
  final bool showMenuButton;
  final bool showCart;
  final bool showWishlist;
  final bool showBackButton; // ? Added
  final VoidCallback? onBack; // ? Added

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.userDesignation,
    this.userImageUrl,
    this.isAdmin = false,
    this.notificationCount = 0,
    this.onNotificationsTap,
    this.onProfileTap,
    this.onLogout,
    this.showMenuButton = false,
    this.showCart = true,
    this.showWishlist = true,
    this.showBackButton = false, // default: hidden
    this.onBack,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  bool _showNotifications = false;
  int _wishlistCount = 0;
  int _cartCount = 0;
  final GlobalKey _conciergeButtonKey = GlobalKey();

  void _toggleConcierge() {
    if (!kIsWeb) return;
    final buttonContext = _conciergeButtonKey.currentContext;
    if (buttonContext == null) return;

    final renderBox = buttonContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final buttonRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    ConciergeManager.toggle(buttonRect: buttonRect);
  }

  @override
  void initState() {
    super.initState();
    // Listen to cart and wishlist updates
    wishlistService.wishlistCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _wishlistCount = count;
        });
      }
    });

    cartService.cartCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _cartCount = count;
        });
      }
    });

    // Initialize counts
    _wishlistCount = wishlistService.itemCount;
    _cartCount = cartService.itemCount;
  }

  void _activateAIAssistant(BuildContext context) {
    final isExpanded =
        NativeAIAssistant.globalKey.currentState?.isAIExpanded ?? false;
    if (isExpanded) {
      NativeAIAssistant.globalKey.currentState?.collapseAI();
    } else {
      NativeAIAssistant.globalKey.currentState?.expandAI();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            !isExpanded ? 'AI Architect activated' : 'AI Architect hidden'),
        backgroundColor: const Color(0xFFF79150),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Fix non-constant expression
    final horizontalSpacing = screenWidth < 768 ? 8.0 : 24.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
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
          horizontal: screenWidth * 0.02,
          vertical: 17, // Increased from 12 to 17 (5px more)
        ),
        child: Row(
          children: [
            // Hamburger Menu (mobile only)
            if (widget.showMenuButton) ...[
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: colors.primary,
                    size: 28,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  style: IconButton.styleFrom(
                    backgroundColor:
                        colors.primaryContainer.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Back Button (now supported)
            if (widget.showBackButton) ...[
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colors.primary,
                  size: 28,
                ),
                onPressed: widget.onBack ?? () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor:
                      colors.primaryContainer.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Logo Section - 2px from left margin
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Image.asset(
                'assets/images/logo.png',
                height: screenWidth < 768 ? 36 : 46,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(width: horizontalSpacing), // fixed here

            // Welcome back message
            if (screenWidth > 600)
              Text(
                'Welcome back, ${widget.userName.split(' ')[0]}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),

            const Spacer(),

            // AI Concierge — toggles hosi-widget-frame iframe
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
            const SizedBox(width: 8),
            // Partnership Logos - Hidden for Admins
            if (!widget.isAdmin) ...[
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          '🤝 AICERTS Partnership: World-class AI & Blockchain certifications',
                        ),
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'Learn More',
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.outline.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/onboarding/aicerts.png',
                      height: screenWidth < 800 ? 20 : 25, // Responsive size
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.school,
                            size: screenWidth < 800 ? 22 : 28, color: colors.primary);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const BBBPartnershipWidget(size: 40, showLabel: false),
            ],
            SizedBox(width: screenWidth < 800 ? 12 : 24),

            // Admin Panel Button
            if (widget.isAdmin) ...[
              Tooltip(
                message: 'Django Admin Panel',
                child: IconButton(
                  icon: Icon(
                    Icons.admin_panel_settings,
                    color: colors.error,
                    size: 28,
                  ),
                  onPressed: () =>
                      context.go('/admin/dashboard?section=django_admin'),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        colors.errorContainer.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Wishlist with Drag & Drop
            if (widget.showWishlist) ...[
              Tooltip(
                message: 'My Wishlist (Drag items here)',
                child: DragTarget<Object>(
                  onWillAcceptWithDetails: (details) {
                    // Accept Course, Learnership, or Masterclass
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
                                ? const Color(0xFFF79150).withValues(alpha: 0.3)
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
                              color: colors.primary,
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
                              decoration: BoxDecoration(
                                color: const Color(0xFFF79150), // Gold color
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
            ],

            // Course Cart with Drag & Drop
            if (widget.showCart) ...[
              Tooltip(
                message: 'Course Cart (Drag items here)',
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
                                ? Colors.green.withValues(alpha: 0.25)
                                : colors.primaryContainer
                                    .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: isHovering
                                ? Border.all(
                                    color: Colors.green.shade600,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isHovering
                                  ? Icons.add_shopping_cart
                                  : Icons.shopping_cart_outlined,
                              color: isHovering
                                  ? Colors.green.shade700
                                  : colors.primary,
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
                                color: Colors.red,
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
            ],

            const SizedBox(width: 12),

            // Theme Toggle
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return Tooltip(
                  message: themeService.isDarkMode
                      ? 'Switch to Light Mode'
                      : 'Switch to Dark Mode',
                  child: IconButton(
                    icon: Icon(
                      themeService.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: colors.primary,
                      size: 26,
                    ),
                    onPressed: () => themeService.toggleTheme(),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colors.primaryContainer.withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 12),

            // Notifications (Hidden for Admins)
            if (!widget.isAdmin) ...[
              Tooltip(
                message: 'Announcements',
                child: IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.campaign,
                        color: colors.primary,
                        size: 26,
                      ),
                      if (widget.notificationCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints:
                                const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              widget.notificationCount > 9
                                  ? '9+'
                                  : '${widget.notificationCount}',
                              style: TextStyle(
                                color: colors.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    if (widget.onNotificationsTap != null) {
                      widget.onNotificationsTap!();
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _buildNotificationsSheet(context),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],

            // User Profile Avatar
            GestureDetector(
              onTap: widget.onProfileTap,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.userImageUrl != null &&
                          widget.userImageUrl!.isNotEmpty
                      ? Image.network(
                          widget.userImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(colors),
                        )
                      : _buildDefaultAvatar(colors),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Logout
            Tooltip(
              message: 'Logout',
              child: IconButton(
                icon: Icon(
                  Icons.logout,
                  color: colors.error,
                  size: 22,
                ),
                onPressed: widget.onLogout ?? () => context.go('/login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ColorScheme colors) {
    return Image.asset(
      'assets/images/default_avatar.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colors.primaryContainer,
          child: Center(
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName.substring(0, 1).toUpperCase()
                  : 'U',
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '?? Announcements',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Mark all read'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildNotificationTile(
                  icon: Icons.campaign,
                  title: 'New Masterclass Available',
                  message: 'AI & Machine Learning Masterclass starts next week',
                  time: '2 hours ago',
                  isUnread: true,
                  colors: colors,
                ),
                _buildNotificationTile(
                  icon: Icons.assignment,
                  title: 'Assignment Due Soon',
                  message: 'Complete Cybersecurity Assessment by Friday',
                  time: '5 hours ago',
                  isUnread: true,
                  colors: colors,
                ),
                _buildNotificationTile(
                  icon: Icons.video_library,
                  title: 'Live Session Reminder',
                  message: 'Blockchain Development session in 30 minutes',
                  time: '1 day ago',
                  isUnread: false,
                  colors: colors,
                ),
                _buildNotificationTile(
                  icon: Icons.star,
                  title: 'Achievement Unlocked',
                  message: 'You completed 5 courses! Keep it up!',
                  time: '2 days ago',
                  isUnread: false,
                  colors: colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    required ColorScheme colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? colors.primary.withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: colors.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWishlistPanel(BuildContext context) {
    SlideInPanel.show(
      context,
      title: 'My Wishlist',
      child: const WishlistPanel(),
    );
  }

  void _showCartPanel(BuildContext context) {
    SlideInPanel.show(
      context,
      title: 'Course Cart',
      child: const CartPanel(),
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
      itemName =
          item.toString(); // Or use a meaningful title getter if available
      if (item.title.isNotEmpty) itemName = item.title;
    } else if (item is Masterclass) {
      final data = item.toJson();
      // Ensure price is set for calculation
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

  Future<void> _handleCartDrop(dynamic item, BuildContext context) async {
    bool added = false;
    String itemName = '';

    if (item is Course) {
      added = await cartService.addCourse(item);
      itemName = item.displayTitle;
    } else if (item is Learnership) {
      added = await cartService.addLearnership(item);
      itemName = item.title.isNotEmpty ? item.title : item.toString();
    } else if (item is Masterclass) {
      final data = item.toJson();
      data['price'] ??= item.priceUsd;
      added = await cartService.addMasterclass(item.id.toString(), data);
      itemName = item.title;
    }

    if (itemName.isNotEmpty && mounted) {
      if (added) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$itemName" added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$itemName" is already in cart'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _ConciergeToggleButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _ConciergeToggleButton({
    required this.isOpen,
    required this.onTap,
  });

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
