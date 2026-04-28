# apps/users/dashboard_serializers.py
"""
Role-specific dashboard data serializers.
ALL DATA FROM POSTGRESQL DATABASE - NO MOCK DATA.

Covers all 4 enrollment pathways:
1. Custom Selection (learner_portal)
2. Industry Training (industry_based_training)
3. Masterclasses (masterclasses)
4. Learnerships (learnerships)
Plus AICERTS integration

Supports role-based country/region filtering for HR Admins.
"""

from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db.models import Count, Avg, Q, F, Sum
from django.utils import timezone
from datetime import timedelta

User = get_user_model()


class ChatRoomSerializer(serializers.Serializer):
    """Chatroom data for dashboards"""
    def to_representation(self, room, current_user):
        from apps.communication.models import Message
        unread = Message.objects.filter(chat_room=room, seen=False, receiver=current_user).count()
        last_msg = Message.objects.filter(chat_room=room).order_by('-created_at').first()
        other = None
        if room.chat_type == 'one_on_one':
            op = room.participants.exclude(user=current_user).select_related('user').first()
            if op:
                other = {'id': op.user.id, 'name': op.user.name or op.user.email, 'email': op.user.email, 'role': 'student' if op.user.role_id == 3 else 'instructor'}
        
        # Get BBB session info for this chat room
        bbb_session_data = None
        if room.upcoming_bbb_session:
            session = room.upcoming_bbb_session
            bbb_session_data = {
                'id': session.id,
                'session_id': session.session_id,
                'meeting_id': session.meeting_id,
                'title': session.title,
                'scheduled_start': session.scheduled_start.isoformat(),
                'scheduled_end': session.scheduled_end.isoformat(),
                'duration_minutes': session.duration_minutes,
                'status': session.status,
                'is_live': session.status == 'live',
                'is_upcoming': session.status == 'scheduled',
                'join_url': f'/api/v1/bbb/sessions/{session.id}/join/',
            }
        elif room.bbb_session_info:
            bbb_session_data = room.bbb_session_info
        
        # Check for BBB session messages in this room
        from apps.bbb_integration.models import LiveSession
        bbb_messages = Message.objects.filter(
            chat_room=room, 
            bbb_session__isnull=False
        ).select_related('bbb_session').order_by('-created_at')[:3]
        
        recent_bbb_sessions = []
        for msg in bbb_messages:
            if msg.bbb_session and msg.bbb_session.id not in [s['id'] for s in recent_bbb_sessions]:
                session = msg.bbb_session
                recent_bbb_sessions.append({
                    'id': session.id,
                    'session_id': session.session_id,
                    'meeting_id': session.meeting_id,
                    'title': session.title,
                    'scheduled_start': session.scheduled_start.isoformat(),
                    'scheduled_end': session.scheduled_end.isoformat(),
                    'duration_minutes': session.duration_minutes,
                    'status': session.status,
                    'is_live': session.status == 'live',
                    'is_upcoming': session.status == 'scheduled',
                    'instructor_name': session.instructor.name if session.instructor else 'TBD',
                    'join_url': f'/api/v1/bbb/sessions/{session.id}/join/',
                    'message_preview': msg.message[:100] if msg else None,
                })
        
        return {
            'id': room.id, 'name': room.name, 'description': room.description, 'chat_type': room.chat_type,
            'course_app': room.course_app, 'course_model': room.course_model, 'course_id': room.course_id, 'course_title': room.course_title,
            'unread_count': unread, 'other_participant': other,
            'last_message': {'id': last_msg.id, 'message': last_msg.message[:100] if last_msg else None, 'sender_name': last_msg.sender.name if last_msg and last_msg.sender else None, 'created_at': last_msg.created_at.isoformat() if last_msg else None, 'bbb_session_id': last_msg.bbb_session.id if last_msg and last_msg.bbb_session else None} if last_msg else None,
            'upcoming_bbb_session': bbb_session_data,
            'recent_bbb_sessions': recent_bbb_sessions,
            'updated_at': room.updated_at.isoformat(),
        }


