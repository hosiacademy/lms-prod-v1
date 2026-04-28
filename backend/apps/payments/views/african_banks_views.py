"""
API Views for African Banks - Serve bank data from database
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework import status
from django.db.models import Q
from ..models import AfricanCountry, AfricanBank


class GetAfricanBanksView(APIView):
    """
    Get banks and payment providers for a specific African country
    
    GET /api/v1/payments/african-banks/?country=ZA
    GET /api/v1/payments/african-banks/?country=KE&category=payment_gateway
    GET /api/v1/payments/african-banks/?country=ZA&type=bank (only banks, no providers)
    
    Returns:
    {
        "country": {...},
        "banks": [...],
        "payment_providers": [...],
        "categories": {
            "commercial_bank": [],
            "payment_gateway": [],
            "mobile_money": [],
            "eft_provider": [],
            "qr_provider": []
        },
        "total_count": 50,
        "recommended_count": 5
    }
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        country_code = request.query_params.get('country', '').upper()
        category_filter = request.query_params.get('category', None)
        type_filter = request.query_params.get('type', None)
        recommended_only = request.query_params.get('recommended', 'false').lower() == 'true'
        
        if not country_code:
            return Response({
                'error': 'Country code is required (e.g., ?country=ZA)',
                'available_countries': list(AfricanCountry.objects.filter(is_active=True).values('code', 'name'))
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get country
        try:
            country = AfricanCountry.objects.get(code=country_code, is_active=True)
        except AfricanCountry.DoesNotExist:
            return Response({
                'error': f'Country {country_code} not found',
                'available_countries': list(AfricanCountry.objects.filter(is_active=True).values('code', 'name'))
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Get banks/providers
        banks_qs = AfricanBank.objects.filter(
            country=country,
            is_active=True
        ).select_related('country')
        
        # Apply filters
        if category_filter:
            banks_qs = banks_qs.filter(category=category_filter)
        
        if type_filter:
            banks_qs = banks_qs.filter(provider_type=type_filter)
        
        if recommended_only:
            banks_qs = banks_qs.filter(is_recommended=True)
        
        banks_qs = banks_qs.order_by('priority', 'name')
        
        # Build response with categorization
        banks_data = []
        payment_providers_data = []
        categories = {
            'commercial_bank': [],
            'payment_gateway': [],
            'mobile_money': [],
            'eft_provider': [],
            'qr_provider': [],
            'other': []
        }
        
        for bank in banks_qs:
            bank_dict = {
                'id': bank.id,
                'name': bank.name,
                'code': bank.code,
                'swift_code': bank.swift_code or '',
                'bank_code': bank.bank_code or '',
                'category': bank.category,
                'provider_type': bank.provider_type,
                'api_integration_code': bank.api_integration_code or bank.code,
                'is_recommended': bank.is_recommended,
                'priority': bank.priority,
                'supports_card': bank.supports_card,
                'supports_mobile_money': bank.supports_mobile_money,
                'supports_eft': bank.supports_eft,
                'supports_qr': bank.supports_qr,
                'logo_url': bank.logo_url or '',
            }
            
            # Categorize
            if bank.provider_type == 'payment_provider':
                payment_providers_data.append(bank_dict)
            else:
                banks_data.append(bank_dict)
            
            # Add to category
            cat = bank.category if bank.category in categories else 'other'
            categories[cat].append(bank_dict)
        
        return Response({
            'country': {
                'id': country.id,
                'code': country.code,
                'name': country.name,
                'currency': country.currency_code,
                'currency_symbol': country.currency_symbol or '',
            },
            'banks': banks_data,
            'payment_providers': payment_providers_data,
            'categories': categories,
            'total_count': len(banks_data) + len(payment_providers_data),
            'bank_count': len(banks_data),
            'provider_count': len(payment_providers_data),
            'recommended_count': sum(1 for b in banks_data + payment_providers_data if b['is_recommended']),
        })


class ListAfricanCountriesView(APIView):
    """
    List all African countries with banks
    
    GET /api/v1/payments/african-countries/
    
    Returns:
    {
        "countries": [
            {
                "code": "ZA",
                "name": "South Africa",
                "currency": "ZAR",
                "bank_count": 50
            },
            ...
        ]
    }
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        countries = AfricanCountry.objects.filter(
            is_active=True
        ).annotate(
            bank_count=models.Count('banks', filter=models.Q(banks__is_active=True))
        ).order_by('priority', 'name')
        
        countries_data = []
        for country in countries:
            countries_data.append({
                'code': country.code,
                'name': country.name,
                'currency': country.currency_code,
                'currency_symbol': country.currency_symbol or '',
                'bank_count': country.bank_count,
            })
        
        return Response({
            'countries': countries_data,
            'total_countries': len(countries_data),
        })


# Import models for annotation
from django.db import models
