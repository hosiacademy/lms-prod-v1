# apps/enrollments/tasks.py
from celery import shared_task
from django.utils import timezone
from .models import ProvisionalEnrollment
import logging

logger = logging.getLogger(__name__)


@shared_task
def expire_provisional_enrollments():
    """
    Auto-expire provisional enrollments past expiry date.

    Runs daily via Celery Beat.
    """
    expired = ProvisionalEnrollment.objects.filter(
        status__in=['provisional', 'cash_pending'],
        expires_at__lt=timezone.now()
    )

    count = 0
    for enrollment in expired:
        enrollment.status = 'expired'
        enrollment.save()

        # Send expiry notification
        send_provisional_expiry_email.delay(enrollment.id)

        # Refund if payment was already made
        if (enrollment.payment_transaction and
                enrollment.payment_transaction.status == 'successful'):
            try:
                from apps.payments.services.payment_service import payment_service
                payment_service.refund_payment(
                    transaction_id=str(enrollment.payment_transaction.id),
                    amount=float(enrollment.payment_transaction.amount),
                    reason="Provisional enrollment expired without activation"
                )
                logger.info(f"Refunded expired enrollment: {enrollment.reference_code}")
            except Exception as e:
                logger.error(
                    f"Failed to refund expired enrollment {enrollment.reference_code}: {e}"
                )

        count += 1

    logger.info(f"Expired {count} provisional enrollments")
    return count


@shared_task
def send_provisional_enrollment_email(enrollment_id):
    """
    Send email notification for provisional enrollment creation.

    For cash payments: Send reference code and office details
    For learnership: Notify that enrollment is pending verification
    """
    try:
        enrollment = ProvisionalEnrollment.objects.get(id=enrollment_id)

        from django.core.mail import send_mail
        from django.conf import settings


        if enrollment.status == 'cash_pending':
            subject = f"Welcome to Hosi Academy - Payment Reference: {enrollment.reference_code}"
            message = f'''
Dear {enrollment.user.get_full_name() or enrollment.user.email},

Welcome to Hosi Academy! Thank you for your enrollment in {enrollment.get_enrollment_type_display()}.

To complete your enrollment, please visit one of our offices to make your payment.
You now have access to our Hosi Academy Chat group, your Specific Training chat group, and direct access to chat with your Instructors.

Reference Code: {enrollment.reference_code}
Amount: {enrollment.payment_transaction.amount if enrollment.payment_transaction else 'TBD'} {enrollment.payment_transaction.currency if enrollment.payment_transaction else 'USD'}
Expires: {enrollment.expires_at.strftime('%Y-%m-%d')}

Office Details:
- Visit our website for office locations
- Email: payments@hosiacademy.com
- Phone: Contact your regional office

Best regards,
Hosi Academy Team
'''
        else:  # provisional for learnership
            subject = "Welcome to Hosi Academy - Enrollment Pending Verification"
            message = f'''
Dear {enrollment.user.get_full_name() or enrollment.user.email},

Welcome to Hosi Academy! Thank you for your payment for the {enrollment.get_enrollment_type_display()} program.

Your enrollment is currently being reviewed to verify that you meet all prerequisites.
You now have access to our Hosi Academy Chat group, your Specific Training chat group, and direct access to chat with your Instructors.

Status: Pending Verification
Review Period: 7 days
Reference: {enrollment.reference_code or 'N/A'}

We will notify you within 7 days with the verification result.

Best regards,
Hosi Academy Team
'''

        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [enrollment.user.email],
            fail_silently=True,
        )

        # Send SMS Welcome
        try:
            from apps.payments.services.sms_service import sms_service, sms_template
            if enrollment.user.phone:
                sms_message = sms_template.payment_success(
                    amount=float(enrollment.payment_transaction.amount) if enrollment.payment_transaction else 0,
                    currency=enrollment.payment_transaction.currency if enrollment.payment_transaction else 'ZAR',
                    reference=enrollment.reference_code or str(enrollment.id)[:8],
                    description=enrollment.get_enrollment_type_display()
                )
                sms_service.send_sms(enrollment.user.phone, sms_message)
        except Exception as e:
            logger.error(f"Failed to send SMS to {enrollment.user.phone}: {e}")

        # Auto-generate chat messages
        try:
            from apps.communication.services import ChatEnforcerService
            ChatEnforcerService.enforce_enrollment_chats(enrollment)
        except Exception as e:
            logger.error(f"Failed to generate chat messages: {e}")

        logger.info(f"Sent provisional enrollment email to {enrollment.user.email}")
    except ProvisionalEnrollment.DoesNotExist:
        logger.error(f"Provisional enrollment {enrollment_id} not found")
    except Exception as e:
        logger.error(f"Failed to send provisional enrollment email: {e}")


