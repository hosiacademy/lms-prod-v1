// lib/src/data/models/enrollment.dart
import 'package:flutter/material.dart';

enum EnrollmentStatus {
  active,
  completed,
  suspended;

  String get displayName {
    switch (this) {
      case EnrollmentStatus.active:
        return 'Active';
      case EnrollmentStatus.completed:
        return 'Completed';
      case EnrollmentStatus.suspended:
        return 'Suspended';
    }
  }

  Color get color {
    switch (this) {
      case EnrollmentStatus.active:
        return const Color(0xFF4CAF50); // Green
      case EnrollmentStatus.completed:
        return const Color(0xFF2196F3); // Blue
      case EnrollmentStatus.suspended:
        return const Color(0xFFFFC107); // Amber
    }
  }
}

class Enrollment {
  final String id;
  final String courseId;
  final String courseName;
  final String courseType; // 'course', 'masterclass', 'learnership', 'industry'
  final EnrollmentStatus status;
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final double? progress; // 0.0 to 100.0
  final String? thumbnailUrl;
  final bool hasCommunityChat;
  final String? chatRoomId;
  final String? attendanceMode; // 'physical' or 'online'

  Enrollment({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.courseType,
    required this.status,
    required this.enrolledAt,
    this.completedAt,
    this.progress,
    this.thumbnailUrl,
    this.hasCommunityChat = true,
    this.chatRoomId,
    this.attendanceMode,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      courseName: json['course_name'] as String,
      courseType: json['course_type'] as String? ?? 'course',
      status: EnrollmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EnrollmentStatus.active,
      ),
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      progress: json['progress'] != null
          ? double.tryParse(json['progress'].toString())
          : null,
      thumbnailUrl: json['thumbnail_url'] as String?,
      hasCommunityChat: json['has_community_chat'] as bool? ?? true,
      chatRoomId: json['chat_room_id'] as String?,
      attendanceMode: json['attendance_mode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'course_name': courseName,
      'course_type': courseType,
      'status': status.name,
      'enrolled_at': enrolledAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'progress': progress,
      'thumbnail_url': thumbnailUrl,
      'has_community_chat': hasCommunityChat,
      'chat_room_id': chatRoomId,
      'attendance_mode': attendanceMode,
    };
  }
}

// Mock data for demo
List<Enrollment> getMockEnrollments() {
  return [
    Enrollment(
      id: 'enroll-001',
      courseId: 'course-ai-101',
      courseName: 'AI Foundations',
      courseType: 'course',
      status: EnrollmentStatus.active,
      enrolledAt: DateTime.now().subtract(const Duration(days: 30)),
      progress: 65.0,
      thumbnailUrl: null,
      hasCommunityChat: true,
      chatRoomId: 'chat-ai-101',
    ),
    Enrollment(
      id: 'enroll-002',
      courseId: 'masterclass-data-science',
      courseName: 'Data Science Masterclass',
      courseType: 'masterclass',
      status: EnrollmentStatus.active,
      enrolledAt: DateTime.now().subtract(const Duration(days: 15)),
      progress: 40.0,
      hasCommunityChat: true,
      chatRoomId: 'chat-ds-masterclass',
    ),
    Enrollment(
      id: 'enroll-003',
      courseId: 'course-python-101',
      courseName: 'Python Programming',
      courseType: 'course',
      status: EnrollmentStatus.completed,
      enrolledAt: DateTime.now().subtract(const Duration(days: 90)),
      completedAt: DateTime.now().subtract(const Duration(days: 5)),
      progress: 100.0,
      hasCommunityChat: true,
      chatRoomId: 'chat-python-101',
    ),
    Enrollment(
      id: 'enroll-004',
      courseId: 'learnership-software-dev',
      courseName: 'Software Development Learnership',
      courseType: 'learnership',
      status: EnrollmentStatus.suspended,
      enrolledAt: DateTime.now().subtract(const Duration(days: 60)),
      progress: 25.0,
      hasCommunityChat: true,
      chatRoomId: 'chat-sw-learnership',
    ),
  ];
}
