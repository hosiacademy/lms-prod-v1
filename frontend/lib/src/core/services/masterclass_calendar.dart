// lib/src/presentation/blocs/course/corporate/components/masterclass_calendar.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/src/data/models/masterclass.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/masterclass_data_provider.dart';
import 'package:frontend/src/core/services/currency_service.dart';
import 'package:frontend/src/core/theme/app_theme.dart';

class MasterclassCalendar extends StatefulWidget {
  final Map<DateTime, List<Masterclass>> events;
  final MasterclassDataProvider dataProvider;
  final Function(Masterclass) onMasterclassTap;
  final Function(Masterclass) onEnrollTap;
  final String? selectedType;

  const MasterclassCalendar({
    super.key,
    required this.events,
    required this.dataProvider,
    required this.onMasterclassTap,
    required this.onEnrollTap,
    this.selectedType,
  });

  @override
  State<MasterclassCalendar> createState() => MasterclassCalendarState();
}

class MasterclassCalendarState extends State<MasterclassCalendar> {
  static const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  int _selectedMonthIndex = 0; // 0 for ALL, 1-12 for specific months
  DateTime _baseDate = DateTime(DateTime.now().year, 1, 1);
  int? _highlightedQuarter;
  List<int> _highlightedMonthIndices = [];

  @override
  void initState() {
    super.initState();
    CurrencyService.instance.initialize();
  }

  // Public method to reset quarter and month filters
  void resetQuarterAndMonthFilters() {
    setState(() {
      _highlightedQuarter = null;
      _highlightedMonthIndices = [];
      _selectedMonthIndex = 0; // Reset to ALL mode
    });
  }

  List<DateTime> get _availableMonths {
    final months = <DateTime>[];
    for (int i = 0; i < 12; i++) {
      final newDate = DateTime(_baseDate.year, _baseDate.month + i, 1);
      months.add(newDate);
    }
    return months;
  }

  DateTime get _selectedMonth =>
      _availableMonths[(_selectedMonthIndex - 1).clamp(0, 11)];

  int _getQuarterForDate(DateTime date) {
    return ((date.month - 1) ~/ 3);
  }

  // Filter events based on stream_type
  Map<DateTime, List<Masterclass>> get _monthEvents {
    final filtered = <DateTime, List<Masterclass>>{};

    widget.events.forEach((date, masterclasses) {
      final isAllMode = _selectedMonthIndex == 0;
      final actualMonthIndex = (_availableMonths
              .indexWhere((m) => m.year == date.year && m.month == date.month) +
          1);

      final matchesMonth = isAllMode ||
          (_highlightedMonthIndices.isNotEmpty
              ? _highlightedMonthIndices.contains(actualMonthIndex)
              : actualMonthIndex == _selectedMonthIndex);

      if (matchesMonth) {
        final filteredClasses = masterclasses.where((masterclass) {
          if (widget.selectedType == null || widget.selectedType == 'all') {
            return true;
          }
          if (widget.selectedType == 'technical') {
            return masterclass.streamType?.toLowerCase() == 'technical';
          }
          if (widget.selectedType == 'professional') {
            return masterclass.streamType?.toLowerCase() == 'professional';
          }
          return true;
        }).toList();

        if (filteredClasses.isNotEmpty) {
          filtered[date] = filteredClasses;
        }
      }
    });

    return filtered;
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }

  String _getFullMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

