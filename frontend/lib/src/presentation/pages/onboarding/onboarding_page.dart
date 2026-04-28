import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/onboarding_header.dart';
import 'widgets/login_side_sheet.dart';
import 'widgets/sections/benefits_grid.dart';
import 'widgets/sections/statistics_section.dart';
import 'widgets/sections/testimonial_section.dart';
import 'widgets/sections/cta_section.dart';
import 'widgets/sections/hero_carousel.dart';
import 'widgets/sections/aicerts_courses.dart';
import '../../../core/services/aicerts_service.dart';
import '../../../data/models/course.dart';
import 'widgets/sections/learning_pathways_compact.dart';
import 'widgets/sections/payment_methods_marquee.dart';
import 'widgets/sections/current_promotions_section.dart';
import '../../../core/services/cart_service.dart';
import 'widgets/sections/african_offices_section.dart';

import 'widgets/overlays/corporate_overlay.dart';
import 'widgets/overlays/learnerships_overlay.dart';
import 'widgets/overlays/industry_overlay.dart';
import 'widgets/overlays/instructors_profiles_overlay.dart';
import 'widgets/overlays/custom_selection_overlay.dart';
import 'widgets/overlays/floating_promo_widget.dart';

import 'widgets/dialogs/africa_contacts_dialog.dart';
import 'widgets/dialogs/legal_modals.dart' as legal;
import 'widgets/modals/faq_modal.dart';
import 'widgets/modals/about_us_modal.dart';
import 'widgets/modals/contact_us_modal.dart';

