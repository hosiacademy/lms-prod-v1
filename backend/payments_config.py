"""
Payment Providers Configuration
All test credentials for sandbox environments
"""

import os
from dotenv import load_dotenv

load_dotenv()

# ============================================================================
# PAYMENT SYSTEM CORE CONFIG
# ============================================================================
PAYMENT_TEST_MODE = os.getenv('PAYMENT_TEST_MODE', 'True') == 'True'
PAYMENT_ENABLE_ALL_PROVIDERS = os.getenv('PAYMENT_ENABLE_ALL_PROVIDERS', 'True') == 'True'
PAYMENT_WEBHOOK_TIMEOUT = int(os.getenv('PAYMENT_WEBHOOK_TIMEOUT', '30'))
PAYMENT_RETRY_ATTEMPTS = int(os.getenv('PAYMENT_RETRY_ATTEMPTS', '3'))
PAYMENT_RETRY_DELAY = int(os.getenv('PAYMENT_RETRY_DELAY', '5'))

# Site URLs for redirects
SITE_URL = os.getenv('SITE_URL', 'http://localhost:3000')
SITE_DOMAIN = os.getenv('SITE_DOMAIN', 'localhost:3000')
API_URL = os.getenv('API_URL', 'http://localhost:8000')

# ============================================================================
# FLUTTERWAVE CONFIGURATION (Pan-African Payment Aggregator)
# ============================================================================
FLUTTERWAVE_CONFIG = {
    'name': 'Flutterwave',
    'code': 'flutterwave',
    'enabled': True,
    'public_key': os.getenv('FLUTTERWAVE_PUBLIC_KEY', 'FLWPUBK_TEST-e1ccbfa2e4c97fcc41f6a0afb1d8c8e8-X'),
    'secret_key': os.getenv('FLUTTERWAVE_SECRET_KEY', 'FLWSECK_TEST-8c8fa03bfeb3f6b3feba51d51f3a4f3e-X'),
    'webhook_secret': os.getenv('FLUTTERWAVE_WEBHOOK_SECRET', 'webhook_test_secret_key_12345'),
    'api_url': os.getenv('FLUTTERWAVE_API_URL', 'https://api.flutterwave.com/v3'),
    'sandbox': os.getenv('FLUTTERWAVE_SANDBOX', 'True') == 'True',
    'test_mode': PAYMENT_TEST_MODE,
    'supported_countries': ['NG', 'GH', 'KE', 'ZA', 'UG', 'TZ', 'RW', 'CM', 'CI', 'SN', 'ZM', 'MW'],
    'test_cards': {
        'visa': {
            'number': '4242424242424242',
            'cvv': '123',
            'expiry': '09/32',
            'name': 'Test Visa',
            'country': 'NG',
        },
        'mastercard': {
            'number': '5291998304461519',
            'cvv': '123',
            'expiry': '09/32',
            'name': 'Test Mastercard',
            'country': 'NG',
        },
    },
    'mobile_money_test': {
        'mtn_momo': '0548577828',
        'orange_money': '+237650000000',
    },
    'webhook_url': f'{API_URL}/api/payments/webhooks/flutterwave/',
    'success_url': f'{SITE_URL}/payment-success',
    'failure_url': f'{SITE_URL}/payment-failed',
}

# ============================================================================
# PAYSTACK CONFIGURATION (West & East African Payment Provider)
# ============================================================================
PAYSTACK_CONFIG = {
    'name': 'Paystack',
    'code': 'paystack',
    'enabled': True,
    'public_key': os.getenv('PAYSTACK_PUBLIC_KEY', 'pk_test_abcdefghijk1234567890abcdefghijk'),
    'secret_key': os.getenv('PAYSTACK_SECRET_KEY', 'sk_test_abcdefghijk1234567890abcdefghijk'),
    'webhook_secret': os.getenv('PAYSTACK_WEBHOOK_SECRET', 'webhook_test_secret_12345'),
    'api_url': os.getenv('PAYSTACK_API_URL', 'https://api.paystack.co'),
    'sandbox': os.getenv('PAYSTACK_SANDBOX', 'True') == 'True',
    'test_mode': PAYMENT_TEST_MODE,
    'supported_countries': ['NG', 'GH', 'KE', 'ZA'],
    'supported_currencies': ['NGN', 'GHS', 'KES', 'ZAR'],
    'test_cards': {
        'visa_success': {
            'number': '4084084084084081',
            'cvv': '408',
            'expiry': '12/50',
            'name': 'Test Visa (Success)',
            'country': 'NG',
        },
        'visa_auth': {
            'number': '4187267867141015',
            'cvv': '883',
            'expiry': '12/50',
            'name': 'Test Visa (Auth Required)',
            'country': 'NG',
        },
        'mastercard': {
            'number': '5398220714026015',
            'cvv': '589',
            'expiry': '12/50',
            'name': 'Test Mastercard',
            'country': 'NG',
        },
    },
    'test_transfer': {
        'code': '50581', # Guaranty Trust Bank
        'account': '0123456789',
    },
    'webhook_url': f'{API_URL}/api/payments/webhooks/paystack/',
    'success_url': f'{SITE_URL}/payment-success',
    'failure_url': f'{SITE_URL}/payment-failed',
}

