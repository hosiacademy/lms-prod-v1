# apps/payments/views/payment_provider_views.py
"""
Payment Provider Views with IP-based detection.

Handles:
- Country detection from IP address
- Available payment methods by country
- Payment provider sandbox configurations
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework import status
from django.conf import settings
import logging
from ..services.payment_service import payment_service

from ..models import PaymentProviderModel, ProviderPaymentMethod, CountryPaymentLandscape, ProviderCountryConfig
from ..serializers import (
    PaymentProviderSerializer,
    ProviderPaymentMethodSerializer,
    CountryPaymentLandscapeSerializer
)

logger = logging.getLogger(__name__)


class DetectLocationView(APIView):
    """
    Detect user's country from IP address.
    
    GET /api/v1/payments/detect-location/
    
    Returns:
    {
        "country_code": "KE",
        "country_name": "Kenya",
        "currency": "KES",
        "ip_address": "105.27.123.45"
    }
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        ip_address = self.get_client_ip(request)
        country_code = self.detect_country_from_ip(ip_address)
        
        # Get currency for detected country
        currency = self.get_currency_for_country(country_code)
        country_name = self.get_country_name(country_code)
        
        return Response({
            'country_code': country_code,
            'country_name': country_name,
            'currency': currency,
            'ip_address': ip_address,
        })
    
    def get_client_ip(self, request):
        """Get client IP address from request"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    def detect_country_from_ip(self, ip_address):
        """Detect country from IP using GeoIP2 database"""
        try:
            import geoip2.database
            reader = geoip2.database.Reader('/app/GeoLite2-Country.mmdb')
            response = reader.country(ip_address)
            return response.country.iso_code
        except Exception as e:
            logger.warning(f"GeoIP detection failed for {ip_address}: {e}")
            return 'ZW'  # Default to Zimbabwe
    
    def get_currency_for_country(self, country_code):
        """Get currency code for country"""
        currency_map = {
            'KE': 'KES',
            'ZW': 'USD',
            'ZA': 'ZAR',
            'NG': 'NGN',
            'GH': 'GHS',
            'TZ': 'TZS',
            'UG': 'UGX',
            'RW': 'RWF',
            'ZM': 'ZMW',
            'MW': 'MWK',
            'MZ': 'MZN',
            'BW': 'BWP',
            'NA': 'NAD',
            'SZ': 'SZL',
            'LS': 'LSL',
        }
        return currency_map.get(country_code, 'USD')
    
    def get_country_name(self, country_code):
        """Get country name from code"""
        country_names = {
            'KE': 'Kenya',
            'ZW': 'Zimbabwe',
            'ZA': 'South Africa',
            'NG': 'Nigeria',
            'GH': 'Ghana',
            'TZ': 'Tanzania',
            'UG': 'Uganda',
            'RW': 'Rwanda',
            'ZM': 'Zambia',
            'MW': 'Malawi',
            'MZ': 'Mozambique',
            'BW': 'Botswana',
            'NA': 'Namibia',
            'SZ': 'Eswatini',
            'LS': 'Lesotho',
        }
        return country_names.get(country_code, 'Unknown')


class GetAvailablePaymentProvidersView(APIView):
    """
    Get available payment providers based on country.
    
    GET /api/v1/payments/providers/?country=KE&amount=500&currency=USD
    
    Returns:
    {
        "detected_country": "KE",
        "providers": [
            {
                "id": 1,
                "name": "M-Pesa",
                "type": "mobile_money",
                "sandbox_mode": true,
                "test_credentials": {...}
            },
            ...
        ],
        "payment_methods": [...]
    }
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        country_code = request.query_params.get('country', 'ZW')
        amount = request.query_params.get('amount')
        currency = request.query_params.get('currency', 'USD')

        # Use PaymentService to get providers (it handles global fallbacks like SmatPay)
        providers_list = payment_service.get_available_providers(
            country=country_code,
            amount=float(amount) if amount else None,
            currency=currency
        )
        
        # Get payment methods for providers
        provider_codes = [p['code'] for p in providers_list]
        payment_methods = ProviderPaymentMethod.objects.filter(
            provider__code__in=provider_codes,
            is_active=True
        )
        
        return Response({
            'detected_country': country_code,
            'amount': amount,
            'currency': currency,
            'available_providers': providers_list, # Key used by frontend
            'providers': providers_list, # Backward compatibility
            'payment_methods': ProviderPaymentMethodSerializer(payment_methods, many=True).data,
        })
    
    def get_sandbox_config(self, provider_code, country_code):
        """Get sandbox configuration for payment provider"""
        sandbox_configs = {
            'mpesa': {
                'sandbox_url': 'https://sandbox.safaricom.co.ke/',
                'test_phone': '+254708374166',
                'test_pin': '1234',
            },
            'ecocash': {
                'sandbox_url': 'https://pssg.ecocash.co.zw/test/',
                'test_phone': '+263771234567',
                'test_pin': '1234',
            },
            'yoco': {
                'sandbox_url': 'https://online.yoco.com/',
                'test_card': {
                    'number': '4111 1111 1111 1111',
                    'cvv': '123',
                    'expiry': '12/25',
                },
            },
            'flutterwave': {
                'sandbox_url': 'https://api.flutterwave.com/v3/',
                'test_card': {
                    'number': '5531 8866 5214 2950',
                    'cvv': '019',
                    'expiry': '09/32',
                },
            },
            'paynow': {
                'sandbox_url': 'https://sandbox.paynow.co.zw/',
                'test_phone': '+263771234567',
            },
        }
        return sandbox_configs.get(provider_code, {})


