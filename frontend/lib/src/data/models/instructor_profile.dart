/// Instructor Profile model - represents facilitator/instructor data from backend
class InstructorProfile {
  final int id;
  final String instructorId;
  final String name;
  final String email;
  final String? department;
  final String? specialization;
  final String? instructorType;
  final bool isAvailable;
  final String? avatarUrl;

  // Performance metrics
  final double overallRating;
  final String? performanceBand;
  final int totalCoursesTaught;
  final double averageStudentRating;
  final double completionRate;

  // Availability
  final int maxCourses;
  final int currentCourseCount;
  final double utilizationRate;

  // HR Admin Assignment Fields
  final int? hrAdminId;
  final String? hrAdminCode;
  final String? hrAdminName;
  final DateTime? assignmentDate;
  final String? assignmentType; // 'country_based', 'specialization', 'performance', 'manual', 'auto'
  final int? assignmentCountryId;
  final String? assignmentCountryName;
  final String? assignmentNotes;

  InstructorProfile({
    required this.id,
    required this.instructorId,
    required this.name,
    required this.email,
    this.department,
    this.specialization,
    this.instructorType,
    required this.isAvailable,
    this.avatarUrl,
    this.overallRating = 0.0,
    this.performanceBand,
    this.totalCoursesTaught = 0,
    this.averageStudentRating = 0.0,
    this.completionRate = 0.0,
    this.maxCourses = 0,
    this.currentCourseCount = 0,
    this.utilizationRate = 0.0,
    this.hrAdminId,
    this.hrAdminCode,
    this.hrAdminName,
    this.assignmentDate,
    this.assignmentType,
    this.assignmentCountryId,
    this.assignmentCountryName,
    this.assignmentNotes,
  });

