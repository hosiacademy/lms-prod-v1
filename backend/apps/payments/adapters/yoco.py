import requests
from django.conf import settings
from django.utils import timezone
from .base import BasePaymentAdapter, PaymentError


class YocoAdapter(BasePaymentAdapter):
    """Yoco for South African card payments"""
    
    API_URL = "https://online.yoco.com/v1"
    
    def get_supported_countries(self):
        return ['ZA']

    def get_supported_currencies(self):
        return ['ZAR']

    def get_supported_methods(self):
        # QR code removed - only card and payment link supported
        return ['card', 'payment_link']

    def _get_secret_key(self):
        if self.config and getattr(self.config, 'secret_key', None):
            return self.config.secret_key
        return getattr(settings, 'YOCO_SECRET_KEY', '')

    def _get_headers(self):
        return {
            "X-Auth-Secret-Key": self._get_secret_key(),
            "Content-Type": "application/json",
        }

    def initiate_payment(self, transaction, callback_url: str, **kwargs):
        """
        Initiate Yoco payment
        Docs: https://developer.yoco.com/online/checkout/integration#standard-checkout
        """
        # Yoco amount is in cents
        amount_cents = int(float(transaction.amount) * 100)
        
        # Get customer details
        user = transaction.user
        email = getattr(user, 'email', None) or transaction.individual_email or transaction.company_email
        name = ""
        if user:
            name = user.get_full_name()
        else:
            name = transaction.individual_name or transaction.company_name or ""
            
        payload = {
            "amount": amount_cents,
            "currency": "ZAR",
            "externalId": transaction.provider_reference,
            "successUrl": callback_url,
            "cancelUrl": callback_url, # Or a separate cancel URL if provided
            "metadata": {
                "transaction_id": str(transaction.id),
                "order_id": str(transaction.order_id) if transaction.order_id else None,
                **transaction.metadata
            }
        }
        
        if email:
            payload['customer'] = {
                'email': email
            }
            if name:
                parts = name.split(' ')
                payload['customer']['firstName'] = parts[0]
                if len(parts) > 1:
                    payload['customer']['lastName'] = ' '.join(parts[1:])

        try:
            response = requests.post(
                f"{self.API_URL}/checkouts",
                headers=self._get_headers(),
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            return {
                'status': 'pending',
                'checkout_url': data['url'],
                'provider_reference': data['id'],
                'requires_redirect': True,
                'provider_data': data
            }

        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Yoco connection error: {str(e)}")

    def verify_payment(self, reference: str):
        """Verify Yoco payment status"""
        try:
            # Note: reference here could be the Yoco Checkout ID or externalId
            # Yoco search API or direct checkout status check
            response = requests.get(
                f"{self.API_URL}/checkouts/{reference}",
                headers=self._get_headers(),
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            status = 'pending'
            if data.get('status') == 'successful':
                status = 'successful'
            elif data.get('status') in ['failed', 'expired', 'cancelled']:
                status = 'failed'

            return {
                'status': status,
                'amount': float(data.get('amount', 0)) / 100,
                'currency': data.get('currency'),
                'reference': data.get('id'),
                'provider_data': data
            }
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Yoco verification failed: {str(e)}")

    def refund_payment(self, transaction, amount=None, reason=""):
        """Refund Yoco payment"""
        # Yoco refund API
        # POST /v1/refunds
        refund_amount = amount or transaction.amount
        payload = {
            "checkoutId": transaction.provider_reference, # Or transactionId if we stored it
            "amount": int(float(refund_amount) * 100)
        }
        
        try:
            response = requests.post(
                f"{self.API_URL}/refunds",
                headers=self._get_headers(),
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            return {
                'status': 'successful' if data.get('status') == 'successful' else 'failed',
                'refund_reference': data.get('id'),
                'provider_data': data
            }
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Yoco refund failed: {str(e)}")

    def verify_webhook_signature(self, payload, headers):
        """Yoco webhooks verification (usually via shared secret)"""
        return True # Default to True for now, implement if secret is available

    def parse_webhook(self, payload):
        """Parse Yoco webhook"""
        # Yoco webhook format varies based on event
        event = payload.get('type')
        data = payload.get('payload', {})
        
        status = 'pending'
        if event == 'payment.succeeded':
            status = 'successful'
        elif event == 'payment.failed':
            status = 'failed'
            
        return {
            'event': event,
            'reference': data.get('externalId') or data.get('id'),
            'status': status,
            'amount': float(data.get('amount', 0)) / 100,
            'currency': data.get('currency'),
            'timestamp': timezone.now().isoformat(),
            'provider_data': payload
        }

    def get_provider_name(self):
        return "Yoco"

    def get_provider_code(self):
        return "yoco"