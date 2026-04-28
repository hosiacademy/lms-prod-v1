# apps/learnerships/services.py
import requests
import logging
from django.utils import timezone
from apps.learnerships.models import Course, CourseProvider

logger = logging.getLogger(__name__)

def sync_aicerts_courses_into_system():
    provider_name = "AiCerts"
    provider, _ = CourseProvider.objects.get_or_create(name=provider_name)

    base_url = "https://www.aicerts.ai/wp-json/aicerts-api/v1/courses"
    per_page = 100
    page = 1
    all_courses = []

    while True:
        try:
            resp = requests.get(base_url, params={"page": page, "per_page": per_page})
            resp.raise_for_status()
            data = resp.json()
            courses = data.get("data", [])
            all_courses.extend(courses)
            if page >= data.get("total_pages", 1):
                break
            page += 1
        except requests.RequestException as e:
            logger.error(f"AICERTS API fetch failed: {e}")
            break

    for course_data in all_courses:
        c, created = Course.objects.update_or_create(
            external_id=course_data["id"],
            defaults={
                "provider": provider,
                "title": course_data["title"],
                "shortname": course_data["title"][:100],
                "summary": course_data.get("description") or "",
                "category_name": ",".join(course_data.get("categories") or []),
                "last_synced": timezone.now(),
                "active": True,
            }
        )
        logger.info(f"{'Created' if created else 'Updated'} course: {c.title}")

    return len(all_courses)
