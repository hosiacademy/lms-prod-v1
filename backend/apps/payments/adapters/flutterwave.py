# apps/payments/adapters/flutterwave.py
import requests
import hashlib
import hmac
import json
import logging
from typing import Dict, Any, Optional
from django.conf import settings
from django.utils import timezone
from .base import BasePaymentAdapter, PaymentError, SignatureVerificationError
from ..models import PaymentProvider, PaymentMethod, Currency, CountryCode
from ..services.flutterwave_oauth import flutterwave_oauth

logger = logging.getLogger(__name__)


class FlutterwaveAdapter(BasePaymentAdapter):
    """Flutterwave payment adapter - Pan-African aggregator"""
    
    PROVIDER_NAME = "Flutterwave"
    PROVIDER_CODE = PaymentProvider.FLUTTERWAVE
    
    # API URLs
    PRODUCTION_URL = "https://api.flutterwave.com/v3"
    SANDBOX_URL = "https://api.flutterwave.com/v3"
    
    # Country-specific configurations - CRITICAL: Each country uses its official currency ONLY
    COUNTRY_CONFIGS = {
        # Southern Africa
        'ZA': {'currency': 'ZAR', 'methods': ['card', 'bank_transfer', 'eft']},  # South African Rand
        'ZW': {'currency': 'USD', 'methods': ['card', 'mobile_money', 'paynow']},  # Zimbabwe uses USD
        'ZM': {'currency': 'ZMW', 'methods': ['card', 'mobile_money']},  # Zambian Kwacha
        'BW': {'currency': 'BWP', 'methods': ['card', 'bank_transfer']},  # Botswana Pula
        'NA': {'currency': 'NAD', 'methods': ['card', 'bank_transfer']},  # Namibian Dollar
        'LS': {'currency': 'LSL', 'methods': ['card', 'mobile_money']},  # Lesotho Loti
        'SZ': {'currency': 'SZL', 'methods': ['card', 'mobile_money']},  # Swazi Lilangeni
        'MZ': {'currency': 'MZN', 'methods': ['card', 'mobile_money', 'mpesa']},  # Mozambican Metical
        'AO': {'currency': 'AOA', 'methods': ['card', 'bank_transfer']},  # Angolan Kwanza
        # East Africa - M-Pesa region
        'KE': {'currency': 'KES', 'methods': ['card', 'mobile_money', 'mpesa', 'paybill']},  # Kenyan Shilling - M-Pesa PRIMARY
        'TZ': {'currency': 'TZS', 'methods': ['card', 'mobile_money', 'mpesa']},  # Tanzanian Shilling
        'UG': {'currency': 'UGX', 'methods': ['card', 'mobile_money', 'mtn_momo', 'airtel_money']},  # Ugandan Shilling
        'RW': {'currency': 'RWF', 'methods': ['card', 'mobile_money', 'mtn_momo']},  # Rwandan Franc
        'BI': {'currency': 'BIF', 'methods': ['card', 'mobile_money']},  # Burundian Franc
        # West Africa
        'NG': {'currency': 'NGN', 'methods': ['card', 'bank_transfer', 'ussd']},  # Nigerian Naira
        'GH': {'currency': 'GHS', 'methods': ['card', 'mobile_money', 'bank_transfer']},  # Ghanaian Cedi
        'CI': {'currency': 'XOF', 'methods': ['card', 'mobile_money', 'orange_money']},  # West African CFA
        'SN': {'currency': 'XOF', 'methods': ['card', 'mobile_money', 'orange_money']},  # West African CFA
        'ML': {'currency': 'XOF', 'methods': ['card', 'mobile_money']},  # West African CFA
        'BF': {'currency': 'XOF', 'methods': ['card', 'mobile_money']},  # West African CFA
        'TG': {'currency': 'XOF', 'methods': ['card', 'mobile_money']},  # West African CFA
        'BJ': {'currency': 'XOF', 'methods': ['card', 'mobile_money']},  # West African CFA
        # Central Africa
        'CM': {'currency': 'XAF', 'methods': ['card', 'mobile_money', 'mtn_momo', 'orange_money']},  # Central African CFA
        'GA': {'currency': 'XAF', 'methods': ['card', 'mobile_money']},  # Central African CFA
        'CG': {'currency': 'XAF', 'methods': ['card', 'mobile_money']},  # Central African CFA
        'CD': {'currency': 'CDF', 'methods': ['card', 'mobile_money', 'mpesa']},  # Congolese Franc
        'CF': {'currency': 'XAF', 'methods': ['card', 'mobile_money']},  # Central African CFA
        'TD': {'currency': 'XAF', 'methods': ['card', 'mobile_money']},  # Central African CFA
        'GQ': {'currency': 'XAF', 'methods': ['card', 'mobile_money']},  # Central African CFA
        # Other African
        'EG': {'currency': 'EGP', 'methods': ['card', 'bank_transfer', 'fawry']},  # Egyptian Pound
        'MA': {'currency': 'MAD', 'methods': ['card', 'bank_transfer']},  # Moroccan Dirham
        'DZ': {'currency': 'DZD', 'methods': ['card', 'bank_transfer']},  # Algerian Dinar
        'TN': {'currency': 'TND', 'methods': ['card', 'bank_transfer']},  # Tunisian Dinar
        'LY': {'currency': 'LYD', 'methods': ['card', 'bank_transfer']},  # Libyan Dinar
        'SD': {'currency': 'SDG', 'methods': ['card', 'bank_transfer']},  # Sudanese Pound
        'SS': {'currency': 'SSP', 'methods': ['card', 'mobile_money']},  # South Sudanese Pound
        'ET': {'currency': 'ETB', 'methods': ['card', 'bank_transfer']},  # Ethiopian Birr
        'SO': {'currency': 'SOS', 'methods': ['card', 'mobile_money']},  # Somali Shilling
        'DJ': {'currency': 'DJF', 'methods': ['card', 'bank_transfer']},  # Djiboutian Franc
        'ER': {'currency': 'ERN', 'methods': ['card', 'bank_transfer']},  # Eritrean Nakfa
        'MW': {'currency': 'MWK', 'methods': ['card', 'mobile_money', 'airtel_money']},  # Malawian Kwacha
    }
    
    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.base_url = self.SANDBOX_URL if self._is_sandbox() else self.PRODUCTION_URL
        self.headers = self._get_headers()
    
    def _is_sandbox(self) -> bool:
        """Check if sandbox mode"""
        if self.config and hasattr(self.config, 'is_sandbox'):
            return self.config.is_sandbox
        return getattr(settings, 'FLUTTERWAVE_SANDBOX', True)
    
    def _get_headers(self) -> Dict[str, str]:
        """Get API headers with OAuth 2.0 token or secret key"""
        # Flutterwave v3 API uses secret key directly
        # OAuth 2.0 is for v4 API
        secret_key = self._get_secret_key()
        
        # Check if we have a valid secret key
        if secret_key and secret_key.startswith('FLWSECK_'):
            return {
                'Authorization': f'Bearer {secret_key}',
                'Content-Type': 'application/json',
            }
        
        # Fallback to OAuth 2.0 for v4 API
        try:
            return flutterwave_oauth.get_headers()
        except Exception as e:
            logger.error(f"Flutterwave authentication failed: {e}")
            raise PaymentError("Flutterwave authentication failed. Please check your credentials.")
    
    def _get_secret_key(self) -> str:
        """Get secret key from config or settings"""
        if self.config and self.config.secret_key:
            return self.config.secret_key
        return getattr(settings, 'FLUTTERWAVE_SECRET_KEY', '')
    
    def _get_public_key(self) -> str:
        """Get public key from config or settings"""
        if self.config and self.config.api_key:
            return self.config.api_key
        return getattr(settings, 'FLUTTERWAVE_PUBLIC_KEY', '')
    
    def get_config(self) -> Dict[str, Any]:
        return {
            'public_key': self._get_public_key(),
            'secret_key': self._get_secret_key(),
            'sandbox': self._is_sandbox(),
            'webhook_secret': getattr(settings, 'FLUTTERWAVE_WEBHOOK_SECRET', ''),
        }
    
    def initiate_payment(self, transaction, **kwargs) -> Dict[str, Any]:
        """
        Initiate Flutterwave payment
        Docs: https://developer.flutterwave.com/docs/payments/accept-payments
        """
        # Get customer details from user or metadata - check MULTIPLE locations
        user = transaction.user
        email = (
            getattr(user, 'email', None) or
            kwargs.get('email') or
            transaction.metadata.get('email') or
            transaction.metadata.get('learner_email') or
            transaction.individual_email or
            transaction.company_email or
            (transaction.metadata.get('individual_details', {}) or {}).get('email') or
            (transaction.metadata.get('corporate_details', {}) or {}).get('contact_email')
        )

        if not email:
            raise PaymentError("Email is required for payment initiation")
            
        full_name = ""
        if user:
            full_name = user.get_full_name() or user.username
        else:
            full_name = kwargs.get('name') or transaction.metadata.get('name') or transaction.metadata.get('learner_full_name') or email.split('@')[0]

        country_config = self.COUNTRY_CONFIGS.get(transaction.country, {})
        
        payload = {
            'tx_ref': transaction.provider_reference,
            'amount': str(transaction.amount),
            'currency': country_config.get('currency', Currency.USD),
            'redirect_url': kwargs.get('callback_url', ''),
            'payment_options': self._get_payment_options(transaction.country),
            'customer': {
                'email': email,
                'name': full_name,
                'phone_number': kwargs.get('phone_number', '') or transaction.phone_number or transaction.metadata.get('phone') or '',
            },
            'customizations': {
                'title': 'Hosi Academy',
                'description': (transaction.description[:250] if transaction.description else f"Payment Ref: {transaction.provider_reference}"),
                'logo': f"{settings.SITE_URL}/static/logo.png",
            },
            'meta': {
                'user_id': str(user.id) if user else 'guest',
                'transaction_id': str(transaction.id),
                'country': transaction.country,
                'is_guest': user is None
            }
        }
        
        # Add phone number for mobile money
        if kwargs.get('phone_number'):
            payload['customer']['phone_number'] = kwargs['phone_number']
        
        # Add bank transfer details for Nigeria
        if transaction.country == 'NG' and kwargs.get('bank_code'):
            payload['bank_transfer_options'] = {
                'bank_code': kwargs['bank_code'],
                'account_number': kwargs.get('account_number', ''),
            }
        
        try:
            response = requests.post(
                f"{self.base_url}/payments",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            
            if data['status'] == 'success':
                self.log_transaction(transaction, 'initiate_payment', {'status': 'success'})
                return {
                    'checkout_url': data['data']['link'],
                    'payment_reference': data['data']['tx_ref'],
                    'provider_data': data,
                    'requires_redirect': True,
                }
            else:
                error_msg = data.get('message', 'Unknown error')
                self.log_transaction(transaction, 'initiate_payment', {'status': 'error', 'error': error_msg})
                raise PaymentError(f"Flutterwave error: {error_msg}")
                
        except requests.exceptions.RequestException as e:
            error = self.handle_error(e, 'initiate_payment')
            raise PaymentError(f"Flutterwave connection error: {str(e)}")
    
    def _get_payment_options(self, country: str) -> str:
        """Get payment options for country"""
        country_config = self.COUNTRY_CONFIGS.get(country, {})
        methods = country_config.get('methods', ['card'])
        
        # Map to Flutterwave payment options
        option_map = {
            'card': 'card',
            'mobile_money': 'mobilemoney',
            'bank_transfer': 'banktransfer',
            'ussd': 'ussd',
            'mpesa': 'mpesa',
            'gh_mobile': 'mobilemoneygh',
            'ug_mobile': 'mobilemoneyug',
            'rw_mobile': 'mobilemoneyrw',
            'zm_mobile': 'mobilemoneyzm',
        }
        
        return ','.join([option_map.get(m, m) for m in methods])
    
    def verify_payment(self, reference: str) -> Dict[str, Any]:
        """Verify payment status"""
        try:
            response = requests.get(
                f"{self.base_url}/transactions/{reference}/verify",
                headers=self.headers,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            
            return {
                'status': data['data']['status'],
                'amount': data['data']['amount'],
                'currency': data['data']['currency'],
                'reference': data['data']['tx_ref'],
                'provider_data': data,
            }
            
        except requests.exceptions.RequestException as e:
            error = self.handle_error(e, 'verify_payment')
            raise PaymentError(f"Failed to verify payment: {str(e)}")
    
    def refund_payment(self, transaction, amount=None, reason="") -> Dict[str, Any]:
        """Process refund"""
        refund_amount = amount or transaction.amount
        
        payload = {
            'amount': refund_amount,
            'comment': reason or f"Refund for transaction {transaction.provider_reference}",
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/transactions/{transaction.provider_reference}/refund",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            
            return {
                'refund_id': data['data']['id'],
                'amount': data['data']['amount'],
                'status': data['data']['status'],
                'provider_data': data,
            }
            
        except requests.exceptions.RequestException as e:
            error = self.handle_error(e, 'refund_payment')
            raise PaymentError(f"Refund failed: {str(e)}")
    
    def verify_webhook_signature(self, payload: bytes, headers: Dict[str, str]) -> bool:
        """Verify Flutterwave webhook signature"""
        webhook_secret = getattr(settings, 'FLUTTERWAVE_WEBHOOK_SECRET', '')
        if not webhook_secret:
            return True  # Skip if no secret configured
        
        signature = headers.get('verif-hash', '')
        if not signature:
            return False
        
        expected_signature = hmac.new(
            webhook_secret.encode('utf-8'),
            msg=payload,
            digestmod=hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(expected_signature, signature)
    
    def parse_webhook(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Parse Flutterwave webhook"""
        event = payload.get('event', '')
        data = payload.get('data', {})
        
        return {
            'event': event,
            'reference': data.get('tx_ref'),
            'status': data.get('status'),
            'amount': data.get('amount'),
            'currency': data.get('currency'),
            'provider_data': payload,
            'timestamp': timezone.now().isoformat(),
        }
    
    def get_checkout_url(self, transaction) -> str:
        """Get checkout URL (Flutterwave returns this in initiate_payment)"""
        # For Flutterwave, we need to initiate payment first
        result = self.initiate_payment(transaction)
        return result['checkout_url']
    
    def get_supported_countries(self) -> list:
        return list(self.COUNTRY_CONFIGS.keys())
    
    def get_supported_currencies(self) -> list:
        currencies = set()
        for config in self.COUNTRY_CONFIGS.values():
            currencies.add(config.get('currency', Currency.USD))
        return list(currencies)
    
    def get_supported_methods(self) -> list:
        """
        Flutterwave supports ALL major payment methods:
        - Card (Visa, Mastercard, Amex)
        - Mobile Money (M-Pesa, MTN, Airtel, Orange, etc.)
        - Bank Transfer / EFT
        - USSD (Nigeria, Ghana)
        QR code is NOT supported/removed.
        """
        # Return explicit list without QR code
        return ['card', 'mobile_money', 'bank_transfer', 'eft', 'ussd', 'mtn_momo', 'airtel_money', 'orange_money', 'mpesa']