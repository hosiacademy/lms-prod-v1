"""
Custom middleware for production hardening.
Includes rate limiting, security headers, and request tracking.
"""
import time
import logging
from django.core.cache import cache
from django.http import JsonResponse
from django.conf import settings

logger = logging.getLogger(__name__)


class RateLimitMiddleware:
    """
    Rate limiting middleware using Redis.
    Limits requests per IP address per time window.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Skip rate limiting for health checks
        if request.path.startswith('/health/') or request.path.startswith('/api/health/'):
            return self.get_response(request)

        # Get client IP
        ip = self.get_client_ip(request)

        # Different limits for different endpoints
        limit, window = self.get_rate_limit(request.path)

        if limit and not self.check_rate_limit(ip, request.path, limit, window):
            logger.warning(f"Rate limit exceeded for IP {ip} on {request.path}")
            return JsonResponse({
                'error': 'Rate limit exceeded',
                'message': f'Too many requests. Please try again later.',
                'retry_after': window
            }, status=429)

        response = self.get_response(request)
        return response

    def get_client_ip(self, request):
        """Get client IP from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '')

    def get_rate_limit(self, path):
        """Get rate limit settings based on path."""
        # Payment endpoints - very strict
        if '/payments/' in path:
            return (5, 60)  # 5 requests per minute

        # Authentication endpoints - strict
        if any(x in path for x in ['/auth/', '/login/', '/register/', '/password']):
            return (10, 60)  # 10 requests per minute

        # API endpoints - moderate
        if path.startswith('/api/'):
            return (60, 60)  # 60 requests per minute

        # General - lenient
        return (120, 60)  # 120 requests per minute

    def check_rate_limit(self, ip, path, limit, window):
        """Check if request is within rate limit."""
        cache_key = f'rate_limit:{ip}:{path}'
        current = cache.get(cache_key, 0)

        if current >= limit:
            return False

        # Increment counter
        if current == 0:
            cache.set(cache_key, 1, window)
        else:
            cache.incr(cache_key)

        return True


class SecurityHeadersMiddleware:
    """
    Add additional security headers beyond Django's built-in headers.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        # Content Security Policy
        if not settings.DEBUG:
            response['Content-Security-Policy'] = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net; "
                "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
                "font-src 'self' https://fonts.gstatic.com; "
                "img-src 'self' data: https:; "
                "connect-src 'self' https://api.flutterwave.com https://api.paystack.co;"
            )

        # Permissions Policy (formerly Feature-Policy)
        response['Permissions-Policy'] = (
            "geolocation=(), "
            "microphone=(), "
            "camera=(), "
            "payment=(self)"
        )

        # Additional headers
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['X-XSS-Protection'] = '1; mode=block'

        return response


class RequestTimingMiddleware:
    """
    Track request timing and add to response headers.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start_time = time.time()

        response = self.get_response(request)

        # Calculate request duration
        duration = time.time() - start_time

        # Add timing header
        response['X-Request-Duration'] = f'{duration:.3f}s'

        # Log slow requests
        if duration > 1.0:
            logger.warning(
                f'Slow request: {request.method} {request.path} took {duration:.3f}s'
            )

        return response
