"""
Django signals for enrollment notifications
Automatically notifies instructors when students enroll
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.db import connection
import logging

logger = logging.getLogger(__name__)


@receiver(post_save, sender='payments.Enrollment')
def enrollment_created_notification(sender, instance, created, **kwargs):
    """
    Send notification to instructor when new enrollment is created
    """
    if created:
        logger.info(f'New enrollment created: {instance.pk}, triggering instructor notification')
        
        try:
            # Import here to avoid circular imports
            from apps.notifications.instructor_notifications import instructor_notifications
            
            # Send notification asynchronously (in production, use Celery task)
            instructor_notifications.notify_instructor_on_enrollment(instance.pk)
            
        except Exception as e:
            logger.error(f'Failed to send instructor notification: {e}')
