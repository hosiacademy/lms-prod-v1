# apps/payments/adapters/monnify.py
import requests
import base64
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class MonnifyAdapter(BasePaymentAdapter):
    """
    Monnify - Nigeria (Bank Transfers, Card, Virtual Accounts).
    Documentation: https://teamapt.atlassian.net/wiki/spaces/MON/pages/212008917/Monnify+API+Documentation
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.api_key = self._get_api_key()
        self.secret_key = self._get_secret_key()
        self.contract_code = getattr(settings, 'MONNIFY_CONTRACT_CODE', '')
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://sandbox.monnify.com/api/v1" if self.is_sandbox else "https://api.monnify.com/api/v1"

    def _get_api_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'MONNIFY_API_KEY', '')

    def _get_secret_key(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'MONNIFY_SECRET_KEY', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'MONNIFY_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['NG']

    def get_supported_currencies(self) -> List[str]:
        return ['NGN']

    def get_supported_methods(self) -> List[str]:
        return ['bank_transfer', 'card', 'ussd']

    def _get_token(self) -> str:
        url = f"{self.base_url}/auth/login"
        auth_string = f"{self.api_key}:{self.secret_key}"
        encoded_auth = base64.b64encode(auth_string.encode()).decode()
        
        headers = {
            "Authorization": f"Basic {encoded_auth}"
        }
        response = requests.post(url, headers=headers)
        response.raise_for_status()
        return response.json().get('responseBody', {}).get('accessToken')

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Monnify Transaction initiation.
        """
        token = self._get_token()
        url = f"{self.base_url}/merchant/transactions/init-transaction"
        
        payload = {
            "amount": float(transaction.amount),
            "customerName": transaction.user.get_full_name() if transaction.user else 'Guest',
            "customerEmail": transaction.user.email if transaction.user else kwargs.get('email', ''),
            "paymentReference": transaction.provider_reference,
            "paymentDescription": transaction.description or "LMS Course Payment",
            "currencyCode": transaction.currency,
            "contractCode": self.contract_code,
            "redirectUrl": callback_url,
            "paymentMethods": ["CARD", "ACCOUNT_TRANSFER"]
        }

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }

        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        data = response.json().get('responseBody', {})

        return {
            'status': 'pending',
            'checkout_url': data.get('checkoutUrl'),
            'provider_reference': data.get('transactionReference'),
            'requires_redirect': True,
            'provider_data': data
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        token = self._get_token()
        url = f"{self.base_url}/merchant/transactions/query?paymentReference={reference}"
        headers = {"Authorization": f"Bearer {token}"}
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json().get('responseBody', {})
        
        return {
            'status': 'successful' if data.get('paymentStatus') == 'PAID' else 'pending',
            'reference': reference,
            'amount': data.get('amountPaid'),
            'provider_data': data
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Monnify refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.success',
            'reference': payload.get('paymentReference'),
            'status': payload.get('paymentStatus'),
            'provider_data': payload
        }
