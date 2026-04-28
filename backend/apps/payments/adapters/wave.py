# apps/payments/adapters/wave.py
import requests
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class WaveAdapter(BasePaymentAdapter):
    """
    Wave - Francophone West Africa (Senegal, Cote d'Ivoire).
    Documentation: https://developer.wave.com/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.api_key = self._get_api_key()
        self.base_url = "https://api.wave.com/v1"

    def _get_api_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'WAVE_API_KEY', '')

    def get_supported_countries(self) -> List[str]:
        return ['SN', 'CI', 'ML', 'BF', 'UG'] # Senegal, Cote d'Ivoire, Mali, Burkina Faso, Uganda

    def get_supported_currencies(self) -> List[str]:
        return ['XOF', 'UGX']

    def get_supported_methods(self) -> List[str]:
        return ['mobile_money', 'wave']

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Wave Checkout initiation.
        """
        url = f"{self.base_url}/checkout/sessions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "amount": str(int(transaction.amount)),
            "currency": transaction.currency,
            "error_url": callback_url,
            "success_url": callback_url,
            "external_id": transaction.provider_reference,
            "client_reference": str(transaction.id)
        }

        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        data = response.json()

        return {
            'status': 'pending',
            'checkout_url': data.get('wave_launch_url'),
            'provider_reference': data.get('id'),
            'requires_redirect': True,
            'provider_data': data
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        url = f"{self.base_url}/checkout/sessions/{reference}"
        headers = {"Authorization": f"Bearer {self.api_key}"}
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        
        return {
            'status': 'successful' if data.get('payment_status') == 'succeeded' else 'pending',
            'reference': reference,
            'provider_data': data
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Wave refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('external_id'),
            'status': payload.get('type'),
            'provider_data': payload
        }
