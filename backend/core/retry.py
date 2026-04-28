"""
Retry logic for resilient external API calls.
"""
import time
import logging
from functools import wraps
from typing import Tuple, Type

logger = logging.getLogger(__name__)


def retry_with_backoff(
    max_attempts=3,
    base_delay=1,
    max_delay=60,
    backoff_factor=2,
    exceptions=(Exception,)
):
    """
    Retry decorator with exponential backoff.

    Args:
        max_attempts: Maximum number of retry attempts
        base_delay: Initial delay between retries (seconds)
        max_delay: Maximum delay between retries (seconds)
        backoff_factor: Multiplier for exponential backoff
        exceptions: Tuple of exceptions to catch and retry

    Usage:
        @retry_with_backoff(max_attempts=3, base_delay=1)
        def call_external_api():
            return requests.post(...)
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            attempt = 0
            delay = base_delay

            while attempt < max_attempts:
                try:
                    return func(*args, **kwargs)

                except exceptions as e:
                    attempt += 1

                    if attempt >= max_attempts:
                        logger.error(
                            f'{func.__name__} failed after {max_attempts} attempts: {str(e)}'
                        )
                        raise

                    # Calculate backoff delay
                    delay = min(base_delay * (backoff_factor ** (attempt - 1)), max_delay)

                    logger.warning(
                        f'{func.__name__} failed (attempt {attempt}/{max_attempts}), '
                        f'retrying in {delay}s: {str(e)}'
                    )

                    time.sleep(delay)

            return None

        return wrapper
    return decorator


# Specific retry decorators for common use cases
def retry_payment_api(func):
    """Retry decorator for payment API calls."""
    return retry_with_backoff(
        max_attempts=3,
        base_delay=2,
        exceptions=(ConnectionError, TimeoutError)
    )(func)


def retry_database_operation(func):
    """Retry decorator for database operations."""
    from django.db import OperationalError

    return retry_with_backoff(
        max_attempts=5,
        base_delay=0.5,
        backoff_factor=1.5,
        exceptions=(OperationalError,)
    )(func)


def retry_external_api(func):
    """Retry decorator for general external API calls."""
    from requests.exceptions import RequestException

    return retry_with_backoff(
        max_attempts=3,
        base_delay=1,
        exceptions=(RequestException, ConnectionError, TimeoutError)
    )(func)
