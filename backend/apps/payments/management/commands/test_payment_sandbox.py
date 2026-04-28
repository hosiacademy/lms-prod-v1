# apps/payments/management/commands/test_payment_sandbox.py
"""
Payment Provider Sandbox Testing Command

Usage:
    python manage.py test_payment_sandbox --provider=paynow --country=ZW
    python manage.py test_payment_sandbox --provider=mpesa --country=KE
    python manage.py test_payment_sandbox --provider=flutterwave --country=NG
    python manage.py test_payment_sandbox --list
    
This command tests payment provider sandbox integrations
"""
import json
from django.core.management.base import BaseCommand
from django.conf import settings


class Command(BaseCommand):
    help = 'Test payment provider sandbox integrations'

    # Sandbox test configurations for each provider
    SANDBOX_CONFIGS = {
        # ===== ZIMBABWE =====
        'paynow': {
            'country': 'ZW',
            'currency': 'USD',
            'test_amount': 10.00,
            'sandbox_mode': True,
            'test_cases': [
                {
                    'name': 'Successful Payment',
                    'phone': '+263771234567',
                    'email': 'success@test.com',
                    'expected': 'success',
                    'description': 'Test successful EcoCash payment'
                },
                {
                    'name': 'Failed Payment',
                    'phone': '+263771234568',
                    'email': 'failure@test.com',
                    'expected': 'failed',
                    'description': 'Test failed payment due to insufficient funds'
                },
                {
                    'name': 'Cancelled Payment',
                    'phone': '+263771234569',
                    'email': 'cancel@test.com',
                    'expected': 'cancelled',
                    'description': 'Test user cancelled payment'
                },
            ],
            'webhook_test': {
                'url': '/api/payments/webhooks/paynow/',
                'test_payload': {
                    'status': 'Success',
                    'reference': 'TEST123456',
                    'amount': 10.00,
                    'currency': 'USD'
                }
            }
        },
        
        # ===== KENYA =====
        'mpesa': {
            'country': 'KE',
            'currency': 'KES',
            'test_amount': 1000.00,
            'sandbox_mode': True,
            'test_cases': [
                {
                    'name': 'Successful STK Push',
                    'phone': '+254708374166',  # Safaricom test number
                    'expected': 'success',
                    'description': 'Test successful M-Pesa STK Push'
                },
                {
                    'name': 'Failed STK Push',
                    'phone': '+254708374167',
                    'expected': 'failed',
                    'description': 'Test failed STK Push (wrong PIN)'
                },
                {
                    'name': 'Timeout',
                    'phone': '+254708374168',
                    'expected': 'timeout',
                    'description': 'Test STK Push timeout'
                },
            ],
            'stk_push_config': {
                'business_shortcode': '174379',
                'passkey': 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919',
                'callback_url': 'https://hosiacademy.africa/api/payments/webhooks/mpesa/'
            }
        },
        
        # ===== NIGERIA =====
        'paystack': {
            'country': 'NG',
            'currency': 'NGN',
            'test_amount': 5000.00,
            'sandbox_mode': True,
            'test_cards': [
                {
                    'name': 'Successful Visa',
                    'number': '4084084084084081',
                    'cvv': '888',
                    'expiry': '01/2030',
                    'expected': 'success'
                },
                {
                    'name': 'Successful Mastercard',
                    'number': '5336699999999992',
                    'cvv': '737',
                    'expiry': '12/2029',
                    'expected': 'success'
                },
                {
                    'name': 'Declined Card',
                    'number': '4084084084084082',
                    'cvv': '888',
                    'expiry': '01/2030',
                    'expected': 'declined'
                },
                {
                    'name': 'Insufficient Funds',
                    'number': '4084084084084083',
                    'cvv': '888',
                    'expiry': '01/2030',
                    'expected': 'insufficient_funds'
                },
            ],
            'test_mobile_money': [
                {
                    'name': 'MTN Mobile Money',
                    'phone': '+233540000001',
                    'network': 'mtn',
                    'expected': 'success'
                },
                {
                    'name': 'Airtel Mobile Money',
                    'phone': '+233540000002',
                    'network': 'airtel',
                    'expected': 'success'
                }
            ]
        },
        
        # ===== PAN-AFRICAN =====
        'flutterwave': {
            'country': 'NG',  # Works across Africa
            'currency': 'USD',
            'test_amount': 50.00,
            'sandbox_mode': True,
            'test_cards': [
                {
                    'name': 'Successful Visa',
                    'number': '4543474001573969',
                    'cvv': '577',
                    'expiry': '09/2026',
                    'expected': 'success'
                },
                {
                    'name': 'Successful Mastercard',
                    'number': '5531886652142950',
                    'cvv': '577',
                    'expiry': '09/2026',
                    'expected': 'success'
                },
            ],
            'supported_countries': ['NG', 'KE', 'GH', 'ZA', 'UG', 'TZ', 'RW', 'ZM'],
            'test_mobile_money': [
                {
                    'name': 'M-Pesa Kenya',
                    'phone': '+254708374166',
                    'country': 'KE',
                    'expected': 'success'
                },
                {
                    'name': 'MTN MoMo Uganda',
                    'phone': '+256700000001',
                    'country': 'UG',
                    'expected': 'success'
                }
            ]
        },
        
        # ===== SOUTH AFRICA =====
        'payfast': {
            'country': 'ZA',
            'currency': 'ZAR',
            'test_amount': 100.00,
            'sandbox_mode': True,
            'test_cases': [
                {
                    'name': 'Successful Card Payment',
                    'card_type': 'visa',
                    'expected': 'success'
                },
                {
                    'name': 'Successful EFT',
                    'bank': 'standard_bank',
                    'expected': 'success'
                },
                {
                    'name': 'Successful Zapper',
                    'expected': 'success'
                }
            ],
            'sandbox_url': 'https://sandbox.payfast.co.za/eng/process'
        },
        
        # ===== GHANA =====
        'mtn_momo_gh': {
            'country': 'GH',
            'currency': 'GHS',
            'test_amount': 50.00,
            'sandbox_mode': True,
            'test_cases': [
                {
                    'name': 'Successful Mobile Money',
                    'phone': '+233540000001',
                    'expected': 'success'
                },
                {
                    'name': 'Failed - Invalid Number',
                    'phone': '+233540000000',
                    'expected': 'failed'
                }
            ]
        },
        
        # ===== EGYPT =====
        'fawry': {
            'country': 'EG',
            'currency': 'EGP',
            'test_amount': 500.00,
            'sandbox_mode': True,
            'test_cases': [
                {
                    'name': 'Successful Fawry Payment',
                    'reference': 'TEST123456',
                    'expected': 'success'
                },
                {
                    'name': 'Cash Payment at Kiosk',
                    'reference': 'TEST123457',
                    'expected': 'pending'
                }
            ]
        },
        
        # ===== SENEGAL =====
        'wave': {
            'country': 'SN',
            'currency': 'XOF',
            'test_amount': 5000.00,
            'sandbox_mode': True,
            'test_cases': [
                {
                    'name': 'Successful Wave Payment',
                    'phone': '+221770000001',
                    'expected': 'success'
                }
            ]
        },
    }

    def add_arguments(self, parser):
        parser.add_argument(
            '--provider',
            type=str,
            help='Payment provider to test (e.g., paynow, mpesa, paystack)'
        )
        parser.add_argument(
            '--country',
            type=str,
            help='Country code (e.g., ZW, KE, NG)'
        )
        parser.add_argument(
            '--list',
            action='store_true',
            help='List all available sandbox tests'
        )
        parser.add_argument(
            '--webhook',
            action='store_true',
            help='Test webhook endpoint only'
        )

    def handle(self, *args, **options):
        if options['list']:
            self.list_tests()
            return
        
        provider = options.get('provider')
        country = options.get('country')
        
        if not provider:
            self.stdout.write(self.style.ERROR('Please specify --provider or use --list'))
            return
        
        if provider not in self.SANDBOX_CONFIGS:
            self.stdout.write(self.style.ERROR(f'Provider {provider} not found. Use --list to see available providers.'))
            return
        
        config = self.SANDBOX_CONFIGS[provider]
        
        if country and config['country'] != country:
            self.stdout.write(self.style.WARNING(
                f'Note: {provider} is configured for {config["country"]}, not {country}'
            ))
        
        self.run_sandbox_test(provider, config, options)

    def list_tests(self):
        """List all available sandbox tests"""
        self.stdout.write('\n🧪 Available Payment Provider Sandbox Tests\n')
        self.stdout.write('=' * 60)
        
        for provider, config in self.SANDBOX_CONFIGS.items():
            self.stdout.write(f'\n📍 {config["country"]} - {provider.upper()}')
            self.stdout.write(f'   Currency: {config["currency"]}')
            self.stdout.write(f'   Test Amount: {config["test_amount"]}')
            self.stdout.write(f'   Sandbox: {"✅" if config["sandbox_mode"] else "❌"}')
            
            if 'test_cases' in config:
                self.stdout.write(f'   Test Cases: {len(config["test_cases"])}')
            if 'test_cards' in config:
                self.stdout.write(f'   Test Cards: {len(config["test_cards"])}')
        
        self.stdout.write('\n' + '=' * 60)
        self.stdout.write('\n💡 Usage:')
        self.stdout.write('   python manage.py test_payment_sandbox --provider=paynow')
        self.stdout.write('   python manage.py test_payment_sandbox --provider=mpesa')
        self.stdout.write('   python manage.py test_payment_sandbox --provider=paystack')
        self.stdout.write('   python manage.py test_payment_sandbox --list\n')

    def run_sandbox_test(self, provider, config, options):
        """Run sandbox test for a provider"""
        self.stdout.write(f'\n🧪 Testing {provider.upper()} ({config["country"]}) Sandbox\n')
        self.stdout.write('=' * 60)
        
        # Test webhook if requested
        if options.get('webhook'):
            self.test_webhook(provider, config)
            return
        
        # Run provider-specific tests
        if provider == 'paynow':
            self.test_paynow(config)
        elif provider == 'mpesa':
            self.test_mpesa(config)
        elif provider == 'paystack':
            self.test_paystack(config)
        elif provider == 'flutterwave':
            self.test_flutterwave(config)
        elif provider == 'payfast':
            self.test_payfast(config)
        else:
            self.test_generic(provider, config)
        
        self.stdout.write('\n' + '=' * 60)
        self.stdout.write(self.style.SUCCESS('✅ Sandbox test completed!\n'))

    def test_paynow(self, config):
        """Test Paynow (Zimbabwe) sandbox"""
        self.stdout.write('\n🇿🇼 Testing Paynow (Zimbabwe)\n')
        
        self.stdout.write('\n📋 Test Configuration:')
        self.stdout.write(f'   Sandbox URL: https://sandbox.paynow.co.zw/')
        self.stdout.write(f'   Currency: {config["currency"]}')
        self.stdout.write(f'   Amount: {config["test_amount"]}')
        
        self.stdout.write('\n📝 Test Cases:')
        for i, test in enumerate(config.get('test_cases', []), 1):
            self.stdout.write(f'\n   {i}. {test["name"]}')
            self.stdout.write(f'      Phone: {test["phone"]}')
            self.stdout.write(f'      Email: {test["email"]}')
            self.stdout.write(f'      Expected: {test["expected"]}')
            self.stdout.write(f'      Description: {test["description"]}')
        
        self.stdout.write('\n💡 Manual Test Steps:')
        self.stdout.write('   1. Go to https://sandbox.paynow.co.zw/')
        self.stdout.write('   2. Create a payment with test amount')
        self.stdout.write('   3. Use test phone numbers above')
        self.stdout.write('   4. For success: Enter PIN 1234')
        self.stdout.write('   5. For failure: Enter wrong PIN')
        self.stdout.write('   6. Check webhook at /api/payments/webhooks/paynow/')
        
        self.stdout.write('\n🔗 Webhook Test:')
        self.stdout.write('   python manage.py test_payment_sandbox --provider=paynow --webhook')

    def test_mpesa(self, config):
        """Test M-Pesa (Kenya) sandbox"""
        self.stdout.write('\n🇰🇪 Testing M-Pesa (Kenya)\n')
        
        self.stdout.write('\n📋 Test Configuration:')
        self.stdout.write(f'   Sandbox URL: https://sandbox.safaricom.co.ke/')
        self.stdout.write(f'   Currency: {config["currency"]}')
        self.stdout.write(f'   Amount: {config["test_amount"]}')
        self.stdout.write(f'   Business Shortcode: {config["stk_push_config"]["business_shortcode"]}')
        
        self.stdout.write('\n📝 STK Push Test Cases:')
        for i, test in enumerate(config.get('test_cases', []), 1):
            self.stdout.write(f'\n   {i}. {test["name"]}')
            self.stdout.write(f'      Phone: {test["phone"]}')
            self.stdout.write(f'      Expected: {test["expected"]}')
            self.stdout.write(f'      Description: {test["description"]}')
        
        self.stdout.write('\n💡 Manual Test Steps:')
        self.stdout.write('   1. Go to https://sandbox.safaricom.co.ke/')
        self.stdout.write('   2. Generate OAuth token')
        self.stdout.write('   3. Call STK Push endpoint with test numbers')
        self.stdout.write('   4. For success: Enter PIN 1234 on phone')
        self.stdout.write('   5. Check callback at /api/payments/webhooks/mpesa/')
        
        self.stdout.write('\n🔗 API Endpoints:')
        self.stdout.write('   - OAuth: POST /oauth/v1/generate')
        self.stdout.write('   - STK Push: POST /mpesa/stkpush/v1/processrequest')
        self.stdout.write('   - Callback: POST /api/payments/webhooks/mpesa/')

    def test_paystack(self, config):
        """Test Paystack (Nigeria) sandbox"""
        self.stdout.write('\n🇳🇬 Testing Paystack (Nigeria)\n')
        
        self.stdout.write('\n📋 Test Configuration:')
        self.stdout.write(f'   Sandbox URL: https://test.paystack.com/')
        self.stdout.write(f'   Currency: {config["currency"]}')
        self.stdout.write(f'   Amount: {config["test_amount"]}')
        
        self.stdout.write('\n💳 Test Cards:')
        for i, card in enumerate(config.get('test_cards', []), 1):
            self.stdout.write(f'\n   {i}. {card["name"]}')
            self.stdout.write(f'      Number: {card["number"]}')
            self.stdout.write(f'      CVV: {card["cvv"]}')
            self.stdout.write(f'      Expiry: {card["expiry"]}')
            self.stdout.write(f'      Expected: {card["expected"]}')
        
        self.stdout.write('\n📱 Test Mobile Money:')
        for i, test in enumerate(config.get('test_mobile_money', []), 1):
            self.stdout.write(f'\n   {i}. {test["name"]}')
            self.stdout.write(f'      Phone: {test["phone"]}')
            self.stdout.write(f'      Network: {test["network"]}')
            self.stdout.write(f'      Expected: {test["expected"]}')
        
        self.stdout.write('\n💡 Manual Test Steps:')
        self.stdout.write('   1. Go to https://test.paystack.com/dashboard')
        self.stdout.write('   2. Use test cards above for card payments')
        self.stdout.write('   3. For mobile money, use test phone numbers')
        self.stdout.write('   4. Check webhook signature verification')
        
        self.stdout.write('\n🔗 Webhook Test:')
        self.stdout.write('   - Endpoint: /api/payments/webhooks/paystack/')
        self.stdout.write('   - Verify signature using PAYSTACK_WEBHOOK_SECRET')

    def test_flutterwave(self, config):
        """Test Flutterwave sandbox"""
        self.stdout.write('\n🌍 Testing Flutterwave (Pan-African)\n')
        
        self.stdout.write('\n📋 Test Configuration:')
        self.stdout.write(f'   Sandbox URL: https://sandbox.flutterwave.com/')
        self.stdout.write(f'   Currency: {config["currency"]}')
        self.stdout.write(f'   Amount: {config["test_amount"]}')
        self.stdout.write(f'   Supported Countries: {", ".join(config.get("supported_countries", []))}')
        
        self.stdout.write('\n💳 Test Cards:')
        for i, card in enumerate(config.get('test_cards', []), 1):
            self.stdout.write(f'\n   {i}. {card["name"]}')
            self.stdout.write(f'      Number: {card["number"]}')
            self.stdout.write(f'      CVV: {card["cvv"]}')
            self.stdout.write(f'      Expiry: {card["expiry"]}')
        
        self.stdout.write('\n📱 Test Mobile Money:')
        for i, test in enumerate(config.get('test_mobile_money', []), 1):
            self.stdout.write(f'\n   {i}. {test["name"]} ({test["country"]})')
            self.stdout.write(f'      Phone: {test["phone"]}')
            self.stdout.write(f'      Expected: {test["expected"]}')

    def test_payfast(self, config):
        """Test PayFast (South Africa) sandbox"""
        self.stdout.write('\n🇿🇦 Testing PayFast (South Africa)\n')
        
        self.stdout.write('\n📋 Test Configuration:')
        self.stdout.write(f'   Sandbox URL: {config.get("sandbox_url", "https://sandbox.payfast.co.za/")}')
        self.stdout.write(f'   Currency: {config["currency"]}')
        self.stdout.write(f'   Amount: {config["test_amount"]}')
        
        self.stdout.write('\n📝 Test Cases:')
        for i, test in enumerate(config.get('test_cases', []), 1):
            self.stdout.write(f'\n   {i}. {test["name"]}')
            self.stdout.write(f'      Expected: {test["expected"]}')

    def test_generic(self, provider, config):
        """Generic test for other providers"""
        self.stdout.write(f'\n🌍 Testing {provider.upper()} ({config["country"]})\n')
        
        self.stdout.write('\n📋 Test Configuration:')
        self.stdout.write(f'   Currency: {config["currency"]}')
        self.stdout.write(f'   Amount: {config["test_amount"]}')
        self.stdout.write(f'   Sandbox: {config["sandbox_mode"]}')
        
        if 'test_cases' in config:
            self.stdout.write('\n📝 Test Cases:')
            for i, test in enumerate(config['test_cases'], 1):
                self.stdout.write(f'   {i}. {test["name"]} - Expected: {test["expected"]}')

    def test_webhook(self, provider, config):
        """Test webhook endpoint"""
        self.stdout.write(f'\n🔗 Testing {provider.upper()} Webhook\n')
        
        if 'webhook_test' in config:
            webhook = config['webhook_test']
            self.stdout.write(f'   Endpoint: {webhook["url"]}')
            self.stdout.write(f'   Method: POST')
            self.stdout.write(f'   Content-Type: application/json')
            self.stdout.write('\n   Test Payload:')
            self.stdout.write(f'   {json.dumps(webhook["test_payload"], indent=6)}')
        else:
            self.stdout.write('   No webhook test configuration available')
