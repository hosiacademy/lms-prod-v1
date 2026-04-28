# apps/payments/adapters/fawry.py
import hashlib
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class FawryAdapter(BasePaymentAdapter):
    """
    Fawry - Egypt Largest Payment Network (Kiosk/Cash/Card).
    Documentation: https://atfawry.com/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.merchant_code = self._get_merchant_code()
        self.security_key = self._get_security_key()
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://atfawry.fawry.com" # Changes for sandbox

    def _get_merchant_code(self) -> str:
        if self.config and hasattr(self.config, 'api_id'): return self.config.api_id
        return getattr(settings, 'FAWRY_MERCH_CODE', '')

    def _get_security_key(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'FAWRY_SEC_KEY', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'FAWRY_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['EG']

    def get_supported_currencies(self) -> List[str]:
        return ['EGP']

    def get_supported_methods(self) -> List[str]:
        return ['kiosk', 'card', 'fawry_pay']

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Fawry Pay-At-Store initiation.
        """
        merchant_code = self.merchant_code
        merchant_ref_num = transaction.provider_reference
        customer_profile_id = str(transaction.user.id) if transaction.user else 'guest'
        item_code = 'LMS_COURSE'
        quantity = 1
        price = f"{transaction.amount:.2f}"
        
        # Hash L1: merchantCode + merchantRefNum + customerProfileId + itemId + quantity + price + expiry (optional) + securityKey
        hash_string = f"{merchant_code}{merchant_ref_num}{customer_profile_id}{item_code}{quantity}{price}{self.security_key}"
        signature = hashlib.sha256(hash_string.encode()).hexdigest()

        payload = {
            "merchantCode": merchant_code,
            "merchantRefNum": merchant_ref_num,
            "customerProfileId": customer_profile_id,
            "customerMobile": kwargs.get('phone_number', ''),
            "customerEmail": transaction.user.email if transaction.user else kwargs.get('email', ''),
            "paymentExpiry": 48, # Hours
            "chargeItems": [
                {
                    "itemId": item_code,
                    "description": transaction.description or "Course Payment",
                    "price": price,
                    "quantity": quantity
                }
            ],
            "signature": signature
        }

        # Fawry typically returns a reference number for the user to take to a store
        
        return {
            'status': 'pending',
            'checkout_url': "https://www.atfawry.com/atfawry/faces/login", # Placeholder
            'provider_reference': merchant_ref_num,
            'requires_redirect': False,
            'requires_kiosk_payment': True,
            'instructions': "Take your reference number to any Fawry point of sale to complete payment.",
            'provider_data': payload
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        return {'status': 'pending', 'reference': reference}

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Fawry refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('merchantRefNum'),
            'status': payload.get('orderStatus'),
            'provider_data': payload
        }
