# apps/payments/adapters/pesepay.py
import requests
import json
import hmac
import hashlib
from typing import Dict, Any, Optional
from django.conf import settings
from django.utils import timezone
from .base import BasePaymentAdapter, PaymentError, SignatureVerificationError


class PesepayAdapter(BasePaymentAdapter):
    """
    Adapter for Pesepay payment gateway (handles EcoCash, cards, etc. in Zimbabwe).
    Uses endpoints from Pesepay API documentation.
    """
    
    # Base URLs from Pesepay SDK constants
    SANDBOX_BASE_URL = 'https://api.sandbox.pesepay.com/api/payments-engine'
    PRODUCTION_BASE_URL = 'https://api.pesepay.com/api/payments-engine'
    
    # Endpoint paths from Pesepay SDK constants
    INITIATE_PAYMENT_PATH = '/v1/payments/initiate'
    SEAMLESS_PAYMENT_PATH = '/v2/payments/make-payment'
    CHECK_PAYMENT_STATUS_PATH = '/v1/payments/check-payment'
    
    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.base_url = self.SANDBOX_BASE_URL if self._is_sandbox() else self.PRODUCTION_BASE_URL
        self.integration_key = self._get_integration_key()
        self.encryption_key = self._get_encryption_key()
        self.headers = {
            'Authorization': f'Bearer {self.integration_key}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }
    
    def _is_sandbox(self) -> bool:
        """Check if sandbox mode is enabled."""
        if self.config and hasattr(self.config, 'is_sandbox'):
            return self.config.is_sandbox
        return getattr(settings, 'PESEPAY_SANDBOX', True)  # Default to sandbox for safety
    
    def _get_integration_key(self) -> str:
        """Get integration key from config or settings."""
        if self.config and self.config.api_key:
            return self.config.api_key
        return getattr(settings, 'PESEPAY_INTEGRATION_KEY', '')
    
    def _get_encryption_key(self) -> str:
        """Get encryption key for webhook/signature verification."""
        if self.config and self.config.secret_key:
            return self.config.secret_key
        return getattr(settings, 'PESEPAY_ENCRYPTION_KEY', '')
    
    def get_supported_countries(self) -> list:
        """Get list of supported country codes."""
        return ['ZW']  # Zimbabwe
    
    def get_supported_currencies(self) -> list:
        """Get list of supported currency codes."""
        # Pesepay supports USD and ZWL for Zimbabwe
        return ['USD', 'ZWL']
    
    def get_supported_methods(self) -> list:
        """Get list of supported payment methods."""
        # Based on typical Pesepay offerings for Zimbabwe
        return [
            'ecocash',      # EcoCash mobile money
            'onemoney',     # OneMoney mobile money
            'telecash',     # Telecash mobile money
            'visa',         # Visa cards
            'mastercard',   # Mastercard
            'zimswitch',    # ZimSwitch local cards
        ]
    
    def get_config(self) -> Dict[str, Any]:
        """Get adapter configuration."""
        return {
            'integration_key': self.integration_key,
            'encryption_key': self.encryption_key[:8] + '...' if self.encryption_key else None,
            'sandbox': self._is_sandbox(),
            'base_url': self.base_url,
        }
    
    def initiate_payment(self, transaction, callback_url, **kwargs) -> Dict[str, Any]:
        """
        Initiate a payment using Pesepay's initiate endpoint.
        This likely creates a payment record and returns a checkout URL.
        
        Endpoint: POST /v1/payments/initiate
        """
        # Prepare payload based on typical payment gateway requirements
        payload = {
            'amount': float(transaction.amount),
            'currency_code': transaction.currency,  # 'USD' or 'ZWL'
            'reference_number': transaction.provider_reference,
            'result_url': callback_url,  # Where Pesepay posts final result
            'return_url': kwargs.get('return_url', callback_url),  # Where user is redirected
            'merchant_reference': f"HOSI-{transaction.id}-{int(timezone.now().timestamp())}",
            'payment_method': kwargs.get('payment_method', 'ecocash'),  # Default to EcoCash
            'customer': {
                'email': transaction.user.email,
                'first_name': transaction.user.first_name or '',
                'last_name': transaction.user.last_name or '',
                'mobile': kwargs.get('phone_number', ''),  # Essential for mobile money
            },
            'metadata': {
                'user_id': str(transaction.user.id),
                'transaction_id': str(transaction.id),
                'description': transaction.description[:100] if transaction.description else '',
                'platform': 'Hosi Academy LMS',
            }
        }
        
        # Add specific fields for mobile money if needed
        if payload['payment_method'] in ['ecocash', 'onemoney', 'telecash']:
            payload['customer']['mobile'] = kwargs.get('phone_number', '')
            if not payload['customer']['mobile']:
                raise PaymentError(f"Phone number required for {payload['payment_method']}")
        
        try:
            response = requests.post(
                f"{self.base_url}{self.INITIATE_PAYMENT_PATH}",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            
            # Log the request for debugging
            self.logger.info(f"Pesepay initiate payment request: {response.status_code}")
            
            if response.status_code >= 400:
                self.logger.error(f"Pesepay error: {response.text}")
            
            response.raise_for_status()
            data = response.json()
            
            # Handle response based on typical payment gateway patterns
            if data.get('success') or data.get('status') in ['SUCCESS', 'PENDING']:
                # Some gateways return a redirect URL for checkout
                checkout_url = data.get('redirect_url') or data.get('checkout_url') or data.get('approval_url')
                
                result = {
                    'status': 'pending',
                    'provider_reference': data.get('transaction_id') or data.get('reference'),
                    'provider_data': data,
                    'requires_redirect': bool(checkout_url),
                }
                
                if checkout_url:
                    result['checkout_url'] = checkout_url
                else:
                    # If no checkout URL, might be seamless/USSD flow
                    result['requires_customer_approval'] = True
                    result['instructions'] = data.get('instructions', 'Approve payment on your mobile device')
                
                return result
            else:
                error_msg = data.get('message') or data.get('error') or 'Payment initiation failed'
                raise PaymentError(f"Pesepay error: {error_msg}")
                
        except requests.exceptions.Timeout:
            raise PaymentError("Pesepay API timeout. Please try again.")
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Network error connecting to Pesepay: {str(e)}")
    
    def make_seamless_payment(self, transaction, callback_url, **kwargs) -> Dict[str, Any]:
        """
        Make a seamless payment using Pesepay's v2 endpoint.
        This might be for direct bank/mobile money transfers without redirect.
        
        Endpoint: POST /v2/payments/make-payment
        """
        payload = {
            'amount': float(transaction.amount),
            'currency_code': transaction.currency,
            'reference_number': transaction.provider_reference,
            'result_url': callback_url,
            'payment_method': kwargs.get('payment_method', 'ecocash'),
            'customer': {
                'email': transaction.user.email,
                'mobile': kwargs.get('phone_number', ''),
            },
            'seamless': True,
            'metadata': {
                'transaction_id': str(transaction.id),
                'user_id': str(transaction.user.id),
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}{self.SEAMLESS_PAYMENT_PATH}",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            
            if data.get('success') or data.get('status') in ['SUCCESS', 'PENDING']:
                return {
                    'status': 'pending',
                    'provider_reference': data.get('transaction_id'),
                    'provider_data': data,
                    'requires_customer_approval': True,  # User approves on mobile
                    'instructions': data.get('message', 'Please approve payment on your mobile device'),
                }
            else:
                error_msg = data.get('message', 'Seamless payment failed')
                raise PaymentError(f"Pesepay error: {error_msg}")
                
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Seamless payment error: {str(e)}")
    
    def check_payment_status(self, reference: str) -> Dict[str, Any]:
        """
        Check payment status using Pesepay's check-payment endpoint.
        
        Endpoint: GET /v1/payments/check-payment?reference={reference}
        """
        try:
            # Might need to pass reference as query parameter or in body
            params = {'reference_number': reference}
            
            response = requests.get(
                f"{self.base_url}{self.CHECK_PAYMENT_STATUS_PATH}",
                headers=self.headers,
                params=params,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            
            # Map Pesepay status to your internal status
            status_map = {
                'SUCCESS': 'successful',
                'FAILED': 'failed',
                'PENDING': 'pending',
                'CANCELLED': 'cancelled',
                'EXPIRED': 'expired',
            }
            
            pesepay_status = data.get('status', 'PENDING').upper()
            mapped_status = status_map.get(pesepay_status, 'pending')
            
            return {
                'status': mapped_status,
                'original_status': pesepay_status,
                'amount': data.get('amount'),
                'currency': data.get('currency_code'),
                'reference': data.get('reference_number') or reference,
                'payment_method': data.get('payment_method'),
                'provider_data': data,
                'checked_at': timezone.now().isoformat(),
            }
            
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Failed to check payment status: {str(e)}")
    
    def verify_payment(self, reference: str) -> Dict[str, Any]:
        """Alias for check_payment_status for base adapter compatibility."""
        return self.check_payment_status(reference)
    
    def refund_payment(self, transaction, amount=None, reason="") -> Dict[str, Any]:
        """
        Process refund - check Pesepay docs for refund endpoint.
        Many gateways use: POST /v1/payments/refund
        """
        # Note: You'll need to check Pesepay documentation for actual refund endpoint
        refund_amount = amount or transaction.amount
        
        payload = {
            'transaction_reference': transaction.provider_reference,
            'amount': float(refund_amount),
            'reason': reason or f"Refund for {transaction.provider_reference}",
            'currency_code': transaction.currency,
        }
        
        try:
            # This endpoint might be different - check Pesepay docs
            response = requests.post(
                f"{self.base_url}/v1/payments/refund",  # Placeholder endpoint
                headers=self.headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()
            
            if data.get('success'):
                return {
                    'refund_id': data.get('refund_id'),
                    'amount': data.get('amount_refunded'),
                    'status': data.get('status', 'processed'),
                    'provider_data': data,
                }
            else:
                error_msg = data.get('message', 'Refund failed')
                raise PaymentError(f"Refund error: {error_msg}")
                
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Refund request failed: {str(e)}")
    
    def verify_webhook_signature(self, payload: bytes, headers: Dict[str, str]) -> bool:
        """
        Verify Pesepay webhook signature.
        Many gateways use HMAC-SHA256 with encryption key.
        """
        if not self.encryption_key:
            self.logger.warning("No encryption key configured for webhook verification")
            return self._is_sandbox()  # Allow in sandbox, require in production
        
        signature = headers.get('X-Pesepay-Signature') or headers.get('X-Signature')
        if not signature:
            self.logger.error("No signature found in webhook headers")
            return False
        
        try:
            # Common pattern: HMAC-SHA256 of payload with encryption key
            expected_signature = hmac.new(
                self.encryption_key.encode('utf-8'),
                msg=payload,
                digestmod=hashlib.sha256
            ).hexdigest()
            
            return hmac.compare_digest(expected_signature, signature)
            
        except Exception as e:
            self.logger.error(f"Webhook signature verification failed: {e}")
            return False
    
    def parse_webhook(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Parse Pesepay webhook payload."""
        return {
            'event': payload.get('event_type') or payload.get('event'),
            'reference': payload.get('reference_number') or payload.get('transaction_reference'),
            'status': payload.get('status'),
            'amount': payload.get('amount'),
            'currency': payload.get('currency_code'),
            'payment_method': payload.get('payment_method'),
            'provider_data': payload,
            'received_at': timezone.now().isoformat(),
        }