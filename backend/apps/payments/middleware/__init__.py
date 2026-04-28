"""
Payment Middleware Package
"""

from .currency_middleware import CurrencyDetectionMiddleware, CurrencyContextMiddleware

# CountryDetectionMiddleware is imported directly from apps.payments.middleware_module
# to avoid circular imports
def __getattr__(name):
    if name == 'CountryDetectionMiddleware':
        from apps.payments.middleware_module import CountryDetectionMiddleware
        return CountryDetectionMiddleware
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")

__all__ = [
    'CurrencyDetectionMiddleware',
    'CurrencyContextMiddleware',
    'CountryDetectionMiddleware',
]
