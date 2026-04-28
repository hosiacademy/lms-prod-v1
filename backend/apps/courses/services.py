import logging
from django.utils import timezone
from apps.courses.models import Course, CourseProvider
from apps.aicerts_courses.models import AiCertsCourse  # NEW table, not the old one

logger = logging.getLogger(__name__)

def sync_aicerts_into_courses():
    """
    Sync AICerts courses from the current AiCertsCourse model
    into the unified Course table.
    """
    # Ensure provider exists
    provider, _ = CourseProvider.objects.get_or_create(
        name="AICerts",
        defaults={"active": True}
    )

    synced_count = 0

    # Fetch all AICerts courses from the new model
    raw_courses = AiCertsCourse.objects.all()  # <- updated table reference
    for raw in raw_courses:
        course, created = Course.objects.update_or_create(
            external_id=raw.external_id,
            provider=provider,
            defaults={
                "title": raw.title,
                "summary": raw.summary or "",
                "category": raw.category_name or "",
                "active": True,
                "last_synced": timezone.now(),
            }
        )
        synced_count += 1
        logger.info(f"{'Created' if created else 'Updated'} course: {course.title}")

    return synced_count
