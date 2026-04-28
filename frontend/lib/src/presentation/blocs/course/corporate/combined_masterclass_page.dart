// lib/src/presentation/blocs/course/corporate/combined_masterclass_page.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'components/masterclass_calendar.dart';
import 'components/masterclass_filters.dart';
import 'components/masterclass_marquee.dart';
import 'providers/masterclass_data_provider.dart';
import 'providers/masterclass_enrollment.dart';
import 'package:frontend/src/data/models/masterclass.dart';
import '../../../widgets/headers/enrollment_page_header.dart';
import 'package:frontend/src/core/services/concierge_service.dart';
import 'package:frontend/src/presentation/widgets/aicerts/aicerts_image_widget.dart';
import 'package:frontend/src/core/services/currency_service.dart';
import 'package:frontend/src/core/theme/app_theme.dart';
import '../../../pages/onboarding/widgets/modals/ai_masterclass_schedule_modal.dart';

class CombinedMasterclassPage extends StatefulWidget {
  final String? initialType;
  final bool embedMode;

  const CombinedMasterclassPage({
    super.key,
    this.initialType,
    this.embedMode = false,
  });

  @override
  State<CombinedMasterclassPage> createState() =>
      _CombinedMasterclassPageState();
}

class _CombinedMasterclassPageState extends State<CombinedMasterclassPage> {
  late final MasterclassDataProvider _dataProvider;
  final GlobalKey<MasterclassCalendarState> _calendarKey =
      GlobalKey<MasterclassCalendarState>();

  @override
  void initState() {
    super.initState();
    _dataProvider = MasterclassDataProvider(initialType: widget.initialType);
    _dataProvider.loadMasterclasses();
  }

  @override
  void dispose() {
    _dataProvider.dispose();
    super.dispose();
  }

  void _resetCalendarFilters() {
    _calendarKey.currentState?.resetQuarterAndMonthFilters();
  }

