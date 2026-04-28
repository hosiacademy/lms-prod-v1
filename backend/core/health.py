"""
Health check views for monitoring system status.
"""
import logging
from datetime import datetime
from django.conf import settings
from django.db import connection
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status

logger = logging.getLogger(__name__)


@csrf_exempt
@require_http_methods(["GET", "HEAD"])
def health_check_simple(request):
    """
    Simple health check endpoint for load balancers.
    Returns 200 OK if service is running.
    No authentication required.
    """
    return JsonResponse({
        'status': 'ok',
        'timestamp': datetime.utcnow().isoformat()
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check_detailed(request):
    """
    Detailed health check with component status.
    Checks database, cache, and other critical services.
    """
    health_status = {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'environment': settings.ENVIRONMENT,
        'debug': settings.DEBUG,
        'components': {}
    }

    all_healthy = True

    # Check database connection
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        health_status['components']['database'] = {
            'status': 'healthy',
            'type': settings.DATABASES['default']['ENGINE'].split('.')[-1]
        }
    except Exception as e:
        all_healthy = False
        health_status['components']['database'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        logger.error(f"Database health check failed: {e}")

    # Check Redis (if configured)
    try:
        import redis
        from django.conf import settings

        if hasattr(settings, 'CELERY_BROKER_URL'):
            redis_url = settings.CELERY_BROKER_URL
            if redis_url.startswith('redis://'):
                r = redis.from_url(redis_url)
                r.ping()
                health_status['components']['redis'] = {
                    'status': 'healthy',
                    'message': 'Connected'
                }
            else:
                health_status['components']['redis'] = {
                    'status': 'skipped',
                    'message': 'Not using Redis'
                }
    except ImportError:
        health_status['components']['redis'] = {
            'status': 'skipped',
            'message': 'Redis not installed'
        }
    except Exception as e:
        all_healthy = False
        health_status['components']['redis'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        logger.error(f"Redis health check failed: {e}")

    # Check Celery (if configured)
    try:
        from celery import current_app
        inspect = current_app.control.inspect()
        stats = inspect.stats()

        if stats:
            health_status['components']['celery'] = {
                'status': 'healthy',
                'workers': len(stats),
                'message': f'{len(stats)} worker(s) active'
            }
        else:
            health_status['components']['celery'] = {
                'status': 'warning',
                'workers': 0,
                'message': 'No workers detected'
            }
    except ImportError:
        health_status['components']['celery'] = {
            'status': 'skipped',
            'message': 'Celery not installed'
        }
    except Exception as e:
        # Celery being down shouldn't fail health check
        health_status['components']['celery'] = {
            'status': 'warning',
            'error': str(e)
        }
        logger.warning(f"Celery health check failed: {e}")

    # Overall status
    if not all_healthy:
        health_status['status'] = 'unhealthy'
        return Response(health_status, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    return Response(health_status, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def readiness_check(request):
    """
    Readiness check for Kubernetes.
    Returns 200 if the service is ready to accept traffic.
    """
    try:
        # Check database is accessible
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()

        return Response({
            'ready': True,
            'timestamp': datetime.utcnow().isoformat()
        }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return Response({
            'ready': False,
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)


@api_view(['GET'])
@permission_classes([AllowAny])
def liveness_check(request):
    """
    Liveness check for Kubernetes.
    Returns 200 if the application is running (but may not be ready).
    """
    return Response({
        'alive': True,
        'timestamp': datetime.utcnow().isoformat()
    }, status=status.HTTP_200_OK)
