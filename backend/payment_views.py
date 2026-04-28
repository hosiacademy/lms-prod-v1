"""
Payment Views - REST API Endpoints for Payment Processing
"""

import json
import logging
from decimal import Decimal
from datetime import datetime

from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from payment_integration_service import PaymentIntegrationService, WebhookHandler
from payments_config import (
    PAYMENT_PROVIDERS, get_provider_for_country, 
    get_enabled_providers, PAYMENT_FEES
)

logger = logging.getLogger(__name__)


# ============================================================================
# PAYMENT INITIATION VIEWS
# ============================================================================

class InitiatePaymentView(APIView):
    """
    Initiate payment with specified provider
    
    POST /api/payments/initiate/
    {
        "provider": "flutterwave",
        "amount": 5000.00,
        "email": "student@example.com",
        "phone": "+2348012345678",
        "enrollment_id": "1234",
        "country": "NG"
    }
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            data = request.data
            provider = data.get('provider', '').lower()
            amount = float(data.get('amount', 0))
            email = data.get('email')
            phone = data.get('phone')
            enrollment_id = data.get('enrollment_id')
            country = data.get('country', 'NG')
            
            # Validate input
            if not all([provider, amount, email, enrollment_id]):
                return Response(
                    {'error': 'Missing required fields'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if amount <= 0:
                return Response(
                    {'error': 'Invalid amount'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Initialize service
            service = PaymentIntegrationService()
            
            # Route to appropriate provider
            if provider == 'flutterwave':
                result = service.initiate_flutterwave_payment(
                    user_id=str(request.user.id),
                    amount=amount,
                    email=email,
                    phone=phone,
                    enrollment_id=enrollment_id,
                    country=country
                )
            
            elif provider == 'paystack':
                result = service.initiate_paystack_payment(
                    user_id=str(request.user.id),
                    amount=amount,
                    email=email,
                    enrollment_id=enrollment_id,
                    country=country
                )
            
            elif provider == 'stripe':
                currency = data.get('currency', 'USD')
                result = service.initiate_stripe_payment(
                    user_id=str(request.user.id),
                    amount=amount,
                    email=email,
                    enrollment_id=enrollment_id,
                    currency=currency
                )
            
            elif provider == 'mpesa':
                result = service.initiate_mpesa_payment(
                    phone=phone,
                    amount=amount,
                    enrollment_id=enrollment_id
                )
            
            elif provider == 'mtn_momo':
                result = service.initiate_mtn_momo_payment(
                    phone=phone,
                    amount=amount,
                    enrollment_id=enrollment_id,
                    country=country
                )
            
            elif provider == 'orange_money':
                result = service.initiate_orange_money_payment(
                    phone=phone,
                    amount=amount,
                    enrollment_id=enrollment_id,
                    country=country
                )
            
            else:
                return Response(
                    {'error': f'Unsupported provider: {provider}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if result.get('success'):
                # Log payment initiation
                logger.info(f"Payment initiated: {provider} - Enrollment {enrollment_id}")
                return Response(result, status=status.HTTP_200_OK)
            else:
                logger.error(f"Payment initiation failed: {result.get('error')}")
                return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            logger.error(f"Payment initiation error: {str(e)}")
            return Response(
                {'error': f'Payment service error: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AvailableProvidersView(APIView):
    """
    Get available payment providers for country
    
    GET /api/payments/providers/?country=NG
    """
    
    def get(self, request):
        try:
            country = request.query_params.get('country', 'NG')
            
            # Get all enabled providers
            providers = []
            for provider_code, config in PAYMENT_PROVIDERS.items():
                if config.get('enabled'):
                    # Check if provider supports country
                    supports_country = False
                    
                    if 'supported_countries' in config:
                        supports_country = country.upper() in config['supported_countries']
                    else:
                        # Global providers (Stripe) support all countries
                        supports_country = True
                    
                    if supports_country:
                        providers.append({
                            'code': provider_code,
                            'name': config['name'],
                            'fee_percentage': PAYMENT_FEES.get(provider_code, {}).get('standard', 0),
                            'supported_currencies': config.get('supported_currencies', ['NGN', 'USD']),
                        })
            
            return Response({
                'country': country,
                'providers': providers
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error fetching providers: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ProviderDetailView(APIView):
    """
    Get details for a specific payment provider
    
    GET /api/payments/providers/flutterwave/
    """
    
    def get(self, request, provider):
        try:
            provider_lower = provider.lower()
            config = PAYMENT_PROVIDERS.get(provider_lower)
            
            if not config or not config.get('enabled'):
                return Response(
                    {'error': 'Provider not found or disabled'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            return Response({
                'code': provider_lower,
                'name': config['name'],
                'supported_countries': config.get('supported_countries', []),
                'supported_currencies': config.get('supported_currencies', []),
                'fees': PAYMENT_FEES.get(provider_lower, {}),
                'sandbox_mode': config.get('sandbox', True),
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error fetching provider details: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ============================================================================
# PAYMENT VERIFICATION VIEWS
# ============================================================================

class VerifyPaymentView(APIView):
    """
    Verify payment status
    
    GET /api/payments/verify/reference_id/
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request, transaction_id):
        try:
            service = PaymentIntegrationService()
            provider = request.query_params.get('provider', 'flutterwave')
            
            result = service.get_payment_status(provider, transaction_id)
            
            return Response(result, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Payment verification error: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ============================================================================
# WEBHOOK HANDLERS
# ============================================================================

@csrf_exempt
@require_http_methods(["POST"])
def provider_webhook(request, provider_code=None):
    """
    Generic webhook handler for all payment providers
    Routes to specific provider handler
    """
    try:
        # Extract provider code from URL
        if not provider_code:
            path_parts = request.path.split('/')
            provider_code = path_parts[-2] if len(path_parts) > 1 else None
        
        if not provider_code:
            return JsonResponse({'error': 'Provider not specified'}, status=400)
        
        provider_code = provider_code.lower().replace('-', '_')
        payload = json.loads(request.body)
        
        # Get signature header (varies by provider)
        signature = (
            request.headers.get('Verif-Hash') or  # Flutterwave
            request.headers.get('x-paystack-signature') or  # Paystack
            request.headers.get('Stripe-Signature') or  # Stripe
            request.headers.get('X-Reference-Id')  # MTN MoMo
        )
        
        handler = WebhookHandler()
        
        # Route to provider-specific handler
        if provider_code == 'flutterwave':
            success, message = handler.service.handle_flutterwave_webhook(payload, signature)
        elif provider_code == 'paystack':
            success, message = handler.service.handle_paystack_webhook(payload, signature)
        elif provider_code == 'stripe':
            success, message = handler.service.handle_stripe_webhook(payload, signature)
        else:
            return JsonResponse({'status': 'unknown provider'}, status=400)
        
        if success:
            logger.info(f"Webhook processed successfully: {provider_code}")
            return JsonResponse({'status': 'success', 'message': message}, status=200)
        else:
            logger.warning(f"Webhook processing failed: {provider_code} - {message}")
            return JsonResponse({'status': 'failed', 'message': message}, status=400)
        
    except json.JSONDecodeError:
        logger.error("Invalid JSON in webhook payload")
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        logger.error(f"Webhook error: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
@require_http_methods(["POST"])
def country_webhook(request, provider_code, country_code):
    """
    Country-specific webhook handler
    Useful for providers with country-specific handling
    """
    request.provider_code = provider_code
    request.country_code = country_code
    return provider_webhook(request, provider_code)


# ============================================================================
# TEST ENDPOINTS (Development Only)
# ============================================================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_test_credentials(request):
    """
    Get test credentials for payment providers (Development only)
    
    GET /api/payments/test/credentials/?provider=flutterwave
    """
    if not settings.DEBUG:
        return Response(
            {'error': 'Not available in production'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    provider = request.query_params.get('provider', 'flutterwave')
    service = PaymentIntegrationService(test_mode=True)
    
    credentials = service.get_test_credentials(provider)
    
    return Response(credentials, status=status.HTTP_200_OK)


@api_view(['GET'])
def health_check(request):
    """
    Health check endpoint for payment system

    GET /api/payments/health/
    """
    return Response({
        'status': 'healthy',
        'providers': get_enabled_providers(),
        'test_mode': PAYMENT_PROVIDERS['flutterwave'].get('sandbox', True),
    }, status=status.HTTP_200_OK)


# ============================================================================
# EFT PAYMENT VIEWS
# ============================================================================

class SubmitEFTBankDetailsView(APIView):
    """
    Submit customer's bank account details for EFT payment
    
    POST /api/v1/payments/eft/submit-bank-details/
    {
        "reference": "HOS-12345",
        "bank_name": "KCB Bank",
        "account_holder": "John Doe",
        "account_number": "1234567890",
        "branch_code": "UNIVERSAL"
    }
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            data = request.data
            reference = data.get('reference')
            bank_name = data.get('bank_name')
            account_holder = data.get('account_holder')
            account_number = data.get('account_number')
            branch_code = data.get('branch_code', 'UNIVERSAL')
            
            # Validate required fields
            if not all([reference, bank_name, account_holder, account_number]):
                return Response(
                    {'error': 'Missing required fields: reference, bank_name, account_holder, account_number'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Find the payment transaction
            from apps.payments.models import PaymentTransaction
            transaction = PaymentTransaction.objects.filter(
                provider_reference=reference
            ).first()
            
            if not transaction:
                # Try by order_id if provider_reference not found
                transaction = PaymentTransaction.objects.filter(
                    order_id=reference
                ).first()
            
            if not transaction:
                return Response(
                    {'error': f'Payment transaction not found for reference: {reference}'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Update transaction metadata with customer bank details
            if not transaction.metadata:
                transaction.metadata = {}
            
            transaction.metadata['customer_bank_details'] = {
                'bank_name': bank_name,
                'account_holder': account_holder,
                'account_number': account_number,
                'branch_code': branch_code,
                'submitted_at': datetime.now().isoformat(),
            }
            transaction.save()
            
            logger.info(f"EFT bank details submitted for transaction {reference}")
            
            return Response({
                'success': True,
                'message': 'Bank details submitted successfully',
                'reference': reference,
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"EFT bank details submission error: {str(e)}")
            return Response(
                {'error': f'Server error: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ============================================================================
# PAYMENT CALLBACK VIEWS (Post-payment redirects from providers)
# ============================================================================

class PaymentSuccessCallbackView(APIView):
    """
    Success callback after user completes payment at provider
    """
    
    def get(self, request):
        try:
            reference_id = request.query_params.get('ref')
            session_id = request.query_params.get('session_id')
            
            if not reference_id and not session_id:
                return Response(
                    {'error': 'No payment reference provided'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Log successful callback
            logger.info(f"Payment success callback received - Ref: {reference_id}, Session: {session_id}")
            
            return Response({
                'status': 'success',
                'message': 'Payment processing',
                'reference': reference_id or session_id
            })
            
        except Exception as e:
            logger.error(f"Success callback error: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PaymentFailureCallbackView(APIView):
    """
    Failure callback after payment fails at provider
    """
    
    def get(self, request):
        try:
            reference_id = request.query_params.get('ref')
            reason = request.query_params.get('reason', 'Unknown')
            
            logger.warning(f"Payment failure callback - Ref: {reference_id}, Reason: {reason}")
            
            return Response({
                'status': 'failed',
                'message': f'Payment failed: {reason}',
                'reference': reference_id
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Failure callback error: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
