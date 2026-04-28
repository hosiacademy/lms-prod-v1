# apps/facilitators/tasks.py

from celery import shared_task
from celery.utils.log import get_task_logger
from django.utils import timezone
from datetime import timedelta
import logging

logger = get_task_logger(__name__)


@shared_task(bind=True, max_retries=3)
def sync_courses_task(self):
    """
    Celery task to sync courses from AICerts API.
    """
    try:
        from .services import sync_courses_for_facilitators
        
        logger.info("Starting scheduled course sync from AICerts API...")
        result = sync_courses_for_facilitators()
        
        logger.info(
            f"Course sync completed: {result['synced']} courses synced, "
            f"{result['skipped']} skipped"
        )
        
        return {
            'status': 'success',
            'synced': result['synced'],
            'skipped': result['skipped'],
            'timestamp': timezone.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Course sync task failed: {e}")
        # Retry the task
        raise self.retry(exc=e, countdown=60)


@shared_task
def update_facilitator_performance_task():
    """
    Celery task to update facilitator performance metrics.
    """
    try:
        from .models import FacilitatorProfile
        
        logger.info("Starting facilitator performance update...")
        facilitators = FacilitatorProfile.objects.filter(is_active=True)
        updated = 0
        
        for facilitator in facilitators:
            facilitator.update_performance_metrics()
            updated += 1
        
        logger.info(f"Performance update completed: {updated} facilitators updated")
        
        return {
            'status': 'success',
            'updated': updated,
            'timestamp': timezone.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Performance update task failed: {e}")
        raise


@shared_task
def auto_assign_facilitators_task():
    """
    Celery task to auto-assign facilitators to available courses.
    """
    try:
        from .services import auto_assign_facilitators
        
        logger.info("Starting auto-assignment of facilitators...")
        assignments_made = auto_assign_facilitators()
        
        logger.info(f"Auto-assignment completed: {assignments_made} assignments made")
        
        return {
            'status': 'success',
            'assignments_made': assignments_made,
            'timestamp': timezone.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Auto-assignment task failed: {e}")
        raise


@shared_task
def generate_analytics_reports_task():
    """
    Celery task to generate analytics reports.
    """
    try:
        from datetime import date
        
        logger.info("Starting analytics report generation...")
        
        # Generate analytics for current period
        period_end = date.today()
        period_start = period_end - timedelta(days=30)
        
        # This would be more complex in reality
        # For now, just log that it was called
        
        logger.info(f"Analytics report period: {period_start} to {period_end}")
        
        return {
            'status': 'success',
            'period_start': period_start.isoformat(),
            'period_end': period_end.isoformat(),
            'timestamp': timezone.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Analytics generation task failed: {e}")
        raise


@shared_task
def send_appraisal_reminders_task():
    """
    Celery task to send performance appraisal reminders.
    """
    try:
        from .models import PerformanceAppraisal
        from django.core.mail import send_mail
        from django.conf import settings
        
        logger.info("Starting appraisal reminder emails...")
        
        # Find upcoming appraisals (next 7 days)
        today = timezone.now().date()
        next_week = today + timedelta(days=7)
        
        upcoming_appraisals = PerformanceAppraisal.objects.filter(
            status='scheduled',
            scheduled_date__gte=today,
            scheduled_date__lte=next_week
        ).select_related('facilitator__user', 'reviewer')
        
        sent_count = 0
        
        for appraisal in upcoming_appraisals:
            try:
                # Send email to facilitator
                send_mail(
                    subject=f"Upcoming Performance Appraisal: {appraisal.facilitator.user.name}",
                    message=(
                        f"Dear {appraisal.facilitator.user.name},\n\n"
                        f"Your performance appraisal is scheduled for "
                        f"{appraisal.scheduled_date.strftime('%B %d, %Y')}.\n\n"
                        f"Please ensure you have completed your self-assessment "
                        f"and have all necessary documents ready.\n\n"
                        f"Reviewer: {appraisal.reviewer.name if appraisal.reviewer else 'TBD'}\n\n"
                        f"Best regards,\nHosi Academy LMS Team"
                    ),
                    from_email='reviews@hosi.academy',
                    recipient_list=[appraisal.facilitator.user.email],
                    fail_silently=True,
                )
                
                sent_count += 1
                
            except Exception as e:
                logger.error(f"Failed to send reminder for appraisal {appraisal.id}: {e}")
        
        logger.info(f"Appraisal reminders sent: {sent_count} emails")
        
        return {
            'status': 'success',
            'emails_sent': sent_count,
            'timestamp': timezone.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Appraisal reminder task failed: {e}")
        raise


@shared_task
def cleanup_old_analytics_task():
    """
    Celery task to cleanup old analytics data.
    """
    try:
        from .models import FacilitatorAnalytics
        from datetime import date, timedelta
        from django.conf import settings
        
        logger.info("Starting cleanup of old analytics data...")
        
        # Get retention period from settings
        retention_days = settings.FACILITATORS_CONFIG.get('KEEP_ANALYTICS_HISTORY', 365)
        cutoff_date = date.today() - timedelta(days=retention_days)
        
        # Delete old analytics (keeping only current ones)
        deleted_count, _ = FacilitatorAnalytics.objects.filter(
            is_current=False,
            period_end__lt=cutoff_date
        ).delete()
        
        logger.info(f"Cleanup completed: {deleted_count} old analytics records deleted")
        
        return {
            'status': 'success',
            'deleted': deleted_count,
            'cutoff_date': cutoff_date.isoformat(),
            'timestamp': timezone.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Cleanup task failed: {e}")
        raise