"""
Caching utilities for LMS platform.
Provides helper functions for Redis caching.
"""
from django.core.cache import cache
from django.conf import settings
from functools import wraps
import hashlib
import json


def make_cache_key(*args, **kwargs):
    """
    Generate a cache key from arguments.
    """
    key_parts = [str(arg) for arg in args]
    key_parts.extend(f"{k}:{v}" for k, v in sorted(kwargs.items()))
    key_string = ":".join(key_parts)
    return hashlib.md5(key_string.encode()).hexdigest()


def cache_result(timeout=None, key_prefix=''):
    """
    Decorator to cache function results.

    Usage:
        @cache_result(timeout=300, key_prefix='user')
        def get_user_data(user_id):
            return expensive_operation(user_id)
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key
            cache_key = f"{key_prefix}:{func.__name__}:{make_cache_key(*args, **kwargs)}"

            # Try to get from cache
            result = cache.get(cache_key)
            if result is not None:
                return result

            # Call function and cache result
            result = func(*args, **kwargs)
            cache_timeout = timeout or settings.CACHE_TTL
            cache.set(cache_key, result, cache_timeout)

            return result
        return wrapper
    return decorator


def invalidate_cache_pattern(pattern):
    """
    Invalidate all cache keys matching a pattern.

    Usage:
        invalidate_cache_pattern('user:*')
    """
    from django_redis import get_redis_connection
    conn = get_redis_connection("default")

    keys = conn.keys(f"{settings.CACHES['default']['KEY_PREFIX']}:{pattern}")
    if keys:
        conn.delete(*keys)
        return len(keys)
    return 0


def cache_course_list():
    """Cache key for course list."""
    return 'courses:list'


def cache_course_detail(course_id):
    """Cache key for course detail."""
    return f'courses:detail:{course_id}'


def cache_user_enrollments(user_id):
    """Cache key for user enrollments."""
    return f'users:{user_id}:enrollments'


def clear_user_cache(user_id):
    """Clear all cache for a specific user."""
    return invalidate_cache_pattern(f'users:{user_id}:*')


def clear_course_cache(course_id):
    """Clear all cache for a specific course."""
    return invalidate_cache_pattern(f'courses:{course_id}:*')
