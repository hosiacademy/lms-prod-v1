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


# Import real adapters with fallbacks
def _safe_import(module_name, class_name):
    try:
        module = __import__(f"apps.payments.adapters.{module_name}", fromlist=[class_name])
        return getattr(module, class_name)
    except (ImportError, AttributeError, ModuleNotFoundError) as e:
        logger.warning(f"{class_name} import failed: {e}")
        return _make_stub(class_name.replace("Adapter", ""))

# Define PaymentProvider constants
class PaymentProvider:
    MOCK = 'mock'
    FLUTTERWAVE = 'flutterwave'
    PAYSTACK = 'paystack'  # Optional: Keep for Nigeria/Ghana focus
    MPESA = 'mpesa'  # Essential: Kenya
    VODACOM_MPESA = 'vodacom_mpesa'  # Essential: TZ, MZ, CD, LS
    VODAFONE_CASH = 'vodafone_cash'  # TODO: Remove (covered by Fawry + Flutterwave)
    MTN_MOMO = 'mtn_momo'  # TODO: Remove (aggregated by Flutterwave)
    AIRTEL_MONEY = 'airtel_money'  # TODO: Remove (aggregated by Flutterwave)
    ORANGE_MONEY = 'orange_money'  # TODO: Remove (aggregated by Flutterwave)
    PAYNOW = 'paynow'  # Essential: Zimbabwe exclusive
    PESEPAY = 'pesepay'  # TODO: Remove (duplicates Paynow)
    PESAPAL = 'pesapal'  # TODO: Remove (duplicates Flutterwave)
    STRIPE = 'stripe'  # Essential: International
    PAYPAL = 'paypal'  # Optional: International/diaspora
    YOCO = 'yoco'  # TODO: Remove (duplicates Flutterwave)
    PAYFAST = 'payfast'  # TODO: Remove (duplicates Flutterwave)
    OZOW = 'ozow'  # TODO: Remove (duplicates Flutterwave)
    SNAPSCAN = 'snapscan'  # TODO: Remove (QR-only, niche)
    INTERSWITCH = 'interswitch'  # TODO: Remove (duplicates Flutterwave)
    REMITA = 'remita'  # TODO: Remove (duplicates Flutterwave)
    CELLULANT = 'cellulant'  # TODO: Remove (duplicates Flutterwave)
    MONNIFY = 'monnify'  # TODO: Remove (duplicates Flutterwave)
    PAYMOB = 'paymob'  # TODO: Remove (duplicates Fawry + Flutterwave)
    FAWRY = 'fawry'  # Essential: Egypt cash network
    WAVE = 'wave'  # TODO: Remove (limited coverage)
    CHIPPER_CASH = 'chippercash'  # TODO: Remove (duplicates Flutterwave)
    BANK_TRANSFER = 'bank_transfer'
    CASH = 'cash'

# Core Adapters
# ============================================================================
# ESSENTIAL (Keep These)
# ============================================================================
FlutterwaveAdapter = _safe_import("flutterwave", "FlutterwaveAdapter")  # ✅ Pan-African
PaystackAdapter = _safe_import("paystack", "PaystackAdapter")  # ⚠️ Optional: NG/GH
MpesaAdapter = _safe_import("mpesa", "MpesaAdapter")  # ✅ Kenya
VodacomMpesaAdapter = _safe_import("vodacom_mpesa", "VodacomMpesaAdapter")  # ✅ TZ, MZ, CD, LS
StripeAdapter = _safe_import("stripe_adapter", "StripeAdapter")  # ✅ International
FawryAdapter = _safe_import("fawry", "FawryAdapter")  # ✅ Egypt cash

# ============================================================================
# ESSENTIAL - Zimbabwe Exclusive - CARD PAYMENT PROVIDER
# ============================================================================
SmatPayAdapter = _safe_import("smatpay", "SmatPayAdapter")  # ✅ Card payment exclusive

# ============================================================================
# ESSENTIAL - Zimbabwe Exclusive
# ============================================================================
PaynowAdapter = _safe_import("paynow", "PaynowAdapter")  # ✅ Zimbabwe only

