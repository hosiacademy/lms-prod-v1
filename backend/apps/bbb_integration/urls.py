"""
BigBlueButton API URL Configuration
URL routing for BBB API endpoints
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import LiveSessionViewSet, SessionRecordingViewSet, StudentBBBViewSet
from .dashboard_views import (
    InstructorSessionViewSet,
    StudentSessionViewSet,
    get_upcoming_sessions,
    join_session,
)

# Create API router
router = DefaultRouter()

# Register ViewSets
router.register(r'sessions', LiveSessionViewSet, basename='livesession')
router.register(r'recordings', SessionRecordingViewSet, basename='sessionrecording')
router.register(r'student', StudentBBBViewSet, basename='student-bbb')

# Dashboard ViewSets
dashboard_router = DefaultRouter()
dashboard_router.register(r'instructor/sessions', InstructorSessionViewSet, basename='instructor-sessions')
dashboard_router.register(r'learner/sessions', StudentSessionViewSet, basename='learner-sessions')

# URL patterns
urlpatterns = [
    path('', include(router.urls)),
    path('', include(dashboard_router.urls)),
    path('sessions/upcoming/', get_upcoming_sessions, name='upcoming-sessions'),
    path('sessions/<int:session_id>/join/', join_session, name='join-session'),
]

# Available endpoints:
# ===== Instructor Endpoints =====
# GET    /api/bbb/sessions/                    - List all sessions (filtered by role)
# POST   /api/bbb/sessions/                    - Create new session (instructors)
# GET    /api/bbb/sessions/{id}/               - Get session details
# PUT    /api/bbb/sessions/{id}/               - Update session
# PATCH  /api/bbb/sessions/{id}/               - Partial update
# DELETE /api/bbb/sessions/{id}/               - Delete session
# POST   /api/bbb/sessions/{id}/start/         - Start session (instructor)
# POST   /api/bbb/sessions/{id}/end/           - End session (instructor)
# GET    /api/bbb/sessions/{id}/join/          - Get join URL
# GET    /api/bbb/sessions/{id}/attendees/     - Get session attendees (instructor)
# GET    /api/bbb/sessions/{id}/recordings/    - Get session recordings
# POST   /api/bbb/sessions/{id}/invite_students/ - Invite students to session
# POST   /api/bbb/sessions/{id}/auto_invite/   - Auto-invite enrolled students
# GET    /api/bbb/sessions/{id}/invitations/   - Get session invitations
# GET    /api/bbb/sessions/my_sessions/        - Get instructor's sessions
# GET    /api/bbb/sessions/upcoming/           - Get upcoming sessions (learners)
#
# GET    /api/bbb/recordings/                  - List all recordings (filtered by role)
# GET    /api/bbb/recordings/{id}/             - Get recording details
# POST   /api/bbb/recordings/{id}/publish/     - Publish recording (instructor)
# POST   /api/bbb/recordings/{id}/unpublish/   - Unpublish recording (instructor)
#
# ===== Student Endpoints =====
# GET    /api/bbb/student/my_invitations/      - Get student's session invitations
# GET    /api/bbb/student/my_recordings/       - Get student's available recordings
# GET    /api/bbb/student/my_sessions/         - Get student's upcoming and past sessions
# POST   /api/bbb/student/accept_invitation/   - Accept session invitation with token
