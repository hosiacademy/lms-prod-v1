# apps/notifications/services.py
"""
Notification Services for Email and SMS
Handles sending enrollment confirmations, failures, and access credentials
"""
import logging
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.conf import settings
from django.utils.html import strip_tags
from typing import Dict, Optional, List
import requests

logger = logging.getLogger(__name__)


class EmailService:
    """Email notification service for enrollment confirmations"""

    @staticmethod
    def send_enrollment_success(
        user_email: str,
        user_name: str,
        enrollment_code: str,
        program_name: str,
        program_type: str,
        enrollment_details: Dict,
        access_credentials: Optional[Dict] = None
    ) -> bool:
        """
        Send enrollment success email with access credentials and platform links

        Args:
            user_email: Learner's email address
            user_name: Learner's full name
            enrollment_code: Unique enrollment code
            program_name: Name of the enrolled program
            program_type: Type (learnership, masterclass, industry_training)
            enrollment_details: Dict with additional enrollment info
            access_credentials: Optional dict with username/password if new account

        Returns:
            bool: True if email sent successfully
        """
        try:
            subject = f"🎉 Enrollment Confirmed - {program_name}"

            # Platform access links
            platform_links = EmailService._get_platform_links()

            # Prepare context for email template
            context = {
                'user_name': user_name,
                'enrollment_code': enrollment_code,
                'program_name': program_name,
                'program_type': program_type.replace('_', ' ').title(),
                'enrollment_details': enrollment_details,
                'access_credentials': access_credentials,
                'platform_links': platform_links,
                'support_email': getattr(settings, 'SUPPORT_EMAIL', 'academy@hosiafrica.com'),
                'support_phone': getattr(settings, 'SUPPORT_PHONE', '+27 67 231 9200'),
                'company_name': 'Hosi Academy',
                'company_tagline': 'The Future of Learning',
                'logo_url': 'http://154.66.211.3:7000/assets/assets/images/logo.png',
                'website_url': 'https://www.hosiacademy.africa',
            }

            # Render HTML email from template
            html_content = render_to_string(
                'notifications/emails/enrollment_success.html',
                context
            )

            # Create plain text version
            text_content = strip_tags(html_content)

            # Create email message
            email = EmailMultiAlternatives(
                subject=subject,
                body=text_content,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[user_email],
            )
            email.attach_alternative(html_content, "text/html")

            # Send email
            email.send(fail_silently=False)

            logger.info(f"Enrollment success email sent to {user_email} - {enrollment_code}")
            return True

        except Exception as e:
            logger.error(f"Failed to send enrollment success email to {user_email}: {str(e)}")
            return False

    @staticmethod
    def send_enrollment_failure(
        user_email: str,
        user_name: str,
        program_name: str,
        program_type: str,
        failure_reason: str,
        support_action: str = None
    ) -> bool:
        """
        Send enrollment failure email with reason and next steps

        Args:
            user_email: Learner's email address
            user_name: Learner's full name
            program_name: Name of the program they tried to enroll in
            program_type: Type of program
            failure_reason: Reason for enrollment failure
            support_action: Optional guidance on what to do next

        Returns:
            bool: True if email sent successfully
        """
        try:
            subject = f"❌ Enrollment Issue - {program_name}"

            context = {
                'user_name': user_name,
                'program_name': program_name,
                'program_type': program_type.replace('_', ' ').title(),
                'failure_reason': failure_reason,
                'support_action': support_action or "Please contact support for assistance.",
                'support_email': getattr(settings, 'SUPPORT_EMAIL', 'academy@hosiafrica.com'),
                'support_phone': getattr(settings, 'SUPPORT_PHONE', '+27 67 231 9200'),
                'company_name': 'Hosi Academy',
                'company_tagline': 'The Future of Learning',
                'logo_url': 'http://154.66.211.3:7000/assets/assets/images/logo.png',
                'website_url': 'https://www.hosiacademy.africa',
            }

            # Render HTML email from template
            html_content = render_to_string(
                'notifications/emails/enrollment_failure.html',
                context
            )

            # Create plain text version
            text_content = strip_tags(html_content)

            # Create email message
            email = EmailMultiAlternatives(
                subject=subject,
                body=text_content,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[user_email],
            )
            email.attach_alternative(html_content, "text/html")

            # Send email
            email.send(fail_silently=False)

            logger.info(f"Enrollment failure email sent to {user_email}")
            return True

        except Exception as e:
            logger.error(f"Failed to send enrollment failure email to {user_email}: {str(e)}")
            return False

    @staticmethod
    def _get_platform_links() -> Dict[str, str]:
        """Generate platform-specific access links"""
        base_url = getattr(settings, 'FRONTEND_BASE_URL', 'https://hosiacademy.com')

        return {
            'web': f"{base_url}/login",
            'android': getattr(
                settings,
                'ANDROID_APP_URL',
                'https://play.google.com/store/apps/details?id=com.hosiacademy.lms'
            ),
            'ios': getattr(
                settings,
                'IOS_APP_URL',
                'https://apps.apple.com/app/hosi-academy/id123456789'
            ),
            'desktop_windows': getattr(
                settings,
                'DESKTOP_WINDOWS_URL',
                f"{base_url}/downloads/HosiAcademy-Setup.exe"
            ),
            'desktop_mac': getattr(
                settings,
                'DESKTOP_MAC_URL',
                f"{base_url}/downloads/HosiAcademy.dmg"
            ),
            'desktop_linux': getattr(
                settings,
                'DESKTOP_LINUX_URL',
                f"{base_url}/downloads/HosiAcademy.AppImage"
            ),
        }


