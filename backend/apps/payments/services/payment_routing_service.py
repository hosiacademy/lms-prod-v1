# backend/apps/payments/services/payment_routing_service.py
"""
Payment Routing Service - Unified Payment Flow

This service routes all payments based on:
1. Country
2. Training type (Masterclass, Learnership, AI Certs, Custom Selection)
3. Payment method (Card, EFT, In-Store Cash)

POLICY:
- Card Payments: SmatPay ONLY (Zimbabwe focused)
- EFT Payments: Direct bank transfers (all countries)
- In-Store Cash: Office payment processing (all countries)
"""

import logging
from typing import Dict, List, Optional, Tuple
from enum import Enum
from django.conf import settings

logger = logging.getLogger(__name__)


class TrainingType(str, Enum):
    """4 Training Types in Hosi Academy LMS"""
    MASTERCLASS = 'masterclass'
    LEARNERSHIP = 'learnership'
    AI_CERTS = 'aicerts_courses'
    CUSTOM_SELECTION = 'custom_selection'


class PaymentMethod(str, Enum):
    """Payment Methods"""
    CARD = 'card'  # Credit/Debit cards (Visa, Mastercard, Zimswitch)
    EFT = 'eft'  # Electronic Funds Transfer / Bank Transfer
    CASH = 'cash'  # In-store office payment


class CardProvider(str, Enum):
    """Card Payment Providers"""
    SMATPAY = 'smatpay'  # Zimbabwe - EXCLUSIVE card gateway


class EFTProvider(str, Enum):
    """EFT/Bank Transfer Providers"""
    DIRECT_TRANSFER = 'bank_transfer'  # Direct bank account transfer
    PESEPAY = 'pesepay'  # Zimbabwe mobile/online banking
    PAYFAST = 'payfast'  # South Africa EFT/ACH


class CashProvider(str, Enum):
    """In-Store Cash Payment"""
    ON_SITE = 'on_site_payment'  # Office reception payment


