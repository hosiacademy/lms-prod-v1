import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/cart_service.dart';
import 'animated_training_menu.dart';
import 'dart:async';
import '../../../../core/services/concierge_manager.dart';

class OnboardingHeader extends StatefulWidget {
  final Map<String, bool> hoverStates;
  final Function(String, bool) onHover;
  final VoidCallback onLoginPressed;
  final TextEditingController searchController;
  final Function(String) onShowOverlay;
  final Function() onHideOverlay;
  final Function(String) onNavigate;
  final Function(bool)? onMenuVisibilityChanged;
  final VoidCallback? onCartPressed;
  final VoidCallback? onPathwaysTap;

  const OnboardingHeader({
    super.key,
    required this.hoverStates,
    required this.onHover,
    required this.onLoginPressed,
    required this.searchController,
    required this.onShowOverlay,
    required this.onHideOverlay,
    required this.onNavigate,
    this.onMenuVisibilityChanged,
    this.onCartPressed,
    this.onPathwaysTap,
  });

  @override
  State<OnboardingHeader> createState() => _OnboardingHeaderState();
}

class _OnboardingHeaderState extends State<OnboardingHeader> {
  int _cartCount = 0;
  StreamSubscription<int>? _cartCountSubscription;

  void _setupCartListener() {
    _cartCountSubscription = cartService.cartCountStream.listen((count) {
      if (mounted) {
        setState(() => _cartCount = count);
      }
    });
    // Initial count
    setState(() => _cartCount = cartService.itemCount);
  }

  @override
  void initState() {
    super.initState();
    _setupCartListener();
  }

