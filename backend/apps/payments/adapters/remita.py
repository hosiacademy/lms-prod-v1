# apps/payments/adapters/remita.py
import requests
import hashlib
import time
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class RemitaAdapter(BasePaymentAdapter):
    """
    Remita - Nigeria (Bank, EFT, Government payments).
    Documentation: https://remita.net/api-documentation/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.merchant_id = self._get_merchant_id()
        self.api_key = self._get_api_key()
        self.service_type_id = self._get_service_type_id()
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://remitademo.net/remita/exapp/api/v1/send/api" if self.is_sandbox else "https://io.remita.net/remita/exapp/api/v1/send/api"

    def _get_merchant_id(self) -> str:
        if self.config and hasattr(self.config, 'api_id'): return self.config.api_id
        return getattr(settings, 'REMITA_MERCHANT_ID', '')

    def _get_api_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'REMITA_API_KEY', '')

    def _get_service_type_id(self) -> str:
        return getattr(settings, 'REMITA_SERVICE_TYPE_ID', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'REMITA_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['NG']

    def get_supported_currencies(self) -> List[str]:
        return ['NGN']

    def get_supported_methods(self) -> List[str]:
        return ['bank_transfer', 'ussd', 'card', 'remita_pay']

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Remita RRR (Remita Retrieval Reference) generation.
        """
        # Hash: merchantId + serviceTypeId + orderId + amount + apiKey
        hash_string = f"{self.merchant_id}{self.service_type_id}{transaction.provider_reference}{transaction.amount}{self.api_key}"
        api_hash = hashlib.sha512(hash_string.encode()).hexdigest()

        payload = {
            "serviceTypeId": self.service_type_id,
            "amount": str(transaction.amount),
            "orderId": transaction.provider_reference,
            "payerName": transaction.user.get_full_name() if transaction.user else 'Guest',
            "payerEmail": transaction.user.email if transaction.user else kwargs.get('email', ''),
            "payerPhone": kwargs.get('phone_number', ''),
            "description": transaction.description or f"Payment {transaction.provider_reference}"
        }

        # Remita initiation to get RRR
        url = f"{self.base_url}/echannels/v3/merchant/rrr/generate"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"remitaConsumerKey={self.merchant_id},remitaConsumerToken={api_hash}"
        }

        # Note: Actual implementation would call requests.post
        # For listing purposes, we return the structure
        
        return {
            'status': 'pending',
            'checkout_url': f"https://remita.net/payment/processes/rrr/checkout.htm?rrr=PENDING_RRR",
            'provider_reference': 'PENDING_RRR',
            'requires_redirect': True,
            'provider_data': payload
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        # Hash: RRR + apiKey + merchantId
        hash_string = f"{reference}{self.api_key}{self.merchant_id}"
        api_hash = hashlib.sha512(hash_string.encode()).hexdigest()
        
        url = f"{self.base_url}/echannels/v3/merchant/rrr/{reference}/status"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"remitaConsumerKey={self.merchant_id},remitaConsumerToken={api_hash}"
        }
        
        return {
            'status': 'pending', # Placeholder
            'reference': reference,
            'provider_data': {}
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Remita refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('orderId'),
            'status': payload.get('message'),
            'provider_data': payload
        }
