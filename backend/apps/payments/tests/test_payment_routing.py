# backend/apps/payments/tests/test_payment_routing.py
"""
Tests for Payment Routing Service and unified payment flow.

Tests cover:
- Payment method validation
- Country configuration
- Provider routing
- SmatPay card exclusivity
- Training type specific flows
"""

from django.test import TestCase, RequestFactory
from django.contrib.auth.models import User
from rest_framework.test import APITestCase, APIClient
from rest_framework import status

from apps.payments.services.payment_routing_service import (
    PaymentRoutingService,
    PaymentMethod,
    TrainingType,
    COUNTRY_PAYMENT_CONFIG
)
from apps.payments.models import PaymentTransaction
import logging

logger = logging.getLogger(__name__)


class PaymentRoutingServiceTests(TestCase):
    """Test Payment Routing Service"""
    
    def test_get_available_methods_zimbabwe_all_training_types(self):
        """Test getting available methods for Zimbabwe"""
        for training_type in ['masterclass', 'learnership', 'aicerts_courses', 'custom_selection']:
            methods = PaymentRoutingService.get_available_payment_methods(
                country_code='ZW',
                training_type=training_type
            )
            
            self.assertIsNotNone(methods)
            self.assertGreater(len(methods), 0)
            
            # Check all methods are present
            method_codes = [m['method'] for m in methods]
            self.assertIn('card', method_codes)
            self.assertIn('eft', method_codes)
            self.assertIn('cash', method_codes)
    
    def test_smatpay_exclusive_for_card_zimbabwe(self):
        """Test SmatPay is exclusive card provider for Zimbabwe"""
        methods = PaymentRoutingService.get_available_payment_methods(
            country_code='ZW',
            training_type='masterclass'
        )
        
        card_method = next((m for m in methods if m['method'] == 'card'), None)
        self.assertIsNotNone(card_method)
        self.assertEqual(card_method['provider'], 'smatpay')
    
    def test_smatpay_exclusive_for_card_south_africa(self):
        """Test SmatPay is exclusive card provider for South Africa"""
        methods = PaymentRoutingService.get_available_payment_methods(
            country_code='ZA',
            training_type='learnership'
        )
        
        card_method = next((m for m in methods if m['method'] == 'card'), None)
        self.assertIsNotNone(card_method)
        self.assertEqual(card_method['provider'], 'smatpay')
    
    def test_validate_payment_method_valid(self):
        """Test validating a valid payment method"""
        is_valid, error = PaymentRoutingService.validate_payment_method(
            country_code='ZW',
            payment_method='card',
            training_type='masterclass'
        )
        
        self.assertTrue(is_valid)
        self.assertIsNone(error)
    
    def test_validate_payment_method_invalid_country(self):
        """Test validating payment method for unsupported country"""
        is_valid, error = PaymentRoutingService.validate_payment_method(
            country_code='XX',  # Invalid country
            payment_method='card'
        )
        
        self.assertFalse(is_valid)
        self.assertIsNotNone(error)
        self.assertIn('not supported', error)
    
    def test_validate_payment_method_invalid_method(self):
        """Test validating unsupported payment method"""
        is_valid, error = PaymentRoutingService.validate_payment_method(
            country_code='ZW',
            payment_method='bitcoin',  # Invalid method
            training_type='masterclass'
        )
        
        self.assertFalse(is_valid)
        self.assertIsNotNone(error)
    
    def test_get_payment_provider_card_smatpay(self):
        """Test getting SmatPay provider for card payment"""
        provider = PaymentRoutingService.get_payment_provider(
            country_code='ZW',
            payment_method='card'
        )
        
        self.assertEqual(provider, 'smatpay')
    
    def test_get_payment_provider_eft_zimbabwe(self):
        """Test getting EFT provider for Zimbabwe"""
        provider = PaymentRoutingService.get_payment_provider(
            country_code='ZW',
            payment_method='eft'
        )
        
        self.assertIsNotNone(provider)
        self.assertIn('transfer', provider.lower())
    
    def test_get_country_config_zimbabwe(self):
        """Test getting complete country configuration"""
        config = PaymentRoutingService.get_country_config('ZW')
        
        self.assertIsNotNone(config)
        self.assertEqual(config['currency'], 'USD')
        self.assertIn('payment_methods', config)
        self.assertIn(PaymentMethod.CARD, config['payment_methods'])
    
    def test_all_supported_countries_configured(self):
        """Test all required countries are configured"""
        required_countries = ['ZW', 'ZA', 'KE', 'TZ', 'NG', 'UG']
        
        for country in required_countries:
            config = PaymentRoutingService.get_country_config(country)
            self.assertIsNotNone(config, f"Country {country} not configured")
    
    def test_instant_access_method_is_card(self):
        """Test instant access method for training types is card"""
        for training_type in ['masterclass', 'learnership', 'aicerts_courses', 'custom_selection']:
            instant_method = PaymentRoutingService.get_instant_access_method(training_type)
            self.assertEqual(instant_method, 'card')
    
    def test_get_methods_for_all_training_types(self):
        """Test getting methods for all training types"""
        training_types = ['masterclass', 'learnership', 'aicerts_courses', 'custom_selection']
        
        for training_type in training_types:
            methods = PaymentRoutingService.get_available_payment_methods(
                country_code='ZW',
                training_type=training_type
            )
            
            # All should have same methods
            self.assertEqual(len(methods), 3)  # Card, EFT, Cash


