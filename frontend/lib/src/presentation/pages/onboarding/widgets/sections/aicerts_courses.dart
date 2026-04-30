import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../core/services/aicerts_service.dart';
import '../../../../../data/models/course.dart';
import '../../../../../core/services/wishlist_service.dart';
import '../../../../widgets/modals/marketing/wishlist_lead_modal.dart';
import '../../../../../core/services/cart_service.dart';
import '../../../../widgets/aicerts/aicerts_image_widget.dart';
import '../../../../../core/services/currency_service.dart';
import '../../../../../core/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../../../../pages/custom_selection/custom_selection_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/services/concierge_manager.dart';

/// Strips HTML tags and decodes common HTML entities from a string.
String _stripHtml(String html) {
  // Replace block-level tags with a space so words don't run together
  String text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), ' ')
      .replaceAll(
          RegExp(r'</?(ul|ol|tr|td|th|div|h\d)[^>]*>', caseSensitive: false),
          ' ')
      .replaceAll(RegExp(r'<[^>]+>'), '') // remove remaining tags
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text;
}

/// AICERTS Courses Section with Two Symmetrical Rows
/// - Top and Bottom rows are perfectly aligned vertically
/// - Cards are never cut off - fully visible or out of view
/// - Manual navigation via arrows only
class AICERTSCoursesSection extends StatefulWidget {
  final Function(String)? onTextClicked;

  const AICERTSCoursesSection({
    super.key,
    this.onTextClicked,
  });

  @override
  State<AICERTSCoursesSection> createState() => _AICERTSCoursesSectionState();
}

class _AICERTSCoursesSectionState extends State<AICERTSCoursesSection> {
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _filterController = TextEditingController();