class InstructorDashboardSerializer(serializers.Serializer):
    """Instructor dashboard - ALL 4 PATHWAYS + AICERTS + BBB SESSIONS"""
    def to_representation(self, user):
        return {
            'role': 'instructor',
            'profile': self._get_profile(user),
            'assigned_learnerships': self._get_learnerships(user),
            'bbb_sessions': self._get_bbb_sessions(user),
            'students': self._get_students(user),
            'chatrooms': self._get_chatrooms(user),
            'stats': self._get_stats(user),
            'engagement': self._get_engagement(user),
        }

    def _get_profile(self, user):
        try:
            fp = user.facilitator_profile
            return {
                'facilitator_id': fp.facilitator_id, 'facilitator_type': fp.facilitator_type, 'department': fp.department,
                'specialization': fp.specialization, 'work_email': fp.work_email or user.email, 'is_available': fp.is_available,
                'overall_rating': round(fp.overall_rating, 2) if fp.overall_rating else 0.0,
                'total_courses_taught': fp.total_courses_taught or 0, 'total_students_taught': fp.total_students_taught or 0,
                'average_student_rating': round(fp.average_student_rating, 2) if fp.average_student_rating else 0.0,
                'completion_rate': round(fp.completion_rate, 2) if fp.completion_rate else 0.0,
            }
        except: return None

    def _get_learnerships(self, user):
        from apps.learnerships.models import LearnershipProgramme
        lps = LearnershipProgramme.objects.filter(instructor=user, active=True)
        return [{'id': lp.id, 'title': lp.title, 'specialization': lp.specialization, 'status': lp.status,
                 'start_date': lp.start_date.isoformat() if lp.start_date else None,
                 'end_date': lp.end_date.isoformat() if lp.end_date else None,
                 'student_count': lp.current_participants, 'active': lp.active} for lp in lps]

    def _get_bbb_sessions(self, user):
        """Get BBB sessions for instructor - upcoming and live sessions"""
        from apps.bbb_integration.models import LiveSession, SessionInvitation
        from apps.learnerships.models import LearnershipProgramme
        from django.utils import timezone
        from datetime import timedelta

        now = timezone.now()
        sessions = []

        # Get upcoming/live sessions for courses this instructor teaches
        # Get learnerships where user is instructor
        instructor_learnership_ids = list(LearnershipProgramme.objects.filter(
            instructor=user, active=True
        ).values_list('id', flat=True))

        if not instructor_learnership_ids:
            return sessions

        # Sessions from learnerships where user is instructor
        learner_sessions = LiveSession.objects.filter(
            course_type='learnership',
            course_id__in=instructor_learnership_ids,
            scheduled_start__gte=now - timedelta(hours=2),  # Include recently started sessions
            status__in=['scheduled', 'live']
        ).select_related('bbb_server').order_by('scheduled_start')

        for session in learner_sessions:
            # Get invited/enrolled students for this session
            invited_students = SessionInvitation.objects.filter(
                session=session,
                status__in=['sent', 'opened', 'joined']
            ).count()

            sessions.append({
                'id': session.id,
                'session_id': session.session_id,
                'meeting_id': session.meeting_id,
                'title': session.title,
                'description': session.description,
                'course_id': session.course_id,
                'course_type': session.course_type,
                'instructor_name': user.name or user.email,
                'scheduled_start': session.scheduled_start.isoformat(),
                'scheduled_end': session.scheduled_end.isoformat(),
                'duration_minutes': session.duration_minutes,
                'status': session.status,
                'is_live': session.status == 'live',
                'is_upcoming': session.status == 'scheduled',
                'invited_students_count': invited_students,
                'max_participants': session.max_participants,
                'moderator_password': session.moderator_password,
                'attendee_password': session.attendee_password,
                'join_url': f'/api/v1/bbb/sessions/{session.id}/join/',
                'start_url': f'/api/v1/bbb/sessions/{session.id}/start/',
            })

        return sessions

    def _get_students(self, user):
        """Get ALL students from instructor's learnerships + existing chat rooms"""
        from apps.learnerships.models import LearnershipEnrollment, LearnershipProgramme
        from apps.communication.models import ChatRoom, Message as CommMessage
        students = {}
        # From learnerships
        for lp in LearnershipProgramme.objects.filter(instructor=user, active=True):
            for enrol in LearnershipEnrollment.objects.filter(programme=lp, active=True).select_related('user'):
                if enrol.user.id not in students:
                    students[enrol.user.id] = {'id': enrol.user.id, 'name': enrol.user.name or enrol.user.email, 'email': enrol.user.email,
                        'role': 'student', 'programmes': [], 'unread_count': 0, 'last_message': None, 'last_message_at': None}
                students[enrol.user.id]['programmes'].append(lp.title)
        # From chat rooms
        for room in ChatRoom.objects.filter(participants__user=user, chat_type='one_on_one').prefetch_related('participants__user', 'last_message'):
            other = room.participants.exclude(user=user).select_related('user').first()
            if other and other.user.role_id == 3:
                s = other.user
                unread = CommMessage.objects.filter(chat_room=room, receiver=user, seen=False).count()
                lm = room.last_message
                if s.id not in students:
                    students[s.id] = {'id': s.id, 'name': s.name or s.email, 'email': s.email, 'role': 'student',
                        'programmes': [], 'unread_count': unread, 'last_message': lm.message[:80] if lm else None, 'last_message_at': lm.created_at.isoformat() if lm else None}
                else:
                    students[s.id]['unread_count'] = unread
                    if lm: students[s.id]['last_message'] = lm.message[:80]; students[s.id]['last_message_at'] = lm.created_at.isoformat()
        return list(students.values())

    def _get_chatrooms(self, user):
        from apps.communication.models import ChatRoom
        from apps.learnerships.models import LearnershipProgramme
        rooms = []
        ctx = {'request': type('obj', (object,), {'user': user})()}
        # Hosi Academy Community
        cr = ChatRoom.objects.filter(chat_type='community', name__icontains='Hosi Academy').first()
        if cr: rooms.append({'type': 'community', 'room': ChatRoomSerializer(context=ctx).to_representation(cr, user)})
        # Learnership course chats
        for lp in LearnershipProgramme.objects.filter(instructor=user, active=True):
            for room in ChatRoom.objects.filter(chat_type='course', course_id=lp.id, course_model='LearnershipProgramme'):
                rooms.append({'type': 'course', 'room': ChatRoomSerializer(context=ctx).to_representation(room, user)})
        # 1-on-1
        for room in ChatRoom.objects.filter(chat_type='one_on_one', participants__user=user).distinct().order_by('-updated_at')[:20]:
            rooms.append({'type': 'direct', 'room': ChatRoomSerializer(context=ctx).to_representation(room, user)})
        return rooms

    def _get_stats(self, user):
        from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
        lps = list(LearnershipProgramme.objects.filter(instructor=user, active=True).values_list('id', flat=True))
        total_students = LearnershipEnrollment.objects.filter(programme_id__in=lps, active=True).values('user_id').distinct().count() if lps else 0
        # Note: facilitator_profile removed - using Instructor table directly
        # Ratings will be calculated from actual instructor performance data
        return {'total_courses_taught': len(lps), 'total_students_taught': total_students,
            'average_student_rating': 0.0,  # Will be calculated from Learnership feedback
            'completion_rate': 0.0,  # Will be calculated from enrollment completion data
            'active_assignments': len(lps), 'overall_rating': 0.0}

    def _get_engagement(self, user):
        from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
        lps = list(LearnershipProgramme.objects.filter(instructor=user, active=True).values_list('id', flat=True))
        if not lps: return {'total_students': 0, 'active_students': 0, 'average_progress': 0.0, 'students_needing_attention': 0, 'engagement_rate': 0.0}
        total = LearnershipEnrollment.objects.filter(programme_id__in=lps, active=True).values('user_id').distinct().count()
        active = total  # Simplified - all active enrollments considered active
        return {'total_students': total, 'active_students': active, 'average_progress': 0.0, 'students_needing_attention': 0, 'engagement_rate': round((active / total * 100) if total > 0 else 0, 2)}


