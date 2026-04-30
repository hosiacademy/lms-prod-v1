// lib/src/presentation/pages/learnerships/learnership_enrollment_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

import 'components/learnership_filters.dart';
import 'components/learnership_marquee.dart';
import 'providers/learnership_data_provider.dart';
import '../../../data/models/learnership.dart';
import '../../../core/utils/course_icons.dart';
import '../../widgets/headers/enrollment_page_header.dart';
import '../../widgets/ai/native_ai_assistant.dart';
import '../../widgets/panels/bulk_enrollment_panel.dart';
import '../../widgets/common/slide_in_panel.dart';
import '../../widgets/modals/multi_step_learnership_enrollment_modal.dart';
import '../../../core/services/currency_service.dart';

// ──────────────────────────────────────────────
//  Pathway Detail Modal
// ──────────────────────────────────────────────

class PathwayDetailModal extends StatelessWidget {
  final String pathwayTitle;
  final Color pathwayColor;
  final String description;
  final String? focusArea;
  final List<String> prerequisites;
  final List<String> certifications;
  final List<String> projects;
  final String? priceFormatted;
  final String? depositFormatted;
  final VoidCallback? onEnroll;

  const PathwayDetailModal({
    super.key,
    required this.pathwayTitle,
    required this.pathwayColor,
    required this.description,
    this.focusArea,
    required this.prerequisites,
    required this.certifications,
    required this.projects,
    this.priceFormatted,
    this.depositFormatted,
    this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      pathwayColor,
                      pathwayColor.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Top bar: back + close
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            onPressed: () => Navigator.of(context).pop(),
                            color: Colors.white,
                            tooltip: 'Back to programmes',
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                            color: Colors.white.withValues(alpha: 0.8),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    // Icon + title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pathwayTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontSize: 18,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Career Pathway',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content - descriptive only
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Focus Area',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        focusArea ?? description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          height: 1.5,
                        ),
                      ),
                      if (priceFormatted != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: pathwayColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: pathwayColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.payments_outlined, color: pathwayColor, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Programme Cost',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    Text(
                                      priceFormatted!,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: pathwayColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (depositFormatted != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Deposit from',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    Text(
                                      depositFormatted!,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (prerequisites.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Prerequisites',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...prerequisites.map((req) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 18, color: pathwayColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(req,
                                          style: const TextStyle(
                                              height: 1.4, fontSize: 13))),
                                ],
                              ),
                            )),
                      ],
                      if (certifications.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Certifications You\'ll Earn',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...certifications.map((cert) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.verified,
                                      size: 18, color: pathwayColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(cert,
                                          style: const TextStyle(
                                              height: 1.4, fontSize: 13))),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 32),
                      Text(
                        'Key Projects',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...projects.map((project) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.assignment_turned_in,
                                    size: 18, color: pathwayColor),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(project,
                                        style: const TextStyle(height: 1.4))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Footer - back + enroll
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
                  border: Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5))),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.onSurface,
                        side: BorderSide(color: colors.outline.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEnroll != null
                            ? () {
                                Navigator.of(context).pop();
                                onEnroll!();
                              }
                            : null,
                        icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                        label: const Text('ENROLL NOW',
                            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pathwayColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: colors.outlineVariant,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
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
    );
  }
}

// ──────────────────────────────────────────────
//  Main Page
// ──────────────────────────────────────────────

class LearnershipEnrollmentPage extends StatefulWidget {
  final String? initialSpecialization;
  final bool embedMode;
  final String? categoryFilter;  // NEW: Filter by category (e.g., 'Cybersecurity', 'AI & Blockchain')
  final String? title;           // NEW: Custom title for header
  final String? subtitle;        // NEW: Custom subtitle for header
  
  const LearnershipEnrollmentPage({
    super.key,
    this.initialSpecialization,
    this.embedMode = false,
    this.categoryFilter,  // Default to null (no filter)
    this.title,
    this.subtitle,
  });

  @override
  State<LearnershipEnrollmentPage> createState() =>
      _LearnershipEnrollmentPageState();
}

class _LearnershipEnrollmentPageState extends State<LearnershipEnrollmentPage> {
  late LearnershipDataProvider _dataProvider;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<NativeAIAssistantState> _aiAssistantKey =
      GlobalKey<NativeAIAssistantState>();
  bool _showPathwaysDiagram = false;
  late String _currentCategory;

