# apps/payments/adapters/pesapal.py
import requests
import json
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class PesapalAdapter(BasePaymentAdapter):
    """
    Pesapal - East African aggregator (Kenya, Uganda, Tanzania).
    Documentation: https://developer.pesapal.com/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.consumer_key = self._get_consumer_key()
        self.consumer_secret = self._get_consumer_secret()
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://cybqa.pesapal.com/pesapalv3" if self.is_sandbox else "https://pay.pesapal.com/v3"

    def _get_consumer_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'PESAPAL_CONSUMER_KEY', '')

    def _get_consumer_secret(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'PESAPAL_CONSUMER_SECRET', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'PESAPAL_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['KE', 'UG', 'TZ', 'RW', 'MW']

    def get_supported_currencies(self) -> List[str]:
        return ['KES', 'UGX', 'TZS', 'RWF', 'MWK', 'USD']

    def get_supported_methods(self) -> List[str]:
        return ['card', 'mobile_money', 'mpesa', 'airtel_money', 'mtn_momo']

    def _get_token(self) -> str:
        """Get OAuth2 token from Pesapal"""
        url = f"{self.base_url}/api/Auth/RequestToken"
        payload = {
            "consumer_key": self.consumer_key,
            "consumer_secret": self.consumer_secret
        }
        response = requests.post(url, json=payload)
        response.raise_for_status()
        return response.json().get('token')

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Pesapal V3 initiation.
        """
        token = self._get_token()
        url = f"{self.base_url}/api/Transactions/SubmitOrderRequest"
        
        payload = {
            "id": transaction.provider_reference,
            "currency": transaction.currency,
            "amount": float(transaction.amount),
            "description": transaction.description or f"Payment {transaction.provider_reference}",
            "callback_url": callback_url,
            "notification_id": kwargs.get('notification_id', getattr(settings, 'PESAPAL_IPN_ID', '')),
            "billing_address": {
                "email_address": transaction.user.email if transaction.user else kwargs.get('email', ''),
                "phone_number": kwargs.get('phone_number', ''),
                "country_code": transaction.country,
                "first_name": transaction.user.first_name if transaction.user else 'Guest',
                "last_name": transaction.user.last_name if transaction.user else ''
            }
        }

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }

        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        data = response.json()

        return {
            'status': 'pending',
            'checkout_url': data.get('redirect_url'),
            'provider_reference': data.get('order_tracking_id'),
            'requires_redirect': True,
            'provider_data': data
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        token = self._get_token()
        url = f"{self.base_url}/api/Transactions/GetTransactionStatus?orderTrackingId={reference}"
        headers = {"Authorization": f"Bearer {token}"}
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        
        return {
            'status': self._map_status(data.get('payment_status_description', '')),
            'amount': data.get('amount'),
            'currency': data.get('currency'),
            'reference': reference,
            'provider_data': data
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Pesapal refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('OrderTrackingId'),
            'status': payload.get('Status'),
            'provider_data': payload
        }
