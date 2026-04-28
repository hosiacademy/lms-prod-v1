# apps/payments/adapters/interswitch.py
import requests
import hashlib
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class InterswitchAdapter(BasePaymentAdapter):
    """
    Interswitch - West African gateway (Nigeria).
    Documentation: https://developers.interswitchgroup.com/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.merchant_code = self._get_merchant_code()
        self.pay_item_id = self._get_pay_item_id()
        self.secret_key = self._get_secret_key()
        self.is_sandbox = self._is_sandbox()
        self.base_url = "https://sandbox.interswitchng.com" if self.is_sandbox else "https://webpay.interswitchng.com"

    def _get_merchant_code(self) -> str:
        if self.config and hasattr(self.config, 'api_id'): return self.config.api_id
        return getattr(settings, 'INTERSWITCH_MERCHANT_CODE', '')

    def _get_pay_item_id(self) -> str:
        # Interswitch often uses pay item IDs for different services
        return getattr(settings, 'INTERSWITCH_PAY_ITEM_ID', '101')

    def _get_secret_key(self) -> str:
        if self.config and hasattr(self.config, 'secret_key'): return self.config.secret_key
        return getattr(settings, 'INTERSWITCH_SECRET_KEY', '')

    def _is_sandbox(self) -> bool:
        if self.config and hasattr(self.config, 'is_sandbox'): return self.config.is_sandbox
        return getattr(settings, 'INTERSWITCH_SANDBOX', True)

    def get_supported_countries(self) -> List[str]:
        return ['NG', 'GH', 'GM', 'SL']

    def get_supported_currencies(self) -> List[str]:
        return ['NGN', 'GHS', 'USD']

    def get_supported_methods(self) -> List[str]:
        return ['card', 'webpay', 'verve', 'quickteller']

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Interswitch Webpay initiation.
        Requires a hash of (reference + merchant_code + pay_item_id + amount + callback_url + secret_key)
        """
        amount_in_kobo = int(transaction.amount * 100)
        
        # Hash creation
        hash_string = (
            f"{transaction.provider_reference}{self.merchant_code}{self.pay_item_id}"
            f"{amount_in_kobo}{callback_url}{self.secret_key}"
        )
        hash_value = hashlib.sha512(hash_string.encode()).hexdigest()

        payload = {
            'merchant_code': self.merchant_code,
            'pay_item_id': self.pay_item_id,
            'amount': amount_in_kobo,
            'currency': '566', # NGN ISO numeric code
            'site_redirect_url': callback_url,
            'txn_ref': transaction.provider_reference,
            'hash': hash_value,
            'cust_name': transaction.user.get_full_name() if transaction.user else 'Guest',
            'cust_id': str(transaction.user.id) if transaction.user else 'guest',
        }

        # Interswitch typically uses a form post to their Webpay portal
        webpay_url = f"{self.base_url}/collections/w/pay"

        return {
            'status': 'pending',
            'checkout_url': webpay_url, # Need to POST the payload to this URL
            'provider_reference': transaction.provider_reference,
            'requires_redirect': True,
            'provider_data': payload
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        # Interswitch GET inquiry
        amount_in_kobo = 0 # Need original amount for some verification types
        url = f"{self.base_url}/collections/api/v1/gettransaction.json?merchantcode={self.merchant_code}&transactionreference={reference}&amount={amount_in_kobo}"
        
        headers = {
            "Hash": hashlib.sha512(f"{self.merchant_code}{reference}{self.secret_key}".encode()).hexdigest()
        }
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        
        return {
            'status': 'successful' if data.get('ResponseCode') == '00' else 'failed',
            'amount': float(data.get('Amount', 0)) / 100,
            'reference': reference,
            'provider_data': data
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("Interswitch refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.update',
            'reference': payload.get('txn_ref'),
            'status': payload.get('resp_code'),
            'provider_data': payload
        }
