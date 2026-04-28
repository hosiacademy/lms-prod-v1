import requests
import json
import hmac
import hashlib
from django.conf import settings
from django.utils import timezone
from .base import BasePaymentAdapter, PaymentError

class PaystackAdapter(BasePaymentAdapter):
    """Paystack adapter for Nigeria, Ghana, Kenya, South Africa"""
    
    API_URL = "https://api.paystack.co"
    
    def get_supported_countries(self):
        return ['NG', 'GH', 'KE', 'ZA']
    
    def get_supported_currencies(self):
        return ['NGN', 'GHS', 'KES', 'ZAR', 'USD']

    def get_supported_methods(self):
        # QR code removed from options
        return [
            'card',         # Visa/Mastercard/Verve
            'bank_transfer', # Nigerian bank transfers
            'ussd',         # Nigeria USSD
            'mobile_money', # Ghana & Kenya mobile money
            'bank',         # Direct bank debit
        ]

    def _get_secret_key(self):
        # Prefer config-based secret key, fallback to settings
        if self.config and getattr(self.config, 'secret_key', None):
            return self.config.secret_key
        return getattr(settings, 'PAYSTACK_SECRET_KEY', '')

    def _get_headers(self):
        return {
            "Authorization": f"Bearer {self._get_secret_key()}",
            "Content-Type": "application/json",
        }

    def initiate_payment(self, transaction, callback_url: str, **kwargs):
        """
        Initiate Paystack payment
        Docs: https://paystack.com/docs/api/transaction/#initialize
        """
        # Get customer email
        user = transaction.user
        email = getattr(user, 'email', None)
        
        if not email:
            email = (transaction.individual_email or 
                     transaction.company_email or
                     transaction.metadata.get('email') or 
                     transaction.metadata.get('individual_details', {}).get('email') or 
                     transaction.metadata.get('corporate_details', {}).get('contact_email') or
                     kwargs.get('email'))
        
        if not email:
            raise PaymentError("Email is required for Paystack payment initiation")

        # Paystack amount is in kobo/cents (smallest unit)
        amount_cents = int(float(transaction.amount) * 100)
        
        payload = {
            "email": email,
            "amount": amount_cents,
            "currency": transaction.currency,
            "reference": transaction.provider_reference,
            "callback_url": callback_url,
            "metadata": {
                "transaction_id": str(transaction.id),
                "order_id": str(transaction.order_id) if transaction.order_id else None,
                **transaction.metadata
            }
        }

        try:
            response = requests.post(
                f"{self.API_URL}/transaction/initialize",
                headers=self._get_headers(),
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            if data.get('status'):
                return {
                    'status': 'pending',
                    'checkout_url': data['data']['authorization_url'],
                    'provider_reference': data['data']['reference'],
                    'requires_redirect': True,
                    'provider_data': data
                }
            else:
                raise PaymentError(f"Paystack initialization failed: {data.get('message')}")

        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Paystack connection error: {str(e)}")

    def verify_payment(self, reference: str):
        """Verify Paystack payment"""
        try:
            response = requests.get(
                f"{self.API_URL}/transaction/verify/{reference}",
                headers=self._get_headers(),
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            if data.get('status') and data['data']['status'] == 'success':
                return {
                    'status': 'successful',
                    'amount': float(data['data']['amount']) / 100,
                    'currency': data['data']['currency'],
                    'reference': data['data']['reference'],
                    'confirmed_at': data['data']['paid_at'],
                    'provider_data': data
                }
            return {
                'status': data['data']['status'] if data.get('status') else 'failed',
                'provider_data': data
            }
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Paystack verification failed: {str(e)}")

    def refund_payment(self, transaction, amount=None, reason=""):
        """Refund Paystack payment"""
        refund_amount = amount or transaction.amount
        payload = {
            "transaction": transaction.provider_reference,
            "amount": int(float(refund_amount) * 100),
            "customer_note": reason
        }
        
        try:
            response = requests.post(
                f"{self.API_URL}/refund",
                headers=self._get_headers(),
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            return {
                'status': 'successful' if data.get('status') else 'failed',
                'refund_reference': data['data']['id'] if data.get('status') else None,
                'provider_data': data
            }
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Paystack refund failed: {str(e)}")

    def verify_webhook_signature(self, payload, headers):
        """Verify Paystack webhook signature"""
        secret = getattr(settings, 'PAYSTACK_WEBHOOK_SECRET', '')
        if not secret:
            return True # Not recommended for production
            
        signature = headers.get('HTTP_X_PAYSTACK_SIGNATURE')
        if not signature:
            return False

        hash = hmac.new(
            secret.encode('utf-8'),
            msg=payload,
            digestmod=hashlib.sha512
        ).hexdigest()
        
        return hmac.compare_digest(hash, signature)

    def parse_webhook(self, payload):
        """Parse Paystack webhook payload"""
        event = payload.get('event')
        data = payload.get('data', {})
        
        # Standardize status
        status = 'pending'
        if event == 'charge.success':
            status = 'successful'
        elif event in ['charge.failed', 'transfer.failed']:
            status = 'failed'
        elif event == 'transfer.success':
            status = 'successful'
            
        return {
            'event': event,
            'reference': data.get('reference'),
            'status': status,
            'amount': float(data.get('amount', 0)) / 100,
            'currency': data.get('currency'),
            'method': data.get('channel'),
            'timestamp': data.get('paid_at') or timezone.now().isoformat(),
            'provider_data': payload
        }

    def get_provider_name(self):
        return "Paystack"

    def get_provider_code(self):
        return "paystack"