class SMSService:
    """SMS notification service for enrollment confirmations"""

    # Supported SMS providers
    PROVIDER_TWILIO = 'twilio'
    PROVIDER_AFRICAS_TALKING = 'africas_talking'
    PROVIDER_CLICKATELL = 'clickatell'

    @staticmethod
    def send_enrollment_success_sms(
        phone_number: str,
        user_name: str,
        enrollment_code: str,
        program_name: str,
        access_link: str
    ) -> bool:
        """
        Send enrollment success SMS

        Args:
            phone_number: Learner's phone number
            user_name: Learner's name
            enrollment_code: Unique enrollment code
            program_name: Name of enrolled program
            access_link: Short link to access the LMS

        Returns:
            bool: True if SMS sent successfully
        """
        try:
            # Create SMS message (160 characters max for single SMS)
            message = (
                f"Hi {user_name}! 🎉 You're enrolled in {program_name}. "
                f"Code: {enrollment_code}. Access: {access_link} - Hosi Academy"
            )

            # Send via configured provider
            provider = getattr(settings, 'SMS_PROVIDER', SMSService.PROVIDER_TWILIO)

            if provider == SMSService.PROVIDER_TWILIO:
                return SMSService._send_via_twilio(phone_number, message)
            elif provider == SMSService.PROVIDER_AFRICAS_TALKING:
                return SMSService._send_via_africas_talking(phone_number, message)
            elif provider == SMSService.PROVIDER_CLICKATELL:
                return SMSService._send_via_clickatell(phone_number, message)
            else:
                logger.warning(f"Unknown SMS provider: {provider}")
                return False

        except Exception as e:
            logger.error(f"Failed to send enrollment success SMS to {phone_number}: {str(e)}")
            return False

    @staticmethod
    def send_enrollment_failure_sms(
        phone_number: str,
        user_name: str,
        program_name: str,
        support_phone: str
    ) -> bool:
        """
        Send enrollment failure SMS

        Args:
            phone_number: Learner's phone number
            user_name: Learner's name
            program_name: Name of program
            support_phone: Support contact number

        Returns:
            bool: True if SMS sent successfully
        """
        try:
            message = (
                f"Hi {user_name}, enrollment in {program_name} failed. "
                f"Please contact support: {support_phone} - Hosi Academy"
            )

            provider = getattr(settings, 'SMS_PROVIDER', SMSService.PROVIDER_TWILIO)

            if provider == SMSService.PROVIDER_TWILIO:
                return SMSService._send_via_twilio(phone_number, message)
            elif provider == SMSService.PROVIDER_AFRICAS_TALKING:
                return SMSService._send_via_africas_talking(phone_number, message)
            elif provider == SMSService.PROVIDER_CLICKATELL:
                return SMSService._send_via_clickatell(phone_number, message)
            else:
                return False

        except Exception as e:
            logger.error(f"Failed to send enrollment failure SMS to {phone_number}: {str(e)}")
            return False

    @staticmethod
    def _send_via_twilio(phone_number: str, message: str) -> bool:
        """Send SMS via Twilio"""
        try:
            from twilio.rest import Client

            account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', None)
            auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', None)
            from_number = getattr(settings, 'TWILIO_PHONE_NUMBER', None)

            if not all([account_sid, auth_token, from_number]):
                logger.error("Twilio credentials not configured")
                return False

            client = Client(account_sid, auth_token)

            message = client.messages.create(
                body=message,
                from_=from_number,
                to=phone_number
            )

            logger.info(f"Twilio SMS sent to {phone_number} - SID: {message.sid}")
            return True

        except Exception as e:
            logger.error(f"Twilio SMS failed: {str(e)}")
            return False

    @staticmethod
    def _send_via_africas_talking(phone_number: str, message: str) -> bool:
        """Send SMS via Africa's Talking"""
        try:
            import africastalking

            username = getattr(settings, 'AFRICAS_TALKING_USERNAME', None)
            api_key = getattr(settings, 'AFRICAS_TALKING_API_KEY', None)
            sender_id = getattr(settings, 'AFRICAS_TALKING_SENDER_ID', 'HosiAcademy')

            if not all([username, api_key]):
                logger.error("Africa's Talking credentials not configured")
                return False

            africastalking.initialize(username, api_key)
            sms = africastalking.SMS

            response = sms.send(message, [phone_number], sender_id)

            logger.info(f"Africa's Talking SMS sent to {phone_number}: {response}")
            return True

        except Exception as e:
            logger.error(f"Africa's Talking SMS failed: {str(e)}")
            return False

    @staticmethod
    def _send_via_clickatell(phone_number: str, message: str) -> bool:
        """Send SMS via Clickatell"""
        try:
            api_key = getattr(settings, 'CLICKATELL_API_KEY', None)

            if not api_key:
                logger.error("Clickatell API key not configured")
                return False

            url = "https://platform.clickatell.com/messages"
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }

            payload = {
                "messages": [
                    {
                        "to": [phone_number],
                        "text": message
                    }
                ]
            }

            response = requests.post(url, json=payload, headers=headers, timeout=10)
            response.raise_for_status()

            logger.info(f"Clickatell SMS sent to {phone_number}")
            return True

        except Exception as e:
            logger.error(f"Clickatell SMS failed: {str(e)}")
            return False


