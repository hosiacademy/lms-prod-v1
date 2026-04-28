# apps/payments/adapters/cellulant.py
import requests
import json
import hashlib
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class CellulantAdapter(BasePaymentAdapter):
    """
    Cellulant (Tingg) - Pan-African aggregator.
    Documentation: https://developer.tingg.africa/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.api_key = self._get_api_key()
        self.secret_key = self._get_secret_key()
        self.service_code = self._get_service_code()
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://sandbox.tingg.africa" if self.is_sandbox else "https://api.tingg.africa"

    def _get_api_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'CELLULANT_API_KEY', '')

    def _get_secret_key(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'CELLULANT_SECRET_KEY', '')

    def _get_service_code(self) -> str:
        return getattr(settings, 'CELLULANT_SERVICE_CODE', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'CELLULANT_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['KE', 'NG', 'GH', 'UG', 'TZ', 'ZM', 'ZW', 'CI', 'SN', 'CM', 'BW']

    def get_supported_currencies(self) -> List[str]:
        return ['KES', 'NGN', 'GHS', 'UGX', 'TZS', 'ZMW', 'USD']

    def get_supported_methods(self) -> List[str]:
        return ['card', 'mobile_money', 'bank_transfer', 'ussd']  # QR code removed

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Cellulant (Tingg) Express Checkout initiation.
        """
        payload = {
            "merchant_transaction_id": transaction.provider_reference,
            "customer_first_name": transaction.user.first_name if transaction.user else 'Guest',
            "customer_last_name": transaction.user.last_name if transaction.user else '',
            "msisdn": kwargs.get('phone_number', ''),
            "customer_email": transaction.user.email if transaction.user else kwargs.get('email', ''),
            "request_amount": float(transaction.amount),
            "currency_code": transaction.currency,
            "account_number": str(transaction.id),
            "service_code": self.service_code,
            "due_date": "",
            "request_description": transaction.description or f"Payment {transaction.provider_reference}",
            "country_code": transaction.country,
            "language_code": "en",
            "success_redirect_url": callback_url,
            "fail_redirect_url": callback_url,
            "pending_redirect_url": callback_url,
            "callback_url": callback_url
        }

        # Tingg requires encryption of the payload
        # For listing, we provide the structure
        
        return {
            'status': 'pending',
            'checkout_url': f"{self.base_url}/checkout/v2/express/",
            'provider_reference': transaction.provider_reference,
            'requires_redirect': True,
            'provider_data': payload
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        return {
            'status': 'pending', # Placeholder
            'reference': reference,
            'provider_data': {}
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Cellulant refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('merchant_transaction_id'),
            'status': payload.get('status_description'),
            'provider_data': payload
        }
