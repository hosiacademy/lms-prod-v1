# apps/aicerts_courses/services.py
import requests
import logging
from django.utils import timezone
from apps.aicerts_courses.models import AiCertsCourse as RawCourse
from apps.industry_based_training.models import Industry, AiCertsCourse as IndustryCourse

logger = logging.getLogger(__name__)


def sync_courses():
    """Sync all courses from AICERTs public API (list + detail) and populate industries.
    
    Fetches paginated list from /courses, then full details from /course/{id} for each.
    Maps all visible fields from API v1.1 documentation.
    """
    base_url = 'https://www.aicerts.ai/wp-json/aicerts-api/v1'
    list_url = f'{base_url}/courses'
    per_page = 100
    page = 1
    all_courses = []

    try:
        # Fetch all pages from list endpoint
        while True:
            params = {'page': page, 'per_page': per_page}
            response = requests.get(list_url, params=params, timeout=30)
            response.raise_for_status()
            api_data = response.json()

            if not api_data.get('success'):
                raise ValueError("API success flag is false")

            courses_page = api_data.get('data', [])
            all_courses.extend(courses_page)

            total_pages = api_data.get('total_pages', 1)
            logger.info(f"Fetched page {page}/{total_pages} ({len(courses_page)} courses)")
            
            if page >= total_pages:
                break
            page += 1

        logger.info(f"Total courses fetched from list: {len(all_courses)}")

    except requests.RequestException as e:
        logger.error(f"List API fetch failed: {e}")
        raise ValueError(f"List API fetch failed: {e}")

    industry_stats = {}

    for item in all_courses:
        course_id = item.get('id')
        if not course_id:
            logger.warning(f"Skipping course without ID: {item}")
            continue

        # Fetch full detail for this course
        detail_url = f'{base_url}/course/{course_id}'
        try:
            detail_response = requests.get(detail_url, timeout=15)
            detail_response.raise_for_status()
            detail_data = detail_response.json()

            if not detail_data.get('success'):
                logger.warning(f"Detail API failed for course {course_id}")
                detail = {}
            else:
                detail = detail_data.get('data', {})
        except requests.RequestException as e:
            logger.warning(f"Detail fetch failed for course {course_id}: {e}")
            detail = {}

        # badge URL + JPG come ONLY from the list endpoint
        # feature image + JPG + ai_tools come ONLY from the detail endpoint
        # Merge: list as base, detail overrides only non-None values
        full_course_data = {**item}
        for k, v in detail.items():
            if v is not None or k not in full_course_data:
                full_course_data[k] = v

        # Ensure lms_course_id is never null
        lms_id_value = (
            full_course_data.get('lms_course_id')
            or str(course_id)
        )

        # 1. Sync to RAW courses (AiCertsCourse model)
        title = full_course_data.get('title', item.get('title', ''))
        categories = ', '.join(full_course_data.get('categories', []))[:499]
        
        stream_type = classify_course_stream_type(title, categories)
        
        raw_course, raw_created = RawCourse.objects.update_or_create(
            external_id=course_id,
            defaults={
                'title': title,
                'shortname': full_course_data.get('shortname', item.get('title', '')[:100]),
                'description': full_course_data.get('description', ''),
                'summary': full_course_data.get('summary', '') or full_course_data.get('description', '')[:200],
                'category_name': categories,
                # Badge fields from list endpoint
                'certificate_badge_url': item.get('certificate_badge_url', ''),
                'certificate_image_jpg_url': item.get('certificate_image_jpg_url', ''),
                # Feature image fields from detail endpoint
                'feature_image_url': detail.get('feature_image_url', ''),
                'feature_image_jpg_url': detail.get('feature_image_jpg_url', ''),
                'ai_tools': detail.get('ai_tools', []),
                'lms_course_id': lms_id_value,
                'price_individual': full_course_data.get('price_individual'),
                'price_package': full_course_data.get('price_package'),
                'is_in_package': full_course_data.get('is_in_package', False),
                'package_name': full_course_data.get('package_name', ''),
                'is_self_paced': full_course_data.get('is_self_paced', False),
                'is_offered': full_course_data.get('is_offered', False),
                'stream_type': stream_type,
                'raw_data': {
                    'list_item': item,
                    'detail_data': detail,
                    'full_combined': full_course_data,
                },
                'last_synced': timezone.now(),
            }
        )

        # 2. Determine industry
        industry_name = map_course_to_industry(
            raw_course.title,
            raw_course.category_name
        )
        industry, _ = Industry.objects.get_or_create(name=industry_name or 'General AI')

        # Track stats
        industry_stats[industry.name] = industry_stats.get(industry.name, 0) + 1

        # 3. Sync to INDUSTRY courses
        industry_course, ic_created = IndustryCourse.objects.update_or_create(
            raw_course=raw_course,
            course_id=str(course_id),
            defaults={
                'title': raw_course.title,
                'description': raw_course.description,
                'categories': raw_course.category_name,
                'certificate_badge_url': raw_course.certificate_badge_url,
                'feature_image_url': raw_course.feature_image_url,
                'lms_id': lms_id_value,
                'industry': industry,
                'last_synced': timezone.now(),
            }
        )

        action = "Created" if ic_created else "Updated"
        logger.info(f"✓ {action}: {raw_course.title[:50]}... -> {industry.name}")

    # Print industry statistics
    logger.info("\n=== INDUSTRY DISTRIBUTION ===")
    for industry_name, count in sorted(industry_stats.items(), key=lambda x: x[1], reverse=True):
        logger.info(f"{industry_name}: {count} courses")

    total_industries = len(industry_stats)
    total_courses = len(all_courses)
    logger.info(f"\nTotal: {total_courses} courses across {total_industries} industries")

    return total_courses