  void _highlightQuarterMonths(int quarter) {
    setState(() {
      _highlightedQuarter = quarter;
      _highlightedMonthIndices = [
        quarter * 3 + 1,
        quarter * 3 + 2,
        quarter * 3 + 3,
      ];
      _selectedMonthIndex = quarter * 3 + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // === MONTH TABS ===
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMonthTab(
                monthDate: _baseDate,
                index: 0,
                isSelected: _selectedMonthIndex == 0,
                quarter: 0,
                isHighlighted: false,
                theme: theme,
                colorScheme: colorScheme,
                label: 'ALL',
                showYear: false,
              ),
              const SizedBox(width: 4),
              ...List.generate(12, (index) {
                final monthDate = _availableMonths[index];
                final actualIndex = index + 1;
                final isSelected = actualIndex == _selectedMonthIndex;
                final quarter = _getQuarterForDate(monthDate);
                final isHighlighted =
                    _highlightedMonthIndices.contains(actualIndex);

                return _buildMonthTab(
                  monthDate: monthDate,
                  index: actualIndex,
                  isSelected: isSelected,
                  quarter: quarter,
                  isHighlighted: isHighlighted,
                  theme: theme,
                  colorScheme: colorScheme,
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // === QUARTER TABS ===
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildQuarterTabs(),
          ),
        ),

        const SizedBox(height: 20),

        // === MASTERCLASS GRID ===
        Expanded(
          child: _buildCompactMonthSchedule(theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildMonthTab({
    required DateTime monthDate,
    required int index,
    required bool isSelected,
    required int quarter,
    required bool isHighlighted,
    required ThemeData theme,
    required ColorScheme colorScheme,
    String? label,
    bool showYear = true,
  }) {
    final quarterColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
    ];
    final quarterColor =
        index == 0 ? colorScheme.secondary : quarterColors[quarter];

    Color backgroundColor;
    if (isSelected || isHighlighted) {
      backgroundColor = quarterColor;
    } else {
      backgroundColor = colorScheme.surface.withValues(alpha: 0.7);
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonthIndex = index;
              _highlightedQuarter = null;
              _highlightedMonthIndices = [];
            });
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? quarterColor
                    : isHighlighted
                        ? quarterColor.withValues(alpha: 0.5)
                        : colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label ?? _getMonthName(monthDate),
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: (isSelected || isHighlighted)
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showYear)
                    Text(
                      '${monthDate.year}',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: (isSelected || isHighlighted)
                            ? colorScheme.onPrimary.withValues(alpha: 0.9)
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildQuarterTabs() {
    final tabs = <Widget>[];

    final quarters = <String, List<DateTime>>{};
    for (final month in _availableMonths) {
      final quarter = _getQuarterForDate(month);
      final year = month.year;
      final key = '$year-$quarter';

      if (!quarters.containsKey(key)) {
        quarters[key] = [];
      }
      quarters[key]!.add(month);
    }

    final sortedKeys = quarters.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('-');
        final bParts = b.split('-');
        final yearCompare =
            int.parse(aParts[0]).compareTo(int.parse(bParts[0]));
        if (yearCompare != 0) return yearCompare;
        return int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
      });

    for (final key in sortedKeys) {
      final monthsInQuarter = quarters[key]!;
      final year = monthsInQuarter.first.year;
      final quarter = _getQuarterForDate(monthsInQuarter.first);

      tabs.add(
        Expanded(
          flex: monthsInQuarter.length,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            child: _QuarterTab(
              year: year,
              quarter: quarter,
              monthCount: monthsInQuarter.length,
              isActive: _highlightedQuarter == quarter,
              onTap: () => _highlightQuarterMonths(quarter),
            ),
          ),
        ),
      );
    }

    return tabs;
  }

  Widget _buildCompactMonthSchedule(ThemeData theme, ColorScheme colorScheme) {
    final monthEvents = _monthEvents;
    final sortedDates = monthEvents.keys.toList()..sort();

    // Flatten & deduplicate by ID (events are keyed per-day, causing same MC to appear multiple times)
    final seenIds = <int>{};
    final uniqueMasterclasses = sortedDates
        .expand((date) => monthEvents[date]!)
        .where((m) => seenIds.add(m.id))
        .toList();

    // Group by title — one card per unique course title, hover reveals all locations
    final groupedByTitle = <String, List<Masterclass>>{};
    for (final m in uniqueMasterclasses) {
      groupedByTitle.putIfAbsent(m.title, () => []).add(m);
    }
    final titleKeys = groupedByTitle.keys.toList();

    if (titleKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedMonthIndex == 0
                  ? 'No masterclasses found matching your filters'
                  : 'No masterclasses scheduled for ${_getFullMonthName(_selectedMonth)}',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isLarge = constraints.maxWidth > 1200;
        final crossAxisCount = isMobile ? 2 : (isLarge ? 4 : 3);
        // More square cards to accommodate the large circular AICERTS image
        final childAspectRatio = isMobile ? 0.78 : 0.85;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: titleKeys.length,
            itemBuilder: (context, index) {
              final title = titleKeys[index];
              final sessions = groupedByTitle[title]!;
              final representative = sessions.first;
              final certImageUrl =
                  widget.dataProvider.getCertificationImage(representative);

              return _buildCompactMasterclassCard(
                masterclass: representative,
                allSessions: sessions,
                certificationImageUrl: certImageUrl,
                theme: theme,
                colorScheme: colorScheme,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCompactMasterclassCard({
    required Masterclass masterclass,
    required List<Masterclass> allSessions,
    required String? certificationImageUrl,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isTechnical = masterclass.streamType?.toLowerCase() == 'technical';
    final streamColor =
        isTechnical ? colorScheme.primary : colorScheme.secondary;

    return LongPressDraggable<Masterclass>(
      data: masterclass,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 200,
          height: 240,
          child: Opacity(
            opacity: 0.8,
            child: _MasterclassHoverCard(
              masterclass: masterclass,
              allSessions: allSessions,
              streamColor: streamColor,
              certificationImageUrl: certificationImageUrl,
              theme: theme,
              colorScheme: colorScheme,
              onTap: () {},
              onEnroll: (_) {},
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _MasterclassHoverCard(
          masterclass: masterclass,
          allSessions: allSessions,
          streamColor: streamColor,
          certificationImageUrl: certificationImageUrl,
          theme: theme,
          colorScheme: colorScheme,
          onTap: () => widget.onMasterclassTap(masterclass),
          onEnroll: (session) => widget.onEnrollTap(session),
        ),
      ),
      child: _MasterclassHoverCard(
        masterclass: masterclass,
        allSessions: allSessions,
        streamColor: streamColor,
        certificationImageUrl: certificationImageUrl,
        theme: theme,
        colorScheme: colorScheme,
        onTap: () => widget.onMasterclassTap(masterclass),
        onEnroll: (session) => widget.onEnrollTap(session),
      ),
    );
  }
}

// ── Hover Card ────────────────────────────────────────────────────────────────

class _MasterclassHoverCard extends StatefulWidget {
  final Masterclass masterclass;
  final List<Masterclass> allSessions;
  final Color streamColor;
  final String? certificationImageUrl;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final Function(Masterclass) onEnroll;

  const _MasterclassHoverCard({
    required this.masterclass,
    required this.allSessions,
    this.certificationImageUrl,
    required this.streamColor,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
    required this.onEnroll,
  });

  @override
  State<_MasterclassHoverCard> createState() => _MasterclassHoverCardState();
}

class _MasterclassHoverCardState extends State<_MasterclassHoverCard> {
  bool _isHovered = false;

  static String _countryFlag(String? countryName) {
    switch (countryName?.toLowerCase()) {
      case 'zimbabwe':
        return '🇿🇼';
      case 'kenya':
        return '🇰🇪';
      case 'zambia':
        return '🇿🇲';
      case 'south africa':
        return '🇿🇦';
      case 'nigeria':
        return '🇳🇬';
      case 'ghana':
        return '🇬🇭';
      case 'ethiopia':
        return '🇪🇹';
      case 'tanzania':
        return '🇹🇿';
      case 'uganda':
        return '🇺🇬';
      default:
        return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterclass = widget.masterclass;
    final sessions = widget.allSessions;
    final colorScheme = widget.colorScheme;
    final theme = widget.theme;
    final isTechnical = masterclass.streamType?.toLowerCase() == 'technical';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.hosiMidnight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.streamColor
                    .withValues(alpha: _isHovered ? 0.3 : 0.12),
                blurRadius: _isHovered ? 18 : 6,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
            border: Border.all(
              color: widget.streamColor
                  .withValues(alpha: _isHovered ? 0.5 : 0.2),
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // ── Normal card content ──────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top badges row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Stream type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isTechnical
                                  ? const Color(0xFF0D47A1)
                                      .withValues(alpha: 0.85)
                                  : const Color(0xFF1B5E20)
                                      .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isTechnical ? 'TECH' : 'PRO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          // Locations count badge (if multiple)
                          if (sessions.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.hosiPeach
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${sessions.length} locations',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Large circular AICERTS image (main focus) ────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Fill most of available width, capped for aesthetics
                              final size =
                                  (constraints.maxWidth * 0.82).clamp(
                                      50.0, 180.0);
                              return Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.streamColor
                                          .withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: widget.certificationImageUrl != null
                                      ? _buildCertImage(
                                          widget.certificationImageUrl!)
                                      : _buildInitialsCircle(
                                          masterclass.title),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // ── Title + price (bottom) ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            masterclass.title,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (masterclass.priceUsd != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              CurrencyService.instance
                                  .formatUSDAmount(masterclass.priceUsd!),
                              style: TextStyle(
                                color: AppTheme.hosiPeach,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Hover overlay: session locations list ────────────────
                AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_isHovered,
                    child: Container(
                      color: AppTheme.hosiMidnight.withValues(alpha: 0.96),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: title
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(10, 10, 10, 6),
                            child: Text(
                              masterclass.title,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                            height: 1,
                          ),
                          // Sessions scroll list
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              itemCount: sessions.length,
                              separatorBuilder: (_, __) => Divider(
                                color: Colors.white.withValues(alpha: 0.08),
                                height: 10,
                              ),
                              itemBuilder: (context, i) {
                                final session = sessions[i];
                                final flag =
                                    _countryFlag(session.countryName);
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Country + city
                                          Text(
                                            '$flag  ${session.city ?? ''}${session.city != null && session.countryName != null ? ', ' : ''}${session.countryName ?? ''}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          // Date range
                                          if (session.startDate != null)
                                            Text(
                                              session.formattedDateRange,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.65),
                                                fontSize: 9,
                                              ),
                                            ),
                                          // Venue
                                          if (session.venue != null)
                                            Text(
                                              session.venue!,
                                              style: TextStyle(
                                                color: AppTheme.hosiPeach
                                                    .withValues(alpha: 0.9),
                                                fontSize: 9,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Enroll button for this specific session
                                    GestureDetector(
                                      onTap: () => widget.onEnroll(session),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.hosiBrown,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ENROLL',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 30))
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1));
  }

  Widget _buildCertImage(String imageUrl) {
    if (imageUrl.endsWith('.svg') || imageUrl.contains('format=svg')) {
      return SvgPicture.network(
        imageUrl,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      ),
      errorWidget: (context, url, error) => _buildFallbackIcon(),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.hosiMidnight, AppTheme.hosiBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.school_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildInitialsCircle(String title) {
    final initials = title
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.streamColor.withValues(alpha: 0.7),
            widget.streamColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Quarter Tab ───────────────────────────────────────────────────────────────

class _QuarterTab extends StatelessWidget {
  final int year;
  final int quarter;
  final int monthCount;
  final bool isActive;
  final VoidCallback onTap;

  const _QuarterTab({
    required this.year,
    required this.quarter,
    required this.monthCount,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final quarterColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
    ];
    final quarterColor = quarterColors[quarter];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? quarterColor : quarterColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: quarterColor.withValues(alpha: isActive ? 1 : 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Q${quarter + 1}',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  height: 1.0,
                ),
              ),
              Text(
                '$year',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: isActive
                      ? colorScheme.onPrimary.withValues(alpha: 0.9)
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 8,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
