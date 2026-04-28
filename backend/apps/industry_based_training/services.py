# apps/industry_based_training/services.py
import requests
import logging
from django.utils import timezone
from apps.aicerts_courses.models import AiCertsCourse as RawCourse
from apps.industry_based_training.models import Industry, AiCertsCourse as IndustryCourse

logger = logging.getLogger(__name__)


def sync_courses():
    """
    Full sync of all AICERTS courses from the public API.
    - Fetches paginated courses (currently 67 across 7 pages as of Jan 2026)
    - Gets detailed data for each course
    - Syncs to RawCourse (aicerts_courses app)
    - Assigns industry based on title/categories
    - Syncs to IndustryCourse (this app) with nullable lms_id
    """
    base_url = 'https://www.aicerts.ai/wp-json/aicerts-api/v1/courses'
    per_page = 100  # Max allowed by API
    page = 1
    all_data = []

    logger.info("Starting full AICERTS courses sync...")

    try:
        while True:
            params = {'page': page, 'per_page': per_page}
            response = requests.get(base_url, params=params, timeout=15)
            response.raise_for_status()
            api_data = response.json()
            page_data = api_data.get('data', [])
            
            if not page_data:
                break
                
            all_data.extend(page_data)
            logger.info(f"Fetched page {page} — {len(page_data)} courses")
            
            page += 1
            if page > api_data.get('total_pages', 1):
                break
                
        logger.info(f"Total courses fetched from API: {len(all_data)}")
        
    except requests.RequestException as e:
        logger.error(f"API fetch failed: {e}")
        raise ValueError(f"Failed to fetch courses from AICERTS API: {e}")

    industry_stats = {}
    synced_count = 0
    skipped_count = 0

    for item in all_data:
        course_id = str(item['id'])
        title = item.get('title', 'Untitled Course')

        # Fetch detailed course info
        detail_url = f'https://www.aicerts.ai/wp-json/aicerts-api/v1/course/{course_id}'
        detail = {}
        try:
            detail_response = requests.get(detail_url, timeout=10)
            detail_response.raise_for_status()
            detail = detail_response.json().get('data', {})
        except requests.RequestException as e:
            logger.warning(f"Detail fetch failed for course {course_id} ({title}): {e}")

        # Safe lms_id handling - can be None now (model allows null=True)
        lms_id_value = (
            item.get('lms_course_id') or
            detail.get('lms_course_id') or
            None  # Explicit None if missing/empty
        )

        # 1. Sync to RAW courses (aicerts_courses.AiCertsCourse)
        raw_course, raw_created = RawCourse.objects.update_or_create(
            external_id=course_id,
            defaults={
                'title': title,
                'shortname': title[:100],
                'summary': item.get('description', ''),
                'category_name': ','.join(item.get('categories', [])),
                'raw_data': {
                    'api_data': item,
                    'detail_data': detail,
                    'certificate_badge_url': item.get('certificate_badge_url', ''),
                    'feature_image_url': detail.get('feature_image_url', ''),
                    'lms_course_id': lms_id_value,
                },
                'last_synced': timezone.now(),
            }
        )

        # 2. Map to industry
        industry_name = map_course_to_industry(title, ','.join(item.get('categories', [])))
        industry_name = industry_name or 'General AI'
        
        industry, _ = Industry.objects.get_or_create(name=industry_name)
        industry_stats[industry_name] = industry_stats.get(industry_name, 0) + 1

        # 3. Sync to IndustryCourse (with nullable lms_id)
        try:
            industry_course, ic_created = IndustryCourse.objects.update_or_create(
                course_id=course_id,
                defaults={
                    'raw_course': raw_course,
                    'title': title,
                    'description': item.get('description', ''),
                    'categories': ','.join(item.get('categories', [])),
                    'certificate_badge_url': item.get('certificate_badge_url', ''),
                    'feature_image_url': detail.get('feature_image_url', ''),
                    'lms_id': lms_id_value,  # Safe: can be None
                    'industry': industry,
                    'last_synced': timezone.now(),
                }
            )
            
            action = "Created" if ic_created else "Updated"
            logger.info(f"✓ {action}: {title[:60]}... → {industry.name} (lms_id: {lms_id_value})")
            synced_count += 1
            
        except Exception as e:
            logger.error(f"Failed to sync course {title} (id {course_id}): {e}")
            skipped_count += 1

    # Final statistics
    total_industries = len(industry_stats)
    logger.info("\n=== INDUSTRY DISTRIBUTION ===")
    for name, count in sorted(industry_stats.items(), key=lambda x: x[1], reverse=True):
        logger.info(f"{name}: {count} courses")

    logger.info(f"\nSync complete!")
    logger.info(f"Total courses processed: {len(all_data)}")
    logger.info(f"Successfully synced: {synced_count}")
    logger.info(f"Skipped/failed: {skipped_count}")
    logger.info(f"Total industries: {total_industries}")

    return synced_count


def map_course_to_industry(title: str, categories: str) -> str | None:
    """
    Bucket courses into industries based on title and categories keywords.
    Returns industry name or None (will default to 'General AI')
    """
    mapping = {
        'Healthcare': ['healthcare', 'health', 'doctor', 'medical', 'pharma', 'nurse', 'medical assistant', 'healthcare administrator'],
        'Mining': ['mining'],
        'Real Estate': ['real estate'],
        'Telecommunications': ['telecommunications', 'telecom'],
        'Finance': ['finance', 'banking', 'accounting', 'investment'],
        'Legal': ['legal', 'law', 'attorney', 'compliance'],
        'Sustainability': ['sustainability', 'environment', 'green'],
        'AI Agent': ['agent', 'automation', 'bot'],
        'Data & Robotics': ['data', 'robotics', 'machine learning', 'ai'],
        'Cloud Computing': ['cloud', 'aws', 'azure', 'google cloud'],
        'Software Development': ['development', 'developer', 'vibe coder', 'programming', 'coding'],
        'AI Ethics': ['ethics', 'responsible ai'],
        'Project Management': ['project management', 'project manager', 'program director', 'scrum'],
        'Product Management': ['product manager', 'product owner'],
        'Education': ['educator', 'learning', 'teacher', 'training'],
        'Executive': ['executive', 'chief', 'officer', 'ceo', 'cto', 'cfo'],
        'Supply Chain': ['supply chain', 'logistics', 'inventory'],
        'Marketing': ['marketing', 'digital marketing', 'seo', 'social media'],
        'Sales': ['sales', 'business development', 'bd'],
        'Customer Service': ['customer service', 'support', 'helpdesk'],
        'Human Resources': ['human resources', 'hr', 'recruitment', 'talent'],
        'Research': ['researcher', 'scientist', 'r&d'],
        'Government': ['government', 'policy maker', 'public sector'],
        'Security': ['security', 'hacker', 'network', 'compliance', 'cybersecurity'],
        'Audio': ['audio', 'sound', 'music'],
    }

    lower_title = title.lower()
    lower_categories = categories.lower() if categories else ''

    for industry_name, keywords in mapping.items():
        if any(keyword in lower_title or keyword in lower_categories for keyword in keywords):
            return industry_name

    return None