# apps/payments/adapters/mtn_momo.py
import requests
import uuid
import base64
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class MTNMoMoAdapter(BasePaymentAdapter):
    """
    MTN Mobile Money - Standard API (Ericsson Converged Wallet).
    Covers GH, UG, RW, ZM, CM, CI, etc.
    Documentation: https://momodeveloper.mtn.com/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.api_user = self._get_api_user()
        self.api_key = self._get_api_key()
        self.subscription_key = getattr(settings, 'MTN_MOMO_SUB_KEY', '')
        self.target_environment = 'sandbox' if self._is_sandbox() else 'mtn_production'
        self.base_url = "https://sandbox.momodeveloper.mtn.com" if self._is_sandbox() else "https://proxy.momoapi.mtn.com"

    def _get_api_user(self) -> str:
        if self.config and hasattr(self.config, 'api_id'): return self.config.api_id
        return getattr(settings, 'MTN_MOMO_API_USER', '')

    def _get_api_key(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'MTN_MOMO_API_KEY', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'MTN_MOMO_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['GH', 'UG', 'RW', 'ZM', 'CM', 'CI', 'BJ', 'GN', 'LR', 'SZ']

    def get_supported_currencies(self) -> List[str]:
        return ['GHS', 'UGX', 'RWF', 'ZMW', 'XAF', 'XOF', 'EUR']

    def get_supported_methods(self) -> List[str]:
        return ['mobile_money', 'mtn_momo']

    def _get_token(self) -> str:
        url = f"{self.base_url}/collection/token/"
        auth_string = f"{self.api_user}:{self.api_key}"
        encoded_auth = base64.b64encode(auth_string.encode()).decode()
        
        headers = {
            "Authorization": f"Basic {encoded_auth}",
            "Ocp-Apim-Subscription-Key": self.subscription_key
        }
        response = requests.post(url, headers=headers)
        response.raise_for_status()
        return response.json().get('access_token')

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        MTN MoMo RequestToPay.
        """
        token = self._get_token()
        url = f"{self.base_url}/collection/v1_0/requesttopay"
        
        external_id = transaction.provider_reference
        request_id = str(uuid.uuid4())
        
        payload = {
            "amount": str(int(transaction.amount)),
            "currency": transaction.currency,
            "externalId": external_id,
            "payer": {
                "partyIdType": "MSISDN",
                "partyId": kwargs.get('phone_number', '')
            },
            "payerMessage": transaction.description or "LMS Payment",
            "payeeNote": "LMS Payment"
        }

        headers = {
            "Authorization": f"Bearer {token}",
            "X-Target-Environment": self.target_environment,
            "X-Reference-Id": request_id,
            "Ocp-Apim-Subscription-Key": self.subscription_key,
            "Content-Type": "application/json"
        }

        # MTN returns 202 Accepted. We then poll using the request_id
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()

        return {
            'status': 'pending',
            'provider_reference': request_id,
            'requires_redirect': False,
            'requires_mobile_approval': True,
            'instructions': "Please check your phone for the MTN MoMo payment prompt",
            'provider_data': {"request_id": request_id, "external_id": external_id}
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        token = self._get_token()
        url = f"{self.base_url}/collection/v1_0/requesttopay/{reference}"
        headers = {
            "Authorization": f"Bearer {token}",
            "X-Target-Environment": self.target_environment,
            "Ocp-Apim-Subscription-Key": self.subscription_key
        }
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        
        return {
            'status': 'successful' if data.get('status') == 'SUCCESSFUL' else 'pending',
            'reference': reference,
            'amount': data.get('amount'),
            'provider_data': data
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("MTN MoMo refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('externalId'),
            'status': payload.get('status'),
            'provider_data': payload
        }