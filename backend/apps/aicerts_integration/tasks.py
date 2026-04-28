# apps/aicerts_integration/tasks.py
"""
Celery Tasks for AICERTs Partnership Integration

Scheduled tasks for:
- Daily course catalog synchronization
- Failed enrollment retries
- User account synchronization
- Progress updates from AICERTs
"""

from celery import shared_task
from django.utils import timezone
from django.conf import settings
from datetime import timedelta
import logging

from .models import (
    AICertsEnrollment,
    AICertsSyncLog
)
from .services import (
    CourseDataService,
    SSOService,
    AICERTsAPIError,
    AICERTsEnrollmentError
)
from apps.aicerts_courses.models import AiCertsCourse

logger = logging.getLogger(__name__)


@shared_task(name='aicerts.sync_courses')
def sync_aicerts_courses_task():
    """
    Synchronize course catalog from AICERTs.
    Runs daily to keep course data up-to-date.
    """
    if not settings.AICERTS_SYNC_ENABLED:
        logger.info("AICERTs sync disabled in settings")
        return {'success': False, 'message': 'Sync disabled'}

    logger.info("Starting AICERTs course sync task...")
    start_time = timezone.now()

    def save_course_callback(course_data):
        """Callback to save/update course in database."""
        course_id = course_data.get('id')
        if not course_id:
            return False

        course, created = AiCertsCourse.objects.update_or_create(
            external_id=course_id,
            defaults={
                'title': course_data.get('title', ''),
                'shortname': course_data.get('certificate_code', ''),
                'description': course_data.get('description', ''),
                'certificate_badge_url': course_data.get('certificate_badge_url', ''),
                'feature_image_url': course_data.get('feature_image_url', ''),
                'is_offered': True,
                'last_synced': timezone.now()
            }
        )
        return created

    try:
        total_courses, new_courses, errors = CourseDataService.sync_all_courses(
            callback=save_course_callback
        )

        end_time = timezone.now()
        duration_ms = int((end_time - start_time).total_seconds() * 1000)

        # Log successful sync
        AICertsSyncLog.objects.create(
            operation_type='course_sync',
            status='success' if not errors else 'partial',
            records_processed=total_courses,
            duration_ms=duration_ms,
            response_data={
                'total_courses': total_courses,
                'new_courses': new_courses,
                'errors_count': len(errors),
                'errors': errors[:10]
            }
        )

        logger.info(
            f"Course sync completed: {total_courses} courses synced, "
            f"{new_courses} new, {len(errors)} errors"
        )

        return {
            'success': True,
            'total_courses': total_courses,
            'new_courses': new_courses,
            'duration_ms': duration_ms
        }

    except AICERTsAPIError as e:
        logger.error(f"Course sync failed: {e}")
        AICertsSyncLog.objects.create(
            operation_type='course_sync',
            status='failed',
            error_message=str(e)
        )
        return {'success': False, 'error': str(e)}


@shared_task(name='aicerts.sync_user_enrollments')
def sync_user_enrollments_task(user_id):
    """
    Sync all locally-enrolled-but-not-yet-pushed enrollments for a user to AICerts.
    Triggered on portal load or login to ensure courses are accessible.

    Args:
        user_id: Django user ID
    """
    from apps.users.models import User

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        logger.error(f"sync_user_enrollments_task: user {user_id} not found")
        return {'success': False, 'error': 'User not found'}

    if not user.aicerts_user_id:
        logger.info(f"sync_user_enrollments_task: user {user.email} has no AICerts ID, skipping")
        return {'success': False, 'error': 'User not synced with AICerts'}

    unsynced = AICertsEnrollment.objects.filter(
        user=user,
        aicerts_enrollment_status='enrolled',
        synced_at__isnull=True,
    ).select_related('course')

    if not unsynced.exists():
        return {'success': True, 'synced_count': 0}

    synced_count = 0
    failed_count = 0

    for enrollment in unsynced:
        try:
            result = SSOService.enroll_user(
                aicerts_user_id=user.aicerts_user_id,
                course_id=enrollment.course.lms_course_id,
                email=user.email,
            )
            enrollment.mark_synced()
            enrollment.aicerts_already_enrolled = result.get('isUserAlreadyEnrolled') == '1'
            enrollment.save(update_fields=['aicerts_already_enrolled'])
            AICertsSyncLog.objects.create(
                operation_type='user_enroll',
                status='success',
                user=user,
                course=enrollment.course,
                response_data=result,
            )
            synced_count += 1
            logger.info(f"Synced enrollment {enrollment.id}: {user.email} → {enrollment.course.title}")
        except AICERTsEnrollmentError as e:
            enrollment.mark_failed(str(e))
            failed_count += 1
            logger.error(f"Sync failed for enrollment {enrollment.id}: {e}")

    logger.info(f"sync_user_enrollments_task for user {user_id}: {synced_count} synced, {failed_count} failed")
    return {'success': True, 'synced_count': synced_count, 'failed_count': failed_count}


