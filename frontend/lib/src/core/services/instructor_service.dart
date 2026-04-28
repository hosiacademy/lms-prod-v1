import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../../data/models/instructor_profile.dart';

/// Service for managing instructor/facilitator data
class InstructorService {
  static const String _keyDashboardData = 'instructor_dashboard_data';

  /// Fetch instructor dashboard data from backend
  static Future<InstructorDashboardData> fetchDashboardData() async {
    try {
      final response = await ApiClient.getInstructorDashboard();
      final dashboardData = InstructorDashboardData.fromJson(response);

      // Cache the data
      await _cacheDashboardData(dashboardData.toJson());

      return dashboardData;
    } catch (e) {
      print('❌ Failed to fetch instructor dashboard: $e');
      throw Exception('Failed to load instructor dashboard data: $e');
    }
  }

  /// Get cached dashboard data
  static Future<InstructorDashboardData?> getCachedDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyDashboardData);
      if (data != null) {
        final jsonMap = json.decode(data) as Map<String, dynamic>;
        return InstructorDashboardData.fromJson(jsonMap);
      }
    } catch (e) {
      print('⚠️ Error getting cached dashboard data: $e');
    }
    return null;
  }

  /// Cache dashboard data to shared preferences
  static Future<void> _cacheDashboardData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDashboardData, json.encode(data));
    } catch (e) {
      print('⚠️ Failed to cache dashboard data: $e');
    }
  }

  /// Clear cached dashboard data
  static Future<void> clearCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDashboardData);
  }

  /// Get instructor profile only
  static Future<InstructorProfile> getProfile() async {
    try {
      final response = await ApiClient.getMyInstructorProfile();
      return InstructorProfile.fromJson(response);
    } catch (e) {
      print('❌ Failed to fetch instructor profile: $e');
      throw Exception('Failed to load instructor profile: $e');
    }
  }

  /// Get all enrolled students with programme data
  static Future<Map<String, dynamic>> getEnrolledStudents() async {
    try {
      return await ApiClient.getInstructorStudents();
    } catch (e) {
      print('❌ Failed to fetch enrolled students: $e');
      return {
        'count': 0,
        'students': [],
        'summary': {
          'total_students': 0,
          'active_students': 0,
          'completed_students': 0,
        }
      };
    }
  }

  /// Get detailed course analytics
  static Future<Map<String, dynamic>> getCourseAnalytics() async {
    try {
      return await ApiClient.getInstructorCourseAnalytics();
    } catch (e) {
      print('❌ Failed to fetch course analytics: $e');
      return {
        'total_courses': 0,
        'categories': {},
        'courses': [],
      };
    }
  }

  /// Get session logs and insights
  static Future<Map<String, dynamic>> getSessionInsights({
    String period = 'all',
  }) async {
    try {
      return await ApiClient.getInstructorSessionInsights(period: period);
    } catch (e) {
      print('❌ Failed to fetch session insights: $e');
      return {
        'summary': {
          'total_sessions': 0,
          'completed_sessions': 0,
          'upcoming_sessions': 0,
          'total_attendance': 0,
        },
        'course_breakdown': [],
        'daily_trend': [],
        'session_logs': [],
      };
    }
  }

  /// Get performance metrics
  static Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      return await ApiClient.getInstructorPerformanceMetrics();
    } catch (e) {
      print('❌ Failed to fetch performance metrics: $e');
      return {
        'instructor_id': '',
        'overall_performance': {
          'rating': 0.0,
          'band': null,
        },
        'teaching_metrics': {
          'total_courses': 0,
          'total_students': 0,
          'completion_rate': 0.0,
        },
      };
    }
  }

  /// Get courses with AICerts designations merged
  static Future<List<InstructorCourse>> getCourses() async {
    try {
      final dashboard = await fetchDashboardData();
      return dashboard.courses;
    } catch (e) {
      print('❌ Failed to fetch courses: $e');
      return [];
    }
  }

  /// Get students with chat data
  static Future<List<InstructorStudent>> getStudents() async {
    try {
      final dashboard = await fetchDashboardData();
      return dashboard.students;
    } catch (e) {
      print('❌ Failed to fetch students: $e');
      return [];
    }
  }

  /// Get BBB sessions
  static Future<List<InstructorSession>> getSessions() async {
    try {
      final dashboard = await fetchDashboardData();
      return dashboard.sessions;
    } catch (e) {
      print('❌ Failed to fetch sessions: $e');
      return [];
    }
  }

  /// Get stats summary
  static Future<Map<String, int>> getStats() async {
    try {
      final dashboard = await fetchDashboardData();
      return {
        'courses_count': dashboard.stats.coursesCount,
        'students_count': dashboard.stats.studentsCount,
        'unread_messages': dashboard.stats.unreadMessages,
        'sessions_count': dashboard.stats.sessionsCount,
      };
    } catch (e) {
      print('❌ Failed to fetch stats: $e');
      return {
        'courses_count': 0,
        'students_count': 0,
        'unread_messages': 0,
        'sessions_count': 0,
      };
    }
  }
}
