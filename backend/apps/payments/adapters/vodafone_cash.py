# payments/adapters/vodafone_cash.py
"""
Vodafone Cash Payment Adapter for Egypt

Vodafone Cash is Vodafone Egypt's mobile money service
(rebranded M-Pesa technology)

Supported:
- Egypt (EG) - Currency: EGP

API Documentation:
- https://developer.vodafone.com.eg/
"""

import requests
import base64
from datetime import datetime
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter


class VodafoneCashAdapter(BasePaymentAdapter):
    """
    Vodafone Cash payment adapter for Egypt
    """

    # API URLs
    SANDBOX_URL = 'https://apitest.vodafone.com.eg'
    PRODUCTION_URL = 'https://api.vodafone.com.eg'

    # Endpoints
    OAUTH_URL = "/oauth/token"
    WALLET_PAYMENT_URL = "/vodafonecash/payment"
    WALLET_REFUND_URL = "/vodafonecash/refund"
    TRANSACTION_STATUS_URL = "/vodafonecash/transaction/status"

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.sandbox = getattr(settings, 'VODAFONE_CASH_SANDBOX', True)
        self.base_url = self.SANDBOX_URL if self.sandbox else self.PRODUCTION_URL
        self.access_token = None
        self.token_expiry = None

    @property
    def client_id(self):
        return getattr(settings, 'VODAFONE_CASH_CLIENT_ID', '')

    @property
    def client_secret(self):
        return getattr(settings, 'VODAFONE_CASH_CLIENT_SECRET', '')

    @property
    def merchant_id(self):
        return getattr(settings, 'VODAFONE_CASH_MERCHANT_ID', '')

    @property
    def callback_url(self):
        return getattr(settings, 'VODAFONE_CASH_CALLBACK_URL', '')

    def validate_config(self):
        required = ['client_id', 'client_secret', 'merchant_id']
        for key in required:
            if not getattr(self, key):
                raise ValueError(f"Vodafone Cash {key} is required")

    def _get_access_token(self) -> str:
        """Get OAuth access token"""
        if self.access_token and self.token_expiry and self.token_expiry > datetime.now().timestamp():
            return self.access_token

        headers = {
            'Content-Type': 'application/x-www-form-urlencoded'
        }

        data = {
            'grant_type': 'client_credentials',
            'client_id': self.client_id,
            'client_secret': self.client_secret
        }

        try:
            response = requests.post(
                f"{self.base_url}{self.OAUTH_URL}",
                headers=headers,
                data=data,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            self.access_token = data['access_token']
            expires_in = data.get('expires_in', 3600)
            self.token_expiry = datetime.now().timestamp() + expires_in - 300

            return self.access_token

        except requests.exceptions.RequestException as e:
            raise Exception(f"Failed to get Vodafone Cash access token: {str(e)}")

    def get_supported_countries(self) -> List[str]:
        """Get list of supported country codes"""
        return ['EG']

    def get_supported_currencies(self) -> List[str]:
        """Get list of supported currency codes"""
        return ['EGP']

    def get_supported_methods(self) -> List[str]:
        """Get list of supported payment methods"""
        return ['wallet_payment', 'stk_push']

    def initiate_payment(self, transaction, **kwargs) -> Dict[str, Any]:
        """
        Initiate Vodafone Cash payment

        Requires:
        - Phone number (in format 201XXXXXXXXX)
        - Amount in EGP
        """
        phone_number = kwargs.get('phone_number')
        if not phone_number:
            raise ValueError("Phone number is required for Vodafone Cash payment")

        # Format phone number (Egypt: +20 or 20 prefix)
        phone_number = self._format_phone_number(phone_number)

        # Get access token
        token = self._get_access_token()

        # Prepare payload
        payload = {
            'merchantId': self.merchant_id,
            'amount': float(transaction.amount),
            'currency': 'EGP',
            'phoneNumber': phone_number,
            'transactionId': transaction.provider_reference or str(transaction.id),
            'description': transaction.description or 'Payment',
            'callbackUrl': self.callback_url,
            'expiryMinutes': 30  # Transaction expires in 30 minutes
        }

        headers = {
            'Authorization': f"Bearer {token}",
            'Content-Type': 'application/json'
        }

        try:
            response = requests.post(
                f"{self.base_url}{self.WALLET_PAYMENT_URL}",
                headers=headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            if data.get('status') == 'success' or data.get('responseCode') == '0':
                return {
                    'checkout_id': data.get('transactionId'),
                    'customer_message': data.get('message', 'Check your phone to complete payment'),
                    'merchant_request_id': data.get('merchantReference'),
                    'response_code': data.get('responseCode'),
                    'provider_response': data,
                    'status': 'pending',
                    'requires_mobile_approval': True,
                    'instructions': 'Enter your Vodafone Cash PIN to complete payment'
                }
            else:
                raise Exception(f"Vodafone Cash error: {data.get('message', 'Unknown error')}")

        except requests.exceptions.RequestException as e:
            raise Exception(f"Vodafone Cash connection error: {str(e)}")

    def _format_phone_number(self, phone_number: str) -> str:
        """Format phone number for Egypt"""
        # Remove spaces, dashes, and plus sign
        phone_number = phone_number.replace(' ', '').replace('-', '').replace('+', '')
        
        # Egypt: +20 or 20 prefix
        if phone_number.startswith('0'):
            phone_number = '20' + phone_number[1:]
        elif not phone_number.startswith('20'):
            phone_number = '20' + phone_number
        
        return phone_number

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        """Verify webhook signature using HMAC"""
        if not signature:
            return False
        
        import hmac
        import hashlib
        
        expected_signature = hmac.new(
            self.client_secret.encode(),
            payload,
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(signature, expected_signature)

    def process_webhook(self, payload: Dict[str, Any], headers: Dict[str, str]):
        """Process Vodafone Cash callback"""
        from django.utils import timezone
        from ..models import PaymentTransaction, PaymentProvider

        transaction_id = payload.get('transactionId')
        status = payload.get('status')
        response_code = payload.get('responseCode')
        message = payload.get('message')

        if not transaction_id:
            raise ValueError("No transactionId in callback")

        # Find transaction
        transactions = PaymentTransaction.objects.filter(
            provider=PaymentProvider.VODAFONE_CASH,
            provider_reference=transaction_id
        )

        if not transactions.exists():
            # Try by merchant reference
            merchant_ref = payload.get('merchantReference')
            if merchant_ref:
                transactions = PaymentTransaction.objects.filter(
                    provider_reference=merchant_ref,
                    provider=PaymentProvider.VODAFONE_CASH
                )

        if not transactions.exists():
            raise ValueError(f"Transaction not found: {transaction_id}")

        transaction = transactions.first()

        # Update transaction based on status
        if status == 'success' or response_code == '0':
            transaction.status = 'successful'
            transaction.metadata.update({
                'vodafone_callback': payload,
                'payment_status': status,
                'country': 'EG'
            })
            transaction.completed_at = timezone.now()
            transaction.webhook_received = True

            # Trigger success logic
            self._handle_successful_payment(transaction)

        elif status == 'failed' or status == 'declined' or response_code != '0':
            transaction.status = 'failed'
            transaction.metadata['vodafone_error'] = {
                'response_code': response_code,
                'message': message,
            }
        elif status == 'cancelled':
            transaction.status = 'cancelled'
            transaction.metadata['vodafone_cancelled'] = True

        transaction.save()

        # Log webhook
        self.log_webhook(payload, headers, 'payment_callback', transaction)

        return transaction

    def check_status(self, transaction_id: str) -> Dict[str, Any]:
        """Check transaction status"""
        token = self._get_access_token()

        headers = {
            'Authorization': f"Bearer {token}",
            'Content-Type': 'application/json',
        }

        params = {
            'transactionId': transaction_id
        }

        try:
            response = requests.get(
                f"{self.base_url}{self.TRANSACTION_STATUS_URL}",
                headers=headers,
                params=params,
                timeout=30,
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Failed to check Vodafone Cash status: {str(e)}")

    def refund_payment(self, transaction, amount=None, reason="") -> Dict[str, Any]:
        """Process refund"""
        token = self._get_access_token()

        payload = {
            'merchantId': self.merchant_id,
            'transactionId': transaction.provider_reference,
            'amount': float(amount or transaction.amount),
            'currency': 'EGP',
            'reason': reason or 'Refund'
        }

        headers = {
            'Authorization': f"Bearer {token}",
            'Content-Type': 'application/json',
        }

        try:
            response = requests.post(
                f"{self.base_url}{self.WALLET_REFUND_URL}",
                headers=headers,
                json=payload,
                timeout=30,
            )
            response.raise_for_status()
            data = response.json()

            return {
                'status': 'successful' if data.get('status') == 'success' else 'failed',
                'refund_reference': data.get('refundTransactionId'),
                'provider_data': data
            }
        except requests.exceptions.RequestException as e:
            raise Exception(f"Failed to process refund: {str(e)}")
