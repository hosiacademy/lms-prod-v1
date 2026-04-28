# Instructor-Student BBB Session Synchronization

## Overview

This document describes the fully optimized BBB session management system that enables instructors/facilitators to create sessions for their students with complete dashboard synchronization.

---

## Key Features

### 1. **Instructor Session Creation**
- Create BBB sessions directly from instructor dashboard
- Select from assigned courses with enrolled student counts
- Auto-invite all enrolled students with one click
- Configure recording settings
- Set date, time, and participant limits

### 2. **Student Dashboard Integration**
- View all upcoming sessions they're invited to
- Access past session recordings
- See pending invitations
- Join sessions directly from dashboard

### 3. **Real-Time Synchronization**
- Session creation → Auto-invite students → Student dashboard updates
- Recording available → Email notification → Student dashboard updates
- Invitation status tracking (pending → sent → opened → joined)

### 4. **Course-Based Organization**
- Sessions linked to specific courses (learnerships, masterclasses, industry training)
- Students see sessions only for courses they're enrolled in
- Instructors see sessions for their assigned courses

---

## Backend Implementation

### API Endpoints

#### Instructor Endpoints

**1. Get Course Options (with enrolled students)**
```
GET /api/bbb/sessions/course_options/
```

Returns all available courses with enrolled student lists:
```json
{
  "learnerships": [
    {
      "id": 1,
      "title": "AI+ Engineer™",
      "student_count": 25,
      "enrolled_students": [
        {"id": 1, "email": "student1@example.com", "name": "John Doe"},
        ...
      ],
      "phases": [...],
      ...
    }
  ],
  "masterclasses": [...],
  "courses": [...]
}
```

**2. Create Session**
```
POST /api/bbb/sessions/
```

Request:
```json
{
  "course_id": 1,
  "course_type": "learnership",
  "title": "Week 1: Introduction to AI",
  "description": "Session agenda...",
  "scheduled_start": "2026-03-15T10:00:00Z",
  "scheduled_end": "2026-03-15T12:00:00Z",
  "record": true,
  "auto_start_recording": true,
  "max_participants": 100
}
```

**3. Auto-Invite Students**
```
POST /api/bbb/sessions/{id}/auto_invite/
```

Automatically invites all enrolled students:
```json
{
  "message": "Auto-invitations sent successfully",
  "invitations_sent": 25,
  "session_id": "session-abc123"
}
```

**4. Instructor Dashboard**
```
GET /api/v1/facilitators/profiles/dashboard/
```

Returns complete dashboard with sessions:
```json
{
  "stats": {
    "courses_count": 3,
    "students_count": 75,
    "sessions_count": 12,
    "upcoming_sessions": 5,
    "live_sessions": 1,
    "total_recordings": 8
  },
  "sessions": [
    {
      "id": 1,
      "title": "Week 1: Introduction to AI",
      "status": "scheduled",
      "scheduled_start": "2026-03-15T10:00:00Z",
      "invitation_count": 25,
      "joined_count": 0,
      "recording_count": 0,
      "is_upcoming": true,
      "is_live_now": false,
      ...
    }
  ]
}
```

#### Student Endpoints

**1. Student BBB Dashboard**
```
GET /api/bbb/student/dashboard/
```

Returns complete student dashboard:
```json
{
  "stats": {
    "upcoming_sessions": 3,
    "past_sessions": 5,
    "available_recordings": 4,
    "pending_invitations": 1
  },
  "upcoming_sessions": [...],
  "past_sessions": [...],
  "recordings": [...],
  "recent_invitations": [...]
}
```

**2. My Invitations**
```
GET /api/bbb/student/my_invitations/
```

**3. My Recordings**
```
GET /api/bbb/student/my_recordings/
```

**4. Accept Invitation**
```
POST /api/bbb/student/accept_invitation/
```

Request:
```json
{
  "token": "invitation_token_here"
}
```

---

## Frontend Implementation

### Flutter Components

#### 1. Create Session Modal
**File:** `frontend/lib/src/presentation/widgets/bbb/create_session_modal.dart`

