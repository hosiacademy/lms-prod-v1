# apps/instructors/services.py

from django.db.models import Q, F, Count, Avg, Max
from django.utils import timezone
from datetime import timedelta
import logging
import requests

from apps.aicerts_courses.models import AiCertsCourse
from .models import Instructor, CourseAssignment, InstructorRating

logger = logging.getLogger(__name__)


def sync_courses_for_instructors(force: bool = False) -> dict:
    """
    Full sync: Fetch all courses from AICERTs public API, sync them to AiCertsCourse model,
    skip self-paced if needed, and return stats for instructor assignment preparation.

    Args:
        force (bool): If True, force sync even if recent sync exists

    Returns:
        dict: {'synced': int, 'skipped': int, 'total': int}
    """
    base_url = 'https://www.aicerts.ai/wp-json/aicerts-api/v1/courses'
    per_page = 100
    page = 1
    params = {'page': page, 'per_page': per_page}

    # Optional: Skip if last sync was recent (unless force=True)
    if not force:
        last_sync = AiCertsCourse.objects.aggregate(last=Max('last_synced'))['last']
        if last_sync and timezone.now() - last_sync < timedelta(hours=24):
            logger.info("Recent sync detected - skipping unless --force used")
            return {'synced': 0, 'skipped': 0, 'total': 0}

    logger.info("Starting full AICERTs course sync for instructors...")

    try:
        # Fetch first page
        response = requests.get(base_url, params=params, timeout=30)
        response.raise_for_status()
        api_data = response.json()
        all_courses = api_data.get('data', [])

        # Fetch remaining pages
        total_pages = api_data.get('total_pages', 1)
        for p in range(2, total_pages + 1):
            params['page'] = p
            response = requests.get(base_url, params=params, timeout=30)
            response.raise_for_status()
            all_courses += response.json().get('data', [])

        synced = 0
        skipped = 0

        for item in all_courses:
            # Skip self-paced courses
            if 'self-paced' in item.get('title', '').lower() or item.get('type') == 'self-paced':
                skipped += 1
                continue

            # Sync to AiCertsCourse model
            course, created = AiCertsCourse.objects.update_or_create(
                external_id=str(item['id']),
                defaults={
                    'title': item['title'],
                    'shortname': item['title'][:100],
                    'summary': item.get('description', ''),
                    'category_name': ','.join(item.get('categories', [])),
                    'raw_data': {
                        'api_data': item,
                        'certificate_badge_url': item.get('certificate_badge_url', ''),
                        'feature_image_url': item.get('feature_image_url', ''),
                        'lms_course_id': item.get('lms_course_id', ''),
                    },
                    'last_synced': timezone.now(),
                }
            )

            if created:
                synced += 1
                logger.info(f"Created new course: {item['title'][:60]}...")
            else:
                synced += 1
                logger.debug(f"Updated existing course: {item['title'][:60]}...")

        total = len(all_courses)
        logger.info(f"Sync complete: {synced} courses processed, {skipped} skipped, total fetched: {total}")

        return {'synced': synced, 'skipped': skipped, 'total': total}

    except requests.RequestException as e:
        logger.error(f"AICERTs API fetch failed: {e}")
        raise ValueError(f"AICERTs API fetch failed: {e}")
    except Exception as e:
        logger.error(f"Unexpected error during sync: {e}")
        raise


def suggest_instructor_for_course(course, limit=5):
    """
    Suggest instructors for a course based on specialization, performance, and availability.
    """
    try:
        instructors = Instructor.objects.filter(
            is_active=True,
            is_available=True
        ).annotate(
            current_count=Count('course_assignments', filter=Q(course_assignments__status__in=['assigned', 'ongoing']))
        ).filter(
            current_count__lt=F('max_courses')
        )

        suggestions = []
        for instructor in instructors:
            score = calculate_instructor_suitability(instructor, course)
            suggestions.append({
                'instructor': instructor,
                'score': score
            })

        suggestions.sort(key=lambda x: x['score'], reverse=True)
        return [s['instructor'] for s in suggestions[:limit]]

    except Exception as e:
        logger.error(f"Error suggesting instructor for course {course}: {e}")
        return Instructor.objects.none()


def calculate_instructor_suitability(instructor, course):
    """
    Calculate a suitability score for an instructor for a specific course (0-100).
    """
    score = 0.0

    # 1. Performance score (40% weight)
    performance_score = instructor.overall_rating * 0.4

    # 2. Availability score (30% weight)
    utilization = instructor.utilization_rate
    availability_score = max(0, 100 - utilization) * 0.3

    # 3. Experience score (20% weight)
    experience_score = min(instructor.years_experience * 2, 100) * 0.2

    # 4. Specialization match score (10% weight)
    specialization_score = 0.0
    if instructor.specialization and course.title:
        specialization_keywords = [kw.lower() for kw in instructor.specialization.split(',')]
        course_keywords = course.title.lower().split()
        matches = sum(1 for kw in specialization_keywords if any(kw in word for word in course_keywords))
        specialization_score = min(matches * 20, 100) * 0.1

    score = performance_score + availability_score + experience_score + specialization_score
    return min(score, 100)


def update_instructor_performance(instructor_id):
    """
    Update performance metrics for a specific instructor.
    """
    try:
        instructor = Instructor.objects.get(id=instructor_id)

        ratings = InstructorRating.objects.filter(instructor=instructor)
        avg_rating = ratings.aggregate(avg=Avg('rating'))['avg'] if ratings.exists() else 0.0

        total_assignments = instructor.course_assignments.count()
        completed_assignments = instructor.course_assignments.filter(status='completed').count()

        completion_rate = (completed_assignments / total_assignments * 100) if total_assignments > 0 else 0.0

        overall_rating = (avg_rating * 20 * 0.6) + (completion_rate * 0.4)
        instructor.overall_rating = min(overall_rating, 100)

        # Set performance band
        if instructor.overall_rating >= 90:
            instructor.performance_band = 'excellent'
        elif instructor.overall_rating >= 75:
            instructor.performance_band = 'good'
        elif instructor.overall_rating >= 60:
            instructor.performance_band = 'satisfactory'
        elif instructor.overall_rating >= 40:
            instructor.performance_band = 'needs_improvement'
        else:
            instructor.performance_band = 'poor'

        instructor.save()
        logger.info(f"Updated performance for {instructor.instructor_id}: rating={instructor.overall_rating:.1f}")
        return True

    except Instructor.DoesNotExist:
        logger.error(f"Instructor {instructor_id} not found")
        return False
    except Exception as e:
        logger.error(f"Error updating performance: {e}")
        return False


def auto_assign_instructors():
    """
    Automatically assign unassigned courses to suitable instructors (scheduled task).
    """
    try:
        unassigned_courses = AiCertsCourse.objects.filter(
            is_active=True
        ).exclude(
            instructor_assignments__status__in=['assigned', 'ongoing']
        )[:10]

        assignments_made = 0

        for course in unassigned_courses:
            suggestions = suggest_instructor_for_course(course, limit=3)
            if suggestions:
                instructor = suggestions[0]
                CourseAssignment.objects.create(
                    instructor=instructor,
                    course=course,
                    status='assigned',
                    start_date=timezone.now().date(),
                    expected_end_date=timezone.now().date() + timedelta(days=30)
                )
                assignments_made += 1
                logger.info(f"Auto-assigned {instructor} to {course.title}")

        logger.info(f"Auto-assignment complete: {assignments_made} new assignments")
        return assignments_made

    except Exception as e:
        logger.error(f"Auto-assign error: {e}")
        return 0
