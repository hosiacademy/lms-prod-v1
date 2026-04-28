# apps/payments/middleware/currency_middleware.py
"""
Currency Localization Middleware
Automatically detects user location from IP and sets local currency context
"""

from django.utils import timezone
from apps.payments.currency_localization import IPLocationService, CurrencyLocalizationService


class CurrencyDetectionMiddleware:
    """
    Middleware that adds currency context to all requests.
    Detects user location from IP address and sets appropriate currency.
    
    NEVER defaults to USD - always uses detected local currency.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Detect currency from IP
        currency_context = CurrencyLocalizationService.get_price_context(request)
        
        # Add to request for views to access
        request.currency_context = currency_context
        request.local_currency = currency_context['currency_code']
        request.exchange_rate = currency_context['exchange_rate']
        request.is_usd = currency_context['is_usd']
        
        response = self.get_response(request)
        
        # Add currency headers for frontend
        response['X-Local-Currency'] = currency_context['currency_code']
        response['X-Exchange-Rate'] = str(currency_context['exchange_rate'])
        response['X-Is-USD'] = str(currency_context['is_usd'])
        
        return response
