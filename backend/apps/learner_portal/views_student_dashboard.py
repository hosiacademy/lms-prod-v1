# apps/learner_portal/views_student_dashboard.py
"""
Comprehensive Student Dashboard - Insightful Learning Portal
ALL DATA FROM POSTGRESQL DATABASE - NO MOCK DATA

Endpoint: GET /api/v1/student-portal/dashboard/complete/

Provides complete student dashboard functionality including:
- Student profile with academic information
- All enrollments across 5 pathways
- Learning progress and certificates
- BBB live sessions
- Chat rooms and communication
- Payment overview
- Wishlist and cart
- Course recommendations
- Notifications
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Count, Avg, Q, Sum, F
from django.db.utils import ProgrammingError
from django.core.exceptions import ObjectDoesNotExist
from django.utils import timezone
from datetime import timedelta
from django.contrib.auth import get_user_model
import logging

logger = logging.getLogger(__name__)
User = get_user_model()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def complete_student_dashboard(request):
    """
    Comprehensive Student Dashboard Endpoint
    GET /api/v1/student-portal/dashboard/complete/
    
    Returns complete dashboard data for student including:
    - Profile information with academic details
    - Comprehensive statistics and analytics
    - All enrollments (5 pathways)
    - Learning progress and certificates
    - Live sessions with attendance tracking
    - Chat rooms and messages
    - Payment overview and history
    - Wishlist and cart
    - Course recommendations
    - Notifications
    """
    from apps.learnerships.models import LearnershipEnrollment, LearnershipProgramme
    from apps.aicerts_integration.models import AICertsEnrollment
    from apps.enrollments.models import ProvisionalEnrollment
    from apps.masterclasses.models import Masterclass
    from apps.industry_based_training.models import Industry, Offering
    from apps.bbb_integration.models import LiveSession, SessionInvitation, SessionAttendance, SessionRecording
    from apps.communication.models import ChatRoom, Message as CommMessage, ChatParticipant
    from apps.communication.services import ChatRoomService
    from apps.certificates.models import Certificate
    from apps.payments.models import Order, PaymentTransaction
    from apps.learner_portal.models import Wishlist, CourseCart, CourseCartItem
    from apps.courses.models import Course
    from apps.aicerts_courses.models import AiCertsCourse
    from django.contrib.contenttypes.models import ContentType
    
    user = request.user
    
    # ==========================================
    # 1. STUDENT PROFILE
    # ==========================================
    profile_data = _get_student_profile(user)
    
    # ==========================================
    # 2. COMPREHENSIVE STATS
    # ==========================================
    stats = _get_student_stats(user)
    
    # ==========================================
    # 3. ALL ENROLLMENTS (5 Pathways)
    # ==========================================
    enrollments_data = _get_all_enrollments(user)
    
    # ==========================================
    # 4. LEARNING PROGRESS & CERTIFICATES
    # ==========================================
    progress_data = _get_learning_progress(user)
    certificates_data = _get_certificates(user)
    
    # ==========================================
    # 5. BBB LIVE SESSIONS
    # ==========================================
    bbb_sessions_data = _get_student_bbb_sessions(user)
    
    # ==========================================
    # 6. CHAT ROOMS & COMMUNICATION
    # ==========================================
    chatrooms_data = _get_chat_rooms(user)
    instructors_data = _get_instructors(user)
    
    # ==========================================
    # 7. PAYMENT OVERVIEW
    # ==========================================
    payment_data = _get_payment_overview(user)
    
    # ==========================================
    # 8. WISHLIST & CART
    # ==========================================
    wishlist_data = _get_wishlist(user)
    cart_data = _get_cart(user)
    
    # ==========================================
    # 9. COURSE RECOMMENDATIONS
    # ==========================================
    recommendations_data = _get_recommendations(user)
    
    # ==========================================
    # 10. NOTIFICATIONS
    # ==========================================
    notifications_data = _get_notifications(user)
    
    # ==========================================
    # 11. ACADEMIC SUPPORT & RESOURCES
    # ==========================================
    academic_support_data = _get_academic_support(user)
    
    # ==========================================
    # 12. COMPLIANCE & DOCUMENTATION
    # ==========================================
    compliance_data = _get_compliance_status(user)
    
    return Response({
        'role': 'student',
        'profile': profile_data,
        'stats': stats,
        'enrollments': enrollments_data,
        'progress': progress_data,
        'certificates': certificates_data,
        'bbb_sessions': bbb_sessions_data,
        'chatrooms': chatrooms_data,
        'instructors': instructors_data,
        'payment_overview': payment_data,
        'wishlist': wishlist_data,
        'cart': cart_data,
        'recommendations': recommendations_data,
        'notifications': notifications_data,
        'academic_support': academic_support_data,
        'compliance_status': compliance_data,
    })


def _get_student_profile(user):
    """Get comprehensive student profile with academic information"""
    from apps.learnerships.models import LearnershipEnrollment
    
    # Get latest enrollment for academic info
    latest_enrollment = LearnershipEnrollment.objects.filter(
        user=user
    ).order_by('-enrolled_at').first()
    
    profile = {
        'student_id': f'STU{user.id:05d}',
        'id': user.id,
        'name': user.name or (user.first_name + ' ' + user.last_name).strip() or user.email,
        'email': user.email,
        'phone': getattr(user, 'phone', None),
        'avatar_url': user.avatar or user.photo or user.image,
        'role_id': getattr(user, 'role_id', 3),
        'country': getattr(user, 'country', None),
        'city': getattr(user, 'city', None),
        'created_at': user.date_joined.isoformat() if user.date_joined else None,
    }
    
    # Academic & Employment Information (from latest learnership enrollment)
    if latest_enrollment:
        profile['academic_info'] = {
            'highest_qualification': latest_enrollment.highest_qualification,
            'qualification_institution': latest_enrollment.qualification_institution,
            'qualification_year': latest_enrollment.qualification_year,
            'education_level': latest_enrollment.education_level,
            'employer': latest_enrollment.employer,
            'job_title': latest_enrollment.job_title,
            'employment_status': latest_enrollment.employment_status,
            'monthly_income': latest_enrollment.monthly_income,
            'existing_skills': latest_enrollment.existing_skills,
        }
        
        # Demographics
        profile['demographics'] = {
            'race': latest_enrollment.race,
            'disability': latest_enrollment.disability,
            'nationality': latest_enrollment.nationality,
        }
        
        # Next of Kin
        profile['next_of_kin'] = {
            'name': latest_enrollment.next_of_kin_name,
            'phone': latest_enrollment.next_of_kin_phone,
            'relationship': latest_enrollment.next_of_kin_relationship,
            'email': latest_enrollment.next_of_kin_email,
            'address': latest_enrollment.next_of_kin_address,
        }
        
        # Medical & Accessibility
        profile['medical_accessibility'] = {
            'medical_conditions': latest_enrollment.medical_conditions,
            'allergies': latest_enrollment.allergies,
            'medications': latest_enrollment.medications,
            'accessibility_needs': latest_enrollment.accessibility_needs,
            'requires_learning_support': latest_enrollment.requires_learning_support,
            'learning_support_details': latest_enrollment.learning_support_details,
        }
    else:
        profile['academic_info'] = {}
        profile['demographics'] = {}
        profile['next_of_kin'] = {}
        profile['medical_accessibility'] = {}
    
    return profile


def _get_student_stats(user):
    """Get comprehensive student statistics"""
    from apps.learnerships.models import LearnershipEnrollment
    from apps.aicerts_integration.models import AICertsEnrollment
    from apps.enrollments.models import ProvisionalEnrollment
    from apps.bbb_integration.models import SessionInvitation
    from apps.communication.models import Message as CommMessage
    from django.db.utils import ProgrammingError
    
    # Enrollment counts
    learnership_count = LearnershipEnrollment.objects.filter(
        user=user, active=True
    ).count()
    
    aicerts_count = AICertsEnrollment.objects.filter(user=user).count()
    aicerts_completed = AICertsEnrollment.objects.filter(
        user=user, completed_at__isnull=False
    ).count()
    
    masterclass_count = ProvisionalEnrollment.objects.filter(
        user=user, enrollment_type='masterclass'
    ).count()
    
    industry_count = ProvisionalEnrollment.objects.filter(
        user=user, enrollment_type='industry'
    ).count()
    
    custom_count = ProvisionalEnrollment.objects.filter(
        user=user, enrollment_type='custom_selection'
    ).count()
    
    total_enrolled = learnership_count + aicerts_count + masterclass_count + industry_count + custom_count
    
    # Certificates (handle if table doesn't exist)
    certificates_count = 0
    try:
        from apps.certificates.models import Certificate
        certificates_count = Certificate.objects.filter(user=user).count()
    except (ProgrammingError, ImportError):
        pass  # Certificates table not created yet
    
    # Upcoming sessions
    now = timezone.now()
    upcoming_sessions_count = SessionInvitation.objects.filter(
        email=user.email,
        status__in=['sent', 'opened', 'joined']
    ).filter(
        session__scheduled_start__gte=now,
        session__status__in=['scheduled', 'live']
    ).count()
    
    # Unread messages
    from apps.communication.models import ChatRoom
    my_rooms = ChatRoom.objects.filter(
        participants__user=user,
        chat_type='one_on_one'
    ).values_list('id', flat=True)
    
    unread_messages = CommMessage.objects.filter(
        chat_room_id__in=my_rooms,
        receiver=user,
        seen=False
    ).count()
    
    # Payment status
    pending_payments = ProvisionalEnrollment.objects.filter(
        user=user,
        status__in=['cash_pending', 'provisional']
    ).count()
    
    # Calculate total learning hours (estimated from progress)
    total_progress = AICertsEnrollment.objects.filter(
        user=user
    ).aggregate(total=Sum('progress_percentage'))['total'] or 0
    
    # Assuming 20 hours per course at 100%
    estimated_learning_hours = round(float(total_progress) / 100 * 20, 1)
    
    return {
        'total_enrolled': total_enrolled,
        'learnerships': learnership_count,
        'aicerts_courses': aicerts_count,
        'aicerts_completed': aicerts_completed,
        'masterclasses': masterclass_count,
        'industry_courses': industry_count,
        'custom_courses': custom_count,
        'certificates_earned': certificates_count,
        'upcoming_sessions': upcoming_sessions_count,
        'unread_messages': unread_messages,
        'pending_payments': pending_payments,
        'estimated_learning_hours': estimated_learning_hours,
    }


def _get_all_enrollments(user):
    """Get ALL enrollments across 5 pathways with comprehensive details"""
    from apps.aicerts_integration.services import SSOService
    from apps.aicerts_integration.models import AICertsEnrollment
    from apps.learnerships.models import LearnershipEnrollment
    from apps.enrollments.models import ProvisionalEnrollment
    from apps.masterclasses.models import Masterclass

    enrollments = []

    # 1. AICERTS Courses
    aicerts_enrollments = AICertsEnrollment.objects.filter(
        user=user
    ).select_related('course')
    
    for enr in aicerts_enrollments:
        sso_url = None
        if enr.aicerts_enrollment_status == 'enrolled' and user.aicerts_user_id:
            try:
                sso_url = SSOService.generate_sso_url(
                    email=user.email,
                    course_id=enr.course.lms_course_id
                )
            except Exception:
                pass
        
        enrollments.append({
            'id': enr.course.id if enr.course else enr.id,
            'title': enr.course.title if enr.course else 'AICerts Course',
            'type': 'aicerts',
            'progress': float(enr.progress_percentage) if enr.progress_percentage else 0,
            'status': enr.aicerts_enrollment_status,
            'enrolled_at': enr.enrolled_at.isoformat() if enr.enrolled_at else None,
            'completed_at': enr.completed_at.isoformat() if enr.completed_at else None,
            'certificate_issued': enr.certificate_issued_at is not None,
            'instructor': 'AICerts',
            'sso_url': sso_url,
            'lms_course_id': enr.course.lms_course_id if enr.course else None,
            'thumbnail_url': getattr(enr.course, 'feature_image_url', None) if enr.course else None,
            'synced_at': enr.synced_at.isoformat() if enr.synced_at else None,
        })
    
    # 2. Learnership Programmes
    learnership_enrollments = LearnershipEnrollment.objects.filter(
        user=user, active=True
    ).select_related('programme__instructor')
    
    for enr in learnership_enrollments:
        lp = enr.programme
        enrollments.append({
            'id': lp.id,
            'title': lp.title,
            'slug': lp.slug,
            'type': 'learnership',
            'status': enr.status,
            'enrollment_type': enr.enrollment_type,
            'enrolled_at': enr.enrolled_at.isoformat() if enr.enrolled_at else None,
            'confirmed_at': enr.confirmed_at.isoformat() if enr.confirmed_at else None,
            'completed_at': enr.completed_at.isoformat() if enr.completed_at else None,
            'start_date': lp.start_date.isoformat() if lp.start_date else None,
            'end_date': lp.end_date.isoformat() if lp.end_date else None,
            'specialization': lp.specialization,
            'nqf_level': lp.nqf_level,
            'duration_months': lp.duration_months,
            'delivery_mode': lp.delivery_mode,
            'instructor': lp.instructor.name if lp.instructor else 'TBD',
            'instructor_id': lp.instructor.id if lp.instructor else None,
            'payment_status': enr.payment_status,
            'payment_plan_type': enr.payment_plan_type,
            'prerequisites_verified': enr.prerequisites_verified,
            'active': enr.active,
        })
    
    # 3. Masterclasses (via ProvisionalEnrollment)
    masterclass_enrollments = ProvisionalEnrollment.objects.filter(
        user=user,
        enrollment_type='masterclass',
        status__in=['confirmed', 'provisional', 'cash_pending']
    ).select_related('payment_transaction')
    
    for enr in masterclass_enrollments:
        mc_id = enr.metadata.get('masterclass_id')
        if mc_id:
            try:
                mc = Masterclass.objects.get(id=mc_id)
                enrollments.append({
                    'id': mc.id,
                    'title': mc.title,
                    'type': 'masterclass',
                    'status': enr.status,
                    'enrolled_at': enr.created_at.isoformat() if enr.created_at else None,
                    'start_date': mc.start_date.isoformat() if mc.start_date else None,
                    'end_date': mc.end_date.isoformat() if mc.end_date else None,
                    'location': f'{mc.city}, {mc.country_name}' if mc.city else mc.country_name,
                    'venue': mc.venue,
                    'stream_type': mc.stream_type,
                    'tier': mc.tier,
                    'price_physical': str(mc.price_physical),
                    'price_online': str(mc.price_online),
                    'enrollment_status': enr.status,
                    'payment_status': 'paid' if enr.payment_transaction else 'pending',
                    'instructor': 'Hosi Academy',
                })
            except Masterclass.DoesNotExist:
                pass
    
    # 4. Industry Training
    industry_enrollments = ProvisionalEnrollment.objects.filter(
        user=user,
        enrollment_type='industry',
        status__in=['confirmed', 'provisional']
    )
    
    for enr in industry_enrollments:
        # Get industry course from metadata or programme
        industry_course_id = enr.metadata.get('industry_course_id') or enr.programme_id
        if industry_course_id:
            from apps.industry_based_training.models import AiCertsCourse as IndustryCourse
            try:
                course = IndustryCourse.objects.get(id=industry_course_id)
                enrollments.append({
                    'id': course.id,
                    'title': course.title,
                    'type': 'industry',
                    'status': enr.status,
                    'enrolled_at': enr.created_at.isoformat() if enr.created_at else None,
                    'industry': course.industry.name if course.industry else None,
                    'description': course.description,
                    'price_usd': str(course.price_usd) if course.price_usd else None,
                    'thumbnail_url': course.feature_image_url,
                    'certificate_badge_url': course.certificate_badge_url,
                    'instructor': 'Hosi Academy',
                })
            except IndustryCourse.DoesNotExist:
                pass
    
    # 5. Custom Selection
    custom_enrollments = ProvisionalEnrollment.objects.filter(
        user=user,
        enrollment_type='custom_selection',
        status__in=['confirmed', 'provisional']
    )
    
    for enr in custom_enrollments:
        # Get selected courses from metadata
        selected_courses = enr.metadata.get('selected_courses', [])
        for course_item in selected_courses:
            enrollments.append({
                'id': course_item.get('id'),
                'title': course_item.get('title', 'Custom Course'),
                'type': 'custom_selection',
                'status': enr.status,
                'enrolled_at': enr.created_at.isoformat() if enr.created_at else None,
                'price': course_item.get('price'),
                'category': course_item.get('category'),
                'instructor': 'Hosi Academy',
            })
    
    return enrollments


def _get_learning_progress(user):
    """Get comprehensive learning progress across all pathways"""
    from apps.aicerts_integration.models import AICertsEnrollment
    from apps.analytics.models import UserProgress
    
    # AICERTS Progress
    aicerts_enrollments = AICertsEnrollment.objects.filter(user=user)
    total_courses = aicerts_enrollments.count()
    completed_courses = aicerts_enrollments.filter(
        completed_at__isnull=False
    ).count()
    in_progress = aicerts_enrollments.filter(
        completed_at__isnull=True,
        aicerts_enrollment_status='enrolled'
    ).count()
    
    avg_progress = aicerts_enrollments.aggregate(
        avg=Avg('progress_percentage')
    )['avg'] or 0
    
    # Calculate completion rate
    completion_rate = round(
        (completed_courses / total_courses * 100) if total_courses > 0 else 0,
        2
    )
    
    # UserProgress table (for learnerships and other courses)
    user_progress_records = UserProgress.objects.filter(user=user)
    learnership_progress = []
    
    for prog in user_progress_records:
        if prog.learnership:
            learnership_progress.append({
                'learnership_id': prog.learnership.id,
                'learnership_title': prog.learnership.title,
                'progress_percentage': prog.progress_percentage,
                'last_accessed': prog.last_accessed.isoformat() if prog.last_accessed else None,
            })
    
    return {
        'total_courses': total_courses,
        'completed_courses': completed_courses,
        'in_progress_courses': in_progress,
        'average_progress': round(avg_progress, 2),
        'completion_rate': completion_rate,
        'learnership_progress': learnership_progress,
    }


def _get_certificates(user):
    """Get all issued certificates"""
    from django.db.utils import ProgrammingError
    
    try:
        from apps.certificates.models import Certificate
        
        certificates = Certificate.objects.filter(
            user=user
        ).select_related('course', 'template').order_by('-issued_at')
        
        return [
            {
                'certificate_id': str(cert.certificate_id),
                'verification_code': cert.verification_code,
                'verification_url': f'/verify-certificate/{cert.verification_code}/',
                'course_name': cert.course_name,
                'student_name': cert.student_name,
                'completion_date': cert.completion_date.isoformat() if cert.completion_date else None,
                'grade': cert.grade,
                'pdf_url': cert.pdf_url,
                'thumbnail_url': cert.thumbnail_url,
                'issued_at': cert.issued_at.isoformat() if cert.issued_at else None,
            }
            for cert in certificates
        ]
    except (ProgrammingError, ImportError):
        return []  # Certificates table not created yet


def _get_student_bbb_sessions(user):
    """Get BBB sessions for student - comprehensive session data"""
    from apps.bbb_integration.models import LiveSession, SessionInvitation, SessionAttendance, SessionRecording
    from apps.learnerships.models import LearnershipEnrollment
    from django.utils import timezone
    from datetime import timedelta
    
    now = timezone.now()
    sessions = []
    seen_session_ids = set()
    
    # 1. Get sessions from SessionInvitations (direct invites)
    invitations = SessionInvitation.objects.filter(
        email=user.email,
        status__in=['sent', 'opened', 'joined']
    ).select_related('session__bbb_server', 'session__instructor')
    
    for invitation in invitations:
        session = invitation.session
        if session.id in seen_session_ids:
            continue
        seen_session_ids.add(session.id)
        
        # Get attendance record
        attendance = SessionAttendance.objects.filter(
            session=session,
            user=user
        ).first()
        
        # Get recordings
        recordings = SessionRecording.objects.filter(
            session=session,
            published=True
        )
        
        sessions.append({
            'id': session.id,
            'session_id': session.session_id,
            'meeting_id': session.meeting_id,
            'title': session.title,
            'description': session.description,
            'course_id': session.course_id,
            'course_type': session.course_type,
            'instructor_name': session.instructor.name if session.instructor else 'TBD',
            'instructor_id': session.instructor.id if session.instructor else None,
            'scheduled_start': session.scheduled_start.isoformat() if session.scheduled_start else None,
            'scheduled_end': session.scheduled_end.isoformat() if session.scheduled_end else None,
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
            'attended': attendance is not None if session.status == 'ended' else None,
            'has_recording': recordings.exists(),
            'recordings': [
                {
                    'id': rec.id,
                    'name': rec.name,
                    'playback_url': rec.playback_url,
                    'duration_minutes': rec.duration_minutes,
                    'thumbnail_url': rec.thumbnail_url,
                    'size_mb': rec.size_mb,
                }
                for rec in recordings
            ],
        })
    
    # 2. Get sessions from enrolled learnerships (auto-enrolled)
    enrolled_programme_ids = list(LearnershipEnrollment.objects.filter(
        user=user, active=True
    ).values_list('programme_id', flat=True))
    
    if enrolled_programme_ids:
        learner_sessions = LiveSession.objects.filter(
            course_type='learnership',
            course_id__in=enrolled_programme_ids,
            scheduled_start__gte=now - timedelta(hours=2),
            scheduled_start__lte=now + timedelta(days=30),
            status__in=['scheduled', 'live']
        ).select_related('instructor', 'bbb_server').order_by('scheduled_start')
        
        for session in learner_sessions:
            if session.id in seen_session_ids:
                continue
            seen_session_ids.add(session.id)
            
            invitation = SessionInvitation.objects.filter(
                session=session, email=user.email
            ).first()
            
            attendance = SessionAttendance.objects.filter(
                session=session,
                user=user
            ).first()
            
            recordings = SessionRecording.objects.filter(
                session=session,
                published=True
            )
            
            sessions.append({
                'id': session.id,
                'session_id': session.session_id,
                'meeting_id': session.meeting_id,
                'title': session.title,
                'description': session.description,
                'course_id': session.course_id,
                'course_type': session.course_type,
                'instructor_name': session.instructor.name if session.instructor else 'TBD',
                'instructor_id': session.instructor.id if session.instructor else None,
                'scheduled_start': session.scheduled_start.isoformat() if session.scheduled_start else None,
                'scheduled_end': session.scheduled_end.isoformat() if session.scheduled_end else None,
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
                'attended': attendance is not None if session.status == 'ended' else None,
                'has_recording': recordings.exists(),
                'recordings': [
                    {
                        'id': rec.id,
                        'name': rec.name,
                        'playback_url': rec.playback_url,
                        'duration_minutes': rec.duration_minutes,
                        'thumbnail_url': rec.thumbnail_url,
                        'size_mb': rec.size_mb,
                    }
                    for rec in recordings
                ],
            })
    
    # Sort by scheduled start time
    sessions.sort(key=lambda x: x.get('scheduled_start') or '')
    
    return sessions


def _get_chat_rooms(user):
    """Get all chat rooms for student"""
    from apps.communication.models import ChatRoom, ChatParticipant, Message as CommMessage
    from apps.learnerships.models import LearnershipEnrollment
    
    rooms = []
    ctx = {'request': type('obj', (object,), {'user': user})()}
    
    # Import ChatRoomSerializer
    from apps.users.dashboard_serializers import ChatRoomSerializer
    
    # 1. Hosi Academy Community
    community_room = ChatRoom.objects.filter(
        chat_type='community',
        name__icontains='Hosi Academy'
    ).first()
    
    if community_room:
        rooms.append({
            'type': 'community',
            'room': ChatRoomSerializer(context=ctx).to_representation(community_room, user)
        })
    
    # 2. Course-specific chats (from Learnerships)
    enrolled_lp_ids = list(LearnershipEnrollment.objects.filter(
        user=user, active=True
    ).values_list('programme_id', flat=True))
    
    for room in ChatRoom.objects.filter(
        chat_type='course',
        course_id__in=enrolled_lp_ids,
        course_model='LearnershipProgramme'
    ):
        rooms.append({
            'type': 'course',
            'room': ChatRoomSerializer(context=ctx).to_representation(room, user)
        })
    
    # 3. 1-on-1 chats (instructors and peers)
    one_on_one_rooms = ChatRoom.objects.filter(
        chat_type='one_on_one',
        participants__user=user
    ).select_related('last_message').distinct().order_by('-updated_at')[:20]
    
    for room in one_on_one_rooms:
        other = ChatParticipant.objects.filter(
            chat_room=room
        ).exclude(user=user).select_related('user').first()
        
        room_type = 'peer'
        if other and other.user.role_id == 2:
            room_type = 'instructor'
        
        rooms.append({
            'type': room_type,
            'room': ChatRoomSerializer(context=ctx).to_representation(room, user)
        })
    
    return rooms


def _get_instructors(user):
    """Get all instructors for student (from enrolled courses)"""
    from apps.learnerships.models import LearnershipEnrollment, LearnershipProgramme
    from apps.communication.models import ChatRoom
    from apps.communication.models import Message as CommMessage
    from apps.communication.services import ChatRoomService
    
    instructor_ids = set()
    
    # Get instructors from enrolled learnerships
    enrolled_lps = LearnershipEnrollment.objects.filter(
        user=user, active=True
    ).select_related('programme__instructor')
    
    for enrollment in enrolled_lps:
        if enrollment.programme.instructor:
            instructor_ids.add(enrollment.programme.instructor.id)
    
    # Get instructor details
    instructors_data = []
    instructors = User.objects.filter(
        id__in=instructor_ids
    ).select_related('facilitator_profile')
    
    for instructor in instructors:
        # Ensure chat room exists
        ChatRoomService.get_or_create_instructor_student_chat(
            instructor=instructor,
            student=user
        )
        
        # Get chat room
        chat_room = ChatRoom.objects.filter(
            participants__user=instructor,
            chat_type='one_on_one'
        ).filter(
            participants__user=user
        ).first()
        
        # Get unread messages
        unread_count = 0
        last_msg = None
        if chat_room:
            unread_count = CommMessage.objects.filter(
                chat_room=chat_room,
                receiver=user,
                seen=False
            ).count()
            last_msg = chat_room.last_message
        
        instructors_data.append({
            'id': instructor.id,
            'name': instructor.name or (instructor.first_name + ' ' + instructor.last_name).strip() or instructor.email,
            'email': instructor.email,
            'role': 'instructor',
            'specialization': instructor.facilitator_profile.specialization if hasattr(instructor, 'facilitator_profile') and instructor.facilitator_profile else None,
            'department': instructor.facilitator_profile.department if hasattr(instructor, 'facilitator_profile') and instructor.facilitator_profile else None,
            'chat_room_id': chat_room.id if chat_room else None,
            'unread_count': unread_count,
            'last_message': last_msg.message[:80] if last_msg else None,
            'last_message_at': last_msg.created_at.isoformat() if last_msg else None,
            'last_message_from_me': last_msg.sender_id == user.id if last_msg else False,
        })
    
    return instructors_data


def _get_payment_overview(user):
    """Get comprehensive payment overview"""
    from apps.learnerships.models import LearnershipEnrollment
    from apps.enrollments.models import ProvisionalEnrollment
    from apps.payments.models import Order, PaymentTransaction
    
    # Pending payments
    pending_learnerships = LearnershipEnrollment.objects.filter(
        user=user,
        payment_status__in=['pending', 'cash_promise', 'partial_paid']
    )
    
    pending_provisional = ProvisionalEnrollment.objects.filter(
        user=user,
        status__in=['cash_pending', 'provisional']
    )
    
    pending_payments = []
    
    for enr in pending_learnerships:
        pending_payments.append({
            'type': 'learnership',
            'id': enr.programme.id,
            'title': enr.programme.title,
            'status': enr.payment_status,
            'payment_plan_type': enr.payment_plan_type,
            'amount_paid': str(enr.amount_paid) if enr.amount_paid else None,
            'deposit_paid': str(enr.deposit_paid) if enr.deposit_paid else None,
            'debit_order_active': enr.debit_order_active,
            'cash_payment_reference': enr.cash_payment_reference,
            'cash_payment_due_date': enr.cash_payment_due_date.isoformat() if enr.cash_payment_due_date else None,
        })
    
    for enr in pending_provisional:
        pending_payments.append({
            'type': 'provisional',
            'id': enr.programme.id if enr.programme else None,
            'title': enr.programme.title if enr.programme else 'Course',
            'status': enr.status,
            'reference_code': enr.reference_code,
            'expires_at': enr.expires_at.isoformat() if enr.expires_at else None,
        })
    
    # Order history (without select_related on payment_transaction)
    orders = Order.objects.filter(
        user=user
    ).order_by('-created_at')[:10]
    
    order_history = []
    for order in orders:
        # Get payment transaction separately if it exists
        payment_status = None
        try:
            if hasattr(order, 'payment_transaction') and order.payment_transaction:
                payment_status = order.payment_transaction.status
        except (AttributeError, ObjectDoesNotExist):
            pass
        
        order_history.append({
            'order_id': str(order.id),
            'total_amount': str(order.total_amount) if hasattr(order, 'total_amount') else '0',
            'status': order.status,
            'payment_method': order.payment_method if hasattr(order, 'payment_method') else None,
            'payment_status': payment_status,
            'created_at': order.created_at.isoformat() if order.created_at else None,
            'items_count': order.items.count() if hasattr(order, 'items') else 0,
        })
    
    # Total spent
    successful_transactions = PaymentTransaction.objects.filter(
        user=user,
        status='successful'
    ).aggregate(total=Sum('amount'))['total'] or 0
    
    return {
        'pending_payments': pending_payments,
        'pending_count': len(pending_payments),
        'order_history': order_history,
        'total_spent': str(successful_transactions),
    }


def _get_wishlist(user):
    """Get user's wishlist"""
    from apps.learner_portal.models import Wishlist
    
    wishlist_items = Wishlist.objects.filter(
        user=user
    ).select_related('content_type').order_by('-created_at')
    
    items = []
    for item in wishlist_items:
        enrolled_item = item.get_enrolled_item()
        items.append({
            'id': item.id,
            'content_type': item.content_type.model,
            'object_id': item.object_id,
            'title': enrolled_item.title if enrolled_item else 'Unknown',
            'price': getattr(enrolled_item, 'cost_usd', None) or getattr(enrolled_item, 'price_usd', None),
            'thumbnail_url': getattr(enrolled_item, 'image_url', None) or getattr(enrolled_item, 'feature_image_url', None),
            'added_at': item.created_at.isoformat() if item.created_at else None,
        })
    
    return items


