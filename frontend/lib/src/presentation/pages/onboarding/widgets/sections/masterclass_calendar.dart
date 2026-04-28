// lib/src/presentation/blocs/course/corporate/components/masterclass_calendar.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/src/data/models/masterclass.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../blocs/course/corporate/providers/masterclass_data_provider.dart';
import 'package:frontend/src/core/services/aicerts_service.dart';
import 'package:frontend/src/core/services/currency_service.dart';
import 'package:frontend/src/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../../../core/providers/cart_provider.dart';
import '../../../../../presentation/widgets/common/safe_network_image.dart';

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
    // Initialize currency service for IP-based currency conversion
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

  String _getQuarterName(int quarter) {
    final quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
    return quarters[quarter];
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
        // Apply stream_type filtering
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
    return months[date.month - 1];
  }

  String _getFullMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[date.month - 1];
  }

  // Highlight months when quarter is clicked
  void _highlightQuarterMonths(int quarter) {
    setState(() {
      _highlightedQuarter = quarter;
      _highlightedMonthIndices = [
        quarter * 3 + 1,
        quarter * 3 + 2,
        quarter * 3 + 3,
      ];
      _selectedMonthIndex =
          quarter * 3 + 1; // Default to first month of quarter
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // === MONTH TABS - horizontally scrollable ===
        Container(
          width: double.infinity,
          margin:
              const EdgeInsets.symmetric(horizontal: 12.0), // Increased margin
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 4), // Add padding for scroll
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // ALL Tab
                _buildMonthTab(
                  monthDate: _baseDate,
                  index: 0,
                  isSelected: _selectedMonthIndex == 0,
                  quarter: 0,
                  isHighlighted: false,
                  theme: theme,
                  colorScheme: colorScheme,
                  label: 'ALL',
                ),
                // January to December Tabs
                ...List.generate(12, (index) {
                  final monthDate = _availableMonths[index];
                  final actualIndex = index + 1;
                  final isSelected = actualIndex == _selectedMonthIndex;
                  final quarter = _getQuarterForDate(monthDate);
                  final isHighlighted =
                      _highlightedMonthIndices.contains(actualIndex);

                  return Padding(
                    padding: const EdgeInsets.only(
                        left: 10), // Increased from 6 to 10
                    child: _buildMonthTab(
                      monthDate: monthDate,
                      index: actualIndex,
                      isSelected: isSelected,
                      quarter: quarter,
                      isHighlighted: isHighlighted,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // === QUARTER TABS - aligned flush under months ===
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildQuarterTabs(),
          ),
        ),

        const SizedBox(height: 20),

        // === COMPACT MASTERCLASS SCHEDULE ===
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

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMonthIndex = index;
          _highlightedQuarter = null;
          _highlightedMonthIndices = [];
        });
      },
      child: Container(
        width: 64, // Increased from 56 for better mobile touch targets
        height: 48, // Increased from 44 for better mobile touch targets
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6), // Slightly larger radius
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
          child: Text(
            label ?? _getMonthName(monthDate),
            style: theme.textTheme.labelMedium!.copyWith(
              color: (isSelected || isHighlighted)
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12, // Slightly larger font
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible, // Allow full text display
          ),
        ),
      ),
    );
  }

  List<Widget> _buildQuarterTabs() {
    final tabs = <Widget>[];

    // Group months by year and quarter (calendar-year based)
    final quarters = <String, List<DateTime>>{};
    for (final month in _availableMonths) {
      final quarter = _getQuarterForDate(month);
      final year = month.year;
      final key = '$year-$quarter'; // e.g., "2026-3" or "2027-0"

      if (!quarters.containsKey(key)) {
        quarters[key] = [];
      }
      quarters[key]!.add(month);
    }

    // Sort quarters by year-quarter key
    final sortedKeys = quarters.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('-');
        final bParts = b.split('-');
        final yearCompare =
            int.parse(aParts[0]).compareTo(int.parse(bParts[0]));
        if (yearCompare != 0) return yearCompare;
        return int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
      });

    // Create quarter tabs with proper alignment
    for (final key in sortedKeys) {
      final monthsInQuarter = quarters[key]!;
      final year = monthsInQuarter.first.year;
      final quarter = _getQuarterForDate(monthsInQuarter.first);

      tabs.add(
        Expanded(
          flex: monthsInQuarter.length,
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 2), // Increased margin
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

    var masterclasses =
        sortedDates.expand((date) => monthEvents[date]!).toList();

    // Show all masterclass instances (locations/dates) as returned by the filtered list
    // Removing the title-based de-duplication so users see every available session
    if (masterclasses.isNotEmpty) {
      final state = widget.dataProvider.stateNotifier.value;
      final hasLocationFilters = state.selectedCountry != null ||
          state.selectedCity != null ||
          state.selectedVenue != null;

      if (hasLocationFilters) {
        print(
            'Showing ${masterclasses.length} unique masterclasses with location filters');
      } else {
        print(
            'Showing ${masterclasses.length} unique masterclasses (all locations)');
      }
    }

    if (masterclasses.isEmpty) {
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
        final w = constraints.maxWidth;
        final int crossAxisCount;
        final double childAspectRatio;
        if (w < 420) {
          crossAxisCount = 1;
          childAspectRatio =
              1.45; // single column — wider card, comfortable height
        } else if (w < 768) {
          crossAxisCount = 2;
          childAspectRatio = 0.68; // 2-col portrait cards
        } else if (w < 1200) {
          crossAxisCount = 3;
          childAspectRatio = 0.72;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 0.72;
        }

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16), // Increased padding
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16, // Increased spacing
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: masterclasses.length,
            itemBuilder: (context, index) {
              final masterclass = masterclasses[index];
              // Get certification image with fallback
              final certImageUrl =
                  widget.dataProvider.getCertificationImage(masterclass);

              // Debug logging
              if (certImageUrl == null) {
                print('No image found for masterclass: ${masterclass.title}');
              } else {
                print('Found image for ${masterclass.title}: $certImageUrl');
              }

              return _buildCompactMasterclassCard(
                masterclass: masterclass,
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
    required String? certificationImageUrl,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    String formatDate(DateTime? date) {
      if (date == null) return '';
      final month = _getFullMonthName(date);
      return '$month ${date.day}, ${date.year}';
    }

    // Determine type-based colors for consistency
    final isTechnical = masterclass.streamType?.toLowerCase() == 'technical';
    final streamColor =
        isTechnical ? colorScheme.primary : colorScheme.secondary;

    final card = _MasterclassHoverCard(
      masterclass: masterclass,
      streamColor: streamColor,
      certificationImageUrl: certificationImageUrl,
      theme: theme,
      colorScheme: colorScheme,
      onTap: () => widget.onMasterclassTap(masterclass),
      onEnroll: () => widget.onEnrollTap(masterclass),
    );

    // Drag-and-drop only on web/desktop — on mobile it conflicts with taps
    if (!kIsWeb) return card;

    return LongPressDraggable<Masterclass>(
      data: masterclass,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 200,
          height: 250,
          child: Opacity(
            opacity: 0.8,
            child: _MasterclassHoverCard(
              masterclass: masterclass,
              streamColor: streamColor,
              certificationImageUrl: certificationImageUrl,
              theme: theme,
              colorScheme: colorScheme,
              onTap: () {},
              onEnroll: () {},
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}

class _MasterclassHoverCard extends StatefulWidget {
  final Masterclass masterclass;
  final Color streamColor;
  final String? certificationImageUrl;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onEnroll;

  const _MasterclassHoverCard({
    required this.masterclass,
    required this.streamColor,
    this.certificationImageUrl,
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

  /// Extracts the original AICERTS URL from a proxy URL, or returns as-is.
  /// Proxy format: /api/v1/.../proxy/image/?url=ENCODED_ORIGINAL&format=svg
  String _extractOriginalUrl(String url) {
    if (url.contains('proxy/image') && url.contains('url=')) {
      final parts = url.split('url=');
      if (parts.length > 1) {
        return Uri.decodeComponent(parts[1].split('&').first);
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final masterclass = widget.masterclass;
    final colorScheme = widget.colorScheme;
    final theme = widget.theme;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = true);
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHovered = false);
          });
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow
                    .withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
            border: Border.all(
              color:
                  widget.streamColor.withValues(alpha: _isHovered ? 0.3 : 0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === TITLE AT THE TOP ===
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: SizedBox(
                    height: 38,
                    child: Text(
                      masterclass.title ?? 'Seminar',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.1,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // === IMAGE AREA (Main Focus) ===
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _getLocalMasterclassImage(masterclass.title) !=
                                null
                            ? Image.asset(
                                _getLocalMasterclassImage(masterclass.title)!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppTheme.hosiMidnight,
                                child: Center(
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 48,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                      ).animate(target: _isHovered ? 1 : 0).scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                          ),
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.hosiMidnight.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // === CERTIFICATION BADGE OVERLAY ===
                      if (widget.certificationImageUrl != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 50,
                            height: 50,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: AuthenticatedSvgImage(
                                originalUrl: _extractOriginalUrl(
                                    widget.certificationImageUrl!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ).animate().scale(
                              duration: 400.ms, curve: Curves.easeOutBack),
                        ),

                      if (masterclass.streamType != null)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.streamColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              masterclass.streamType!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // === DETAILS & BUTTON AT THE BOTTOM ===
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (masterclass.startDate != null)
                                  _CompactDetail(
                                    icon: Icons.calendar_today_rounded,
                                    label:
                                        '${masterclass.startDate!.day} ${MasterclassCalendarState.months[masterclass.startDate!.month - 1]} ${masterclass.startDate!.year}',
                                    colorScheme: colorScheme,
                                  ),
                                if (masterclass.city != null ||
                                    masterclass.venue != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: _CompactDetail(
                                      icon: Icons.location_on_rounded,
                                      label: masterclass.city ??
                                          masterclass.venue ??
                                          '',
                                      colorScheme: colorScheme,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            masterclass.formattedPrice,
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Enroll Button — independent GestureDetector so it
                      // never conflicts with the card-level tap
                      SizedBox(
                        width: double.infinity,
                        height: 48, // min touch target
                        child: ElevatedButton(
                          onPressed: widget.onEnroll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'ENROLL NOW',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.2,
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
        ),
      ),
    );
  }
}

class _CompactDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _CompactDetail({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 10, color: colorScheme.onSurface),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
        height: 36, // Increased height
        decoration: BoxDecoration(
          color: isActive ? quarterColor : quarterColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6), // Slightly larger radius
          border: Border.all(
            color: quarterColor.withValues(alpha: isActive ? 1 : 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            'Q${quarter + 1} \'${year.toString().substring(2)}',
            style: theme.textTheme.bodyMedium!.copyWith(
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12, // Consistent font size
              height: 1.0, // Tight line height to prevent wrapping
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

String? _getLocalMasterclassImage(String? title) {
  if (title == null) return null;

  final titleLower = title.toLowerCase();

  // Mapping logic to use all 10 images (r1-r10)

  // AI / Machine Learning Foundations (r1)
  if (titleLower.contains('foundation') ||
      titleLower.contains('fundamental') ||
      titleLower.contains('intro')) {
    return 'assets/images/masterclasses/r1_ai.jpg';
  }

  // Cloud & Infrastructure (r2)
  if (titleLower.contains('cloud computing') ||
      titleLower.contains('ai & cloud')) {
    return 'assets/images/masterclasses/r2_ai.jpg';
  }

  // Advanced AI Models (r3)
  if (titleLower.contains('deep learning') ||
      titleLower.contains('neural network') ||
      titleLower.contains('generative ai')) {
    return 'assets/images/masterclasses/r3_ai.jpg';
  }

  // Specialized Logic (r4)
  if (titleLower.contains('nlp') ||
      titleLower.contains('natural language') ||
      titleLower.contains('computer vision')) {
    return 'assets/images/masterclasses/r4_ai.jpg';
  }

  // Business Strategy (r5)
  if (titleLower.contains('strategy') ||
      titleLower.contains('leadership') ||
      titleLower.contains('management')) {
    return 'assets/images/masterclasses/r5.jpg';
  }

  // Programming (r6)
  if (titleLower.contains('python') ||
      titleLower.contains('coding') ||
      titleLower.contains('developer')) {
    return 'assets/images/masterclasses/r6.png';
  }

  // Data Science (r7)
  if (titleLower.contains('data science') || titleLower.contains('analytics')) {
    return 'assets/images/masterclasses/r7.jpg';
  }

  // Industry Specific Finance/Health (r8)
  if (titleLower.contains('finance') || titleLower.contains('healthcare')) {
    return 'assets/images/masterclasses/r8.jpg';
  }

  // Engineering (r9)
  if (titleLower.contains('engineering') ||
      titleLower.contains('manufacturing')) {
    return 'assets/images/masterclasses/r9.jpg';
  }

  // Generic Professional (r10)
  if (titleLower.contains('professional') ||
      titleLower.contains('development')) {
    return 'assets/images/masterclasses/r10.png';
  }

  // Catch-all mapping based on string hash for diversity if no keywords match
  final hash = title.hashCode.abs() % 10;
  final images = [
    'assets/images/masterclasses/r1_ai.jpg',
    'assets/images/masterclasses/r2_ai.jpg',
    'assets/images/masterclasses/r3_ai.jpg',
    'assets/images/masterclasses/r4_ai.jpg',
    'assets/images/masterclasses/r5.jpg',
    'assets/images/masterclasses/r6.png',
    'assets/images/masterclasses/r7.jpg',
    'assets/images/masterclasses/r8.jpg',
    'assets/images/masterclasses/r9.jpg',
    'assets/images/masterclasses/r10.png',
  ];
  return images[hash];
}
