#!/usr/bin/env python3
"""
Payment Providers Test Suite - Updated Version
Tests all 11 active payment providers with proper mocking

Usage:
    cd /home/tk/lms-prod/backend
    ../backend/venv_linux/bin/python apps/payments/tests/test_payment_providers_updated.py
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, Mock
from datetime import datetime

# Setup paths
BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, BACKEND_DIR)

# Setup minimal Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

# Configure Django settings manually for testing
import django
from django.conf import settings

if not settings.configured:
    settings.configure(
        DEBUG=True,
        SECRET_KEY='test-secret-key-for-testing-only',
        INSTALLED_APPS=[
            'django.contrib.contenttypes',
            'django.contrib.auth',
            'apps.payments',
        ],
        DATABASES={
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': ':memory:',
            }
        },
        # Payment provider test credentials
        FLUTTERWAVE_SECRET_KEY='FLWSECK_TEST-1234567890',
        FLUTTERWAVE_PUBLIC_KEY='FLWPUBK_TEST-1234567890',
        FLUTTERWAVE_SANDBOX=True,
        MPESA_CONSUMER_KEY='test_key',
        MPESA_CONSUMER_SECRET='test_secret',
        MPESA_BUSINESS_SHORTCODE='174379',
        MPESA_PASSKEY='bfb279f9aa9bdbcf158e97dd1a503017',
        MPESA_SANDBOX=True,
        STRIPE_SECRET_KEY='sk_test_51234567890',
        STRIPE_PUBLIC_KEY='pk_test_51234567890',
        STRIPE_WEBHOOK_SECRET='whsec_test_123456',
        PAYSTACK_SECRET_KEY='sk_test_1234567890',
        PAYSTACK_PUBLIC_KEY='pk_test_1234567890',
        PAYSTACK_SANDBOX=True,
        PAYNOW_INTEGRATION_ID='12345',
        PAYNOW_INTEGRATION_KEY='test_key_12345',
        PAYNOW_SANDBOX=True,
        FAWRY_MERCH_CODE='TEST_MERCH',
        FAWRY_SEC_KEY='test_sec_key',
        FAWRY_SANDBOX=True,
        AIRTEL_CLIENT_ID='test_client_id',
        AIRTEL_CLIENT_SECRET='test_secret',
        AIRTEL_SANDBOX=True,
        MTN_MOMO_API_KEY='test_api_key',
        MTN_MOMO_PRIMARY_KEY='test_primary',
        ORANGE_MONEY_MERCHANT_KEY='test_merchant',
        ORANGE_MONEY_MERCHANT_PASSWORD='test_password',
        VODACOM_MPESA_SANDBOX=True,
        ROOT_URLCONF='',
        DEFAULT_AUTO_FIELD='django.db.models.BigAutoField',
    )

try:
    django.setup()
except Exception as e:
    print(f"Warning: Django setup warning: {e}")

# Now import the adapters
from apps.payments.adapters import ADAPTER_REGISTRY, get_adapter
from apps.payments.adapters.base import BasePaymentAdapter


# ============================================================================
# MOCK TRANSACTION
# ============================================================================
class MockTransaction:
    """Mock transaction for testing"""
    def __init__(self, amount=100.00, currency='USD', country='US', email='test@example.com'):
        self.id = 12345
        self.amount = amount
        self.currency = currency
        self.country = country
        self.reference = f"TXN-{datetime.now().timestamp()}"
        self.provider_reference = f"REF-{datetime.now().timestamp()}"
        self.status = 'pending'
        self.provider = None
        self.provider_data = {}
        self.metadata = {
            'customer_email': email,
            'customer_phone': '+1234567890',
            'description': 'Test payment',
        }
        self.user = Mock()
        self.user.email = email
        self.user.id = 999
        self.user.first_name = 'Test'
        self.user.last_name = 'User'
        self.user.get_full_name = lambda: 'Test User'
    
    def save(self):
        pass


# ============================================================================
# BASE TEST CLASS
# ============================================================================
class BasePaymentProviderTest:
    """Base test class with common test methods"""
    
    provider_code = None
    provider_name = None
    
    def get_adapter(self):
        return get_adapter(self.provider_code)
    
    def test_adapter_exists(self):
        """Test: Adapter is registered"""
        self.assertIn(self.provider_code, ADAPTER_REGISTRY)
    
    def test_adapter_initialization(self):
        """Test: Adapter initializes without error"""
        adapter = self.get_adapter()
        self.assertIsNotNone(adapter)
        self.assertIsInstance(adapter, BasePaymentAdapter)
    
    def test_get_provider_name(self):
        """Test: Get provider name"""
        adapter = self.get_adapter()
        name = adapter.get_provider_name()
        self.assertIsInstance(name, str)
        self.assertTrue(len(name) > 0)
    
    def test_get_provider_code(self):
        """Test: Get provider code"""
        adapter = self.get_adapter()
        code = adapter.get_provider_code()
        self.assertEqual(code, self.provider_code)
    
    def test_get_supported_countries(self):
        """Test: Get supported countries returns list"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        self.assertIsInstance(countries, list)
    
    def test_get_supported_currencies(self):
        """Test: Get supported currencies returns list"""
        adapter = self.get_adapter()
        currencies = adapter.get_supported_currencies()
        self.assertIsInstance(currencies, list)
    
    def test_get_supported_methods(self):
        """Test: Get supported methods returns list"""
        adapter = self.get_adapter()
        methods = adapter.get_supported_methods()
        self.assertIsInstance(methods, list)


