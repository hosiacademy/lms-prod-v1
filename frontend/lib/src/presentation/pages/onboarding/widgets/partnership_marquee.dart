import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/src/core/theme/app_theme.dart';

/// Masterclass Schedule Marquee — real HOSI Academy calendar 2026/2027
/// Zimbabwe · Kenya · Zambia  |  April 2026 → March 2027
/// Each chip is clickable → enrollment
class PartnershipMarquee extends StatefulWidget {
  final VoidCallback? onEnrollTap;

  const PartnershipMarquee({
    super.key,
    this.onEnrollTap,
  });

  @override
  State<PartnershipMarquee> createState() => _PartnershipMarqueeState();
}

class _PartnershipMarqueeState extends State<PartnershipMarquee> {
  final ScrollController _controller = ScrollController();
  bool _isDisposed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) _startScroll();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startScroll() {
    if (_isDisposed || !mounted) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 600), () {
      if (!_isDisposed && mounted && _controller.hasClients) _animate();
    });
  }

  void _animate() {
    if (_isDisposed || !mounted || !_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    final cur = _controller.offset;
    final remaining = max - cur;
    if (remaining <= 0) {
      _controller.jumpTo(0);
      _animate();
      return;
    }
    _controller
        .animateTo(max,
            duration: Duration(milliseconds: (remaining * 26).toInt()),
            curve: Curves.linear)
        .then((_) {
      if (!_isDisposed && mounted && _controller.hasClients) {
        _controller.jumpTo(0);
        _animate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final sessions = _MasterclassData.all;

    return Container(
      width: double.infinity,
      height: 96,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.hosiMidnight : colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: isDark ? const Color(0xFF8C4928) : colorScheme.primary.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Fixed label - Calendar icon + "Masterclasses"
          GestureDetector(
            onTap: widget.onEnrollTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Tooltip(
                message: 'masterclasses schedule',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.hosiBrown : colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scrolling chips
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) => true,
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                // Duplicate 3× for seamless infinite loop
                itemCount: sessions.length * 3,
                itemBuilder: (context, i) {
                  return _SessionChip(
                    session: sessions[i % sessions.length],
                    onTap: widget.onEnrollTap,
                    theme: theme,
                    isDark: isDark,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _MasterclassSession {
  final String title;
  final String dates; // e.g. "6–8 Apr 2026"
  final String city;
  final String country;
  final String flag;
  final bool isProfessional; // false = Technical

  const _MasterclassSession({
    required this.title,
    required this.dates,
    required this.city,
    required this.country,
    required this.flag,
    required this.isProfessional,
  });
}

// ── Full 2026/2027 Calendar ───────────────────────────────────────────────────

class _MasterclassData {
  static const _zw = ('Harare', 'Zimbabwe', '🇿🇼');
  static const _ke = ('Nairobi', 'Kenya', '🇰🇪');
  static const _zm = ('Lusaka', 'Zambia', '🇿🇲');

  static _MasterclassSession _s(
    String title,
    String dates,
    (String, String, String) loc,
    bool isPro,
  ) =>
      _MasterclassSession(
        title: title,
        dates: dates,
        city: loc.$1,
        country: loc.$2,
        flag: loc.$3,
        isProfessional: isPro,
      );

  static final List<_MasterclassSession> all = [
    // ── April 2026 ──────────────────────────────────────────────────────────
    _s('AI+ Finance™',    '6–8 Apr 2026',   _zw, true),
    _s('AI+ Finance™',    '13–15 Apr 2026', _ke, true),
    _s('AI+ Developer™',  '13–17 Apr 2026', _zw, false),
    _s('AI+ Developer™',  '20–24 Apr 2026', _ke, false),
    _s('AI+ Finance™',    '20–22 Apr 2026', _zm, true),
    _s('AI+ Developer™',  '27 Apr–1 May',   _zm, false),
    // ── May 2026 ────────────────────────────────────────────────────────────
    _s('AI+ Human Resources™', '4–6 May 2026',   _zw, true),
    _s('AI+ Human Resources™', '11–13 May 2026', _ke, true),
    _s('AI+ Engineer™',        '11–15 May 2026', _zw, false),
    _s('AI+ Engineer™',        '18–22 May 2026', _ke, false),
    _s('AI+ Human Resources™', '18–20 May 2026', _zm, true),
    _s('AI+ Engineer™',        '25–29 May 2026', _zm, false),
    // ── June 2026 ───────────────────────────────────────────────────────────
    _s('AI+ Supply Chain™', '1–3 Jun 2026',   _zw, true),
    _s('AI+ Supply Chain™', '8–10 Jun 2026',  _ke, true),
    _s('AI+ Vibe Coder™',   '8–12 Jun 2026',  _zw, false),
    _s('AI+ Vibe Coder™',   '15–19 Jun 2026', _ke, false),
    _s('AI+ Supply Chain™', '15–17 Jun 2026', _zm, true),
    _s('AI+ Vibe Coder™',   '22–26 Jun 2026', _zm, false),
    // ── July 2026 ───────────────────────────────────────────────────────────
    _s('AI+ Project Manager™',                   '6–8 Jul 2026',   _zw, true),
    _s('AI+ Project Manager™',                   '13–15 Jul 2026', _ke, true),
    _s('AI+ Project Management Practitioner™',   '13–15 Jul 2026', _zw, true),
    _s('AI+ Project Management Practitioner™',   '20–22 Jul 2026', _ke, true),
    _s('AI+ Project Manager™',                   '20–22 Jul 2026', _zm, true),
    _s('AI+ Prompt Engineer Level 2™',           '20–24 Jul 2026', _zw, false),
    _s('AI+ Prompt Engineer Level 2™',           '27–31 Jul 2026', _ke, false),
    _s('AI+ Project Management Practitioner™',   '27–29 Jul 2026', _zm, true),
    _s('AI+ Prompt Engineer Level 2™',           '3–7 Aug 2026',   _zm, false),
    // ── August 2026 ─────────────────────────────────────────────────────────
    _s('AI+ Agile PM Fundamentals™',         '3–5 Aug 2026',   _zw, true),
    _s('AI+ Agile PM Fundamentals™',         '10–12 Aug 2026', _ke, true),
    _s('AI+ Program Director – Practitioner™','10–12 Aug 2026', _zw, true),
    _s('AI+ Program Director – Practitioner™','17–19 Aug 2026', _ke, true),
    _s('AI+ Agile PM Fundamentals™',         '17–19 Aug 2026', _zm, true),
    _s('AI+ Context Engineering™',           '17–21 Aug 2026', _zw, false),
    _s('AI+ Context Engineering™',           '24–28 Aug 2026', _ke, false),
    _s('AI+ Program Director – Practitioner™','24–26 Aug 2026', _zm, true),
    _s('AI+ Context Engineering™',           '31 Aug–4 Sep',   _zm, false),
    // ── September 2026 ──────────────────────────────────────────────────────
    _s('AI+ Legal™',              '7–9 Sep 2026',   _zw, true),
    _s('AI+ Legal™',              '14–16 Sep 2026', _ke, true),
    _s('AI+ Real Estate™',        '14–16 Sep 2026', _zw, true),
    _s('AI+ Real Estate™',        '21–23 Sep 2026', _ke, true),
    _s('AI+ Legal™',              '21–23 Sep 2026', _zm, true),
    _s('AI+ Security Level 1™',   '21–25 Sep 2026', _zw, false),
    _s('AI+ Security Level 1™',   '28 Sep–2 Oct',   _ke, false),
    _s('AI+ Real Estate™',        '28–30 Sep 2026', _zm, true),
    _s('AI+ Security Level 1™',   '5–9 Oct 2026',   _zm, false),
    // ── October 2026 ────────────────────────────────────────────────────────
    _s('AI+ Sales™',              '5–7 Oct 2026',   _zw, true),
    _s('AI+ Sales™',              '12–14 Oct 2026', _ke, true),
    _s('AI+ Marketing™',          '12–14 Oct 2026', _zw, true),
    _s('AI+ Marketing™',          '19–21 Oct 2026', _ke, true),
    _s('AI+ Sales™',              '19–21 Oct 2026', _zm, true),
    _s('AI+ Security Level 2™',   '19–23 Oct 2026', _zw, false),
    _s('AI+ Security Level 2™',   '26–30 Oct 2026', _ke, false),
    _s('AI+ Marketing™',          '26–28 Oct 2026', _zm, true),
    _s('AI+ Security Level 2™',   '2–6 Nov 2026',   _zm, false),
    // ── November 2026 ───────────────────────────────────────────────────────
    _s('AI+ Customer Service™',   '2–4 Nov 2026',   _zw, true),
    _s('AI+ Customer Service™',   '9–11 Nov 2026',  _ke, true),
    _s('AI+ Product Manager™',    '9–11 Nov 2026',  _zw, true),
    _s('AI+ Product Manager™',    '16–18 Nov 2026', _ke, true),
    _s('AI+ Customer Service™',   '16–18 Nov 2026', _zm, true),
    _s('AI+ Security Level 3™',   '16–20 Nov 2026', _zw, false),
    _s('AI+ Security Level 3™',   '23–27 Nov 2026', _ke, false),
    _s('AI+ Product Manager™',    '23–25 Nov 2026', _zm, true),
    _s('AI+ Security Level 3™',   '30 Nov–4 Dec',   _zm, false),
    // ── December 2026 ───────────────────────────────────────────────────────
    _s('AI+ Ethics™',             '7–9 Dec 2026',   _zw, true),
    _s('AI+ Ethics™',             '14–16 Dec 2026', _ke, true),
    _s('AI+ Writer™',             '14–16 Dec 2026', _zw, true),
    _s('AI+ Writer™',             '21–23 Dec 2026', _ke, true),
    _s('AI+ Ethics™',             '21–23 Dec 2026', _zm, true),
    _s('AI+ Security Compliance™','21–25 Dec 2026', _zw, false),
    _s('AI+ Security Compliance™','28 Dec–1 Jan',   _ke, false),
    _s('AI+ Writer™',             '28–30 Dec 2026', _zm, true),
    _s('AI+ Security Compliance™','4–8 Jan 2027',   _zm, false),
    // ── January 2027 ────────────────────────────────────────────────────────
    _s('AI+ Researcher™',         '4–6 Jan 2027',   _zw, true),
    _s('AI+ Researcher™',         '11–13 Jan 2027', _ke, true),
    _s('AI+ Chief AI Officer™',   '11–13 Jan 2027', _zw, true),
    _s('AI+ Chief AI Officer™',   '18–20 Jan 2027', _ke, true),
    _s('AI+ Researcher™',         '18–20 Jan 2027', _zm, true),
    _s('AI+ Network™',            '18–22 Jan 2027', _zw, false),
    _s('AI+ Network™',            '25–29 Jan 2027', _ke, false),
    _s('AI+ Chief AI Officer™',   '25–27 Jan 2027', _zm, true),
    _s('AI+ Network™',            '1–5 Feb 2027',   _zm, false),
    // ── February 2027 ───────────────────────────────────────────────────────
    _s('AI+ Government™',         '1–3 Feb 2027',   _zw, true),
    _s('AI+ Government™',         '8–10 Feb 2027',  _ke, true),
    _s('AI+ Policy Maker™',       '8–10 Feb 2027',  _zw, true),
    _s('AI+ Policy Maker™',       '15–17 Feb 2027', _ke, true),
    _s('AI+ Government™',         '15–17 Feb 2027', _zm, true),
    _s('AI+ Ethical Hacker™',     '15–19 Feb 2027', _zw, false),
    _s('AI+ Ethical Hacker™',     '22–26 Feb 2027', _ke, false),
    _s('AI+ Policy Maker™',       '22–24 Feb 2027', _zm, true),
    _s('AI+ Ethical Hacker™',     '1–5 Mar 2027',   _zm, false),
    // ── March 2027 ──────────────────────────────────────────────────────────
    _s('AI+ Mining™',                      '1–3 Mar 2027',   _zw, true),
    _s('AI+ Mining™',                      '8–10 Mar 2027',  _ke, true),
    _s('AI+ Telecommunications™',          '8–10 Mar 2027',  _zw, true),
    _s('AI+ Telecommunications™',          '15–17 Mar 2027', _ke, true),
    _s('AI+ Mining™',                      '15–17 Mar 2027', _zm, true),
    _s('Executive Intro to RSAIF',         '15–19 Mar 2027', _zw, false),
    _s('Executive Intro to RSAIF',         '22–26 Mar 2027', _ke, false),
    _s('AI+ Telecommunications™',         '22–24 Mar 2027', _zm, true),
    _s('Executive Intro to RSAIF',         '29 Mar–2 Apr',   _zm, false),
  ];
}

// ── Session chip widget ───────────────────────────────────────────────────────

class _SessionChip extends StatefulWidget {
  final _MasterclassSession session;
  final VoidCallback? onTap;
  final ThemeData theme;
  final bool isDark;

  const _SessionChip({
    required this.session,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_SessionChip> createState() => _SessionChipState();
}

class _SessionChipState extends State<_SessionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final colorScheme = widget.theme.colorScheme;
    return MouseRegion(
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.isDark ? AppTheme.hosiBrown.withValues(alpha: 0.9) : colorScheme.primary.withValues(alpha: 0.2))
                : (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? (widget.isDark ? AppTheme.hosiPeach : colorScheme.primary)
                  : (widget.isDark ? Colors.white.withValues(alpha: 0.1) : colorScheme.outline.withValues(alpha: 0.2)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppTheme.hosiPeach.withValues(alpha: 0.9) : colorScheme.primary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  s.dates,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              // Course title
              Text(
                s.title,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              // Type chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: s.isProfessional
                      ? (widget.isDark ? const Color(0xFF1B5E20).withValues(alpha: 0.7) : Colors.green.withValues(alpha: 0.2))
                      : (widget.isDark ? const Color(0xFF0D47A1).withValues(alpha: 0.7) : Colors.blue.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.isProfessional ? 'PRO' : 'TECH',
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : colorScheme.onSurface,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Flag + city
              Text(
                '${s.flag} ${s.city}',
                style: TextStyle(
                  color: widget.isDark ? Colors.white.withValues(alpha: 0.6) : colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              // Arrow
              Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: _hovered 
                    ? (widget.isDark ? Colors.white : colorScheme.primary)
                    : (widget.isDark ? AppTheme.hosiPeach : colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