Features:
- Course dropdown with student counts
- Date/time pickers
- Recording settings
- Auto-invite toggle
- Real-time student count display

Usage:
```dart
showDialog(
  context: context,
  builder: (context) => CreateSessionModal(
    onSessionCreated: () {
      // Refresh dashboard
      _refreshDashboard();
    },
  ),
);
```

#### 2. API Client Methods
**File:** `frontend/lib/src/core/api/api_client.dart`

```dart
// Get course options
final courses = await ApiClient.getBBBCourseOptions();

// Create session
final session = await ApiClient.createBBBSession(
  courseId: courseId,
  courseType: 'learnership',
  title: 'Session Title',
  scheduledStart: startIso,
  scheduledEnd: endIso,
);

// Auto-invite students
await ApiClient.autoInviteStudentsToSession(sessionId);

// Get dashboards
final instructorDashboard = await ApiClient.getInstructorBBBDashboard();
final studentDashboard = await ApiClient.getStudentBBBDashboard();
```

---

## Data Flow

### Session Creation Flow

```
┌─────────────────┐
│   Instructor    │
│   Dashboard     │
└────────┬────────┘
         │
         │ 1. Click "Create Session"
         ▼
┌─────────────────┐
│  Session Modal  │
│  - Select course│
│  - Set date/time│
│  - Configure    │
└────────┬────────┘
         │
         │ 2. Submit form
         ▼
┌─────────────────┐
│   Backend API   │
│  POST /sessions │
└────────┬────────┘
         │
         │ 3. Create session
         │ 4. Auto-invite students
         ▼
┌─────────────────┐
│  Email Service  │
│  Send invites   │
└────────┬────────┘
         │
         │ 5. Update database
         ▼
┌─────────────────┐
│  Student        │
│  Dashboard      │
│  (Auto-updated) │
└─────────────────┘
```

### Student Join Flow

```
┌─────────────────┐
│    Student      │
│    Email        │
└────────┬────────┘
         │
         │ 1. Click invite link
         ▼
┌─────────────────┐
│  Accept Invite  │
│  POST /accept   │
└────────┬────────┘
         │
         │ 2. Get join URL
         ▼
┌─────────────────┐
│   BBB Server    │
│   Join Meeting  │
└────────┬────────┘
         │
         │ 3. Track attendance
         ▼
┌─────────────────┐
│  Session Stats  │
│  Updated        │
└─────────────────┘
```

### Recording Notification Flow

```
┌─────────────────┐
│   Instructor    │
│   Ends Session  │
└────────┬────────┘
         │
         │ 1. End session
         ▼
┌─────────────────┐
│   BBB Server    │
│   Generate     │
│   Recording    │
└────────┬────────┘
         │
         │ 2. Sync recordings
         ▼
┌─────────────────┐
│   Backend       │
│   Notify        │
│   Students      │
└────────┬────────┘
         │
         │ 3. Send emails
         ▼
┌─────────────────┐
│  Student        │
│  Dashboard      │
│  Recording     │
│  Available     │
└─────────────────┘
```

---

## Database Models

### SessionInvitation (Already documented)

Tracks invitation status for each student:
- `status`: pending → sent → opened → joined
- `chat_invitation_sent`: Whether chat invite was sent
- `chat_invitation_accepted`: Whether student accepted chat

### LiveSession Enhancements

Sessions now include:
- `course_id`: Linked course
- `course_type`: Type of course
- `instructor`: Instructor user
- `invitations`: Related invitations
- `recordings`: Related recordings
- `attendances`: Attendance tracking

---

## Dashboard Synchronization

### Instructor Dashboard Data

```dart
{
  'profile': {...},
  'stats': {
    'courses_count': 3,
    'students_count': 75,
    'sessions_count': 12,
    'upcoming_sessions': 5,
    'live_sessions': 1,
    'total_recordings': 8,
  },
  'courses': [...],
  'students': [...],
  'sessions': [
    {
      'id': 1,
      'title': '...',
      'status': 'scheduled',
      'scheduled_start': '...',
      'invitation_count': 25,
      'joined_count': 0,
      'recording_count': 0,
      'is_upcoming': true,
      'is_live_now': false,
    }
  ]
}
```

