# payments/adapters/mpesa.py
import requests
import base64
from datetime import datetime
from typing import Dict, Any, Optional
from django.conf import settings
from .base import BasePaymentAdapter
from ..models import PaymentTransaction, PaymentProvider, Currency

class MpesaAdapter(BasePaymentAdapter):
    """Safaricom M-Pesa payment adapter"""
    
    # API URLs
    PRODUCTION_URL = "https://api.safaricom.co.ke"
    SANDBOX_URL = "https://sandbox.safaricom.co.ke"
    
    # Endpoints
    OAUTH_URL = "/oauth/v1/generate?grant_type=client_credentials"
    STK_PUSH_URL = "/mpesa/stkpush/v1/processrequest"
    QUERY_URL = "/mpesa/stkpushquery/v1/query"
    
    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        # M-Pesa config comes from Django settings, not provider_config
        self.sandbox = getattr(settings, 'MPESA_SANDBOX', True)
        self.base_url = self.SANDBOX_URL if self.sandbox else self.PRODUCTION_URL
        self.access_token = None
        self.token_expiry = None
    
    @property
    def consumer_key(self):
        return getattr(settings, 'MPESA_CONSUMER_KEY', '')
    
    @property
    def consumer_secret(self):
        return getattr(settings, 'MPESA_CONSUMER_SECRET', '')
    
    @property
    def business_shortcode(self):
        return getattr(settings, 'MPESA_BUSINESS_SHORTCODE', '')
    
    @property
    def passkey(self):
        return getattr(settings, 'MPESA_PASSKEY', '')
    
    @property
    def callback_url(self):
        return getattr(settings, 'MPESA_CALLBACK_URL', '')
    
    def validate_config(self):
        required = ['consumer_key', 'consumer_secret', 'business_shortcode', 'passkey']
        for key in required:
            if not getattr(self, key):
                raise ValueError(f"M-Pesa {key} is required")

    def _get_access_token(self) -> str:
        """Get OAuth access token"""
        if self.access_token and self.token_expiry and self.token_expiry > datetime.now():
            return self.access_token

        auth_string = f"{self.consumer_key}:{self.consumer_secret}"
        encoded_auth = base64.b64encode(auth_string.encode()).decode()

        headers = {
            'Authorization': f"Basic {encoded_auth}"
        }

        try:
            response = requests.get(
                f"{self.base_url}{self.OAUTH_URL}",
                headers=headers,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            self.access_token = data['access_token']
            # Set expiry 5 minutes before actual expiry for safety
            expires_in = data.get('expires_in', 3599)
            self.token_expiry = datetime.now().timestamp() + expires_in - 300

            return self.access_token

        except requests.exceptions.RequestException as e:
            raise Exception(f"Failed to get M-Pesa access token: {str(e)}")

    def _generate_password(self, timestamp: str) -> str:
        """Generate M-Pesa API password"""
        import hashlib

        string_to_encode = f"{self.business_shortcode}{self.passkey}{timestamp}"
        encoded = base64.b64encode(string_to_encode.encode()).decode()

        return encoded
    
    def initiate_payment(self, transaction: PaymentTransaction, **kwargs) -> Dict[str, Any]:
        """
        Initiate M-Pesa STK Push (Lipa Na M-Pesa Online)
        
        Requires:
        - Phone number (in format 2547XXXXXXXX)
        - Amount in KES
        """
        phone_number = kwargs.get('phone_number')
        if not phone_number:
            raise ValueError("Phone number is required for M-Pesa payment")
        
        # Format phone number (ensure 254 format)
        if phone_number.startswith('0'):
            phone_number = '254' + phone_number[1:]
        elif phone_number.startswith('+'):
            phone_number = phone_number[1:]
        
        # Get access token
        token = self._get_access_token()
        
        # Generate timestamp
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')

        # Prepare payload
        payload = {
            'BusinessShortCode': self.business_shortcode,
            'Password': self._generate_password(timestamp),
            'Timestamp': timestamp,
            'TransactionType': 'CustomerPayBillOnline',
            'Amount': int(transaction.amount),
            'PartyA': phone_number,
            'PartyB': self.business_shortcode,
            'PhoneNumber': phone_number,
            'CallBackURL': self.callback_url,
            'AccountReference': transaction.provider_reference,
            'TransactionDesc': transaction.description[:20]  # Max 20 chars
        }
        
        headers = {
            'Authorization': f"Bearer {token}",
            'Content-Type': 'application/json'
        }
        
        try:
            response = requests.post(
                f"{self.base_url}{self.STK_PUSH_URL}",
                headers=headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            
            if data.get('ResponseCode') == '0':
                return {
                    'checkout_id': data['CheckoutRequestID'],
                    'customer_message': data['CustomerMessage'],
                    'merchant_request_id': data['MerchantRequestID'],
                    'response_code': data['ResponseCode'],
                    'provider_response': data,
                }
            else:
                raise Exception(f"M-Pesa error: {data.get('ResponseDescription', 'Unknown error')}")
                
        except requests.exceptions.RequestException as e:
            raise Exception(f"M-Pesa connection error: {str(e)}")
    
    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        """M-Pesa doesn't use webhook signatures, validate callback instead"""
        return True  # We'll validate the callback data structure
    
    def process_webhook(self, payload: Dict[str, Any], headers: Dict[str, str]) -> PaymentTransaction:
        """Process M-Pesa callback"""
        from django.utils import timezone
        
        # M-Pesa callback structure
        callback_data = payload.get('Body', {}).get('stkCallback', {})
        checkout_id = callback_data.get('CheckoutRequestID')
        result_code = callback_data.get('ResultCode')
        result_desc = callback_data.get('ResultDesc')
        
        if not checkout_id:
            raise ValueError("No CheckoutRequestID in callback")
        
        # Find transaction by metadata (we store CheckoutRequestID in metadata)
        transactions = PaymentTransaction.objects.filter(
            provider=PaymentProvider.M_PESA,
            metadata__checkout_id=checkout_id
        )
        
        if not transactions.exists():
            # Try to find by AccountReference
            callback_items = callback_data.get('CallbackMetadata', {}).get('Item', [])
            for item in callback_items:
                if item.get('Name') == 'AccountReference':
                    account_ref = item.get('Value')
                    transactions = PaymentTransaction.objects.filter(
                        provider_reference=account_ref,
                        provider=PaymentProvider.M_PESA
                    )
                    break
        
        if not transactions.exists():
            raise ValueError(f"Transaction not found for checkout ID: {checkout_id}")
        
        transaction = transactions.first()
        
        # Update transaction based on result code
        if result_code == 0:
            # Successful payment
            transaction.status = 'successful'
            
            # Extract payment details from callback
            callback_items = callback_data.get('CallbackMetadata', {}).get('Item', [])
            payment_details = {}
            for item in callback_items:
                payment_details[item.get('Name')] = item.get('Value')
            
            transaction.metadata.update({
                'mpesa_callback': callback_data,
                'payment_details': payment_details,
            })
            transaction.completed_at = timezone.now()
            transaction.webhook_received = True
            
            # Trigger payment success logic
            self._handle_successful_payment(transaction)
            
        else:
            # Failed payment
            transaction.status = 'failed'
            transaction.metadata['mpesa_error'] = {
                'result_code': result_code,
                'result_desc': result_desc,
            }
        
        transaction.save()
        
        # Log webhook
        self.log_webhook(payload, headers, 'stk_callback', transaction)
        
        return transaction
    
    def check_status(self, checkout_id: str) -> Dict[str, Any]:
        """Query M-Pesa STK push status"""
        token = self._get_access_token()
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        
        payload = {
            'BusinessShortCode': self.business_shortcode,
            'Password': self._generate_password(timestamp),
            'Timestamp': timestamp,
            'CheckoutRequestID': checkout_id,
        }
        
        headers = {
            'Authorization': f"Bearer {token}",
            'Content-Type': 'application/json',
        }
        
        try:
            response = requests.post(
                f"{self.base_url}{self.QUERY_URL}",
                headers=headers,
                json=payload,
                timeout=30,
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Failed to query M-Pesa status: {str(e)}")

    def get_supported_countries(self) -> list:
        """Get list of supported country codes."""
        return ['KE']  # Kenya

    def get_supported_currencies(self) -> list:
        """Get list of supported currency codes."""
        return ['KES']  # Kenyan Shilling

    def get_supported_methods(self) -> list:
        """Get list of supported payment methods."""
        return ['stk_push', 'paybill', 'till_number']