# Country-specific configurations
COUNTRY_PAYMENT_CONFIG = {
    'ZW': {  # Zimbabwe
        'name': 'Zimbabwe',
        'currency': 'USD',
        'payment_methods': {
            PaymentMethod.CARD: {
                'provider': CardProvider.SMATPAY,
                'card_types': ['Visa', 'Mastercard', 'ZimSwitch'],
                'description': '💳 Visa, Mastercard, or ZimSwitch Card (SmatPay)',
                'enabled': True,
            },
            PaymentMethod.EFT: {
                'provider': EFTProvider.DIRECT_TRANSFER,
                'description': '🏦 Bank Transfer (via SmarTransfer or Direct Account)',
                'enabled': True,
            },
            PaymentMethod.CASH: {
                'provider': CashProvider.ON_SITE,
                'description': '💰 Pay Cash at Hosi Academy Office',
                'enabled': True,
                'locations': [
                    {'name': 'Harare HQ', 'address': '...', 'hours': '9AM-5PM MON-FRI'}
                ]
            },
        }
    },
    'ZA': {  # South Africa
        'name': 'South Africa',
        'currency': 'ZAR',
        'payment_methods': {
            PaymentMethod.CARD: {
                'provider': CardProvider.SMATPAY,
                'card_types': ['Visa', 'Mastercard'],
                'description': '💳 Visa or Mastercard (SmatPay)',
                'enabled': True,
            },
            PaymentMethod.EFT: {
                'provider': EFTProvider.PAYFAST,
                'description': '🏦 South African EFT / Bank Transfer',
                'enabled': True,
            },
            PaymentMethod.CASH: {
                'provider': CashProvider.ON_SITE,
                'description': '💰 Pay Cash at Office',
                'enabled': True,
                'locations': [
                    {'name': 'Johannesburg Office', 'address': '...', 'hours': '9AM-5PM MON-FRI'}
                ]
            },
        }
    },
    'KE': {  # Kenya
        'name': 'Kenya',
        'currency': 'KES',
        'payment_methods': {
            PaymentMethod.CARD: {
                'provider': CardProvider.SMATPAY,
                'card_types': ['Visa', 'Mastercard'],
                'description': '💳 Visa or Mastercard (SmatPay)',
                'enabled': True,
            },
            PaymentMethod.EFT: {
                'provider': EFTProvider.DIRECT_TRANSFER,
                'description': '🏦 Bank Transfer / M-Pesa Business',
                'enabled': True,
            },
            PaymentMethod.CASH: {
                'provider': CashProvider.ON_SITE,
                'description': '💰 Pay Cash at Office',
                'enabled': True,
                'locations': [
                    {'name': 'Nairobi Office', 'address': '...', 'hours': '9AM-5PM MON-FRI'}
                ]
            },
        }
    },
    'TZ': {  # Tanzania
        'name': 'Tanzania',
        'currency': 'TZS',
        'payment_methods': {
            PaymentMethod.CARD: {
                'provider': CardProvider.SMATPAY,
                'card_types': ['Visa', 'Mastercard'],
                'description': '💳 Visa or Mastercard (SmatPay)',
                'enabled': True,
            },
            PaymentMethod.EFT: {
                'provider': EFTProvider.DIRECT_TRANSFER,
                'description': '🏦 Bank Transfer',
                'enabled': True,
            },
            PaymentMethod.CASH: {
                'provider': CashProvider.ON_SITE,
                'description': '💰 Pay Cash at Office',
                'enabled': True,
            },
        }
    },
    'NG': {  # Nigeria
        'name': 'Nigeria',
        'currency': 'NGN',
        'payment_methods': {
            PaymentMethod.CARD: {
                'provider': CardProvider.SMATPAY,
                'card_types': ['Visa', 'Mastercard'],
                'description': '💳 Visa or Mastercard (SmatPay)',
                'enabled': True,
            },
            PaymentMethod.EFT: {
                'provider': EFTProvider.DIRECT_TRANSFER,
                'description': '🏦 Bank Transfer',
                'enabled': True,
            },
            PaymentMethod.CASH: {
                'provider': CashProvider.ON_SITE,
                'description': '💰 Pay Cash at Office',
                'enabled': True,
            },
        }
    },
    'UG': {  # Uganda
        'name': 'Uganda',
        'currency': 'UGX',
        'payment_methods': {
            PaymentMethod.CARD: {
                'provider': CardProvider.SMATPAY,
                'card_types': ['Visa', 'Mastercard'],
                'description': '💳 Visa or Mastercard (SmatPay)',
                'enabled': True,
            },
            PaymentMethod.EFT: {
                'provider': EFTProvider.DIRECT_TRANSFER,
                'description': '🏦 Bank Transfer',
                'enabled': True,
            },
            PaymentMethod.CASH: {
                'provider': CashProvider.ON_SITE,
                'description': '💰 Pay Cash at Office',
                'enabled': True,
            },
        }
    },
    # ... other countries can be added following the same pattern
}

# Training Type specific payment method preferences (can be overridden per country)
TRAINING_TYPE_PAYMENT_PREFERENCES = {
    TrainingType.MASTERCLASS: {
        'preferred_methods': [PaymentMethod.CARD, PaymentMethod.EFT, PaymentMethod.CASH],
        'instant_access_method': PaymentMethod.CARD,  # Card gives instant access
    },
    TrainingType.LEARNERSHIP: {
        'preferred_methods': [PaymentMethod.CARD, PaymentMethod.EFT, PaymentMethod.CASH],
        'instant_access_method': PaymentMethod.CARD,
    },
    TrainingType.AI_CERTS: {
        'preferred_methods': [PaymentMethod.CARD, PaymentMethod.EFT, PaymentMethod.CASH],
        'instant_access_method': PaymentMethod.CARD,
    },
    TrainingType.CUSTOM_SELECTION: {
        'preferred_methods': [PaymentMethod.CARD, PaymentMethod.EFT, PaymentMethod.CASH],
        'instant_access_method': PaymentMethod.CARD,
    },
}


