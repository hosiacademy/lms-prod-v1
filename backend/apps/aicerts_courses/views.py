from rest_framework import viewsets, filters, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny  # ← Import AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from .models import AiCertsCourse
from .serializers import AiCertsCourseSerializer, AiCertsCourseListSerializer

class AiCertsCourseViewSet(viewsets.ModelViewSet):
    """API endpoint for AICerts courses"""
    queryset = AiCertsCourse.objects.all()
    serializer_class = AiCertsCourseSerializer
    permission_classes = [AllowAny]  # ← CHANGED: Now public / no auth required
    pagination_class = None  # Disable pagination - return all courses at once
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['provider', 'is_offered', 'is_self_paced', 'is_in_package']
    search_fields = ['title', 'shortname', 'summary', 'category_name']
    ordering_fields = ['last_synced', 'title', 'price_individual']
    ordering = ['-last_synced']
    def get_serializer_class(self):
        """Use different serializers for list vs detail"""
        if self.action == 'list':
            return AiCertsCourseListSerializer
        return AiCertsCourseSerializer

@api_view(['GET'])
@permission_classes([AllowAny])
def custom_selection_catalog(request):
    """
    API Endpoint: Catalog for Custom Selection Page
    GET /api/v1/courses/custom-selection-catalog/
    """
    from apps.industry_based_training.models import Offering
    from django.conf import settings
    import urllib.parse

    courses = AiCertsCourse.objects.filter(is_offered=True).order_by('title')
    
    # If no courses marked offered, just return all (fallback)
    if not courses.exists():
        courses = AiCertsCourse.objects.all().order_by('title')

    def proxy_url(url):
        """
        Convert AICERTS image URLs to backend proxy URLs.
        Returns RELATIVE paths (starting with /) to avoid double-proxying.
        """
        if not url:
            return None
        if 'aicerts.ai' in url:
            proxy_path = "/api/v1/courses/masterclasses/proxy/image/"
            encoded_url = urllib.parse.quote(url)
            # Return RELATIVE URL (not absolute) to prevent double-proxying
            final_url = f"{proxy_path}?url={encoded_url}"
            if url.lower().endswith('.svg'):
                final_url += "&format=svg"
            return final_url
        return url

    # Fetch Offerings as Bundles
    offerings = Offering.objects.all().prefetch_related('courses')
    bundles = []
    
    from apps.payments.services.geolocation_service import GeolocationService
    from apps.payments.services.currency_service import CurrencyConversionService
    from decimal import Decimal

    country = 'ZA'  # Default to South Africa
    currency = 'ZAR'
    
    try:
        for o in offerings:
            # Use proxy for bundle image if it's from aicerts
            raw_bundle_image = o.courses.first().feature_image_url if o.courses.exists() else None
            
            bundle_price = Decimal(str(o.price_usd)) if getattr(o, 'price_usd', None) else Decimal('0.0')
            bundle_price_info = CurrencyConversionService.get_localized_price(bundle_price, currency)
            
            bundles.append({
                'id': f'bundle_{o.id}',
                'title': o.name,
                'description': o.description,
                'price': float(bundle_price_info['amount']),
                'currency': currency,
                'formatted_price': bundle_price_info['formatted'],
                'course_count': o.courses.count(),
                'courses': [
                    {
                        'id': c.raw_course.id if c.raw_course else c.id,
                        'title': c.title,
                        'image_url': proxy_url(c.feature_image_url)
                    } for c in o.courses.all()
                ],
                'course_type': 'bundle',
                'image_url': proxy_url(raw_bundle_image)
            })
    except Exception as e:
        # If there's a DB issue with Offerings, just log it and continue
        import logging
        logging.error(f"Error fetching offerings: {e}")

    results = []
    for c in courses:
        usd_price_ind = Decimal(str(c.price_individual)) if getattr(c, 'price_individual', None) else Decimal('100.0')
        price_info = CurrencyConversionService.get_localized_price(usd_price_ind, currency)
        
        results.append({
            'id': c.id,
            'external_id': c.external_id,
            'title': c.title,
            'summary': c.summary,
            'description': c.description,
            'category': c.category_name,
            'price': float(price_info['amount']),
            'currency': currency,
            'formatted_price': price_info['formatted'],
            'price_usd': float(usd_price_ind),
            'price_package': float(c.price_package) if getattr(c, 'price_package', None) else None,
            'image_url': proxy_url(c.feature_image_url or c.certificate_badge_url),
            'feature_image_url': proxy_url(c.feature_image_url or c.certificate_badge_url),
            'certificate_badge_url': proxy_url(c.certificate_badge_url),
            'is_self_paced': c.is_self_paced,
            'is_in_package': c.is_in_package,
            'course_type': 'custom_selection',
            'provider': 'aicerts'
        })
        
    data = {
        'count': courses.count(),
        'results': results,
        'bundles': bundles
    }
    return Response(data)
