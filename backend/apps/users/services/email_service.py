# apps/users/services/email_service.py
"""
Email Service for Hosi Academy
Handles all transactional and bulk emails
"""
from django.core.mail import EmailMultiAlternatives, send_mail
from django.conf import settings
from django.template.loader import render_to_string
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

# Default schedule text for masterclass emails
DEFAULT_SCHEDULE_TEXT = """08:30 - 09:00: Arrival & Registration
09:00 - 17:00: Modules & Practical Sessions"""


class EmailService:
    """Centralized email service for all academy communications"""
    
    @staticmethod
    def send_enrollment_confirmation(enrollment):
        """
        Send enrollment confirmation email
        Auto-triggered when enrollment is created
        Includes learnership brief and LMS link
        """
        try:
            user = enrollment.user
            programme = enrollment.programme
            
            # Get instructor details
            instructor_name = 'Hosi Academy Team'
            instructor_email = 'support@hosiacademy.co.za'
            
            if hasattr(programme, 'instructor') and programme.instructor:
                instructor_name = programme.instructor.name
                instructor_email = programme.instructor.email
            
            subject = f'✅ Enrollment Confirmed - {programme.title[:50]}'
            
            # Build learnership brief
            learnership_brief = programme.description or programme.focus or ''
            if not learnership_brief and programme.role:
                learnership_brief = f'This learnership prepares you for a career as a {programme.role}.'
            
            # LMS URL
            lms_url = 'https://www.hosiacademy.africa/student/dashboard/'
            
            html_message = render_to_string(
                'emails/enrollment_confirmation.html',
                {
                    'user': user,
                    'enrollment': enrollment,
                    'programme': programme,
                    'instructor_name': instructor_name,
                    'instructor_email': instructor_email,
                    'portal_url': lms_url,
                    'learnership_brief': learnership_brief,
                }
            )
            
            text_message = f'''
Dear {user.name or user.username},

ENROLLMENT CONFIRMED ✅

Enrollment ID: {enrollment.id}
Programme: {programme.title}
Instructor: {instructor_name}
Email: {instructor_email}

LEARNERSHIP BRIEF:
{learnership_brief[:200]}...

ACCESS YOUR LMS DASHBOARD:
{lms_url}

Login Email: {user.email}

Welcome to Hosi Academy!
'''
            
            msg = EmailMultiAlternatives(
                subject=subject,
                body=text_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[user.email]
            )
            msg.attach_alternative(html_message, 'text/html')
            msg.send()
            
            logger.info(f'Enrollment email sent to {user.email} (ID: {enrollment.id})')
            return True
            
        except Exception as e:
            logger.error(f'Failed to send enrollment email: {str(e)}')
            return False
    
    @staticmethod
    def send_bulk_email(
        recipients: List[Dict],
        subject: str,
        message: str,
        html_message: Optional[str] = None,
        from_email: Optional[str] = None
    ) -> Dict[str, int]:
        """
        Send bulk email to multiple recipients
        
        Args:
            recipients: List of dicts with 'email' and optionally 'name'
            subject: Email subject
            message: Plain text message
            html_message: Optional HTML version
            from_email: Optional custom from email
        
        Returns:
            Dict with 'sent' and 'failed' counts
        """
        sent = 0
        failed = 0
        
        for recipient in recipients:
            try:
                email = recipient.get('email')
                name = recipient.get('name', '')
                
                if not email:
                    failed += 1
                    continue
                
                # Personalize
                personalized_message = message.replace('{name}', name)
                personalized_html = html_message.replace('{name}', name) if html_message else None
                
                msg = EmailMultiAlternatives(
                    subject=subject,
                    body=personalized_message,
                    from_email=from_email or settings.DEFAULT_FROM_EMAIL,
                    to=[email]
                )
                
                if personalized_html:
                    msg.attach_alternative(personalized_html, 'text/html')
                
                msg.send()
                sent += 1
                
            except Exception as e:
                logger.error(f'Failed to send to {email}: {str(e)}')
                failed += 1
        
        return {'sent': sent, 'failed': failed}
    
    @staticmethod
    def get_mailing_list(recipient_type: str = 'all') -> List[Dict]:
        """
        Get mailing list from database
        
        Args:
            recipient_type: 'all', 'students', 'instructors', 'admins', 'enrollments'
        
        Returns:
            List of dicts with email, name, type
        """
        from apps.users.models import User
        from apps.learnerships.models import LearnershipEnrollment
        
        recipients = []
        
        if recipient_type in ['all', 'students']:
            students = User.objects.filter(role_id=3, is_active=True)
            for student in students:
                recipients.append({
                    'email': student.email,
                    'name': student.name or student.username,
                    'type': 'student'
                })
        
        if recipient_type in ['all', 'instructors']:
            instructors = User.objects.filter(role_id=2, is_active=True)
            for instructor in instructors:
                recipients.append({
                    'email': instructor.email,
                    'name': instructor.name or instructor.username,
                    'type': 'instructor'
                })
        
        if recipient_type in ['all', 'admins']:
            admins = User.objects.filter(is_staff=True, is_active=True)
            for admin in admins:
                recipients.append({
                    'email': admin.email,
                    'name': admin.name or admin.username,
                    'type': 'admin'
                })
        
        if recipient_type in ['all', 'enrollments']:
            enrollments = LearnershipEnrollment.objects.select_related(
                'user', 'programme'
            ).filter(active=True)
            for enrollment in enrollments:
                recipients.append({
                    'email': enrollment.user.email,
                    'name': enrollment.user.name or enrollment.user.username,
                    'type': 'enrollment',
                    'programme': enrollment.programme.title,
                    'enrollment_id': enrollment.id
                })
        
        # Remove duplicates
        seen = set()
        unique = []
        for r in recipients:
            if r['email'] not in seen:
                seen.add(r['email'])
                unique.append(r)
        
        return unique
    
    @staticmethod
    def send_payment_confirmation(transaction):
        """Send payment confirmation email"""
        try:
            user = transaction.user
            
            subject = f'✅ Payment Confirmed - {transaction.amount} {transaction.currency}'
            
            message = f'''
Dear {user.name or user.username},

Your payment has been confirmed!

Amount: {transaction.amount} {transaction.currency}
Reference: {transaction.provider_reference}
Date: {transaction.completed_at}

Thank you for your purchase!

Best regards,
Hosi Academy
'''
            
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=False,
            )
            
            logger.info(f'Payment email sent to {user.email}')
            return True
            
        except Exception as e:
            logger.error(f'Failed to send payment email: {str(e)}')
            return False
    
    @staticmethod
    def send_password_reset(user, reset_token):
        """Send password reset email"""
        try:
            subject = 'Password Reset Request - Hosi Academy'
            
            reset_url = f'https://www.hosiacademy.africa/reset-password/{reset_token}/'
            
            message = f'''
Dear {user.name or user.username},

You requested a password reset.

Click the link below to reset your password:
{reset_url}

This link expires in 1 hour.

If you didn't request this, please ignore this email.

Best regards,
Hosi Academy
'''
            
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=False,
            )
            
            logger.info(f'Password reset email sent to {user.email}')
            return True
            
        except Exception as e:
            logger.error(f'Failed to send password reset email: {str(e)}')
            return False

    @staticmethod
    def send_masterclass_invitation(enrollment, masterclass_details: dict):
        """
        Send masterclass invitation email with schedule and curriculum
        
        Args:
            enrollment: LearnershipEnrollment object
            masterclass_details: Dict with:
                - title, start_date, end_date, duration_days
                - delivery_mode, venue_platform, instructor_name
                - client_company_name, portal_url
                - certification, target_audience, curriculum
        """
        try:
            from datetime import datetime
            user = enrollment.user
            
            subject = f'🎓 Invitation: {masterclass_details.get("title", "AI Masterclass")}'
            current_date = datetime.now().strftime('%d %B %Y')
            
            # Text email with schedule
            text_message = f'''
Welcome to the Hosi Academy AI Masterclass!
{current_date}

Dear {user.name or user.username},

Welcome to the {masterclass_details.get("title", "AI Masterclass")} at Hosi Academy!

We are thrilled to have you join us for this intensive training experience, 
sponsored by your employer, {masterclass_details.get("client_company_name", "Your Employer")}.

Over the next {masterclass_details.get("duration_days", "3")} days, you will be immersed 
in a curriculum designed to provide you with practical, actionable AI skills that you can 
apply directly to your role. This masterclass is certified by our global partner, AICerts®, 
ensuring you receive a world-class, industry-recognized credential.

YOUR MASTERCLASS DETAILS:
• Masterclass: {masterclass_details.get("title", "AI Masterclass")}
• Dates: {masterclass_details.get("start_date", "TBA")} to {masterclass_details.get("end_date", "TBA")}
• Delivery Mode: {masterclass_details.get("delivery_mode", "Online")}
• Venue/Platform: {masterclass_details.get("venue_platform", "TBA")}
• Certification: {masterclass_details.get("certification", "AICerts® Certified")}
• Target Audience: {masterclass_details.get("target_audience", "Professionals")}

WHAT TO EXPECT:
✓ Expert Instruction: Learn from certified instructors with deep industry experience.
✓ Hands-On Learning: Engage in practical exercises, case studies, and real-world simulations.
✓ Networking: Connect with peers from across your industry and expand your professional network.

DAILY SCHEDULE:
{masterclass_details.get("daily_schedule_text", DEFAULT_SCHEDULE_TEXT)}

CURRICULUM:
{masterclass_details.get("curriculum_text", "See attached detailed curriculum")}

ACCESS YOUR LMS DASHBOARD:
{masterclass_details.get("portal_url", "https://www.hosiacademy.africa/")}

We look forward to hosting you and helping you on your AI learning journey.

Sincerely,
The Hosi Academy Team
'''
            
            # Try to send HTML if template exists
            try:
                html_message = render_to_string(
                    'emails/masterclass_invitation.html',
                    {
                        'delegate_name': user.name or user.username,
                        'masterclass_title': masterclass_details.get('title', 'AI Masterclass'),
                        'current_date': current_date,
                        'start_date': masterclass_details.get('start_date', 'TBA'),
                        'end_date': masterclass_details.get('end_date', 'TBA'),
                        'duration_days': masterclass_details.get('duration_days', '3'),
                        'delivery_mode': masterclass_details.get('delivery_mode', 'Online'),
                        'venue_platform': masterclass_details.get('venue_platform', 'TBA'),
                        'instructor_name': masterclass_details.get('instructor_name', 'Hosi Academy Team'),
                        'client_company_name': masterclass_details.get('client_company_name', 'Your Employer'),
                        'portal_url': masterclass_details.get('portal_url', 'https://www.hosiacademy.africa/'),
                        'certification': masterclass_details.get('certification', 'AICerts® Certified'),
                        'target_audience': masterclass_details.get('target_audience', 'Professionals'),
                        'daily_schedule': masterclass_details.get('daily_schedule', []),
                        'curriculum': masterclass_details.get('curriculum', {}),
                    }
                )
                
                msg = EmailMultiAlternatives(
                    subject=subject,
                    body=text_message,
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    to=[user.email]
                )
                msg.attach_alternative(html_message, 'text/html')
                msg.send()
            except Exception as template_error:
                # Fallback to text-only if template fails
                logger.warning(f'HTML template failed, sending text-only: {str(template_error)}')
                send_mail(
                    subject=subject,
                    message=text_message,
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[user.email],
                    fail_silently=False,
                )
            
            logger.info(f'Masterclass invitation sent to {user.email}')
            return True
            
        except Exception as e:
            logger.error(f'Failed to send masterclass invitation: {str(e)}')
            return False

    @staticmethod
    def send_cybersecurity_enrollment(enrollment, currency: str = 'ZAR'):
        """
        Send cybersecurity learnership enrollment email with phase details and cost breakdown
        
        Args:
            enrollment: LearnershipEnrollment object
            currency: 'ZAR' or 'USD'
        """
        try:
            from apps.learnerships.services.cybersecurity_pricing import (
                get_localized_cost_breakdown,
                get_cybersecurity_learnership
            )
            
            user = enrollment.user
            programme = enrollment.programme
            
            # Determine role slug from programme title
            role_slug = None
            programme_title_lower = programme.title.lower()
            
            if 'soc' in programme_title_lower:
                role_slug = 'soc_analyst'
            elif 'engineer' in programme_title_lower:
                role_slug = 'security_engineer'
            elif 'consultant' in programme_title_lower:
                role_slug = 'security_consultant'
            elif 'red' in programme_title_lower:
                role_slug = 'red_teamer'
            elif 'blue' in programme_title_lower:
                role_slug = 'blue_teamer'
            elif 'bug' in programme_title_lower or 'hunter' in programme_title_lower:
                role_slug = 'bug_hunter'
            
            # Get cost breakdown
            if role_slug:
                cost_data = get_localized_cost_breakdown(role_slug, currency)
            else:
                # Fallback to generic
                cost_data = None
            
            # Get instructor
            instructor_name = 'Hosi Academy Team'
            instructor_email = 'support@hosiacademy.co.za'
            
            if hasattr(programme, 'instructor') and programme.instructor:
                instructor_name = programme.instructor.name
                instructor_email = programme.instructor.email
            
            subject = f'🔐 Enrollment Confirmed - {programme.title}'
            
            # LMS URL
            lms_url = 'https://www.hosiacademy.africa/student/dashboard/'
            
            # Render HTML if cost data available
            if cost_data:
                html_message = render_to_string(
                    'emails/cybersecurity_enrollment.html',
                    {
                        'user': user,
                        'enrollment': enrollment,
                        'learnership_title': cost_data['title'],
                        'instructor_name': instructor_name,
                        'instructor_email': instructor_email,
                        'lms_url': lms_url,
                        'currency': cost_data['currency'],
                        'currency_symbol': cost_data['currency_symbol'],
                        'total_cert_cost': cost_data['total_cert_cost'],
                        'platform_cost': cost_data['platform_cost'],
                        'instructor_cost': cost_data['instructor_cost'],
                        'total_cost': cost_data['total_cost'],
                        'phases': cost_data['phases'],
                    }
                )
                
                # Text version
                text_message = f'''
Dear {user.name or user.username},

ENROLLMENT CONFIRMED ✅

Programme: {cost_data['title']}
Enrollment ID: {enrollment.id}
Instructor: {instructor_name}

COST BREAKDOWN ({cost_data['currency_symbol']} {cost_data['currency']}):
- Certification Costs: {cost_data['currency_symbol']}{cost_data['total_cert_cost']:.2f}
- Platform Access (12 months): {cost_data['currency_symbol']}{cost_data['platform_cost']:.2f}
- Instructor Support (12 months): {cost_data['currency_symbol']}{cost_data['instructor_cost']:.2f}
- TOTAL: {cost_data['currency_symbol']}{cost_data['total_cost']:.2f}

PHASES:
'''
                for phase_key, phase in cost_data['phases'].items():
                    text_message += f"\n{phase['name']} ({cost_data['currency_symbol']}{phase['phase_total']:.2f}):\n"
                    for cert in phase['certifications']:
                        text_message += f"  • {cert['name']} - {cert['description']} ({cost_data['currency_symbol']}{cert['cost']:.2f})\n"
                
                text_message += f'''
ACCESS YOUR LMS DASHBOARD:
{lms_url}

Login Email: {user.email}

Welcome to Hosi Academy!
'''
            else:
                # Fallback to generic enrollment email
                return EmailService.send_enrollment_confirmation(enrollment)
            
            msg = EmailMultiAlternatives(
                subject=subject,
                body=text_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[user.email]
            )
            msg.attach_alternative(html_message, 'text/html')
            msg.send()
            
            logger.info(f'Cybersecurity enrollment email sent to {user.email} (ID: {enrollment.id})')
            return True
            
        except Exception as e:
            logger.error(f'Failed to send cybersecurity enrollment email: {str(e)}')
            return False


# SMS Service - READY BUT NOT ACTIVE
class SMSService:
    """
    SMS Service - Infrastructure Ready
    Uncomment and configure to activate
    """
    
    @staticmethod
    def is_enabled() -> bool:
        """Check if SMS is enabled"""
        return getattr(settings, 'SMS_ENABLED', False)
    
    @staticmethod
    def send(phone: str, message: str) -> bool:
        """
        Send SMS - Currently disabled
        Activate by setting SMS_ENABLED=True in settings
        """
        if not SMSService.is_enabled():
            logger.info(f'SMS disabled. Would send to {phone}: {message[:50]}...')
            return False
        
        # Africa's Talking integration (ready to activate)
        # from africastalking.AfricaTalkingGateway import AfricaTalkingGateway
        # gateway = AfricaTalkingGateway(
        #     settings.AFRICASTALKING_USERNAME,
        #     settings.AFRICASTALKING_API_KEY
        # )
        # gateway.sendSMS(phone, message)
        
        logger.warning('SMS service called but not configured')
        return False