  factory InstructorProfile.fromJson(Map<String, dynamic> json) {
    return InstructorProfile(
      id: json['id'] ?? 0,
      instructorId: json['instructor_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      department: json['department'],
      specialization: json['specialization'],
      instructorType: json['instructor_type'],
      isAvailable: json['is_available'] ?? false,
      avatarUrl: json['avatar_url'],
      overallRating: _parseDouble(json['overall_rating']),
      performanceBand: json['performance_band'],
      totalCoursesTaught: json['total_courses_taught'] ?? 0,
      averageStudentRating: _parseDouble(json['average_student_rating']),
      completionRate: _parseDouble(json['completion_rate']),
      maxCourses: json['max_courses'] ?? 0,
      currentCourseCount: json['current_course_count'] ?? 0,
      utilizationRate: _parseDouble(json['utilization_rate']),
      hrAdminId: json['hr_admin_id'],
      hrAdminCode: json['hr_admin_code'],
      hrAdminName: json['hr_admin_name'],
      assignmentDate: json['assignment_date'] != null ? DateTime.tryParse(json['assignment_date']) : null,
      assignmentType: json['assignment_type'],
      assignmentCountryId: json['assignment_country_id'],
      assignmentCountryName: json['assignment_country_name'],
      assignmentNotes: json['assignment_notes'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instructor_id': instructorId,
      'name': name,
      'email': email,
      'department': department,
      'specialization': specialization,
      'instructor_type': instructorType,
      'is_available': isAvailable,
      'avatar_url': avatarUrl,
      'overall_rating': overallRating,
      'performance_band': performanceBand,
      'total_courses_taught': totalCoursesTaught,
      'average_student_rating': averageStudentRating,
      'completion_rate': completionRate,
      'max_courses': maxCourses,
      'current_course_count': currentCourseCount,
      'utilization_rate': utilizationRate,
      'hr_admin_id': hrAdminId,
      'hr_admin_code': hrAdminCode,
      'hr_admin_name': hrAdminName,
      'assignment_date': assignmentDate?.toIso8601String(),
      'assignment_type': assignmentType,
      'assignment_country_id': assignmentCountryId,
      'assignment_country_name': assignmentCountryName,
      'assignment_notes': assignmentNotes,
    };
  }

  bool get hasHrAdminAssignment => hrAdminId != null;
  String get hrAdminDisplayText => hrAdminName ?? hrAdminCode ?? 'Unassigned';
}

/// Instructor Course - represents a course assigned to an instructor
class InstructorCourse {
  final int id;
  final String title;
  final String? slug;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int enrolledCount;
  final String? specialization;
  final String? category;
  final String? nqfLevel;
  final int? durationMonths;
  final String? deliveryMode;
  final int sessionCount;
  final double averageAttendance;
  final double completionRate;
  final String? type;

  InstructorCourse({
    required this.id,
    required this.title,
    this.slug,
    required this.status,
    this.startDate,
    this.endDate,
    this.enrolledCount = 0,
    this.specialization,
    this.category,
    this.nqfLevel,
    this.durationMonths,
    this.deliveryMode,
    this.sessionCount = 0,
    this.averageAttendance = 0.0,
    this.completionRate = 0.0,
    this.type,
  });

  factory InstructorCourse.fromJson(Map<String, dynamic> json) {
    return InstructorCourse(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'],
      status: json['status'] ?? 'assigned',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      enrolledCount: json['enrolled_count'] ?? 0,
      specialization: json['specialization'],
      category: json['category'],
      nqfLevel: json['nqf_level'],
      durationMonths: json['duration_months'],
      deliveryMode: json['delivery_mode'],
      sessionCount: json['session_count'] ?? 0,
      averageAttendance: _parseDouble(json['average_attendance']),
      completionRate: _parseDouble(json['completion_rate']),
      type: json['type'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'enrolled_count': enrolledCount,
      'specialization': specialization,
      'category': category,
      'nqf_level': nqfLevel,
      'duration_months': durationMonths,
      'delivery_mode': deliveryMode,
      'session_count': sessionCount,
      'average_attendance': averageAttendance,
      'completion_rate': completionRate,
      'type': type,
    };
  }
}

/// Programme enrollment for a student
class StudentProgramme {
  final int id;
  final String title;
  final String? category;
  final String status;
  final String? enrollmentDate;

  StudentProgramme({
    required this.id,
    required this.title,
    this.category,
    required this.status,
    this.enrollmentDate,
  });

  factory StudentProgramme.fromJson(Map<String, dynamic> json) {
    return StudentProgramme(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'],
      status: json['status'] ?? 'active',
      enrollmentDate: json['enrollment_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'status': status,
      'enrollment_date': enrollmentDate,
    };
  }
}

/// Instructor Student - represents a student in instructor's courses
class InstructorStudent {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? chatRoomId;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool? lastMessageFromMe;
  final bool isEnrolledStudent;
  final List<StudentProgramme> programmes;
  final String? enrollmentDate;
  final String? enrollmentStatus;
  final int sessionsAttended;

  InstructorStudent({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.chatRoomId,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageFromMe,
    this.isEnrolledStudent = true,
    this.programmes = const [],
    this.enrollmentDate,
    this.enrollmentStatus,
    this.sessionsAttended = 0,
  });

  factory InstructorStudent.fromJson(Map<String, dynamic> json) {
    final programmesJson = json['programmes'] as List<dynamic>? ?? [];
    return InstructorStudent(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      chatRoomId: json['chat_room_id'] as String?,
      unreadCount: json['unread_count'] ?? 0,
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'])
          : null,
      lastMessageFromMe: json['last_message_from_me'] as bool?,
      isEnrolledStudent: json['is_enrolled_student'] ?? true,
      programmes: programmesJson
          .map((e) => StudentProgramme.fromJson(e as Map<String, dynamic>))
          .toList(),
      enrollmentDate: json['enrollment_date'],
      enrollmentStatus: json['enrollment_status'],
      sessionsAttended: json['sessions_attended'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'chat_room_id': chatRoomId,
      'unread_count': unreadCount,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_from_me': lastMessageFromMe,
      'is_enrolled_student': isEnrolledStudent,
      'programmes': programmes.map((p) => p.toJson()).toList(),
      'enrollment_date': enrollmentDate,
      'enrollment_status': enrollmentStatus,
      'sessions_attended': sessionsAttended,
    };
  }
}

/// Instructor Session - represents a BBB live session
class InstructorSession {
  final int id;
  final String sessionId;
  final String meetingId;
  final String title;
  final String? description;
  final int courseId;
  final String courseType;
  final String status;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final int durationMinutes;
  final bool record;
  final bool hasRecording;
  final int maxParticipants;
  final String? moderatorPassword;
  final String? attendeePassword;
  final int invitationCount;
  final int joinedCount;
  final int attendanceCount;
  final int recordingCount;
  final bool isUpcoming;
  final bool isLiveNow;
  final String? joinUrl;
  final String? startUrl;

  InstructorSession({
    required this.id,
    required this.sessionId,
    required this.meetingId,
    required this.title,
    this.description,
    required this.courseId,
    required this.courseType,
    required this.status,
    this.scheduledStart,
    this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.durationMinutes = 0,
    this.record = true,
    this.hasRecording = false,
    this.maxParticipants = 100,
    this.moderatorPassword,
    this.attendeePassword,
    this.invitationCount = 0,
    this.joinedCount = 0,
    this.attendanceCount = 0,
    this.recordingCount = 0,
    this.isUpcoming = false,
    this.isLiveNow = false,
    this.joinUrl,
    this.startUrl,
  });

  factory InstructorSession.fromJson(Map<String, dynamic> json) {
    return InstructorSession(
      id: json['id'] ?? 0,
      sessionId: json['session_id'] ?? '',
      meetingId: json['meeting_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      courseId: json['course_id'] ?? 0,
      courseType: json['course_type'] ?? 'learnership',
      status: json['status'] ?? 'scheduled',
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.tryParse(json['scheduled_start'])
          : null,
      scheduledEnd: json['scheduled_end'] != null
          ? DateTime.tryParse(json['scheduled_end'])
          : null,
      actualStart: json['actual_start'] != null
          ? DateTime.tryParse(json['actual_start'])
          : null,
      actualEnd: json['actual_end'] != null
          ? DateTime.tryParse(json['actual_end'])
          : null,
      durationMinutes: json['duration_minutes'] ?? 0,
      record: json['record'] ?? true,
      hasRecording: json['has_recording'] ?? false,
      maxParticipants: json['max_participants'] ?? 100,
      moderatorPassword: json['moderator_password'],
      attendeePassword: json['attendee_password'],
      invitationCount: json['invitation_count'] ?? 0,
      joinedCount: json['joined_count'] ?? 0,
      attendanceCount: json['attendance_count'] ?? 0,
      recordingCount: json['recording_count'] ?? 0,
      isUpcoming: json['is_upcoming'] ?? false,
      isLiveNow: json['is_live_now'] ?? false,
      joinUrl: json['join_url'],
      startUrl: json['start_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'meeting_id': meetingId,
      'title': title,
      'description': description,
      'course_id': courseId,
      'course_type': courseType,
      'status': status,
      'scheduled_start': scheduledStart?.toIso8601String(),
      'scheduled_end': scheduledEnd?.toIso8601String(),
      'actual_start': actualStart?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'record': record,
      'has_recording': hasRecording,
      'max_participants': maxParticipants,
      'moderator_password': moderatorPassword,
      'attendee_password': attendeePassword,
      'invitation_count': invitationCount,
      'joined_count': joinedCount,
      'attendance_count': attendanceCount,
      'recording_count': recordingCount,
      'is_upcoming': isUpcoming,
      'is_live_now': isLiveNow,
      'join_url': joinUrl,
      'start_url': startUrl,
    };
  }
}

/// Recent Activity Data
class RecentActivity {
  final int sessionsLast7Days;
  final int messagesLast7Days;

  RecentActivity({
    required this.sessionsLast7Days,
    required this.messagesLast7Days,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      sessionsLast7Days: json['sessions_last_7_days'] ?? 0,
      messagesLast7Days: json['messages_last_7_days'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessions_last_7_days': sessionsLast7Days,
      'messages_last_7_days': messagesLast7Days,
    };
  }
}

/// Performance Metrics
class PerformanceMetrics {
  final double overallRating;
  final String? performanceBand;
  final double averageStudentRating;
  final double completionRate;
  final int totalCoursesTaught;
  final int totalStudentsTaught;
  final double utilizationRate;
  final bool isAvailable;

  PerformanceMetrics({
    required this.overallRating,
    this.performanceBand,
    required this.averageStudentRating,
    required this.completionRate,
    required this.totalCoursesTaught,
    required this.totalStudentsTaught,
    required this.utilizationRate,
    required this.isAvailable,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      overallRating: _parseDouble(json['overall_rating']),
      performanceBand: json['performance_band'],
      averageStudentRating: _parseDouble(json['average_student_rating']),
      completionRate: _parseDouble(json['completion_rate']),
      totalCoursesTaught: json['total_courses_taught'] ?? 0,
      totalStudentsTaught: json['total_students_taught'] ?? 0,
      utilizationRate: _parseDouble(json['utilization_rate']),
      isAvailable: json['is_available'] ?? false,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_rating': overallRating,
      'performance_band': performanceBand,
      'average_student_rating': averageStudentRating,
      'completion_rate': completionRate,
      'total_courses_taught': totalCoursesTaught,
      'total_students_taught': totalStudentsTaught,
      'utilization_rate': utilizationRate,
      'is_available': isAvailable,
    };
  }
}

/// Instructor Stats - statistics for the instructor dashboard
class InstructorStats {
  final int coursesCount;
  final int studentsCount;
  final int unreadMessages;
  final int sessionsCount;
  final int upcomingSessions;
  final int liveSessions;
  final int totalRecordings;
  final int totalEnrollments;
  final double averageSessionAttendance;
  final RecentActivity? recentActivity;
  final Map<String, dynamic> courseCategories;

  InstructorStats({
    required this.coursesCount,
    required this.studentsCount,
    required this.unreadMessages,
    required this.sessionsCount,
    this.upcomingSessions = 0,
    this.liveSessions = 0,
    this.totalRecordings = 0,
    this.totalEnrollments = 0,
    this.averageSessionAttendance = 0.0,
    this.recentActivity,
    this.courseCategories = const {},
  });

  factory InstructorStats.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json['course_categories'] as Map<String, dynamic>? ?? {};
    return InstructorStats(
      coursesCount: json['courses_count'] ?? 0,
      studentsCount: json['students_count'] ?? 0,
      unreadMessages: json['unread_messages'] ?? 0,
      sessionsCount: json['sessions_count'] ?? 0,
      upcomingSessions: json['upcoming_sessions'] ?? 0,
      liveSessions: json['live_sessions'] ?? 0,
      totalRecordings: json['total_recordings'] ?? 0,
      totalEnrollments: json['total_enrollments'] ?? 0,
      averageSessionAttendance: _parseDouble(json['average_session_attendance']),
      recentActivity: json['recent_activity'] != null
          ? RecentActivity.fromJson(json['recent_activity'])
          : null,
      courseCategories: categoriesJson,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'courses_count': coursesCount,
      'students_count': studentsCount,
      'unread_messages': unreadMessages,
      'sessions_count': sessionsCount,
      'upcoming_sessions': upcomingSessions,
      'live_sessions': liveSessions,
      'total_recordings': totalRecordings,
      'total_enrollments': totalEnrollments,
      'average_session_attendance': averageSessionAttendance,
      'recent_activity': recentActivity?.toJson(),
      'course_categories': courseCategories,
    };
  }
}

/// Instructor Dashboard Data - complete dashboard response from backend
class InstructorDashboardData {
  final InstructorProfile profile;
  final InstructorStats stats;
  final PerformanceMetrics? performanceMetrics;
  final List<InstructorCourse> courses;
  final List<InstructorStudent> students;
  final List<InstructorSession> sessions;
  final Map<String, dynamic>? analytics;

  InstructorDashboardData({
    required this.profile,
    required this.stats,
    this.performanceMetrics,
    required this.courses,
    required this.students,
    required this.sessions,
    this.analytics,
  });

  factory InstructorDashboardData.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>? ?? {};
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    final performanceMetricsJson = json['performance_metrics'] as Map<String, dynamic>?;
    final coursesJson = json['courses'] as List<dynamic>? ?? [];
    final studentsJson = json['students'] as List<dynamic>? ?? [];
    final sessionsJson = json['sessions'] as List<dynamic>? ?? [];
    final analyticsJson = json['analytics'] as Map<String, dynamic>?;

    return InstructorDashboardData(
      profile: InstructorProfile.fromJson(profileJson),
      stats: InstructorStats.fromJson(statsJson),
      performanceMetrics: performanceMetricsJson != null
          ? PerformanceMetrics.fromJson(performanceMetricsJson)
          : null,
      courses: coursesJson
          .map((e) => InstructorCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      students: studentsJson
          .map((e) => InstructorStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
      sessions: sessionsJson
          .map((e) => InstructorSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      analytics: analyticsJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'stats': stats.toJson(),
      'performance_metrics': performanceMetrics?.toJson(),
      'courses': courses.map((c) => c.toJson()).toList(),
      'students': students.map((s) => s.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'analytics': analytics,
    };
  }
}
