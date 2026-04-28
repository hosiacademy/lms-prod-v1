# apps/instructors/views.py

from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Count, Avg, Q
from django.utils import timezone
from django.contrib.auth import get_user_model
import logging

from .models import Instructor, CourseAssignment, InstructorRating
from .serializers import (
    InstructorSerializer,
    CourseAssignmentSerializer,
    InstructorRatingSerializer,
    PerformanceMetricsSerializer,
    AssignmentSuggestionSerializer
)
from .services import suggest_instructor_for_course, update_instructor_performance

logger = logging.getLogger(__name__)
User = get_user_model()


class InstructorViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing instructor profiles.
    """
    queryset = Instructor.objects.filter(is_active=True).select_related('user')
    serializer_class = InstructorSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()

        # Filter by department if provided
        department = self.request.query_params.get('department', None)
        if department:
            queryset = queryset.filter(department=department)

        # Filter by availability if provided
        is_available = self.request.query_params.get('is_available', None)
        if is_available is not None:
            queryset = queryset.filter(is_available=is_available.lower() == 'true')

        # Filter by performance band if provided
        performance_band = self.request.query_params.get('performance_band', None)
        if performance_band:
            queryset = queryset.filter(performance_band=performance_band)

        return queryset

    @action(detail=True, methods=['get'])
    def assignments(self, request, pk=None):
        """Get all assignments for a specific instructor."""
        instructor = self.get_object()
        assignments = instructor.course_assignments.all().select_related('course')
        serializer = CourseAssignmentSerializer(assignments, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def ratings(self, request, pk=None):
        """Get all ratings for a specific instructor."""
        instructor = self.get_object()
        ratings = instructor.ratings.all().select_related('student', 'course')
        serializer = InstructorRatingSerializer(ratings, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def update_performance(self, request, pk=None):
        """Update performance metrics for an instructor."""
        instructor = self.get_object()
        success = update_instructor_performance(instructor.id)

        if success:
            instructor.refresh_from_db()
            serializer = self.get_serializer(instructor)
            return Response(serializer.data)
        else:
            return Response(
                {'error': 'Failed to update performance metrics'},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['get'], permission_classes=[permissions.AllowAny])
    def public_list(self, request):
        """Public list of active instructors for the onboarding page."""
        limit = int(request.query_params.get('limit', 12))
        offset = int(request.query_params.get('offset', 0))
        qs = Instructor.objects.filter(is_active=True).select_related('user').order_by('-overall_rating')[offset:offset + limit]
        serializer = self.get_serializer(qs, many=True)
        return Response({'results': serializer.data, 'count': Instructor.objects.filter(is_active=True).count()})

    @action(detail=False, methods=['get'])
    def top_performers(self, request):
        """Get top performing instructors."""
        top_instructors = self.get_queryset().filter(
            overall_rating__gt=0
        ).order_by('-overall_rating')[:10]

        serializer = self.get_serializer(top_instructors, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def available(self, request):
        """Get available instructors."""
        from django.db.models import F
        available_instructors = self.get_queryset().filter(
            is_available=True
        ).annotate(
            current_count=Count('course_assignments', filter=Q(course_assignments__status__in=['assigned', 'ongoing']))
        ).order_by('-overall_rating')

        serializer = self.get_serializer(available_instructors, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get the current user's instructor profile."""
        try:
            profile = Instructor.objects.get(user=request.user)
            serializer = self.get_serializer(profile)
            return Response(serializer.data)
        except Instructor.DoesNotExist:
            return Response({'detail': 'Instructor profile not found.'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """
        Enhanced Instructor Dashboard - Comprehensive analytics and insights.
        GET /api/v1/instructors/profiles/dashboard/

        Returns complete dashboard data for instructor including:
        - Profile information
        - Comprehensive statistics and analytics
        - Assigned courses with enrollment data
        - Enrolled students with chat integration
        - Live sessions with attendance tracking
        - Performance metrics and insights
        - Recent activity and notifications
        """
        from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
        from apps.communication.models import Message as CommMessage, ChatRoom
        from apps.bbb_integration.models import LiveSession, SessionInvitation, SessionRecording, SessionAttendance
        from apps.courses.models import Course
        from django.db.models import Count, Avg, Sum, Q
        from datetime import timedelta

        # Check if user is an instructor by role_id (2 = Instructor)
        if not hasattr(request.user, 'role_id') or request.user.role_id != 2:
            return Response({'detail': 'Not an instructor.'}, status=status.HTTP_403_FORBIDDEN)

        # Get the instructor's profile
        try:
            profile = request.user.facilitator_profile
        except AttributeError:
            profile = None

        if not profile:
            return Response({'detail': 'No instructor profile found. Please contact administration.'}, status=status.HTTP_404_NOT_FOUND)

        # Get ONLY learnerships where this user is the assigned instructor
        learnerships = LearnershipProgramme.objects.filter(
            instructor=request.user,
            active=True
        )

        # ALSO get learnerships from sessions where this user is the instructor
        # (for cases where sessions exist but learnership.instructor is not set)
        session_course_ids = LiveSession.objects.filter(
            instructor=request.user,
            course_type='learnership'
        ).values_list('course_id', flat=True).distinct()
        
        if session_course_ids:
            learnerships_from_sessions = LearnershipProgramme.objects.filter(
                id__in=session_course_ids,
                active=True
            ).exclude(id__in=learnerships.values_list('id', flat=True))
            learnerships = learnerships | learnerships_from_sessions

        # Get students enrolled in instructor's learnerships
        learnership_ids = list(learnerships.values_list('id', flat=True))

        # Build comprehensive courses data
        courses_data = []
        total_enrolled_students = 0
        course_categories = {}

        for lp in learnerships:
            # Get enrollment count from ALL 4 pathways
            # 1. LearnershipEnrollment
            learnership_enrollments = LearnershipEnrollment.objects.filter(
                programme=lp,
                active=True
            ).count()
            
            # 2. ProvisionalEnrollments
            from apps.enrollments.models import ProvisionalEnrollment
            provisional_enrollments = ProvisionalEnrollment.objects.filter(
                programme=lp,
                status__in=['confirmed', 'provisional', 'cash_pending']
            ).count()
            
            # 3. Payment Enrollments (from enrollments table)
            from apps.payments.models import Enrollment as PaymentEnrollment
            payment_enrollments = PaymentEnrollment.objects.filter(
                object_id=lp.id,
                enrollment_type='learnership',
                status__in=['active', 'completed', 'pending_info']
            ).count()
            
            # 4. Industry/AICerts enrollments (if applicable)
            industry_enrollments = 0
            # Note: IndustryTrainingEnrollment model may not exist in all deployments
            
            # Total unique students across all pathways
            enrollment_count = learnership_enrollments + provisional_enrollments + payment_enrollments + industry_enrollments
            total_enrolled_students += enrollment_count

            # Track categories (default to "AI" if not set)
            category = lp.category or 'AI'
            if category not in course_categories:
                course_categories[category] = {'count': 0, 'students': 0}
            course_categories[category]['count'] += 1
            course_categories[category]['students'] += enrollment_count

            # Get session count for this course
            session_count = LiveSession.objects.filter(
                course_id=lp.id,
                course_type='learnership'
            ).count()

            # Get average session attendance
            avg_attendance = 0
            if session_count > 0:
                sessions_for_course = LiveSession.objects.filter(
                    course_id=lp.id,
                    course_type='learnership'
                )
                total_attendees = sum(
                    SessionAttendance.objects.filter(session=s).count()
                    for s in sessions_for_course
                )
                avg_attendance = total_attendees / session_count if session_count > 0 else 0

            courses_data.append({
                'id': lp.id,
                'title': lp.title,
                'slug': lp.slug,
                'status': lp.status,
                'start_date': str(lp.start_date) if lp.start_date else None,
                'end_date': str(lp.end_date) if lp.end_date else None,
                'enrolled_count': enrollment_count,
                'specialization': lp.specialization or '',
                'category': category,
                'nqf_level': lp.nqf_level or '',
                'duration_months': lp.duration_months,
                'delivery_mode': lp.delivery_mode,
                'session_count': session_count,
                'average_attendance': round(avg_attendance, 1),
                'completion_rate': 0,  # Will be calculated from completions
            })

        # Get ALL students from ALL 4 enrollment pathways
        enrolled_student_ids = set()
        student_details = {}

        if learnership_ids:
            # 1. LearnershipEnrollment pathway
            enrollments = LearnershipEnrollment.objects.filter(
                programme_id__in=learnership_ids,
                active=True
            ).select_related('user', 'programme')

            for enrollment in enrollments:
                if enrollment.user_id:
                    enrolled_student_ids.add(enrollment.user_id)
                    if enrollment.user_id not in student_details:
                        student_details[enrollment.user_id] = {
                            'programmes': [],
                            'enrollment_date': enrollment.enrolled_at,
                            'status': enrollment.status,
                            'pathways': ['learnership'],
                        }
                    else:
                        if 'learnership' not in student_details[enrollment.user_id]['pathways']:
                            student_details[enrollment.user_id]['pathways'].append('learnership')
                    student_details[enrollment.user_id]['programmes'].append({
                        'id': enrollment.programme.id,
                        'title': enrollment.programme.title,
                        'enrollment_date': enrollment.enrolled_at.isoformat(),
                        'status': enrollment.status,
                        'pathway': 'learnership',
                    })

            # 2. ProvisionalEnrollment pathway
            from apps.enrollments.models import ProvisionalEnrollment
            prov_enrollments = ProvisionalEnrollment.objects.filter(
                programme_id__in=learnership_ids,
                status__in=['confirmed', 'provisional', 'cash_pending']
            ).select_related('user', 'programme')

            for enrollment in prov_enrollments:
                if enrollment.user_id:
                    enrolled_student_ids.add(enrollment.user_id)
                    if enrollment.user_id not in student_details:
                        student_details[enrollment.user_id] = {
                            'programmes': [],
                            'enrollment_date': enrollment.created_at,
                            'status': enrollment.status,
                            'pathways': ['provisional'],
                        }
                    else:
                        if 'provisional' not in student_details[enrollment.user_id]['pathways']:
                            student_details[enrollment.user_id]['pathways'].append('provisional')
                    student_details[enrollment.user_id]['programmes'].append({
                        'id': enrollment.programme.id,
                        'title': enrollment.programme.title,
                        'enrollment_date': enrollment.created_at.isoformat(),
                        'status': enrollment.status,
                        'pathway': 'provisional',
                    })

            # 3. Payment Enrollment pathway (from enrollments table)
            from apps.payments.models import Enrollment as PaymentEnrollment
            payment_enrollments = PaymentEnrollment.objects.filter(
                object_id__in=learnership_ids,
                enrollment_type='learnership',
                status__in=['active', 'completed', 'pending_info']
            ).select_related('user')

            for enrollment in payment_enrollments:
                if enrollment.user_id:
                    enrolled_student_ids.add(enrollment.user_id)
                    if enrollment.user_id not in student_details:
                        student_details[enrollment.user_id] = {
                            'programmes': [],
                            'enrollment_date': enrollment.enrolled_at or enrollment.created_at,
                            'status': enrollment.status,
                            'pathways': ['payment'],
                        }
                    else:
                        if 'payment' not in student_details[enrollment.user_id]['pathways']:
                            student_details[enrollment.user_id]['pathways'].append('payment')
                    # Get course title from GenericForeignKey
                    course_title = 'Course'
                    try:
                        course_title = enrollment.content_object.title if enrollment.content_object else 'Course'
                    except:
                        pass
                    student_details[enrollment.user_id]['programmes'].append({
                        'id': enrollment.object_id,
                        'title': course_title,
                        'enrollment_date': (enrollment.enrolled_at or enrollment.created_at).isoformat(),
                        'status': enrollment.status,
                        'pathway': 'payment',
                    })

            # 4. Industry/AICerts enrollments - Not implemented (model doesn't exist)
            # Skip for now

        # Get students with chat data
        students_data = []
        unread_total = 0

        students = User.objects.filter(id__in=enrolled_student_ids).order_by('name', 'first_name')

        # Ensure chat rooms exist for all students
        from apps.communication.services import ChatRoomService
        for student in students:
            ChatRoomService.get_or_create_instructor_student_chat(
                instructor=request.user,
                student=student
            )

        # Get chat rooms with data
        for student in students:
            student_chat_room = ChatRoom.objects.filter(
                participants__user=student,
                chat_type='one_on_one'
            ).filter(
                participants__user=request.user
            ).first()

            unread_count = 0
            last_msg = None
            if student_chat_room:
                unread_count = CommMessage.objects.filter(
                    chat_room=student_chat_room,
                    receiver=request.user,
                    seen=False
                ).count()
                last_msg = student_chat_room.last_message

            unread_total += unread_count

            student_info = student_details.get(student.id, {})

            students_data.append({
                'id': student.id,
                'name': student.name or (student.first_name + ' ' + student.last_name).strip() or student.email,
                'email': student.email,
                'chat_room_id': student_chat_room.id if student_chat_room else None,
                'unread_count': unread_count,
                'last_message': last_msg.message[:80] if last_msg else None,
                'last_message_at': last_msg.created_at.isoformat() if last_msg else None,
                'last_message_from_me': last_msg.sender_id == request.user.id if last_msg else False,
                'is_enrolled_student': True,
                'programmes': student_info.get('programmes', []),
                'pathways': student_info.get('pathways', []),
                'enrollment_date': student_info.get('enrollment_date', '').isoformat() if student_info.get('enrollment_date') else None,
                'enrollment_status': student_info.get('status', 'active'),
            })

        # BBB Sessions - ONLY for this instructor's learnerships
        sessions = LiveSession.objects.filter(
            instructor=request.user,
            course_type='learnership',
            course_id__in=learnership_ids
        ).select_related('bbb_server').order_by('scheduled_start')

        # Get session statistics
        sessions_data = []
        total_session_attendees = 0
        total_recordings = 0
        upcoming_count = 0
        live_count = 0

        for s in sessions:
            # Get invitation stats
            invitation_count = SessionInvitation.objects.filter(
                session=s,
                status__in=['sent', 'opened', 'joined']
            ).count()
            joined_count = SessionInvitation.objects.filter(
                session=s,
                status='joined'
            ).count()
            recording_count = s.recordings.filter(published=True).count()
            total_recordings += recording_count

            # Get attendance count
            attendance_count = SessionAttendance.objects.filter(session=s).count()
            total_session_attendees += attendance_count

            if s.is_upcoming:
                upcoming_count += 1
            elif s.is_live_now:
                live_count += 1

            sessions_data.append({
                'id': s.id,
                'session_id': s.session_id,
                'meeting_id': s.meeting_id,
                'title': s.title,
                'description': s.description,
                'course_id': s.course_id,
                'course_type': s.course_type,
                'status': s.status,
                'scheduled_start': s.scheduled_start.isoformat() if s.scheduled_start else None,
                'scheduled_end': s.scheduled_end.isoformat() if s.scheduled_end else None,
                'actual_start': s.actual_start.isoformat() if s.actual_start else None,
                'actual_end': s.actual_end.isoformat() if s.actual_end else None,
                'duration_minutes': s.duration_minutes,
                'record': s.record,
                'has_recording': s.has_recording,
                'max_participants': s.max_participants,
                'moderator_password': s.moderator_password,
                'attendee_password': s.attendee_password,
                'invitation_count': invitation_count,
                'joined_count': joined_count,
                'attendance_count': attendance_count,
                'recording_count': recording_count,
                'is_upcoming': s.is_upcoming,
                'is_live_now': s.is_live_now,
                'join_url': f'/api/v1/bbb/sessions/{s.id}/join/',
                'start_url': f'/api/v1/bbb/sessions/{s.id}/start/',
            })

        # Calculate comprehensive analytics
        total_sessions = sessions.count()
        avg_session_attendance = total_session_attendees / total_sessions if total_sessions > 0 else 0

        # Get recent activity (last 7 days)
        seven_days_ago = timezone.now() - timedelta(days=7)
        recent_sessions = sessions.filter(scheduled_start__gte=seven_days_ago).count()
        recent_messages = CommMessage.objects.filter(
            chat_room__participants__user=request.user,
            created_at__gte=seven_days_ago
        ).count()

        # Build comprehensive stats
        stats = {
            'courses_count': len(courses_data),
            'students_count': len(students_data),
            'unread_messages': unread_total,
            'sessions_count': total_sessions,
            'upcoming_sessions': upcoming_count,
            'live_sessions': live_count,
            'total_recordings': total_recordings,
            'total_enrollments': total_enrolled_students,
            'average_session_attendance': round(avg_session_attendance, 1),
            'recent_activity': {
                'sessions_last_7_days': recent_sessions,
                'messages_last_7_days': recent_messages,
            },
            'course_categories': course_categories,
        }

        # Build performance metrics
        performance_metrics = {
            'overall_rating': profile.overall_rating,
            'performance_band': profile.performance_band,
            'average_student_rating': profile.average_student_rating,
            'completion_rate': profile.completion_rate,
            'total_courses_taught': profile.total_courses_taught,
            'total_students_taught': profile.total_students_taught,
            'utilization_rate': round(profile.utilization_rate, 1),
            'is_available': profile.is_available,
        }

        return Response({
            'profile': {
                'id': profile.id,
                'instructor_id': profile.instructor_id,
                'name': request.user.name or request.user.first_name,
                'email': request.user.email,
                'department': profile.department,
                'specialization': profile.specialization,
                'instructor_type': profile.instructor_type,
                'is_available': profile.is_available,
                'avatar_url': request.user.photo or request.user.image or request.user.avatar,
            },
            'stats': stats,
            'performance_metrics': performance_metrics,
            'courses': courses_data,
            'students': students_data,
            'sessions': sessions_data,
            'analytics': {
                'enrollment_trend': [],  # Can be populated with historical data
                'session_attendance_trend': [],  # Can be populated with historical data
                'category_breakdown': course_categories,
            },
        })

    @action(detail=False, methods=['get'])
    def my_students(self, request):
        """
        Get all students enrolled in instructor's courses.
        GET /api/v1/instructors/profiles/my_students/

        Returns detailed student information with enrollment data:
        - Student profile information
        - Enrolled programmes/courses
        - Enrollment status and dates
        - Chat integration data
        - Session attendance
        """
        from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
        from apps.communication.models import ChatRoom, Message as CommMessage
        from apps.bbb_integration.models import SessionAttendance
        from django.db.models import Prefetch

        # Check if user is an instructor
        if not hasattr(request.user, 'role_id') or request.user.role_id != 2:
            return Response({'detail': 'Not an instructor.'}, status=status.HTTP_403_FORBIDDEN)

        try:
            profile = request.user.facilitator_profile
        except AttributeError:
            profile = None

        if not profile:
            return Response({'detail': 'No instructor profile found.'}, status=status.HTTP_404_NOT_FOUND)

        # Get learnerships taught by this instructor
        learnerships = LearnershipProgramme.objects.filter(
            instructor=request.user,
            active=True
        )
        learnership_ids = list(learnerships.values_list('id', flat=True))

        if not learnership_ids:
            return Response({
                'count': 0,
                'students': [],
                'summary': {
                    'total_students': 0,
                    'active_students': 0,
                    'completed_students': 0,
                }
            })

        # Get all enrollments with student data
        enrollments = LearnershipEnrollment.objects.filter(
            programme_id__in=learnership_ids,
            active=True
        ).select_related('user', 'programme').order_by('user__name', 'user__email')

        # Group by student
        student_data = {}
        for enrollment in enrollments:
            if not enrollment.user_id:
                continue

            if enrollment.user_id not in student_data:
                student_data[enrollment.user_id] = {
                    'user': enrollment.user,
                    'programmes': [],
                    'enrollment_dates': [],
                    'statuses': [],
                }

            student_data[enrollment.user_id]['programmes'].append(enrollment.programme)
            student_data[enrollment.user_id]['enrollment_dates'].append(enrollment.enrolled_at)
            student_data[enrollment.user_id]['statuses'].append(enrollment.status)

        # Build student response
        students_list = []
        active_count = 0
        completed_count = 0

        for user_id, data in student_data.items():
            user = data['user']

            # Get chat room
            student_chat_room = ChatRoom.objects.filter(
                participants__user=user,
                chat_type='one_on_one'
            ).filter(
                participants__user=request.user
            ).first()

            unread_count = 0
            if student_chat_room:
                unread_count = CommMessage.objects.filter(
                    chat_room=student_chat_room,
                    receiver=request.user,
                    seen=False
                ).count()

            # Get session attendance count
            total_sessions_attended = SessionAttendance.objects.filter(
                user=user,
                session__instructor=request.user
            ).count()

            # Count statuses
            student_statuses = data['statuses']
            if 'completed' in student_statuses:
                completed_count += 1
            if any(s in ['active', 'confirmed', 'payment_complete'] for s in student_statuses):
                active_count += 1

            students_list.append({
                'id': user.id,
                'name': user.name or (user.first_name + ' ' + user.last_name).strip() or user.email,
                'email': user.email,
                'phone': user.phone or '',
                'avatar_url': user.photo or user.image or user.avatar,
                'chat_room_id': student_chat_room.id if student_chat_room else None,
                'unread_messages': unread_count,
                'programmes': [
                    {
                        'id': p.id,
                        'title': p.title,
                        'category': p.category,
                        'status': p.status,
                    }
                    for p in data['programmes']
                ],
                'enrollment_count': len(data['programmes']),
                'first_enrollment_date': min(data['enrollment_dates']).isoformat() if data['enrollment_dates'] else None,
                'enrollment_statuses': list(set(data['statuses'])),
                'sessions_attended': total_sessions_attended,
                'is_active': any(s in ['active', 'confirmed', 'payment_complete'] for s in student_statuses),
            })

        return Response({
            'count': len(students_list),
            'students': students_list,
            'summary': {
                'total_students': len(students_list),
                'active_students': active_count,
                'completed_students': completed_count,
            }
        })

    @action(detail=False, methods=['get'])
    def course_analytics(self, request):
        """
        Get detailed analytics for each course taught by the instructor.
        GET /api/v1/instructors/profiles/course_analytics/

        Returns:
        - Course breakdown by category
        - Enrollment trends
        - Session statistics
        - Student engagement metrics
        """
        from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
        from apps.bbb_integration.models import LiveSession, SessionAttendance, SessionRecording
        from django.db.models import Count, Avg, Q
        from datetime import timedelta

        # Check if user is an instructor
        if not hasattr(request.user, 'role_id') or request.user.role_id != 2:
            return Response({'detail': 'Not an instructor.'}, status=status.HTTP_403_FORBIDDEN)

        try:
            profile = request.user.facilitator_profile
        except AttributeError:
            profile = None

        if not profile:
            return Response({'detail': 'No instructor profile found.'}, status=status.HTTP_404_NOT_FOUND)

        # Get learnerships
        learnerships = LearnershipProgramme.objects.filter(
            instructor=request.user,
            active=True
        )

        # Category breakdown
        category_stats = {}
        course_analytics_list = []

        for lp in learnerships:
            category = lp.category or 'AI'

            # Get enrollment count
            enrollment_count = LearnershipEnrollment.objects.filter(
                programme=lp,
                active=True
            ).count()

            # Get sessions
            sessions = LiveSession.objects.filter(
                course_id=lp.id,
                course_type='learnership'
            )
            session_count = sessions.count()

            # Get attendance
            total_attendance = SessionAttendance.objects.filter(
                session__in=sessions
            ).count()
            avg_attendance = total_attendance / session_count if session_count > 0 else 0

            # Get recordings
            recording_count = SessionRecording.objects.filter(
                session__in=sessions,
                published=True
            ).count()

            # Get upcoming sessions
            upcoming_sessions = sessions.filter(
                status='scheduled',
                scheduled_start__gte=timezone.now()
            ).count()

            course_data = {
                'id': lp.id,
                'title': lp.title,
                'slug': lp.slug,
                'category': category,
                'status': lp.status,
                'nqf_level': lp.nqf_level,
                'duration_months': lp.duration_months,
                'enrollments': {
                    'total': enrollment_count,
                    'active': LearnershipEnrollment.objects.filter(
                        programme=lp,
                        active=True,
                        status__in=['active', 'confirmed', 'payment_complete']
                    ).count(),
                },
                'sessions': {
                    'total': session_count,
                    'upcoming': upcoming_sessions,
                    'completed': sessions.filter(status='ended').count(),
                    'average_attendance': round(avg_attendance, 1),
                },
                'recordings': {
                    'total': recording_count,
                },
                'start_date': str(lp.start_date) if lp.start_date else None,
                'end_date': str(lp.end_date) if lp.end_date else None,
            }

            course_analytics_list.append(course_data)

            # Aggregate category stats
            if category not in category_stats:
                category_stats[category] = {
                    'course_count': 0,
                    'total_enrollments': 0,
                    'total_sessions': 0,
                }
            category_stats[category]['course_count'] += 1
            category_stats[category]['total_enrollments'] += enrollment_count
            category_stats[category]['total_sessions'] += session_count

        return Response({
            'total_courses': len(learnerships),
            'categories': category_stats,
            'courses': course_analytics_list,
        })

    @action(detail=False, methods=['get'])
    def session_insights(self, request):
        """
        Get session logs and insights for instructor analytics.
        GET /api/v1/instructors/profiles/session_insights/

        Returns:
        - Session history with attendance
        - Recording analytics
        - Student engagement per session
        - Time-based trends
        """
        from apps.bbb_integration.models import LiveSession, SessionRecording, SessionAttendance, SessionInvitation
        from django.db.models import Count, Avg, Q
        from datetime import timedelta
        from django.utils import timezone

        # Check if user is an instructor
        if not hasattr(request.user, 'role_id') or request.user.role_id != 2:
            return Response({'detail': 'Not an instructor.'}, status=status.HTTP_403_FORBIDDEN)

        try:
            profile = request.user.facilitator_profile
        except AttributeError:
            profile = None

        if not profile:
            return Response({'detail': 'No instructor profile found.'}, status=status.HTTP_404_NOT_FOUND)

        # Get learnerships taught by instructor
        from apps.learnerships.models import LearnershipProgramme
        learnerships = LearnershipProgramme.objects.filter(
            instructor=request.user,
            active=True
        )
        learnership_ids = list(learnerships.values_list('id', flat=True))

        # Get all sessions
        sessions = LiveSession.objects.filter(
            instructor=request.user,
            course_type='learnership',
            course_id__in=learnership_ids
        ).select_related('bbb_server').order_by('-scheduled_start')

        # Time period filters
        period = request.query_params.get('period', 'all')  # all, week, month, quarter
        if period == 'week':
            sessions = sessions.filter(scheduled_start__gte=timezone.now() - timedelta(weeks=1))
        elif period == 'month':
            sessions = sessions.filter(scheduled_start__gte=timezone.now() - timedelta(days=30))
        elif period == 'quarter':
            sessions = sessions.filter(scheduled_start__gte=timezone.now() - timedelta(days=90))

        # Build session logs
        session_logs = []
        total_attendance = 0
        total_invitations = 0
        total_recordings = 0

        for session in sessions:
            # Get attendance
            attendance = SessionAttendance.objects.filter(session=session)
            attendance_count = attendance.count()
            total_attendance += attendance_count

            # Get invitations
            invitations = SessionInvitation.objects.filter(session=session)
            invitation_count = invitations.count()
            total_invitations += invitation_count
            joined_invitations = invitations.filter(status='joined').count()

            # Get recordings
            recordings = SessionRecording.objects.filter(session=session, published=True)
            recording_count = recordings.count()
            total_recordings += recording_count

            # Calculate engagement rate
            engagement_rate = 0
            if invitation_count > 0:
                engagement_rate = (joined_invitations / invitation_count) * 100

            session_logs.append({
                'id': session.id,
                'title': session.title,
                'course_id': session.course_id,
                'course_type': session.course_type,
                'scheduled_start': session.scheduled_start.isoformat() if session.scheduled_start else None,
                'scheduled_end': session.scheduled_end.isoformat() if session.scheduled_end else None,
                'status': session.status,
                'duration_minutes': session.duration_minutes,
                'attendance': {
                    'count': attendance_count,
                    'invitations': invitation_count,
                    'joined_via_invitation': joined_invitations,
                    'engagement_rate': round(engagement_rate, 1),
                },
                'recordings': {
                    'count': recording_count,
                    'total_duration': sum(r.duration_minutes for r in recordings),
                },
                'is_upcoming': session.is_upcoming,
                'is_live_now': session.is_live_now,
                'has_recording': session.has_recording,
            })

        # Calculate summary statistics
        total_sessions = sessions.count()
        completed_sessions = sessions.filter(status='ended').count()
        upcoming_sessions = sessions.filter(status='scheduled').count()
        avg_attendance = total_attendance / total_sessions if total_sessions > 0 else 0
        avg_engagement = (total_invitations / total_sessions if total_sessions > 0 else 0)

        # Group by course
        course_breakdown = {}
        for session in sessions:
            course_key = f"{session.course_id}_{session.course_type}"
            if course_key not in course_breakdown:
                course_breakdown[course_key] = {
                    'course_id': session.course_id,
                    'course_type': session.course_type,
                    'session_count': 0,
                    'total_attendance': 0,
                    'total_recordings': 0,
                }
            course_breakdown[course_key]['session_count'] += 1
            course_breakdown[course_key]['total_attendance'] += SessionAttendance.objects.filter(session=session).count()
            course_breakdown[course_key]['total_recordings'] += SessionRecording.objects.filter(
                session=session, published=True
            ).count()

        # Time-based trend (last 30 days)
        daily_stats = []
        for i in range(30):
            date = timezone.now().date() - timedelta(days=i)
            day_sessions = sessions.filter(
                scheduled_start__date=date
            )
            if day_sessions.exists():
                day_attendance = sum(
                    SessionAttendance.objects.filter(session=s).count()
                    for s in day_sessions
                )
                daily_stats.append({
                    'date': date.isoformat(),
                    'sessions_count': day_sessions.count(),
                    'total_attendance': day_attendance,
                })

        return Response({
            'summary': {
                'total_sessions': total_sessions,
                'completed_sessions': completed_sessions,
                'upcoming_sessions': upcoming_sessions,
                'total_attendance': total_attendance,
                'average_attendance_per_session': round(avg_attendance, 1),
                'total_invitations': total_invitations,
                'average_invitations_per_session': round(avg_engagement, 1),
                'total_recordings': total_recordings,
            },
            'course_breakdown': list(course_breakdown.values()),
            'daily_trend': daily_stats[:14],  # Last 2 weeks
            'session_logs': session_logs[:50],  # Last 50 sessions
        })

    @action(detail=False, methods=['get'])
    def performance_metrics(self, request):
        """
        Get comprehensive performance metrics for the instructor.
        GET /api/v1/instructors/profiles/performance_metrics/

        Returns:
        - Overall performance rating
        - Student feedback summary
        - Course completion rates
        - Session effectiveness
        - Activity timeline
        """
        from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
        from apps.bbb_integration.models import LiveSession, SessionAttendance, SessionRecording
        from django.db.models import Count, Avg, Q
        from datetime import timedelta
        from django.utils import timezone

        # Check if user is an instructor
        if not hasattr(request.user, 'role_id') or request.user.role_id != 2:
            return Response({'detail': 'Not an instructor.'}, status=status.HTTP_403_FORBIDDEN)

        try:
            profile = request.user.facilitator_profile
        except AttributeError:
            return Response({'detail': 'No instructor profile found.'}, status=status.HTTP_404_NOT_FOUND)

        # Get learnerships
        learnerships = LearnershipProgramme.objects.filter(
            instructor=request.user,
            active=True
        )
        learnership_ids = list(learnerships.values_list('id', flat=True))

        # Calculate enrollment completion rate
        total_enrollments = LearnershipEnrollment.objects.filter(
            programme_id__in=learnership_ids,
            active=True
        ).count()

        completed_enrollments = LearnershipEnrollment.objects.filter(
            programme_id__in=learnership_ids,
            active=True,
            status='completed'
        ).count()

        completion_rate = (completed_enrollments / total_enrollments * 100) if total_enrollments > 0 else 0

        # Get sessions
        sessions = LiveSession.objects.filter(
            instructor=request.user,
            course_type='learnership',
            course_id__in=learnership_ids
        )

        # Session metrics
        total_sessions = sessions.count()
        completed_sessions = sessions.filter(status='ended').count()

        # Attendance metrics
        total_attendance = sum(
            SessionAttendance.objects.filter(session=s).count()
            for s in sessions
        )
        avg_attendance_rate = (total_attendance / (total_sessions * 100)) * 100 if total_sessions > 0 else 0

        # Recording metrics
        total_recordings = SessionRecording.objects.filter(
            session__in=sessions,
            published=True
        ).count()
        recording_rate = (total_recordings / total_sessions * 100) if total_sessions > 0 else 0

        # Student feedback (from instructor ratings)
        from .models import InstructorRating
        ratings = InstructorRating.objects.filter(instructor=profile)
        avg_rating = ratings.aggregate(avg=Avg('rating'))['avg'] or 0
        total_reviews = ratings.count()

        # Activity timeline (last 30 days)
        thirty_days_ago = timezone.now() - timedelta(days=30)
        recent_sessions = sessions.filter(scheduled_start__gte=thirty_days_ago).count()
        recent_enrollments = LearnershipEnrollment.objects.filter(
            programme_id__in=learnership_ids,
            enrolled_at__gte=thirty_days_ago
        ).count()

        # Performance trends
        performance_trends = {
            'sessions_trend': 'stable',  # Can be calculated with historical comparison
            'enrollments_trend': 'stable',
            'attendance_trend': 'stable',
        }

        return Response({
            'instructor_id': profile.instructor_id,
            'overall_performance': {
                'rating': profile.overall_rating,
                'band': profile.performance_band,
                'last_review': str(profile.last_performance_review) if profile.last_performance_review else None,
            },
            'teaching_metrics': {
                'total_courses': learnerships.count(),
                'total_students': total_enrollments,
                'completion_rate': round(completion_rate, 1),
                'average_student_rating': round(avg_rating, 2),
                'total_reviews': total_reviews,
            },
            'session_metrics': {
                'total_sessions': total_sessions,
                'completed_sessions': completed_sessions,
                'average_attendance': round(total_attendance / total_sessions, 1) if total_sessions > 0 else 0,
                'attendance_rate': round(avg_attendance_rate, 1),
                'recording_rate': round(recording_rate, 1),
                'total_recordings': total_recordings,
            },
            'recent_activity': {
                'sessions_last_30_days': recent_sessions,
                'enrollments_last_30_days': recent_enrollments,
            },
            'performance_trends': performance_trends,
            'capacity': {
                'current_courses': learnerships.count(),
                'max_courses': profile.max_courses,
                'utilization_rate': round(profile.utilization_rate, 1),
                'is_available': profile.is_available,
            },
        })


class CourseAssignmentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing course assignments.
    """
    queryset = CourseAssignment.objects.all().select_related('instructor', 'course', 'assigned_by')
    serializer_class = CourseAssignmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        """Set the assigned_by user when creating an assignment."""
        serializer.save(assigned_by=self.request.user)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active assignments."""
        active_assignments = self.get_queryset().filter(
            status__in=['assigned', 'ongoing']
        )
        serializer = self.get_serializer(active_assignments, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def completed(self, request):
        """Get completed assignments within the last 30 days."""
        from django.utils import timezone
        from datetime import timedelta

        thirty_days_ago = timezone.now().date() - timedelta(days=30)
        completed_assignments = self.get_queryset().filter(
            status='completed',
            actual_end_date__gte=thirty_days_ago
        )
        serializer = self.get_serializer(completed_assignments, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark an assignment as completed."""
        assignment = self.get_object()

        if assignment.status == 'completed':
            return Response(
                {'error': 'Assignment is already completed'},
                status=status.HTTP_400_BAD_REQUEST
            )

        assignment.status = 'completed'
        assignment.actual_end_date = timezone.now().date()
        assignment.save()

        # Update instructor performance
        update_instructor_performance(assignment.instructor.id)

        serializer = self.get_serializer(assignment)
        return Response(serializer.data)


class InstructorRatingViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing instructor ratings.
    """
    queryset = InstructorRating.objects.all().select_related('instructor', 'course', 'student')
    serializer_class = InstructorRatingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        """Set the student when creating a rating."""
        serializer.save(student=self.request.user)


class AnalyticsViewSet(viewsets.ViewSet):
    """
    ViewSet for instructor analytics.
    """
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get summary analytics."""
        from django.db.models import Count, Avg

        # Basic counts
        total_instructors = Instructor.objects.filter(is_active=True).count()
        available_instructors = Instructor.objects.filter(
            is_active=True, is_available=True
        ).count()

        # Performance distribution
        performance_distribution = {}
        for band, display in Instructor.PERFORMANCE_RATINGS:
            count = Instructor.objects.filter(
                is_active=True,
                performance_band=band
            ).count()
            percentage = (count / total_instructors * 100) if total_instructors > 0 else 0
            performance_distribution[band] = {
                'display': display,
                'count': count,
                'percentage': round(percentage, 1)
            }

        # Assignments statistics
        active_assignments = CourseAssignment.objects.filter(
            status__in=['assigned', 'ongoing']
        ).count()

        from django.utils import timezone
        from datetime import timedelta
        thirty_days_ago = timezone.now().date() - timedelta(days=30)
        completed_assignments = CourseAssignment.objects.filter(
            status='completed',
            actual_end_date__gte=thirty_days_ago
        ).count()

        # Average ratings
        avg_rating = InstructorRating.objects.aggregate(avg=Avg('rating'))['avg'] or 0

        return Response({
            'total_instructors': total_instructors,
            'available_instructors': available_instructors,
            'active_assignments': active_assignments,
            'completed_assignments_last_30_days': completed_assignments,
            'average_rating': round(avg_rating, 1),
            'performance_distribution': performance_distribution
        })

    @action(detail=False, methods=['post'])
    def suggest_assignments(self, request):
        """Get assignment suggestions for courses."""
        from apps.courses.models import Course

        course_id = request.data.get('course_id')
        if not course_id:
            return Response(
                {'error': 'course_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            course = Course.objects.get(id=course_id)
        except Course.DoesNotExist:
            return Response(
                {'error': 'Course not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        suggestions = suggest_instructor_for_course(course, limit=5)

        # Prepare response data
        suggestion_data = []
        for instructor in suggestions:
            score = calculate_instructor_suitability(instructor, course)
            suggestion_data.append({
                'instructor': InstructorSerializer(instructor).data,
                'suitability_score': round(score, 1),
                'current_assignments': instructor.current_course_count,
                'utilization_rate': round(instructor.utilization_rate, 1)
            })

        return Response({
            'course': course.title,
            'suggestions': suggestion_data
        })


def calculate_instructor_suitability(instructor, course):
    """
    Helper function to calculate suitability score.
    """
    # This is a simplified version - same logic as in services.py
    score = 0.0

    # 1. Performance score (40% weight)
    performance_score = instructor.overall_rating * 0.4

    # 2. Availability score (30% weight)
    utilization = instructor.utilization_rate
    availability_score = max(0, 100 - utilization) * 0.3

    # 3. Experience score (20% weight)
    experience_score = min(instructor.years_experience * 2, 100) * 0.2

    # 4. Specialization match score (10% weight)
    specialization_score = 0.0
    if instructor.specialization and course.title:
        specialization_keywords = [kw.lower() for kw in instructor.specialization.split(',')]
        course_keywords = course.title.lower().split()
        matches = sum(1 for kw in specialization_keywords if any(kw in word for word in course_keywords))
        specialization_score = min(matches * 20, 100) * 0.1

    score = performance_score + availability_score + experience_score + specialization_score

    return min(score, 100)