  void _handleMasterclassTap(Masterclass masterclass) {
    // Check if this is the AI+ Finance™ masterclass
    final isAiFinance = masterclass.title.toLowerCase().contains('ai+ finance') ||
        masterclass.title.toLowerCase().contains('ai finance');
    
    if (isAiFinance) {
      // Show the schedule & curriculum modal
      AiMasterclassScheduleModal.show(context);
    } else {
      // Set concierge prompt for other masterclasses
      ConciergeService.setPrompt(
          "I am interested in the '${masterclass.title}' masterclass. "
          "Could you please provide detailed information about: "
          "\n1. The full curriculum and learning modules?"
          "\n2. What are the key benefits and career outcomes?"
          "\n3. Is there a certification upon completion, and who is the awarding body?"
          "\n4. What are the prerequisites for this masterclass?");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedMode) {
      return _buildMainContent(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return ValueListenableBuilder<MasterclassState>(
      valueListenable: _dataProvider.stateNotifier,
      builder: (context, state, child) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(child: Text('Error: ${state.error}'));
        }

        return Column(
          children: [
            if (!widget.embedMode)
              const EnrollmentPageHeader(
                title: 'Masterclasses',
                subtitle: 'Scale your expertise with AI-driven learning',
              ),

            _GeoLocalBanner(
              allMasterclasses: state.allMasterclasses,
              onMasterclassTap: _handleMasterclassTap,
              onEnrollTap: (masterclass) =>
                  MasterclassEnrollment.startEnrollment(
                context: context,
                masterclass: masterclass,
                onPaymentComplete: () {
                  _dataProvider.loadMasterclasses();
                },
              ),
            ),

            MasterclassMarquee(
              running: state.running,
              upcoming: state.upcoming,
              onMarqueeItemTap: _handleMasterclassTap,
            ),

            MasterclassFilters(
              selectedType: state.selectedType,
              selectedCountry: state.selectedCountry,
              selectedCity: state.selectedCity,
              selectedVenue: state.selectedVenue,
              countries: state.countries,
              cities: state.cities,
              venues: state.venues,
              onTypeChanged: _dataProvider.setType,
              onCountryChanged: _dataProvider.setCountry,
              onCityChanged: _dataProvider.setCity,
              onVenueChanged: _dataProvider.setVenue,
              onResetAllFilters: () {
                _dataProvider.resetFilters();
                _resetCalendarFilters();
              },
            ),

            Expanded(
              child: MasterclassCalendar(
                key: _calendarKey,
                events: state.events,
                dataProvider: _dataProvider,
                onMasterclassTap: _handleMasterclassTap,
                onEnrollTap: (masterclass) =>
                    MasterclassEnrollment.startEnrollment(
                  context: context,
                  masterclass: masterclass,
                  onPaymentComplete: () {
                    _dataProvider.loadMasterclasses();
                  },
                ),
                selectedType: state.selectedType,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── GEO-LOCATED TOP 5 BANNER ────────────────────────────────────────────────

class _GeoLocalBanner extends StatefulWidget {
  final List<Masterclass> allMasterclasses;
  final void Function(Masterclass) onEnrollTap;
  final void Function(Masterclass) onMasterclassTap;

  const _GeoLocalBanner({
    required this.allMasterclasses,
    required this.onEnrollTap,
    required this.onMasterclassTap,
  });

  @override
  State<_GeoLocalBanner> createState() => _GeoLocalBannerState();
}

class _GeoLocalBannerState extends State<_GeoLocalBanner> {
  String _countryCode = '';
  String _countryName = '';
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _detectCountry();
  }

  Future<void> _detectCountry() async {
    // Use already-cached country from CurrencyService (set during app startup)
    String code = CurrencyService.instance.userCountryCode;
    String name = CurrencyService.instance.userCountryName;

    // Fallback: detect directly if not yet available
    if (code.isEmpty) {
      try {
        final dio = Dio();
        final response = await dio
            .get('https://ipapi.co/json/')
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 && response.data != null) {
          code = (response.data['country_code'] as String?) ?? '';
          name = (response.data['country_name'] as String?) ?? '';
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _countryCode = code.toUpperCase();
        _countryName = name;
        _locationLoading = false;
      });
    }
  }

  List<Masterclass> get _localCourses {
    if (_countryCode.isEmpty) return [];
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 90));

    final filtered = widget.allMasterclasses.where((mc) {
      // Must match user's country
      final codeMatch =
          mc.countryCode?.toUpperCase() == _countryCode;
      if (!codeMatch) return false;
      // Must not be past (end_date >= today)
      if (mc.endDate != null && mc.endDate!.isBefore(now)) return false;
      // Must start within 90 days (or already ongoing)
      if (mc.startDate != null && mc.startDate!.isAfter(cutoff)) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (a.startDate == null) return 1;
      if (b.startDate == null) return -1;
      return a.startDate!.compareTo(b.startDate!);
    });

    return filtered.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_locationLoading) return const SizedBox.shrink();

    final courses = _localCourses;
    if (courses.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.hosiMidnight.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.hosiPeach,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  'In $_countryName',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.hosiMidnight,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.hosiPeach.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${courses.length} masterclass${courses.length == 1 ? '' : 'es'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.hosiBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scroll of course cards
          SizedBox(
            height: 310,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _buildCard(context, courses[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Masterclass mc) {
    final theme = Theme.of(context);
    final isOngoing = mc.isOngoing;

    return GestureDetector(
      onTap: () => widget.onMasterclassTap(mc),
      child: Container(
        width: 224,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOngoing
                ? AppTheme.successGreen.withValues(alpha: 0.35)
                : theme.colorScheme.outline.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            if (mc.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AICERTSImageWidget(
                  imageUrl: mc.imageUrl,
                  imageType: AICERTSImageType.course,
                  height: 120,
                  width: 224,
                  fit: BoxFit.cover,
                ),
              ),
          Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOngoing
                          ? AppTheme.successGreen.withValues(alpha: 0.12)
                          : AppTheme.hosiPeach.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOngoing ? 'Ongoing' : 'Upcoming',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isOngoing
                            ? AppTheme.successGreen
                            : AppTheme.hosiPeach,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Title
              Text(
                mc.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.hosiMidnight,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),

              // Dates
              if (mc.startDate != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mc.formattedDateRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 2),

              // Location
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 11, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      mc.displayLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Price + Enroll button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mc.formattedPrice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.hosiBrown,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onEnrollTap(mc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.hosiPeach,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Enroll',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}
