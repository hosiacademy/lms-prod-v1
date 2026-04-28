"""
BigBlueButton API Service
Handles all BBB API interactions for creating, managing, and monitoring live sessions
"""

import hashlib
import urllib.parse
from datetime import datetime
from typing import Dict, Optional, List
import requests
from django.conf import settings
from django.utils import timezone
from .models import BBBServer, LiveSession, SessionRecording, SessionAttendance, SessionInvitation
from .email_service import BBBSessionEmailService


class BBBService:
    """Service class for interacting with BigBlueButton API"""

    def __init__(self, bbb_server: BBBServer = None):
        """
        Initialize BBB service with a specific server or auto-select one

        Args:
            bbb_server: Specific BBB server to use, or None to auto-select
        """
        if bbb_server:
            self.server = bbb_server
        else:
            # Auto-select server with lowest load
            self.server = self._select_server()

        if not self.server:
            raise ValueError("No active BBB server available")

        self.api_url = self.server.api_url.rstrip('/')
        self.secret = self.server.secret

    def _select_server(self) -> Optional[BBBServer]:
        """Select BBB server with lowest current load"""
        return BBBServer.objects.filter(
            is_active=True
        ).order_by('current_load').first()

    def _generate_checksum(self, call: str, params: str) -> str:
        """
        Generate BBB API checksum

        Args:
            call: API method name
            params: Query string parameters

        Returns:
            SHA256 checksum
        """
        query_string = call + params + self.secret
        return hashlib.sha256(query_string.encode()).hexdigest()

    def _build_url(self, call: str, params: Dict) -> str:
        """
        Build complete BBB API URL with checksum

        Args:
            call: API method name
            params: Dictionary of parameters

        Returns:
            Complete API URL with checksum
        """
        # Build query string
        query_string = urllib.parse.urlencode(params)

        # Generate checksum
        checksum = self._generate_checksum(call, query_string)

        # Build final URL
        return f"{self.api_url}/{call}?{query_string}&checksum={checksum}"

    def create_meeting(self, session: LiveSession) -> Dict:
        """
        Create a BBB meeting

        Args:
            session: LiveSession instance

        Returns:
            API response data
        """
        params = {
            'name': session.title,
            'meetingID': session.meeting_id,
            'attendeePW': session.attendee_password,
            'moderatorPW': session.moderator_password,
            'record': 'true' if session.record else 'false',
            'autoStartRecording': 'true' if session.auto_start_recording else 'false',
            'allowStartStopRecording': 'true' if session.allow_start_stop_recording else 'false',
            'maxParticipants': str(session.max_participants),
            'logoutURL': session.logout_url or '',
            'welcome': session.welcome_message or f'Welcome to {session.title}!',
        }

        # Add BBB configuration from settings
        if hasattr(settings, 'BBB_CONFIG'):
            bbb_config = settings.BBB_CONFIG
            params.update({
                'webcamsOnlyForModerator': 'true' if bbb_config.get('WEBCAMS_ONLY_FOR_MODERATOR') else 'false',
                'muteOnStart': 'true' if bbb_config.get('MUTE_ON_START') else 'false',
                'lockSettingsDisableCam': 'true' if bbb_config.get('LOCK_SETTINGS_DISABLE_CAM') else 'false',
                'lockSettingsDisableMic': 'true' if bbb_config.get('LOCK_SETTINGS_DISABLE_MIC') else 'false',
            })

        url = self._build_url('create', params)
        response = requests.get(url, timeout=30, verify=False)

        return self._parse_xml_response(response.text)

    def get_join_url(self, session: LiveSession, user_name: str, is_moderator: bool = False) -> str:
        """
        Generate join URL for a participant

        Args:
            session: LiveSession instance
            user_name: Name of the user joining
            is_moderator: Whether user joins as moderator

        Returns:
            Join URL (with HTTPS for web compatibility)
        """
        params = {
            'fullName': user_name,
            'meetingID': session.meeting_id,
            'password': session.moderator_password if is_moderator else session.attendee_password,
            'redirect': 'true',
        }

        join_url = self._build_url('join', params)
        
        # Convert to HTTPS for web browser compatibility
        if join_url.startswith('http://'):
            join_url = join_url.replace('http://', 'https://')
        
        return join_url

    def is_meeting_running(self, meeting_id: str) -> bool:
        """
        Check if a meeting is currently running

        Args:
            meeting_id: BBB meeting ID

        Returns:
            True if meeting is running
        """
        params = {'meetingID': meeting_id}
        url = self._build_url('isMeetingRunning', params)

        try:
            response = requests.get(url, timeout=10, verify=False)
            data = self._parse_xml_response(response.text)
            return data.get('running', 'false') == 'true'
        except Exception:
            return False

    def end_meeting(self, session: LiveSession) -> Dict:
        """
        End a BBB meeting

        Args:
            session: LiveSession instance

        Returns:
            API response data
        """
        params = {
            'meetingID': session.meeting_id,
            'password': session.moderator_password,
        }

        url = self._build_url('end', params)
        response = requests.get(url, timeout=30, verify=False)

        # Update session status
        session.status = 'ended'
        session.actual_end = timezone.now()
        session.save()

        return self._parse_xml_response(response.text)

    def get_meeting_info(self, meeting_id: str, moderator_password: str) -> Dict:
        """
        Get detailed meeting information

        Args:
            meeting_id: BBB meeting ID
            moderator_password: Moderator password

        Returns:
            Meeting information
        """
        params = {
            'meetingID': meeting_id,
            'password': moderator_password,
        }

        url = self._build_url('getMeetingInfo', params)
        response = requests.get(url, timeout=30, verify=False)

        return self._parse_xml_response(response.text)

    def get_recordings(self, meeting_id: str = None) -> List[Dict]:
        """
        Get recordings for a meeting or all recordings

        Args:
            meeting_id: Optional meeting ID to filter recordings

        Returns:
            List of recording data
        """
        params = {}
        if meeting_id:
            params['meetingID'] = meeting_id

        url = self._build_url('getRecordings', params)
        response = requests.get(url, timeout=30, verify=False)
        data = self._parse_xml_response(response.text)

        # Extract recordings from response
        recordings = data.get('recordings', {}).get('recording', [])
        if isinstance(recordings, dict):
            recordings = [recordings]

        return recordings

    def publish_recording(self, record_id: str, publish: bool = True) -> Dict:
        """
        Publish or unpublish a recording

        Args:
            record_id: Recording ID
            publish: True to publish, False to unpublish

        Returns:
            API response data
        """
        params = {
            'recordID': record_id,
            'publish': 'true' if publish else 'false',
        }

        url = self._build_url('publishRecordings', params)
        response = requests.get(url, timeout=30, verify=False)

        return self._parse_xml_response(response.text)

    def delete_recording(self, record_id: str) -> Dict:
        """
        Delete a recording permanently

        Args:
            record_id: Recording ID

        Returns:
            API response data
        """
        params = {'recordID': record_id}
        url = self._build_url('deleteRecordings', params)
        response = requests.get(url, timeout=30, verify=False)

        return self._parse_xml_response(response.text)

    def sync_recordings(self, session: LiveSession) -> int:
        """
        Sync recordings from BBB to database

        Args:
            session: LiveSession instance

        Returns:
            Number of recordings synced
        """
        recordings = self.get_recordings(session.meeting_id)
        synced_count = 0

        for recording_data in recordings:
            record_id = recording_data.get('recordID')
            if not record_id:
                continue

            # Check if recording already exists
            recording, created = SessionRecording.objects.get_or_create(
                record_id=record_id,
                defaults={
                    'session': session,
                    'name': recording_data.get('name', session.title),
                    'published': recording_data.get('published', 'false') == 'true',
                    'start_time': self._parse_timestamp(recording_data.get('startTime')),
                    'end_time': self._parse_timestamp(recording_data.get('endTime')),
                    'duration_minutes': int(recording_data.get('playback', {}).get('duration', 0)) // 60,
                    'playback_url': recording_data.get('playback', {}).get('format', {}).get('url', ''),
                    'playback_format': recording_data.get('playback', {}).get('format', {}).get('type', 'presentation'),
                }
            )

            if created:
                synced_count += 1
                session.has_recording = True
                session.save()

        return synced_count

    def _parse_xml_response(self, xml_text: str) -> Dict:
        """
        Parse XML response from BBB API

        Args:
            xml_text: XML response text

        Returns:
            Parsed data as dictionary
        """
        try:
            import xml.etree.ElementTree as ET
            root = ET.fromstring(xml_text)

            def element_to_dict(element):
                result = {}
                for child in element:
                    if len(child) == 0:
                        result[child.tag] = child.text
                    else:
                        result[child.tag] = element_to_dict(child)
                return result

            return element_to_dict(root)
        except Exception as e:
            return {'error': str(e), 'raw': xml_text}

    def _parse_timestamp(self, timestamp_str: str) -> datetime:
        """
        Parse BBB timestamp to datetime

        Args:
            timestamp_str: Timestamp string (milliseconds since epoch)

        Returns:
            datetime object
        """
        try:
            timestamp_ms = int(timestamp_str)
            return datetime.fromtimestamp(timestamp_ms / 1000, tz=timezone.utc)
        except (ValueError, TypeError):
            return timezone.now()