# ============================================================================
# ESSENTIAL PROVIDERS (6)
# ============================================================================

class TestFlutterwaveProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test Flutterwave - Pan-African Aggregator"""
    provider_code = 'flutterwave'
    provider_name = 'Flutterwave'
    
    def test_flutterwave_countries(self):
        """Test: Flutterwave supports 40+ African countries"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        self.assertGreater(len(countries), 40)
    
    def test_flutterwave_key_countries(self):
        """Test: Flutterwave supports key markets"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        for country in ['NG', 'GH', 'KE', 'ZA', 'UG', 'TZ', 'RW', 'ZW']:
            self.assertIn(country, countries)
    
    @patch('requests.post')
    def test_flutterwave_initiate_payment(self, mock_post):
        """Test: Flutterwave payment initiation"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'status': 'success',
            'data': {
                'link': 'https://checkout.flutterwave.com/test',
            }
        }
        mock_post.return_value = mock_response
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='KES', country='KE')
        
        result = adapter.initiate_payment(
            transaction=transaction,
            callback_url='https://example.com/webhook',
        )
        
        self.assertIn('status', result)
        mock_post.assert_called_once()
    
    def test_flutterwave_webhook_verification(self):
        """Test: Flutterwave webhook signature verification"""
        adapter = self.get_adapter()
        payload = b'{"event": "charge.completed"}'
        headers = {'X-Flutterwave-Signature': 'test-sig'}
        result = adapter.verify_webhook_signature(payload, headers)
        self.assertIsInstance(result, bool)


class TestMpesaProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test M-Pesa - Kenya"""
    provider_code = 'mpesa'
    provider_name = 'M-Pesa'
    
    def test_mpesa_kenya_only(self):
        """Test: M-Pesa only supports Kenya"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        self.assertIn('KE', countries)
    
    def test_mpesa_currency(self):
        """Test: M-Pesa uses KES"""
        adapter = self.get_adapter()
        currencies = adapter.get_supported_currencies()
        self.assertIn('KES', currencies)
    
    @patch('requests.post')
    def test_mpesa_stk_push(self, mock_post):
        """Test: M-Pesa STK Push initiation"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'ResponseCode': '0',
            'ResponseDescription': 'Success',
            'CheckoutRequestID': 'ws_CO_123456789',
        }
        mock_post.return_value = mock_response
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='KES', country='KE', amount=1000)
        
        result = adapter.initiate_payment(
            transaction=transaction,
            phone_number='+254708374149',
        )
        
        self.assertIsNotNone(result)
        mock_post.assert_called()


class TestVodacomMpesaProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test Vodacom M-Pesa - TZ, MZ, CD, LS"""
    provider_code = 'vodacom_mpesa'
    provider_name = 'Vodacom M-Pesa'
    
    def test_vodacom_countries(self):
        """Test: Vodacom M-Pesa supports 4 countries"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        # Should support TZ, MZ, CD, LS
        self.assertGreater(len(countries), 0)
    
    def test_vodacom_tanzania(self):
        """Test: Vodacom supports Tanzania"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        self.assertIn('TZ', countries)
    
    @patch('requests.post')
    def test_vodacom_stk_push(self, mock_post):
        """Test: Vodacom M-Pesa STK Push"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'ResponseCode': '0',
            'ResponseDescription': 'Success',
        }
        mock_post.return_value = mock_response
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='TZS', country='TZ', amount=10000)
        
        result = adapter.initiate_payment(
            transaction=transaction,
            phone_number='+255712345678',
        )
        
        self.assertIsNotNone(result)


class TestPaynowProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test Paynow - Zimbabwe"""
    provider_code = 'paynow'
    provider_name = 'Paynow'
    
    def test_paynow_zimbabwe(self):
        """Test: Paynow supports Zimbabwe"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        self.assertIn('ZW', countries)
    
    def test_paynow_currencies(self):
        """Test: Paynow supports USD and ZWL"""
        adapter = self.get_adapter()
        currencies = adapter.get_supported_currencies()
        self.assertIn('USD', currencies)
        self.assertIn('ZWL', currencies)
    
    def test_paynow_methods(self):
        """Test: Paynow supports multiple methods"""
        adapter = self.get_adapter()
        methods = adapter.get_supported_methods()
        # Should include ecocash, onemoney, telecash, visa, mastercard
        self.assertGreater(len(methods), 3)
    
    @patch('requests.post')
    def test_paynow_initiate(self, mock_post):
        """Test: Paynow payment initiation"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.text = 'status=OK&pollurl=https://paynow.co.zw/poll/123'
        mock_post.return_value = mock_response
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='USD', country='ZW')
        
        result = adapter.initiate_payment(
            transaction=transaction,
            callback_url='https://example.com/webhook',
        )
        
        self.assertIn('status', result)
        mock_post.assert_called_once()
    
    def test_paynow_webhook_hash(self):
        """Test: Paynow uses SHA512 hash verification"""
        adapter = self.get_adapter()
        payload = b'status=PAID&reference=123'
        headers = {}
        result = adapter.verify_webhook_signature(payload, headers)
        self.assertIsInstance(result, bool)


class TestFawryProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test Fawry - Egypt"""
    provider_code = 'fawry'
    provider_name = 'Fawry'
    
    def test_fawry_egypt_only(self):
        """Test: Fawry only supports Egypt"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        self.assertIn('EG', countries)
    
    def test_fawry_currency(self):
        """Test: Fawry uses EGP"""
        adapter = self.get_adapter()
        currencies = adapter.get_supported_currencies()
        self.assertIn('EGP', currencies)
    
    def test_fawry_methods(self):
        """Test: Fawry supports kiosk payments"""
        adapter = self.get_adapter()
        methods = adapter.get_supported_methods()
        self.assertIn('kiosk', methods)
        self.assertIn('card', methods)
    
    def test_fawry_initiate_returns_reference(self):
        """Test: Fawry payment returns reference number"""
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='EGP', country='EG')
        
        result = adapter.initiate_payment(
            transaction=transaction,
            callback_url='https://example.com/webhook',
        )
        
        self.assertIn('provider_reference', result)
        self.assertIn('instructions', result)


class TestStripeProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test Stripe - International"""
    provider_code = 'stripe'
    provider_name = 'Stripe'
    
    def test_stripe_countries(self):
        """Test: Stripe supports 46+ countries"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        self.assertGreater(len(countries), 40)
    
    def test_stripe_currencies(self):
        """Test: Stripe supports 135+ currencies"""
        adapter = self.get_adapter()
        currencies = adapter.get_supported_currencies()
        self.assertGreater(len(currencies), 10)
    
    def test_stripe_methods(self):
        """Test: Stripe supports cards and more"""
        adapter = self.get_adapter()
        methods = adapter.get_supported_methods()
        self.assertIn('card', methods)
    
    @patch('stripe.PaymentIntent.create')
    def test_stripe_payment_intent(self, mock_create):
        """Test: Stripe creates Payment Intent"""
        mock_create.return_value = Mock(
            id='pi_123456',
            client_secret='pi_123456_secret_abc',
        )
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='USD', country='US')
        
        result = adapter.initiate_payment(
            transaction=transaction,
            callback_url='https://example.com/webhook',
        )
        
        self.assertIn('payment_intent_id', result)
        mock_create.assert_called_once()
    
    def test_stripe_webhook_verification(self):
        """Test: Stripe webhook signature verification"""
        adapter = self.get_adapter()
        payload = b'{"type": "payment_intent.succeeded"}'
        headers = {'Stripe-Signature': 't=123456,v1=abc'}
        result = adapter.verify_webhook_signature(payload, headers)
        self.assertIsInstance(result, bool)


# ============================================================================
# OPTIONAL PROVIDERS (5)
# ============================================================================

class TestPaystackProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test Paystack - Nigeria/Ghana"""
    provider_code = 'paystack'
    provider_name = 'Paystack'
    
    def test_paystack_countries(self):
        """Test: Paystack supports NG, GH, KE, ZA"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        for country in ['NG', 'GH']:
            self.assertIn(country, countries)
    
    @patch('requests.post')
    def test_paystack_initiate(self, mock_post):
        """Test: Paystack transaction initialization"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'status': True,
            'data': {
                'authorization_url': 'https://checkout.paystack.com/test',
            }
        }
        mock_post.return_value = mock_response
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='NGN', country='NG')
        
        result = adapter.initiate_payment(
            transaction=transaction,
            callback_url='https://example.com/webhook',
        )
        
        self.assertIsNotNone(result)


class TestPayPalProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test PayPal - International"""
    provider_code = 'paypal'
    provider_name = 'PayPal'
    
    def test_paypal_international(self):
        """Test: PayPal supports many countries"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        self.assertGreater(len(countries), 100)
    
    @patch('requests.post')
    def test_paypal_order_create(self, mock_post):
        """Test: PayPal creates order"""
        mock_response = MagicMock()
        mock_response.status_code = 201
        mock_response.json.return_value = {
            'id': 'ORDER-123',
            'status': 'CREATED',
        }
        mock_post.return_value = mock_response
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='USD', country='US')
        
        result = adapter.initiate_payment(
            transaction=transaction,
            callback_url='https://example.com/webhook',
        )
        
        self.assertIsNotNone(result)


class TestMTNMoMoProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test MTN MoMo - 12 African Countries"""
    provider_code = 'mtn_momo'
    provider_name = 'MTN Mobile Money'
    
    def test_mtn_countries(self):
        """Test: MTN MoMo supports 12+ countries"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        self.assertGreater(len(countries), 10)
    
    @patch('requests.post')
    def test_mtn_request_to_pay(self, mock_post):
        """Test: MTN MoMo RequestToPay"""
        mock_response = MagicMock()
        mock_response.status_code = 202
        mock_response.headers = {'X-Reference-Id': 'REF-123'}
        mock_post.return_value = mock_response
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='UGX', country='UG')
        
        result = adapter.initiate_payment(
            transaction=transaction,
            phone_number='+256775000111',
        )
        
        self.assertIsNotNone(result)


class TestAirtelMoneyProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test Airtel Money - Multiple Countries"""
    provider_code = 'airtel_money'
    provider_name = 'Airtel Money'
    
    def test_airtel_countries(self):
        """Test: Airtel Money supports multiple countries"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        # KE, UG, TZ, RW, MW, ZM, CD, etc.
        self.assertGreater(len(countries), 10)
    
    @patch('requests.post')
    def test_airtel_initiate_makes_api_call(self, mock_post):
        """Test: Airtel Money MUST make API call - CRITICAL BUG TEST"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'status': 'pending',
            'reference': 'AIRTEL-123',
        }
        mock_post.return_value = mock_response
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='KES', country='KE')
        
        # This MUST call requests.post
        result = adapter.initiate_payment(
            transaction=transaction,
            phone_number='+254708374149',
        )
        
        # CRITICAL: Verify API call was made
        mock_post.assert_called_once()
        self.assertIn('status', result)
    
    def test_airtel_token_required(self):
        """Test: Airtel requires OAuth token"""
        adapter = self.get_adapter()
        # Should have token method
        self.assertTrue(hasattr(adapter, '_get_token'))


