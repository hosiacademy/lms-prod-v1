# apps/payments/adapters/payfast.py
import requests
import hashlib
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class PayFastAdapter(BasePaymentAdapter):
    """
    PayFast South Africa - Supports Card, EFT (Instant EFT), and more.
    Documentation: https://developers.payfast.co.za/docs/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.merchant_id = self._get_merchant_id()
        self.merchant_key = self._get_merchant_key()
        self.passphrase = self._get_passphrase()
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://sandbox.payfast.co.za" if self.is_sandbox else "https://www.payfast.co.za"

    def _get_merchant_id(self) -> str:
        if self.config and hasattr(self.config, 'api_id'): return self.config.api_id
        return getattr(settings, 'PAYFAST_MERCHANT_ID', '')

    def _get_merchant_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'PAYFAST_MERCHANT_KEY', '')

    def _get_passphrase(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'PAYFAST_PASSPHRASE', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'PAYFAST_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['ZA']

    def get_supported_currencies(self) -> List[str]:
        return ['ZAR']

    def get_supported_methods(self) -> List[str]:
        return ['card', 'eft', 'zapper', 'momo']  # QR code removed

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        PayFast uses a form post for initiation.
        For server-side, we generate the signature and return the URL.
        """
        data = {
            'merchant_id': self.merchant_id,
            'merchant_key': self.merchant_key,
            'return_url': kwargs.get('return_url', callback_url),
            'cancel_url': kwargs.get('cancel_url', callback_url),
            'notify_url': callback_url,
            'name_first': transaction.user.first_name if transaction.user else 'Guest',
            'name_last': transaction.user.last_name if transaction.user else '',
            'email_address': transaction.user.email if transaction.user else kwargs.get('email', ''),
            'm_payment_id': str(transaction.id),
            'amount': f"{transaction.amount:.2f}",
            'item_name': transaction.description or f"Payment {transaction.provider_reference}",
        }

        # Generate signature
        signature = self._generate_signature(data)
        data['signature'] = signature

        # Build URL for redirect
        from urllib.parse import urlencode
        checkout_url = f"{self.base_url}/eng/process?{urlencode(data)}"

        return {
            'status': 'pending',
            'checkout_url': checkout_url,
            'provider_reference': str(transaction.id),
            'requires_redirect': True,
            'provider_data': data
        }

    def _generate_signature(self, data: Dict[str, str]) -> str:
        """PayFast signature generation"""
        payload = ""
        for key, value in data.items():
            if value:
                payload += f"{key}={requests.utils.quote(str(value))}&"
        
        payload = payload[:-1] # Remove last &
        if self.passphrase:
            payload += f"&passphrase={requests.utils.quote(self.passphrase)}"
            
        return hashlib.md5(payload.encode()).hexdigest()

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        # Implementation for ITN (Instant Transaction Notification) verification
        raise NotImplementedError("PayFast ITN verification should be handled via webhook")

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("PayFast refund not implemented via API in this version")

    def verify_webhook_signature(self, payload, headers):
        # PayFast sends data as POST. Verification involves checking the signature and IP.
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.success' if payload.get('payment_status') == 'COMPLETE' else 'payment.failed',
            'reference': payload.get('m_payment_id'),
            'status': payload.get('payment_status'),
            'amount': payload.get('amount_gross'),
            'currency': 'ZAR',
            'provider_data': payload
        }
