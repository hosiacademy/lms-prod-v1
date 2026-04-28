# apps/payments/adapters/mock.py
import logging
import uuid
from typing import Dict, Any, List
from django.utils import timezone
from .base import BasePaymentAdapter, PaymentError

class MockAdapter(BasePaymentAdapter):
    """
    Mock payment adapter for sandbox testing without external APIs
    """
    
    PROVIDER_NAME = "Mock Payment"
    PROVIDER_CODE = "mock"
    
    def get_supported_countries(self) -> List[str]:
        return ['NG', 'KE', 'GH', 'ZA', 'UG', 'TZ', 'RW', 'ZM', 'CM', 'SN', 'CI', 'US', 'GB']
        
    def get_supported_currencies(self) -> List[str]:
        return ['NGN', 'KES', 'GHS', 'ZAR', 'USD', 'EUR', 'GBP', 'XAF', 'XOF']
        
    def get_supported_methods(self) -> List[str]:
        return ['card', 'mobile_money', 'bank_transfer', 'ussd']
        
    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Simulate payment initiation
        """
        self.logger.info(f"Mock payment initiated: {transaction.provider_reference}")
        
        # Return a mock checkout URL that points to our own simulation endpoint or just a success page
        return {
            'status': 'pending',
            'checkout_url': f"/payment/mock-simulate/{transaction.id}/",
            'provider_reference': f"MOCK_{uuid.uuid4().hex[:12].upper()}",
            'requires_redirect': True,
            'provider_data': {'mock': True}
        }
        
    def verify_payment(self, reference: str) -> Dict[str, Any]:
        """
        Always return successful if reference starts with MOCK_
        """
        return {
            'status': 'successful',
            'amount': 100.0,
            'currency': 'USD',
            'reference': reference,
            'confirmed_at': timezone.now().isoformat(),
            'provider_data': {'mock': True}
        }
        
    def refund_payment(self, transaction, amount=None, reason="") -> Dict[str, Any]:
        return {
            'status': 'successful',
            'refund_id': f"MOCK_REF_{uuid.uuid4().hex[:8].upper()}",
            'amount': amount or transaction.amount,
            'message': 'Mock refund successful'
        }