def _get_cart(user):
    """Get user's active cart"""
    from apps.learner_portal.models import CourseCart, CourseCartItem
    
    cart = CourseCart.objects.filter(
        user=user,
        status='active'
    ).first()
    
    if not cart:
        return None
    
    cart_items = CourseCartItem.objects.filter(
        cart=cart
    ).select_related('content_type')
    
    items = []
    for item in cart_items:
        enrolled_item = item.get_enrolled_item()
        items.append({
            'id': item.id,
            'title': enrolled_item.title if enrolled_item else 'Unknown',
            'price': str(item.price),
            'thumbnail_url': getattr(enrolled_item, 'image_url', None) or getattr(enrolled_item, 'feature_image_url', None),
        })
    
    return {
        'cart_id': cart.id,
        'items': items,
        'items_count': items.count(),
        'total_amount': str(cart.total_amount),
        'status': cart.status,
    }


def _get_recommendations(user):
    """Get course recommendations for student"""
    from apps.aicerts_courses.models import AiCertsCourse
    from apps.masterclasses.models import Masterclass
    from apps.learnerships.models import LearnershipProgramme
    
    recommendations = {
        'recommended_courses': [],
        'upcoming_masterclasses': [],
        'open_learnerships': [],
    }
    
    # Get enrolled categories for personalization
    from apps.aicerts_integration.models import AICertsEnrollment
    enrolled_courses = AICertsEnrollment.objects.filter(
        user=user
    ).select_related('course')
    
    enrolled_category_ids = set()
    for enr in enrolled_courses:
        if enr.course:
            enrolled_category_ids.add(enr.course.category_id)
    
    # Recommended AICERTS courses (same categories, not enrolled)
    if enrolled_category_ids:
        recommended = AiCertsCourse.objects.filter(
            category_id__in=enrolled_category_ids,
            active=True
        ).exclude(
            id__in=[enr.course_id for enr in enrolled_courses if enr.course_id]
        )[:5]
        
        for course in recommended:
            recommendations['recommended_courses'].append({
                'id': course.id,
                'title': course.title,
                'category': course.category.name if course.category else None,
                'thumbnail_url': course.feature_image_url,
                'price_individual': str(course.price_individual) if course.price_individual else None,
            })
    
    # Upcoming masterclasses
    upcoming_masterclasses = Masterclass.objects.filter(
        status='scheduled',
        start_date__gte=timezone.now().date()
    ).order_by('start_date')[:5]
    
    for mc in upcoming_masterclasses:
        recommendations['upcoming_masterclasses'].append({
            'id': mc.id,
            'title': mc.title,
            'start_date': mc.start_date.isoformat() if mc.start_date else None,
            'location': f'{mc.city}, {mc.country_name}' if mc.city else mc.country_name,
            'price_online': str(mc.price_online),
            'price_physical': str(mc.price_physical),
            'thumbnail_url': None,
        })
    
    # Open learnerships
    open_learnerships = LearnershipProgramme.objects.filter(
        active=True,
        status='open',
        enrollment_deadline__gte=timezone.now().date()
    ).order_by('start_date')[:5]
    
    for lp in open_learnerships:
        recommendations['open_learnerships'].append({
            'id': lp.id,
            'title': lp.title,
            'specialization': lp.specialization,
            'start_date': lp.start_date.isoformat() if lp.start_date else None,
            'end_date': lp.end_date.isoformat() if lp.end_date else None,
            'enrollment_deadline': lp.enrollment_deadline.isoformat() if lp.enrollment_deadline else None,
        })
    
    return recommendations