  @override
  void initState() {
    super.initState();
    // Default to AI & Blockchain if no filter is provided
    _currentCategory = widget.categoryFilter ?? 'AI & Blockchain';
    _dataProvider = LearnershipDataProvider(
        initialSpecialization: widget.initialSpecialization,
        categoryFilter: _currentCategory);
    _dataProvider.loadLearnerships();

    _searchController.addListener(() {
      _dataProvider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _dataProvider.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setLearnershipAsPrompt(String learnershipName) {
    _aiAssistantKey.currentState?.setPromptAndRespond(learnershipName);
  }

  Widget _buildCategoryTab(String category, IconData icon) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelected = _currentCategory == category;

    return InkWell(
      onTap: () {
        if (_currentCategory == category) return;
        setState(() {
          _currentCategory = category;
          // Re-initialize or reload data provider with new category
          _dataProvider.dispose();
          _dataProvider = LearnershipDataProvider(
            initialSpecialization: widget.initialSpecialization,
            categoryFilter: _currentCategory,
          );
          _dataProvider.loadLearnerships();
          _dataProvider.setSearchQuery(_searchController.text);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colors.onPrimary : colors.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? colors.onPrimary : colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedMode) {
      return _buildMainContent();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        if (!widget.embedMode)
          EnrollmentPageHeader(
            title: widget.title ?? 'Learnerships',
            subtitle: widget.subtitle ?? 'Work-Integrated Learning Programs',
            searchController: _searchController,
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/onboarding');
              }
            },
          ),
        
        // Category Tabs
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.1))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildCategoryTab('AI & Blockchain', Icons.auto_awesome),
                const SizedBox(width: 12),
                _buildCategoryTab('Cybersecurity', Icons.security),
              ],
            ),
          ),
        ),
        if (widget.embedMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search learnerships...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () => _aiAssistantKey.currentState?.expandAI(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.outline.withValues(alpha: 0.1),
                  ),
                ),
                filled: true,
                fillColor:
                    colors.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
                bottom: BorderSide(
                    color: colors.outline.withValues(alpha: 0.1), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<LearnershipState>(
                valueListenable: _dataProvider.stateNotifier,
                builder: (context, state, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.categoryName ?? 'Career Pathways',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700, color: colors.onSurface),
                    ),
                    Text(
                      '${state.learnerships.length} programme${state.learnerships.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(
                    () => _showPathwaysDiagram = !_showPathwaysDiagram),
                icon: Icon(
                    _showPathwaysDiagram ? Icons.close : Icons.account_tree,
                    size: 18),
                label: Text(_showPathwaysDiagram ? 'Close' : 'View Pathways'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ],
          ),
        ),
        if (_showPathwaysDiagram) _buildPathwaysDiagram(theme, colors),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
                bottom: BorderSide(
                    color: colors.outline.withValues(alpha: 0.1), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ValueListenableBuilder<LearnershipState>(
                  valueListenable: _dataProvider.stateNotifier,
                  builder: (context, state, _) {
                    return LearnershipFilters(
                      selectedSpecialization: state.selectedSpecialization,
                      selectedCountry: state.selectedCountry,
                      selectedCity: state.selectedCity,
                      countries: state.countries,
                      cities: state.cities,
                      specializations: state.specializations,
                      onSpecializationChanged: (val) {
                        _dataProvider.setSpecialization(val);
                        _setLearnershipAsPrompt(
                            'Tell me about the $val career pathway');
                      },
                      onCountryChanged: _dataProvider.setCountry,
                      onCityChanged: _dataProvider.setCity,
                    );
                  },
                ),
              ),
              ValueListenableBuilder<LearnershipState>(
                valueListenable: _dataProvider.stateNotifier,
                builder: (context, state, _) {
                  return Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: colors.outlineVariant
                                  .withValues(alpha: 0.1))),
                      color: colors.surfaceContainerHighest,
                    ),
                    child: LearnershipMarquee(
                      enrollmentOpen: state.enrollmentOpen,
                      upcoming: state.upcoming,
                      onMarqueeItemTap: (learnership) =>
                          _setLearnershipAsPrompt(learnership.title),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<LearnershipState>(
            valueListenable: _dataProvider.stateNotifier,
            builder: (context, state, _) {
              if (state.isLoading)
                return Center(
                    child: CircularProgressIndicator(color: colors.primary));
              if (state.error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off,
                            size: 64,
                            color: colors.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _dataProvider.refresh(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state.learnerships.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: colors.onSurface),
                      const SizedBox(height: 16),
                      Text('No learnerships found',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: colors.onSurface)),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final isTablet = constraints.maxWidth < 1024;

                  Widget buildCard(int index) {
                    final learnership = state.learnerships[index];
                    return _LearnershipCard(
                      learnership: learnership,
                      onTitleTap: () => _setLearnershipAsPrompt(learnership.title),
                      onCardTap: () {
                        _setLearnershipAsPrompt(learnership.displayName);
                        _showPathwayDetails(context, learnership);
                      },
                      onEnroll: () => _showEnrollmentModal(learnership),
                    );
                  }

                  if (isMobile) {
                    // Mobile: full-width stacked list, no aspect ratio
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.learnerships.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: buildCard(index),
                      ),
                    );
                  }

                  // Tablet / Desktop: grid
                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 2 : 3,
                      childAspectRatio: 0.95, // Even more compact to remove blank space
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: state.learnerships.length,
                    itemBuilder: (context, index) => buildCard(index),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPathwayDetails(BuildContext context, Learnership learnership) {
    final pathwayData = _getPathwayData(learnership.specialization);

    showDialog(
      context: context,
      builder: (context) => PathwayDetailModal(
        pathwayTitle: learnership.displayName,
        pathwayColor: CourseIcons.getColorForSpecialization(
            learnership.specialization, Theme.of(context).colorScheme),
        description: learnership.description ??
            pathwayData['description'] ??
            'No description available.',
        focusArea: learnership.focus,
        prerequisites: learnership.prerequisites ?? [],
        certifications: pathwayData['certifications'] ?? [],
        projects: pathwayData['projects'] ?? [],
        priceFormatted: learnership.formattedPrice,
        depositFormatted: CurrencyService.instance.formatUSDAmount(
          learnership.calculatedPriceUsd * 0.30,
        ),
        onEnroll: learnership.isEnrollmentOpen
            ? () => _showEnrollmentModal(learnership)
            : null,
      ),
    );
  }

  Map<String, dynamic> _getPathwayData(String pathway) {
    return {
      'description':
          'A comprehensive 6-9 month programme designed to build expertise in $pathway through hands-on projects and industry certifications.',
      'certifications': [
        'AICerts Foundation Certification',
        'AWS/Azure/GCP Cloud Certification',
        'Industry Partner Certification',
      ],
      'projects': [
        'Capstone Project solving real-world problems',
        '3-5 practical application projects',
        'Professional portfolio development',
      ],
    };
  }

  Widget _buildPathwaysDiagram(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
            bottom: BorderSide(
                color: colors.outline.withValues(alpha: 0.1), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: colors.primary, size: 24),
              const SizedBox(width: 10),
              Text('4-Phase Learning Journey',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: colors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildPhaseCard(
                        'Foundation',
                        'Months 1-2',
                        'Build core AI fundamentals',
                        Icons.library_books,
                        colors.primary),
                    const SizedBox(width: 12),
                    _buildPhaseCard(
                        'Specialization',
                        'Months 3-4',
                        'Earn vendor certifications',
                        Icons.build,
                        colors.secondary),
                    const SizedBox(width: 12),
                    _buildPhaseCard(
                        'Application',
                        'Months 5-6',
                        'Deliver capstone project',
                        Icons.rocket_launch,
                        colors.tertiary),
                    const SizedBox(width: 12),
                    _buildPhaseCard(
                        'Readiness',
                        'Months 7-9',
                        'Prepare for job placement',
                        Icons.work,
                        colors.primary),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.3),
                        colors.secondary.withValues(alpha: 0.3),
                        colors.tertiary.withValues(alpha: 0.3),
                        colors.primary.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(String title, String duration, String description,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.1), // Higher opacity for dark mode
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? color.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.3), // Stronger border in dark mode
            width: isDark ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? color.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon,
                  color: isDark ? color.withValues(alpha: 0.9) : color,
                  size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? color.withValues(alpha: 0.95) : color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? color.withValues(alpha: 0.9)
                    : color.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? colorScheme.onSurface.withValues(
                        alpha: 0.95) // Even higher contrast for dark mode
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isDark
                    ? FontWeight.w500
                    : FontWeight.normal, // Slightly bolder in dark mode
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnrollmentModal(Learnership learnership) async {
    // Check if user is authenticated
    final isAuthenticated = await AuthService.isAuthenticated();
    
    // Show the correct multi-step learnership enrollment modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MultiStepLearnershipEnrollmentModal(
          learnership: learnership,
          onEnrollmentComplete: () {
            Navigator.of(context).pop();
            _dataProvider.refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enrollment submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          allowPrefill: isAuthenticated, // Only pre-fill if logged in
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
//  Learnership Card - Identical structure for all backend-loaded items
// ──────────────────────────────────────────────

class _LearnershipCard extends StatefulWidget {
  final Learnership learnership;
  final VoidCallback onTitleTap; // Title click → AI prompt
  final VoidCallback onCardTap; // Card body click → descriptive modal
  final VoidCallback onEnroll; // Button click → enrollment

  const _LearnershipCard({
    required this.learnership,
    required this.onTitleTap,
    required this.onCardTap,
    required this.onEnroll,
  });

  @override
  State<_LearnershipCard> createState() => _LearnershipCardState();
}

class _LearnershipCardState extends State<_LearnershipCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final learnership = widget.learnership;
    final courseIcon = CourseIcons.getIconForCourse(learnership.specialization);
    final cardColor = CourseIcons.getColorForSpecialization(learnership.specialization, colors);

    final card = MouseRegion(
      onEnter: (_) { if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isHovered = true)); },
      onExit:  (_) { if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isHovered = false)); },
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: _buildCard(theme, colors, learnership, courseIcon, cardColor),
      ),
    );

    return Draggable<Learnership>(
      data: learnership,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: 340, child: Opacity(opacity: 0.85, child: widget))),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }

  Widget _buildCard(ThemeData theme, ColorScheme colors,
      Learnership learnership, IconData courseIcon, Color cardColor) {
    final isDark = theme.brightness == Brightness.dark;
    final isOpen = learnership.isEnrollmentOpen;
    final hasImage = learnership.imageUrl?.isNotEmpty == true;
    final desc = learnership.focus ?? learnership.description ?? 'Work-integrated learning programme';
    final skillList = (learnership.skills?.isNotEmpty == true)
        ? learnership.skills!
        : (learnership.modules ?? []);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.6), // Elaborate border
          width: 2.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onCardTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── IMAGE (Fixed height for compactness) ───────────────────
                SizedBox(
                  height: 160, 
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background: network image or gradient fallback
                      if (hasImage)
                        Image.network(
                          learnership.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildImageFallback(cardColor, courseIcon),
                        )
                      else
                        _buildImageFallback(cardColor, courseIcon),

                      // Bottom scrim for title readability
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Status badge — top left
                      const SizedBox.shrink(), // Removed status inscriptions as requested

                      // Price badge — top right
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            (learnership.isFunded == true) ? 'FUNDED' : learnership.formattedPrice,
                            style: TextStyle(
                              color: (learnership.isFunded == true)
                                  ? Colors.greenAccent.shade200
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      // Title — bottom of image
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: widget.onTitleTap,
                          child: Text(
                            learnership.displayName,
                            style: const TextStyle(
                              color: Colors.white, // Visible title overlay
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── BODY ──────────────────────────────────────────
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row: duration + mode
                        Row(children: [
                          Icon(Icons.schedule_outlined, size: 14,
                              color: colors.onSurface.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text(
                            learnership.formattedDuration,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(CourseIcons.getDeliveryModeIcon(learnership.deliveryMode),
                              size: 14, color: colors.onSurface.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              learnership.deliveryModeDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // NQF badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cardColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              learnership.nqfLevel ?? 'NQF 5',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: cardColor,
                              ),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 12),

                        // Description
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurface.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Skill tags
                        if (skillList.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('KEY FOCUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: colors.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: skillList.take(4).map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cardColor.withValues(alpha: isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cardColor.withValues(alpha: isDark ? 0.9 : 0.8),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                        
                        const SizedBox(height: 16),

                        // ── CTA buttons ────────────────────────────────
                        Row(children: [
                          // Details button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onCardTap,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: cardColor.withValues(alpha: 0.5), width: 1.5),
                                foregroundColor: cardColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Enroll button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isOpen ? widget.onEnroll : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: isOpen ? cardColor : colors.onSurface.withValues(alpha: 0.08),
                                foregroundColor: isOpen ? Colors.white : colors.onSurface.withValues(alpha: 0.3),
                                elevation: isOpen && _isHovered ? 6 : 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                isOpen ? 'Enroll Now' : 'Closed',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ); // FIXED
  }

  Widget _buildImageFallback(Color cardColor, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor,
            Color.lerp(cardColor, Colors.black, 0.35)!,
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 56, color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }
}
