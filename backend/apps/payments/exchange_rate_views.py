"""
Exchange Rate API Views
Provides endpoints for currency conversion and rate fetching
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.http import JsonResponse
import logging
import requests

logger = logging.getLogger(__name__)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_exchange_rates(request):
    """
    Get cached exchange rates from database.
    Rates are fetched daily via Celery task.
    
    Returns:
    {
        'base': 'USD',
        'rates': {
            'ZAR': 18.5,
            'KES': 130.0,
            ...
        },
        'updated_at': '2024-03-08T10:00:00Z',
        'expires_at': '2024-03-09T10:00:00Z'
    }
    """
    try:
        from apps.payments.exchange_rate_models import ExchangeRate
        
        # Get all active, non-expired rates
        rates_qs = ExchangeRate.objects.filter(
            is_active=True,
            expires_at__gt=timezone.now()
        )
        
        if not rates_qs.exists():
            # No cached rates - trigger fetch task
            from apps.payments.tasks import fetch_exchange_rates
            fetch_exchange_rates.delay()
            
            return Response({
                'base': 'USD',
                'rates': {},
                'message': 'Fetching latest rates...',
                'updated_at': None,
                'expires_at': None
            }, status=status.HTTP_202_ACCEPTED)
        
        # Build rates dict
        rates = {}
        updated_at = None
        expires_at = None
        
        for rate_obj in rates_qs:
            rates[rate_obj.currency_code] = float(rate_obj.rate)
            if not updated_at or rate_obj.fetched_at > updated_at:
                updated_at = rate_obj.fetched_at
                expires_at = rate_obj.expires_at
        
        return Response({
            'base': 'USD',
            'rates': rates,
            'updated_at': updated_at.isoformat() if updated_at else None,
            'expires_at': expires_at.isoformat() if expires_at else None,
            'count': len(rates)
        })
        
    except Exception as e:
        logger.error(f"Failed to get exchange rates: {e}")
        return Response({
            'error': 'Failed to fetch exchange rates',
            'detail': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([AllowAny])
def convert_currency(request):
    """
    Convert amount from USD to local currency.
    
    Query params:
    - amount: Amount in USD (required)
    - currency: Target currency code (optional, defaults to detected)
    - country: Country code for detection (optional)
    
    Returns:
    {
        'amount_usd': 100.0,
        'amount_local': 1850.0,
        'currency': 'ZAR',
        'rate': 18.5,
        'formatted': 'R 1,850'
    }
    """
    try:
        from apps.payments.exchange_rate_models import ExchangeRate
        
        # Get amount
        amount_usd = request.query_params.get('amount', 0)
        try:
            amount_usd = float(amount_usd)
        except (ValueError, TypeError):
            return Response({
                'error': 'Invalid amount'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get target currency
        currency = request.query_params.get('currency', '').upper()
        country = request.query_params.get('country', '').upper()
        
        if not currency:
            # Detect from IP or country param
            from apps.payments.views import detect_location_view
            detect_response = detect_location_view(request)
            if detect_response and hasattr(detect_response, 'data'):
                currency = detect_response.data.get('currency', 'USD')
            else:
                currency = 'USD'
        
        # Get exchange rate
        if currency == 'USD':
            rate = 1.0
        else:
            rate_obj = ExchangeRate.get_rate(currency)
            if rate_obj:
                rate = float(rate_obj.rate)
            else:
                # Rate not found - trigger fetch and return USD
                from apps.payments.tasks import fetch_exchange_rates
                fetch_exchange_rates.delay()
                rate = 1.0
                currency = 'USD'
        
        # Calculate
        amount_local = amount_usd * rate
        
        # Format
        formatted = _format_currency(amount_local, currency)
        
        return Response({
            'amount_usd': amount_usd,
            'amount_local': amount_local,
            'currency': currency,
            'rate': rate,
            'formatted': formatted
        })
        
    except Exception as e:
        logger.error(f"Currency conversion failed: {e}")
        return Response({
            'error': 'Conversion failed',
            'detail': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _format_currency(amount, currency_code):
    """Format amount with currency symbol - WHOLE NUMBERS ONLY"""
    from apps.payments.exchange_rate_models import ExchangeRate
    
    rate_obj = ExchangeRate.get_rate(currency_code)
    symbol = rate_obj.currency_symbol if rate_obj else currency_code
    
    # WHOLE NUMBERS ONLY - NO THOUSANDS SEPARATOR
    formatted = str(round(float(amount)))
    
    return f"{symbol}{formatted}"