  @override
  void dispose() {
    _cartCountSubscription?.cancel();
    // Close concierge when navigating away from the onboarding page.
    if (kIsWeb) ConciergeManager.closeAny();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 1450;
    final isMobile = screenWidth < 600;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                left: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 2,
                    right: isMobile ? 8 : (isNarrowScreen ? 12 : 32),
                    top: isMobile ? 8 : 12,
                    bottom: isMobile ? 8 : 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left - Logo + Africa map
                       // Left - Logo + Africa map - Take minimum space needed
                       Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Image.asset(
                             'assets/images/logo.png',
                             height: isMobile ? 32 : 50,
                             fit: BoxFit.contain,
                             errorBuilder: (context, error, stackTrace) =>
                                 const Icon(
                               Icons.school,
                               size: 40,
                               color: Color(0xFFF79150),
                             ),
                           ),
                           if (!isMobile) ...[
                             const SizedBox(width: 12),
                             Image.asset(
                               'assets/images/onboarding/africa_map.png',
                               height: 45,
                               fit: BoxFit.contain,
                             ),
                           ],
                         ],
                       ),

                      if (isNarrowScreen)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(width: isMobile ? 2 : 8),
                              // Cart Icon with badge for mobile
                              if (_cartCount > 0)
                                Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.shopping_cart_rounded,
                                        color: Color(0xFFF79150),
                                        size: 28,
                                      ),
                                      onPressed: widget.onCartPressed,
                                      tooltip: 'View Cart',
                                    ),
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$_cartCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                IconButton(
                                  icon: const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Color(0xFFF79150),
                                    size: 28,
                                  ),
                                  onPressed: widget.onCartPressed,
                                  tooltip: 'View Cart',
                                ),
                              SizedBox(width: isMobile ? 2 : 4),
                              if (isMobile)
                                IconButton(
                                  icon: const Icon(Icons.login),
                                  onPressed: widget.onLoginPressed,
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFF79150),
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: widget.onLoginPressed,
                                  icon: const Icon(Icons.login, size: 18),
                                  label: const Text('Sign In'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF79150),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                ),
                              SizedBox(width: isMobile ? 4 : 12),
                              IconButton(
                                icon: const Icon(Icons.menu_rounded,
                                    color: Color(0xFFF79150), size: 32),
                                onPressed: () => _showMobileMenu(context),
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                _buildTrainingButton(
                                  context,
                                  title: 'AI & Blockchain Training',
                                  hoverKey: 'ai_blockchain',
                                  overlayKey: 'ai_blockchain',
                                ),
                                const SizedBox(width: 16),
                                _buildTrainingButton(
                                  context,
                                  title: 'Cybersecurity Training',
                                  hoverKey: 'cybersecurity',
                                  overlayKey: 'cybersecurity',
                                  isCybersecurity: true,
                                ),
                              const SizedBox(width: 16),
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
                                        color: const Color(0xFFF79150),
                                        size: 24,
                                      ),
                                      onPressed: () =>
                                          themeService.toggleTheme(),
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.1),
                                        padding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              // Cart Icon with badge
                              if (_cartCount > 0)
                                Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.shopping_cart_rounded,
                                        color: Color(0xFFF79150),
                                        size: 28,
                                      ),
                                      onPressed: widget.onCartPressed,
                                      tooltip: 'View Cart',
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$_cartCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                IconButton(
                                  icon: const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Color(0xFFF79150),
                                    size: 28,
                                  ),
                                  onPressed: widget.onCartPressed,
                                  tooltip: 'View Cart',
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: widget.onLoginPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8C4928),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  elevation: 3,
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingButton(
    BuildContext context, {
    required String title,
    required String hoverKey,
    required String overlayKey,
    bool isCybersecurity = false,
  }) {
    final isHovered = widget.hoverStates[hoverKey] ?? false;

    return AnimatedTrainingMenu(
      title: title,
      isHovered: isHovered,
      onHover: widget.onHover,
      onOptionClick: (route) {
        // Navigate directly to the enrollment page
        widget.onNavigate(route);
      },
      onMenuVisibilityChanged: widget.onMenuVisibilityChanged,
      isCybersecurity: isCybersecurity,
      onPathwaysTap: widget.onPathwaysTap,
    );
  }

  void _showComingSoonModal(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.hosiBrown,
                        AppTheme.hosiPeach,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.construction_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coming Soon',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "We're working on it!",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 64,
                        color: AppTheme.hosiBrown.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'This cybersecurity training option is not available yet.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We\'re developing exciting new cybersecurity training programs. Please check back soon or explore our available Learnerships option.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Got it!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMobileMenu(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: colors.shadow.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Training Pathways',
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface),
                          ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: colors.onSurface),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Theme toggle
                      Consumer<ThemeService>(
                        builder: (context, themeService, child) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                colors.primary.withValues(alpha: 0.1),
                                colors.secondary.withValues(alpha: 0.1)
                              ]),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: colors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        colors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    themeService.isDarkMode
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    color: colors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    themeService.isDarkMode
                                        ? 'Dark Mode'
                                        : 'Light Mode',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colors.onSurface),
                                  ),
                                ),
                                Switch(
                                  value: themeService.isDarkMode,
                                  onChanged: (_) => themeService.toggleTheme(),
                                  thumbColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return colors.primary;
                                    }
                                    return null;
                                  }),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      Text(
                        'EXPLORE TRAINING',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AI & Blockchain Training (expandable)
                      _buildExpandablePathway(
                        context,
                        title: 'AI & Blockchain Training',
                        icon: Icons.psychology_rounded,
                        color: colors.primary,
                        options: [
                          _MenuOption('Masterclasses', () {
                            Navigator.pop(context);
                            widget.onNavigate('/enroll/corporate');
                          }),
                          _MenuOption('Learnerships', () {
                            Navigator.pop(context);
                            widget.onNavigate('/enroll/learnerships');
                          }),
                          _MenuOption('Industry Training', () {
                            Navigator.pop(context);
                            widget.onNavigate('/enroll/industry');
                          }),
                          _MenuOption('Custom Selection', () {
                            Navigator.pop(context);
                            widget.onNavigate('/enroll/custom');
                          }),
                        ],
                        delay: 200.ms,
                      ),
                      const SizedBox(height: 16),

                      // Cybersecurity Training (expandable)
                      _buildExpandablePathway(
                        context,
                        title: 'Cybersecurity Training',
                        icon: Icons.security_rounded,
                        color: Colors.red.shade700,
                        options: [
                          _MenuOption('Masterclasses', () {
                            Navigator.pop(context);
                            _showComingSoonModal(context);
                          }),
                          _MenuOption('Learnerships', () {
                            Navigator.pop(context);
                            widget.onNavigate('/enroll/cybersecurity');
                          }),
                          _MenuOption('Industry Training', () {
                            Navigator.pop(context);
                            _showComingSoonModal(context);
                          }),
                          _MenuOption('Custom Selection', () {
                            Navigator.pop(context);
                            _showComingSoonModal(context);
                          }),
                        ],
                        delay: 300.ms,
                      ),
                      const SizedBox(height: 16),

                      // Expert Trainers - standalone
                      _buildMenuTile(
                        context,
                        title: 'Expert Trainers',
                        icon: Icons.people_rounded,
                        color: Colors.blue.shade700,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onShowOverlay('trainers');
                        },
                        delay: 400.ms,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandablePathway(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<_MenuOption> options,
    required Duration delay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          title: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: options
              .map((opt) => ListTile(
                    leading:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    title: Text(opt.label),
                    onTap: opt.onTap,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ))
              .toList(),
        ),
      ),
    ).animate(delay: delay).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Duration delay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            size: 18),
        onTap: onTap,
      ),
    ).animate(delay: delay).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _MenuOption {
  final String label;
  final VoidCallback onTap;

  _MenuOption(this.label, this.onTap);
}


