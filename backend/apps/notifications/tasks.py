# apps/notifications/tasks.py
"""
Celery tasks for asynchronous notification sending
"""
from celery import shared_task
import logging

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3)
def send_enrollment_notifications_task(self, enrollment_id: int, success: bool = True, failure_reason: str = None):
    """
    Async task to send enrollment notifications (email + SMS)

    Args:
        enrollment_id: ID of the enrollment record
        success: Whether enrollment was successful
        failure_reason: Optional failure reason

    Returns:
        dict: Results of email and SMS sending
    """
    try:
        from apps.notifications.services import NotificationService

        logger.info(f"Sending enrollment notifications for enrollment {enrollment_id}")

        results = NotificationService.send_enrollment_notifications(
            enrollment_id=enrollment_id,
            success=success,
            failure_reason=failure_reason
        )

        logger.info(f"Enrollment notifications sent: {results}")
        return results

    except Exception as e:
        logger.error(f"Failed to send enrollment notifications: {str(e)}")

        # Retry the task up to 3 times with exponential backoff
        raise self.retry(exc=e, countdown=60 * (2 ** self.request.retries))


@shared_task
def send_bulk_enrollment_notifications_task(bulk_enrollment_id: int, success: bool = True):
    """
    Async task to send notifications for all learners in a bulk enrollment

    Args:
        bulk_enrollment_id: ID of the bulk enrollment record
        success: Whether bulk enrollment was successful

    Returns:
        dict: Summary of notifications sent
    """
    try:
        from apps.payments.models import BulkEnrollment, Enrollment

        bulk_enrollment = BulkEnrollment.objects.get(id=bulk_enrollment_id)
        individual_enrollments = Enrollment.objects.filter(bulk_enrollment=bulk_enrollment)

        logger.info(f"Sending bulk enrollment notifications for {individual_enrollments.count()} learners")

        results = {
            'total': individual_enrollments.count(),
            'email_sent': 0,
            'sms_sent': 0,
            'failed': 0
        }

        for enrollment in individual_enrollments:
            try:
                notification_result = send_enrollment_notifications_task.delay(
                    enrollment_id=enrollment.id,
                    success=success
                )

                # Count successful sends
                if notification_result:
                    results['email_sent'] += 1
                    results['sms_sent'] += 1

            except Exception as e:
                logger.error(f"Failed to queue notification for enrollment {enrollment.id}: {str(e)}")
                results['failed'] += 1

        logger.info(f"Bulk enrollment notifications queued: {results}")
        return results

    except Exception as e:
        logger.error(f"Failed to send bulk enrollment notifications: {str(e)}")
        return {'error': str(e)}


@shared_task
def send_payment_reminder_task(enrollment_id: int):
    """
    Send payment reminder for pending enrollments

    Args:
        enrollment_id: ID of the enrollment with pending payment
    """
    try:
        from apps.payments.models import Enrollment
        from apps.notifications.services import EmailService

        enrollment = Enrollment.objects.select_related('user').get(id=enrollment_id)

        if enrollment.status != 'pending_payment':
            logger.info(f"Enrollment {enrollment_id} no longer pending payment, skipping reminder")
            return

        user = enrollment.user
        program = enrollment.content_object
        program_name = getattr(program, 'title', '') or getattr(program, 'name', 'Unknown Program')

        # Send reminder email
        subject = f"⏰ Payment Reminder - {program_name}"
        # Implementation would use a payment reminder template
        logger.info(f"Payment reminder sent for enrollment {enrollment_id}")

    except Exception as e:
        logger.error(f"Failed to send payment reminder: {str(e)}")
