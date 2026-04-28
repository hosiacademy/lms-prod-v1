import 'package:flutter/material.dart';
import 'package:frontend/src/core/theme/app_theme.dart';

/// Modal showing the detailed 3-day schedule and curriculum for the AI+ Finance™ Masterclass.
class AiMasterclassScheduleModal extends StatelessWidget {
  const AiMasterclassScheduleModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const AiMasterclassScheduleModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 36,
        vertical: isMobile ? 10 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.hosiPeach.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.hosiPeach.withValues(alpha: 0.10),
              blurRadius: 60,
              spreadRadius: 8,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, isMobile),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Masterclass Overview
                    _SectionLabel('Masterclass Overview'),
                    const SizedBox(height: 12),
                    _buildOverviewSection(colors),
                    const SizedBox(height: 28),

                    // Daily Schedule
                    _SectionLabel('Daily Schedule'),
                    const SizedBox(height: 12),
                    _buildDailySchedule(colors, theme),
                    const SizedBox(height: 28),

                    // Curriculum Outline
                    _SectionLabel('Curriculum Outline'),
                    const SizedBox(height: 12),
                    _buildCurriculumOutline(colors, theme),
                    const SizedBox(height: 24),

                    // Note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFFF5A623), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '*The curriculum above is for the AI+ Finance™ masterclass.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.60),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
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
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 14, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF091520), Color(0xFF162B45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Masterclass: Schedule & Curriculum',
                  style: TextStyle( 
                    fontSize: isMobile ? 16 : 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI+ Finance™',
                  style: TextStyle( 
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF5A623),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white54,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _OverviewRow(
            icon: Icons.calendar_month_rounded,
            label: 'Duration',
            value: '3 Days',
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 10),
          _OverviewRow(
            icon: Icons.verified_rounded,
            label: 'Certification',
            value: 'AI+ Finance™',
            color: const Color(0xFFF5A623),
          ),
          const SizedBox(height: 10),
          _OverviewRow(
            icon: Icons.groups_rounded,
            label: 'Target Audience',
            value: 'Finance Professionals, Executives, Analysts',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildDailySchedule(ColorScheme colors, ThemeData theme) {
    return Column(
      children: [
        _buildScheduleDay(
          colors,
          theme,
          'Day 1',
          [
            _ScheduleItem('08:30 - 09:00', 'Arrival & Registration / Platform Login'),
            _ScheduleItem('09:00 - 10:30', 'Module 1: Introduction to AI in the Financial Sector'),
            _ScheduleItem('10:30 - 11:00', 'Coffee Break'),
            _ScheduleItem('11:00 - 12:30', 'Module 2: AI for Fraud Detection and Risk Management'),
            _ScheduleItem('12:30 - 13:30', 'Lunch Break'),
            _ScheduleItem('13:30 - 15:00', 'Module 3: Automating Financial Reporting with AI & Practical Exercise'),
            _ScheduleItem('15:00 - 15:30', 'Coffee Break'),
            _ScheduleItem('15:30 - 17:00', 'Module 4: Case Study: Implementing an AI-Powered Auditing System & Group Discussion'),
          ],
        ),
        const SizedBox(height: 16),
        _buildScheduleDay(
          colors,
          theme,
          'Day 2',
          [
            _ScheduleItem('08:30 - 09:00', 'Arrival & Registration / Platform Login'),
            _ScheduleItem('09:00 - 10:30', 'Module 5: Algorithmic Trading and AI Models'),
            _ScheduleItem('10:30 - 11:00', 'Coffee Break'),
            _ScheduleItem('11:00 - 12:30', 'Module 6: AI-Powered Portfolio Management'),
            _ScheduleItem('12:30 - 13:30', 'Lunch Break'),
            _ScheduleItem('13:30 - 15:00', 'Module 7: Natural Language Processing (NLP) for Market Sentiment Analysis & Practical Exercise'),
            _ScheduleItem('15:00 - 15:30', 'Coffee Break'),
            _ScheduleItem('15:30 - 17:00', 'Module 8: Practical Lab: Building a Simple Predictive Model & Group Discussion'),
          ],
        ),
        const SizedBox(height: 16),
        _buildScheduleDay(
          colors,
          theme,
          'Day 3',
          [
            _ScheduleItem('08:30 - 09:00', 'Arrival & Registration / Platform Login'),
            _ScheduleItem('09:00 - 10:30', 'Module 9: Developing an AI Strategy for a Financial Institution'),
            _ScheduleItem('10:30 - 11:00', 'Coffee Break'),
            _ScheduleItem('11:00 - 12:30', 'Module 10: AI Ethics and Governance in Finance'),
            _ScheduleItem('12:30 - 13:30', 'Lunch Break'),
            _ScheduleItem('13:30 - 15:00', 'Module 11: The Future of FinTech and AI & Practical Exercise'),
            _ScheduleItem('15:00 - 15:30', 'Coffee Break'),
            _ScheduleItem('15:30 - 17:00', 'Module 12: Certification Exam Preparation & Final Q&A'),
            _ScheduleItem('17:00 - 18:00', 'Exam Writing'),
            _ScheduleItem('18:00 - 18:30', 'Present Certificates'),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleDay(
    ColorScheme colors,
    ThemeData theme,
    String dayTitle,
    List<_ScheduleItem> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              dayTitle,
              style: TextStyle( 
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Schedule items
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return _ScheduleRow(
              time: entry.value.time,
              activity: entry.value.activity,
              showDivider: !isLast,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCurriculumOutline(ColorScheme colors, ThemeData theme) {
    return Column(
      children: [
        _buildCurriculumDay(
          colors,
          theme,
          'Day 1',
          'AI in Financial Operations',
          [
            _CurriculumModule('Module 1', 'Introduction to AI in the Financial Sector'),
            _CurriculumModule('Module 2', 'AI for Fraud Detection and Risk Management'),
            _CurriculumModule('Module 3', 'Automating Financial Reporting with AI'),
            _CurriculumModule('Module 4', 'Case Study: Implementing an AI-Powered Auditing System'),
          ],
        ),
        const SizedBox(height: 16),
        _buildCurriculumDay(
          colors,
          theme,
          'Day 2',
          'AI for Investment and Analysis',
          [
            _CurriculumModule('Module 5', 'Algorithmic Trading and AI Models'),
            _CurriculumModule('Module 6', 'AI-Powered Portfolio Management'),
            _CurriculumModule('Module 7', 'Natural Language Processing (NLP) for Market Sentiment Analysis'),
            _CurriculumModule('Module 8', 'Practical Lab: Building a Simple Predictive Model'),
            _CurriculumModule('Module 9', 'Developing an AI Strategy for a Financial Institution'),
          ],
        ),
        const SizedBox(height: 16),
        _buildCurriculumDay(
          colors,
          theme,
          'Day 3',
          'AI Strategy and Certification',
          [
            _CurriculumModule('Module 10', 'AI Ethics and Governance in Finance'),
            _CurriculumModule('Module 11', 'The Future of FinTech and AI'),
            _CurriculumModule('Module 12', 'Certification Exam Preparation & Final Q&A'),
            _CurriculumModule('Exam', 'Exam Writing'),
            _CurriculumModule('Certificates', 'Present Certificates'),
          ],
        ),
      ],
    );
  }

  Widget _buildCurriculumDay(
    ColorScheme colors,
    ThemeData theme,
    String dayTitle,
    String dayTheme,
    List<_CurriculumModule> modules,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayTitle,
                  style: TextStyle( 
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayTheme,
                  style: TextStyle( 
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
          // Modules
          ...modules.asMap().entries.map((entry) {
            final isLast = entry.key == modules.length - 1;
            return _CurriculumRow(
              moduleNumber: entry.value.moduleNumber,
              title: entry.value.title,
              showDivider: !isLast,
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ── Helper Classes ────────────────────────────────────────────────────────────

class _ScheduleItem {
  final String time;
  final String activity;
  const _ScheduleItem(this.time, this.activity);
}

class _CurriculumModule {
  final String moduleNumber;
  final String title;
  const _CurriculumModule(this.moduleNumber, this.title);
}

class _OverviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _OverviewRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String time;
  final String activity;
  final bool showDivider;

  const _ScheduleRow({
    required this.time,
    required this.activity,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  time,
                  style: TextStyle( 
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF79150),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activity,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: Colors.white.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

class _CurriculumRow extends StatelessWidget {
  final String moduleNumber;
  final String title;
  final bool showDivider;

  const _CurriculumRow({
    required this.moduleNumber,
    required this.title,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                child: Text(
                  moduleNumber,
                  style: TextStyle( 
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF79150),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: Colors.white.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle( 
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFF5A623),
        letterSpacing: 1.2,
      ),
    );
  }
}