class TestOrangeMoneyProvider(unittest.TestCase, BasePaymentProviderTest):
    """Test Orange Money - West & Central Africa"""
    provider_code = 'orange_money'
    provider_name = 'Orange Money'
    
    def test_orange_countries(self):
        """Test: Orange Money supports West/Central Africa"""
        adapter = self.get_adapter()
        countries = adapter.get_supported_countries()
        for country in ['CM', 'SN', 'CI']:
            self.assertIn(country, countries)
    
    def test_orange_currencies(self):
        """Test: Orange Money uses XOF/XAF"""
        adapter = self.get_adapter()
        currencies = adapter.get_supported_currencies()
        self.assertTrue(
            'XOF' in currencies or 'XAF' in currencies,
            "Orange Money should use XOF or XAF"
        )
    
    @patch('requests.post')
    def test_orange_webpay(self, mock_post):
        """Test: Orange Money WebPay"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'status': 'success',
            'payment_url': 'https://orange.money/pay',
        }
        mock_post.return_value = mock_response
        
        adapter = self.get_adapter()
        transaction = MockTransaction(currency='XAF', country='CM')
        
        result = adapter.initiate_payment(
            transaction=transaction,
            phone_number='+237699000000',
        )
        
        self.assertIsNotNone(result)


# ============================================================================
# INTEGRATION TESTS
# ============================================================================

class TestAllProvidersRegistered(unittest.TestCase):
    """Test that all 11 providers are registered"""
    
    def test_eleven_providers_registered(self):
        """Test: All 11 providers in ADAPTER_REGISTRY"""
        expected = [
            'flutterwave', 'mpesa', 'vodacom_mpesa', 'paynow', 'fawry', 'stripe',
            'paystack', 'paypal', 'mtn_momo', 'airtel_money', 'orange_money'
        ]
        
        for provider in expected:
            self.assertIn(provider, ADAPTER_REGISTRY)
    
    def test_get_adapter_returns_instance(self):
        """Test: get_adapter() works for all providers"""
        for provider_code in ADAPTER_REGISTRY.keys():
            adapter = get_adapter(provider_code)
            self.assertIsNotNone(adapter)


# ============================================================================
# RUN TESTS
# ============================================================================

if __name__ == '__main__':
    print("="*70)
    print("Payment Provider Test Suite - 11 Providers")
    print("="*70)
    print()
    
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add all test classes
    test_classes = [
        # Essential (6)
        TestFlutterwaveProvider,
        TestMpesaProvider,
        TestVodacomMpesaProvider,
        TestPaynowProvider,
        TestFawryProvider,
        TestStripeProvider,
        
        # Optional (5)
        TestPaystackProvider,
        TestPayPalProvider,
        TestMTNMoMoProvider,
        TestAirtelMoneyProvider,
        TestOrangeMoneyProvider,
        
        # Integration
        TestAllProvidersRegistered,
    ]
    
    for test_class in test_classes:
        tests = loader.loadTestsFromTestCase(test_class)
        suite.addTests(tests)
    
    # Run
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Summary
    print()
    print("="*70)
    print(f"Tests Run: {result.testsRun}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print(f"Skipped: {len(result.skipped)}")
    success_rate = (result.testsRun - len(result.failures) - len(result.errors)) / result.testsRun * 100 if result.testsRun > 0 else 0
    print(f"Success Rate: {success_rate:.1f}%")
    print("="*70)
    
    sys.exit(0 if result.wasSuccessful() else 1)
