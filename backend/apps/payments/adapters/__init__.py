# apps/payments/adapters/__init__.py
import logging
from .base import (
    BasePaymentAdapter,
    PaymentError,
    SignatureVerificationError,
    AdapterConfigurationError
)

logger = logging.getLogger(__name__)

# Helper to create a stub adapter that won't crash on abstract methods
def _make_stub(name):
    """Create a concrete stub adapter class that satisfies all abstract methods"""
    class StubAdapter(BasePaymentAdapter):
        def get_supported_countries(self): return []
        def get_supported_currencies(self): return []
        def get_supported_methods(self): return []
        def initiate_payment(self, *args, **kwargs): raise NotImplementedError(f"{name} adapter not available")
        def verify_payment(self, *args, **kwargs): raise NotImplementedError(f"{name} adapter not available")
        def refund_payment(self, *args, **kwargs): raise NotImplementedError(f"{name} adapter not available")
        def verify_webhook_signature(self, *args, **kwargs): return False
        def parse_webhook(self, *args, **kwargs): return {}
        def get_provider_name(self): return name
        def get_provider_code(self): return name.lower()
    StubAdapter.__name__ = f"{name}Adapter"
    StubAdapter.__qualname__ = f"{name}Adapter"
    return StubAdapter

def _safe_import(module_name, class_name):
    try:
        module = __import__(f"apps.payments.adapters.{module_name}", fromlist=[class_name])
        return getattr(module, class_name)
    except (ImportError, AttributeError, ModuleNotFoundError) as e:
        logger.warning(f"{class_name} import failed: {e}")
        return _make_stub(class_name.replace("Adapter", ""))

class PaymentProvider:
    MOCK = 'mock'
    # ALL OTHERS COMMENTED OUT AS REQUESTED
    # FLUTTERWAVE = 'flutterwave'
    # PAYSTACK = 'paystack'
    # MPESA = 'mpesa'
    # VODACOM_MPESA = 'vodacom_mpesa'
    # PAYNOW = 'paynow'
    # STRIPE = 'stripe'
    # PAYPAL = 'paypal'
    BANK_TRANSFER = 'bank_transfer'
    CASH = 'cash'

# ESSENTIAL - ONLY SMATPAY
SmatPayAdapter = _safe_import("smatpay", "SmatPayAdapter")

from .mock import MockAdapter

ADAPTER_REGISTRY = {
    # Testing
    PaymentProvider.MOCK: MockAdapter,
    
    # SMATPAY ONLY
    'smatpay': SmatPayAdapter,
    
    # DIRECT BANK TRANSFER (Manual EFT)
    'bank_transfer': MockAdapter,  # Placeholder for direct bank transfer (manual payment)
    'on_site_payment': MockAdapter,  # Placeholder for in-store cash payments
}

def get_adapter(provider_code: str, config=None):
    """
    Factory function to get adapter instance
    """
    provider_code = str(provider_code).lower().strip()
    adapter_class = ADAPTER_REGISTRY.get(provider_code)
    
    if not adapter_class:
        logger.warning(f"No adapter found for provider: {provider_code}")
        return None
    
    return adapter_class(config)

def get_supported_providers(country: str = None, method: str = None, currency: str = None) -> list:
    providers = []
    for provider_code, adapter_class in ADAPTER_REGISTRY.items():
        try:
            adapter = adapter_class()
            if country and country not in adapter.get_supported_countries(): continue
            if method and method not in adapter.get_supported_methods(): continue
            if currency and currency not in adapter.get_supported_currencies(): continue
            
            providers.append({
                'code': provider_code,
                'name': adapter.get_provider_name() if hasattr(adapter, 'get_provider_name') else provider_code.title(),
                'methods': adapter.get_supported_methods(),
                'currencies': adapter.get_supported_currencies(),
            })
        except Exception:
            continue
    return providers

__all__ = [
    'BasePaymentAdapter', 'PaymentError', 'SignatureVerificationError',
    'AdapterConfigurationError', 'get_adapter', 'get_supported_providers',
    'ADAPTER_REGISTRY', 'PaymentProvider',
    
    # ONLY SMATPAY IS EXPOSED
    'SmatPayAdapter',
    'MockAdapter',
]