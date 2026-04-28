# apps/payments/views/country_views.py
"""
API Views for country detection and payment provider selection
"""
import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page

from ..services.geolocation_service import geo_location_service
from ..services.payment_service import payment_service

logger = logging.getLogger(__name__)


@method_decorator(cache_page(60 * 5), name='get')  # Cache for 5 minutes
class DetectCountryView(APIView):
    """
    Detect user's country from IP address
    
    GET /api/payments/detect-country/
    
    Response:
    {
        "country_code": "ZW",
        "country_name": "Zimbabwe",
        "is_african": true,
        "ip_address": "197.80.0.1",
        "currency": "USD",
        "recommended_providers": ["paynow", "ecash", "telecash"]
    }
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        # Get IP address (from middleware or directly from request)
        ip_address = getattr(request, 'ip_address', None)
        if not ip_address:
            ip_address = request.META.get('HTTP_X_FORWARDED_FOR', '').split(',')[0].strip()
            if not ip_address:
                ip_address = request.META.get('REMOTE_ADDR', '')
        
        # Detect country
        country_code = geo_location_service.get_country_from_ip(ip_address)
        
        # Get location details
        location_details = geo_location_service.get_location_details(ip_address)
        
        # Get country name
        country_name = location_details.get('country_name', '')
        if not country_name and country_code:
            # Try to get from database
            from apps.localization.models import Country
            try:
                country = Country.objects.get(code=country_code)
                country_name = country.name
            except Country.DoesNotExist:
                country_name = country_code
        
        # Get recommended providers for this country
        recommended_providers = []
        currency = 'USD'
        
        if country_code:
            try:
                from ..models import CountryPaymentLandscape
                landscape = CountryPaymentLandscape.objects.get(country_code=country_code)
                recommended_providers = landscape.recommended_providers
                currency = landscape.local_currency
            except Exception:
                # Fallback: get from payment service
                try:
                    providers = payment_service.get_available_providers(country_code)
                    recommended_providers = [
                        p['code'] for p in providers if p.get('is_recommended')
                    ][:5]
                except Exception:
                    pass
        
        response_data = {
            'country_code': country_code,
            'country_name': country_name,
            'is_african': location_details.get('is_african', False) if country_code else False,
            'ip_address': ip_address,
            'currency': currency,
            'recommended_providers': recommended_providers,
            'detection_method': 'geoip2' if location_details.get('country_code') else 'fallback',
        }
        
        return Response(response_data)


class AvailableProvidersView(APIView):
    """
    Get available payment providers for a country
    
    GET /api/payments/providers/?country=ZW&amount=50&currency=USD
    
    Query Parameters:
        - country: Country code (optional, auto-detected from IP if not provided)
        - amount: Transaction amount (optional)
        - currency: Currency code (optional)
    
    Response:
    {
        "country": "ZW",
        "country_name": "Zimbabwe",
        "currency": "USD",
        "providers": [
            {
                "code": "paynow",
                "name": "Paynow",
                "category": "local_gateway",
                "methods": ["mobile_money", "ussd", "bank_transfer"],
                "currencies": ["USD", "ZWL"],
                "min_amount": 1.00,
                "max_amount": 10000.00,
                "fee_percentage": 2.5,
                "is_recommended": true,
                "priority": 1,
                "integration_status": "production"
            },
            ...
        ]
    }
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        # Get country from query param or detect from IP
        country_code = request.query_params.get('country')
        
        if not country_code:
            # Auto-detect from IP
            country_code = getattr(request, 'detected_country_code', None)
            
            if not country_code:
                ip_address = request.META.get('HTTP_X_FORWARDED_FOR', '').split(',')[0].strip()
                if not ip_address:
                    ip_address = request.META.get('REMOTE_ADDR', '')
                country_code = geo_location_service.get_country_from_ip(ip_address)
        
        # Default to Zimbabwe if still no country detected
        if not country_code:
            country_code = 'ZW'
        
        # Get amount and currency from query params
        amount = request.query_params.get('amount')
        currency = request.query_params.get('currency')
        
        if amount:
            try:
                amount = float(amount)
            except (ValueError, TypeError):
                amount = None
        
        # Get available providers
        try:
            providers = payment_service.get_available_providers(
                country=country_code,
                amount=amount,
                currency=currency
            )
        except Exception as e:
            logger.error(f"Error getting providers for {country_code}: {e}")
            providers = []
        
        # Get country name
        country_name = country_code
        try:
            from apps.localization.models import Country
            country = Country.objects.get(code=country_code)
            country_name = country.name
        except Exception:
            pass
        
        response_data = {
            'country': country_code,
            'country_name': country_name,
            'currency': currency or 'USD',
            'amount': amount,
            'providers': providers,
            'total_providers': len(providers),
        }
        
        return Response(response_data)