class PaymentRoutingAPITests(APITestCase):
    """Test Payment Methods API endpoints"""
    
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_get_payment_methods_endpoint(self):
        """Test GET /api/v1/payments/methods/methods/ endpoint"""
        response = self.client.get(
            '/api/v1/payments/methods/methods/',
            {'country': 'ZW', 'training_type': 'masterclass'}
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('methods', response.data)
        
        # Verify card payment provider is SmatPay
        card_method = next(
            (m for m in response.data['methods'] if m['method'] == 'card'),
            None
        )
        self.assertIsNotNone(card_method)
        self.assertEqual(card_method['provider'], 'smatpay')
    
    def test_validate_payment_method_endpoint_valid(self):
        """Test POST /api/v1/payments/methods/validate-method/ with valid method"""
        response = self.client.post(
            '/api/v1/payments/methods/validate-method/',
            {
                'country': 'ZW',
                'payment_method': 'card',
                'training_type': 'masterclass'
            },
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['valid'])
        self.assertEqual(response.data['provider'], 'smatpay')
    
    def test_validate_payment_method_endpoint_invalid_country(self):
        """Test validation endpoint with invalid country"""
        response = self.client.post(
            '/api/v1/payments/methods/validate-method/',
            {
                'country': 'XX',
                'payment_method': 'card'
            },
            format='json'
        )
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.data['valid'])
    
    def test_routing_endpoint(self):
        """Test GET /api/v1/payments/methods/routing/ endpoint"""
        response = self.client.get(
            '/api/v1/payments/methods/routing/',
            {'country': 'ZW', 'method': 'card'}
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['provider'], 'smatpay')
    
    def test_country_config_endpoint(self):
        """Test GET /api/v1/payments/methods/country-config/ endpoint"""
        response = self.client.get(
            '/api/v1/payments/methods/country-config/',
            {'country': 'ZW'}
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['currency'], 'USD')
        self.assertIn('card', response.data['payment_methods'])
    
    def test_smatpay_info_endpoint(self):
        """Test GET /api/v1/payments/methods/smatpay-info/ endpoint"""
        response = self.client.get(
            '/api/v1/payments/methods/smatpay-info/',
            {'country': 'ZW'}
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['is_exclusive'])
        self.assertEqual(response.data['card_provider'], 'smatpay')
    
    def test_methods_for_training_endpoint_all_types(self):
        """Test methods-for-training endpoint for all training types"""
        training_types = ['masterclass', 'learnership', 'aicerts_courses', 'custom_selection']
        
        for training_type in training_types:
            response = self.client.get(
                '/api/v1/payments/methods/methods-for-training/',
                {'country': 'ZW', 'training_type': training_type}
            )
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(len(response.data['payment_methods']), 3)
            self.assertEqual(response.data['instant_access_method'], 'card')
    
    def test_supported_countries_endpoint(self):
        """Test GET /api/v1/payments/methods/supported-countries/ endpoint"""
        response = self.client.get(
            '/api/v1/payments/methods/supported-countries/'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data['supported_countries']), 6)
        
        # Verify Zimbabwe is in list
        zw = next(
            (c for c in response.data['supported_countries'] if c['code'] == 'ZW'),
            None
        )
        self.assertIsNotNone(zw)


