"""
Unit Tests for Payment Service
Tests the core payment processing logic in payment_service.py
"""
import pytest
from unittest.mock import Mock, patch, MagicMock
from decimal import Decimal
from django.utils import timezone
from django.test import TestCase

from apps.payments.services.payment_service import PaymentService
from apps.payments.models import (
    PaymentTransaction, PaymentStatus, TransactionType,
    ProviderCountryConfig, PaymentProviderModel, Order
)
from apps.payments.adapters import PaymentError, SignatureVerificationError


@pytest.mark.unit
@pytest.mark.payment
class TestPaymentService:
    """Unit tests for PaymentService core functionality"""

    @pytest.fixture
    def payment_service(self):
        """Create payment service instance"""
        return PaymentService()

    @pytest.fixture
    def mock_user(self):
        """Mock user object"""
        user = Mock()
        user.id = 1
        user.email = 'test@example.com'
        user.username = 'testuser'
        return user

    @pytest.fixture
    def mock_provider_config(self):
        """Mock provider country config"""
        config = Mock(spec=ProviderCountryConfig)
        config.min_amount = Decimal('1.00')
        config.max_amount = Decimal('10000.00')
        config.fee_percentage = Decimal('2.5')
        config.fixed_fee = Decimal('0.00')
        config.supported_currencies = ['USD', 'ZAR']
        return config

    @pytest.fixture
    def mock_adapter(self):
        """Mock payment adapter"""
        adapter = Mock()
        adapter.get_supported_countries.return_value = ['ZA', 'KE', 'NG']
        adapter.get_supported_currencies.return_value = ['USD', 'ZAR']
        adapter.get_supported_methods.return_value = ['card', 'mobile_money']
        adapter.validate_amount.return_value = (True, 'Valid amount')
        adapter.initiate_payment.return_value = {
            'checkout_url': 'https://payment.example.com/checkout/123',
            'requires_redirect': True,
            'provider_reference': 'PROV_123456',
        }
        adapter.verify_webhook_signature.return_value = True
        adapter.parse_webhook.return_value = {
            'reference': 'PROV_123456',
            'status': 'successful',
            'event': 'payment.completed',
        }
        return adapter

    # ==================== GET AVAILABLE PROVIDERS ====================

    @patch('apps.payments.services.payment_service.PaymentProviderModel')
    @patch('apps.payments.services.payment_service.ProviderCountryConfig')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_get_available_providers_success(
        self, mock_get_adapter, mock_config_qs, mock_provider_model,
        payment_service, mock_adapter
    ):
        """Test getting available providers for a country"""
        # Setup mocks
        mock_config = Mock()
        mock_config.provider = Mock()
        mock_config.provider.code = 'flutterwave'
        mock_config.provider.name = 'Flutterwave'
        mock_config.provider.category = 'aggregator'
        mock_config.provider.is_recommended = True
        mock_config.provider.priority = 1
        mock_config.min_amount = Decimal('1.00')
        mock_config.max_amount = Decimal('10000.00')
        mock_config.fee_percentage = Decimal('2.5')
        mock_config.fixed_fee = Decimal('0.00')
        
        mock_config_qs.objects.filter.return_value.select_related.return_value = [mock_config]
        mock_get_adapter.return_value = mock_adapter

        # Call method
        providers = payment_service.get_available_providers(country='ZA', amount=100.0, currency='USD')

        # Assertions
        assert len(providers) > 0
        provider = providers[0]
        assert provider['code'] == 'flutterwave'
        assert provider['name'] == 'Flutterwave'
        assert provider['category'] == 'aggregator'
        assert provider['min_amount'] == 1.00
        assert provider['max_amount'] == 10000.00

    @patch('apps.payments.services.payment_service.ProviderCountryConfig')
    def test_get_available_providers_no_configs(
        self, mock_config_qs, payment_service
    ):
        """Test getting providers when no configs exist for country"""
        mock_config_qs.objects.filter.return_value.select_related.return_value = []

        providers = payment_service.get_available_providers(country='XX')

        assert len(providers) == 0

    @patch('apps.payments.services.payment_service.get_adapter')
    @patch('apps.payments.services.payment_service.ProviderCountryConfig')
    def test_get_available_providers_adapter_error(
        self, mock_config_qs, mock_get_adapter, payment_service, mock_config
    ):
        """Test handling adapter initialization errors"""
        mock_config_qs.objects.filter.return_value.select_related.return_value = [mock_config]
        mock_get_adapter.side_effect = Exception('Adapter init failed')

        providers = payment_service.get_available_providers(country='ZA')

        # Should skip providers with errors
        assert len(providers) == 0

    # ==================== INITIATE PAYMENT ====================

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_initiate_payment_success(
        self, mock_get_adapter, mock_transaction_model,
        payment_service, mock_user, mock_provider_config, mock_adapter
    ):
        """Test successful payment initiation"""
        # Setup mocks
        mock_get_adapter.return_value = mock_adapter
        
        mock_transaction = Mock()
        mock_transaction.id = 1
        mock_transaction.provider_reference = 'PROV_123456'
        mock_transaction_model.objects.create.return_value = mock_transaction

        # Call method
        result = payment_service.initiate_payment(
            user=mock_user,
            amount=Decimal('100.00'),
            currency='USD',
            country='ZA',
            provider_code='flutterwave',
            description='Test payment',
            metadata={'order_id': 1},
        )

        # Assertions
        assert result is not None
        assert 'transaction' in result
        assert 'checkout_url' in result
        mock_transaction_model.objects.create.assert_called_once()
        mock_adapter.initiate_payment.assert_called_once()

    @patch('apps.payments.services.payment_service.ProviderCountryConfig')
    def test_initiate_payment_provider_not_found(
        self, mock_config_qs, payment_service, mock_user
    ):
        """Test initiation when provider config not found"""
        mock_config_qs.objects.get.side_effect = ProviderCountryConfig.DoesNotExist

        with pytest.raises(PaymentError) as exc_info:
            payment_service.initiate_payment(
                user=mock_user,
                amount=Decimal('100.00'),
                currency='USD',
                country='ZA',
                provider_code='invalid_provider',
            )

        assert 'not available' in str(exc_info.value)

    @patch('apps.payments.services.payment_service.ProviderCountryConfig')
    def test_initiate_payment_amount_below_minimum(
        self, mock_config_qs, payment_service, mock_user, mock_provider_config
    ):
        """Test initiation with amount below minimum"""
        mock_config_qs.objects.get.return_value = mock_provider_config
        mock_provider_config.min_amount = Decimal('10.00')

        with pytest.raises(PaymentError) as exc_info:
            payment_service.initiate_payment(
                user=mock_user,
                amount=Decimal('5.00'),  # Below minimum
                currency='USD',
                country='ZA',
                provider_code='flutterwave',
            )

        assert 'below minimum' in str(exc_info.value)

    @patch('apps.payments.services.payment_service.ProviderCountryConfig')
    def test_initiate_payment_amount_above_maximum(
        self, mock_config_qs, payment_service, mock_user, mock_provider_config
    ):
        """Test initiation with amount above maximum"""
        mock_config_qs.objects.get.return_value = mock_provider_config
        mock_provider_config.max_amount = Decimal('1000.00')

        with pytest.raises(PaymentError) as exc_info:
            payment_service.initiate_payment(
                user=mock_user,
                amount=Decimal('5000.00'),  # Above maximum
                currency='USD',
                country='ZA',
                provider_code='flutterwave',
            )

        assert 'above maximum' in str(exc_info.value)

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_initiate_payment_adapter_validation_error(
        self, mock_get_adapter, mock_transaction_model,
        payment_service, mock_user, mock_provider_config, mock_adapter
    ):
        """Test initiation with adapter validation error"""
        mock_get_adapter.return_value = mock_adapter
        mock_adapter.validate_amount.return_value = (False, 'Invalid amount for currency')
        
        mock_transaction = Mock()
        mock_transaction_model.objects.create.return_value = mock_transaction

        with pytest.raises(PaymentError) as exc_info:
            payment_service.initiate_payment(
                user=mock_user,
                amount=Decimal('100.00'),
                currency='USD',
                country='ZA',
                provider_code='flutterwave',
            )

        assert 'Invalid amount' in str(exc_info.value)
        # Transaction should be marked as failed
        assert mock_transaction.status == PaymentStatus.FAILED

    # ==================== HANDLE WEBHOOK ====================

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_handle_webhook_success(
        self, mock_get_adapter, mock_transaction_qs,
        payment_service, mock_adapter
    ):
        """Test successful webhook processing"""
        # Setup mocks
        mock_get_adapter.return_value = mock_adapter
        
        mock_transaction = Mock()
        mock_transaction.status = PaymentStatus.PENDING
        mock_transaction.metadata = {}
        mock_transaction.provider_reference = 'PROV_123456'
        
        mock_transaction_qs.objects.select_for_update().get.return_value = mock_transaction

        payload = {
            'reference': 'PROV_123456',
            'status': 'successful',
            'event': 'payment.completed',
        }

        # Call method
        result = payment_service.handle_webhook(
            provider_code='flutterwave',
            payload=payload,
            headers={'X-Signature': 'abc123'},
        )

        # Assertions
        assert result is not None
        assert mock_transaction.status == PaymentStatus.SUCCESSFUL
        assert mock_transaction.webhook_received == True
        mock_transaction.save.assert_called()

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_handle_webhook_idempotency(
        self, mock_get_adapter, mock_transaction_qs,
        payment_service, mock_adapter
    ):
        """Test webhook idempotency - already successful transaction"""
        mock_get_adapter.return_value = mock_adapter
        
        mock_transaction = Mock()
        mock_transaction.status = PaymentStatus.SUCCESSFUL  # Already successful
        mock_transaction.metadata = {}
        
        mock_transaction_qs.objects.select_for_update().get.return_value = mock_transaction

        payload = {
            'reference': 'PROV_123456',
            'status': 'successful',
            'event': 'payment.completed',
        }

        # Call method
        result = payment_service.handle_webhook(
            provider_code='flutterwave',
            payload=payload,
            headers={'X-Signature': 'abc123'},
        )

        # Assertions
        assert result is not None
        # Should not process again, just update metadata
        assert mock_transaction.status == PaymentStatus.SUCCESSFUL

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_handle_webhook_invalid_signature(
        self, mock_get_adapter, mock_transaction_qs,
        payment_service, mock_adapter
    ):
        """Test webhook with invalid signature"""
        mock_get_adapter.return_value = mock_adapter
        mock_adapter.verify_webhook_signature.return_value = False

        payload = {'reference': 'PROV_123456'}

        with pytest.raises(SignatureVerificationError):
            payment_service.handle_webhook(
                provider_code='flutterwave',
                payload=payload,
                headers={'X-Signature': 'invalid'},
            )

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_handle_webhook_transaction_not_found(
        self, mock_get_adapter, mock_transaction_qs,
        payment_service, mock_adapter
    ):
        """Test webhook for non-existent transaction"""
        mock_get_adapter.return_value = mock_adapter
        mock_adapter.verify_webhook_signature.return_value = True
        mock_transaction_qs.objects.select_for_update().get.side_effect = PaymentTransaction.DoesNotExist

        payload = {
            'reference': 'PROV_NOT_FOUND',
            'status': 'successful',
        }

        with pytest.raises(PaymentError) as exc_info:
            payment_service.handle_webhook(
                provider_code='flutterwave',
                payload=payload,
                headers={'X-Signature': 'abc123'},
            )

        assert 'not found' in str(exc_info.value)

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_handle_webhook_failure_event(
        self, mock_get_adapter, mock_transaction_qs,
        payment_service, mock_adapter
    ):
        """Test webhook processing for failed payment"""
        mock_get_adapter.return_value = mock_adapter
        
        mock_transaction = Mock()
        mock_transaction.status = PaymentStatus.PENDING
        mock_transaction.metadata = {}
        
        mock_transaction_qs.objects.select_for_update().get.return_value = mock_transaction

        payload = {
            'reference': 'PROV_123456',
            'status': 'failed',
            'event': 'payment.failed',
        }

        # Call method
        result = payment_service.handle_webhook(
            provider_code='flutterwave',
            payload=payload,
            headers={'X-Signature': 'abc123'},
        )

        # Assertions
        assert result is not None
        assert mock_transaction.status == PaymentStatus.FAILED

    # ==================== VERIFY PAYMENT ====================

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_verify_payment_success(
        self, mock_get_adapter, mock_transaction_qs,
        payment_service, mock_adapter
    ):
        """Test payment verification"""
        mock_get_adapter.return_value = mock_adapter
        mock_adapter.verify_payment.return_value = {
            'status': PaymentStatus.SUCCESSFUL,
            'provider_data': {'verified': True},
        }

        mock_transaction = Mock()
        mock_transaction.status = PaymentStatus.PENDING
        mock_transaction.provider = 'flutterwave'
        mock_transaction.provider_reference = 'PROV_123456'
        
        mock_transaction_qs.objects.get.return_value = mock_transaction

        # Call method
        result = payment_service.verify_payment(transaction_id='123')

        # Assertions
        assert result is not None
        assert result['status'] == PaymentStatus.SUCCESSFUL
        mock_adapter.verify_payment.assert_called_once()

    # ==================== REFUND PAYMENT ====================

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    @patch('apps.payments.services.payment_service.PaymentRefund')
    @patch('apps.payments.services.payment_service.get_adapter')
    def test_refund_payment_success(
        self, mock_get_adapter, mock_refund_model, mock_transaction_qs,
        payment_service, mock_adapter
    ):
        """Test successful refund processing"""
        mock_get_adapter.return_value = mock_adapter
        mock_adapter.refund_payment.return_value = {
            'status': 'success',
            'refund_id': 'REF_123456',
            'provider_data': {'refunded': True},
        }

        mock_transaction = Mock()
        mock_transaction.status = PaymentStatus.SUCCESSFUL
        mock_transaction.amount = Decimal('100.00')
        mock_transaction.provider = 'flutterwave'
        mock_transaction.user = Mock()
        
        mock_transaction_qs.objects.get.return_value = mock_transaction

        mock_refund = Mock()
        mock_refund.refund_reference = 'REF_123456'
        mock_refund_model.objects.create.return_value = mock_refund

        # Call method
        result = payment_service.refund_payment(
            transaction_id='123',
            amount=Decimal('100.00'),
            reason='Customer request',
        )

        # Assertions
        assert result is not None
        assert 'refund' in result
        assert mock_transaction.status == PaymentStatus.REFUNDED
        mock_adapter.refund_payment.assert_called_once()

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    def test_refund_payment_not_successful(
        self, mock_transaction_qs, payment_service
    ):
        """Test refund for non-successful transaction"""
        mock_transaction = Mock()
        mock_transaction.status = PaymentStatus.PENDING  # Not successful
        
        mock_transaction_qs.objects.get.return_value = mock_transaction

        with pytest.raises(PaymentError) as exc_info:
            payment_service.refund_payment(transaction_id='123')

        assert 'Only successful transactions' in str(exc_info.value)

    @patch('apps.payments.services.payment_service.PaymentTransaction')
    def test_refund_payment_already_refunded(
        self, mock_transaction_qs, payment_service
    ):
        """Test refund for already refunded transaction"""
        mock_transaction = Mock()
        mock_transaction.status = PaymentStatus.SUCCESSFUL
        mock_transaction.metadata = {'refunded': True}  # Already refunded
        
        mock_transaction_qs.objects.get.return_value = mock_transaction

        with pytest.raises(PaymentError) as exc_info:
            payment_service.refund_payment(transaction_id='123')

        assert 'already refunded' in str(exc_info.value)

    # ==================== GENERATE REFERENCE ====================

    def test_generate_reference_format(self, payment_service):
        """Test reference generation format"""
        reference = payment_service._generate_reference('TEST')

        # Should match format: TEST_TIMESTAMP_UUID
        assert reference.startswith('TEST_')
        assert len(reference) > 10
        # Should contain only uppercase letters, numbers, and underscores
        assert all(c.isalnum() or c == '_' for c in reference)

    def test_generate_reference_unique(self, payment_service):
        """Test that generated references are unique"""
        ref1 = payment_service._generate_reference('TEST')
        ref2 = payment_service._generate_reference('TEST')

        assert ref1 != ref2

    def test_generate_reference_different_prefixes(self, payment_service):
        """Test reference generation with different prefixes"""
        ref1 = payment_service._generate_reference('PAY')
        ref2 = payment_service._generate_reference('REF')

        assert ref1.startswith('PAY_')
        assert ref2.startswith('REF_')