class InstructorSessionManager:
    """Manager for instructor-specific session operations"""

    @staticmethod
    def create_session_for_course(
        instructor,
        course_id: int,
        course_type: str,
        title: str,
        scheduled_start: datetime,
        scheduled_end: datetime,
        description: str = '',
        **kwargs
    ) -> LiveSession:
        """
        Create a new live session for a course

        Args:
            instructor: User instance (instructor)
            course_id: Course ID
            course_type: Type of course (course, masterclass, learnership)
            title: Session title
            scheduled_start: When session starts
            scheduled_end: When session ends
            description: Session description
            **kwargs: Additional session settings

        Returns:
            Created LiveSession instance
        """
        # Select BBB server
        service = BBBService()

        # Create session
        session = LiveSession.objects.create(
            instructor=instructor,
            course_id=course_id,
            course_type=course_type,
            title=title,
            description=description,
            scheduled_start=scheduled_start,
            scheduled_end=scheduled_end,
            bbb_server=service.server,
            status='scheduled',
            **kwargs
        )

        # Send announcement to course chat and 1-on-1 chats
        InstructorSessionManager.send_session_announcement_to_chat(session)

        return session

    @staticmethod
    def start_session(session: LiveSession) -> str:
        """
        Start a live session and get moderator join URL

        Args:
            session: LiveSession instance

        Returns:
            Moderator join URL
        """
        service = BBBService(session.bbb_server)

        # Create meeting in BBB
        service.create_meeting(session)

        # Update session status
        session.status = 'live'
        session.actual_start = timezone.now()
        session.save()

        # Increment server load
        session.bbb_server.current_load += 1
        session.bbb_server.save()

        # Generate join URL for instructor
        instructor_name = session.instructor.get_full_name() or session.instructor.email
        join_url = service.get_join_url(session, instructor_name, is_moderator=True)

        return join_url

    @staticmethod
    def end_session(session: LiveSession) -> None:
        """
        End a live session

        Args:
            session: LiveSession instance
        """
        service = BBBService(session.bbb_server)
        service.end_meeting(session)

        # Decrement server load
        if session.bbb_server.current_load > 0:
            session.bbb_server.current_load -= 1
            session.bbb_server.save()

        # Sync recordings
        service.sync_recordings(session)

        # Notify students that recording is available (if any new recordings)
        if session.has_recording:
            InstructorSessionManager.notify_recording_available(session)

        # Auto-accrue for Instructor (optional - skip if instructors app models not available)
        try:
            from apps.instructors.models import Instructor, CourseAssignment as InstructorCourseAssignment
            from django.contrib.contenttypes.models import ContentType

            profile = Instructor.objects.get(user=session.instructor)
            
            # Find closest assignment
            # Map course_type to ContentType if needed
            ctype = None
            if session.course_type == 'masterclass':
                ctype = ContentType.objects.get(app_label='masterclasses', model='masterclass')
            elif session.course_type == 'learnership':
                ctype = ContentType.objects.get(app_label='learnerships', model='learnershipprogramme')
                
            assignment = None
            if ctype:
                assignment = CourseAssignment.objects.filter(
                    facilitator=profile,
                    content_type=ctype,
                    object_id=session.course_id,
                    status__in=['assigned', 'ongoing']
                ).first()
            
            if not assignment:
                # Fallback to legacy Course if course_type is 'course'
                assignment = CourseAssignment.objects.filter(
                    facilitator=profile,
                    course_id=session.course_id,
                    status__in=['assigned', 'ongoing']
                ).first()

            if assignment:
                # Instructor attendance tracking not implemented yet
                pass  # Skip attendance tracking for now

        except Exception as e:
            # Don't break session ending if accrual fails
            print(f"DEBUG: Skipped instructor accrual for session {session.id}: {e}")

    @staticmethod
    def get_session_join_url(session: LiveSession, user, is_moderator: bool = False) -> str:
        """
        Get join URL for a user

        Args:
            session: LiveSession instance
            user: User instance
            is_moderator: Whether user should join as moderator

        Returns:
            Join URL
        """
        service = BBBService(session.bbb_server)
        user_name = user.get_full_name() or user.email

        # Track attendance
        SessionAttendance.objects.get_or_create(
            session=session,
            user=user,
            defaults={'joined_as_moderator': is_moderator}
        )

        return service.get_join_url(session, user_name, is_moderator)

    @staticmethod
    def get_instructor_sessions(instructor, status: str = None) -> List[LiveSession]:
        """
        Get all sessions for an instructor

        Args:
            instructor: User instance
            status: Optional status filter

        Returns:
            QuerySet of LiveSession instances
        """
        queryset = LiveSession.objects.filter(instructor=instructor)

        if status:
            queryset = queryset.filter(status=status)

        return queryset.order_by('-scheduled_start')

    @staticmethod
    def invite_students_to_session(
        session: LiveSession,
        students: List[Dict],
        send_chat_invite: bool = True
    ) -> int:
        """
        Invite students to a session via email

        Args:
            session: LiveSession instance
            students: List of dicts with 'email' and 'name' keys
            send_chat_invite: Whether to send 1-on-1 chat invitations

        Returns:
            Number of invitations sent
        """
        return BBBSessionEmailService.invite_all_enrolled_students(
            session=session,
            enrolled_students=students,
            send_chat_invite=send_chat_invite,
        )

    @staticmethod
    def auto_invite_enrolled_students(session: LiveSession) -> int:
        """
        Automatically invite all enrolled students to a session

        Args:
            session: LiveSession instance

        Returns:
            Number of invitations sent
        """
        from apps.payments.models import Enrollment
        from django.contrib.contenttypes.models import ContentType
        from apps.masterclasses.models import Masterclass
        from apps.learnerships.models import LearnershipProgramme
        from apps.aicerts_courses.models import AiCertsCourse

        students = []
        seen_emails = set()

        # Get content type for the session's course
        try:
            if session.course_type == 'masterclass':
                ctype = ContentType.objects.get(app_label='masterclasses', model='masterclass')
                course_model = Masterclass
            elif session.course_type == 'learnership':
                ctype = ContentType.objects.get(app_label='learnerships', model='learnershipprogramme')
                course_model = LearnershipProgramme
            elif session.course_type == 'industry_training':
                ctype = ContentType.objects.get(app_label='aicerts_courses', model='aicertscourse')
                course_model = AiCertsCourse
            else:
                # Generic course type - try all
                enrollments = Enrollment.objects.filter(
                    content_type__model__in=['masterclass', 'learnershipprogramme', 'aicertscourse']
                ).select_related('user')
                for enrollment in enrollments:
                    if enrollment.user.email not in seen_emails:
                        students.append({
                            'email': enrollment.user.email,
                            'name': enrollment.user.get_full_name() or enrollment.user.email,
                        })
                        seen_emails.add(enrollment.user.email)
                return BBBSessionEmailService.invite_all_enrolled_students(
                    session=session,
                    enrolled_students=students,
                    send_chat_invite=True,
                )

            # Get enrollments for this specific course
            enrollments = Enrollment.objects.filter(
                content_type=ctype,
                object_id=session.course_id,
                status='enrolled'
            ).select_related('user')

            for enrollment in enrollments:
                if enrollment.user.email not in seen_emails:
                    students.append({
                        'email': enrollment.user.email,
                        'name': enrollment.user.get_full_name() or enrollment.user.email,
                    })
                    seen_emails.add(enrollment.user.email)

        except Exception as e:
            print(f"DEBUG: Failed to get enrolled students for session {session.id}: {e}")

        # Send invitations
        if students:
            return BBBSessionEmailService.invite_all_enrolled_students(
                session=session,
                enrolled_students=students,
                send_chat_invite=True,
            )
        
        return 0

    @staticmethod
    def send_session_announcement_to_chat(session: LiveSession) -> int:
        """
        Send BBB session announcement to course chat room and 1-on-1 chats
        Also sends SMS and Email notifications to all enrolled students

        Args:
            session: LiveSession instance

        Returns:
            Number of messages sent
        """
        from apps.communication.models import ChatRoom, ChatParticipant, Message
        from apps.learnerships.models import LearnershipEnrollment, LearnershipProgramme
        from django.contrib.contenttypes.models import ContentType
        from django.db import connection
        import logging
        
        logger = logging.getLogger(__name__)
        messages_sent = 0
        emails_sent = 0
        sms_sent = 0

        # Get all enrolled students for this course from central enrollments table
        student_ids = []
        with connection.cursor() as cursor:
            # Query enrollments table using instructor_id
            # enrollment_id is unique per enrollment
            # student_id is unique per student across ALL enrollment pathways
            # instructor_id links to the instructor teaching this course
            cursor.execute('''
                SELECT DISTINCT e.student_id, e.user_id, e.enrollment_id, e.instructor_id, 
                       u.email, u.first_name, u.last_name, u.phone
                FROM enrollments e
                JOIN users u ON e.user_id = u.id
                WHERE (e.object_id = %s OR e.learnership_enrollment_id IN (
                        SELECT id FROM learnerships_learnershipenrollment WHERE programme_id = %s
                      ))
                      AND (e.instructor_id = %s OR e.instructor_id IS NULL)
                ORDER BY e.student_id
            ''', [session.course_id, session.course_id, session.instructor_id])
            for row in cursor.fetchall():
                student_ids.append({
                    'student_id': row[0],
                    'user_id': row[1],
                    'enrollment_id': row[2],
                    'instructor_id': row[3],
                    'email': row[4],
                    'first_name': row[5],
                    'last_name': row[6],
                    'phone': row[7]
                })

        if not student_ids:
            logger.warning(f'No enrolled students found for session {session.id}')
            return 0

        logger.info(f'Sending BBB session notifications for session {session.id} to {len(student_ids)} students')

        if not student_ids:
            return 0

        # Send SMS and Email to each enrolled student
        from apps.bbb_integration.email_service import BBBSessionEmailService
        from apps.payments.services.sms_service import TwilioSMSService
        from django.conf import settings
        
        base_url = getattr(settings, 'BASE_URL', 'https://www.hosiacademy.africa')
        sms_service = TwilioSMSService()
        
        session_date = session.scheduled_start.strftime('%A, %d %B %Y')
        session_time = session.scheduled_start.strftime('%H:%M')
        course_title = session.title.replace('Live Session: ', '')
        
        for student in student_ids:
            student_name = f"{student['first_name']} {student['last_name']}".strip() or "Student"
            
            # Send Email
            try:
                from apps.bbb_integration.models import SessionInvitation
                invitation, created = SessionInvitation.objects.get_or_create(
                    session=session,
                    email=student['email'],
                    defaults={
                        'student_name': student_name,
                        'status': 'sent'
                    }
                )
                
                # Send email with session details and app link
                email_context = {
                    'student_name': student_name,
                    'session_title': session.title,
                    'course_title': course_title,
                    'scheduled_start': session.scheduled_start,
                    'scheduled_end': session.scheduled_end,
                    'instructor_name': session.instructor.get_full_name() or session.instructor.email,
                    'join_url': f"{base_url}/#/instructor/dashboard",
                    'app_url': base_url,
                    'session_duration_minutes': session.duration_minutes,
                }
                
                from django.core.mail import EmailMultiAlternatives
                from django.template.loader import render_to_string
                
                subject = f'📺 Live Session: {course_title} - {session_date} at {session_time}'
                
                html_content = f"""
                <html>
                <body>
                    <h2>Live Session Announcement</h2>
                    <p>Dear {student_name},</p>
                    <p>You have been invited to attend a live session for <strong>{course_title}</strong>.</p>
                    <h3>Session Details:</h3>
                    <ul>
                        <li><strong>Title:</strong> {session.title}</li>
                        <li><strong>Date:</strong> {session_date}</li>
                        <li><strong>Time:</strong> {session_time}</li>
                        <li><strong>Duration:</strong> {session.duration_minutes} minutes</li>
                        <li><strong>Instructor:</strong> {session.instructor.get_full_name() or session.instructor.email}</li>
                    </ul>
                    <p><a href="{base_url}/#/instructor/dashboard" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Join Session</a></p>
                    <p>Log in to your dashboard at <a href="{base_url}">{base_url}</a> to access the session.</p>
                    <p>Best regards,<br/>Hosi Academy Team</p>
                </body>
                </html>
                """
                
                email = EmailMultiAlternatives(
                    subject=subject,
                    body=f"Dear {student_name},\n\nYou are invited to: {session.title}\nDate: {session_date} at {session_time}\n\nJoin at: {base_url}/#/instructor/dashboard",
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    to=[student['email']],
                )
                email.attach_alternative(html_content, 'text/html')
                email.send(fail_silently=False)
                emails_sent += 1
                messages_sent += 1
                logger.info(f'✓ Email sent to {student["email"]} for session {session.id}')
            except Exception as e:
                logger.error(f'✗ Email failed to {student["email"]}: {e}')

            # Send SMS
            try:
                if student['phone']:
                    sms_message = f"Hosi Academy: Live session for {course_title} on {session_date} at {session_time}. Instructor: {session.instructor.first_name}. Join: {base_url}/#/instructor/dashboard"
                    sms_result = sms_service.send_sms(student['phone'], sms_message)
                    if sms_result.get('success'):
                        sms_sent += 1
                        messages_sent += 1
                        logger.info(f'✓ SMS sent to {student["phone"]} for session {session.id}')
                    else:
                        logger.warning(f'⚠ SMS failed to {student["phone"]}: {sms_result.get("error")}')
            except Exception as e:
                logger.error(f'✗ SMS failed to {student["phone"]}: {e}')

        logger.info(f'BBB session {session.id} notifications complete: {emails_sent} emails, {sms_sent} SMS, {messages_sent} total')
        return messages_sent

    @staticmethod
    def notify_recording_available(session: LiveSession):
        """
        Notify all invited students that recording is available

        Args:
            session: LiveSession instance
        """
        try:
            # Get session recording
            recording = session.recordings.filter(published=True).order_by('-start_time').first()
            if not recording:
                return

            # Get all invitations
            invitations = session.invitations.filter(status__in=['sent', 'opened', 'joined'])
            
            site_domain = settings.FRONTEND_URL if hasattr(settings, 'FRONTEND_URL') else 'http://localhost:3000'
            recording_url = f"{site_domain}/student/recordings/{recording.id}/"

            for invitation in invitations:
                try:
                    BBBSessionEmailService.send_recording_available(
                        invitation=invitation,
                        session=session,
                        recording_url=recording_url,
                    )
                except Exception as e:
                    print(f"Failed to notify {invitation.email}: {e}")

        except Exception as e:
            print(f"DEBUG: Failed to notify recording available for session {session.id}: {e}")
