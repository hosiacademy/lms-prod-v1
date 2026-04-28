# apps/payments/adapters/chipper_cash.py
import requests
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class ChipperCashAdapter(BasePaymentAdapter):
    """
    Chipper Cash - Pan-African coverage (NG, GH, KE, UG, ZA, RW).
    Documentation: https://chippercash.com/developers
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.api_key = self._get_api_key()
        self.base_url = "https://api.chippercash.com/v1"

    def _get_api_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'CHIPPER_API_KEY', '')

    def get_supported_countries(self) -> List[str]:
        return ['NG', 'GH', 'KE', 'UG', 'ZA', 'RW']

    def get_supported_currencies(self) -> List[str]:
        return ['NGN', 'GHS', 'KES', 'UGX', 'ZAR', 'RWF', 'USD']

    def get_supported_methods(self) -> List[str]:
        return ['wallet', 'chipper_cash']

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Chipper Cash initiation.
        """
        payload = {
            "amount": float(transaction.amount),
            "currency": transaction.currency,
            "reference": transaction.provider_reference,
            "description": transaction.description or "Payment",
            "callback_url": callback_url,
            "customer": {
                "email": transaction.user.email if transaction.user else kwargs.get('email', '')
            }
        }

        # Placeholder for actual API call
        return {
            'status': 'pending',
            'checkout_url': f"https://chippercash.com/pay/{transaction.provider_reference}",
            'provider_reference': transaction.provider_reference,
            'requires_redirect': True,
            'provider_data': payload
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        return {'status': 'pending', 'reference': reference}

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Chipper Cash refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('reference'),
            'status': payload.get('status'),
            'provider_data': payload
        }
