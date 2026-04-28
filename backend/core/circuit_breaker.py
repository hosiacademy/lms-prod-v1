"""
Circuit breaker pattern implementation for external API calls.
Prevents cascading failures when external services are down.
"""
import time
import logging
from functools import wraps
from django.core.cache import cache

logger = logging.getLogger(__name__)


class CircuitBreakerOpen(Exception):
    """Raised when circuit breaker is open."""
    pass


class CircuitBreaker:
    """
    Circuit breaker implementation.

    States:
    - CLOSED: Normal operation, requests pass through
    - OPEN: Too many failures, reject requests immediately
    - HALF_OPEN: Testing if service recovered

    Usage:
        breaker = CircuitBreaker('payment_api', failure_threshold=5, timeout=60)

        @breaker
        def call_payment_api():
            return requests.post(...)
    """

    def __init__(self, name, failure_threshold=5, timeout=60, half_open_attempts=3):
        self.name = name
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.half_open_attempts = half_open_attempts

        # Cache keys
        self.state_key = f'circuit_breaker:{name}:state'
        self.failure_count_key = f'circuit_breaker:{name}:failures'
        self.last_failure_key = f'circuit_breaker:{name}:last_failure'
        self.half_open_attempts_key = f'circuit_breaker:{name}:half_open_attempts'

    def __call__(self, func):
        """Decorator to wrap function with circuit breaker."""
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Check circuit state
            state = self.get_state()

            if state == 'open':
                # Circuit is open, check if we should try half-open
                if self.should_attempt_reset():
                    self.set_state('half_open')
                else:
                    logger.warning(f'Circuit breaker {self.name} is OPEN, rejecting request')
                    raise CircuitBreakerOpen(f'Circuit breaker {self.name} is open')

            try:
                # Execute function
                result = func(*args, **kwargs)

                # Success - reset if half-open
                if state == 'half_open':
                    self.reset()
                    logger.info(f'Circuit breaker {self.name} closed after successful half-open attempt')

                return result

            except Exception as e:
                # Record failure
                self.record_failure()

                # Check if we should trip the breaker
                if state == 'half_open' or self.get_failure_count() >= self.failure_threshold:
                    self.trip()
                    logger.error(f'Circuit breaker {self.name} tripped after {self.get_failure_count()} failures')

                raise

        return wrapper

    def get_state(self):
        """Get current circuit state."""
        return cache.get(self.state_key, 'closed')

    def set_state(self, state):
        """Set circuit state."""
        cache.set(self.state_key, state, self.timeout * 10)

    def get_failure_count(self):
        """Get current failure count."""
        return cache.get(self.failure_count_key, 0)

    def record_failure(self):
        """Record a failure."""
        current = self.get_failure_count()
        cache.set(self.failure_count_key, current + 1, self.timeout)
        cache.set(self.last_failure_key, time.time(), self.timeout)

    def trip(self):
        """Trip the circuit breaker (open it)."""
        self.set_state('open')
        logger.error(f'Circuit breaker {self.name} is now OPEN')

    def reset(self):
        """Reset the circuit breaker."""
        self.set_state('closed')
        cache.delete(self.failure_count_key)
        cache.delete(self.last_failure_key)
        cache.delete(self.half_open_attempts_key)
        logger.info(f'Circuit breaker {self.name} reset to CLOSED')

    def should_attempt_reset(self):
        """Check if we should attempt to reset (move to half-open)."""
        last_failure = cache.get(self.last_failure_key)
        if last_failure is None:
            return True

        time_since_failure = time.time() - last_failure
        return time_since_failure >= self.timeout


# Global circuit breakers for external services
payment_provider_breaker = CircuitBreaker('payment_provider', failure_threshold=5, timeout=60)
aicerts_api_breaker = CircuitBreaker('aicerts_api', failure_threshold=3, timeout=30)
email_service_breaker = CircuitBreaker('email_service', failure_threshold=10, timeout=120)
sms_service_breaker = CircuitBreaker('sms_service', failure_threshold=10, timeout=120)
