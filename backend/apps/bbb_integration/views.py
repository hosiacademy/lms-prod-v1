"""
BigBlueButton API Views
REST API endpoints for instructors and learners to manage live sessions
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.generics import ListAPIView
from django.utils import timezone
from django.shortcuts import get_object_or_404
from datetime import datetime

from .models import LiveSession, SessionRecording, SessionAttendance, BBBServer, SessionInvitation
from .services import BBBService, InstructorSessionManager
from .serializers import (
    LiveSessionSerializer,
    LiveSessionCreateSerializer,
    SessionRecordingSerializer,
    SessionAttendanceSerializer,
    SessionInvitationSerializer,
    StudentInviteSerializer,
    BulkStudentInviteSerializer,
)


class LiveSessionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing live sessions
    Instructors can create, update, start, and end sessions
    """
    permission_classes = [IsAuthenticated]
    serializer_class = LiveSessionSerializer

    def get_queryset(self):
        """Filter sessions based on user role"""
        user = self.request.user

        # Instructors see their own sessions
        if user.role_id == 2:  # Instructor role
            return LiveSession.objects.filter(instructor=user)

        # Admins see all sessions
        if user.role_id == 1:  # Admin role
            return LiveSession.objects.all()

        # Learners see sessions for their enrolled courses
        # TODO: Filter by course enrollment
        return LiveSession.objects.filter(status='scheduled')

    def get_serializer_class(self):
        """Use create serializer for POST requests"""
        if self.action == 'create':
            return LiveSessionCreateSerializer
        return LiveSessionSerializer

    def perform_create(self, serializer):
        """Create session with current user as instructor"""
        serializer.save(instructor=self.request.user)

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        """
        Start a live session
        Instructor-only action
        """
        session = self.get_object()

        # Verify user is instructor
        if session.instructor != request.user and request.user.role_id != 1:
            return Response(
                {'error': 'Only the session instructor can start this session'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Check if session is scheduled
        if session.status != 'scheduled':
            return Response(
                {'error': f'Cannot start session with status: {session.status}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Start session and get moderator join URL
            join_url = InstructorSessionManager.start_session(session)

            return Response({
                'message': 'Session started successfully',
                'session_id': session.session_id,
                'meeting_id': session.meeting_id,
                'join_url': join_url,
                'status': 'live'
            })
        except Exception as e:
            return Response(
                {'error': f'Failed to start session: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        """
        End a live session
        Instructor-only action
        """
        session = self.get_object()

        # Verify user is instructor or admin
        if session.instructor != request.user and request.user.role_id != 1:
            return Response(
                {'error': 'Only the session instructor can end this session'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Check if session is live
        if session.status != 'live':
            return Response(
                {'error': f'Cannot end session with status: {session.status}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # End session
            InstructorSessionManager.end_session(session)

            return Response({
                'message': 'Session ended successfully',
                'session_id': session.session_id,
                'status': 'ended',
                'has_recording': session.has_recording
            })
        except Exception as e:
            return Response(
                {'error': f'Failed to end session: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['get'])
    def join(self, request, pk=None):
        """
        Get join URL for a session
        Returns moderator URL for instructors, attendee URL for learners
        """
        session = self.get_object()

        # Check if session is live
        if session.status != 'live':
            return Response(
                {'error': 'Session is not currently live'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Determine if user should join as moderator
            is_moderator = (
                session.instructor == request.user or
                request.user.role_id == 1  # Admin
            )

            # Get join URL
            join_url = InstructorSessionManager.get_session_join_url(
                session,
                request.user,
                is_moderator
            )

            return Response({
                'join_url': join_url,
                'session_id': session.session_id,
                'role': 'moderator' if is_moderator else 'attendee'
            })
        except Exception as e:
            return Response(
                {'error': f'Failed to generate join URL: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['get'])
    def attendees(self, request, pk=None):
        """
        Get list of session attendees
        Instructor-only action
        """
        session = self.get_object()

        # Verify user is instructor or admin
        if session.instructor != request.user and request.user.role_id != 1:
            return Response(
                {'error': 'Only the session instructor can view attendees'},
                status=status.HTTP_403_FORBIDDEN
            )

        attendances = session.attendances.select_related('user').all()
        serializer = SessionAttendanceSerializer(attendances, many=True)

        return Response({
            'session_id': session.session_id,
            'total_attendees': attendances.count(),
            'attendees': serializer.data
        })

    @action(detail=True, methods=['get'])
    def recordings(self, request, pk=None):
        """Get all recordings for a session"""
        session = self.get_object()
        recordings = session.recordings.all()
        serializer = SessionRecordingSerializer(recordings, many=True)

        return Response({
            'session_id': session.session_id,
            'total_recordings': recordings.count(),
            'recordings': serializer.data
        })

    @action(detail=False, methods=['get'])
    def my_sessions(self, request):
        """
        Get all sessions for the current instructor
        Organized by status
        
        NOTE: LiveSession.instructor is a ForeignKey to User model.
        The instructor_id in the Instructor model is a system-generated ID (e.g., FAC-XXXX)
        that is different from User.id. Sessions are linked via User.id, not Instructor.instructor_id.
        """
        # Check if user is authenticated
        if not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Check if user is an instructor or admin
        # Role ID 2 = Instructor (all instructors share this role_id)
        # Role ID 1 = Admin
        if not hasattr(request.user, 'role_id') or request.user.role_id not in [1, 2]:
            return Response(
                {'error': 'This endpoint is for instructors only'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Filter sessions by user.id (LiveSession.instructor points to User model)
        sessions = LiveSession.objects.filter(instructor_id=request.user.id)

        # Check if user has instructor profile or sessions
        has_instructor_profile = hasattr(request.user, 'facilitator_profile')
        has_sessions = sessions.exists()

        if not has_instructor_profile and not has_sessions:
            return Response(
                {'error': 'This endpoint is for instructors only'},
                status=status.HTTP_403_FORBIDDEN
            )

        return Response({
            'upcoming': LiveSessionSerializer(
                sessions.filter(status='scheduled', scheduled_start__gte=timezone.now()),
                many=True
            ).data,
            'live': LiveSessionSerializer(
                sessions.filter(status='live'),
                many=True
            ).data,
            'past': LiveSessionSerializer(
                sessions.filter(status='ended').order_by('-scheduled_start')[:10],
                many=True
            ).data,
        })

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def upcoming(self, request):
        """Get all upcoming sessions for learners"""
        upcoming_sessions = LiveSession.objects.filter(
            status='scheduled',
            scheduled_start__gte=timezone.now()
        ).order_by('scheduled_start')

        serializer = LiveSessionSerializer(upcoming_sessions, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def invite_students(self, request, pk=None):
        """
        Invite students to a session via email
        Instructor-only action
        """
        session = self.get_object()

        # Verify user is instructor or admin
        if session.instructor != request.user and request.user.role_id != 1:
            return Response(
                {'error': 'Only the session instructor can invite students'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = BulkStudentInviteSerializer(data=request.data)
        if serializer.is_valid():
            students = serializer.validated_data['students']
            send_chat_invite = serializer.validated_data.get('send_chat_invite', True)

            try:
                sent_count = InstructorSessionManager.invite_students_to_session(
                    session=session,
                    students=students,
                    send_chat_invite=send_chat_invite,
                )

                return Response({
                    'message': f'Invitations sent successfully',
                    'invitations_sent': sent_count,
                    'session_id': session.session_id,
                })
            except Exception as e:
                return Response(
                    {'error': f'Failed to send invitations: {str(e)}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def auto_invite(self, request, pk=None):
        """
        Automatically invite all enrolled students to a session
        Instructor-only action
        """
        session = self.get_object()

        # Verify user is instructor or admin
        if session.instructor != request.user and request.user.role_id != 1:
            return Response(
                {'error': 'Only the session instructor can invite students'},
                status=status.HTTP_403_FORBIDDEN
            )

        try:
            sent_count = InstructorSessionManager.auto_invite_enrolled_students(session)

            return Response({
                'message': 'Auto-invitations sent successfully',
                'invitations_sent': sent_count,
                'session_id': session.session_id,
            })
        except Exception as e:
            return Response(
                {'error': f'Failed to send auto-invitations: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['get'])
    def invitations(self, request, pk=None):
        """
        Get list of session invitations
        Instructor-only action
        """
        session = self.get_object()

        # Verify user is instructor or admin
        if session.instructor != request.user and request.user.role_id != 1:
            return Response(
                {'error': 'Only the session instructor can view invitations'},
                status=status.HTTP_403_FORBIDDEN
            )

        invitations = session.invitations.all()
        serializer = SessionInvitationSerializer(invitations, many=True)

        return Response({
            'session_id': session.session_id,
            'total_invitations': invitations.count(),
            'invitations': serializer.data,
        })

    @action(detail=False, methods=['get'])
    def course_options(self, request):
        """
        Return all available course options for session creation:
        learnerships (with phases), masterclasses, and AICERTS courses.
        Includes enrolled students for each course.
        Instructors use this to populate the session creation form.
        """
        from apps.learnerships.models import LearnershipProgramme, LearnershipPhase, LearnershipEnrollment
        from apps.masterclasses.models import Masterclass
        from apps.aicerts_courses.models import AiCertsCourse
        from apps.payments.models import Enrollment
        from django.contrib.contenttypes.models import ContentType

        # Helper to get enrolled students for a course
        def get_enrolled_students(content_type_id, object_id):
            enrollments = Enrollment.objects.filter(
                content_type_id=content_type_id,
                object_id=object_id,
                status='enrolled'
            ).select_related('user')
            return [
                {
                    'id': e.user.id,
                    'email': e.user.email,
                    'name': e.user.get_full_name() or e.user.email,
                }
                for e in enrollments
            ]

        # Learnerships with their phases and enrolled students
        learnerships = []
        learnership_ctype = ContentType.objects.get_for_model(LearnershipProgramme).id
        for prog in LearnershipProgramme.objects.filter(active=True).prefetch_related('phases').order_by('title'):
            phases = [
                {
                    'id': ph.id,
                    'name': ph.name,
                    'order': ph.order,
                    'duration_weeks': ph.duration_weeks,
                    'start_date': ph.start_date.isoformat() if ph.start_date else None,
                    'end_date': ph.end_date.isoformat() if ph.end_date else None,
                    'description': ph.description or '',
                }
                for ph in prog.phases.all().order_by('order')
            ]
            enrolled_students = get_enrolled_students(learnership_ctype, prog.id)
            learnerships.append({
                'id': prog.id,
                'title': prog.title,
                'role': prog.role or '',
                'nqf_level': prog.nqf_level or '',
                'duration_months': prog.duration_months or 0,
                'duration_weeks': prog.duration_weeks or 0,
                'delivery_mode': prog.delivery_mode or 'hybrid',
                'location': prog.location or '',
                'city': prog.city or '',
                'country': prog.country or '',
                'max_participants': prog.max_participants,
                'specialization': prog.specialization or '',
                'is_funded': prog.is_funded,
                'stipend_amount': str(prog.stipend_amount) if prog.stipend_amount else '0',
                'status': prog.status,
                'phases': phases,
                'enrolled_students': enrolled_students,
                'student_count': len(enrolled_students),
            })

        # Masterclasses (scheduled or ongoing)
        masterclasses = []
        masterclass_ctype = ContentType.objects.get_for_model(Masterclass).id
        for mc in Masterclass.objects.filter(
            status__in=['scheduled', 'ongoing']
        ).order_by('start_date'):
            enrolled_students = get_enrolled_students(masterclass_ctype, mc.id)
            masterclasses.append({
                'id': mc.id,
                'title': mc.title,
                'focus_area': mc.focus_area or '',
                'tier': mc.tier or '',
                'stream_type': mc.stream_type or '',
                'start_date': mc.start_date.isoformat() if mc.start_date else None,
                'end_date': mc.end_date.isoformat() if mc.end_date else None,
                'city': mc.city or '',
                'country_name': mc.country_name or '',
                'max_participants': mc.max_participants,
                'status': mc.status,
                'enrolled_students': enrolled_students,
                'student_count': len(enrolled_students),
            })

        # AICERTS Courses
        courses = []
        aicerts_ctype = ContentType.objects.get_for_model(AiCertsCourse).id
        for course in AiCertsCourse.objects.order_by('title')[:100]:
            enrolled_students = get_enrolled_students(aicerts_ctype, course.id)
            courses.append({
                'id': course.id,
                'title': course.title,
                'category_name': course.category_name or '',
                'enrolled_students': enrolled_students,
                'student_count': len(enrolled_students),
            })

        return Response({
            'learnerships': learnerships,
            'masterclasses': masterclasses,
            'courses': courses,
        })

    @action(detail=False, methods=['post'])
    def start_now(self, request):
        """
        Create a session and immediately start it (go live now).
        Accepts same payload as session creation plus optional duration_minutes.
        Returns a moderator join URL.
        Instructor-only.
        """
        if request.user.role_id not in (1, 2):
            return Response(
                {'error': 'Only instructors can start sessions'},
                status=status.HTTP_403_FORBIDDEN
            )

        data = request.data.copy()

        # Default: session runs for duration_minutes from now (default 90 min)
        duration_minutes = int(data.pop('duration_minutes', 90))
        now = timezone.now()
        data.setdefault('scheduled_start', now.isoformat())
        data.setdefault('scheduled_end', (now + timezone.timedelta(minutes=duration_minutes)).isoformat())
        data.setdefault('course_id', 1)
        data.setdefault('course_type', 'course')

        serializer = LiveSessionCreateSerializer(data=data, context={'request': request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        session = serializer.save(instructor=request.user)

        try:
            join_url = InstructorSessionManager.start_session(session)
            return Response({
                'message': 'Session created and started',
                'session_id': session.session_id,
                'meeting_id': session.meeting_id,
                'join_url': join_url,
                'status': 'live',
                'id': session.id,
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            session.delete()
            return Response(
                {'error': f'Session created but failed to start on BBB: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SessionRecordingViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for session recordings
    Instructors can manage their recordings
    """
    permission_classes = [IsAuthenticated]
    serializer_class = SessionRecordingSerializer

    def get_queryset(self):
        """Filter recordings based on user role"""
        user = self.request.user

        # Instructors see recordings from their sessions
        if user.role_id == 2:
            return SessionRecording.objects.filter(
                session__instructor=user
            )

        # Admins see all recordings
        if user.role_id == 1:
            return SessionRecording.objects.all()

        # Learners see published recordings only
        return SessionRecording.objects.filter(published=True)

    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        """
        Publish a recording
        Instructor-only action
        """
        recording = self.get_object()

        # Verify user is instructor or admin
        if recording.session.instructor != request.user and request.user.role_id != 1:
            return Response(
                {'error': 'Only the session instructor can publish recordings'},
                status=status.HTTP_403_FORBIDDEN
            )

        try:
            service = BBBService(recording.session.bbb_server)
            service.publish_recording(recording.record_id, publish=True)

            recording.published = True
            recording.save()

            return Response({
                'message': 'Recording published successfully',
                'record_id': recording.record_id
            })
        except Exception as e:
            return Response(
                {'error': f'Failed to publish recording: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def unpublish(self, request, pk=None):
        """
        Unpublish a recording
        Instructor-only action
        """
        recording = self.get_object()

        # Verify user is instructor or admin
        if recording.session.instructor != request.user and request.user.role_id != 1:
            return Response(
                {'error': 'Only the session instructor can unpublish recordings'},
                status=status.HTTP_403_FORBIDDEN
            )

        try:
            service = BBBService(recording.session.bbb_server)
            service.publish_recording(recording.record_id, publish=False)

            recording.published = False
            recording.save()

            return Response({
                'message': 'Recording unpublished successfully',
                'record_id': recording.record_id
            })
        except Exception as e:
            return Response(
                {'error': f'Failed to unpublish recording: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StudentBBBViewSet(viewsets.ViewSet):
    """
    Student-facing BBB endpoints
    Provides access to session invitations, recordings, and join URLs
    """
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """
        Complete student dashboard with sessions, invitations, and recordings
        """
        user_email = request.user.email
        
        # Get sessions student was invited to
        invited_session_ids = SessionInvitation.objects.filter(
            email=user_email,
            status__in=['sent', 'opened', 'joined']
        ).values_list('session_id', flat=True)
        
        # Get sessions student attended
        attended_session_ids = SessionAttendance.objects.filter(
            user=request.user
        ).values_list('session_id', flat=True)
        
        session_ids = set(invited_session_ids) | set(attended_session_ids)
        
        # Get upcoming sessions
        upcoming = LiveSession.objects.filter(
            id__in=session_ids,
            status='scheduled',
            scheduled_start__gte=timezone.now()
        ).select_related('instructor').order_by('scheduled_start')
        
        # Get past sessions
        past = LiveSession.objects.filter(
            id__in=session_ids,
            status__in=['live', 'ended']
        ).select_related('instructor').order_by('-scheduled_start')[:20]
        
        # Get published recordings
        recordings = SessionRecording.objects.filter(
            session_id__in=session_ids,
            published=True
        ).select_related('session__instructor').order_by('-start_time')[:50]
        
        # Get invitations
        invitations = SessionInvitation.objects.filter(
            email=user_email
        ).select_related('session__instructor').order_by('-created_at')[:20]
        
        return Response({
            'stats': {
                'upcoming_sessions': upcoming.count(),
                'past_sessions': past.count(),
                'available_recordings': recordings.count(),
                'pending_invitations': invitations.filter(status='pending').count(),
            },
            'upcoming_sessions': LiveSessionSerializer(upcoming, many=True).data,
            'past_sessions': LiveSessionSerializer(past, many=True).data,
            'recordings': SessionRecordingSerializer(recordings, many=True).data,
            'recent_invitations': SessionInvitationSerializer(invitations, many=True).data,
        })

    @action(detail=False, methods=['get'])
    def my_invitations(self, request):
        """
        Get all session invitations for the current student
        """
        user_email = request.user.email
        
        invitations = SessionInvitation.objects.filter(
            email=user_email
        ).select_related('session__instructor').order_by('-created_at')
        
        serializer = SessionInvitationSerializer(invitations, many=True)
        
        return Response({
            'total': invitations.count(),
            'invitations': serializer.data,
        })

    @action(detail=False, methods=['get'])
    def my_recordings(self, request):
        """
        Get all available session recordings for the current student
        Shows recordings from sessions the student was invited to or attended
        """
        user_email = request.user.email
        
        # Get sessions student was invited to or attended
        invited_sessions = SessionInvitation.objects.filter(
            email=user_email,
            status__in=['sent', 'opened', 'joined']
        ).values_list('session_id', flat=True)
        
        attended_sessions = SessionAttendance.objects.filter(
            user=request.user
        ).values_list('session_id', flat=True)
        
        session_ids = set(invited_sessions) | set(attended_sessions)
        
        # Get published recordings from those sessions
        recordings = SessionRecording.objects.filter(
            session_id__in=session_ids,
            published=True
        ).select_related('session__instructor').order_by('-start_time')
        
        serializer = SessionRecordingSerializer(recordings, many=True)
        
        return Response({
            'total': recordings.count(),
            'recordings': serializer.data,
        })

    @action(detail=False, methods=['get'])
    def my_sessions(self, request):
        """
        Get all upcoming and past sessions for the current student
        """
        user_email = request.user.email

        # Get sessions student was invited to
        invited_session_ids = SessionInvitation.objects.filter(
            email=user_email,
            status__in=['sent', 'opened', 'joined']
        ).values_list('session_id', flat=True)

        # Get sessions student attended
        attended_session_ids = SessionAttendance.objects.filter(
            user=request.user
        ).values_list('session_id', flat=True)

        session_ids = set(invited_session_ids) | set(attended_session_ids)

        # Get all enrolled courses for the student to auto-include their sessions
        from apps.payments.models import Enrollment
        from django.db.models import Q

        enrolled_courses = Enrollment.objects.filter(
            user=request.user,
            status__in=['enrolled', 'completed']
        ).values('content_type__model', 'object_id')

        enrollment_q = Q(id__in=session_ids)

        for enr in enrolled_courses:
            model_name = enr['content_type__model']
            # Map content type model to course_type in LiveSession
            c_type = 'course'
            if model_name == 'masterclass':
                c_type = 'masterclass'
            elif model_name == 'learnershipprogramme':
                c_type = 'learnership'
            elif model_name == 'aicertscourse':
                c_type = 'course'

            enrollment_q |= Q(course_type=c_type, course_id=enr['object_id'])

        # Get sessions
        upcoming = LiveSession.objects.filter(
            enrollment_q,
            status='scheduled',
            scheduled_start__gte=timezone.now()
        ).select_related('instructor').order_by('scheduled_start').distinct()

        past = LiveSession.objects.filter(
            enrollment_q,
            status__in=['live', 'ended']
        ).select_related('instructor').order_by('-scheduled_start').distinct()[:20]        
        return Response({
            'upcoming': LiveSessionSerializer(upcoming, many=True).data,
            'past': LiveSessionSerializer(past, many=True).data,
        })

    @action(detail=False, methods=['post'])
    def accept_invitation(self, request):
        """
        Accept a session invitation using invitation token
        """
        token = request.data.get('token')
        
        if not token:
            return Response(
                {'error': 'Invitation token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            invitation = SessionInvitation.objects.get(invitation_token=token)
            
            # Mark as opened/joined
            if invitation.status == 'pending':
                invitation.mark_as_opened()
            
            # Get join URL
            session = invitation.session
            service = BBBService(session.bbb_server)
            join_url = service.get_join_url(
                session,
                invitation.student_name,
                is_moderator=False
            )
            
            return Response({
                'message': 'Invitation accepted',
                'session_id': session.session_id,
                'join_url': join_url,
            })
        except SessionInvitation.DoesNotExist:
            return Response(
                {'error': 'Invalid invitation token'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Failed to accept invitation: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
