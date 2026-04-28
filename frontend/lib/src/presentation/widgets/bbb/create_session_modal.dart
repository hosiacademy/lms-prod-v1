import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/bbb_service.dart';

/// Modal for instructors to create new BBB sessions for their courses
class CreateSessionModal extends StatefulWidget {
  final Function()? onSessionCreated;

  const CreateSessionModal({Key? key, this.onSessionCreated}) : super(key: key);

  @override
  State<CreateSessionModal> createState() => _CreateSessionModalState();
}

class _CreateSessionModalState extends State<CreateSessionModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  CourseOption? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  bool _recordSession = true;
  bool _autoStartRecording = true;
  bool _sendInvites = true;
  int _maxParticipants = 100;

  List<CourseOption> _courses = [];
  bool _isLoadingCourses = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final options = await ApiClient.getBBBCourseOptions();
      setState(() {
        _courses = options;
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load courses: $e';
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course')),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    try {
      final session = await ApiClient.createBBBSession(
        courseId: _selectedCourse!.id,
        courseType: _selectedCourse!.type,
        title: _titleController.text,
        description: _descriptionController.text,
        scheduledStart: startDateTime.toIso8601String(),
        scheduledEnd: endDateTime.toIso8601String(),
        record: _recordSession,
        autoStartRecording: _autoStartRecording,
        maxParticipants: _maxParticipants,
      );

      // Auto-invite students if requested
      if (_sendInvites && _selectedCourse!.studentCount > 0) {
        await ApiClient.autoInviteStudentsToSession(session['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session "${_titleController.text}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSessionCreated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(theme),

            // Content
            Expanded(
              child: _isLoadingCourses
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _buildForm(theme),
            ),

            // Actions
            _buildActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.video_call, color: theme.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Live Session',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Schedule a BBB session for your students',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Course Selection
            _buildCourseDropdown(theme),

            const SizedBox(height: 20),

            // Session Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Session Title',
                hintText: 'e.g., Week 1: Introduction to AI',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
            ),

            const SizedBox(height: 20),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Session agenda or description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(theme),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(theme, true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(theme, false),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Settings
            _buildSettings(theme),

            const SizedBox(height: 20),

            // Student Info
            if (_selectedCourse != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedCourse!.studentCount} students enrolled',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    if (_sendInvites) ...[
                      const SizedBox(height: 8),
                      Text(
                        '✓ All enrolled students will receive email invitations',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDropdown(ThemeData theme) {
    // Flatten all course options
    final allCourses = <CourseOption>[];
    for (final learnership in _courses.whereType<LearnershipOption>()) {
      allCourses.add(learnership);
    }
    for (final masterclass in _courses.whereType<MasterclassOption>()) {
      allCourses.add(masterclass);
    }
    for (final course in _courses.whereType<AICertsOption>()) {
      allCourses.add(course);
    }

    return DropdownButtonFormField<CourseOption>(
      value: _selectedCourse,
      decoration: InputDecoration(
        labelText: 'Select Course',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: allCourses.map((course) {
        return DropdownMenuItem(
          value: course,
          child: Text(
            '${course.title} (${course.studentCount} students)',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCourse = value),
      validator: (v) => v == null ? 'Please select a course' : null,
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(ThemeData theme, bool isStart) {
    final time = isStart ? _startTime : _endTime;
    return InkWell(
      onTap: () => _selectTime(context, isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isStart ? 'Start Time' : 'End Time',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(time.format(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Settings',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _recordSession,
          onChanged: (v) => setState(() => _recordSession = v ?? true),
          title: const Text('Record this session'),
          subtitle: const Text('Recording will be available to students after the session'),
        ),
        if (_recordSession)
          CheckboxListTile(
            value: _autoStartRecording,
            onChanged: (v) => setState(() => _autoStartRecording = v ?? true),
            title: const Text('Auto-start recording'),
            subtitle: const Text('Recording starts automatically when session begins'),
          ),
        CheckboxListTile(
          value: _sendInvites,
          onChanged: (v) => setState(() => _sendInvites = v ?? true),
          title: const Text('Send invitations to enrolled students'),
          subtitle: const Text('Students will receive email with session link'),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _createSession,
            icon: const Icon(Icons.add),
            label: const Text('Create Session'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Course option models
abstract class CourseOption {
  final int id;
  final String title;
  final String type;
  final int studentCount;
  final List<Map<String, dynamic>> enrolledStudents;

  CourseOption({
    required this.id,
    required this.title,
    required this.type,
    required this.studentCount,
    required this.enrolledStudents,
  });
}

class LearnershipOption extends CourseOption {
  final List<Map<String, dynamic>> phases;

  LearnershipOption({
    required int id,
    required String title,
    required int studentCount,
    required this.phases,
    required List<Map<String, dynamic>> enrolledStudents,
  }) : super(id: id, title: title, type: 'learnership', studentCount: studentCount, enrolledStudents: enrolledStudents);

  factory LearnershipOption.fromJson(Map<String, dynamic> json) {
    return LearnershipOption(
      id: json['id'],
      title: json['title'],
      studentCount: json['student_count'] ?? 0,
      phases: json['phases'] ?? [],
      enrolledStudents: json['enrolled_students'] ?? [],
    );
  }
}

class MasterclassOption extends CourseOption {
  MasterclassOption({
    required int id,
    required String title,
    required int studentCount,
    required List<Map<String, dynamic>> enrolledStudents,
  }) : super(id: id, title: title, type: 'masterclass', studentCount: studentCount, enrolledStudents: enrolledStudents);

  factory MasterclassOption.fromJson(Map<String, dynamic> json) {
    return MasterclassOption(
      id: json['id'],
      title: json['title'],
      studentCount: json['student_count'] ?? 0,
      enrolledStudents: json['enrolled_students'] ?? [],
    );
  }
}

class AICertsOption extends CourseOption {
  AICertsOption({
    required int id,
    required String title,
    required int studentCount,
    required List<Map<String, dynamic>> enrolledStudents,
  }) : super(id: id, title: title, type: 'industry_training', studentCount: studentCount, enrolledStudents: enrolledStudents);

  factory AICertsOption.fromJson(Map<String, dynamic> json) {
    return AICertsOption(
      id: json['id'],
      title: json['title'],
      studentCount: json['student_count'] ?? 0,
      enrolledStudents: json['enrolled_students'] ?? [],
    );
  }
}