def _get_notifications(user):
    """Get user notifications"""
    from apps.notifications.models import Notification
    
    notifications = Notification.objects.filter(
        user=user
    ).order_by('-created_at')[:20]
    
    return [
        {
            'id': notif.id,
            'title': notif.title,
            'content': notif.content,
            'notification_type': notif.notification_type,
            'course_app': notif.course_app,
            'course_model': notif.course_model,
            'course_id': notif.course_id,
            'timestamp': notif.created_at.isoformat() if notif.created_at else None,
            'unread': not notif.status,  # status=False means unread
            'author_id': notif.author_id,
        }
        for notif in notifications
    ]


def _get_academic_support(user):
    """Get academic support resources"""
    from apps.learnerships.models import LearnershipEnrollment, LearnershipPhase, PhaseCourse
    
    support_data = {
        'assigned_instructors': [],
        'course_materials': [],
        'learning_resources': [],
    }
    
    # Get instructors from enrolled learnerships
    enrollments = LearnershipEnrollment.objects.filter(
        user=user, active=True
    ).select_related('programme__instructor')
    
    for enr in enrollments:
        if enr.programme.instructor:
            support_data['assigned_instructors'].append({
                'programme_id': enr.programme.id,
                'programme_title': enr.programme.title,
                'instructor_id': enr.programme.instructor.id,
                'instructor_name': enr.programme.instructor.name or enr.programme.instructor.email,
                'instructor_email': enr.programme.instructor.email,
                'specialization': enr.programme.instructor.facilitator_profile.specialization if hasattr(enr.programme.instructor, 'facilitator_profile') else None,
            })
        
        # Get course materials (phases and courses)
        phases = enr.programme.phases.all().prefetch_related('courses')
        for phase in phases:
            for phase_course in phase.courses.all():
                support_data['course_materials'].append({
                    'phase_name': phase.name,
                    'phase_order': phase.order,
                    'course_title': phase_course.course.title,
                    'course_provider': phase_course.course.provider.name if phase_course.course.provider else None,
                })
    
    return support_data


