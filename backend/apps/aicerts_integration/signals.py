# apps/aicerts_integration/signals.py
"""
Signals for AICERTs Partnership Integration

Handles:
- Automatic user synchronization with AICERTs on registration
- Instructor validation for course assignments
- Enrollment tracking
"""

from django.db.models.signals import post_save, pre_save, m2m_changed
from django.dispatch import receiver
from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone
import logging
import time

from apps.users.models import User
from .models import (
    AICertsEnrollment,
    AICertsInstructorDesignation,
    AICertsSyncLog
)
from .services import (
    SSOService,
    AICERTsAPIError
)

logger = logging.getLogger(__name__)


@receiver(post_save, sender=User)
def auto_create_aicerts_user(sender, instance, created, **kwargs):
    """
    Automatically create user on AICERTs when they register on Hosi Academy.
    Only runs if AICERTS_AUTO_CREATE_USERS is enabled and user is email verified.
    """
    if not created:
        # Only run for new users
        return

    if not settings.AICERTS_AUTO_CREATE_USERS:
        logger.debug("Auto-create AICERTs users disabled in settings")
        return

    if not instance.email:
        logger.warning(f"User {instance.id} has no email, skipping AICERTs creation")
        return

    # Skip if user already has AICERTs ID
    if instance.aicerts_user_id:
        logger.debug(f"User {instance.email} already has AICERTs ID: {instance.aicerts_user_id}")
        return

    # Check if email is verified (optional - adjust based on requirements)
    if not instance.email_verified_at:
        logger.info(f"User {instance.email} email not verified, skipping AICERTs creation")
        return

    try:
        # Create user on AICERTs
        result = SSOService.create_user(
            email=instance.email,
            first_name=instance.first_name or instance.username,
            last_name=instance.last_name or '',
            username=instance.email
        )

        aicerts_user_id = result.get('id')

        # Update local user record (aicerts_synced_at is a numeric epoch timestamp)
        User.objects.filter(pk=instance.pk).update(
            aicerts_user_id=aicerts_user_id,
            aicerts_synced_at=time.time()
        )

        # Log successful sync
        AICertsSyncLog.objects.create(
            operation_type='user_create',
            status='success',
            user=instance,
            response_data=result
        )

        logger.info(f"Created AICERTs user for {instance.email} (ID: {aicerts_user_id})")

    except AICERTsAPIError as e:
        logger.error(f"Failed to create AICERTs user for {instance.email}: {e}")

        # Log failed sync
        AICertsSyncLog.objects.create(
            operation_type='user_create',
            status='failed',
            user=instance,
            error_message=str(e)
        )


@receiver(m2m_changed, sender=User.aicerts_instructor_courses.through)
def validate_instructor_designation(sender, instance, action, pk_set, **kwargs):
    """
    Validate that only registered AICERTs instructors can be assigned courses.
    Enforces partnership rule: must be is_aicerts_instructor=True.
    """
    if action != "pre_add":
        return

    if not instance.is_aicerts_instructor:
        raise ValidationError(
            f"User {instance.get_full_name()} ({instance.email}) is not a registered "
            f"AICERTs instructor. Please set is_aicerts_instructor=True before "
            f"assigning courses."
        )

    # Optionally: Check if instructor has AICERTs account
    if not instance.aicerts_user_id:
        logger.warning(
            f"Instructor {instance.email} is marked as AICERTs instructor but has no "
            f"AICERTs user ID. They may need to be created on AICERTs first."
        )


@receiver(post_save, sender=AICertsEnrollment)
def trigger_enrollment_sync_on_create(sender, instance, created, **kwargs):
    """
    When a new enrollment is created with status='enrolled' but not yet synced,
    fire a background task to push it to AICerts immediately.
    """
    if not created:
        return
    if instance.aicerts_enrollment_status != 'enrolled':
        return
    if instance.synced_at is not None:
        return
    user = instance.user
    if not getattr(user, 'aicerts_user_id', None):
        return
    try:
        from .tasks import sync_user_enrollments_task
        sync_user_enrollments_task.delay(user.id)
    except Exception as e:
        logger.warning(f"Could not fire sync task for enrollment {instance.id}: {e}")


@receiver(post_save, sender=AICertsEnrollment)
def log_enrollment_changes(sender, instance, created, **kwargs):
    """
    Log enrollment status changes for audit trail.
    """
    if created:
        logger.info(
            f"New enrollment created: {instance.user.email} → {instance.course.title} "
            f"(status: {instance.aicerts_enrollment_status})"
        )


@receiver(pre_save, sender=User)
def validate_aicerts_instructor_flag(sender, instance, **kwargs):
    """
    Log when users are marked as AICERTs instructors.
    Helps admins track instructor registrations.
    """
    if instance.pk:  # Only for existing users
        try:
            old_instance = User.objects.get(pk=instance.pk)
            if not old_instance.is_aicerts_instructor and instance.is_aicerts_instructor:
                logger.info(
                    f"User {instance.email} marked as AICERTs instructor "
                    f"(AICERTs ID: {instance.aicerts_user_id})"
                )
        except User.DoesNotExist:
            pass
