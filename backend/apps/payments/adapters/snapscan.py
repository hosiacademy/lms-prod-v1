# apps/payments/adapters/snapscan.py
import requests
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter, PaymentError


class SnapScanAdapter(BasePaymentAdapter):
    """
    SnapScan - South African QR Code payments.
    Documentation: https://developer.snapscan.co.za/
    """

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.api_key = self._get_api_key()
        self.merchant_id = self._get_merchant_id()
        self.base_url = "https://pos.snapscan.io/qr"

    def _get_api_key(self) -> str:
        if self.config and hasattr(self.config, 'api_key'): return self.config.api_key
        return getattr(settings, 'SNAPSCAN_API_KEY', '')

    def _get_merchant_id(self) -> str:
        if self.config and hasattr(self.config, 'api_id'): return self.config.api_id
        return getattr(settings, 'SNAPSCAN_MERCHANT_ID', '')

    def get_supported_countries(self) -> List[str]:
        return ['ZA']

    def get_supported_currencies(self) -> List[str]:
        return ['ZAR']

    def get_supported_methods(self) -> List[str]:
        return ['qr_code', 'snapscan']

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        SnapScan QR Code generation.
        """
        amount_in_cents = int(transaction.amount * 100)
        
        # SnapScan deep link / QR format
        # https://pos.snapscan.io/qr/MERCHANT_ID?id=REFERENCE&amount=CENTS&strict=true
        qr_url = f"{self.base_url}/{self.merchant_id}?id={transaction.provider_reference}&amount={amount_in_cents}&strict=true"

        return {
            'status': 'pending',
            'checkout_url': qr_url,
            'qr_code_data': qr_url,
            'provider_reference': transaction.provider_reference,
            'requires_redirect': True,
            'provider_data': {
                'qr_url': qr_url,
                'merchant_id': self.merchant_id,
                'reference': transaction.provider_reference
            }
        }

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        # SnapScan API status check
        url = f"https://api.snapscan.io/merchant/api/v1/payments/{reference}"
        headers = {"Authorization": f"Bearer {self.api_key}"}
        
        response = requests.get(url, headers=headers)
        if response.status_code == 404:
            return {'status': 'pending', 'reference': reference}
            
        response.raise_for_status()
        data = response.json()
        
        return {
            'status': 'successful' if data.get('status') == 'completed' else 'pending',
            'amount': float(data.get('totalAmount', 0)) / 100,
            'reference': reference,
            'provider_data': data
        }

    def refund_payment(self, transaction, amount=None, reason=""):
        raise NotImplementedError("SnapScan refund not implemented")

    def verify_webhook_signature(self, payload, headers):
        return True

    def parse_webhook(self, payload):
        return {
            'event': 'payment.success',
            'reference': payload.get('id'),
            'status': 'completed',
            'amount': float(payload.get('totalAmount', 0)) / 100,
            'provider_data': payload
        }
