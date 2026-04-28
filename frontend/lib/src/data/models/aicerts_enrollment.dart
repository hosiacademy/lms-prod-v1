// lib/src/data/models/aicerts_enrollment.dart

class AICertsEnrollment {
  final int id;
  final int courseId;
  final String courseTitle;
  final String? courseShortname;
  final String status;
  final DateTime enrolledAt;
  final double progress;
  final DateTime? lastAccessedAt;
  final DateTime? completedAt;

  AICertsEnrollment({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    this.courseShortname,
    required this.status,
    required this.enrolledAt,
    this.progress = 0.0,
    this.lastAccessedAt,
    this.completedAt,
  });

  factory AICertsEnrollment.fromJson(Map<String, dynamic> json) {
    return AICertsEnrollment(
      id: json['id'] as int,
      courseId: json['course'] as int,
      courseTitle: json['course_title'] as String? ?? 'Unknown Course',
      courseShortname: json['course_shortname'] as String?,
      status: json['aicerts_enrollment_status'] as String? ?? 'pending',
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      progress: double.tryParse(json['progress_percentage']?.toString() ?? '') ?? 0.0,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  bool get isEnrolled => status == 'enrolled';
}
