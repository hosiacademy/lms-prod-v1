# apps/payments/management/commands/test_payment_providers.py
"""
Django management command to test payment provider configurations.

Usage:
    python manage.py test_payment_providers
    python manage.py test_payment_providers --provider=paystack
    python manage.py test_payment_providers --full
"""

from django.core.management.base import BaseCommand, CommandError
from django.conf import settings
from django.contrib.auth import get_user_model
from apps.payments.services.payment_service import PaymentService
from apps.payments.models import PaymentTransaction, Order
from apps.payments.adapters import get_adapter, PaymentError
import sys
from decimal import Decimal

User = get_user_model()


class Command(BaseCommand):
    help = 'Test payment provider configurations'

    def add_arguments(self, parser):
        parser.add_argument(
            '--provider',
            type=str,
            help='Test specific provider (e.g., paystack, stripe, mpesa)',
        )
        parser.add_argument(
            '--full',
            action='store_true',
            help='Run full integration tests (creates test transactions)',
        )
        parser.add_argument(
            '--country',
            type=str,
            default='NG',
            help='Country code for testing (default: NG)',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('\n=== Payment Provider Configuration Test ===\n'))

        provider = options.get('provider')
        full_test = options.get('full')
        country = options.get('country')

        # Test environment variables
        self.test_environment_variables(provider)

        # Test provider connectivity
        self.test_provider_connectivity(provider, country)

        # Full integration tests
        if full_test:
            self.stdout.write(self.style.WARNING('\n--- Running Full Integration Tests ---'))
            self.run_integration_tests(provider, country)

        self.stdout.write(self.style.SUCCESS('\n✅ All tests completed!'))

    def test_environment_variables(self, provider=None):
        """Test that required environment variables are set"""
        self.stdout.write(self.style.WARNING('\n--- Testing Environment Variables ---'))

        providers_config = {
            'stripe': {
                'vars': ['STRIPE_SECRET_KEY', 'STRIPE_PUBLIC_KEY', 'STRIPE_WEBHOOK_SECRET'],
                'optional': []
            },
            'paystack': {
                'vars': ['PAYSTACK_SECRET_KEY', 'PAYSTACK_PUBLIC_KEY', 'PAYSTACK_WEBHOOK_SECRET'],
                'optional': []
            },
            'flutterwave': {
                'vars': ['FLUTTERWAVE_SECRET_KEY', 'FLUTTERWAVE_PUBLIC_KEY', 'FLUTTERWAVE_ENCRYPTION_KEY'],
                'optional': ['FLUTTERWAVE_WEBHOOK_SECRET']
            },
            'mpesa': {
                'vars': ['MPESA_CONSUMER_KEY', 'MPESA_CONSUMER_SECRET', 'MPESA_BUSINESS_SHORTCODE', 'MPESA_PASSKEY'],
                'optional': ['MPESA_CALLBACK_URL']
            },
            'mtn_momo': {
                'vars': ['MTN_MOMO_SUBSCRIPTION_KEY', 'MTN_MOMO_API_USER', 'MTN_MOMO_API_KEY'],
                'optional': []
            },
            'orange_money': {
                'vars': ['ORANGE_MONEY_CLIENT_ID', 'ORANGE_MONEY_CLIENT_SECRET'],
                'optional': ['ORANGE_MONEY_MERCHANT_KEY']
            },
        }

        providers_to_test = [provider] if provider else providers_config.keys()

        all_passed = True
        for prov in providers_to_test:
            if prov not in providers_config:
                continue

            config = providers_config[prov]
            self.stdout.write(f'\n{prov.upper()}:')

            for var in config['vars']:
                value = getattr(settings, var, None)
                if value and value != 'your_key_here' and not value.startswith('xxxx'):
                    self.stdout.write(self.style.SUCCESS(f'  ✓ {var}: Configured'))
                else:
                    self.stdout.write(self.style.ERROR(f'  ✗ {var}: Missing or invalid'))
                    all_passed = False

            for var in config['optional']:
                value = getattr(settings, var, None)
                if value:
                    self.stdout.write(self.style.SUCCESS(f'  ✓ {var}: Configured (optional)'))
                else:
                    self.stdout.write(self.style.WARNING(f'  ! {var}: Not configured (optional)'))

        return all_passed

    def test_provider_connectivity(self, provider=None, country='NG'):
        """Test connectivity to payment providers"""
        self.stdout.write(self.style.WARNING('\n--- Testing Provider Connectivity ---'))

        payment_service = PaymentService()

        # Test getting available providers
        try:
            providers = payment_service.get_available_providers(
                country=country,
                amount=100.0,
                currency='USD'
            )

            if providers:
                self.stdout.write(self.style.SUCCESS(f'\n✓ Found {len(providers)} available providers for {country}:'))
                for prov in providers:
                    self.stdout.write(f"  - {prov['name']} ({prov['code']})")
                    self.stdout.write(f"    Methods: {', '.join(prov['methods'][:3])}")
                    self.stdout.write(f"    Fee: {prov['fee_percentage']}%")
            else:
                self.stdout.write(self.style.WARNING(f'! No providers available for {country}'))

        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Error getting providers: {str(e)}'))

    def run_integration_tests(self, provider=None, country='NG'):
        """Run full integration tests with test transactions"""
        self.stdout.write(self.style.WARNING('\n⚠️  Creating test transactions...'))

        # Get or create test user
        test_user, created = User.objects.get_or_create(
            email='test.payment@hosi.africa',
            defaults={
                'username': 'test.payment@hosi.africa',
                'first_name': 'Test',
                'last_name': 'User',
            }
        )

        if created:
            self.stdout.write(f'Created test user: {test_user.email}')

        # Create test order
        order = Order.objects.create(
            user=test_user,
            tracking=f'TEST-ORDER-{int(timezone.now().timestamp())}',
            amount=Decimal('100.00'),
            currency='USD',
            status='pending',
        )

        self.stdout.write(f'Created test order: {order.tracking}')

        payment_service = PaymentService()

        # Test providers
        providers_to_test = [provider] if provider else ['paystack', 'stripe']

        for prov in providers_to_test:
            self.test_payment_initiation(payment_service, test_user, prov, country)

    def test_payment_initiation(self, payment_service, user, provider, country):
        """Test payment initiation for a specific provider"""
        self.stdout.write(f'\n--- Testing {provider.upper()} ---')

        try:
            # Test payment initiation
            result = payment_service.initiate_payment(
                user=user,
                amount=100.0,
                currency='USD',
                country=country,
                provider_code=provider,
                description='Test payment',
                metadata={'test': True},
            )

            transaction = result['transaction']

            self.stdout.write(self.style.SUCCESS(f'✓ Payment initiated successfully'))
            self.stdout.write(f'  Transaction ID: {transaction.id}')
            self.stdout.write(f'  Provider Reference: {transaction.provider_reference}')
            self.stdout.write(f'  Status: {transaction.status}')

            if result.get('checkout_url'):
                self.stdout.write(f'  Checkout URL: {result["checkout_url"][:50]}...')

            if result.get('requires_redirect'):
                self.stdout.write('  ℹ️  Requires redirect to complete payment')

            if result.get('requires_stk_push'):
                self.stdout.write('  ℹ️  Requires STK push approval')

            # Test payment verification
            self.stdout.write('\n  Testing payment verification...')
            verification = payment_service.verify_payment(str(transaction.id))

            self.stdout.write(self.style.SUCCESS(f'  ✓ Verification successful'))
            self.stdout.write(f'    Current status: {verification["transaction"].status}')

        except PaymentError as e:
            self.stdout.write(self.style.ERROR(f'✗ Payment error: {str(e)}'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Unexpected error: {str(e)}'))
            import traceback
            self.stdout.write(traceback.format_exc())
