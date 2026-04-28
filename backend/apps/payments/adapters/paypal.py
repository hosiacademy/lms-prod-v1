# apps/payments/adapters/paypal.py
import requests
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class PayPalAdapter(BasePaymentAdapter):
    """
    PayPal - International coverage.
    Documentation: https://developer.paypal.com/docs/api/overview/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.client_id = self._get_client_id()
        self.client_secret = self._get_client_secret()
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://api-m.sandbox.paypal.com" if self.is_sandbox else "https://api-m.paypal.com"

    def _get_client_id(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'PAYPAL_CLIENT_ID', '')

    def _get_client_secret(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'PAYPAL_CLIENT_SECRET', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'PAYPAL_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['US', 'GB', 'ZA', 'KE', 'NG', 'EG', 'MA'] # Over 200 countries

    def get_supported_currencies(self) -> List[str]:
        return ['USD', 'EUR', 'GBP', 'ZAR'] # Most major currencies

    def get_supported_methods(self) -> List[str]:
        return ['card', 'paypal']

    def _get_token(self) -> str:
        url = f"{self.base_url}/v1/oauth2/token"
        response = requests.post(
            url,
            data={"grant_type": "client_credentials"},
            auth=(self.client_id, self.client_secret)
        )
        response.raise_for_status()
        return response.json().get('access_token')

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        PayPal Orders V2 initiation.
        """
        token = self._get_token()
        url = f"{self.base_url}/v2/checkout/orders"
        
        payload = {
            "intent": "CAPTURE",
            "purchase_units": [{
                "reference_id": transaction.provider_reference,
                "amount": {
                    "currency_code": transaction.currency,
                    "value": f"{transaction.amount:.2f}"
                },
                "description": transaction.description or f"Payment {transaction.provider_reference}"
            }],
            "application_context": {
                "return_url": callback_url,
                "cancel_url": callback_url
            }
        }

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }

        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        data = response.json()

        # Find the checkout link
        checkout_url = next(link['href'] for link in data['links'] if link['rel'] == 'approve')

        return {
            'status': 'pending',
            'checkout_url': checkout_url,
            'provider_reference': data['id'],
            'requires_redirect': True,
            'provider_data': data
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        token = self._get_token()
        url = f"{self.base_url}/v2/checkout/orders/{reference}"
        headers = {"Authorization": f"Bearer {token}"}
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        
        return {
            'status': 'successful' if data.get('status') == 'COMPLETED' else 'pending',
            'reference': reference,
            'provider_data': data
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("PayPal refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True # PayPal webhook signature verification is complex (requires cert validation)

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('resource', {}).get('id'),
            'status': payload.get('event_type'),
            'provider_data': payload
        }
