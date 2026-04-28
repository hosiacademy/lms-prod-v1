# apps/payments/adapters/orange_money.py
import requests
import base64
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class OrangeMoneyAdapter(BasePaymentAdapter):
    """
    Orange Money - Francophone Africa (CI, SN, ML, BF, GN, CM, etc.).
    Documentation: https://developer.orange.com/apis/om-webpay/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.client_id = getattr(settings, 'ORANGE_CLIENT_ID', '')
        self.client_secret = getattr(settings, 'ORANGE_CLIENT_SECRET', '')
        self.merchant_key = getattr(settings, 'ORANGE_MERCHANT_KEY', '')
        self.base_url = "https://api.orange.com"

    def get_supported_countries(self) -> List[str]:
        return ['CI', 'SN', 'ML', 'BF', 'GN', 'CM', 'BJ', 'LR', 'SL', 'MG', 'JO', 'BW']

    def get_supported_currencies(self) -> List[str]:
        return ['XOF', 'XAF', 'MGA', 'JOD', 'BWP']

    def get_supported_methods(self) -> List[str]:
        return ['mobile_money', 'orange_money']

    def _get_token(self) -> str:
        url = f"{self.base_url}/oauth/v3/token"
        auth_string = f"{self.client_id}:{self.client_secret}"
        encoded_auth = base64.b64encode(auth_string.encode()).decode()
        
        headers = {
            "Authorization": f"Basic {encoded_auth}",
            "Content-Type": "application/x-www-form-urlencoded"
        }
        response = requests.post(url, data={"grant_type": "client_credentials"}, headers=headers)
        response.raise_for_status()
        return response.json().get('access_token')

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Orange Money WebPay initiation.
        """
        token = self._get_token()
        url = f"{self.base_url}/orange-money-webpay/dev/v1/webpayment"
        
        payload = {
            "merchant_key": self.merchant_key,
            "currency": transaction.currency,
            "order_id": transaction.provider_reference,
            "amount": int(transaction.amount),
            "return_url": callback_url,
            "cancel_url": callback_url,
            "notif_url": callback_url,
            "lang": "fr",
            "reference": f"LMS_{transaction.id}"
        }

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }

        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        data = response.json()

        return {
            'status': 'pending',
            'checkout_url': data.get('payment_url'),
            'provider_reference': data.get('pay_token'),
            'requires_redirect': True,
            'provider_data': data
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        return {
            'status': 'pending', 
            'reference': reference,
            'provider_data': {}
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Orange Money refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.success' if payload.get('status') == 'SUCCESS' else 'payment.failed',
            'reference': payload.get('notif_token'),
            'status': payload.get('status'),
            'provider_data': payload
        }

    def get_provider_name(self) -> str:
        return "Orange Money"

    def get_provider_code(self) -> str:
        return "orange_money"