# apps/payments/adapters/paymob.py
import requests
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class PaymobAdapter(BasePaymentAdapter):
    """
    Paymob - Egypt and North Africa Coverage.
    Documentation: https://docs.paymob.com/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.api_key = self._get_api_key()
        self.integration_id = getattr(settings, 'PAYMOB_INTEGRATION_ID', '')
        self.iframe_id = getattr(settings, 'PAYMOB_IFRAME_ID', '')
        self.base_url = "https://accept.paymob.com/api"

    def _get_api_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'PAYMOB_API_KEY', '')

    def get_supported_countries(self) -> List[str]:
        return ['EG', 'JO', 'PK', 'KE'] # Egypt, Jordan, Pakistan, Kenya

    def get_supported_currencies(self) -> List[str]:
        return ['EGP', 'USD', 'KES']

    def get_supported_methods(self) -> List[str]:
        return ['card', 'wallet', 'kiosk', 'valu']

    def _get_token(self) -> str:
        url = f"{self.base_url}/auth/tokens"
        response = requests.post(url, json={"api_key": self.api_key})
        response.raise_for_status()
        return response.json().get('token')

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Paymob Three-Step Initiation:
        1. Auth Token
        2. Create Order
        3. Create Payment Key
        """
        token = self._get_token()
        
        # 2. Create Order
        order_url = f"{self.base_url}/ecommerce/orders"
        order_payload = {
            "auth_token": token,
            "delivery_needed": "false",
            "amount_cents": str(int(transaction.amount * 100)),
            "currency": transaction.currency,
            "merchant_order_id": transaction.provider_reference,
            "items": []
        }
        order_res = requests.post(order_url, json=order_payload)
        order_res.raise_for_status()
        order_id = order_res.json().get('id')

        # 3. Create Payment Key
        key_url = f"{self.base_url}/acceptance/payment_keys"
        key_payload = {
            "auth_token": token,
            "amount_cents": str(int(transaction.amount * 100)),
            "expiration": 3600,
            "order_id": order_id,
            "billing_data": {
                "apartment": "NA",
                "email": transaction.user.email if transaction.user else kwargs.get('email', 'NA'),
                "floor": "NA",
                "first_name": transaction.user.first_name if transaction.user else 'Guest',
                "street": "NA",
                "building": "NA",
                "phone_number": kwargs.get('phone_number', 'NA'),
                "shipping_method": "PKG",
                "postal_code": "NA",
                "city": "NA",
                "country": transaction.country,
                "last_name": transaction.user.last_name if transaction.user else 'NA',
                "state": "NA"
            },
            "currency": transaction.currency,
            "integration_id": self.integration_id,
            "lock_order_when_paid": "false"
        }
        key_res = requests.post(key_url, json=key_payload)
        key_res.raise_for_status()
        payment_key = key_res.json().get('token')

        checkout_url = f"https://accept.paymob.com/api/acceptance/iframes/{self.iframe_id}?payment_token={payment_key}"

        return {
            'status': 'pending',
            'checkout_url': checkout_url,
            'provider_reference': str(order_id),
            'requires_redirect': True,
            'provider_data': order_res.json()
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        return {
            'status': 'pending', 
            'reference': reference,
            'provider_data': {}
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Paymob refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('obj', {}).get('order', {}).get('merchant_order_id'),
            'status': 'successful' if payload.get('obj', {}).get('success') == True else 'failed',
            'provider_data': payload
        }
