# apps/payments/adapters/paynow.py
import requests
import json
import hashlib
import hmac
from typing import Dict, Any, Optional
from urllib.parse import urlencode
from django.conf import settings
from django.utils import timezone
from .base import BasePaymentAdapter, PaymentError, SignatureVerificationError


class PaynowAdapter(BasePaymentAdapter):
    """
    Paynow Zimbabwe payment gateway adapter.
    Supports: EcoCash, OneMoney, Telecash, Visa, Mastercard, ZimSwitch
    
    API Documentation: https://paynow.co.zw/merchant/api-documentation
    """
    
    # Paynow API Endpoints
    SANDBOX_BASE_URL = "https://test.paynow.co.zw"
    PRODUCTION_BASE_URL = "https://www.paynow.co.zw"
    
    # API Paths
    INITIATE_TRANSACTION_PATH = "/interface/initiatetransaction"
    POLL_TRANSACTION_PATH = "/interface/checkpaymentstatus"
    
    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        self.base_url = self.SANDBOX_BASE_URL if self._is_sandbox() else self.PRODUCTION_BASE_URL
        self.integration_id = self._get_integration_id()
        self.integration_key = self._get_integration_key()
    
    def _is_sandbox(self) -> bool:
        """Check if sandbox mode is enabled."""
        if self.config and hasattr(self.config, 'is_sandbox'):
            return self.config.is_sandbox
        return getattr(settings, 'PAYNOW_SANDBOX', True)
    
    def _get_integration_id(self) -> str:
        """Get Paynow integration ID."""
        if self.config:
            # Handle both dict and object config
            if isinstance(self.config, dict):
                return self.config.get('api_id', '')
            elif hasattr(self.config, 'api_id'):
                return self.config.api_id
        return getattr(settings, 'PAYNOW_INTEGRATION_ID', '')

    def _get_integration_key(self) -> str:
        """Get Paynow integration key."""
        if self.config:
            # Handle both dict and object config
            if isinstance(self.config, dict):
                return self.config.get('api_key', '')
            elif hasattr(self.config, 'api_key'):
                return self.config.api_key
        return getattr(settings, 'PAYNOW_INTEGRATION_KEY', '')
    
    def _generate_hash(self, values: Dict[str, Any]) -> str:
        """
        Generate Paynow hash for security.
        Paynow uses SHA512 hash of concatenated values.
        """
        hash_string = ""
        
        # Paynow expects values in specific order for hash generation
        # Typically: amount + reference + additional data + integration_key
        hash_string += str(values.get('amount', ''))
        hash_string += str(values.get('reference', ''))
        hash_string += str(values.get('additionalinfo', ''))
        hash_string += str(values.get('returnurl', ''))
        hash_string += str(values.get('resulturl', ''))
        hash_string += str(self.integration_key)
        
        # Generate SHA512 hash
        hash_value = hashlib.sha512(hash_string.encode('utf-8')).hexdigest().upper()
        return hash_value
    
    def get_supported_countries(self) -> list:
        """Get list of supported country codes."""
        return ['ZW']  # Zimbabwe
    
    def get_supported_currencies(self) -> list:
        """Get list of supported currency codes."""
        # Paynow supports USD and ZWL for Zimbabwe
        return ['USD', 'ZWL']
    
    def get_supported_methods(self) -> list:
        """Get list of supported payment methods."""
        return [
            'ecocash',      # EcoCash mobile money
            'onemoney',     # OneMoney mobile money
            'telecash',     # Telecash mobile money
            'visa',         # Visa cards
            'mastercard',   # Mastercard
            'zimswitch',    # ZimSwitch local cards
            'banktransfer', # Bank transfer
        ]
    
    def initiate_payment(self, transaction, callback_url, **kwargs) -> Dict[str, Any]:
        """
        Initiate a Paynow payment transaction.

        Paynow Flow:
        1. Create payment with amount, reference, etc.
        2. Get poll URL and payment instructions
        3. Redirect user to payment instructions
        4. Poll for status using poll URL
        """
        # Get email from multiple sources
        auth_email = (
            getattr(transaction.user, 'email', None) if transaction.user else None or
            transaction.metadata.get('email') or
            transaction.individual_email or
            transaction.company_email or
            (transaction.metadata.get('individual_details') or {}).get('email') or
            (transaction.metadata.get('corporate_details') or {}).get('contact_email') or
            'customer@example.com'  # Fallback
        )
        
        # Prepare payment data
        payment_data = {
            'id': self.integration_id,
            'reference': transaction.provider_reference,
            'amount': float(transaction.amount),
            'additionalinfo': transaction.description[:255] if transaction.description else 'Hosi Academy Payment',
            'returnurl': kwargs.get('return_url', getattr(settings, 'PAYNOW_RETURN_URL', callback_url)),
            'resulturl': callback_url,
            'authemail': auth_email,
            'status': 'Message',  # Paynow status field
        }
        
        # Add customer information
        if transaction.user and (transaction.user.first_name or transaction.user.last_name):
            payment_data['additionalinfo'] += f" | {transaction.user.get_full_name()}"
        
        # Add phone number for mobile money if provided
        if kwargs.get('phone_number'):
            payment_data['phone'] = kwargs.get('phone_number')
        
        # Specify payment method if provided
        payment_method = kwargs.get('payment_method', '')
        if payment_method:
            payment_data['method'] = payment_method
        
        # Generate security hash
        payment_data['hash'] = self._generate_hash(payment_data)
        
        try:
            # Send POST request to Paynow
            response = requests.post(
                f"{self.base_url}{self.INITIATE_TRANSACTION_PATH}",
                data=payment_data,
                timeout=30
            )
            
            self.logger.info(f"Paynow initiate request: {response.status_code}")
            
            if response.status_code != 200:
                raise PaymentError(f"Paynow API error: HTTP {response.status_code}")
            
            # Parse Paynow response (key=value format)
            response_data = {}
            for line in response.text.split('&'):
                if '=' in line:
                    key, value = line.split('=', 1)
                    response_data[key] = value
            
            # Check if request was successful
            if response_data.get('status', '').upper() != 'OK':
                error_msg = response_data.get('error', 'Payment initiation failed')
                raise PaymentError(f"Paynow error: {error_msg}")
            
            # Extract important data from response
            poll_url = response_data.get('pollurl', '')
            browser_url = response_data.get('browserurl', '')
            paynow_reference = response_data.get('paynowreference', '')
            
            result = {
                'status': 'pending',
                'provider_reference': paynow_reference,
                'provider_data': response_data,
                'requires_redirect': bool(browser_url),
            }
            
            if browser_url:
                result['checkout_url'] = browser_url
                result['instructions'] = 'Redirect to Paynow payment page'
            else:
                result['poll_url'] = poll_url
                result['requires_customer_approval'] = True
                result['instructions'] = response_data.get('instructions', 
                    'Please approve payment on your mobile device')
            
            # For mobile money, add specific instructions
            if payment_method in ['ecocash', 'onemoney', 'telecash']:
                result['mobile_instructions'] = (
                    f"Check your {payment_method.title()} phone for a payment prompt"
                )
            
            return result
            
        except requests.exceptions.Timeout:
            raise PaymentError("Paynow API timeout. Please try again.")
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Network error connecting to Paynow: {str(e)}")
    
    def verify_payment(self, reference: str) -> Dict[str, Any]:
        """
        Poll Paynow for payment status.
        
        Note: Paynow uses a poll URL returned during initiation,
        but we can also poll using the transaction reference.
        """
        poll_data = {
            'id': self.integration_id,
            'reference': reference,
        }
        
        # Generate hash for polling
        poll_data['hash'] = self._generate_hash(poll_data)
        
        try:
            response = requests.post(
                f"{self.base_url}{self.POLL_TRANSACTION_PATH}",
                data=poll_data,
                timeout=30
            )
            
            if response.status_code != 200:
                raise PaymentError(f"Paynow poll error: HTTP {response.status_code}")
            
            # Parse response
            response_data = {}
            for line in response.text.split('&'):
                if '=' in line:
                    key, value = line.split('=', 1)
                    response_data[key] = value
            
            # Map Paynow status to internal status
            paynow_status = response_data.get('status', '').upper()
            status_map = {
                'PAID': 'successful',
                'AWAITING DELIVERY': 'pending',
                'CANCELLED': 'cancelled',
                'DELIVERED': 'successful',
                'DISPUTED': 'disputed',
                'REFUNDED': 'refunded',
            }
            
            mapped_status = status_map.get(paynow_status, 'pending')
            
            return {
                'status': mapped_status,
                'original_status': paynow_status,
                'amount': response_data.get('amount'),
                'reference': response_data.get('reference'),
                'paynow_reference': response_data.get('paynowreference'),
                'provider_data': response_data,
                'polled_at': timezone.now().isoformat(),
            }
            
        except requests.exceptions.RequestException as e:
            raise PaymentError(f"Failed to poll Paynow payment: {str(e)}")
    
    def verify_webhook_signature(self, payload: bytes, headers: Dict[str, str]) -> bool:
        """
        Verify Paynow webhook signature.
        Paynow sends the hash in the payload which we need to verify.
        """
        try:
            # Parse the payload (key=value format)
            payload_str = payload.decode('utf-8')
            payload_data = {}
            for line in payload_str.split('&'):
                if '=' in line:
                    key, value = line.split('=', 1)
                    payload_data[key] = value
            
            # Extract hash from payload
            received_hash = payload_data.get('hash', '')
            if not received_hash:
                return False
            
            # Recreate the hash to verify
            hash_string = ""
            
            # Paynow's hash verification logic
            # We need to concatenate values in the correct order
            expected_fields = ['reference', 'paynowreference', 'amount', 'status']
            
            for field in expected_fields:
                if field in payload_data:
                    hash_string += payload_data[field]
            
            hash_string += self.integration_key
            
            expected_hash = hashlib.sha512(hash_string.encode('utf-8')).hexdigest().upper()
            
            return received_hash.upper() == expected_hash
            
        except Exception as e:
            self.logger.error(f"Paynow webhook verification failed: {e}")
            return False
    
    def parse_webhook(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Parse Paynow webhook payload."""
        # Paynow sends data as key=value pairs, already parsed by Django
        return {
            'event': 'payment.update',
            'reference': payload.get('reference'),
            'paynow_reference': payload.get('paynowreference'),
            'status': payload.get('status'),
            'amount': payload.get('amount'),
            'method': payload.get('method'),
            'provider_data': payload,
            'received_at': timezone.now().isoformat(),
        }
    
    def refund_payment(self, transaction, amount=None, reason="") -> Dict[str, Any]:
        """
        Process refund through Paynow.
        Note: Check Paynow documentation for refund API endpoint.
        """
        # Paynow refund might require contacting support or using merchant portal
        # This is a placeholder implementation
        
        self.logger.warning("Paynow refund may require manual processing through merchant portal")
        
        return {
            'status': 'requires_manual',
            'message': 'Refunds may require manual processing via Paynow merchant portal',
            'instructions': 'Contact Paynow support or use merchant portal for refunds',
            'transaction_reference': transaction.provider_reference,
        }