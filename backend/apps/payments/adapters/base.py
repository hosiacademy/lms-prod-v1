# apps/payments/adapters/base.py
import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Tuple, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class PaymentError(Exception):
    """Base payment error"""
    pass


class SignatureVerificationError(PaymentError):
    """Raised when webhook signature verification fails"""
    pass


class AdapterConfigurationError(PaymentError):
    """Raised when adapter configuration is invalid"""
    pass


class BasePaymentAdapter(ABC):
    """
    Abstract base class for all payment adapters
    """
    
    def __init__(self, config=None):
        self.config = config or {}
        self.logger = logging.getLogger(self.__class__.__name__)
    
    @abstractmethod
    def get_supported_countries(self) -> List[str]:
        """Get list of supported country codes (ISO 3166-1 alpha-2)"""
        pass
    
    @abstractmethod
    def get_supported_currencies(self) -> List[str]:
        """Get list of supported currency codes (ISO 4217)"""
        pass
    
    @abstractmethod
    def get_supported_methods(self) -> List[str]:
        """Get list of supported payment methods"""
        pass
    
    def validate_amount(self, amount, currency) -> Tuple[bool, str]:
        """Validate amount for given currency"""
        try:
            amount = float(amount)
            if amount <= 0:
                return False, "Amount must be positive"
            
            # Currency-specific validations
            currency_validations = {
                'NGN': lambda x: x >= 50,  # Nigerian Naira minimum
                'KES': lambda x: x >= 10,  # Kenyan Shilling minimum
                'GHS': lambda x: x >= 0.1,  # Ghanaian Cedi minimum
                'ZAR': lambda x: x >= 5,    # South African Rand minimum
                'USD': lambda x: x >= 1,    # US Dollar minimum
                'XOF': lambda x: x >= 50,   # West African CFA franc
                'XAF': lambda x: x >= 50,   # Central African CFA franc
            }
            
            if currency in currency_validations and not currency_validations[currency](amount):
                return False, f"Minimum amount for {currency} is {self._get_min_amount(currency)}"
            
            return True, "Valid"
            
        except (ValueError, TypeError):
            return False, "Invalid amount"
    
    def _get_min_amount(self, currency: str) -> str:
        """Get minimum amount for currency"""
        min_amounts = {
            'NGN': '50 NGN',
            'KES': '10 KES',
            'GHS': '0.1 GHS',
            'ZAR': '5 ZAR',
            'USD': '1 USD',
            'XOF': '50 XOF',
            'XAF': '50 XAF',
            'ZWL': '10 ZWL',
            'ZMW': '1 ZMW',
        }
        return min_amounts.get(currency, '0.01')
    
    @abstractmethod
    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Initiate payment with provider
        
        Args:
            transaction: PaymentTransaction object
            callback_url: Webhook callback URL
            **kwargs: Additional parameters (phone_number, payment_method, etc.)
        
        Returns:
            Dict containing:
                - status: str (pending, requires_action, failed)
                - checkout_url: Optional[str] (if requires redirect)
                - provider_reference: str (provider's transaction ID)
                - requires_redirect: bool
                - requires_mobile_approval: bool
                - instructions: Optional[str]
                - qr_code_data: Optional[str]
                - provider_data: Dict (raw provider response)
        """
        pass
    
    def verify_payment(self, reference: str) -> Dict[str, Any]:
        """
        Verify payment status with provider
        
        Returns:
            Dict containing:
                - status: str (pending, successful, failed, cancelled)
                - amount: Optional[float]
                - currency: Optional[str]
                - reference: str (provider reference)
                - confirmed_at: Optional[str] (ISO datetime)
                - provider_data: Dict (raw provider response)
        """
        raise NotImplementedError
    
    def refund_payment(self, transaction, amount: Optional[float] = None, reason: str = "") -> Dict[str, Any]:
        """
        Process refund with provider
        
        Returns:
            Dict containing:
                - status: str (pending, successful, failed, requires_manual)
                - refund_reference: Optional[str]
                - message: Optional[str]
                - provider_data: Dict (raw provider response)
        """
        raise NotImplementedError
    
    def verify_webhook_signature(self, payload: bytes, headers: Dict[str, str]) -> bool:
        """
        Verify webhook signature

        Args:
            payload: Raw request body
            headers: Request headers

        Returns:
            bool: True if signature is valid
        """
        raise NotImplementedError

    def handle_error(self, exception, operation: str = "payment_operation") -> Dict[str, Any]:
        """
        Handle payment exceptions and return structured error
        
        Args:
            exception: The exception that was raised
            operation: The operation being performed when error occurred
            
        Returns:
            Dict containing error details
        """
        error_type = type(exception).__name__
        error_message = str(exception)
        
        # Log the error
        self.logger.error(f"Payment error during {operation}: {error_message}", exc_info=True)
        
        return {
            'success': False,
            'error': error_message,
            'error_type': error_type,
            'operation': operation,
        }
    
    def _generate_reference(self, prefix: str = "PAY") -> str:
        """Generate unique payment reference"""
        import uuid
        return f"{prefix}-{uuid.uuid4().hex[:8].upper()}"
    
    def parse_webhook(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse webhook payload into standardized format
        
        Returns:
            Dict containing:
                - event: str (payment.success, payment.failed, etc.)
                - reference: str (provider transaction reference)
                - status: str (successful, failed, pending, cancelled)
                - amount: float
                - currency: str
                - method: Optional[str] (payment method used)
                - timestamp: str (ISO datetime)
                - provider_data: Dict (original payload)
        """
        return {
            'event': payload.get('event', 'payment.update'),
            'reference': payload.get('reference') or payload.get('id') or payload.get('transaction_reference'),
            'status': self._map_status(payload.get('status', '')),
            'amount': float(payload.get('amount', 0)),
            'currency': payload.get('currency', ''),
            'method': payload.get('method') or payload.get('payment_method'),
            'timestamp': payload.get('timestamp') or datetime.utcnow().isoformat(),
            'provider_data': payload,
        }
    
    def _map_status(self, provider_status: str) -> str:
        """Map provider-specific status to standardized status"""
        status_mapping = {
            # Common success statuses
            'success': 'successful',
            'successful': 'successful',
            'completed': 'successful',
            'paid': 'successful',
            'confirmed': 'successful',
            'settled': 'successful',
            
            # Pending statuses
            'pending': 'pending',
            'processing': 'pending',
            'initiated': 'pending',
            'awaiting': 'pending',
            'in_progress': 'pending',
            
            # Failed statuses
            'failed': 'failed',
            'error': 'failed',
            'rejected': 'failed',
            'declined': 'failed',
            'expired': 'failed',
            
            # Cancelled statuses
            'cancelled': 'cancelled',
            'canceled': 'cancelled',
            'voided': 'cancelled',
            
            # Refund statuses
            'refunded': 'refunded',
            'reversed': 'refunded',
        }
        
        provider_status_lower = str(provider_status).lower()
        return status_mapping.get(provider_status_lower, 'pending')
    
    def get_provider_name(self) -> str:
        """Get provider display name"""
        # Default: Use class name without 'Adapter'
        class_name = self.__class__.__name__
        if class_name.endswith('Adapter'):
            return class_name[:-7]
        return class_name
    
    def get_provider_code(self) -> str:
        """Get provider code (lowercase, snake_case)"""
        name = self.get_provider_name()
        # Convert to snake_case
        import re
        name = re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()
        return name
    
    def validate_country_currency(self, country: str, currency: str) -> Tuple[bool, str]:
        """
        Validate if currency is supported for country
        
        Returns: (is_valid, error_message)
        """
        if country not in self.get_supported_countries():
            return False, f"Country {country} not supported by {self.get_provider_name()}"
        
        if currency not in self.get_supported_currencies():
            return False, f"Currency {currency} not supported by {self.get_provider_name()}"
        
        # Country-currency specific validations
        country_currency_map = {
            'NG': ['NGN', 'USD'],
            'KE': ['KES', 'USD'],
            'GH': ['GHS', 'USD'],
            'ZA': ['ZAR', 'USD'],
            'ZW': ['USD', 'ZWL'],
            'ZM': ['ZMW', 'USD'],
            'CI': ['XOF', 'USD'],
            'SN': ['XOF', 'USD'],
            'CM': ['XAF', 'USD'],
        }
        
        if country in country_currency_map and currency not in country_currency_map[country]:
            return False, f"Currency {currency} not typically used in {country}"
        
        return True, "Valid"