class StudentDashboardSerializer(serializers.Serializer):
    """Student dashboard - ALL 4 PATHWAYS + BBB SESSIONS"""
    def to_representation(self, user):
        return {'role': 'student', 'profile': self._get_profile(user),
            'enrollments': self._get_enrollments(user),
            'bbb_sessions': self._get_bbb_sessions(user),
            'chatrooms': self._get_chatrooms(user),
            'learning_progress': self._get_progress(user), 'stats': self._get_stats(user)}

    def _get_profile(self, user):
        return {'student_id': f'STU{user.id}', 'name': user.name or user.get_full_name() or user.username,
            'email': user.email, 'avatar': user.avatar or user.photo or user.image}

    def _get_enrollments(self, user):
        """Get ALL enrollments across 4 pathways + AICERTS"""
        enrollments = []
        # 1. AICERTS
        from apps.aicerts_integration.models import AICertsEnrollment
        from apps.aicerts_integration.services import SSOService
        for e in AICertsEnrollment.objects.filter(user=user).select_related('course'):
            # Generate SSO URL for course access (use lms_course_id for Moodle)
            sso_url = None
            if e.aicerts_enrollment_status == 'enrolled' and user.aicerts_user_id:
                try:
                    sso_url = SSOService.generate_sso_url(
                        email=user.email,
                        course_id=e.course.lms_course_id
                    )
                except Exception:
                    pass  # SSO URL generation failed, but still show the course
            enrollments.append({
                'id': e.course.id,
                'title': e.course.title,
                'type': 'aicerts',
                'progress': float(e.progress_percentage) if e.progress_percentage else 0,
                'status': e.aicerts_enrollment_status,
                'completed_at': e.completed_at.isoformat() if e.completed_at else None,
                'certificate_issued': e.certificate_issued_at is not None,
                'instructor': 'AICerts',
                'sso_url': sso_url,
                'lms_course_id': e.course.lms_course_id,
                'thumbnail_url': getattr(e.course, 'feature_image_url', None),
            })
        # 2. Learnerships
        from apps.learnerships.models import LearnershipEnrollment
        for e in LearnershipEnrollment.objects.filter(user=user, active=True).select_related('programme'):
            enrollments.append({'id': e.programme.id, 'title': e.programme.title, 'type': 'learnership', 'status': 'active',
                'start_date': e.programme.start_date.isoformat() if e.programme.start_date else None,
                'end_date': e.programme.end_date.isoformat() if e.programme.end_date else None,
                'instructor': e.programme.instructor.name if e.programme.instructor else 'TBD'})
        # 3. Masterclasses (via ProvisionalEnrollment)
        from apps.enrollments.models import ProvisionalEnrollment
        for e in ProvisionalEnrollment.objects.filter(user=user, enrollment_type='masterclass').select_related('programme'):
            enrollments.append({'id': e.programme.id if e.programme else None, 'title': e.programme.title if e.programme else 'Masterclass',
                'type': 'masterclass', 'status': e.status, 'instructor': 'Hosi Academy'})
        # 4. Industry Training
        for e in ProvisionalEnrollment.objects.filter(user=user, enrollment_type='industry').select_related('programme'):
            enrollments.append({'id': e.programme.id if e.programme else None, 'title': e.programme.title if e.programme else 'Industry Training',
                'type': 'industry', 'status': e.status, 'instructor': 'Hosi Academy'})
        # 5. Custom Selection
        for e in ProvisionalEnrollment.objects.filter(user=user, enrollment_type='custom_selection').select_related('programme'):
            enrollments.append({'id': e.programme.id if e.programme else None, 'title': e.programme.title if e.programme else 'Custom Course',
                'type': 'custom_selection', 'status': e.status, 'instructor': 'Hosi Academy'})
        return enrollments

    def _get_bbb_sessions(self, user):
        """Get BBB sessions for student - sessions they're invited to or enrolled in courses"""
        from apps.bbb_integration.models import LiveSession, SessionInvitation
        from apps.learnerships.models import LearnershipEnrollment, LearnershipProgramme
        from django.utils import timezone
        from datetime import timedelta
        
        now = timezone.now()
        sessions = []
        seen_session_ids = set()
        
        # 1. Get sessions from SessionInvitations (direct invites)
        invitations = SessionInvitation.objects.filter(
            email=user.email,
            status__in=['sent', 'opened', 'joined']
        ).select_related('session__bbb_server')
        
        for invitation in invitations:
            session = invitation.session
            if session.id in seen_session_ids:
                continue
            seen_session_ids.add(session.id)
            
            sessions.append({
                'id': session.id,
                'session_id': session.session_id,
                'meeting_id': session.meeting_id,
                'title': session.title,
                'description': session.description,
                'course_id': session.course_id,
                'course_type': session.course_type,
                'instructor_name': session.instructor.name if session.instructor else 'TBD',
                'scheduled_start': session.scheduled_start.isoformat(),
                'scheduled_end': session.scheduled_end.isoformat(),
                'duration_minutes': session.duration_minutes,
                'status': session.status,
                'is_live': session.status == 'live',
                'is_upcoming': session.status == 'scheduled',
                'invitation_status': invitation.status,
                'invitation_token': invitation.invitation_token,
                'max_participants': session.max_participants,
                'attendee_password': session.attendee_password,
                'join_url': f'/api/v1/bbb/sessions/{session.id}/join/',
                'accept_invitation_url': f'/api/v1/bbb/student/accept_invitation/',
            })
        
        # 2. Get sessions from enrolled learnerships (even without direct invitation)
        enrolled_programme_ids = list(LearnershipEnrollment.objects.filter(
            user=user, active=True
        ).values_list('programme_id', flat=True))
        
        if enrolled_programme_ids:
            learner_sessions = LiveSession.objects.filter(
                course_type='learnership',
                course_id__in=enrolled_programme_ids,
                scheduled_start__gte=now - timedelta(hours=2),
                scheduled_start__lte=now + timedelta(days=30),  # Next 30 days
                status__in=['scheduled', 'live']
            ).select_related('instructor', 'bbb_server').order_by('scheduled_start')
            
            for session in learner_sessions:
                if session.id in seen_session_ids:
                    continue
                seen_session_ids.add(session.id)
                
                # Check if student has accepted invitation
                invitation = SessionInvitation.objects.filter(
                    session=session, email=user.email
                ).first()
                
                sessions.append({
                    'id': session.id,
                    'session_id': session.session_id,
                    'meeting_id': session.meeting_id,
                    'title': session.title,
                    'description': session.description,
                    'course_id': session.course_id,
                    'course_type': session.course_type,
                    'instructor_name': session.instructor.name if session.instructor else 'TBD',
                    'scheduled_start': session.scheduled_start.isoformat(),
                    'scheduled_end': session.scheduled_end.isoformat(),
                    'duration_minutes': session.duration_minutes,
                    'status': session.status,
                    'is_live': session.status == 'live',
                    'is_upcoming': session.status == 'scheduled',
                    'invitation_status': invitation.status if invitation else 'auto_enrolled',
                    'invitation_token': invitation.invitation_token if invitation else None,
                    'max_participants': session.max_participants,
                    'attendee_password': session.attendee_password,
                    'join_url': f'/api/v1/bbb/sessions/{session.id}/join/',
                    'accept_invitation_url': f'/api/v1/bbb/student/accept_invitation/' if invitation else None,
                })
        
        # Sort by scheduled start time
        sessions.sort(key=lambda x: x['scheduled_start'])
        
        return sessions

    def _get_chatrooms(self, user):
        from apps.communication.models import ChatRoom, ChatParticipant
        from apps.learnerships.models import LearnershipEnrollment
        rooms = []
        ctx = {'request': type('obj', (object,), {'user': user})()}
        # Hosi Academy Community
        cr = ChatRoom.objects.filter(chat_type='community', name__icontains='Hosi Academy').first()
        if cr: rooms.append({'type': 'community', 'room': ChatRoomSerializer(context=ctx).to_representation(cr, user)})
        # Course chats (from Learnerships)
        lp_ids = list(LearnershipEnrollment.objects.filter(user=user, active=True).values_list('programme_id', flat=True))
        for room in ChatRoom.objects.filter(chat_type='course', course_id__in=lp_ids, course_model='LearnershipProgramme'):
            rooms.append({'type': 'course', 'room': ChatRoomSerializer(context=ctx).to_representation(room, user)})
        # 1-on-1
        for room in ChatRoom.objects.filter(chat_type='one_on_one', participants__user=user).select_related('last_message').distinct().order_by('-updated_at')[:20]:
            other = ChatParticipant.objects.filter(chat_room=room).exclude(user=user).select_related('user').first()
            rtype = 'instructor' if other and other.user.role_id == 2 else 'peer'
            rooms.append({'type': rtype, 'room': ChatRoomSerializer(context=ctx).to_representation(room, user)})
        return rooms

    def _get_progress(self, user):
        from apps.aicerts_integration.models import AICertsEnrollment
        enrols = AICertsEnrollment.objects.filter(user=user)
        total, completed = enrols.count(), enrols.filter(completed_at__isnull=False).count()
        in_prog = enrols.filter(completed_at__isnull=True, aicerts_enrollment_status='enrolled').count()
        avg = enrols.aggregate(avg=Avg('progress_percentage'))['avg'] or 0
        return {'total_courses': total, 'completed_courses': completed, 'in_progress_courses': in_prog,
            'average_progress': round(avg, 2), 'completion_rate': round((completed / total * 100) if total > 0 else 0, 2)}

    def _get_stats(self, user):
        from apps.aicerts_integration.models import AICertsEnrollment
        from django.db.models import Sum
        total = AICertsEnrollment.objects.filter(user=user).count()
        completed = AICertsEnrollment.objects.filter(user=user, completed_at__isnull=False).count()
        certs = AICertsEnrollment.objects.filter(user=user, certificate_issued_at__isnull=False).count()
        tp = AICertsEnrollment.objects.filter(user=user).aggregate(sum=Sum('progress_percentage'))['sum'] or 0
        return {'total_enrolled': total, 'completed': completed, 'in_progress': total - completed,
            'certificates_earned': certs, 'estimated_learning_hours': round(tp / 100 * 20, 1)}


