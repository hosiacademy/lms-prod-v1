import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/onboarding_header.dart';
import 'widgets/partnership_marquee.dart';
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

import 'widgets/overlays/corporate_overlay.dart';
import 'widgets/overlays/learnerships_overlay.dart';
import 'widgets/overlays/industry_overlay.dart';
import 'widgets/overlays/instructors_profiles_overlay.dart';
import 'widgets/overlays/custom_selection_overlay.dart';

import '../../blocs/course/corporate/combined_masterclass_page.dart';
import '../learnerships/learnership_enrollment_page.dart';
import '../industry_training/industry_training_enrollment_page.dart';
import '../custom_selection/custom_selection_page.dart';
import '../splash/splash_modal.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  Timer? _hideTimer;
  bool _isDisposed = false;
  List<Course> _featuredCourses = [];
  bool _isLoadingFeatured = true;
  String? _featuredError;

  Map<String, bool> _hoverStates = {
    'ai_blockchain': false,
    'cybersecurity': false,
    'learnerships': false,
    'custom_selection': false,
    'trainers': false,
  };

  String? _activeOverlay;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _pathwaysSectionKey = GlobalKey();
  bool _showLoginSheet = false;
  bool _showSplashModal = false;
  bool _isTrainingMenuVisible = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _fetchFeaturedCourses();
        _checkAndShowModals();
      }
    });
  }

  Future<void> _fetchFeaturedCourses() async {
    if (_isDisposed || !mounted) return;
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
    super.dispose();
  }

  void _toggleLoginSheet() {
    if (_isDisposed || !mounted) return;
    setState(() => _showLoginSheet = !_showLoginSheet);
  }

  void showOverlay(String name) {
    if (_isDisposed || !mounted) return;
    _hideTimer?.cancel();
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
    context.go(route);
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
        _showEnrollmentPage(context, const LearnershipEnrollmentPage());
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

  void _showEnrollmentPage(BuildContext context, Widget page) {
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
                ),
                if (!_isTrainingMenuVisible)
                  PartnershipMarquee(
                    onEnrollTap: () => _navigateToEnrollment('/enroll/corporate'),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HeroCarouselSection(
                          isLoading: _isLoadingFeatured,
                          courseError: _featuredError,
                          courses: _featuredCourses,
                        ),
                        AICERTSCoursesSection(
                          onTextClicked: _populateAISearch,
                        ),
                        const SizedBox(height: 64),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Learning Pathways',
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

                        /// ── FOOTER ─────────────────────────────────────────────────
                        Container(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(
                              vertical: 32, horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const PaymentMethodsMarquee(),
                              const SizedBox(height: 20),
                              // Divider FIRST — before links
                              Divider(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.25)),
                              const SizedBox(height: 16),
                              // Logo + compact horizontal links
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Logo on the left
                                  Image.asset(
                                    'assets/images/logo.png',
                                    height: 36,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.school_rounded,
                                        size: 36,
                                        color: Color(0xFFF79150)),
                                  ),
                                  const SizedBox(width: 30),
                                  // Links wrap
                                  Expanded(
                                    child: Wrap(
                                      spacing: 20,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        _FooterLink('AI Masterclasses',
                                            () => showOverlay('corporate')),
                                        _FooterLink('Learnerships',
                                            () => showOverlay('learnerships')),
                                        _FooterLink('Industry Training',
                                            () => showOverlay('industry')),
                                        _FooterLink('Instructors',
                                            () => showOverlay('trainers')),
                                        _FooterLink('Sign In',
                                            _toggleLoginSheet),
                                        _FooterLink(
                                            'info@hosiacademy.com', () {}),
                                        _FooterLink(
                                            '+27 (0) 11 023 1995', () {}),
                                        _FooterLink('Privacy Policy', () {}),
                                        _FooterLink(
                                            'Terms of Service', () {}),
                                      ].map((w) => w).toList(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '© ${DateTime.now().year} Hosi Academy South Africa. All rights reserved.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                  letterSpacing: 0.3,
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
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
