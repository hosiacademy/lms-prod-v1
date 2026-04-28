"""
BBB Session Email Service
Handles sending session invitations and reminders to students
"""

from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.conf import settings
from django.utils import timezone
from .models import LiveSession, SessionInvitation


class BBBSessionEmailService:
    """Service for sending BBB session-related emails"""
    
    # Site configuration (replacing Django Sites framework)
    SITE_NAME = getattr(settings, 'SITE_NAME', 'Hosi Academy')
    SITE_URL = getattr(settings, 'BASE_URL', 'https://www.hosiacademy.africa')

    @staticmethod
    def send_session_invitation(invitation: SessionInvitation, session: LiveSession):
        """
        Send session invitation email to student

        Args:
            invitation: SessionInvitation instance
            session: LiveSession instance
        """
        # Use BASE_URL from settings instead of Sites framework
        base_url = BBBSessionEmailService.SITE_URL
        join_url = f"{base_url}/bbb/join/{invitation.invitation_token}/"

        # Email context
        context = {
            'student_name': invitation.student_name,
            'session_title': session.title,
            'session_description': session.description,
            'scheduled_start': session.scheduled_start,
            'scheduled_end': session.scheduled_end,
            'instructor_name': session.instructor.get_full_name() or session.instructor.email,
            'join_url': join_url,
            'site_name': BBBSessionEmailService.SITE_NAME,
            'session_duration_minutes': session.duration_minutes,
        }

        # Render email content
        subject = f'Invitation: {session.title} - {BBBSessionEmailService.SITE_NAME}'
        
        html_content = render_to_string(
            'bbb_integration/emails/session_invitation.html',
            context
        )
        
        text_content = render_to_string(
            'bbb_integration/emails/session_invitation.txt',
            context
        )

        # Create and send email
        email = EmailMultiAlternatives(
            subject=subject,
            body=text_content,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[invitation.email],
        )
        email.attach_alternative(html_content, 'text/html')
        email.send(fail_silently=False)

        # Update invitation status
        invitation.status = 'sent'
        invitation.sent_at = timezone.now()
        invitation.metadata['email_sent_at'] = timezone.now().isoformat()
        invitation.save()

    @staticmethod
    def send_session_reminder(invitation: SessionInvitation, session: LiveSession):
        """
        Send session reminder email (1 hour before start)

        Args:
            invitation: SessionInvitation instance
            session: LiveSession instance
        """
        site = Site.objects.get_current()
        join_url = f"{site.domain}/bbb/join/{invitation.invitation_token}/"
        
        context = {
            'student_name': invitation.student_name,
            'session_title': session.title,
            'scheduled_start': session.scheduled_start,
            'instructor_name': session.instructor.get_full_name() or session.instructor.email,
            'join_url': join_url,
            'site_name': site.name,
            'hours_until_start': 1,
        }

        subject = f'Reminder: {session.title} starts in 1 hour - {site.name}'
        
        html_content = render_to_string(
            'bbb_integration/emails/session_reminder.html',
            context
        )
        
        text_content = render_to_string(
            'bbb_integration/emails/session_reminder.txt',
            context
        )

        email = EmailMultiAlternatives(
            subject=subject,
            body=text_content,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[invitation.email],
        )
        email.attach_alternative(html_content, 'text/html')
        email.send(fail_silently=False)

        invitation.metadata['reminder_sent_at'] = timezone.now().isoformat()
        invitation.save()

    @staticmethod
    def send_chat_invitation(invitation: SessionInvitation, session: LiveSession):
        """
        Send 1-on-1 chat invitation for the session

        Args:
            invitation: SessionInvitation instance
            session: LiveSession instance
        """
        chat_url = f"{BBBSessionEmailService.SITE_URL}/chat/session/{session.id}/"

        context = {
            'student_name': invitation.student_name,
            'session_title': session.title,
            'instructor_name': session.instructor.get_full_name() or session.instructor.email,
            'chat_url': chat_url,
            'site_name': BBBSessionEmailService.SITE_NAME,
        }

        subject = f'Chat Access: {session.title} - {BBBSessionEmailService.SITE_NAME}'
        
        html_content = render_to_string(
            'bbb_integration/emails/chat_invitation.html',
            context
        )
        
        text_content = render_to_string(
            'bbb_integration/emails/chat_invitation.txt',
            context
        )

        email = EmailMultiAlternatives(
            subject=subject,
            body=text_content,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[invitation.email],
        )
        email.attach_alternative(html_content, 'text/html')
        email.send(fail_silently=False)

        invitation.chat_invitation_sent = True
        invitation.metadata['chat_invite_sent_at'] = timezone.now().isoformat()
        invitation.save()

    @staticmethod
    def send_recording_available(invitation: SessionInvitation, session: LiveSession, recording_url: str):
        """
        Send email when session recording becomes available

        Args:
            invitation: SessionInvitation instance
            session: LiveSession instance
            recording_url: URL to access the recording
        """
        context = {
            'student_name': invitation.student_name,
            'session_title': session.title,
            'recording_url': recording_url,
            'site_name': BBBSessionEmailService.SITE_NAME,
        }

        subject = f'Recording Available: {session.title} - {BBBSessionEmailService.SITE_NAME}'
        
        html_content = render_to_string(
            'bbb_integration/emails/recording_available.html',
            context
        )
        
        text_content = render_to_string(
            'bbb_integration/emails/recording_available.txt',
            context
        )

        email = EmailMultiAlternatives(
            subject=subject,
            body=text_content,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[invitation.email],
        )
        email.attach_alternative(html_content, 'text/html')
        email.send(fail_silently=False)

        invitation.metadata['recording_email_sent_at'] = timezone.now().isoformat()
        invitation.save()

    @staticmethod
    def invite_student_to_session(
        session: LiveSession,
        student_email: str,
        student_name: str,
        send_chat_invite: bool = True
    ) -> SessionInvitation:
        """
        Complete flow to invite a student to a session

        Args:
            session: LiveSession instance
            student_email: Student email address
            student_name: Student name
            send_chat_invite: Whether to also send chat invitation

        Returns:
            Created SessionInvitation instance
        """
        # Create invitation
        invitation = SessionInvitation.objects.create(
            session=session,
            email=student_email,
            student_name=student_name,
            status='pending',
        )

        # Send session invitation
        BBBSessionEmailService.send_session_invitation(invitation, session)

        # Send chat invitation if requested
        if send_chat_invite:
            BBBSessionEmailService.send_chat_invitation(invitation, session)

        return invitation

    @staticmethod
    def invite_all_enrolled_students(
        session: LiveSession,
        enrolled_students: list,
        send_chat_invite: bool = True
    ) -> int:
        """
        Invite all enrolled students to a session

        Args:
            session: LiveSession instance
            enrolled_students: List of dicts with 'email' and 'name' keys
            send_chat_invite: Whether to also send chat invitations

        Returns:
            Number of invitations sent
        """
        sent_count = 0
        
        for student in enrolled_students:
            try:
                BBBSessionEmailService.invite_student_to_session(
                    session=session,
                    student_email=student['email'],
                    student_name=student['name'],
                    send_chat_invite=send_chat_invite,
                )
                sent_count += 1
            except Exception as e:
                print(f"Failed to invite {student['email']}: {str(e)}")
                continue

        return sent_count