# ============================================================================
# OPTIONAL - Keep Based on Usage (Monitor for 3-6 months)
# ============================================================================
PayPalAdapter = _safe_import("paypal", "PayPalAdapter")  # ⚠️ International/diaspora
MTNMoMoAdapter = _safe_import("mtn_momo", "MTNMoMoAdapter")  # ⚠️ If MTN volume >10%
AirtelMoneyAdapter = _safe_import("airtel_money", "AirtelMoneyAdapter")  # ⚠️ If Airtel volume >10%
OrangeMoneyAdapter = _safe_import("orange_money", "OrangeMoneyAdapter")  # ⚠️ If Orange volume >10%

# ============================================================================
# TODO: REMOVE - Duplicates Flutterwave (Commented Out)
# ============================================================================
# PesepayAdapter = _safe_import("pesepay", "PesepayAdapter")  # ❌ Duplicates Paynow
# PesapalAdapter = _safe_import("pesapal", "PesapalAdapter")  # ❌ Duplicates Flutterwave
# YocoAdapter = _safe_import("yoco", "YocoAdapter")  # ❌ Duplicates Flutterwave
# PayFastAdapter = _safe_import("payfast", "PayFastAdapter")  # ❌ Duplicates Flutterwave
# OzowAdapter = _safe_import("ozow", "OzowAdapter")  # ❌ Duplicates Flutterwave
# SnapScanAdapter = _safe_import("snapscan", "SnapScanAdapter")  # ❌ QR-only, niche
# InterswitchAdapter = _safe_import("interswitch", "InterswitchAdapter")  # ❌ Duplicates Flutterwave
# RemitaAdapter = _safe_import("remita", "RemitaAdapter")  # ❌ Duplicates Flutterwave
# CellulantAdapter = _safe_import("cellulant", "CellulantAdapter")  # ❌ Duplicates Flutterwave
# MonnifyAdapter = _safe_import("monnify", "MonnifyAdapter")  # ❌ Duplicates Flutterwave
# PaymobAdapter = _safe_import("paymob", "PaymobAdapter")  # ❌ Duplicates Fawry + Flutterwave
# WaveAdapter = _safe_import("wave", "WaveAdapter")  # ❌ Limited coverage
# ChipperCashAdapter = _safe_import("chipper_cash", "ChipperCashAdapter")  # ❌ Duplicates Flutterwave
# VodafoneCashAdapter = _safe_import("vodafone_cash", "VodafoneCashAdapter")  # ❌ Covered by Fawry + Flutterwave

from .mock import MockAdapter  # ✅ Testing only

# Adapter registry - ALIGNED WITH SMATPAY-ONLY CARD POLICY
# ============================================================================
# CORE ADAPTERS FOR PRODUCTION (SmatPay + Regional Gateways)
# ============================================================================
# POLICY:
# - Card Payments: SmatPay ONLY (Visa, Mastercard, ZimSwitch)
# - EFT Payments: Direct Bank Transfers + Regional Gateways
# - Other Methods: Mobile Money, Cash, etc.
# ============================================================================

SmatPayAdapter = _safe_import("smatpay", "SmatPayAdapter")  # ✅ Card payment exclusive