@pytest.mark.integration
@pytest.mark.payment
@pytest.mark.django_db
class TestPaymentServiceIntegration(TestCase):
    """Integration tests for PaymentService with database"""

    def setUp(self):
        """Set up test data"""
        self.payment_service = PaymentService()
        
        # Create test provider
        self.provider = PaymentProviderModel.objects.create(
            code='test_provider',
            name='Test Provider',
            category='aggregator',
            is_active=True,
        )

        # Create test provider country config
        self.config = ProviderCountryConfig.objects.create(
            provider=self.provider,
            country='ZA',
            is_active=True,
            min_amount=Decimal('1.00'),
            max_amount=Decimal('10000.00'),
            supported_currencies=['USD', 'ZAR'],
        )

        # Create test user
        from django.contrib.auth import get_user_model
        User = get_user_model()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
        )

        # Create test order
        self.order = Order.objects.create(
            user=self.user,
            tracking='ORD-TEST123',
            amount=Decimal('100.00'),
            currency='USD',
            status='pending',
        )

    def test_initiate_payment_creates_transaction(self):
        """Test that payment initiation creates transaction in database"""
        result = self.payment_service.initiate_payment(
            user=self.user,
            amount=Decimal('100.00'),
            currency='USD',
            country='ZA',
            provider_code='test_provider',
            metadata={'order_id': self.order.id},
        )

        # Verify transaction was created
        assert PaymentTransaction.objects.count() == 1
        transaction = PaymentTransaction.objects.first()
        assert transaction.user == self.user
        assert transaction.amount == Decimal('100.00')
        assert transaction.currency == 'USD'
        assert transaction.provider == 'test_provider'
        assert transaction.status == PaymentStatus.PENDING

    def test_webhook_updates_transaction_status(self):
        """Test that webhook processing updates transaction status"""
        # Create transaction
        transaction = PaymentTransaction.objects.create(
            user=self.user,
            order=self.order,
            amount=Decimal('100.00'),
            currency='USD',
            country='ZA',
            provider='test_provider',
            provider_reference='TEST_PROV_123',
            status=PaymentStatus.PENDING,
            metadata={},
        )

        # Mock adapter
        with patch('apps.payments.services.payment_service.get_adapter') as mock_get_adapter:
            mock_adapter = Mock()
            mock_adapter.verify_webhook_signature.return_value = True
            mock_adapter.parse_webhook.return_value = {
                'reference': 'TEST_PROV_123',
                'status': 'successful',
                'event': 'payment.completed',
            }
            mock_get_adapter.return_value = mock_adapter

            # Process webhook
            self.payment_service.handle_webhook(
                provider_code='test_provider',
                payload={'status': 'successful'},
                headers={'X-Signature': 'test'},
            )

        # Refresh from database
        transaction.refresh_from_db()

        # Verify status updated
        assert transaction.status == PaymentStatus.SUCCESSFUL
        assert transaction.webhook_received == True