  // Card dimensions - MUST be consistent across both rows
  static const double cardWidth = 320.0;
  static const double cardSpacing = 20.0;
  static const double cardTotalWidth = cardWidth + cardSpacing;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _applyFilter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCourses = _allCourses);
    } else {
      final lowerQuery = query.toLowerCase();
      setState(() {
        _filteredCourses = _allCourses.where((course) {
          final title = course.displayTitle.toLowerCase();
          final description = (course.description ?? '').toLowerCase();
          return title.contains(lowerQuery) || description.contains(lowerQuery);
        }).toList();
      });
    }
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await AICertsService.fetchCourses();
      // Filter out courses without a cost (price_usd <= 0 or null)
      final paidCourses = courses.where((c) => (c.price ?? 0) > 0).toList();
      
      if (mounted) {
        setState(() {
          _allCourses = paidCourses;
          _filteredCourses = paidCourses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load courses';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _handleEnroll(Course course) async {
    if (!mounted) return;

    // Redirect to Custom Selection pathway with the specific course pre-selected
    // This is the same flow as the Custom Selection page
    if (mounted) {
      // Navigate to Custom Selection page with the course context
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CustomSelectionPage(
            initialCourseId: course.id.toString(),
          ),
        ),
      );
    }
  }

  void _handleAskAI(Course course) {
    if (!mounted) return;
    ConciergeManager.openAtBottomRightWithPrompt(
      "I am interested in the '${course.displayTitle}' certification course. "
      "Could you please provide detailed information about: "
      "\n1. The full curriculum and learning modules?"
      "\n2. What are the key benefits and career outcomes?"
      "\n3. Is there a certification upon completion, and who is the awarding body?"
      "\n4. What are the prerequisites for this course?"
      "\n5. How long does it take to complete?",
    );
  }

  void _showAddedToCartSnackbar(BuildContext context, Course course) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Added to Cart',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    course.displayTitle,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to cart or show cart panel
          },
        ),
      ),
    );
  }

  void _showAlreadyInCartSnackbar(BuildContext context, Course course) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This course is already in your cart',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Calculate how many FULL cards fit on screen without being cut
  int _calculateVisibleCount(double screenWidth) {
    const minEdgePadding = 24.0;
    int visibleCount =
        ((screenWidth - 2 * minEdgePadding + cardSpacing) / cardTotalWidth)
            .floor();
    if (visibleCount < 1) visibleCount = 1;
    return visibleCount;
  }

  /// Calculate edge padding for perfect centering
  double _calculateEdgePadding(double screenWidth, int visibleCount) {
    final totalContentWidth =
        visibleCount * cardWidth + (visibleCount - 1) * cardSpacing;
    return (screenWidth - totalContentWidth) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = screenWidth * 0.005; // 0.5% padding each side = 99% width

    if (_error != null) {
      return const SizedBox.shrink();
    }

    final visibleCount = _calculateVisibleCount(screenWidth);
    final edgePadding = _calculateEdgePadding(screenWidth, visibleCount);

    final coursesToDisplay = _isLoading
        ? List.generate(
            8,
            (index) => Course(
                id: index.toString(),
                title: 'Loading...',
                description: 'loading'))
        : (_filteredCourses.isEmpty && _filterController.text.isEmpty
            ? _allCourses
            : _filteredCourses);

    if (coursesToDisplay.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 64),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? colors.surface
            : colors.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
              color: colors.outline.withValues(alpha: 0.1), width: 1),
          bottom: BorderSide(
              color: colors.outline.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: Title + Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'AICERTS COURSES OFFERED',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                            fontSize: screenWidth < 768 ? 26 : 38,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Globally recognized self-paced professional certifications',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                            fontSize: screenWidth < 768 ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Course count badge
                if (!_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${coursesToDisplay.length} courses',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _filterController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Search AICERTS courses by name or topic...',
                    hintStyle: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.45),
                        fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: colors.primary, size: 20),
                    suffixIcon: _filterController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _filterController.clear();
                              _applyFilter('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                          color: colors.outline.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                          color: colors.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: colors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: _applyFilter,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chips - Centralized width-wise via parent column
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _AdvantageChip(
                    icon: Icons.verified_rounded,
                    label: 'Globally Recognised Certs',
                    color: colors.primary,
                  ),
                  _AdvantageChip(
                    icon: Icons.bolt_rounded,
                    label: 'Self-Paced Learning',
                    color: const Color(0xFF8C4928),
                  ),
                  _AdvantageChip(
                    icon: Icons.public_rounded,
                    label: 'Africa-Focused Content',
                    color: const Color(0xFF2E7D32),
                  ),
                  _AdvantageChip(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Industry-Validated Skills',
                    color: const Color(0xFFF79150),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Two ROWS Top and Bottom
          _TwoRowCourseGrid(
            courses: coursesToDisplay,
            onEnroll: _handleEnroll,
            onAskAI: _handleAskAI,
            onTextClicked: widget.onTextClicked,
            cardWidth: cardWidth,
            cardSpacing: cardSpacing,
          ),
        ],
      ),
    );
  }
}

/// Sleek partnership advantage chip
class _AdvantageChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AdvantageChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// Two-row grid that ensures vertical alignment and no cut cards
class _TwoRowCourseGrid extends StatefulWidget {
  final List<Course> courses;
  final Function(Course) onEnroll;
  final Function(Course) onAskAI;
  final Function(String)? onTextClicked;
  final double cardWidth;
  final double cardSpacing;

  const _TwoRowCourseGrid({
    required this.courses,
    required this.onEnroll,
    required this.onAskAI,
    this.onTextClicked,
    required this.cardWidth,
    required this.cardSpacing,
  });

  @override
  State<_TwoRowCourseGrid> createState() => _TwoRowCourseGridState();
}

class _TwoRowCourseGridState extends State<_TwoRowCourseGrid> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void _scroll(double delta) {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final target = (_scrollController.offset + delta)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final half = (widget.courses.length / 2).ceil();
    final topRow = widget.courses.take(half).toList();
    final bottomRow = widget.courses.skip(half).toList();