class SmatPayExclusivityTests(TestCase):
    """Test SmatPay exclusivity for card payments"""
    
    def test_card_payment_never_routes_to_flutterwave(self):
        """Verify card payment is never routed to Flutterwave"""
        provider = PaymentRoutingService.get_payment_provider(
            country_code='ZW',
            payment_method='card'
        )
        
        self.assertNotEqual(provider.lower(), 'flutterwave')
    
    def test_card_payment_never_routes_to_paystack(self):
        """Verify card payment is never routed to Paystack"""
        provider = PaymentRoutingService.get_payment_provider(
            country_code='NG',  # Nigeria where Paystack is available
            payment_method='card'
        )
        
        self.assertNotEqual(provider.lower(), 'paystack')
    
    def test_card_payment_never_routes_to_stripe(self):
        """Verify card payment is never routed to Stripe"""
        for country in ['ZW', 'ZA', 'KE']:
            provider = PaymentRoutingService.get_payment_provider(
                country_code=country,
                payment_method='card'
            )
            
            self.assertNotEqual(provider.lower(), 'stripe')
    
    def test_smatpay_is_only_card_provider_all_countries(self):
        """Test SmatPay is the only card provider for all configured countries"""
        for country in ['ZW', 'ZA', 'KE', 'TZ', 'NG', 'UG']:
            provider = PaymentRoutingService.get_payment_provider(
                country_code=country,
                payment_method='card'
            )
            
            self.assertEqual(provider.lower(), 'smatpay')


class TrainingTypePaymentFlowTests(TestCase):
    """Test payment flows for all 4 training types"""
    
    def test_masterclass_has_all_payment_options(self):
        """Test Masterclass has card, EFT, and cash options"""
        methods = PaymentRoutingService.get_available_payment_methods(
            country_code='ZW',
            training_type='masterclass'
        )
        
        method_codes = [m['method'] for m in methods]
        self.assertIn('card', method_codes)
        self.assertIn('eft', method_codes)
        self.assertIn('cash', method_codes)
    
    def test_learnership_has_all_payment_options(self):
        """Test Learnership has card, EFT, and cash options"""
        methods = PaymentRoutingService.get_available_payment_methods(
            country_code='ZW',
            training_type='learnership'
        )
        
        method_codes = [m['method'] for m in methods]
        self.assertIn('card', method_codes)
        self.assertIn('eft', method_codes)
        self.assertIn('cash', method_codes)
    
    def test_aicerts_has_all_payment_options(self):
        """Test AI Certs has card, EFT, and cash options"""
        methods = PaymentRoutingService.get_available_payment_methods(
            country_code='ZW',
            training_type='aicerts_courses'
        )
        
        method_codes = [m['method'] for m in methods]
        self.assertIn('card', method_codes)
        self.assertIn('eft', method_codes)
        self.assertIn('cash', method_codes)
    
    def test_custom_selection_has_all_payment_options(self):
        """Test Custom Selection has card, EFT, and cash options"""
        methods = PaymentRoutingService.get_available_payment_methods(
            country_code='ZW',
            training_type='custom_selection'
        )
        
        method_codes = [m['method'] for m in methods]
        self.assertIn('card', method_codes)
        self.assertIn('eft', method_codes)
        self.assertIn('cash', method_codes)