# ============================================================================
# STRIPE CONFIGURATION (Global Payment Provider - 46+ Countries)
# ============================================================================
STRIPE_CONFIG = {
    'name': 'Stripe',
    'code': 'stripe',
    'enabled': True,
    'public_key': os.getenv('STRIPE_PUBLIC_KEY', 'pk_test_51234567890abcdefghijk1234567890'),
    'secret_key': os.getenv('STRIPE_SECRET_KEY', 'sk_test_51234567890abcdefghijk1234567890'),
    'webhook_secret': os.getenv('STRIPE_WEBHOOK_SECRET', 'whsec_test_abcdefghijk1234567890'),
    'api_url': os.getenv('STRIPE_API_URL', 'https://api.stripe.com/v1'),
    'sandbox': os.getenv('STRIPE_SANDBOX', 'True') == 'True',
    'test_mode': PAYMENT_TEST_MODE,
    'supported_countries': 46,  # 46+ countries worldwide
    'supported_currencies': 135,  # 135+ currencies
    'test_cards': {
        'visa': {
            'number': '4242424242424242',
            'cvc': '123',
            'expiry': '12/50',
            'name': 'Test Visa',
            'country': 'US',
        },
        'visa_3d_secure': {
            'number': '4000002500003155',
            'cvc': '123',
            'expiry': '12/50',
            'name': 'Test Visa (3D Secure)',
            'country': 'US',
        },
        'mastercard': {
            'number': '5555555555554444',
            'cvc': '123',
            'expiry': '12/50',
            'name': 'Test Mastercard',
            'country': 'US',
        },
        'amex': {
            'number': '378282246310005',
            'cvc': '1234',
            'expiry': '12/50',
            'name': 'Test American Express',
            'country': 'US',
        },
    },
    'webhook_url': f'{API_URL}/api/payments/webhooks/stripe/',
    'success_url': f'{SITE_URL}/payment-success',
    'failure_url': f'{SITE_URL}/payment-failed',
}

# ============================================================================
# LOCAL MOBILE MONEY PROVIDERS (African Markets)
# ============================================================================
MPESA_CONFIG = {
    'name': 'M-Pesa',
    'code': 'mpesa',
    'enabled': True,
    'business_shortcode': os.getenv('MPESA_BUSINESS_SHORTCODE', '174379'),
    'consumer_key': os.getenv('MPESA_CONSUMER_KEY', 'test_key'),
    'consumer_secret': os.getenv('MPESA_CONSUMER_SECRET', 'test_secret'),
    'passkey': os.getenv('MPESA_PASSKEY', 'bfb279f9aa9bdbcf158e97dd1a503017'),
    'api_url': 'https://sandbox.safaricom.co.ke/mpesa',
    'sandbox': True,
    'test_number': '254708374149',
    'supported_countries': ['KE'],
}

MTN_MOMO_CONFIG = {
    'name': 'MTN Mobile Money',
    'code': 'mtn_momo',
    'enabled': True,
    'api_key': os.getenv('MTN_MOMO_API_KEY', 'test_api_key'),
    'primary_key': os.getenv('MTN_MOMO_PRIMARY_KEY', 'test_primary_key'),
    'api_url': 'https://sandbox.momodeveloper.mtn.com',
    'sandbox': True,
    'test_number': '256775000111',
    'supported_countries': ['UG', 'BF', 'CM', 'CI', 'GH', 'GM', 'GW', 'KE', 'LR', 'ML', 'MZ', 'RW', 'SN', 'TZ', 'ZA'],
}