@shared_task
def send_provisional_expiry_email(enrollment_id):
    """
    Send email notification for provisional enrollment expiry.
    """
    try:
        enrollment = ProvisionalEnrollment.objects.get(id=enrollment_id)

        from django.core.mail import send_mail
        from django.conf import settings

        subject = "Enrollment Expired"
        message = f"""
Dear {enrollment.user.get_full_name() or enrollment.user.email},

Your provisional enrollment has expired.

Reference: {enrollment.reference_code or 'N/A'}
Enrollment Type: {enrollment.get_enrollment_type_display()}
Expired On: {enrollment.expires_at.strftime('%Y-%m-%d')}

{"If you have already made payment, a refund will be processed within 7-14 business days." if enrollment.payment_transaction and enrollment.payment_transaction.status == 'successful' else ""}

To enroll again, please visit our website and start a new enrollment.

Best regards,
Hosi Academy Team
"""

        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [enrollment.user.email],
            fail_silently=True,
        )

        logger.info(f"Sent expiry email to {enrollment.user.email}")
    except ProvisionalEnrollment.DoesNotExist:
        logger.error(f"Provisional enrollment {enrollment_id} not found")
    except Exception as e:
        logger.error(f"Failed to send expiry email: {e}")


@shared_task
def notify_admin_for_prerequisite_verification(enrollment_id):
    """
    Notify admin of new learnership enrollment needing prerequisite verification.
    """
    try:
        enrollment = ProvisionalEnrollment.objects.get(id=enrollment_id)

        from django.core.mail import send_mail
        from django.conf import settings

        admin_email = getattr(settings, 'ADMIN_EMAIL', 'admin@hosiacademy.com')

        subject = f"New Learnership Enrollment - Prerequisite Verification Required"
        message = f"""
A new learnership enrollment requires prerequisite verification.

User: {enrollment.user.email}
Name: {enrollment.user.get_full_name()}
Programme: {enrollment.programme.title if enrollment.programme else 'N/A'}
Reference: {enrollment.reference_code or 'N/A'}
Payment: {enrollment.payment_transaction.amount if enrollment.payment_transaction else 'N/A'} {enrollment.payment_transaction.currency if enrollment.payment_transaction else ''}
Expires: {enrollment.expires_at.strftime('%Y-%m-%d')} (7 days)

Action Required:
1. Review user's qualifications
2. Verify prerequisites are met
3. Confirm or reject enrollment in Django Admin

Admin Link: {settings.SITE_URL}/admin/enrollments/provisionalenrollment/{enrollment.id}/change/

IMPORTANT: Please complete verification within 7 days or enrollment will auto-expire and refund.

Best regards,
Hosi Academy System
"""

        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [admin_email],
            fail_silently=True,
        )

        logger.info(f"Notified admin for prerequisite verification: {enrollment.reference_code}")
    except ProvisionalEnrollment.DoesNotExist:
        logger.error(f"Provisional enrollment {enrollment_id} not found")
    except Exception as e:
        logger.error(f"Failed to send admin notification: {e}")


@shared_task
def send_expiry_warning_emails():
    """
    Send warning emails 3 days before provisional enrollment expiry.

    Runs daily via Celery Beat.
    """
    from datetime import timedelta

    # Get enrollments expiring in 3 days
    warning_date = timezone.now() + timedelta(days=3)
    expiring_soon = ProvisionalEnrollment.objects.filter(
        status__in=['provisional', 'cash_pending'],
        expires_at__date=warning_date.date(),
    )

    count = 0
    for enrollment in expiring_soon:
        try:
            from django.core.mail import send_mail
            from django.conf import settings

            subject = "Reminder: Enrollment Expiring Soon"
            message = f"""
Dear {enrollment.user.get_full_name() or enrollment.user.email},

This is a reminder that your provisional enrollment is expiring in 3 days.

Reference: {enrollment.reference_code or 'N/A'}
Enrollment Type: {enrollment.get_enrollment_type_display()}
Expires: {enrollment.expires_at.strftime('%Y-%m-%d')}

{
"Please visit our office to complete your payment before expiration."
if enrollment.status == 'cash_pending'
else "Your enrollment is pending prerequisite verification. We will contact you soon."
}

Best regards,
Hosi Academy Team
"""

            send_mail(
                subject,
                message,
                settings.DEFAULT_FROM_EMAIL,
                [enrollment.user.email],
                fail_silently=True,
            )

            count += 1
            logger.info(f"Sent expiry warning to {enrollment.user.email}")

        except Exception as e:
            logger.error(f"Failed to send expiry warning: {e}")

    logger.info(f"Sent {count} expiry warning emails")
    return count