class GetProvidersByCategoryView(APIView):
    """
    Get payment providers filtered by category.

    GET /api/v1/payments/providers-by-category/?country=KE&category=card&amount=5000&currency=KES

    Categories: card, mobile_money, eft, qr, cash

    Returns providers sorted by:
    1. Recommended providers first (priority order)
    2. Active providers with better rates
    3. Includes country-specific fees and methods
    """
    permission_classes = [AllowAny]

    def get(self, request):
        country_code = request.query_params.get('country', 'ZW')
        category = request.query_params.get('category', 'card')
        amount = request.query_params.get('amount')
        currency = request.query_params.get('currency', 'USD')

        # Map frontend categories to backend categories
        category_mapping = {
            'card': ['aggregator', 'international', 'local_gateway'],
            'mobile_money': ['mobile_money'],
            'eft': ['bank_api'],
            'qr': ['pos_qr'],
            'cash': ['manual'],
        }

        backend_categories = category_mapping.get(category, [])

        # Get country payment landscape for recommended providers
        try:
            landscape = CountryPaymentLandscape.objects.get(country_code=country_code)
            recommended_providers = landscape.recommended_providers or []
        except CountryPaymentLandscape.DoesNotExist:
            recommended_providers = []

        # Get provider configs for this country with fees
        provider_configs = ProviderCountryConfig.objects.filter(
            country=country_code,
            is_active=True
        ).select_related('provider')

        # Filter by category and build response with priority sorting
        providers_data = []
        for config in provider_configs:
            provider = config.provider
            # Check if provider matches category
            if provider.category not in backend_categories:
                continue

            provider_data = PaymentProviderSerializer(provider).data
            # Add country-specific configuration
            provider_data['is_recommended'] = provider.code in recommended_providers
            provider_data['priority'] = provider.priority if provider.priority else 999
            provider_data['fee_percentage'] = float(config.fee_percentage)
            provider_data['fixed_fee'] = float(config.fixed_fee)
            provider_data['min_amount'] = float(config.min_amount) if config.min_amount else 0
            provider_data['max_amount'] = float(config.max_amount) if config.max_amount else 999999
            provider_data['supported_currencies'] = config.supported_currencies or []
            provider_data['supported_methods'] = config.supported_methods or []
            provider_data['is_sandbox'] = config.is_sandbox

            providers_data.append(provider_data)

        # Sort: recommended first (by priority), then by fee percentage
        providers_data.sort(key=lambda p: (
            0 if p['is_recommended'] else 1,
            p['priority'],
            p['fee_percentage']
        ))

        return Response({
            'country': country_code,
            'category': category,
            'providers': providers_data,
            'landscape': {
                'dominant_methods': landscape.dominant_methods if landscape else [],
                'mobile_money_penetration': landscape.mobile_money_penetration if landscape else 0,
                'card_penetration': landscape.card_penetration if landscape else 0,
            } if landscape else None,
        })


