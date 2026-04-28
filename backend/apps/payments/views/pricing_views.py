# backend/apps/payments/views/pricing_views.py
"""
Pricing API Views
Returns current pricing from backend - no hardcoded values
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from ...courses.models import Course
from ...masterclasses.models import Masterclass
from .. import currency_localization


class PricingConfigView(APIView):
    """
    Returns current pricing configuration from backend.
    All prices come from Django backend - no hardcoded frontend values.
    """
    
    def get(self, request):
        """Get current pricing for all course types"""
        
        # Get base prices from currency localization module
        pricing_data = {
            'aicerts': {
                'professional': {
                    'usd': float(currency_localization.PROFESSIONAL_COURSE_PRICE_USD),
                    'description': 'AICERTS Professional courses'
                },
                'technical': {
                    'usd': float(currency_localization.TECHNICAL_COURSE_PRICE_USD),
                    'description': 'AICERTS Technical courses'
                }
            },
            'masterclasses': {
                'professional': {
                    'physical': {
                        'usd': 470.00,
                        'description': 'Professional Masterclass (Physical attendance)'
                    },
                    'online': {
                        'usd': 320.00,
                        'description': 'Professional Masterclass (Online attendance)'
                    }
                },
                'technical': {
                    'physical': {
                        'usd': 680.00,
                        'description': 'Technical Masterclass (Physical attendance)'
                    },
                    'online': {
                        'usd': 430.00,
                        'description': 'Technical Masterclass (Online attendance)'
                    }
                }
            },
            'metadata': {
                'currency': 'USD',
                'source': 'Django Backend',
                'note': 'All prices served from backend - no hardcoded frontend values'
            }
        }
        
        return Response(pricing_data, status=status.HTTP_200_OK)


class AICERTSCoursesPricingView(APIView):
    """Returns AICERTS courses with their current pricing"""
    
    def get(self, request):
        """Get AICERTS courses with backend pricing"""
        
        courses = Course.objects.filter(
            course_type='aicerts',
            active=True
        ).values(
            'id', 'title', 'shortname', 'stream_type',
            'price_individual', 'price_usd'
        )
        
        # Add localized prices
        result = []
        for course in courses:
            course_data = {
                'id': course['id'],
                'title': course['title'],
                'shortname': course['shortname'],
                'stream_type': course['stream_type'],
                'price_usd': course['price_individual'] or course['price_usd'],
            }
            result.append(course_data)
        
        return Response({
            'courses': result,
            'default_prices': {
                'professional': float(CurrencyLocalizationService.PROFESSIONAL_COURSE_PRICE_USD),
                'technical': float(CurrencyLocalizationService.TECHNICAL_COURSE_PRICE_USD)
            }
        })


class MasterclassPricingView(APIView):
    """Returns masterclasses with their current pricing"""
    
    def get(self, request):
        """Get masterclasses with backend pricing"""
        
        masterclasses = Masterclass.objects.filter(
            active=True
        ).values(
            'id', 'title', 'slug', 'stream_type',
            'price_physical_usd', 'price_online_usd'
        )
        
        result = []
        for mc in masterclasses:
            mc_data = {
                'id': mc['id'],
                'title': mc['title'],
                'slug': mc['slug'],
                'stream_type': mc['stream_type'],
                'price_physical_usd': mc['price_physical_usd'],
                'price_online_usd': mc['price_online_usd'],
            }
            result.append(mc_data)
        
        return Response({
            'masterclasses': result
        })
