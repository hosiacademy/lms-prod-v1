"""
Advanced logging configuration for production monitoring.
Supports JSON logging for better log aggregation and parsing.
"""
import logging
import json
from datetime import datetime
from django.conf import settings


class JSONFormatter(logging.Formatter):
    """
    Custom JSON formatter for structured logging.
    Outputs logs in JSON format for easy parsing by log aggregation tools.
    """

    def format(self, record):
        log_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno,
        }

        # Add exception info if present
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)

        # Add extra fields
        if hasattr(record, 'user_id'):
            log_data['user_id'] = record.user_id
        if hasattr(record, 'request_id'):
            log_data['request_id'] = record.request_id
        if hasattr(record, 'ip_address'):
            log_data['ip_address'] = record.ip_address
        if hasattr(record, 'user_agent'):
            log_data['user_agent'] = record.user_agent
        if hasattr(record, 'endpoint'):
            log_data['endpoint'] = record.endpoint
        if hasattr(record, 'method'):
            log_data['method'] = record.method
        if hasattr(record, 'status_code'):
            log_data['status_code'] = record.status_code
        if hasattr(record, 'response_time'):
            log_data['response_time_ms'] = record.response_time

        # Add environment info
        log_data['environment'] = getattr(settings, 'ENVIRONMENT', 'unknown')
        log_data['debug'] = getattr(settings, 'DEBUG', False)

        return json.dumps(log_data)


class RequestLoggingMiddleware:
    """
    Middleware to log all requests with response time and status.
    """

    def __init__(self, get_response):
        self.get_response = get_response
        self.logger = logging.getLogger('lms.requests')

    def __call__(self, request):
        import time

        # Skip health check endpoints from detailed logging
        if request.path.startswith('/health/') or request.path.startswith('/api/health/'):
            return self.get_response(request)

        start_time = time.time()

        # Process request
        response = self.get_response(request)

        # Calculate response time
        response_time = (time.time() - start_time) * 1000  # Convert to ms

        # Get user info
        user_id = None
        if hasattr(request, 'user') and request.user.is_authenticated:
            user_id = request.user.id

        # Log request
        self.logger.info(
            f"{request.method} {request.path} - {response.status_code}",
            extra={
                'user_id': user_id,
                'ip_address': self.get_client_ip(request),
                'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                'endpoint': request.path,
                'method': request.method,
                'status_code': response.status_code,
                'response_time': round(response_time, 2),
            }
        )

        # Log slow requests
        if response_time > 1000:  # More than 1 second
            self.logger.warning(
                f"Slow request detected: {request.method} {request.path} took {response_time:.2f}ms",
                extra={
                    'user_id': user_id,
                    'endpoint': request.path,
                    'method': request.method,
                    'response_time': round(response_time, 2),
                }
            )

        return response

    @staticmethod
    def get_client_ip(request):
        """Get the client's IP address from the request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


def get_logging_config(debug=False):
    """
    Generate logging configuration based on environment.
    """
    log_level = 'DEBUG' if debug else 'INFO'
    formatter = 'verbose' if debug else 'json'

    return {
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'verbose': {
                'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
                'style': '{',
            },
            'simple': {
                'format': '{levelname} {message}',
                'style': '{',
            },
            'json': {
                '()': JSONFormatter,
            },
        },
        'filters': {
            'require_debug_false': {
                '()': 'django.utils.log.RequireDebugFalse',
            },
            'require_debug_true': {
                '()': 'django.utils.log.RequireDebugTrue',
            },
        },
        'handlers': {
            'console': {
                'level': 'DEBUG',
                'class': 'logging.StreamHandler',
                'formatter': formatter,
            },
            'file_info': {
                'level': 'INFO',
                'class': 'logging.handlers.RotatingFileHandler',
                'filename': settings.BASE_DIR / 'logs' / 'info.log',
                'maxBytes': 1024 * 1024 * 10,  # 10MB
                'backupCount': 10,
                'formatter': formatter,
            },
            'file_error': {
                'level': 'ERROR',
                'class': 'logging.handlers.RotatingFileHandler',
                'filename': settings.BASE_DIR / 'logs' / 'error.log',
                'maxBytes': 1024 * 1024 * 10,  # 10MB
                'backupCount': 10,
                'formatter': formatter,
            },
            'file_security': {
                'level': 'WARNING',
                'class': 'logging.handlers.RotatingFileHandler',
                'filename': settings.BASE_DIR / 'logs' / 'security.log',
                'maxBytes': 1024 * 1024 * 10,  # 10MB
                'backupCount': 10,
                'formatter': formatter,
            },
            'mail_admins': {
                'level': 'ERROR',
                'class': 'django.utils.log.AdminEmailHandler',
                'filters': ['require_debug_false'],
                'formatter': 'verbose',
            },
        },
        'loggers': {
            'django': {
                'handlers': ['console', 'file_info'],
                'level': log_level,
                'propagate': False,
            },
            'django.request': {
                'handlers': ['console', 'file_error', 'mail_admins'],
                'level': 'ERROR',
                'propagate': False,
            },
            'django.security': {
                'handlers': ['console', 'file_security'],
                'level': 'WARNING',
                'propagate': False,
            },
            'lms.requests': {
                'handlers': ['console', 'file_info'],
                'level': 'INFO',
                'propagate': False,
            },
            'apps.payments': {
                'handlers': ['console', 'file_info', 'file_error'],
                'level': 'DEBUG' if debug else 'INFO',
                'propagate': False,
            },
            'apps.facilitators': {
                'handlers': ['console', 'file_info'],
                'level': 'DEBUG' if debug else 'INFO',
                'propagate': False,
            },
            'celery': {
                'handlers': ['console', 'file_info'],
                'level': 'INFO',
                'propagate': False,
            },
        },
        'root': {
            'handlers': ['console', 'file_info'],
            'level': log_level,
        },
    }
