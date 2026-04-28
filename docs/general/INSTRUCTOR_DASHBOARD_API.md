# Comprehensive Instructor Dashboard API Implementation

## Overview

This document describes the enhanced Instructor Dashboard backend API endpoints designed to provide comprehensive analytics, insights, and management capabilities for instructors. The implementation pulls student data through the users table linked via instructor ID, enrollment data through the enrollment table, and integrates session logs for complete instructor insights.

---

## Backend API Endpoints

All endpoints are prefixed with `/api/v1/instructors/profiles/`

### 1. **Enhanced Dashboard Endpoint**
```
GET /api/v1/instructors/profiles/dashboard/
```

**Purpose:** Main dashboard endpoint with comprehensive analytics

**Returns:**
```json
{
  "profile": {
    "id": 1,
    "instructor_id": "FAC-ABC12345",
    "name": "John Doe",
    "email": "instructor@example.com",
    "department": "Computer Science",
    "specialization": "AI, Cybersecurity",
    "instructor_type": "facilitator",
    "is_available": true,
    "avatar_url": "https://..."
  },
  "stats": {
    "courses_count": 3,
    "students_count": 75,
    "unread_messages": 12,
    "sessions_count": 24,
    "upcoming_sessions": 5,
    "live_sessions": 1,
    "total_recordings": 18,
    "total_enrollments": 75,
    "average_session_attendance": 18.5,
    "recent_activity": {
      "sessions_last_7_days": 8,
      "messages_last_7_days": 45
    },
    "course_categories": {
      "Cybersecurity": {"count": 2, "students": 50},
      "AI": {"count": 1, "students": 25}
    }
  },
  "performance_metrics": {
    "overall_rating": 85.5,
    "performance_band": "excellent",
    "average_student_rating": 4.5,
    "completion_rate": 92.3,
    "total_courses_taught": 15,
    "total_students_taught": 250,
    "utilization_rate": 60.0,
    "is_available": true
  },
  "courses": [...],
  "students": [...],
  "sessions": [...],
  "analytics": {
    "enrollment_trend": [],
    "session_attendance_trend": [],
    "category_breakdown": {...}
  }
}
```

**Key Features:**
- Profile information with avatar
- Comprehensive statistics with category breakdown
- Performance metrics
- Course list with enrollment counts
- Student list with chat integration
- Session list with attendance tracking
- Analytics data for trends

---

### 2. **My Students Endpoint**
```
GET /api/v1/instructors/profiles/my_students/
```

**Purpose:** Get all students enrolled in instructor's courses with detailed enrollment data

**Returns:**
```json
{
  "count": 75,
  "students": [
    {
      "id": 101,
      "name": "Jane Student",
      "email": "student@example.com",
      "phone": "+27 123 456 789",
      "avatar_url": "https://...",
      "chat_room_id": "room_123",
      "unread_messages": 2,
      "programmes": [
        {
          "id": 1,
          "title": "AI+ Engineer™",
          "category": "Cybersecurity",
          "status": "active"
        }
      ],
      "enrollment_count": 1,
      "first_enrollment_date": "2026-02-01T10:00:00Z",
      "enrollment_statuses": ["active"],
      "sessions_attended": 12,
      "is_active": true
    }
  ],
  "summary": {
    "total_students": 75,
    "active_students": 68,
    "completed_students": 7
  }
}
```

**Key Features:**
- Student profile information
- Enrolled programmes with categories
- Enrollment status tracking
- Session attendance count
- Chat integration data
- Summary statistics

---

### 3. **Course Analytics Endpoint**
```
GET /api/v1/instructors/profiles/course_analytics/
```

**Purpose:** Get detailed analytics for each course with category breakdown

**Returns:**
```json
{
  "total_courses": 3,
  "categories": {
    "Cybersecurity": {
      "course_count": 2,
      "total_enrollments": 50,
      "total_sessions": 40
    },
    "AI": {
      "course_count": 1,
      "total_enrollments": 25,
      "total_sessions": 20
    }
  },
  "courses": [
    {
      "id": 1,
      "title": "AI+ Engineer™",
      "slug": "ai-plus-engineer",
      "category": "Cybersecurity",
      "status": "active",
      "nqf_level": "Level 5",
      "duration_months": 12,
      "enrollments": {
        "total": 25,
        "active": 23
      },
      "sessions": {
        "total": 24,
        "upcoming": 5,
        "completed": 18,
        "average_attendance": 18.5
      },
      "recordings": {
        "total": 18
      },
      "start_date": "2026-01-15",
      "end_date": "2027-01-15"
    }
  ]
}
```

**Key Features:**
- Category breakdown with aggregated stats
- Per-course enrollment analytics
- Session statistics
- Recording counts
- Course metadata

