# apps/facilitators/middleware.py

from django.utils.deprecation import MiddlewareMixin
from django.core.cache import cache
import time


class FacilitatorMiddleware(MiddlewareMixin):
    """
    Middleware to add facilitator context and track performance.
    """
    
    def process_request(self, request):
        # Add facilitator tracking to request
        request.facilitator_start_time = time.time()
        
        # Check if user is a facilitator
        if hasattr(request, 'user') and request.user.is_authenticated:
            if hasattr(request.user, 'facilitator_profile'):
                request.is_facilitator = True
                request.facilitator_profile = request.user.facilitator_profile
            else:
                request.is_facilitator = False
        else:
            request.is_facilitator = False
        
        return None
    
    def process_response(self, request, response):
        # Track API response times for facilitators
        if hasattr(request, 'facilitator_start_time'):
            duration = time.time() - request.facilitator_start_time
            
            # Log slow responses (optional)
            if duration > 2.0:  # More than 2 seconds
                import logging
                logger = logging.getLogger('apps.facilitators')
                logger.warning(
                    f"Slow facilitator API response: {request.path} took {duration:.2f}s"
                )
        
        return response