ADAPTER_REGISTRY = {
    # Testing
    PaymentProvider.MOCK: MockAdapter,
    
    # ========================================================================
    # CARD PAYMENTS - SmatPay ONLY (EXCLUSIVE)
    # ========================================================================
    # All card payments (Visa, Mastercard, ZimSwitch) route through SmatPay
    # No other adapters handle card payments
    'smatpay': SmatPayAdapter,  # ✅ Card payment exclusive provider
    
    # ========================================================================
    # EFT / BANK TRANSFER PAYMENTS
    # ========================================================================
    PaymentProvider.PAYNOW: PaynowAdapter,  # Zimbabwe online banking
    PaymentProvider.PESEPAY: _safe_import("pesepay", "PesepayAdapter"),  # Zimbabwe mobile banking (if available)
    
    # ========================================================================
    # DIRECT BANK TRANSFER (Manual EFT)
    # ========================================================================
    'bank_transfer': MockAdapter,  # Placeholder for direct bank transfer (manual payment)
    'on_site_payment': MockAdapter,  # Placeholder for in-store cash payments
    
    # ========================================================================
    # LEGACY ADAPTERS - KEPT FOR BACKWARD COMPATIBILITY
    # ========================================================================
    # NOTE: These are no longer used for NEW enrollments
    # Card functionality removed - clients must use SmatPay
    # These adapters now only handle NON-CARD payments if needed
    
    PaymentProvider.FLUTTERWAVE: FlutterwaveAdapter,  # Legacy only - NO CARD
    PaymentProvider.PAYSTACK: PaystackAdapter,  # Legacy only - NO CARD
    PaymentProvider.MPESA: MpesaAdapter,  # Kenya mobile money only
    PaymentProvider.VODACOM_MPESA: VodacomMpesaAdapter,  # TZ, MZ, CD, LS mobile money
    PaymentProvider.FAWRY: FawryAdapter,  # Egypt cash network
    PaymentProvider.STRIPE: StripeAdapter,  # International legacy
    PaymentProvider.PAYPAL: PayPalAdapter,  # International legacy
    PaymentProvider.MTN_MOMO: MTNMoMoAdapter,  # Mobile money
    PaymentProvider.AIRTEL_MONEY: AirtelMoneyAdapter,  # Mobile money
    PaymentProvider.ORANGE_MONEY: OrangeMoneyAdapter,  # Mobile money
    
    # ========================================================================
    # REMOVED - Not in use (commented for reference)
    # ========================================================================
    # PaymentProvider.PESAPAL: PesapalAdapter,  # ❌ Legacy
    # PaymentProvider.YOCO: YocoAdapter,  # ❌ South Africa legacy
    # PaymentProvider.PAYFAST: PayFastAdapter,  # ❌ South Africa legacy
    # PaymentProvider.OZOW: OzowAdapter,  # ❌ South Africa legacy
    # PaymentProvider.SNAPSCAN: SnapScanAdapter,  # ❌ QR-only, niche
    # PaymentProvider.INTERSWITCH: InterswitchAdapter,  # ❌ Duplicates Flutterwave
    # PaymentProvider.REMITA: RemitaAdapter,  # ❌ Duplicates Flutterwave
    # PaymentProvider.CELLULANT: CellulantAdapter,  # ❌ Duplicates Flutterwave
    # PaymentProvider.MONNIFY: MonnifyAdapter,  # ❌ Duplicates Flutterwave
    # PaymentProvider.PAYMOB: PaymobAdapter,  # ❌ Duplicates Fawry + Flutterwave
    # PaymentProvider.WAVE: WaveAdapter,  # ❌ Limited coverage
    # PaymentProvider.CHIPPER_CASH: ChipperCashAdapter,  # ❌ Duplicates Flutterwave
    # PaymentProvider.VODAFONE_CASH: VodafoneCashAdapter,  # ❌ Covered by Fawry + Flutterwave
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
    # Base classes
    'BasePaymentAdapter', 'PaymentError', 'SignatureVerificationError',
    'AdapterConfigurationError', 'get_adapter', 'get_supported_providers',
    'ADAPTER_REGISTRY', 'PaymentProvider',
    
    # ✅ ESSENTIAL ADAPTERS (6)
    'FlutterwaveAdapter',  # Pan-African
    'MpesaAdapter',  # Kenya
    'VodacomMpesaAdapter',  # TZ, MZ, CD, LS
    'PaynowAdapter',  # Zimbabwe
    'FawryAdapter',  # Egypt
    'StripeAdapter',  # International
    
    # ⚠️ OPTIONAL ADAPTERS (4) - Monitor usage
    'PaystackAdapter',  # Nigeria/Ghana
    'PayPalAdapter',  # International
    'MTNMoMoAdapter',  # If MTN volume >10%
    'AirtelMoneyAdapter',  # If Airtel volume >10%
    'OrangeMoneyAdapter',  # If Orange volume >10%
    
    # Testing
    'MockAdapter',
    
    # ❌ REMOVED ADAPTERS (18) - Commented out, duplicates Flutterwave
    # 'PesepayAdapter', 'PesapalAdapter', 'YocoAdapter', 'PayFastAdapter',
    # 'OzowAdapter', 'SnapScanAdapter', 'InterswitchAdapter', 'RemitaAdapter',
    # 'CellulantAdapter', 'MonnifyAdapter', 'PaymobAdapter', 'WaveAdapter',
    # 'ChipperCashAdapter', 'VodafoneCashAdapter'
]