class PaymentRoutingService:
    """Service to route payments to correct provider based on country and method"""

    @staticmethod
    def get_available_payment_methods(country_code: str, training_type: str = None) -> List[Dict]:
        """
        Get available payment methods for a country and optionally filtered by training type.
        
        Args:
            country_code: ISO 3166-1 alpha-2 country code (e.g., 'ZW', 'ZA', 'KE')
            training_type: Optional training type (masterclass, learnership, aicerts_courses, custom_selection)
            
        Returns:
            List of available payment methods with details
        """
        country_code = str(country_code).upper()
        
        # Get country config
        country_config = COUNTRY_PAYMENT_CONFIG.get(country_code)
        if not country_config:
            logger.warning(f"Country {country_code} not configured, returning empty methods")
            return []
        
        # Get payment methods for country
        payment_methods = country_config.get('payment_methods', {})
        
        # Filter by training type preferences if provided
        if training_type:
            training_type = TrainingType(training_type) if isinstance(training_type, str) else training_type
            preferences = TRAINING_TYPE_PAYMENT_PREFERENCES.get(training_type, {})
            preferred_methods = preferences.get('preferred_methods', [])
            
            # Filter to only preferred methods
            filtered_methods = {
                k: v for k, v in payment_methods.items()
                if k in preferred_methods and v.get('enabled', True)
            }
        else:
            filtered_methods = {k: v for k, v in payment_methods.items() if v.get('enabled', True)}
        
        # Format response
        result = []
        for method, config in filtered_methods.items():
            result.append({
                'method': method.value,
                'provider': config['provider'].value if hasattr(config['provider'], 'value') else str(config['provider']),
                'description': config['description'],
                'card_types': config.get('card_types'),
                'enabled': config.get('enabled', True),
                'locations': config.get('locations'),
            })
        
        return result

    @staticmethod
    def get_payment_provider(country_code: str, payment_method: str) -> Optional[str]:
        """
        Get the payment provider for a specific country and payment method.
        
        Args:
            country_code: ISO country code
            payment_method: Payment method (card, eft, cash)
            
        Returns:
            Provider code (e.g., 'smatpay', 'bank_transfer', 'on_site_payment')
        """
        country_code = str(country_code).upper()
        payment_method = PaymentMethod(payment_method) if isinstance(payment_method, str) else payment_method
        
        country_config = COUNTRY_PAYMENT_CONFIG.get(country_code)
        if not country_config:
            return None
        
        method_config = country_config['payment_methods'].get(payment_method)
        if not method_config:
            return None
        
        provider = method_config.get('provider')
        return provider.value if hasattr(provider, 'value') else str(provider)

    @staticmethod
    def validate_payment_method(country_code: str, payment_method: str, training_type: str = None) -> Tuple[bool, Optional[str]]:
        """
        Validate if a payment method is available for a country/training type.
        
        Args:
            country_code: ISO country code
            payment_method: Payment method
            training_type: Optional training type
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        country_code = str(country_code).upper()
        
        # Check if country configured
        if country_code not in COUNTRY_PAYMENT_CONFIG:
            return False, f"Country {country_code} not supported"
        
        # Check if payment method available for country
        available_methods = PaymentRoutingService.get_available_payment_methods(country_code, training_type)
        available_method_codes = [m['method'] for m in available_methods]
        
        if payment_method not in available_method_codes:
            return False, f"Payment method '{payment_method}' not available for {country_code}"
        
        return True, None

    @staticmethod
    def get_instant_access_method(training_type: str) -> str:
        """Get the payment method that provides instant enrollment access."""
        training_type = TrainingType(training_type) if isinstance(training_type, str) else training_type
        prefs = TRAINING_TYPE_PAYMENT_PREFERENCES.get(training_type, {})
        return prefs.get('instant_access_method', PaymentMethod.CARD).value

    @staticmethod
    def get_country_config(country_code: str) -> Optional[Dict]:
        """Get full configuration for a country."""
        country_code = str(country_code).upper()
        return COUNTRY_PAYMENT_CONFIG.get(country_code)


# Export for use in views and services
__all__ = [
    'PaymentRoutingService',
    'TrainingType',
    'PaymentMethod',
    'CardProvider',
    'EFTProvider',
    'CashProvider',
    'COUNTRY_PAYMENT_CONFIG',
    'TRAINING_TYPE_PAYMENT_PREFERENCES',
]