### Student Dashboard Data

```dart
{
  'stats': {
    'upcoming_sessions': 3,
    'past_sessions': 5,
    'available_recordings': 4,
    'pending_invitations': 1,
  },
  'upcoming_sessions': [...],
  'past_sessions': [...],
  'recordings': [...],
  'recent_invitations': [...]
}
```

---

## Configuration

### Backend Settings

Ensure these are set in `settings.py`:

```python
# BBB Configuration
BBB_CONFIG = {
    'ENABLED': True,
    'API_URL': 'https://bbb.example.com/bigbluebutton/api/',
    'SECRET': 'your-secret-key',
    'MAX_PARTICIPANTS': 250,
    'RECORD_BY_DEFAULT': True,
    'AUTO_START_RECORDING': True,
}

# Email Configuration
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'your-email@gmail.com'
EMAIL_HOST_PASSWORD = 'your-password'
DEFAULT_FROM_EMAIL = 'Hosi Academy <noreply@hosi.academy>'

# Frontend URL for links
FRONTEND_URL = 'https://hosi.academy'
```

---

## Testing

### Manual Testing Checklist

#### Instructor Flow
1. [ ] Navigate to instructor dashboard
2. [ ] Click "Create Session" button
3. [ ] Select a course (verify student count shows)
4. [ ] Fill in session details
5. [ ] Enable "Send invitations"
6. [ ] Submit form
7. [ ] Verify session appears in dashboard
8. [ ] Verify invitation count matches enrolled students
9. [ ] Start session → Verify "Join" URL works
10. [ ] End session → Verify recording syncs

#### Student Flow
1. [ ] Receive email invitation
2. [ ] Click "Join Session" link
3. [ ] Verify redirect to BBB
4. [ ] Check student dashboard → Session appears
5. [ ] After session → Recording appears in dashboard
6. [ ] Receive recording notification email

#### Admin Flow
1. [ ] View sessions in Django admin
2. [ ] Use "Auto-invite enrolled students" action
3. [ ] View invitation status
4. [ ] Resend invitations if needed

---

## Troubleshooting

### Sessions Not Appearing in Student Dashboard

1. Verify student is enrolled in the course (`Enrollment` model)
2. Check invitation was sent (`SessionInvitation` model)
3. Verify invitation status is not 'expired'
4. Check student email matches enrollment email

### Auto-Invite Not Sending Emails

1. Check email configuration in `settings.py`
2. Verify `Enrollment` records exist for the course
3. Check Django logs for email errors
4. Test with console email backend

### Recordings Not Syncing

1. Verify BBB server is configured correctly
2. Check `sync_recordings()` is called when session ends
3. Verify recording is published in BBB
4. Check `SessionRecording` records are created

---

## Files Modified/Created

### Backend
- `apps/bbb_integration/serializers.py` - Enhanced serializers
- `apps/bbb_integration/views.py` - New endpoints, student dashboard
- `apps/facilitators/views.py` - Enhanced instructor dashboard
- `apps/bbb_integration/models.py` - SessionInvitation model
- `apps/bbb_integration/email_service.py` - Email service
- `apps/bbb_integration/services.py` - Invitation methods

### Frontend
- `frontend/lib/src/core/api/api_client.dart` - BBB API methods
- `frontend/lib/src/presentation/widgets/bbb/create_session_modal.dart` - Session creation UI

### Documentation
- `apps/bbb_integration/BBB_INVITATION_SYSTEM.md` - Invitation system docs
- `apps/bbb_integration/INSTRUCTOR_STUDENT_SYNC.md` - This document

---

## Future Enhancements

- [ ] Real-time notifications via WebSocket
- [ ] Session reminders (SMS/WhatsApp)
- [ ] Attendance tracking via QR code
- [ ] Session feedback/rating system
- [ ] Recurring sessions support
- [ ] Session templates
- [ ] Bulk session creation
- [ ] Calendar integration (Google Calendar, Outlook)
- [ ] Session analytics dashboard

---

## Support

For issues or questions, contact the development team or create an issue in the project tracker.