ORANGE_MONEY_CONFIG = {
    'name': 'Orange Money',
    'code': 'orange_money',
    'enabled': True,
    'merchant_key': os.getenv('ORANGE_MONEY_MERCHANT_KEY', 'test_merchant_key'),
    'merchant_password': os.getenv('ORANGE_MONEY_MERCHANT_PASSWORD', 'test_merchant_password'),
    'api_url': 'https://api.orange.com/orange-money-sandbox',
    'sandbox': True,
    'test_number': '+237699000000',
    'supported_countries': ['CM', 'SN', 'CI', 'ML', 'BF'],
}

# ============================================================================
# PROVIDER REGISTRY
# ============================================================================
PAYMENT_PROVIDERS = {
    'flutterwave': FLUTTERWAVE_CONFIG,
    'paystack': PAYSTACK_CONFIG,
    'stripe': STRIPE_CONFIG,
    'mpesa': MPESA_CONFIG,
    'mtn_momo': MTN_MOMO_CONFIG,
    'orange_money': ORANGE_MONEY_CONFIG,
}

# ============================================================================
# FEES CONFIGURATION (in percentages)
# ============================================================================
PAYMENT_FEES = {
    'flutterwave': {
        'international': 3.9,  # 3.9% + ₦25
        'domestic': 1.4,       # 1.4%
    },
    'paystack': {
        'standard': 1.5,       # 1.5% + flat rate
        'international': 3.9,  # 3.9% + flat rate
    },
    'stripe': {
        'card': 2.9,           # 2.9% + $0.30
        'international': 3.9,  # 3.9% for international
    },
    'mobile_money': 1.0,       # 1% average
}

# ============================================================================
# WEBHOOK SIGNATURE VERIFICATION
# ============================================================================
WEBHOOK_VERIFICATION_ENABLED = os.getenv('WEBHOOK_VERIFICATION_ENABLED', 'True') == 'True'
WEBHOOK_SIGNATURE_VERIFICATION = os.getenv('WEBHOOK_SIGNATURE_VERIFICATION', 'True') == 'True'
WEBHOOK_LOG_ALL = os.getenv('WEBHOOK_LOG_ALL', 'True') == 'True'

# Webhook timeouts for verification (seconds)
WEBHOOK_TIMEOUTS = {
    'flutterwave': 30,
    'paystack': 30,
    'stripe': 30,
}

# ============================================================================
# PAYMENT STATUSES
# ============================================================================
PAYMENT_STATUS_CHOICES = [
    ('pending', 'Pending'),
    ('processing', 'Processing'),
    ('completed', 'Completed'),
    ('failed', 'Failed'),
    ('cancelled', 'Cancelled'),
    ('refunded', 'Refunded'),
]

# ============================================================================
# CURRENCY CONVERSION
# ============================================================================
CURRENCY_EXCHANGE_RATES = {
    'USD': 1.0,
    'NGN': 0.0013,       # Nigerian Naira
    'GHS': 0.0062,       # Ghanaian Cedis
    'KES': 0.0077,       # Kenyan Shilling
    'ZAR': 0.053,        # South African Rand
    'UGX': 0.00027,      # Ugandan Shilling
    'TZS': 0.00039,      # Tanzanian Shilling
    'RWF': 0.00077,      # Rwandan Franc
    'EUR': 1.10,         # Euro
    'GBP': 1.28,         # British Pound
}

# Get function to retrieve provider config safely
def get_provider_config(provider_code):
    """Get configuration for a specific payment provider"""
    return PAYMENT_PROVIDERS.get(provider_code.lower())

def get_enabled_providers():
    """Get list of enabled payment providers"""
    return [code for code, config in PAYMENT_PROVIDERS.items() if config.get('enabled')]

def get_provider_for_country(country_code):
    """Get recommended payment provider for a specific country"""
    country_upper = country_code.upper()
    
    # Try providers in priority order
    priority_providers = ['flutterwave', 'paystack', 'stripe']
    
    for provider_code in priority_providers:
        config = get_provider_config(provider_code)
        if config and config.get('enabled'):
            # Check if provider supports country
            if 'supported_countries' in config:
                if country_upper in config['supported_countries']:
                    return config
            else:
                # Provider (like Stripe) supports most countries
                return config
    
    # Default to Stripe if no specific match
    return get_provider_config('stripe')
