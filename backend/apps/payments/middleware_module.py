# apps/payments/middleware.py
"""
Middleware for IP-based country detection
Automatically detects user's country from IP address and attaches to request
"""
import logging
from .services.geolocation_service import geo_location_service

logger = logging.getLogger(__name__)


class CountryDetectionMiddleware:
    """
    Middleware to detect user's country from IP address
    
    Adds the following attributes to request:
        - request.detected_country_code: ISO country code (e.g., 'ZW', 'KE')
        - request.is_african_user: Boolean indicating if user is from Africa
        - request.ip_address: Client IP address
    
    Usage in settings.py:
        MIDDLEWARE = [
            ...
            'apps.payments.middleware.CountryDetectionMiddleware',
            ...
        ]
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Get client IP address
        ip_address = self._get_client_ip(request)
        
        # Detect country from IP
        country_code = geo_location_service.get_country_from_ip(ip_address)
        
        # Attach to request
        request.ip_address = ip_address
        request.detected_country_code = country_code
        request.is_african_user = country_code is not None
        
        # Log detection for debugging
        if country_code:
            logger.debug(f"IP {ip_address} detected as country: {country_code}")
        else:
            logger.debug(f"Could not detect country for IP: {ip_address}")
        
        response = self.get_response(request)
        
        # Add country header to response (optional, for debugging)
        if country_code:
            response['X-Detected-Country'] = country_code
        
        return response
    
    def _get_client_ip(self, request):
        """
        Get client IP address from request, handling proxies and load balancers
        
        Checks headers in order of preference:
        1. X-Forwarded-For (most common for proxies)
        2. X-Real-IP (nginx)
        3. CF-Connecting-IP (Cloudflare)
        4. Remote addr (fallback)
        """
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            # X-Forwarded-For can contain multiple IPs: client, proxy1, proxy2
            # The first one is the client IP
            ip = x_forwarded_for.split(',')[0].strip()
            return ip
        
        x_real_ip = request.META.get('HTTP_X_REAL_IP')
        if x_real_ip:
            return x_real_ip
        
        cf_connecting_ip = request.META.get('HTTP_CF_CONNECTING_IP')
        if cf_connecting_ip:
            return cf_connecting_ip
        
        # Fallback to remote addr
        return request.META.get('REMOTE_ADDR', '')