class CountryProvidersView(APIView):
    """
    Get all countries with their payment providers

    GET /api/payments/countries/

    Optional Query Parameters:
        - africa_only: Filter to African countries only (default: true)
        - include_providers: Include provider details (default: true)

    Response:
    {
        "countries": [
            {
                "code": "ZW",
                "name": "Zimbabwe",
                "currency": "USD",
                "mobile_money_penetration": 65.0,
                "recommended_providers": ["paynow", "ecash"],
                "dominant_methods": ["mobile_money", "ussd"]
            },
            ...
        ]
    }
    """
    permission_classes = [AllowAny]

    def get(self, request):
        africa_only = request.query_params.get('africa_only', 'true').lower() == 'true'
        include_providers = request.query_params.get('include_providers', 'true').lower() == 'true'

        from ..models import CountryPaymentLandscape

        # Get all landscapes
        landscapes = CountryPaymentLandscape.objects.all()

        # Filter to African countries if requested
        # Use a simple list of African country codes instead of AFRICAN_IP_RANGES
        if africa_only:
            african_codes = [
                'KE', 'ZW', 'ZA', 'NG', 'GH', 'TZ', 'UG', 'RW', 'ZM', 'MW', 'MZ',
                'BW', 'NA', 'SZ', 'LS', 'SN', 'CI', 'ML', 'BF', 'NE', 'TG', 'BJ',
                'CM', 'GA', 'CG', 'CD', 'CF', 'TD', 'GQ', 'ST', 'AO', 'EG', 'LY',
                'TN', 'MA', 'DZ', 'SD', 'SS', 'ET', 'ER', 'DJ', 'SO', 'KM', 'MG',
                'MU', 'SC', 'RE', 'YT', 'BI', 'CV', 'GM', 'GN', 'GW', 'LR', 'MR',
                'SL', 'EH'
            ]
            landscapes = landscapes.filter(country_code__in=african_codes)
        
        countries_data = []
        
        for landscape in landscapes:
            country_data = {
                'code': landscape.country_code,
                'name': landscape.country_name,
                'currency': landscape.local_currency,
                'mobile_money_penetration': float(landscape.mobile_money_penetration) if landscape.mobile_money_penetration else 0,
                'card_penetration': float(landscape.card_penetration) if landscape.card_penetration else 0,
                'internet_penetration': float(landscape.internet_penetration) if landscape.internet_penetration else 0,
                'dominant_methods': landscape.dominant_methods,
                'recommended_providers': landscape.recommended_providers,
            }
            
            if include_providers:
                try:
                    providers = payment_service.get_available_providers(landscape.country_code)
                    country_data['providers'] = providers
                    country_data['total_providers'] = len(providers)
                except Exception:
                    country_data['providers'] = []
                    country_data['total_providers'] = 0
            
            countries_data.append(country_data)
        
        # Sort by country name
        countries_data.sort(key=lambda x: x['name'])
        
        response_data = {
            'countries': countries_data,
            'total_countries': len(countries_data),
            'africa_only': africa_only,
        }
        
        return Response(response_data)


class TestIPDetectionView(APIView):
    """
    Test view for IP detection - useful for debugging
    
    GET /api/payments/test-ip-detection/?ip=197.80.0.1
    
    Query Parameters:
        - ip: IP address to test (optional, uses request IP if not provided)
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        test_ip = request.query_params.get('ip')
        
        if not test_ip:
            test_ip = request.META.get('HTTP_X_FORWARDED_FOR', '').split(',')[0].strip()
            if not test_ip:
                test_ip = request.META.get('REMOTE_ADDR', '')
        
        # Get detection result
        country_code = geo_location_service.get_country_from_ip(test_ip)
        location_details = geo_location_service.get_location_details(test_ip)
        
        # Check if African
        is_african = geo_location_service.is_african_ip(test_ip)
        
        response_data = {
            'tested_ip': test_ip,
            'detected_country_code': country_code,
            'location_details': location_details,
            'is_african': is_african,
            'detection_method': 'geoip2' if location_details.get('country_code') else 'fallback',
        }
        
        return Response(response_data)