---

### 4. **Session Insights Endpoint**
```
GET /api/v1/instructors/profiles/session_insights/?period=month
```

**Query Parameters:**
- `period`: `all` (default), `week`, `month`, `quarter`

**Purpose:** Get session logs and insights for instructor analytics

**Returns:**
```json
{
  "summary": {
    "total_sessions": 24,
    "completed_sessions": 18,
    "upcoming_sessions": 5,
    "total_attendance": 432,
    "average_attendance_per_session": 18.0,
    "total_invitations": 600,
    "average_invitations_per_session": 25.0,
    "total_recordings": 18
  },
  "course_breakdown": [
    {
      "course_id": 1,
      "course_type": "learnership",
      "session_count": 24,
      "total_attendance": 432,
      "total_recordings": 18
    }
  ],
  "daily_trend": [
    {
      "date": "2026-03-10",
      "sessions_count": 2,
      "total_attendance": 36
    }
  ],
  "session_logs": [
    {
      "id": 1,
      "title": "Week 1: Introduction to AI",
      "course_id": 1,
      "course_type": "learnership",
      "scheduled_start": "2026-03-15T10:00:00Z",
      "scheduled_end": "2026-03-15T12:00:00Z",
      "status": "scheduled",
      "duration_minutes": 120,
      "attendance": {
        "count": 0,
        "invitations": 25,
        "joined_via_invitation": 0,
        "engagement_rate": 0.0
      },
      "recordings": {
        "count": 0,
        "total_duration": 0
      },
      "is_upcoming": true,
      "is_live_now": false,
      "has_recording": false
    }
  ]
}
```

**Key Features:**
- Session summary statistics
- Course-wise breakdown
- Daily attendance trends (last 14 days)
- Detailed session logs with attendance and engagement metrics
- Time period filtering

---

### 5. **Performance Metrics Endpoint**
```
GET /api/v1/instructors/profiles/performance_metrics/
```

**Purpose:** Get comprehensive performance metrics for the instructor

**Returns:**
```json
{
  "instructor_id": "FAC-ABC12345",
  "overall_performance": {
    "rating": 85.5,
    "band": "excellent",
    "last_review": "2026-02-15"
  },
  "teaching_metrics": {
    "total_courses": 3,
    "total_students": 75,
    "completion_rate": 92.3,
    "average_student_rating": 4.5,
    "total_reviews": 45
  },
  "session_metrics": {
    "total_sessions": 24,
    "completed_sessions": 18,
    "average_attendance": 18.0,
    "attendance_rate": 72.0,
    "recording_rate": 75.0,
    "total_recordings": 18
  },
  "recent_activity": {
    "sessions_last_30_days": 8,
    "enrollments_last_30_days": 12
  },
  "performance_trends": {
    "sessions_trend": "stable",
    "enrollments_trend": "stable",
    "attendance_trend": "stable"
  },
  "capacity": {
    "current_courses": 3,
    "max_courses": 5,
    "utilization_rate": 60.0,
    "is_available": true
  }
}
```

**Key Features:**
- Overall performance rating
- Teaching effectiveness metrics
- Session effectiveness stats
- Recent activity summary
- Performance trends
- Capacity utilization

---

## Data Models

### Student-Instructor Relationship

Students are linked to instructors through:
1. **LearnershipProgramme** → `instructor` field (User FK)
2. **LearnershipEnrollment** → `programme` FK + `user` FK (student)
3. **User** table → Student profile data

```
Instructor (User) 
  ↓ (instructor FK)
LearnershipProgramme
  ↓ (programme FK)
LearnershipEnrollment
  ↓ (user FK)
Student (User)
```

### Course Categories

Courses are categorized by the `category` field in `LearnershipProgramme`:
- AI (default)
- Cybersecurity
- Cloud Security
- Software Development
- etc.

### Session Analytics

Sessions are tracked through:
- **LiveSession**: Session metadata
- **SessionInvitation**: Student invitations
- **SessionAttendance**: Actual attendance
- **SessionRecording**: Available recordings

---

## Frontend Integration

### Dart Models

Updated models in `frontend/lib/src/data/models/instructor_profile.dart`:

- `InstructorProfile`: Enhanced with avatar, instructor_id
- `InstructorCourse`: Added category, sessions, attendance data
- `InstructorStudent`: Added programmes, enrollment data, sessions attended
- `InstructorSession`: Comprehensive session data with attendance
- `InstructorStats`: Enhanced with categories, recent activity
- `PerformanceMetrics`: New model for performance data
- `RecentActivity`: New model for activity tracking
- `StudentProgramme`: New model for programme enrollment

### API Client Methods

Added to `frontend/lib/src/core/api/api_client.dart`:

```dart
// Get all enrolled students
static Future<Map<String, dynamic>> getInstructorStudents()

// Get course analytics
static Future<Map<String, dynamic>> getInstructorCourseAnalytics()

// Get session insights
static Future<Map<String, dynamic>> getInstructorSessionInsights({String period})

// Get performance metrics
static Future<Map<String, dynamic>> getInstructorPerformanceMetrics()
```

### Service Methods

Added to `frontend/lib/src/core/services/instructor_service.dart`:

```dart
static Future<Map<String, dynamic>> getEnrolledStudents()
static Future<Map<String, dynamic>> getCourseAnalytics()
static Future<Map<String, dynamic>> getSessionInsights({String period})
static Future<Map<String, dynamic>> getPerformanceMetrics()
```

---

## Usage Examples

### Fetch Complete Dashboard
```dart
final dashboard = await InstructorService.fetchDashboardData();
print('Courses: ${dashboard.stats.coursesCount}');
print('Students: ${dashboard.stats.studentsCount}');
print('Unread Messages: ${dashboard.stats.unreadMessages}');
```

### Get Enrolled Students
```dart
final studentsData = await InstructorService.getEnrolledStudents();
print('Total Students: ${studentsData['summary']['total_students']}');
print('Active Students: ${studentsData['summary']['active_students']}');
```

### Get Course Analytics by Category
```dart
final analytics = await InstructorService.getCourseAnalytics();
final categories = analytics['categories'];
for (var category in categories.entries) {
  print('${category.key}: ${category.value['course_count']} courses');
}
```

### Get Session Insights
```dart
final insights = await InstructorService.getSessionInsights(period: 'month');
print('Total Sessions: ${insights['summary']['total_sessions']}');
print('Average Attendance: ${insights['summary']['average_attendance_per_session']}');
```

### Get Performance Metrics
```dart
final performance = await InstructorService.getPerformanceMetrics();
print('Overall Rating: ${performance['overall_performance']['rating']}');
print('Completion Rate: ${performance['teaching_metrics']['completion_rate']}%');
```

---

## Analytics Enhancements

### Dashboard Analytics Section

The dashboard now includes comprehensive analytics:

1. **Course Category Breakdown**
   - Number of courses per category
   - Student enrollment per category
   - Session counts per category

2. **Enrollment Trends**
   - Track enrollment growth over time
   - Identify popular courses
   - Monitor completion rates

3. **Session Attendance Trends**
   - Daily attendance tracking
   - Engagement rate calculation
   - Invitation effectiveness

4. **Performance Metrics**
   - Overall instructor rating
   - Student feedback summary
   - Capacity utilization

5. **Recent Activity**
   - Last 7 days activity summary
   - Session count
   - Message count

---

## Testing

### Backend Testing

Test the endpoints using curl or Postman:

```bash
# Get dashboard
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/v1/instructors/profiles/dashboard/

# Get students
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/v1/instructors/profiles/my_students/

# Get course analytics
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/v1/instructors/profiles/course_analytics/

# Get session insights (last month)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/v1/instructors/profiles/session_insights/?period=month"

# Get performance metrics
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/v1/instructors/profiles/performance_metrics/
```

### Frontend Testing

Run the Flutter app and navigate to the Instructor Dashboard to verify:
- Dashboard loads with all statistics
- Students list shows enrolled students with programmes
- Courses display category and session data
- Sessions show attendance and engagement metrics

---

## Files Modified

### Backend
- `backend/apps/instructors/views.py` - Enhanced dashboard + new endpoints
- `backend/apps/instructors/urls.py` - URL routing (already configured)

### Frontend
- `frontend/lib/src/data/models/instructor_profile.dart` - Enhanced models
- `frontend/lib/src/core/api/api_client.dart` - New API methods
- `frontend/lib/src/core/services/instructor_service.dart` - New service methods

---

## Security & Permissions

All endpoints require:
- Authentication (user must be logged in)
- Instructor role (role_id = 2)
- Active instructor profile

Returns 403 Forbidden for non-instructors.
Returns 404 Not Found if no instructor profile exists.

---

## Performance Considerations

- Uses `select_related()` for efficient database queries
- Caches dashboard data in SharedPreferences
- Paginates large datasets (session logs limited to 50)
- Aggregates data at database level where possible

---

## Future Enhancements

- [ ] Historical trend data with charts
- [ ] Export analytics to CSV/PDF
- [ ] Real-time notifications via WebSocket
- [ ] Student performance analytics
- [ ] Comparative analytics (vs other instructors)
- [ ] Custom date range filters
- [ ] Advanced filtering and sorting
- [ ] Session feedback integration

---

## Support

For issues or questions regarding this implementation, contact the development team or create an issue in the project tracker.
