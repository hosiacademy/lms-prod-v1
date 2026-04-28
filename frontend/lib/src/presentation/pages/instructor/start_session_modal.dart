// lib/src/presentation/pages/instructor/start_session_modal.dart
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import 'bbb_session_viewer.dart';

/// Comprehensive modal for instructors to create and schedule BBB live sessions.
/// Supports Learnerships (with phase selection), Masterclasses, and AICERTS Courses.
/// Two submit modes: Schedule for Later, or Schedule & Go Live Now.
class StartSessionModal extends StatefulWidget {
  const StartSessionModal({super.key});

  @override
  State<StartSessionModal> createState() => _StartSessionModalState();
}

class _StartSessionModalState extends State<StartSessionModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _welcomeController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '100');

  // Course type: 'learnership', 'masterclass', 'course'
  String _courseType = 'learnership';

  // Options loaded from API
  List<Map<String, dynamic>> _learnerships = [];
  List<Map<String, dynamic>> _masterclasses = [];
  List<Map<String, dynamic>> _courses = [];
  bool _loadingOptions = true;
  String? _optionsError;

  // Selected items
  Map<String, dynamic>? _selectedLearnership;
  Map<String, dynamic>? _selectedPhase;
  Map<String, dynamic>? _selectedMasterclass;
  Map<String, dynamic>? _selectedCourse;

  // Schedule
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  // Settings
  bool _recordSession = true;
  bool _autoStartRecording = true;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCourseOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _welcomeController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseOptions() async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });
    try {
      final response = await ApiClient.get('/api/v1/bbb/sessions/course_options/');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _learnerships = List<Map<String, dynamic>>.from(data['learnerships'] ?? []);
          _masterclasses = List<Map<String, dynamic>>.from(data['masterclasses'] ?? []);
          _courses = List<Map<String, dynamic>>.from(data['courses'] ?? []);
          _loadingOptions = false;
        });
      } else {
        setState(() {
          _optionsError = 'Could not load course options';
          _loadingOptions = false;
        });
      }
    } catch (e) {
      setState(() {
        _optionsError = 'Network error: $e';
        _loadingOptions = false;
      });
    }
  }

  void _onCourseTypeChanged(String type) {
    setState(() {
      _courseType = type;
      _selectedLearnership = null;
      _selectedPhase = null;
      _selectedMasterclass = null;
      _selectedCourse = null;
      _titleController.clear();
      _maxParticipantsController.text = '100';
    });
  }

  void _onLearnershipSelected(Map<String, dynamic>? prog) {
    setState(() {
      _selectedLearnership = prog;
      _selectedPhase = null;
      if (prog != null) {
        _titleController.text = prog['title'] ?? '';
        _maxParticipantsController.text =
            (prog['max_participants'] ?? 35).toString();
        final welcome = prog['role'] != null && prog['role'].toString().isNotEmpty
            ? 'Welcome to the ${prog['title']} — ${prog['role']} session!'
            : 'Welcome to ${prog['title']}!';
        _welcomeController.text = welcome;
      }
    });
  }

  void _onPhaseSelected(Map<String, dynamic>? phase) {
    setState(() {
      _selectedPhase = phase;
      if (phase != null && _selectedLearnership != null) {
        _titleController.text =
            '${_selectedLearnership!['title']} — ${phase['name']}';
        // Auto-set date from phase start_date if available
        if (phase['start_date'] != null) {
          try {
            final d = DateTime.parse(phase['start_date'] as String);
            _selectedDate = d;
          } catch (_) {}
        }
      }
    });
  }

  void _onMasterclassSelected(Map<String, dynamic>? mc) {
    setState(() {
      _selectedMasterclass = mc;
      if (mc != null) {
        _titleController.text = mc['title'] ?? '';
        _maxParticipantsController.text =
            (mc['max_participants'] ?? 35).toString();
        _welcomeController.text = 'Welcome to ${mc['title']}!';
        if (mc['start_date'] != null) {
          try {
            final d = DateTime.parse(mc['start_date'] as String);
            _selectedDate = d;
          } catch (_) {}
        }
      }
    });
  }

  void _onCourseSelected(Map<String, dynamic>? course) {
    setState(() {
      _selectedCourse = course;
      if (course != null) {
        _titleController.text = course['title'] ?? '';
        _welcomeController.text = 'Welcome to the ${course['title']} live session!';
      }
    });
  }

  int get _selectedCourseId {
    if (_courseType == 'learnership') return _selectedLearnership?['id'] ?? 0;
    if (_courseType == 'masterclass') return _selectedMasterclass?['id'] ?? 0;
    return _selectedCourse?['id'] ?? 0;
  }

  bool get _hasSelectedCourse {
    if (_courseType == 'learnership') return _selectedLearnership != null;
    if (_courseType == 'masterclass') return _selectedMasterclass != null;
    return _selectedCourse != null;
  }

  Map<String, dynamic> get _cohortInfo {
    final Map<String, dynamic> info = {};
    if (_courseType == 'learnership' && _selectedLearnership != null) {
      final prog = _selectedLearnership!;
      info['programme_title'] = prog['title'];
      info['nqf_level'] = prog['nqf_level'];
      info['delivery_mode'] = prog['delivery_mode'];
      info['location'] = prog['location'];
      info['city'] = prog['city'];
      info['country'] = prog['country'];
      info['duration_months'] = prog['duration_months'];
      info['specialization'] = prog['specialization'];
      info['is_funded'] = prog['is_funded'];
      info['stipend_amount'] = prog['stipend_amount'];
      if (_selectedPhase != null) {
        info['phase_name'] = _selectedPhase!['name'];
        info['phase_order'] = _selectedPhase!['order'];
        info['phase_duration_weeks'] = _selectedPhase!['duration_weeks'];
      }
    } else if (_courseType == 'masterclass' && _selectedMasterclass != null) {
      final mc = _selectedMasterclass!;
      info['focus_area'] = mc['focus_area'];
      info['tier'] = mc['tier'];
      info['stream_type'] = mc['stream_type'];
      info['city'] = mc['city'];
      info['country'] = mc['country_name'];
    } else if (_courseType == 'course' && _selectedCourse != null) {
      info['category_name'] = _selectedCourse!['category_name'];
    }
    return info;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  DateTime get _scheduledStart => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

  DateTime get _scheduledEnd => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

  int get _durationMinutes {
    final diff = _scheduledEnd.difference(_scheduledStart);
    return diff.inMinutes > 0 ? diff.inMinutes : 90;
  }

  Map<String, dynamic> get _sessionPayload => {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'scheduled_start': _scheduledStart.toIso8601String(),
        'scheduled_end': _scheduledEnd.toIso8601String(),
        'record': _recordSession,
        'auto_start_recording': _autoStartRecording,
        'allow_start_stop_recording': true,
        'max_participants': int.tryParse(_maxParticipantsController.text) ?? 100,
        'welcome_message': _welcomeController.text.trim(),
        'course_id': _selectedCourseId,
        'course_type': _courseType,
        'phase_id': _selectedPhase?['id'],
        'cohort_info': _cohortInfo,
      };

  Future<void> _submitSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasSelectedCourse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course or programme')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await ApiClient.post('/api/v1/bbb/sessions/', data: _sessionPayload);
      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session scheduled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(response.data?['detail'] ?? 'Error ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitStartNow() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasSelectedCourse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course or programme')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        ..._sessionPayload,
        'duration_minutes': _durationMinutes,
      };
      final response = await ApiClient.post('/api/v1/bbb/sessions/start_now/', data: payload);
      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final sessionId = data['id']?.toString() ?? '';
          final joinUrl = data['join_url'] as String?;
          Navigator.pop(context, true);
          // Open the BBB session viewer immediately
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Dialog.fullscreen(
                child: BBBSessionViewer(
                  sessionId: sessionId,
                  sessionTitle: _titleController.text.trim(),
                  joinUrl: joinUrl,
                ),
              ),
            );
          }
        } else {
          throw Exception(response.data?['error'] ?? 'Error ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start session: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSmall = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 32,
        vertical: isSmall ? 20 : 32,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(theme, colors),
            Expanded(
              child: _loadingOptions
                  ? const Center(child: CircularProgressIndicator())
                  : _optionsError != null
                      ? _buildErrorState(colors)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCourseTypeSelector(theme, colors),
                                const SizedBox(height: 20),
                                _buildCourseSelector(theme, colors),
                                const SizedBox(height: 20),
                                if (_hasSelectedCourse) ...[
                                  _buildCourseMetadataCard(theme, colors),
                                  const SizedBox(height: 20),
                                ],
                                _buildSessionDetails(theme, colors),
                                const SizedBox(height: 20),
                                _buildScheduleSection(theme, colors, isSmall),
                                const SizedBox(height: 20),
                                _buildSettingsSection(theme, colors),
                              ],
                            ),
                          ),
                        ),
            ),
            _buildFooter(theme, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF172E3D),
            const Color(0xFF172E3D).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.video_call, size: 26, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Live Session',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Powered by BigBlueButton',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 56, color: colors.error),
          const SizedBox(height: 16),
          Text(_optionsError!, style: TextStyle(color: colors.error)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadCourseOptions,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseTypeSelector(ThemeData theme, ColorScheme colors) {
    final types = [
      ('learnership', Icons.workspace_premium, 'Learnership'),
      ('masterclass', Icons.star_rate, 'Masterclass'),
      ('course', Icons.school, 'AICERTS Course'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Programme Type',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: types.map((t) {
            final selected = _courseType == t.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _onCourseTypeChanged(t.$1),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary.withValues(alpha: 0.12)
                          : colors.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? colors.primary : colors.outline.withValues(alpha: 0.4),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(t.$2,
                            size: 22,
                            color: selected ? colors.primary : colors.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(height: 4),
                        Text(
                          t.$3,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: selected ? colors.primary : colors.onSurface.withValues(alpha: 0.7),
                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCourseSelector(ThemeData theme, ColorScheme colors) {
    if (_courseType == 'learnership') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown<Map<String, dynamic>>(
            label: 'Learnership Programme *',
            hint: 'Select a programme',
            value: _selectedLearnership,
            items: _learnerships,
            itemLabel: (p) => p['title'] ?? '',
            onChanged: _onLearnershipSelected,
            theme: theme,
            colors: colors,
          ),
          if (_selectedLearnership != null) ...[
            const SizedBox(height: 14),
            _buildDropdown<Map<String, dynamic>>(
              label: 'Phase',
              hint: 'Select phase (optional)',
              value: _selectedPhase,
              items: List<Map<String, dynamic>>.from(
                  _selectedLearnership!['phases'] as List? ?? []),
              itemLabel: (p) {
                final weeks = p['duration_weeks'] != null ? ' (${p['duration_weeks']}w)' : '';
                return 'Phase ${p['order']}: ${p['name']}$weeks';
              },
              onChanged: _onPhaseSelected,
              theme: theme,
              colors: colors,
            ),
          ],
        ],
      );
    }

    if (_courseType == 'masterclass') {
      return _buildDropdown<Map<String, dynamic>>(
        label: 'Masterclass *',
        hint: 'Select a masterclass',
        value: _selectedMasterclass,
        items: _masterclasses,
        itemLabel: (mc) {
          final loc = mc['city']?.isNotEmpty == true ? ' — ${mc['city']}' : '';
          return '${mc['title']}$loc';
        },
        onChanged: _onMasterclassSelected,
        theme: theme,
        colors: colors,
      );
    }

    // course
    return _buildDropdown<Map<String, dynamic>>(
      label: 'AICERTS Course *',
      hint: 'Select a course',
      value: _selectedCourse,
      items: _courses,
      itemLabel: (c) => c['title'] ?? '',
      onChanged: _onCourseSelected,
      theme: theme,
      colors: colors,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(10),
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(hint, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              borderRadius: BorderRadius.circular(10),
              items: items.map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
                  )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseMetadataCard(ThemeData theme, ColorScheme colors) {
    final chips = <_InfoChip>[];

    if (_courseType == 'learnership' && _selectedLearnership != null) {
      final p = _selectedLearnership!;
      if (p['nqf_level']?.toString().isNotEmpty == true)
        chips.add(_InfoChip(Icons.grade, 'NQF ${p['nqf_level']}'));
      if (p['duration_months'] != null && p['duration_months'] != 0)
        chips.add(_InfoChip(Icons.calendar_month, '${p['duration_months']} months'));
      if (p['delivery_mode']?.isNotEmpty == true)
        chips.add(_InfoChip(Icons.devices, (p['delivery_mode'] as String).toUpperCase()));
      if (p['city']?.isNotEmpty == true)
        chips.add(_InfoChip(Icons.location_on, p['city']));
      if (p['is_funded'] == true)
        chips.add(_InfoChip(Icons.attach_money, 'Funded'));
      if (p['specialization']?.isNotEmpty == true)
        chips.add(_InfoChip(Icons.hub, p['specialization']));
      if (_selectedPhase != null) {
        final ph = _selectedPhase!;
        if (ph['duration_weeks'] != null)
          chips.add(_InfoChip(Icons.timelapse, '${ph['duration_weeks']} weeks'));
        if (ph['description']?.isNotEmpty == true)
          chips.add(_InfoChip(Icons.info_outline, ph['description'], wide: true));
      }
    } else if (_courseType == 'masterclass' && _selectedMasterclass != null) {
      final mc = _selectedMasterclass!;
      if (mc['focus_area']?.isNotEmpty == true)
        chips.add(_InfoChip(Icons.hub, mc['focus_area']));
      if (mc['tier']?.isNotEmpty == true)
        chips.add(_InfoChip(Icons.star, (mc['tier'] as String).toUpperCase()));
      if (mc['city']?.isNotEmpty == true)
        chips.add(_InfoChip(Icons.location_on, mc['city']));
      if (mc['country_name']?.isNotEmpty == true)
        chips.add(_InfoChip(Icons.flag, mc['country_name']));
    } else if (_courseType == 'course' && _selectedCourse != null) {
      final c = _selectedCourse!;
      if (c['category_name']?.isNotEmpty == true)
        chips.add(_InfoChip(Icons.category, c['category_name']));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Text('Programme Details',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.primary, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: chips.map((c) => _buildInfoChip(c, colors)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(_InfoChip chip, ColorScheme colors) {
    return Container(
      constraints: chip.wide ? const BoxConstraints(maxWidth: double.infinity) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: chip.wide ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(chip.icon, size: 13, color: colors.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              chip.label,
              style: TextStyle(fontSize: 12, color: colors.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetails(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Session Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration(
              colors, 'Session Title *', 'e.g. Phase 1 Kickoff — Data Science', Icons.title),
          validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: _inputDecoration(
              colors, 'Agenda / Description', 'What will be covered in this session?', Icons.notes),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _welcomeController,
          decoration: _inputDecoration(
              colors, 'Welcome Message', 'Shown to participants when they join', Icons.waving_hand),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maxParticipantsController,
          decoration: _inputDecoration(colors, 'Max Participants', '100', Icons.group),
          keyboardType: TextInputType.number,
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 1) return 'Enter a valid number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildScheduleSection(ThemeData theme, ColorScheme colors, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Schedule',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        // Date row
        _buildTappableField(
          icon: Icons.calendar_today,
          label: 'Date',
          value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          onTap: _selectDate,
          colors: colors,
          theme: theme,
        ),
        const SizedBox(height: 10),
        // Time row
        isSmall
            ? Column(children: [
                _buildTappableField(
                  icon: Icons.access_time,
                  label: 'Start',
                  value: _startTime.format(context),
                  onTap: _selectStartTime,
                  colors: colors,
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _buildTappableField(
                  icon: Icons.access_time_filled,
                  label: 'End',
                  value: _endTime.format(context),
                  onTap: _selectEndTime,
                  colors: colors,
                  theme: theme,
                ),
              ])
            : Row(
                children: [
                  Expanded(
                    child: _buildTappableField(
                      icon: Icons.access_time,
                      label: 'Start Time',
                      value: _startTime.format(context),
                      onTap: _selectStartTime,
                      colors: colors,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTappableField(
                      icon: Icons.access_time_filled,
                      label: 'End Time',
                      value: _endTime.format(context),
                      onTap: _selectEndTime,
                      colors: colors,
                      theme: theme,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 8),
        // Duration display
        if (_durationMinutes > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Duration: ${_durationMinutes ~/ 60}h ${_durationMinutes % 60}min',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _buildToggleRow(
          icon: Icons.fiber_manual_record,
          iconColor: _recordSession ? Colors.red : colors.onSurface.withValues(alpha: 0.4),
          title: 'Record Session',
          subtitle: 'Session recording will be available for review',
          value: _recordSession,
          onChanged: (v) => setState(() {
            _recordSession = v;
            if (!v) _autoStartRecording = false;
          }),
          colors: colors,
          theme: theme,
        ),
        if (_recordSession) ...[
          const SizedBox(height: 8),
          _buildToggleRow(
            icon: Icons.play_circle,
            iconColor: _autoStartRecording ? Colors.green : colors.onSurface.withValues(alpha: 0.4),
            title: 'Auto-Start Recording',
            subtitle: 'Recording starts automatically when session begins',
            value: _autoStartRecording,
            onChanged: (v) => setState(() => _autoStartRecording = v),
            colors: colors,
            theme: theme,
          ),
        ],
      ],
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colors,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
        color: colors.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
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
  }

  Widget _buildTappableField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required ColorScheme colors,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
          color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.primary),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      ColorScheme colors, String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.25),
        border: Border(top: BorderSide(color: colors.outline.withValues(alpha: 0.2))),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _submitSchedule,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.schedule, size: 18),
              label: const Text('Schedule'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: colors.primary),
                foregroundColor: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitStartNow,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow, size: 20),
              label: const Text('Go Live Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip {
  final IconData icon;
  final String label;
  final bool wide;
  const _InfoChip(this.icon, this.label, {this.wide = false});
}
