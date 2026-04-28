# payments/adapters/vodacom_mpesa.py
"""
Vodacom M-Pesa Payment Adapter

Supports:
- Tanzania (TZ) - Currency: TZS
- Mozambique (MZ) - Currency: MZN
- Democratic Republic of Congo (CD) - Currency: USD/CDF
- Lesotho (LS) - Currency: LSL/ZAR

API Documentation:
- Tanzania: https://developer.vodacom.co.tz/
- Mozambique: https://developer.vodacom.co.mz/
"""

import requests
import base64
from datetime import datetime
from typing import Dict, Any, List
from django.conf import settings
from .base import BasePaymentAdapter


class VodacomMpesaAdapter(BasePaymentAdapter):
    """
    Vodacom M-Pesa payment adapter for Tanzania, Mozambique, DRC, and Lesotho
    """

    # API URLs by country
    API_URLS = {
        'TZ': {
            'sandbox': 'https://openapi.sandbox.vodacom.co.tz',
            'production': 'https://openapi.vodacom.co.tz'
        },
        'MZ': {
            'sandbox': 'https://openapi.sandbox.vodacom.co.mz',
            'production': 'https://openapi.vodacom.co.mz'
        },
        'CD': {
            'sandbox': 'https://openapi.sandbox.vodacom.cd',
            'production': 'https://openapi.vodacom.cd'
        },
        'LS': {
            'sandbox': 'https://openapi.sandbox.vodacom.co.ls',
            'production': 'https://openapi.vodacom.co.ls'
        }
    }

    # Currencies by country
    CURRENCIES = {
        'TZ': 'TZS',
        'MZ': 'MZN',
        'CD': 'USD',  # Also supports CDF
        'LS': 'LSL'   # Also supports ZAR
    }

    # Endpoints
    OAUTH_URL = "/oauth/v1/generate?grant_type=client_credentials"
    STK_PUSH_URL = "/mpesa/stkpush/v1/processrequest"
    QUERY_URL = "/mpesa/stkpushquery/v1/query"
    REVERSAL_URL = "/mpesa/reversal/v1/request"

    def __init__(self, provider_config=None, country_code: str = 'TZ'):
        super().__init__(provider_config)
        self.country_code = country_code.upper()
        
        # Get sandbox setting
        self.sandbox = getattr(settings, 'VODACOM_MPESA_SANDBOX', True)
        
        # Get country-specific base URL
        country_urls = self.API_URLS.get(self.country_code, self.API_URLS['TZ'])
        self.base_url = country_urls['sandbox'] if self.sandbox else country_urls['production']
        
        self.access_token = None
        self.token_expiry = None

    @property
    def consumer_key(self):
        return getattr(settings, f'VODACOM_MPESA_{self.country_code}_CONSUMER_KEY', '')

    @property
    def consumer_secret(self):
        return getattr(settings, f'VODACOM_MPESA_{self.country_code}_CONSUMER_SECRET', '')

    @property
    def business_shortcode(self):
        return getattr(settings, f'VODACOM_MPESA_{self.country_code}_SHORTCODE', '')

    @property
    def passkey(self):
        return getattr(settings, f'VODACOM_MPESA_{self.country_code}_PASSKEY', '')

    @property
    def callback_url(self):
        return getattr(settings, f'VODACOM_MPESA_{self.country_code}_CALLBACK_URL', '')

    def validate_config(self):
        required = ['consumer_key', 'consumer_secret', 'business_shortcode', 'passkey']
        for key in required:
            if not getattr(self, key):
                raise ValueError(f"Vodacom M-Pesa {self.country_code} {key} is required")

    def _get_access_token(self) -> str:
        """Get OAuth access token"""
        if self.access_token and self.token_expiry and self.token_expiry > datetime.now().timestamp():
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
            expires_in = data.get('expires_in', 3599)
            self.token_expiry = datetime.now().timestamp() + expires_in - 300

            return self.access_token

        except requests.exceptions.RequestException as e:
            raise Exception(f"Failed to get Vodacom M-Pesa access token: {str(e)}")

    def _generate_password(self, timestamp: str) -> str:
        """Generate M-Pesa API password"""
        string_to_encode = f"{self.business_shortcode}{self.passkey}{timestamp}"
        encoded = base64.b64encode(string_to_encode.encode()).decode()
        return encoded

    def get_supported_countries(self) -> List[str]:
        """Get list of supported country codes"""
        return list(self.API_URLS.keys())

    def get_supported_currencies(self) -> List[str]:
        """Get list of supported currency codes"""
        currencies = ['TZS', 'MZN', 'USD']
        if self.country_code == 'LS':
            currencies.append('ZAR')
            currencies.append('LSL')
        if self.country_code == 'CD':
            currencies.append('CDF')
        return currencies

    def get_supported_methods(self) -> List[str]:
        """Get list of supported payment methods"""
        return ['stk_push', 'paybill', 'till_number']

    def initiate_payment(self, transaction, **kwargs) -> Dict[str, Any]:
        """
        Initiate Vodacom M-Pesa STK Push

        Requires:
        - Phone number (in format 2557XXXXXXXX for Tanzania, etc.)
        - Amount in local currency
        """
        phone_number = kwargs.get('phone_number')
        if not phone_number:
            raise ValueError("Phone number is required for Vodacom M-Pesa payment")

        # Format phone number based on country
        phone_number = self._format_phone_number(phone_number)

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
            'Amount': int(float(transaction.amount)),
            'PartyA': phone_number,
            'PartyB': self.business_shortcode,
            'PhoneNumber': phone_number,
            'CallBackURL': self.callback_url,
            'AccountReference': transaction.provider_reference or transaction.id,
            'TransactionDesc': transaction.description[:20] if transaction.description else 'Payment'
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
                    'status': 'pending',
                    'requires_mobile_approval': True,
                    'instructions': f"Check your phone to complete payment"
                }
            else:
                raise Exception(f"Vodacom M-Pesa error: {data.get('ResponseDescription', 'Unknown error')}")

        except requests.exceptions.RequestException as e:
            raise Exception(f"Vodacom M-Pesa connection error: {str(e)}")

    def _format_phone_number(self, phone_number: str) -> str:
        """Format phone number based on country"""
        # Remove spaces, dashes, and plus sign
        phone_number = phone_number.replace(' ', '').replace('-', '').replace('+', '')
        
        # Country-specific formatting
        if self.country_code == 'TZ':
            # Tanzania: +255 or 255 prefix
            if phone_number.startswith('0'):
                phone_number = '255' + phone_number[1:]
            elif not phone_number.startswith('255'):
                phone_number = '255' + phone_number
        elif self.country_code == 'MZ':
            # Mozambique: +258 or 258 prefix
            if phone_number.startswith('0'):
                phone_number = '258' + phone_number[1:]
            elif not phone_number.startswith('258'):
                phone_number = '258' + phone_number
        elif self.country_code == 'CD':
            # DRC: +243 or 243 prefix
            if phone_number.startswith('0'):
                phone_number = '243' + phone_number[1:]
            elif not phone_number.startswith('243'):
                phone_number = '243' + phone_number
        elif self.country_code == 'LS':
            # Lesotho: +266 or 266 prefix
            if phone_number.startswith('0'):
                phone_number = '266' + phone_number[1:]
            elif not phone_number.startswith('266'):
                phone_number = '266' + phone_number
        
        return phone_number

    def verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        """Vodacom M-Pesa doesn't use webhook signatures"""
        return True

    def process_webhook(self, payload: Dict[str, Any], headers: Dict[str, str]):
        """Process Vodacom M-Pesa callback"""
        from django.utils import timezone
        from ..models import PaymentTransaction, PaymentProvider

        callback_data = payload.get('Body', {}).get('stkCallback', {})
        checkout_id = callback_data.get('CheckoutRequestID')
        result_code = callback_data.get('ResultCode')
        result_desc = callback_data.get('ResultDesc')

        if not checkout_id:
            raise ValueError("No CheckoutRequestID in callback")

        # Find transaction by metadata
        transactions = PaymentTransaction.objects.filter(
            provider=PaymentProvider.VODACOM_MPESA,
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
                        provider=PaymentProvider.VODACOM_MPESA
                    )
                    break

        if not transactions.exists():
            raise ValueError(f"Transaction not found for checkout ID: {checkout_id}")

        transaction = transactions.first()

        # Update transaction based on result code
        if result_code == 0:
            transaction.status = 'successful'

            # Extract payment details
            callback_items = callback_data.get('CallbackMetadata', {}).get('Item', [])
            payment_details = {}
            for item in callback_items:
                payment_details[item.get('Name')] = item.get('Value')

            transaction.metadata.update({
                'vodacom_callback': callback_data,
                'payment_details': payment_details,
                'country': self.country_code
            })
            transaction.completed_at = timezone.now()
            transaction.webhook_received = True

            # Trigger success logic
            self._handle_successful_payment(transaction)

        else:
            transaction.status = 'failed'
            transaction.metadata['vodacom_error'] = {
                'result_code': result_code,
                'result_desc': result_desc,
            }

        transaction.save()

        # Log webhook
        self.log_webhook(payload, headers, 'stk_callback', transaction)

        return transaction

    def check_status(self, checkout_id: str) -> Dict[str, Any]:
        """Query STK push status"""
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
            raise Exception(f"Failed to query Vodacom M-Pesa status: {str(e)}")

    def refund_payment(self, transaction, amount=None, reason="") -> Dict[str, Any]:
        """Process refund via M-Pesa reversal"""
        token = self._get_access_token()

        payload = {
            'InitiatorName': getattr(settings, f'VODACOM_MPESA_{self.country_code}_INITIATOR', ''),
            'SecurityCredential': getattr(settings, f'VODACOM_MPESA_{self.country_code}_SECURITY_CREDENTIAL', ''),
            'CommandID': 'TransactionReversal',
            'TransactionID': transaction.provider_reference,
            'Amount': int(float(amount or transaction.amount)),
            'ReceiverParty': transaction.metadata.get('phone_number', ''),
            'RecieverIdentifierType': 'MSISDN',
            'Occasion': reason or 'Refund',
        }

        headers = {
            'Authorization': f"Bearer {token}",
            'Content-Type': 'application/json',
        }

        try:
            response = requests.post(
                f"{self.base_url}{self.REVERSAL_URL}",
                headers=headers,
                json=payload,
                timeout=30,
            )
            response.raise_for_status()
            data = response.json()

            return {
                'status': 'successful' if data.get('ResultCode') == '0' else 'failed',
                'refund_reference': data.get('ConversationID'),
                'provider_data': data
            }
        except requests.exceptions.RequestException as e:
            raise Exception(f"Failed to process refund: {str(e)}")
