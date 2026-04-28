from django.shortcuts import render
from django.http import JsonResponse
from django.core.paginator import Paginator
from django.db import models
from .models import Industry, AiCertsCourse, Offering
from .services import sync_courses

def course_list(request):
    """
    API Endpoint: List all industry & role-based training courses
    GET /api/v1/industry-training/courses/
    
    Query Parameters:
    - industry: Filter by industry ID or name
    - role: Filter by role (maps to categories)
    - search: Search in title and description
    - page: Page number (default: 1)
    - page_size: Items per page (default: 50)
    """
    # Trigger sync if no courses exist (auto-seed)
    if not AiCertsCourse.objects.exists():
        sync_courses()

    # Base queryset - only select_related('industry') to avoid raw_course schema issues
    queryset = AiCertsCourse.objects.select_related('industry').all().order_by('-last_synced')

    # Filter by industry
    industry = request.GET.get('industry')
    if industry:
        if industry.isdigit():
            queryset = queryset.filter(industry_id=industry)
        else:
            queryset = queryset.filter(industry__name__iexact=industry)

    # Filter by role (matches against categories)
    role = request.GET.get('role')
    if role:
        # Role filtering maps to course categories
        queryset = queryset.filter(categories__icontains=role)

    # Search filter
    search = request.GET.get('search')
    if search:
        queryset = queryset.filter(
            models.Q(title__icontains=search) | 
            models.Q(description__icontains=search)
        )

    # Pagination
    page_number = request.GET.get('page', 1)
    page_size = request.GET.get('page_size', 50)

    paginator = Paginator(queryset, page_size)
    page_obj = paginator.get_page(page_number)

    data = {
        'count': paginator.count,
        'total_pages': paginator.num_pages,
        'current_page': page_obj.number,
        'results': [
            {
                'id': c.id,
                'course_id': c.course_id,
                'title': c.title,
                'description': c.description,
                'industry': c.industry.name if c.industry else None,
                'industry_id': c.industry.id if c.industry else None,
                'categories': c.categories,
                'feature_image_url': c.feature_image_url,
                'certificate_badge_url': c.certificate_badge_url,
                'lms_id': c.lms_id,
                'price_usd': float(c.price) if c.price is not None else None,
            } for c in page_obj
        ]
    }
    return JsonResponse(data)

def industry_course_list(request, industry_id):
    # Sync courses on load (move to cron for production)
    sync_courses()

    industry = Industry.objects.get(id=industry_id)
    courses = AiCertsCourse.objects.filter(industry=industry)  # FIXED
    return render(request, 'industry_based_training/industry_course_list.html', {
        'industry': industry,
        'courses': courses
    })

def active_courses(request):
    """
    API Endpoint: List all active industry courses
    GET /api/v1/industry-training/active-courses/
    """
    # Trigger sync if no courses exist (auto-seed)
    if not AiCertsCourse.objects.exists():
        sync_courses()

    # Filtering
    industry_id = request.GET.get('industry')
    role_type = request.GET.get('role_type')
    
    queryset = AiCertsCourse.objects.select_related('raw_course').all().order_by('-last_synced')
    
    if industry_id:
        if industry_id.isdigit():
            queryset = queryset.filter(industry_id=industry_id)
        else:
            queryset = queryset.filter(industry__name__iexact=industry_id)
            
    # Pagination
    page_number = request.GET.get('page', 1)
    page_size = request.GET.get('page_size', 50)
    
    paginator = Paginator(queryset, page_size)
    page_obj = paginator.get_page(page_number)
    
    data = {
        'count': paginator.count,
        'total_pages': paginator.num_pages,
        'current_page': page_obj.number,
        'results': [
            {
                'id': c.id,
                'course_id': c.course_id,
                'title': c.title,
                'description': c.description,
                'industry': c.industry.name if c.industry else None,
                'industry_id': c.industry.id if c.industry else None,
                'categories': c.categories,
                'feature_image_url': c.feature_image_url,
                'certificate_badge_url': c.certificate_badge_url,
                'lms_id': c.lms_id,
                'price_usd': float(c.price) if c.price is not None else None,
            } for c in page_obj
        ]
    }
    return JsonResponse(data)

def list_industries(request):
    """
    API Endpoint: List all industries
    GET /api/v1/industry-training/industries/
    """
    # Trigger sync if no industries exist
    if not Industry.objects.exists():
        sync_courses()
        
    industries = Industry.objects.all().order_by('name')
    
    data = {
        'count': industries.count(),
        'results': [
            {
                'id': i.id,
                'name': i.name,
                'description': i.description,
                'course_count': i.industry_courses.count()
            } for i in industries
        ]
    }
    return JsonResponse(data)

def list_roles(request):
    """
    API Endpoint: List all available roles for industry training
    GET /api/v1/industry-training/roles/
    """
    # Since we don't have a distinct Roles table yet, we'll return a curated list of roles
    # that map to our course categories or job titles.
    roles = [
        {"id": "developer", "name": "Software Developer"},
        {"id": "manager", "name": "Project Manager"},
        {"id": "executive", "name": "Executive / C-Suite"},
        {"id": "analyst", "name": "Data Analyst"},
        {"id": "marketer", "name": "Digital Marketer"},
        {"id": "sales", "name": "Sales Representative"},
        {"id": "hr", "name": "HR Professional"},
        {"id": "operations", "name": "Operations Manager"},
        {"id": "finance", "name": "Financial Analyst"},
        {"id": "security", "name": "Cybersecurity Specialist"},
        {"id": "healthcare", "name": "Healthcare Professional"},
        {"id": "educator", "name": "Educator / Trainer"},
    ]
    
    return JsonResponse({
        "count": len(roles),
        "results": roles
    })