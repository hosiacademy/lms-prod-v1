# backend/apps/payments/views/payment_methods_views.py
"""
API endpoints for payment method selection and routing.

Implements unified payment flow across all training types:
- Masterclass
- Learnership  
- AI Certs Courses
- Custom Selection

Routes all card payments through SmatPay exclusively.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from django.conf import settings
import logging

from ..services.payment_routing_service import (
    PaymentRoutingService,
    PaymentMethod,
    COUNTRY_PAYMENT_CONFIG
)

logger = logging.getLogger(__name__)


class AvailablePaymentMethodsView(APIView):
    """
    GET /api/v1/payments/methods/?country=ZW&training_type=masterclass
    
    Returns available payment methods for a country and training type.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        country_code = request.query_params.get('country', '').upper()
        training_type = request.query_params.get('training_type')
        
        if not country_code:
            return Response({
                'error': 'country parameter is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            methods = PaymentRoutingService.get_available_payment_methods(
                country_code=country_code,
                training_type=training_type
            )
            
            if not methods:
                return Response({
                    'error': f'No payment methods available for country {country_code}'
                }, status=status.HTTP_404_NOT_FOUND)
            
            return Response({
                'country': country_code,
                'training_type': training_type,
                'methods': methods,
                'currency': COUNTRY_PAYMENT_CONFIG.get(country_code, {}).get('currency', 'USD'),
            })
        
        except Exception as e:
            logger.error(f"Error getting payment methods: {str(e)}")
            return Response({
                'error': 'Failed to retrieve payment methods'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PaymentMethodValidationView(APIView):
    """
    POST /api/v1/payments/validate-method/
    
    Validate if a payment method is available for a country/training type.
    
    Request body:
    {
      "country": "ZW",
      "payment_method": "card",
      "training_type": "masterclass"
    }
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        country_code = request.data.get('country', '').upper()
        payment_method = request.data.get('payment_method', '').lower()
        training_type = request.data.get('training_type')
        
        if not country_code or not payment_method:
            return Response({
                'error': 'country and payment_method are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            is_valid, error_message = PaymentRoutingService.validate_payment_method(
                country_code=country_code,
                payment_method=payment_method,
                training_type=training_type
            )
            
            if is_valid:
                provider = PaymentRoutingService.get_payment_provider(
                    country_code=country_code,
                    payment_method=payment_method
                )
                return Response({
                    'valid': True,
                    'country': country_code,
                    'payment_method': payment_method,
                    'provider': provider,
                    'training_type': training_type,
                })
            else:
                return Response({
                    'valid': False,
                    'error': error_message,
                    'country': country_code,
                    'payment_method': payment_method,
                }, status=status.HTTP_400_BAD_REQUEST)
        
        except Exception as e:
            logger.error(f"Validation error: {str(e)}")
            return Response({
                'error': 'Validation failed'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PaymentRoutingView(APIView):
    """
    GET /api/v1/payments/routing/?country=ZW&method=card
    
    Get payment routing information for a specific country and payment method.
    Returns the provider code and configuration.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        country_code = request.query_params.get('country', '').upper()
        payment_method = request.query_params.get('method', '').lower()
        
        if not country_code or not payment_method:
            return Response({
                'error': 'country and method parameters are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            provider = PaymentRoutingService.get_payment_provider(
                country_code=country_code,
                payment_method=payment_method
            )
            
            if not provider:
                return Response({
                    'error': f'No provider configured for {country_code} / {payment_method}'
                }, status=status.HTTP_404_NOT_FOUND)
            
            country_config = PaymentRoutingService.get_country_config(country_code)
            method_config = country_config['payment_methods'].get(PaymentMethod(payment_method))
            
            return Response({
                'country': country_code,
                'method': payment_method,
                'provider': provider,
                'provider_config': method_config,
                'country_currency': country_config.get('currency', 'USD'),
            })
        
        except Exception as e:
            logger.error(f"Routing error: {str(e)}")
            return Response({
                'error': 'Failed to get routing information'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CountryPaymentConfigView(APIView):
    """
    GET /api/v1/payments/country-config/?country=ZW
    
    Get complete payment configuration for a country.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        country_code = request.query_params.get('country', '').upper()
        
        if not country_code:
            return Response({
                'error': 'country parameter is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            config = PaymentRoutingService.get_country_config(country_code)
            
            if not config:
                return Response({
                    'error': f'Country {country_code} not configured'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Format payment methods for response
            formatted_methods = {}
            for method, method_config in config['payment_methods'].items():
                formatted_methods[method.value] = {
                    'provider': method_config['provider'].value,
                    'description': method_config['description'],
                    'card_types': method_config.get('card_types'),
                    'enabled': method_config.get('enabled', True),
                    'locations': method_config.get('locations'),
                }
            
            return Response({
                'country': country_code,
                'country_name': config['name'],
                'currency': config['currency'],
                'payment_methods': formatted_methods,
            })
        
        except Exception as e:
            logger.error(f"Config error: {str(e)}")
            return Response({
                'error': 'Failed to get country configuration'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class SmatPayCardGatewayInfoView(APIView):
    """
    GET /api/v1/payments/smatpay-info/?country=ZW
    
    Get SmatPay card gateway information for a country.
    Confirms SmatPay is the exclusive card provider.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        country_code = request.query_params.get('country', '').upper()
        
        if not country_code:
            return Response({
                'error': 'country parameter is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Check if card payment is available
            is_valid, error = PaymentRoutingService.validate_payment_method(
                country_code=country_code,
                payment_method='card'
            )
            
            if not is_valid:
                return Response({
                    'error': error
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Get provider (should be smatpay)
            provider = PaymentRoutingService.get_payment_provider(
                country_code=country_code,
                payment_method='card'
            )
            
            # Get methods for country
            methods = PaymentRoutingService.get_available_payment_methods(
                country_code=country_code
            )
            card_method = next((m for m in methods if m['method'] == 'card'), None)
            
            return Response({
                'country': country_code,
                'card_provider': provider,
                'is_exclusive': provider == 'smatpay',
                'card_types': card_method.get('card_types', []) if card_method else [],
                'description': card_method.get('description', '') if card_method else '',
                'enabled': card_method.get('enabled', True) if card_method else False,
            })
        
        except Exception as e:
            logger.error(f"SmatPay info error: {str(e)}")
            return Response({
                'error': 'Failed to get SmatPay information'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ============================================================================
# Convenience Functions for Template/Frontend Usage
# ============================================================================

@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def get_payment_methods_for_training(request):
    """
    GET /api/v1/payments/methods-for-training/?country=ZW&training_type=masterclass
    
    Convenience endpoint that returns payment methods for a specific training type.
    """
    country = request.query_params.get('country', '').upper()
    training_type = request.query_params.get('training_type', '')
    
    if not country:
        return Response({'error': 'country is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    if not training_type:
        return Response({'error': 'training_type is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        methods = PaymentRoutingService.get_available_payment_methods(
            country_code=country,
            training_type=training_type
        )
        
        return Response({
            'country': country,
            'training_type': training_type,
            'payment_methods': methods,
            'instant_access_method': PaymentRoutingService.get_instant_access_method(training_type),
        })
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return Response({'error': 'Failed to retrieve payment methods'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def get_all_supported_countries(request):
    """
    GET /api/v1/payments/supported-countries/
    
    Returns list of all supported countries and their configurations.
    """
    try:
        countries = []
        for country_code, config in COUNTRY_PAYMENT_CONFIG.items():
            countries.append({
                'code': country_code,
                'name': config['name'],
                'currency': config['currency'],
                'payment_methods': list(config['payment_methods'].keys()),
            })
        
        return Response({
            'supported_countries': countries,
            'total': len(countries),
        })
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return Response({'error': 'Failed to retrieve countries'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