def map_course_to_industry(title, categories):
    """Map courses to industries based on keywords (case-insensitive)"""
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
        'General AI': [],  # Fallback
    }

    lower_title = title.lower()
    lower_categories = categories.lower() if categories else ''

    for industry_name, keywords in mapping.items():
        if any(keyword in lower_title or keyword in lower_categories for keyword in keywords):
            return industry_name

    return 'General AI'


def classify_course_stream_type(title, categories):
    """
    Classify course as 'technical' or 'professional' based on title and categories.
    
    Priority order:
    1. Check for explicit "Technical" or "Professional" in title/categories
    2. Check for technical role keywords (developer, engineer, etc.)
    3. Default to professional
    """
    lower_title = title.lower()
    lower_categories = categories.lower() if categories else ''
    combined = f"{lower_title} {lower_categories}"
    
    # PRIORITY 1: Check for explicit stream type keywords
    if 'technical' in lower_categories or 'technical' in lower_title:
        return 'technical'
    
    if 'professional' in lower_categories or 'professional' in lower_title:
        return 'professional'
    
    # PRIORITY 2: Check for technical role keywords
    technical_keywords = [
        'developer', 'development', 'engineer', 'engineering', 'programming',
        'coding', 'implementation', 'devops', 'cloud architect',
        'security analyst', 'data scientist', 'machine learning engineer',
        'blockchain developer', 'ai developer', 'software', 'programmer',
        'full stack', 'backend', 'frontend', 'mobile developer',
        'cybersecurity', 'network security', 'penetration testing',
        'data analytics', 'business intelligence', 'data engineer',
        'robotics', 'automation engineer', 'ai implementation',
        'vibe coder', 'ai+ developer', 'blockchain', 'smart contracts',
        'quantum', 'system engineer', 'ai technical',
    ]
    
    # Check for technical keywords
    for keyword in technical_keywords:
        if keyword in combined:
            return 'technical'
    
    # PRIORITY 3: Default to professional
    return 'professional'