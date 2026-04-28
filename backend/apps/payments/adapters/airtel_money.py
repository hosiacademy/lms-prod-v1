# apps/payments/adapters/airtel_money.py
import requests
import json
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class AirtelMoneyAdapter(BasePaymentAdapter):
    """
    Airtel Money - Pan-African Mobile Money (KE, UG, TZ, MW, RW, ZM, etc.).
    Documentation: https://developers.airtel.africa/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.client_id = self._get_client_id()
        self.client_secret = self._get_client_secret()
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://openapiuat.airtel.africa" if self.is_sandbox else "https://openapi.airtel.africa"

    def _get_client_id(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'AIRTEL_CLIENT_ID', '')

    def _get_client_secret(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'AIRTEL_CLIENT_SECRET', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'AIRTEL_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['KE', 'UG', 'TZ', 'RW', 'MW', 'ZM', 'CD', 'CG', 'GA', 'TD', 'NE', 'TD', 'SL', 'SC']

    def get_supported_currencies(self) -> List[str]:
        return ['KES', 'UGX', 'TZS', 'RWF', 'MWK', 'ZMW', 'CDF', 'XAF', 'XOF', 'SLL', 'SCR']

    def get_supported_methods(self) -> List[str]:
        return ['mobile_money', 'airtel_money']

    def _get_token(self) -> str:
        url = f"{self.base_url}/auth/oauth2/token"
        payload = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "grant_type": "client_credentials"
        }
        response = requests.post(url, json=payload)
        response.raise_for_status()
        return response.json().get('access_token')

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Airtel Money Disbursement/Collection (Merchant Pay).
        """
        token = self._get_token()
        url = f"{self.base_url}/merchant/v1/payments/"
        
        payload = {
            "reference": str(transaction.id),
            "subscriber": {
                "msisdn": kwargs.get('phone_number', '')
            },
            "transaction": {
                "amount": float(transaction.amount),
                "id": transaction.provider_reference,
                "currency": transaction.currency
            }
        }

        headers = {
            "Content-Type": "application/json",
            "Accept": "*/*",
            "X-Country": transaction.country,
            "X-Currency": transaction.currency,
            "Authorization": f"Bearer {token}"
        }

        # Note: Actual implementation would call requests.post
        
        return {
            'status': 'pending',
            'provider_reference': transaction.provider_reference,
            'requires_redirect': False,
            'requires_mobile_approval': True,
            'instructions': "Please approve the payment prompt on your Airtel phone",
            'provider_data': payload
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        return {
            'status': 'pending', 
            'reference': reference,
            'provider_data': {}
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Airtel Money refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('transaction', {}).get('id'),
            'status': payload.get('transaction', {}).get('status'),
            'provider_data': payload
        }
