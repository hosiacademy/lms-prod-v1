# apps/payments/adapters/ozow.py
import hashlib
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class OzowAdapter(BasePaymentAdapter):
    """
    Ozow (formerly i-Pay) - South African Instant EFT.
    Documentation: https://ozow.com/developers/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.site_code = self._get_site_code()
        self.private_key = self._get_private_key()
        self.api_key = self._get_api_key()
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://pay.ozow.com"

    def _get_site_code(self) -> str:
        if self.config and hasattr(self.config, 'api_id'): return self.config.api_id
        return getattr(settings, 'OZOW_SITE_CODE', '')

    def _get_private_key(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'OZOW_PRIVATE_KEY', '')

    def _get_api_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'OZOW_API_KEY', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'OZOW_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['ZA', 'NA', 'BW'] # Mostly ZA, some regional

    def get_supported_currencies(self) -> List[str]:
        return ['ZAR']

    def get_supported_methods(self) -> List[str]:
        return ['eft', 'instant_eft']

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Ozow payment initiation.
        """
        payload = {
            'SiteCode': self.site_code,
            'CountryCode': transaction.country,
            'CurrencyCode': transaction.currency,
            'Amount': f"{transaction.amount:.2f}",
            'TransactionReference': transaction.provider_reference,
            'BankReference': transaction.provider_reference[:20],
            'CancelUrl': kwargs.get('cancel_url', callback_url),
            'ErrorUrl': kwargs.get('error_url', callback_url),
            'SuccessUrl': kwargs.get('success_url', callback_url),
            'NotifyUrl': callback_url,
            'IsTest': self.is_sandbox,
        }

        # Ozow requires SHA512 hash of concatenated values
        hash_string = (
            f"{payload['SiteCode']}{payload['CountryCode']}{payload['CurrencyCode']}"
            f"{payload['Amount']}{payload['TransactionReference']}{payload['BankReference']}"
            f"{payload['CancelUrl']}{payload['ErrorUrl']}{payload['SuccessUrl']}"
            f"{payload['NotifyUrl']}{payload['IsTest']}{self.private_key}"
        ).lower()
        
        hash_check = hashlib.sha512(hash_string.encode()).hexdigest()
        payload['HashCheck'] = hash_check

        # For Ozow, we typically redirect the user to their payment page
        from urllib.parse import urlencode
        checkout_url = f"{self.base_url}?{urlencode(payload)}"

        return {
            'status': 'pending',
            'checkout_url': checkout_url,
            'provider_reference': transaction.provider_reference,
            'requires_redirect': True,
            'provider_data': payload
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        raise NotImplementedError("Ozow status check not implemented")

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Ozow refund not supported via standard API")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        status = payload.get('Status')
        return {
            'event': 'payment.success' if status == 'Complete' else 'payment.failed',
            'reference': payload.get('TransactionReference'),
            'status': status,
            'amount': payload.get('Amount'),
            'currency': 'ZAR',
            'provider_data': payload
        }