class PaymentSandboxConfigView(APIView):
    """
    Get payment sandbox configurations for testing.
    
    GET /api/v1/payments/sandbox-configs/
    
    Returns all sandbox credentials and test data for payment providers.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        if not user.is_staff:
            return Response({
                'error': 'Admin access required'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Complete sandbox configurations for all African countries
        sandbox_configs = {
            'kenya': {
                'country_code': 'KE',
                'currency': 'KES',
                'providers': {
                    'mpesa': {
                        'name': 'M-Pesa',
                        'type': 'mobile_money',
                        'sandbox_url': 'https://sandbox.safaricom.co.ke/',
                        'credentials': {
                            'consumer_key': 'YOUR_MPESA_CONSUMER_KEY',
                            'consumer_secret': 'YOUR_MPESA_CONSUMER_SECRET',
                            'shortcode': '174379',
                            'passkey': 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919',
                        },
                        'test_data': {
                            'phone': '+254708374166',
                            'pin': '1234',
                            'amount': 1000,
                        },
                        'stk_push_endpoint': '/mpesa/stkpush/v1/processrequest',
                    },
                    'airtel_money': {
                        'name': 'Airtel Money',
                        'type': 'mobile_money',
                        'sandbox_url': 'https://sandbox.airtelmoney.co.ke/',
                        'test_data': {
                            'phone': '+254708374167',
                            'pin': '1234',
                        },
                    },
                    'flutterwave': {
                        'name': 'Flutterwave',
                        'type': 'card',
                        'sandbox_url': 'https://api.flutterwave.com/v3/',
                        'credentials': {
                            'public_key': 'FLWPUBK_TEST-XXXXX-X',
                            'secret_key': 'FLWSECK_TEST-XXXXX-X',
                        },
                        'test_card': {
                            'number': '5531 8866 5214 2950',
                            'cvv': '019',
                            'expiry': '09/32',
                            'name': 'Test User',
                        },
                    },
                },
            },
            'zimbabwe': {
                'country_code': 'ZW',
                'currency': 'USD',
                'providers': {
                    'ecocash': {
                        'name': 'EcoCash',
                        'type': 'mobile_money',
                        'sandbox_url': 'https://pssg.ecocash.co.zw/test/',
                        'credentials': {
                            'merchant_code': 'TEST_MERCHANT',
                            'api_key': 'TEST_API_KEY',
                        },
                        'test_data': {
                            'phone': '+263771234567',
                            'pin': '1234',
                        },
                    },
                    'paynow': {
                        'name': 'Paynow',
                        'type': 'card',
                        'sandbox_url': 'https://sandbox.paynow.co.zw/',
                        'credentials': {
                            'integration_id': 'TEST_ID',
                            'integration_key': 'TEST_KEY',
                        },
                        'test_data': {
                            'phone': '+263771234567',
                        },
                    },
                },
            },
            'south_africa': {
                'country_code': 'ZA',
                'currency': 'ZAR',
                'providers': {
                    'yoco': {
                        'name': 'Yoco',
                        'type': 'card',
                        'sandbox_url': 'https://online.yoco.com/',
                        'credentials': {
                            'secret_key': 'sk_test_YOUR_TEST_KEY',
                            'public_key': 'pk_test_YOUR_PUBLIC_KEY',
                        },
                        'test_card': {
                            'number': '4111 1111 1111 1111',
                            'cvv': '123',
                            'expiry': '12/25',
                            'name': 'Test User',
                        },
                    },
                    'payfast': {
                        'name': 'PayFast',
                        'type': 'card',
                        'sandbox_url': 'https://sandbox.payfast.co.za/',
                        'credentials': {
                            'merchant_id': '10000100',
                            'merchant_key': '46f0cd694581a',
                            'passphrase': 'test',
                        },
                    },
                },
            },
            'nigeria': {
                'country_code': 'NG',
                'currency': 'NGN',
                'providers': {
                    'paystack': {
                        'name': 'Paystack',
                        'type': 'card',
                        'sandbox_url': 'https://api.paystack.co/',
                        'credentials': {
                            'public_key': 'pk_test_YOUR_KEY',
                            'secret_key': 'sk_test_YOUR_KEY',
                        },
                        'test_card': {
                            'number': '4111 1111 1111 1111',
                            'cvv': '123',
                            'expiry': '12/25',
                        },
                    },
                    'flutterwave': {
                        'name': 'Flutterwave',
                        'type': 'card',
                        'sandbox_url': 'https://api.flutterwave.com/v3/',
                        'test_card': {
                            'number': '5531 8866 5214 2950',
                            'cvv': '019',
                            'expiry': '09/32',
                        },
                    },
                },
            },
        }
        
        return Response({
            'sandbox_configs': sandbox_configs,
            'note': 'These are test credentials. Replace with actual sandbox credentials in production.',
        })
