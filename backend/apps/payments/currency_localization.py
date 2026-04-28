import logging
import requests
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)

class IPLocationService:
    @staticmethod
    def get_location(ip_address):
        # Skip for local/private IPs
        if ip_address in ['127.0.0.1', 'localhost'] or ip_address.startswith('192.168.') or ip_address.startswith('10.'):
            return {'country_code': 'ZA', 'currency': 'ZAR'}

        cache_key = f"ip_loc_{ip_address}"
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data

        try:
            # Multi-provider fallback logic
            response = requests.get(f"https://ipapi.co/{ip_address}/json/", timeout=2)
            if response.status_code == 200:
                data = response.json()
                result = {
                    'country_code': data.get('country_code', 'ZA'),
                    'currency': data.get('currency', 'ZAR')
                }
                # Cache for 24 hours
                cache.set(cache_key, result, 86400)
                return result
        except Exception as e:
            logger.error(f"IP Location lookup failed for {ip_address}: {e}")

        return {'country_code': 'ZA', 'currency': 'ZAR'}

class CurrencyLocalizationMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')

        location = IPLocationService.get_location(ip)
        request.country_code = location['country_code']
        request.currency = location['currency']

        response = self.get_response(request)
        return response

PROFESSIONAL_COURSE_PRICE_USD = 250.00
TECHNICAL_COURSE_PRICE_USD = 450.00

class CurrencyLocalizationService:
    @staticmethod
    def format_price(usd_amount, currency_context):
        rate = currency_context.get('exchange_rate', 1.0)
        symbol = currency_context.get('currency_symbol', '$')
        local_price = round(float(usd_amount) * float(rate))
        return f"{symbol} {local_price}"

    @staticmethod
    def get_professional_course_price(currency_context):
        rate = currency_context.get('exchange_rate', 1.0)
        return float(PROFESSIONAL_COURSE_PRICE_USD) * float(rate)

    @staticmethod
    def get_technical_course_price(currency_context):
        rate = currency_context.get('exchange_rate', 1.0)
        return float(TECHNICAL_COURSE_PRICE_USD) * float(rate)

    @staticmethod
    def get_course_price(course, currency_context):
        price = getattr(course, 'price_individual', PROFESSIONAL_COURSE_PRICE_USD)
        if not price:
            price = PROFESSIONAL_COURSE_PRICE_USD
        rate = currency_context.get('exchange_rate', 1.0)
        return float(price) * float(rate)