import '../../blocs/course/corporate/combined_masterclass_page.dart';
import '../learnerships/learnership_enrollment_page.dart';
import 'cybersecurity_learnerships/cybersecurity_learnerships_page.dart';
import 'ai_blockchain_learnerships/ai_blockchain_learnerships_page.dart';
import '../industry_training/industry_training_enrollment_page.dart';
import '../custom_selection/custom_selection_page.dart';
import '../splash/splash_modal.dart';
import 'widgets/modals/partner_program_modal.dart';
import '../../../core/services/concierge_manager.dart';
import '../../widgets/panels/cart_panel.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback? onHeroReady;
  const OnboardingPage({super.key, this.onHeroReady});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  Timer? _hideTimer;
  bool _isDisposed = false;
  List<Course> _featuredCourses = [];
  bool _isLoadingFeatured = true;
  String? _featuredError;
  final ScrollController _scrollController = ScrollController();
  bool _fabCollapsed = false;  // smart-shift: true = icon-only, retreated right

  Map<String, bool> _hoverStates = {
    'ai_blockchain': false,
    'cybersecurity': false,
    'learnerships': false,
    'custom_selection': false,
    'trainers': false,
  };

  String? _activeOverlay;
  final TextEditingController _searchController = TextEditingController();
  bool _showLoginSheet = false;
  bool _showSplashModal = false;
  bool _isTrainingMenuVisible = false;
  bool _showCartPanel = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _pathwaysSectionKey = GlobalKey();

  void scrollToPathways() {
    final context = _pathwaysSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _fetchFeaturedCourses();
        _checkAndShowModals();
        // Initialize cart service
        cartService.init();
      }
    });
  }

  void _onScroll() {
    if (_isDisposed || !mounted) return;
    // Collapse FAB (icon-only) when scrolled past 300px to avoid overlapping CTAs
    final collapsed = _scrollController.offset > 300;
    if (collapsed != _fabCollapsed) {
      setState(() => _fabCollapsed = collapsed);
    }
  }

  Future<void> _fetchFeaturedCourses() async {
    if (_isDisposed || !mounted) return;
    
    // Immediately signal that the hero/layout is ready to dismiss the splash screen.
    // This prevents the slow backend from blocking the app loading experience.
    widget.onHeroReady?.call();
    
    setState(() {
      _isLoadingFeatured = true;
      _featuredError = null;
    });

    try {
      final courses = await AICertsService.fetchCourses();
      if (!_isDisposed && mounted) {
        setState(() {
          _featuredCourses = courses;
          _isLoadingFeatured = false;
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _featuredError = 'Failed to load featured courses.';
          _isLoadingFeatured = false;
        });
      }
    }
  }

  Future<void> _checkAndShowModals() async {
    // No blocking modals on load — page renders directly
  }

  Future<void> _onSplashComplete() async {
    if (!_isDisposed && mounted) {
      setState(() => _showSplashModal = false);
    }
  }

  void _populateAISearch(String prompt) {
    if (_isDisposed || !mounted) return;
    setState(() => _searchController.text = prompt);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleLoginSheet() {
    if (_isDisposed || !mounted) return;
    setState(() => _showLoginSheet = !_showLoginSheet);
  }

  void _toggleCartPanel() {
    if (_isDisposed || !mounted) return;
    setState(() => _showCartPanel = !_showCartPanel);
  }

  void showOverlay(String name) {
    if (_isDisposed || !mounted) return;
    _hideTimer?.cancel();
    ConciergeManager.closeAny();
    setState(() => _activeOverlay = name);
  }

  void scheduleHideOverlay() {
    if (_isDisposed) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 450), () {
      if (!_isDisposed && mounted) setState(() => _activeOverlay = null);
    });
  }

  void cancelHideOverlay() {
    _hideTimer?.cancel();
  }

  void hideOverlayImmediately() {
    if (_isDisposed || !mounted) return;
    _hideTimer?.cancel();
    setState(() => _activeOverlay = null);
  }

  void _onHover(String item, bool isHovering) {
    if (_isDisposed || !mounted) return;
    setState(() => _hoverStates[item] = isHovering);
  }

  void _onTrainingMenuVisibilityChanged(bool isVisible) {
    if (_isDisposed || !mounted) return;
    setState(() => _isTrainingMenuVisible = isVisible);
  }

  void _onNavigate(String route) {
    hideOverlayImmediately();

    // Handle enrollment pathway routes
    switch (route) {
      case '/enroll/corporate':
        _showEnrollmentPage(context, const CombinedMasterclassPage());
        break;
      case '/enroll/learnerships':
        // Default learnerships - show AI & Blockchain category
        _showEnrollmentPage(context, const AIBlockchainLearnershipsPage());
        break;
      case '/enroll/cybersecurity':
        // Cybersecurity category only
        _showEnrollmentPage(context, const CybersecurityLearnershipsPage());
        break;
      case '/enroll/ai-blockchain':
        // AI & Blockchain category only
        _showEnrollmentPage(context, const AIBlockchainLearnershipsPage());
        break;
      case '/enroll/industry':
        _showEnrollmentPage(context, const IndustryTrainingEnrollmentPage());
        break;
      case '/enroll/custom':
        _showEnrollmentPage(context, const CustomSelectionPage());
        break;
      default:
        context.go(route);
    }
  }

  void _navigateToEnrollment(String route) {
    hideOverlayImmediately();

    switch (route) {
      case 'trainers':
        showOverlay('trainers');
        break;
      case '/enroll/corporate':
        _showEnrollmentPage(context, const CombinedMasterclassPage());
        break;
      case '/enroll/learnerships':
        // Default learnerships - show AI & Blockchain category
        _showEnrollmentPage(context, const AIBlockchainLearnershipsPage());
        break;
      case '/enroll/cybersecurity':
        // Cybersecurity category only
        _showEnrollmentPage(context, const CybersecurityLearnershipsPage());
        break;
      case '/enroll/ai-blockchain':
        // AI & Blockchain category only
        _showEnrollmentPage(context, const AIBlockchainLearnershipsPage());
        break;
      case '/enroll/industry':
        _showEnrollmentPage(context, const IndustryTrainingEnrollmentPage());
        break;
      case '/enroll/custom':
        _showEnrollmentPage(context, const CustomSelectionPage());
        break;
      default:
        context.go(route);
    }
  }

  Widget _buildOverlay(String name) {
    switch (name) {
      case 'corporate':
      case 'ai_blockchain':
        return CorporateOverlay(
          onHide: hideOverlayImmediately,
          onViewMasterclassSchedule: () {
            hideOverlayImmediately();
            _showEnrollmentPage(context, const CombinedMasterclassPage());
          },
          onCreateOwnMasterclass: () {
            hideOverlayImmediately();
            _showEnrollmentPage(
              context,
              const CombinedMasterclassPage(initialType: 'technical'),
            );
          },
          onFullDetails: () {
            hideOverlayImmediately();
            _showEnrollmentPage(context, const CombinedMasterclassPage());
          },
          onMouseEnter: cancelHideOverlay,
          onMouseExit: scheduleHideOverlay,
        );

      case 'cybersecurity':
        return CorporateOverlay(
          onHide: hideOverlayImmediately,
          onViewMasterclassSchedule: () {
            hideOverlayImmediately();
            _showEnrollmentPage(context, const CombinedMasterclassPage());
          },
          onFullDetails: () {
            hideOverlayImmediately();
            _showEnrollmentPage(context, const CombinedMasterclassPage());
          },
          onMouseEnter: cancelHideOverlay,
          onMouseExit: scheduleHideOverlay,
        );

      case 'learnerships':
        return LearnershipsOverlay(
          onHide: hideOverlayImmediately,
          onApplyNow: () {
            hideOverlayImmediately();
            _showEnrollmentPage(context, const LearnershipEnrollmentPage());
          },
          onDownloadBrochure: () {
            hideOverlayImmediately();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Downloading brochure...')),
            );
          },
          onMouseEnter: cancelHideOverlay,
          onMouseExit: scheduleHideOverlay,
        );

      case 'industry':
        return IndustryTrainingOverlay(
          onHide: hideOverlayImmediately,
          onBrowseCatalog: () {
            hideOverlayImmediately();
            _showEnrollmentPage(
                context, const IndustryTrainingEnrollmentPage());
          },
          onScheduleConsultation: () {
            hideOverlayImmediately();
            _showEnrollmentPage(
                context, const IndustryTrainingEnrollmentPage());
          },
          onMouseEnter: cancelHideOverlay,
          onMouseExit: scheduleHideOverlay,
        );

      case 'custom_selection':
        return CustomSelectionOverlay(
          onHide: hideOverlayImmediately,
          onBrowseCourses: () {
            hideOverlayImmediately();
            _showEnrollmentPage(context, const CustomSelectionPage());
          },
          onViewCart: () {
            hideOverlayImmediately();
            _showEnrollmentPage(
                context, const CustomSelectionPage(initialView: 'cart'));
          },
          onMouseEnter: cancelHideOverlay,
          onMouseExit: scheduleHideOverlay,
        );

      case 'trainers':
      case 'instructors':
        return InstructorsProfilesOverlay(
          isModal: false,
          onHide: hideOverlayImmediately,
          onMouseEnter: cancelHideOverlay,
          onMouseExit: scheduleHideOverlay,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _footerColLink(
      BuildContext context, String label, VoidCallback? onTap, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: onTap != null
                ? theme.colorScheme.onSurface.withValues(alpha: 0.75)
                : theme.colorScheme.onSurface.withValues(alpha: 0.45),
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _footerColumn(
      ThemeData theme, String heading, List<Widget> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            letterSpacing: 1.1,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        ...links,
      ],
    );
  }

  void _showEnrollmentPage(BuildContext context, Widget page) {
    ConciergeManager.closeAny();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        pageBuilder: (context, animation, secondaryAnimation) {
          final colorScheme = Theme.of(context).colorScheme;
          final size = MediaQuery.of(context).size;
          final isMobile = size.width < 600;

          return Align(
            alignment: isMobile ? Alignment.center : Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 0 : 20,
                horizontal: isMobile ? 0 : 10,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? size.width : size.width * 0.90,
                  maxHeight: isMobile ? size.height : size.height * 0.95,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: isMobile
                        ? BorderRadius.zero
                        : const BorderRadius.only(
                            topRight: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(10, 0),
                      ),
                    ],
                    border: isMobile
                        ? null
                        : Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                            width: 1,
                          ),
                  ),
                  child: ClipRRect(
                    borderRadius: isMobile
                        ? BorderRadius.zero
                        : const BorderRadius.only(
                            topRight: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                    child: Scaffold(body: page),
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          var tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OnboardingHeader(
                  hoverStates: _hoverStates,
                  onHover: _onHover,
                  onLoginPressed: _toggleLoginSheet,
                  searchController: _searchController,
                  onShowOverlay: showOverlay,
                  onHideOverlay: scheduleHideOverlay,
                  onNavigate: _onNavigate,
                  onMenuVisibilityChanged: _onTrainingMenuVisibilityChanged,
                  onCartPressed: _toggleCartPanel,
                  onPathwaysTap: scrollToPathways,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HeroCarouselSection(
                          isLoading: _isLoadingFeatured,
                          courseError: _featuredError,
                          courses: _featuredCourses,
                          onExploreCourses: () {
                            _navigateToEnrollment('/enroll/corporate');
                          },
                          onEnrollPressed: (course) {
                            _showEnrollmentPage(context, const CombinedMasterclassPage());
                          },
                        ),
                        AICERTSCoursesSection(
                          onTextClicked: _populateAISearch,
                        ),
                        CurrentPromotionsSection(
                          onEnrollTap: (pathway) {
                            if (pathway == 'masterclass') {
                              _showEnrollmentPage(context, const CombinedMasterclassPage());
                            } else if (pathway == 'aicerts_custom_industry' || pathway == 'aicerts') {
                              _showEnrollmentPage(context, const CustomSelectionPage());
                            } else if (pathway == 'industry_training') {
                              _showEnrollmentPage(context, const IndustryTrainingEnrollmentPage());
                            } else {
                              _showEnrollmentPage(context, const CombinedMasterclassPage());
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Click to navigate to learning pathway',
                            style: textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 32,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        KeyedSubtree(
                          key: _pathwaysSectionKey,
                          child: LearningPathwaysCompact(
                              onPathSelected: _navigateToEnrollment),
                        ),
                        const SizedBox(height: 40),
                        // Expert Trainers - Centered standalone button
                        Center(
                          child: GestureDetector(
                            onTap: () => showOverlay('trainers'),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth = MediaQuery.of(context).size.width;
                                  final isMobile = screenWidth < 600;
                                  final scale = 0.7; // 30% smaller
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: (isMobile ? 20 : 28) * scale,
                                      vertical: (isMobile ? 12 : 16) * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1A1A2E), Color(0xFF8C4928)],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.people_rounded, color: Colors.white, size: 24 * scale),
                                        SizedBox(width: 12 * scale),
                                        Flexible(
                                          child: Text(
                                            'Meet Our Trainers',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: (isMobile ? 14 : 16) * scale,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'What You Get',
                            style: textTheme.headlineMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const BenefitsGridSection(),
                        StatisticsSection(theme: theme),
                        const TestimonialSection(),
                        CtaSection(
                          theme: theme,
                          colorScheme: colorScheme,
                          onPressed: () {
                            if (_pathwaysSectionKey.currentContext != null) {
                              Scrollable.ensureVisible(
                                _pathwaysSectionKey.currentContext!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),

                        // ── Payment methods strip ──
                        const PaymentMethodsMarquee(),

                        const SizedBox(height: 48),
                        
                        // ── Visit Our African Offices ──
                        const AfricanOfficesSection(),

                        // ── Multi-column footer (below divider) ──
                        Container(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Demarcation line
                              Divider(
                                height: 1,
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.18),
                              ),
                              // Footer columns
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isMobile = constraints.maxWidth < 640;
                                  final isSmallMobile = constraints.maxWidth < 480;
                                  return Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        isSmallMobile ? 12 : (isMobile ? 16 : 32), 
                                        32, 
                                        isSmallMobile ? 12 : (isMobile ? 16 : 32), 
                                        24),
                                    child: Builder(
                                      builder: (context) {
                                        final colPrograms = _footerColumn(
                                          theme,
                                          'Programs',
                                          [
                                            _footerColLink(context, 'AI Masterclasses', () => _showEnrollmentPage(context, const CombinedMasterclassPage()), theme),
                                            _footerColLink(context, 'AI & Blockchain Learnerships', () => _showEnrollmentPage(context, const LearnershipEnrollmentPage(categoryFilter: 'AI & Blockchain')), theme),
                                            _footerColLink(context, 'Cybersecurity Learnerships', () => _showEnrollmentPage(context, const CybersecurityLearnershipsPage()), theme),
                                            _footerColLink(context, 'Industry Training', () => _showEnrollmentPage(context, const IndustryTrainingEnrollmentPage()), theme),
                                            _footerColLink(context, 'Custom Training', () => _showEnrollmentPage(context, const CustomSelectionPage()), theme),
                                          ],
                                        );

                                        final colEcosystem = _footerColumn(
                                          theme,
                                          'Ecosystem',
                                          [
                                            _footerColLink(context, 'Student Portal', _toggleLoginSheet, theme),
                                            _footerColLink(context, 'Expert Trainers', () => showOverlay('trainers'), theme),
                                            _footerColLink(context, 'Become a Partner', () => PartnerProgramModal.show(context), theme),
                                            _footerColLink(context, 'About Us', () => showDialog(context: context, builder: (_) => const AboutUsModal()), theme),
                                            _footerColLink(context, 'FAQ', () => showDialog(context: context, builder: (_) => const FAQModal()), theme),
                                          ],
                                        );

                                        final colContact = _footerColumn(
                                          theme,
                                          'Contact & Support',
                                          [
                                            _footerColLink(context, 'info@hosiacademy.com', () => showDialog(context: context, builder: (_) => const ContactUsModal()), theme),
                                            _footerColLink(context, 'Contacts', () => AfricaContactsDialog.show(context), theme),
                                            _footerColLink(context, 'Privacy Policy', () => legal.PrivacyPolicyModal.show(context), theme),
                                            _footerColLink(context, 'Terms of Service', () => legal.TermsConditionsModal.show(context), theme),
                                          ],
                                        );

                                        if (isSmallMobile) {
                                          // Very small mobile: stack everything vertically with compact spacing
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Logo section
                                              Image.asset(
                                                'assets/images/logo.png',
                                                height: 40,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Empowering Africa through AI & Technology',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                                  fontSize: 10,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              // Stack columns vertically
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  colPrograms,
                                                  const SizedBox(height: 20),
                                                  colEcosystem,
                                                  const SizedBox(height: 20),
                                                  colContact,
                                                ],
                                              ),
                                            ],
                                          );
                                        } else if (isMobile) {
                                          // Mobile: logo top, then 3 columns in responsive grid
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Image.asset(
                                                'assets/images/logo.png',
                                                height: 44,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Empowering Africa\nthrough AI & Technology',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                                  fontSize: 11,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              // Use Wrap for better responsiveness
                                              Wrap(
                                                spacing: 16,
                                                runSpacing: 20,
                                                children: [
                                                  SizedBox(
                                                    width: (constraints.maxWidth - 16) / 2,
                                                    child: colPrograms,
                                                  ),
                                                  SizedBox(
                                                    width: (constraints.maxWidth - 16) / 2,
                                                    child: colEcosystem,
                                                  ),
                                                  SizedBox(
                                                    width: constraints.maxWidth,
                                                    child: colContact,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        }

                                        // Desktop: logo left | 3 equal columns right
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Logo block
                                            SizedBox(
                                              width: 180,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/logo.png',
                                                    height: 52,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Empowering Africa\nthrough AI & Technology',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 48),
                                            // 3 equal columns
                                            Expanded(
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: colPrograms),
                                                  const SizedBox(width: 24),
                                                  Expanded(child: colEcosystem),
                                                  const SizedBox(width: 24),
                                                  Expanded(child: colContact),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),

                              // Bottom bar — copyright only
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.12),
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '© ${DateTime.now().year} Hosi Academy South Africa. All rights reserved.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
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
          if (_activeOverlay != null) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: hideOverlayImmediately,
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
            Positioned.fill(
              child: MouseRegion(
                onEnter: (_) {
                  if (mounted) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => cancelHideOverlay());
                  }
                },
                onExit: (_) {
                  if (mounted) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => scheduleHideOverlay());
                  }
                },
                hitTestBehavior: HitTestBehavior.opaque,
                child: Center(
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        final screenHeight = constraints.maxHeight;
                        final isMobile = screenWidth < 600;
                        final overlayWidth =
                            isMobile ? screenWidth : screenWidth * 0.98;
                        final overlayMaxHeight =
                            isMobile ? screenHeight : screenHeight * 0.9;

                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: overlayWidth,
                            maxHeight: overlayMaxHeight,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                )
                              ],
                            ),
                            child: _buildOverlay(_activeOverlay!),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_showSplashModal)
            Positioned.fill(child: SplashModal(onComplete: _onSplashComplete)),
          if (_showLoginSheet)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleLoginSheet,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Align(
                    alignment: MediaQuery.of(context).size.width > 600
                        ? Alignment.centerRight
                        : Alignment.center,
                    child: GestureDetector(
                      onTap: () {}, // Prevent closure when clicking on sheet
                      child: LoginSideSheet(
                        onClose: _toggleLoginSheet,
                        onLoginSuccess: () {
                          _toggleLoginSheet();
                          context.go('/');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_showCartPanel)
            Positioned.fill(
              child: Stack(
                children: [
                  // Backdrop
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _toggleCartPanel,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  // Cart Panel
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {}, // Prevent closure when clicking on panel
                      child: const CartPanel(),
                    ),
                  ),
                ],
              ),
            ),
          // ── Floating Promotion (bottom-left) ──────────────────────────
          Positioned(
            left: 20,
            bottom: 20,
            child: FloatingPromoWidget(),
          ),
          // ── Floating Concierge FAB (bottom-right, smart-shift) ──────────
          ValueListenableBuilder<bool>(
            valueListenable: ConciergeManager.isOpen,
            builder: (context, isOpen, _) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                right: _fabCollapsed ? -8 : 16,
                bottom: 20,
                child: _ConciergeFab(
                  isOpen: isOpen,
                  collapsed: _fabCollapsed,
                  onTap: () => ConciergeManager.toggleFromFab(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Fixed bottom-right concierge FAB with smart-shift (collapses to icon only)
class _ConciergeFab extends StatefulWidget {
  final bool isOpen;
  final bool collapsed;
  final VoidCallback onTap;

  const _ConciergeFab({
    required this.isOpen,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<_ConciergeFab> createState() => _ConciergeFabState();
}

class _ConciergeFabState extends State<_ConciergeFab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final showLabel = !widget.collapsed || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = false);
          });
        }
      },
      child: Tooltip(
        message: 'Click to open Hosi Academy AI Concierge',
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isOpen || _hovered
                    ? [const Color(0xFF8B4513), const Color(0xFFF79150)]
                    : [const Color(0xFF172E3D), const Color(0xFF8B4513)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF79150)
                      .withValues(alpha: _hovered ? 0.45 : 0.25),
                  blurRadius: _hovered ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.isOpen
                    ? const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20)
                    : Image.asset(
                        'assets/images/Lms.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.isOpen ? 'Close Concierge' : 'Hosi AI Concierge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink(this.label, this.onTap);

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = false);
          });
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: _hovered
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.6),
                fontWeight: _hovered ? FontWeight.w700 : FontWeight.w500,
                decoration:
                    _hovered ? TextDecoration.underline : TextDecoration.none,
                decorationColor: colors.primary,
              ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}