class NotificationService:
    """Unified notification service coordinating email and SMS"""

    @staticmethod
    def send_enrollment_notifications(
        enrollment_id: int,
        success: bool = True,
        failure_reason: str = None
    ) -> Dict[str, bool]:
        """
        Send both email and SMS notifications for enrollment

        Args:
            enrollment_id: ID of the enrollment record
            success: Whether enrollment was successful
            failure_reason: Reason for failure (if success=False)

        Returns:
            Dict with 'email' and 'sms' keys indicating send status
        """
        from apps.payments.models import Enrollment

        try:
            enrollment = Enrollment.objects.select_related('user').get(id=enrollment_id)
        except Enrollment.DoesNotExist:
            logger.error(f"Enrollment {enrollment_id} not found")
            return {'email': False, 'sms': False}

        user = enrollment.user
        user_email = enrollment.learner_email or user.email
        user_phone = enrollment.learner_phone or user.phone
        user_name = enrollment.learner_full_name or user.get_full_name() or user.username

        # Get program details
        program = enrollment.content_object
        program_name = getattr(program, 'title', '') or getattr(program, 'name', 'Unknown Program')
        program_type = enrollment.enrollment_type

        results = {'email': False, 'sms': False}

        if success:
            # Success notifications
            enrollment_details = {
                'start_date': getattr(program, 'start_date', None),
                'duration': getattr(program, 'duration', None) or getattr(program, 'formattedDuration', None),
                'location': getattr(program, 'location', None) or getattr(program, 'displayLocation', None),
                'delivery_mode': getattr(program, 'delivery_mode', 'Online'),
                'enrolled_at': enrollment.enrolled_at,
            }

            # Check if new account (credentials needed)
            access_credentials = {}
            if hasattr(user, 'is_new_account') and user.is_new_account:
                access_credentials.update({
                    'username': user.email,
                    'password': 'Check your email for password setup link'
                })

            # Add AICerts SSO link if applicable
            from apps.payments.models import EnrollmentType
            if program_type in [EnrollmentType.MASTERCLASS, EnrollmentType.INDUSTRY_TRAINING, EnrollmentType.ROLE_TRAINING]:
                try:
                    from apps.aicerts_integration.services import SSOService
                    # Identify the primary AICerts course ID for redirect if possible
                    aicerts_course_id = None
                    
                    if program_type == EnrollmentType.INDUSTRY_TRAINING:
                        # For industry training, program is likely AiCertsCourse (Managed)
                        if hasattr(program, 'course_id') and program.course_id:
                            aicerts_course_id = program.course_id
                        elif hasattr(program, 'external_id'):
                            aicerts_course_id = program.external_id
                    
                    # Generate SSO URL
                    sso_url = SSOService.generate_sso_url(user.email, course_id=aicerts_course_id)
                    access_credentials['aicerts_sso_url'] = sso_url
                except Exception as e:
                    logger.error(f"Failed to generate SSO URL for notification: {str(e)}")

            if not access_credentials:
                access_credentials = None

            # Send email
            results['email'] = EmailService.send_enrollment_success(
                user_email=user_email,
                user_name=user_name,
                enrollment_code=enrollment.enrollment_code,
                program_name=program_name,
                program_type=program_type,
                enrollment_details=enrollment_details,
                access_credentials=access_credentials
            )

            # Send SMS if phone number available
            if user_phone:
                base_url = getattr(settings, 'FRONTEND_BASE_URL', 'https://hosiacademy.com')
                access_link = f"{base_url}/login"

                results['sms'] = SMSService.send_enrollment_success_sms(
                    phone_number=user_phone,
                    user_name=user_name,
                    enrollment_code=enrollment.enrollment_code,
                    program_name=program_name,
                    access_link=access_link
                )
        else:
            # Failure notifications
            results['email'] = EmailService.send_enrollment_failure(
                user_email=user_email,
                user_name=user_name,
                program_name=program_name,
                program_type=program_type,
                failure_reason=failure_reason or "An error occurred during enrollment.",
                support_action="Please try again or contact our support team."
            )

            # Send SMS if phone number available
            if user_phone:
                support_phone = getattr(settings, 'SUPPORT_PHONE', '+27112345678')
                results['sms'] = SMSService.send_enrollment_failure_sms(
                    phone_number=user_phone,
                    user_name=user_name,
                    program_name=program_name,
                    support_phone=support_phone
                )

        return results
