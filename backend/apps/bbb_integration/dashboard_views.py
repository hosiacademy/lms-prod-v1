"""
BBB Session Dashboard Views
Provides instructor and student dashboards for BBB sessions
"""

from rest_framework import viewsets, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.shortcuts import get_object_or_404
from apps.bbb_integration.models import LiveSession, SessionInvitation, SessionAttendance
from apps.bbb_integration.services import BBBService
from apps.bbb_integration.serializers import LiveSessionSerializer


class IsInstructorOrReadOnly(permissions.BasePermission):
    """Permission class for instructor-only actions"""
    
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.instructor == request.user


class InstructorSessionViewSet(viewsets.ModelViewSet):
    """ViewSet for instructor to manage their sessions"""
    
    serializer_class = LiveSessionSerializer
    permission_classes = [IsAuthenticated, IsInstructorOrReadOnly]
    
    def get_queryset(self):
        """Instructor can only see their own sessions"""
        return LiveSession.objects.filter(
            instructor=self.request.user
        ).order_by('-scheduled_start')
    
    def retrieve(self, request, *args, **kwargs):
        """Get session details with join URLs"""
        instance = self.get_object()

        # Check if user is the instructor
        if instance.instructor != request.user:
            return Response(
                {'error': 'You do not have permission to view this session'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Generate join URL
        bbb_service = BBBService(instance.bbb_server)
        join_url = bbb_service.get_join_url(
            session=instance,
            user_name=f"{request.user.first_name} {request.user.last_name}",
            is_moderator=True
        )
        
        # Get enrolled students
        from apps.learnerships.models import LearnershipEnrollment
        enrolled_students = []
        
        if instance.course_type == 'learnership':
            enrollments = LearnershipEnrollment.objects.filter(
                programme_id=instance.course_id,
                active=True
            ).select_related('user')[:50]
            
            for enrollment in enrollments:
                enrolled_students.append({
                    'id': enrollment.user.id,
                    'name': f"{enrollment.user.first_name} {enrollment.user.last_name}",
                    'email': enrollment.user.email,
                    'has_joined': SessionAttendance.objects.filter(
                        session=instance,
                        user=enrollment.user
                    ).exists()
                })
        
        # Get attendance count
        attendance_count = SessionAttendance.objects.filter(
            session=instance
        ).distinct('user').count()
        
        data = LiveSessionSerializer(instance).data
        data['join_url'] = join_url
        data['enrolled_students'] = enrolled_students
        data['attendance_count'] = attendance_count
        data['is_moderator'] = True
        
        return Response(data)
    
    def start_session(self, request, *args, **kwargs):
        """Start a scheduled session"""
        instance = self.get_object()
        
        if instance.instructor != request.user:
            return Response(
                {'error': 'Only the instructor can start the session'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Update status to live
        instance.status = 'live'
        instance.actual_start = timezone.now()
        instance.save()
        
        # Create BBB meeting if not exists
        try:
            bbb_service = BBBService(instance.bbb_server)
            bbb_service.create_meeting(instance)
        except Exception as e:
            # Meeting might already exist
            pass
        
        return Response({
            'message': 'Session started successfully',
            'status': 'live',
            'started_at': instance.actual_start
        })
    
    def end_session(self, request, *args, **kwargs):
        """End a live session"""
        instance = self.get_object()
        
        if instance.instructor != request.user:
            return Response(
                {'error': 'Only the instructor can end the session'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Update status to ended
        instance.status = 'ended'
        instance.actual_end = timezone.now()
        instance.save()
        
        # End BBB meeting
        try:
            bbb_service = BBBService(instance.bbb_server)
            bbb_service.end_meeting(instance.meeting_id)
        except Exception as e:
            pass
        
        return Response({
            'message': 'Session ended successfully',
            'status': 'ended',
            'ended_at': instance.actual_end
        })


class StudentSessionViewSet(viewsets.ModelViewSet):
    """ViewSet for students to view and join sessions"""
    
    serializer_class = LiveSessionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Student can see sessions for their enrolled programmes"""
        from apps.learnerships.models import LearnershipEnrollment
        
        # Get enrolled programme IDs
        enrolled_programme_ids = LearnershipEnrollment.objects.filter(
            user=self.request.user,
            active=True
        ).values_list('programme_id', flat=True)
        
        return LiveSession.objects.filter(
            course_id__in=enrolled_programme_ids,
            course_type='learnership'
        ).order_by('-scheduled_start')
    
    def retrieve(self, request, *args, **kwargs):
        """Get session details with student join URL"""
        instance = self.get_object()

        # Check if student is enrolled in the programme
        from apps.learnerships.models import LearnershipEnrollment

        is_enrolled = LearnershipEnrollment.objects.filter(
            programme_id=instance.course_id,
            user=request.user,
            active=True
        ).exists()

        if not is_enrolled:
            return Response(
                {'error': 'You are not enrolled in this programme'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Generate join URL
        bbb_service = BBBService(instance.bbb_server)
        join_url = bbb_service.get_join_url(
            session=instance,
            user_name=f"{request.user.first_name} {request.user.last_name}",
            is_moderator=False
        )

        # Track attendance
        SessionAttendance.objects.get_or_create(
            session=instance,
            user=request.user,
            defaults={'joined_as_moderator': False}
        )

        data = LiveSessionSerializer(instance).data
        data['join_url'] = join_url
        data['is_moderator'] = False
        data['instructor_name'] = f"{instance.instructor.first_name} {instance.instructor.last_name}"

        return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_upcoming_sessions(request):
    """Get upcoming sessions for the user"""
    
    if hasattr(request.user, 'instructor_profile') or request.user.role == 'instructor':
        # Instructor view
        sessions = LiveSession.objects.filter(
            instructor=request.user,
            status='scheduled',
            scheduled_start__gte=timezone.now()
        ).order_by('scheduled_start')[:10]
        
        is_instructor = True
    else:
        # Student view
        from apps.learnerships.models import LearnershipEnrollment
        
        enrolled_programme_ids = LearnershipEnrollment.objects.filter(
            user=request.user,
            active=True
        ).values_list('programme_id', flat=True)
        
        sessions = LiveSession.objects.filter(
            course_id__in=enrolled_programme_ids,
            course_type='learnership',
            status='scheduled',
            scheduled_start__gte=timezone.now()
        ).order_by('scheduled_start')[:10]
        
        is_instructor = False
    
    serializer = LiveSessionSerializer(sessions, many=True)
    
    return Response({
        'sessions': serializer.data,
        'is_instructor': is_instructor,
        'count': sessions.count()
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def join_session(request, session_id):
    """Generate join URL for a session"""
    
    session = get_object_or_404(LiveSession, id=session_id)
    
    # Determine if user is instructor or student
    is_moderator = (session.instructor == request.user)
    
    if is_moderator:
        password = session.moderator_password
    else:
        # Check if student is enrolled
        from apps.learnerships.models import LearnershipEnrollment
        
        is_enrolled = LearnershipEnrollment.objects.filter(
            programme_id=session.course_id,
            user=request.user,
            active=True
        ).exists()
        
        if not is_enrolled:
            return Response(
                {'error': 'You are not enrolled in this programme'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        password = session.attendee_password
    
    # Generate join URL
    bbb_service = BBBService(session.bbb_server)
    join_url = bbb_service.get_join_url(
        meeting_id=session.meeting_id,
        full_name=f"{request.user.first_name} {request.user.last_name}",
        password=password,
        user_id=str(request.user.id),
        is_moderator=is_moderator
    )
    
    # Track attendance
    SessionAttendance.objects.get_or_create(
        session=session,
        user=request.user,
        defaults={'joined_as_moderator': is_moderator}
    )
    
    return Response({
        'join_url': join_url,
        'session_id': session.id,
        'session_title': session.title,
        'is_moderator': is_moderator,
        'scheduled_start': session.scheduled_start,
        'status': session.status
    })