def _get_compliance_status(user):
    """Get compliance and documentation status"""
    from apps.learnerships.models import LearnershipEnrollment
    
    # Get latest enrollment
    enrollment = LearnershipEnrollment.objects.filter(
        user=user
    ).order_by('-enrolled_at').first()
    
    if not enrollment:
        return {
            'has_enrollment': False,
            'documentation_complete': False,
        }
    
    # Check documentation checklist
    documentation = {
        'has_id_copy': enrollment.has_id_copy,
        'has_qualification_certificates': enrollment.has_qualification_certificates,
        'has_proof_of_residence': enrollment.has_proof_of_residence,
        'has_cv': enrollment.has_cv,
        'has_motivational_letter': enrollment.has_motivational_letter,
    }
    
    docs_submitted = sum(1 for v in documentation.values() if v)
    total_docs = len(documentation)
    
    return {
        'has_enrollment': True,
        'enrollment_id': enrollment.id,
        'programme_title': enrollment.programme.title,
        'documentation': documentation,
        'documentation_complete': docs_submitted == total_docs,
        'docs_submitted': docs_submitted,
        'total_docs': total_docs,
        'prerequisites_verified': enrollment.prerequisites_verified,
        'verification_notes': enrollment.verification_notes,
        'seta_declaration_accepted': enrollment.seta_declaration_accepted,
        'terms_accepted': enrollment.terms_accepted,
        'data_protection_accepted': enrollment.data_protection_accepted,
    }