class AdminDashboardSerializer(serializers.Serializer):
    """
    Admin/Executive dashboard - System-wide metrics across ALL pathways.
    Supports multi-country filtering for all admin roles.
    System Admin (superuser) has unrestricted access to all countries.

    Usage:
        # For admin with country restriction
        serializer = AdminDashboardSerializer(context={
            'country_filter': Q(country_id__in=[1, 2, 3]),
            'selected_country_id': 1  # Optional: filter to specific country
        })

        # For superuser/system admin (no filter)
        serializer = AdminDashboardSerializer()
    """
    def to_representation(self, user):
        country_filter = self.context.get('country_filter', Q())
        selected_country_id = self.context.get('selected_country_id', None)
        return {
            'role': 'admin',
            'system_stats': self._get_system(user, country_filter, selected_country_id),
            'user_metrics': self._get_users(country_filter, selected_country_id),
            'pathway_metrics': self._get_pathways(country_filter, selected_country_id),
            'geographic_metrics': self._get_geographic(country_filter, selected_country_id),
            'revenue_metrics': self._get_revenue(country_filter, selected_country_id),
            'engagement': self._get_engagement(country_filter, selected_country_id),
            'country_context': self._get_country_context(user, country_filter, selected_country_id)
        }

    def _get_system(self, user, country_filter=Q(), selected_country_id=None):
        from apps.aicerts_integration.models import AICertsEnrollment
        from apps.aicerts_courses.models import AiCertsCourse

        # Apply country filter to user counts if specified
        user_country_filter = Q()
        if country_filter:
            user_country_filter = country_filter
        elif selected_country_id:
            user_country_filter = Q(country_id=selected_country_id)

        return {
            'total_users': User.objects.filter(user_country_filter).count() if user_country_filter else User.objects.count(),
            'total_students': User.objects.filter(user_country_filter, role_id=3).count() if user_country_filter else User.objects.filter(role_id=3).count(),
            'total_instructors': User.objects.filter(user_country_filter, role_id=2).count() if user_country_filter else User.objects.filter(role_id=2).count(),
            'total_admins': User.objects.filter(user_country_filter, Q(role_id=1) | Q(is_superuser=True)).count() if user_country_filter else User.objects.filter(Q(role_id=1) | Q(is_superuser=True)).count(),
            'total_courses': AiCertsCourse.objects.count(),  # Courses are global
            'total_enrollments': AICertsEnrollment.objects.count()  # Enrollments are global
        }

    def _get_users(self, country_filter=Q(), selected_country_id=None):
        now = timezone.now()
        # Apply country filter if specified
        user_filter = country_filter if country_filter else Q()
        if selected_country_id and not user_filter:
            user_filter = Q(country_id=selected_country_id)

        base_filter = user_filter if user_filter else Q()
        return {
            'new_users_week': User.objects.filter(base_filter, date_joined__gte=now - timedelta(days=7)).count(),
            'new_users_month': User.objects.filter(base_filter, date_joined__gte=now - timedelta(days=30)).count(),
            'active_users_week': User.objects.filter(base_filter, last_login__gte=now - timedelta(days=7)).count()
        }

    def _get_pathways(self, country_filter=Q(), selected_country_id=None):
        from apps.enrollments.models import ProvisionalEnrollment
        from apps.learnerships.models import LearnershipEnrollment
        from apps.users.filters import filter_queryset_by_user_country

        # Use helper to properly apply country filter through the 'user' relation
        pe_qs = filter_queryset_by_user_country(
            self.context.get('request').user if self.context.get('request') else None,
            ProvisionalEnrollment.objects.all(),
            country_field='user__country_id',
            selected_country_id=selected_country_id
        )
        # For system operations where no request is passed but filter is active
        if not self.context.get('request') and country_filter:
            if 'country_id__in' in str(country_filter):
                country_ids = country_filter.children[0][1] if country_filter.children else []
                pe_qs = ProvisionalEnrollment.objects.filter(user__country_id__in=country_ids)
            elif 'country_id' in str(country_filter):
                country_id = country_filter.children[0][1] if country_filter.children else None
                pe_qs = ProvisionalEnrollment.objects.filter(user__country_id=country_id)

        le_qs = filter_queryset_by_user_country(
            self.context.get('request').user if self.context.get('request') else None,
            LearnershipEnrollment.objects.filter(active=True),
            country_field='user__country_id',
            selected_country_id=selected_country_id
        )
        if not self.context.get('request') and country_filter:
            if 'country_id__in' in str(country_filter):
                country_ids = country_filter.children[0][1] if country_filter.children else []
                le_qs = LearnershipEnrollment.objects.filter(active=True, user__country_id__in=country_ids)
            elif 'country_id' in str(country_filter):
                country_id = country_filter.children[0][1] if country_filter.children else None
                le_qs = LearnershipEnrollment.objects.filter(active=True, user__country_id=country_id)

        return {
            'masterclass': pe_qs.filter(enrollment_type='masterclass').count(),
            'industry': pe_qs.filter(enrollment_type='industry').count(),
            'learnership': le_qs.count(),
            'custom_selection': pe_qs.filter(enrollment_type='custom_selection').count()
        }

    def _get_geographic(self, country_filter=Q(), selected_country_id=None):
        from django.db.models import Count
        from apps.masterclasses.models import Masterclass
        from apps.localization.models import Country

        # If specific country is selected, show only that country's data
        if selected_country_id:
            country = Country.objects.filter(id=selected_country_id).first()
            if country:
                return {
                    'by_country': [{
                        'country_code': country.code,
                        'country_name': country.name,
                        'count': 1,
                        'is_restricted': True
                    }],
                    'is_restricted': True,
                    'restricted_country': country.name,
                    'selected_country_id': selected_country_id
                }

        # If country filter has specific IDs, show only those
        if country_filter and 'country_id__in' in str(country_filter):
            # Extract country IDs from filter
            country_ids = []
            for q in country_filter.children:
                if hasattr(q, 'lhs') and 'country_id__in' in str(q.lhs):
                    country_ids = list(q.rhs) if hasattr(q.rhs, '__iter__') else []
                    break

            if country_ids:
                countries = Country.objects.filter(id__in=country_ids)
                by_country = []
                for c in countries:
                    by_country.append({
                        'country_code': c.code,
                        'country_name': c.name,
                        'count': 1,
                        'is_restricted': True
                    })
                return {
                    'by_country': by_country,
                    'is_restricted': True,
                    'multi_country_view': True
                }

        # Default: show all countries
        by_country = Masterclass.objects.values('country_code').annotate(count=Count('id')).order_by('-count')[:10]
        return {'by_country': list(by_country), 'is_restricted': False}

    def _get_revenue(self, country_filter=Q(), selected_country_id=None):
        from apps.payments.models import PaymentTransaction
        now = timezone.now()

        # Apply country filter if specified
        filter_kwargs = {'created_at__gte': now.replace(day=1), 'status': 'successful'}
        # Revenue filtering by country would require joining with user/company tables
        # This can be extended based on business requirements

        mtd = PaymentTransaction.objects.filter(**filter_kwargs).aggregate(sum=Sum('amount'))['sum'] or 0
        return {'revenue_mtd': float(mtd), 'revenue_ytd': 0}

    def _get_engagement(self, country_filter=Q(), selected_country_id=None):
        from apps.aicerts_integration.models import AICertsEnrollment
        now = timezone.now()

        # Apply country filter if specified
        filter_kwargs = {'last_accessed_at__gte': now - timedelta(days=7)}
        if country_filter and 'user__country_id' in str(country_filter):
            # Extract country ID from filter
            for q in country_filter.children:
                if hasattr(q, 'lhs') and 'country_id' in str(q.lhs):
                    filter_kwargs['user__country_id'] = q.rhs
                    break
        elif selected_country_id:
            filter_kwargs['user__country_id'] = selected_country_id

        active = AICertsEnrollment.objects.filter(**filter_kwargs).values('user_id').distinct().count()
        return {'active_learners_week': active, 'average_platform_progress': 0, 'engagement_rate': 0}

    def _get_country_context(self, user, country_filter=Q(), selected_country_id=None):
        """Return country context information for the frontend"""
        from apps.users.filters import get_dashboard_country_context

        # Use the centralized filter function for consistency
        return get_dashboard_country_context(user, selected_country_id)


def build_dashboard_data(user, request=None, selected_country_id=None):
    """
    Returns role-appropriate dashboard data - ALL FROM DATABASE.
    Applies country/region filtering for all admin roles.
    System Admin (superuser) has unrestricted access.

    Args:
        user: The authenticated user
        request: Optional request object to extract country filter from
        selected_country_id: Optional specific country ID to filter by (for multi-country admins)

    Returns:
        dict: Dashboard data filtered by role and country access
    """
    from apps.users.filters import get_user_country_filter, get_allowed_countries

    if user.role_id == 2:
        return InstructorDashboardSerializer().to_representation(user)
    elif user.role_id == 3:
        return StudentDashboardSerializer().to_representation(user)
    elif user.role_id == 1 or user.is_superuser:
        # Admin/Executive - apply country filter based on role and country access
        country_filter = get_user_country_filter(user, selected_country_id)
        
        # If no specific country selected but user has multi-country access,
        # pass the selected_country_id for proper context
        context = {
            'country_filter': country_filter,
            'selected_country_id': selected_country_id
        }
        
        return AdminDashboardSerializer(context=context).to_representation(user)
    return {'role': 'unknown', 'error': 'Unknown role'}