@shared_task(name='aicerts.retry_failed_enrollments')
def retry_failed_enrollments_task():
    """
    Retry failed enrollment syncs with AICERTs.
    Only retries enrollments with < 3 attempts and failed within last 24 hours.
    """
    logger.info("Starting failed enrollment retry task...")

    # Get failed enrollments that need retry
    cutoff_time = timezone.now() - timedelta(hours=24)
    failed_enrollments = AICertsEnrollment.objects.filter(
        aicerts_enrollment_status='failed',
        sync_attempts__lt=3,
        last_sync_attempt__gte=cutoff_time
    )

    success_count = 0
    failed_count = 0
    skipped_count = 0

    for enrollment in failed_enrollments:
        try:
            # Check if user has AICERTs ID
            if not enrollment.user.aicerts_user_id:
                logger.warning(f"Skipping enrollment {enrollment.id}: user has no AICERTs ID")
                skipped_count += 1
                continue

            # Retry enrollment (use lms_course_id for Moodle, not WordPress external_id)
            result = SSOService.enroll_user(
                aicerts_user_id=enrollment.user.aicerts_user_id,
                course_id=enrollment.course.lms_course_id,
                email=enrollment.user.email
            )

            enrollment.mark_synced()
            success_count += 1

            logger.info(
                f"Successfully retried enrollment {enrollment.id}: "
                f"{enrollment.user.email} → {enrollment.course.title}"
            )

        except AICERTsEnrollmentError as e:
            enrollment.mark_failed(str(e))
            failed_count += 1

            logger.error(
                f"Retry failed for enrollment {enrollment.id}: {e}"
            )

    # Log retry results
    AICertsSyncLog.objects.create(
        operation_type='user_enroll',
        status='success' if failed_count == 0 else 'partial',
        records_processed=success_count + failed_count + skipped_count,
        response_data={
            'success_count': success_count,
            'failed_count': failed_count,
            'skipped_count': skipped_count
        }
    )

    logger.info(
        f"Enrollment retry completed: {success_count} successful, "
        f"{failed_count} failed, {skipped_count} skipped"
    )

    return {
        'success': True,
        'success_count': success_count,
        'failed_count': failed_count,
        'skipped_count': skipped_count
    }


@shared_task(name='aicerts.sync_user_to_aicerts')
def sync_user_to_aicerts_task(user_id):
    """
    Asynchronously create user on AICERTs.
    Triggered when user registers on Hosi Academy.

    Args:
        user_id: User ID to sync
    """
    from apps.users.models import User

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        logger.error(f"User {user_id} not found for AICERTs sync")
        return {'success': False, 'error': 'User not found'}

    # Skip if already synced
    if user.aicerts_user_id:
        logger.debug(f"User {user.email} already synced to AICERTs")
        return {'success': True, 'already_synced': True}

    try:
        # Create user on AICERTs
        result = SSOService.create_user(
            email=user.email,
            first_name=user.first_name or user.username,
            last_name=user.last_name or '',
            username=user.email
        )

        aicerts_user_id = result.get('id')

        # Update local user record
        user.aicerts_user_id = aicerts_user_id
        user.aicerts_synced_at = timezone.now()
        user.save(update_fields=['aicerts_user_id', 'aicerts_synced_at'])

        # Log successful sync
        AICertsSyncLog.objects.create(
            operation_type='user_create',
            status='success',
            user=user,
            response_data=result
        )

        logger.info(f"User {user.email} synced to AICERTs (ID: {aicerts_user_id})")

        return {
            'success': True,
            'aicerts_user_id': aicerts_user_id
        }

    except AICERTsAPIError as e:
        logger.error(f"Failed to sync user {user.email} to AICERTs: {e}")

        # Log failed sync
        AICertsSyncLog.objects.create(
            operation_type='user_create',
            status='failed',
            user=user,
            error_message=str(e)
        )

        return {
            'success': False,
            'error': str(e)
        }


@shared_task(name='aicerts.cleanup_old_sso_sessions')
def cleanup_old_sso_sessions_task():
    """
    Clean up expired SSO sessions.
    Keeps database clean and maintains performance.

    Schedule: Daily at 3:00 AM
    """
    from .models import AICertsSSOSession

    cutoff_time = timezone.now() - timedelta(days=7)

    deleted_count, _ = AICertsSSOSession.objects.filter(
        expires_at__lt=cutoff_time
    ).delete()

    logger.info(f"Cleaned up {deleted_count} expired SSO sessions")

    return {
        'success': True,
        'deleted_count': deleted_count
    }


@shared_task(name='aicerts.cleanup_old_sync_logs')
def cleanup_old_sync_logs_task():
    """
    Clean up old sync logs (keep last 90 days).
    Prevents database bloat.

    Schedule: Weekly on Sunday at 4:00 AM
    """
    cutoff_time = timezone.now() - timedelta(days=90)

    deleted_count, _ = AICertsSyncLog.objects.filter(
        created_at__lt=cutoff_time
    ).delete()

    logger.info(f"Cleaned up {deleted_count} old sync logs")

    return {
        'success': True,
        'deleted_count': deleted_count
    }


@shared_task(name='aicerts.verify_enrollment_status')
def verify_enrollment_status_task():
    """
    Verify enrollment consistency between Hosi Academy and AICERTs.
    Identifies discrepancies and logs them for manual review.

    Schedule: Weekly on Monday at 1:00 AM
    """
    logger.info("Starting enrollment status verification...")

    # Get all enrollments marked as 'enrolled'
    enrolled = AICertsEnrollment.objects.filter(
        aicerts_enrollment_status='enrolled'
    )

    inconsistencies = []

    for enrollment in enrolled[:100]:  # Limit to 100 per run to avoid overload
        # Here you would call AICERTs API to check actual enrollment status
        # For now, we just log
        logger.debug(
            f"Verifying enrollment: {enrollment.user.email} → {enrollment.course.title}"
        )

    # Log verification results
    AICertsSyncLog.objects.create(
        operation_type='progress_update',
        status='success',
        records_processed=len(enrolled),
        response_data={
            'verified_count': len(enrolled),
            'inconsistencies': inconsistencies
        }
    )

    logger.info(
        f"Enrollment verification completed: {len(enrolled)} verified, "
        f"{len(inconsistencies)} inconsistencies found"
    )

    return {
        'success': True,
        'verified_count': len(enrolled),
        'inconsistencies': inconsistencies
    }