    while (bottomRow.length < topRow.length) {
      bottomRow.add(topRow[bottomRow.length % topRow.length]);
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    // Synchronized with _ModernCourseCard height
    final cardHeight = isMobile ? 420.0 : 460.0;
    final rowHeight = cardHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final horizontalPadding = isMobile ? 16.0 : 40.0;
        final availableWidth = screenWidth - (2 * horizontalPadding);

        // Calculate how many cards can fit comfortably (target ~320px)
        int count = isMobile
            ? 1
            : ((availableWidth + widget.cardSpacing) /
                    (320.0 + widget.cardSpacing))
                .floor();
        if (count < 1) count = 1;

        // Calculate the actual card width
        final actualCardWidth = isMobile
            ? (availableWidth - 10)
            : (availableWidth - (count - 1) * widget.cardSpacing) / count;
        final scrollStep = availableWidth + widget.cardSpacing;

        return Stack(
          children: [
            Container(
              height: isMobile ? (rowHeight + 40) : (rowHeight * 2) + 40,
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding.clamp(0, double.infinity)),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(
                      isMobile ? widget.courses.length : topRow.length,
                      (index) {
                    final topItem =
                        isMobile ? widget.courses[index] : topRow[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index <
                                (isMobile
                                        ? widget.courses.length
                                        : topRow.length) -
                                    1
                            ? widget.cardSpacing
                            : 0,
                      ),
                      child: SizedBox(
                        width: actualCardWidth,
                        child: Column(
                          children: [
                            _ModernCourseCard(
                              course: topItem,
                              onEnroll: () => widget.onEnroll(topItem),
                              onAskAI: () => widget.onAskAI(topItem),
                              onTextClicked: widget.onTextClicked,
                              cardWidth: actualCardWidth,
                            ),
                            if (!isMobile) ...[
                              const SizedBox(height: 24),
                              _ModernCourseCard(
                                course: bottomRow[index],
                                onEnroll: () =>
                                    widget.onEnroll(bottomRow[index]),
                                onAskAI: () => widget.onAskAI(bottomRow[index]),
                                onTextClicked: widget.onTextClicked,
                                cardWidth: actualCardWidth,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Left Arrow
            Positioned(
              left: 0,
              top: 0,
              bottom: 40,
              child: Center(
                child: _ArrowButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _scroll(-scrollStep),
                ),
              ),
            ),

            // Right Arrow
            Positioned(
              right: 0,
              top: 0,
              bottom: 40,
              child: Center(
                child: _ArrowButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _scroll(scrollStep),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Styled arrow button for manual navigation
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ArrowButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 48, color: colors.primary.withValues(alpha: 0.8)),
        ),
      ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
    );
  }
}

/// Modern course card with fixed width for perfect alignment
class _ModernCourseCard extends StatefulWidget {
  final Course course;
  final VoidCallback onEnroll;
  final VoidCallback? onAskAI;
  final Function(String)? onTextClicked;
  final double cardWidth;

  const _ModernCourseCard({
    super.key,
    required this.course,
    required this.onEnroll,
    this.onAskAI,
    this.onTextClicked,
    required this.cardWidth,
  });

  @override
  State<_ModernCourseCard> createState() => _ModernCourseCardState();
}

class _ModernCourseCardState extends State<_ModernCourseCard> {
  bool _isAddingToCart = false;
  double _fontSizeFactor = 1.0;
  final ScrollController _textScrollController = ScrollController();
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _isWishlisted = wishlistService.hasCourse(widget.course.id);
  }

  Future<void> _handleWishlist() async {
    if (_isWishlisted) {
      final success = await wishlistService.removeCourse(widget.course.id);
      if (success && mounted) {
        setState(() => _isWishlisted = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist'))
        );
      }
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WishlistLeadModal(
          course: widget.course,
          onComplete: (interest, timing, notes) async {
            final success = await wishlistService.addCourse(widget.course);
            if (success && mounted) {
              setState(() => _isWishlisted = true);
            }
          },
        ),
      );
    }
  }

  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    try {
      final success = await cartService.addCourse(widget.course);
      if (mounted && success) {
        _showAddedToCartSnackbar(context, widget.course);
      } else if (mounted && !success) {
        _showErrorSnackbar(context, 'Failed to add to cart');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  void _showAddedToCartSnackbar(BuildContext context, Course course) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Added to Cart',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    course.displayTitle,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to cart or show cart panel
          },
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _textScrollController.dispose();
    super.dispose();
  }

  void _toggleMagnify() {
    setState(() {
      if (_fontSizeFactor == 1.0) {
        _fontSizeFactor = 1.4;
      } else if (_fontSizeFactor == 1.4) {
        _fontSizeFactor = 1.8;
      } else {
        _fontSizeFactor = 1.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final cardHeight = isMobile ? 420.0 : 460.0;
    final imageHeight = (cardHeight * 0.5).clamp(130.0, 230.0);

    // Strip HTML tags and decode common entities, then remove repeated title
    String description = _stripHtml(
        widget.course.description ?? 'Self-paced industry certification.');
    final titleLower = widget.course.displayTitle.toLowerCase().trim();
    if (description.toLowerCase().trimLeft().startsWith(titleLower)) {
      if (description.length >= widget.course.displayTitle.length) {
        description =
            description.substring(widget.course.displayTitle.length).trimLeft();
      }
    }
    if (description.isEmpty) description = 'Self-paced industry certification.';

    // Price use localPrice if available, otherwise convert USD (localized conversion)
    final priceText = widget.course.localPrice ??
        (widget.course.price != null
            ? CurrencyService.instance.formatUSDAmount(widget.course.price!)
            : 'Contact for pricing');

    return Container(
      width: widget.cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Container(
            width: widget.cardWidth,
            height: imageHeight,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
              border: Border(bottom: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: AICERTSCourseCardImage(
                    featureImageUrl: widget.course.featureImageUrl,
                    certificateBadgeUrl: widget.course.certificateBadgeUrl,
                    width: widget.cardWidth,
                    height: imageHeight,
                    showBadge: false,
                    fit: BoxFit.contain,
                  ),
                ),
                // Magnifying Glass Zoom Icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    onPressed: _toggleMagnify,
                    icon: Icon(
                      _fontSizeFactor > 1.0 ? Icons.zoom_out : Icons.zoom_in,
                      size: 20,
                      color: colors.primary.withValues(alpha: 0.7),
                    ),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
                // Price Tag (Superimposed, right side, vertically central, no background)
                if (priceText != null)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 12,
                    child: Center(
                      child: Text(
                        priceText,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: colors.surface.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox.shrink(),

                  // Scrollable Description - No ellipsis
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outline.withValues(alpha: 0.05)),
                      ),
                      child: RawScrollbar(
                        controller: _textScrollController,
                        thumbVisibility: true,
                        thickness: 4,
                        radius: const Radius.circular(10),
                        thumbColor: colors.primary.withValues(alpha: 0.4),
                        child: SingleChildScrollView(
                          controller: _textScrollController,
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.9),
                                height: 1.6,
                                fontSize: 12 * _fontSizeFactor,
                                fontWeight: _fontSizeFactor > 1.0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CTA Buttons - Horizontally symmetrically aligned
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAddingToCart ? null : _handleAddToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isAddingToCart
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _handleWishlist,
                        icon: Icon(
                          _isWishlisted ? Icons.bookmark : Icons.bookmark_border,
                          color: _isWishlisted ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        tooltip: _isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onEnroll,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            side: BorderSide(color: colors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Enroll', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmering skeleton for the course card
class _ModernCourseSkeleton extends StatelessWidget {
  final double cardWidth;

  const _ModernCourseSkeleton({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final cardHeight = isMobile ? 440.0 : 480.0;
    final imageHeight = cardHeight * 0.6;

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: imageHeight,
            width: cardWidth,
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms, color: colors.primary.withValues(alpha: 0.05)),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title lines
                  _SkeletonLine(width: cardWidth * 0.7, height: 14),
                  const SizedBox(height: 8),
                  _SkeletonLine(width: cardWidth * 0.4, height: 14),
                  const SizedBox(height: 16),

                  // Description lines
                  _SkeletonLine(width: cardWidth * 0.9, height: 10),
                  const SizedBox(height: 6),
                  _SkeletonLine(width: cardWidth * 0.8, height: 10),
                  const SizedBox(height: 6),
                  _SkeletonLine(width: cardWidth * 0.6, height: 10),

                  const Spacer(),

                  // Bottom row (button placeholders)
                  Row(
                    children: [
                      _SkeletonLine(width: 80, height: 32, borderRadius: 8),
                      const SizedBox(width: 12),
                      _SkeletonLine(width: 80, height: 32, borderRadius: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonLine({
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
        duration: 1500.ms, color: colors.onSurface.withValues(alpha: 0.05));
  }
}