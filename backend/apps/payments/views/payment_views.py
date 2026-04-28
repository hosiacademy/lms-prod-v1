# apps/payments/views/payment_views.py
import logging
import requests
from typing import Dict
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.viewsets import ModelViewSet
from django.shortcuts import get_object_or_404
from django.conf import settings
from ..services.payment_service import payment_service
from ..services.geolocation_service import geo_location_service, GeolocationService
from apps.users.models import User
import uuid
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, permission_classes
from ..models import Order, PaymentTransaction, Cart, PaymentStatus
from ..serializers import OrderSerializer, PaymentTransactionSerializer

logger = logging.getLogger(__name__)


class DetectLocationView(APIView):
    """
    GET /api/v1/payments/detect-location/

    Detect user's country and currency based on IP address.
    Properly extracts client IP from X-Forwarded-For header when behind proxy/nginx.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        try:
            # CRITICAL FIX: Extract actual client IP from X-Forwarded-For header
            # When behind nginx/proxy, REMOTE_ADDR is the proxy IP, not client IP
            client_ip = GeolocationService.get_client_ip(request)

            logger.info(f"Detect location for client IP: {client_ip}")

            # Get country code from client IP
            country_code = geo_location_service.get_country_from_ip(client_ip)

            # Get currency from country code
            currency_code = GeolocationService.get_currency_from_country(
                country_code or 'ZA'  # Default to South Africa instead of Zimbabwe
            )

            # Get full location data
            location_data = GeolocationService.get_location_from_request(request)

            logger.info(f"Detected: country={country_code}, currency={currency_code}, client_ip={client_ip}")

            return Response({
                'country_code': country_code or 'ZA',
                'currency': currency_code,
                'city': location_data.get('city'),
                'region': location_data.get('region'),
                'ip': client_ip
            })
        except Exception as e:
            logger.error(f"Error detecting location: {str(e)}")
            return Response({
                'country_code': 'ZA',  # Default to South Africa
                'currency': 'ZAR',     # Default to ZAR instead of USD
                'error': str(e),
                'ip': client_ip if 'client_ip' in locals() else 'unknown'
            })


class ExchangeRatesView(APIView):
    """
    GET /api/v1/payments/exchange-rates/
    
    Returns exchange rates for all African currencies relative to USD.
    Rates are fetched from external API and cached.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        try:
            # Fetch live exchange rates from external API
            response = requests.get(
                'https://api.exchangerate-api.com/v4/latest/USD',
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                rates = data.get('rates', {})
                
                # Filter to African currencies only
                african_currencies = {
                    'ZAR', 'KES', 'NGN', 'GHS', 'EGP', 'TZS', 'UGX', 'ETB',
                    'RWF', 'ZMW', 'XOF', 'XAF', 'MAD', 'DZD', 'TND', 'MZN',
                    'BWP', 'NAD', 'AOA', 'MWK', 'USD', 'GBP', 'EUR'
                }
                
                filtered_rates = {
                    k: v for k, v in rates.items() 
                    if k in african_currencies
                }
                
                # Calculate expires_at (24 hours from now)
                expires_at = timezone.now() + timezone.timedelta(hours=24)
                
                return Response({
                    'base': 'USD',
                    'rates': filtered_rates,
                    'timestamp': timezone.now().isoformat(),
                    'expires_at': expires_at.isoformat(),
                })
            else:
                # Return fallback rates
                return Response({
                    'base': 'USD',
                    'rates': self._get_fallback_rates(),
                    'timestamp': timezone.now().isoformat(),
                    'error': 'Failed to fetch live rates',
                })
        except Exception as e:
            logger.error(f"Error fetching exchange rates: {str(e)}")
            return Response({
                'base': 'USD',
                'rates': self._get_fallback_rates(),
                'error': str(e),
            })
    
    def _get_fallback_rates(self) -> Dict[str, float]:
        """Fallback exchange rates when API is unavailable"""
        return {
            'USD': 1.0,
            'ZAR': 18.50,  # South African Rand
            'KES': 129.00,  # Kenyan Shilling
            'NGN': 1550.00,  # Nigerian Naira
            'GHS': 15.50,  # Ghanaian Cedi
            'EGP': 49.00,  # Egyptian Pound
            'TZS': 2500.00,  # Tanzanian Shilling
            'UGX': 3700.00,  # Ugandan Shilling
            'ETB': 125.00,  # Ethiopian Birr
            'RWF': 1350.00,  # Rwandan Franc
            'ZMW': 27.00,  # Zambian Kwacha
            'XOF': 605.00,  # West African CFA Franc
            'XAF': 605.00,  # Central African CFA Franc
            'MAD': 10.00,  # Moroccan Dirham
            'DZD': 134.00,  # Algerian Dinar
            'TND': 3.10,  # Tunisian Dinar
            'MZN': 64.00,  # Mozambican Metical
            'BWP': 13.50,  # Botswana Pula
            'NAD': 18.50,  # Namibian Dollar
            'AOA': 850.00,  # Angolan Kwanza
            'MWK': 1730.00,  # Malawian Kwacha
            'GBP': 0.79,  # British Pound
            'EUR': 0.92,  # Euro
        }


class OrderViewSet(ModelViewSet):
    """CRUD operations for Orders"""
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Users can only see their own orders
        return self.queryset.filter(user=self.request.user)


class CreateOrderView(APIView):
    """Create a new order from cart"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        # Get user's cart
        cart = Cart.objects.filter(user=request.user).first()
        if not cart:
            return Response(
                {'error': 'No cart found'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create order from cart
        order = Order.objects.create(
            user=request.user,
            total_amount=cart.total_amount,
            currency=cart.currency or 'USD',
            payment_method='pending',
            status='pending',
            metadata={'cart_id': str(cart.id)}
        )
        
        # Clear cart after order creation
        cart.items.all().delete()
        
        return Response(
            OrderSerializer(order).data,
            status=status.HTTP_201_CREATED
        )


class PaymentInitiateView(APIView):
    """Initiate payment for an order"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, order_id):
        order = get_object_or_404(Order, id=order_id, user=request.user)
        
        # Create payment transaction
        transaction = PaymentTransaction.objects.create(
            user=request.user,
            amount=order.total_amount,
            currency='USD',  # Default, adjust as needed
            payment_method=request.data.get('payment_method', 'card'),
            status='pending'
        )
        
        # Here you would integrate with payment gateway
        # For now, return a placeholder response
        
        return Response({
            'order_id': order.id,
            'transaction_id': transaction.transaction_id,
            'amount': order.total_amount,
            'status': 'payment_initiated',
            'message': 'Redirect user to payment gateway'
        })


# === Views for urls.py ===

class AvailableProvidersView(APIView):
    """Get available payment providers, auto-detected by country from IP"""
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        amount = request.query_params.get('amount')
        
        # --- Country resolution (IP-based if not provided) ---
        country = request.query_params.get('country')
        auto_detected = False
        
        if not country:
            country = GeolocationService.get_country_from_request(request)
            auto_detected = True
            logger.info(f"Auto-detected country from IP: {country}")

        country = country.upper()
        
        # --- Currency resolution ---
        currency = request.query_params.get('currency')
        if not currency:
            currency = GeolocationService.get_currency_from_country(country)
        
        try:
            providers = payment_service.get_available_providers(
                country=country,
                amount=float(amount) if amount else None,
                currency=currency
            )
            return Response({
                'detected_country': country,
                'detected_currency': currency,
                'auto_detected': auto_detected,
                'available_providers': providers,
                'count': len(providers),
            })
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class InitiatePaymentView(APIView):
    """Initiate a payment"""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        # Extract required fields
        data = request.data

        # 1. Handle anonymous users (common in enrollment wizard)
        user = request.user
        if not user or not user.is_authenticated:
            try:
                # Try to identify user from metadata/payload
                metadata = data.get('metadata', {})
                details = metadata.get('individual_details') or metadata.get('corporate_details')
                email = None
                
                # Check multiple locations for email
                if details:
                    email = details.get('email') or details.get('contact_email')
                if not email:
                    email = data.get('email') or metadata.get('email')
                if not email:
                    individual = metadata.get('individual_details', {})
                    email = individual.get('email')

                if email:
                    user, created = User.objects.get_or_create(
                        email=email.lower(),
                        defaults={
                            'username': email.lower(),
                            'name': details.get('full_name') or details.get('company_name') or 'Student',
                        }
                    )
            except Exception as e:
                logger.warning(f"Could not identify/create anonymous user: {str(e)}")
                # Continue as anonymous, the service might handle it or fail gracefully
                pass

        # 2. Check if this is the "Stage 1" call (reference request) or "Stage 2" (initiate with provider)
        if 'provider' not in data and 'provider_code' not in data:
            # Frontend is just asking for a reference to track this enrollment
            enrollment_ref = f"ENR-{uuid.uuid4().hex[:8].upper()}"
            return Response({
                'reference': enrollment_ref,
                'status': 'reference_generated',
                'description': 'Payment reference generated for enrollment'
            })

        # 3. Stage 2: Normal Initiation
        required_fields = ['amount', 'currency', 'country']
        for field in required_fields:
            if field not in data:
                return Response(
                    {'error': f'{field} is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        provider_code = data.get('provider') or data.get('provider_code')
        if not provider_code:
             return Response(
                {'error': 'provider is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 4. Validate provider-specific requirements
        # Check if provider requires phone number (for STK Push like M-Pesa)
        stk_push_providers = ['mpesa', 'airtel_money', 'mtn_momo', 'orange_money', 'wave', 'telebirr']
        if provider_code in stk_push_providers:
            # Try to get phone number from metadata
            metadata = data.get('metadata', {})
            phone_number = (
                data.get('phone_number') or
                metadata.get('phone_number') or
                metadata.get('individual_details', {}).get('phone') or
                metadata.get('corporate_details', {}).get('contact_phone')
            )
            
            if not phone_number:
                return Response({
                    'error': f'Phone number required for {provider_code} payment',
                    'error_code': 'PHONE_NUMBER_REQUIRED',
                    'provider': provider_code,
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Add phone number to metadata for the payment service
            data['metadata'] = metadata
            data['metadata']['phone_number'] = phone_number

        # Ensure email is in metadata for payment service
        if data.get('email') and 'email' not in data.get('metadata', {}):
            if not data.get('metadata'):
                data['metadata'] = {}
            data['metadata']['email'] = data['email']

        # PAYMENT ROUTING VALIDATION (NEW)
        # Enforce SmatPay exclusivity for card payments and validate routing
        try:
            from ..services.payment_routing_service import PaymentRoutingService
            
            payment_method = data.get('payment_method', 'card').lower()
            country = data.get('country', '').upper()
            metadata = data.get('metadata', {})
            training_type = metadata.get('training_type')
            
            # Validate payment method is available for country/training type
            is_valid, error = PaymentRoutingService.validate_payment_method(
                country_code=country,
                payment_method=payment_method,
                training_type=training_type
            )
            
            if not is_valid:
                logger.warning(
                    f"Payment method validation failed. Country: {country}, "
                    f"Method: {payment_method}, Error: {error}"
                )
                return Response({
                    'error': error,
                    'error_code': 'INVALID_PAYMENT_METHOD',
                    'country': country,
                    'payment_method': payment_method,
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get correct provider from routing
            correct_provider = PaymentRoutingService.get_payment_provider(
                country_code=country,
                payment_method=payment_method
            )
            
            # Enforce SmatPay for card payments (security check)
            if payment_method == 'card' and provider_code.lower() != 'smatpay':
                logger.warning(
                    f"SECURITY: Card payment attempt with non-SmatPay provider. "
                    f"User: {user.id if user and user.is_authenticated else 'anonymous'}, "
                    f"Requested: {provider_code}, Enforcing: smatpay"
                )
                # Auto-correct to SmatPay for security
                provider_code = 'smatpay'
                return Response({
                    'warning': 'Card payments must use SmatPay. Payment method corrected.',
                    'provider': 'smatpay',
                    'country': country,
                    'payment_method': payment_method,
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Verify provider matches routing
            if provider_code.lower() != correct_provider.lower():
                logger.info(
                    f"Provider mismatch detected. Correcting from {provider_code} to {correct_provider}"
                )
                # Show error instead of auto-correcting to make problem visible
                return Response({
                    'error': f'Provider {provider_code} not configured for {payment_method} payment in {country}',
                    'error_code': 'PROVIDER_NOT_AVAILABLE',
                    'correct_provider': correct_provider,
                    'country': country,
                    'payment_method': payment_method,
                }, status=status.HTTP_400_BAD_REQUEST)
        
        except ImportError:
            logger.warning("PaymentRoutingService import failed, skipping validation")
        except Exception as e:
            logger.error(f"Payment routing validation error: {str(e)}")
            # Don't block payment if routing validation has issues, log and continue
            pass

        try:
            result = payment_service.initiate_payment(
                user=user if (user and user.is_authenticated) else None,
                amount=float(data['amount']),
                currency=data['currency'],
                country=data['country'],
                provider_code=provider_code,
                description=data.get('description', ''),
                metadata=data.get('metadata', {}),
                callback_url=data.get('callback_url'),
                redirect_url=data.get('redirect_url'),
                ip_address=request.META.get('REMOTE_ADDR'),
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                phone_number=data.get('metadata', {}).get('phone_number'),
            )

            # 4. Serialize the transaction object before returning
            if 'transaction' in result and result['transaction']:
                serializer = PaymentTransactionSerializer(result['transaction'])
                result['transaction'] = serializer.data

            # Add helpful flags for frontend
            result['provider_code'] = provider_code
            if provider_code in stk_push_providers:
                result['requires_stk_push'] = True
                result['stk_push_message'] = f'Check your phone to complete payment'

            return Response(result)
        except Exception as e:
            logger.error(f"Payment initiation failed: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class VerifyPaymentView(APIView):
    """Verify payment status"""
    permission_classes = [permissions.AllowAny]
    
    def get(self, request, transaction_id):
        try:
            result = payment_service.verify_payment(transaction_id)
            
            # Serialize the transaction object
            if 'transaction' in result and result['transaction']:
                from ..serializers import PaymentTransactionSerializer
                serializer = PaymentTransactionSerializer(result['transaction'])
                result['transaction'] = serializer.data
                
            return Response(result)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class PaymentCallbackView(APIView):
    """Handle payment callback from provider"""
    permission_classes = []  # Public endpoint
    
    def get(self, request, transaction_id):
        try:
            # Find transaction
            transaction = PaymentTransaction.objects.get(id=transaction_id)
            
            # Verify payment
            result = payment_service.verify_payment(str(transaction.id))
            
            # Redirect to frontend or show success page
            redirect_url = transaction.redirect_url or \
                         f"{getattr(settings, 'FRONTEND_URL', '')}/payment/success?transaction={transaction_id}"
            
            return Response({
                'status': 'success',
                'transaction': {
                    'id': str(transaction.id),
                    'status': transaction.status,
                    'amount': transaction.amount,
                    'currency': transaction.currency,
                },
                'redirect_url': redirect_url,
            })
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class RefundPaymentView(APIView):
    """Process refund for a payment"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, transaction_id):
        data = request.data
        
        try:
            result = payment_service.refund_payment(
                transaction_id=transaction_id,
                amount=float(data.get('amount')) if data.get('amount') else None,
                reason=data.get('reason', '')
            )
            return Response(result)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

@csrf_exempt
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def simulate_payment_success(request, transaction_id):
    """
    POST /api/payments/simulate-success/{transaction_id}/
    
    Simulate a successful payment for a transaction in sandbox mode.
    Supports looking up by Transaction ID or Enrollment Code (ENR-...).
    """
    try:
        # Search for transaction by ID or enrollment code in metadata/field
        if str(transaction_id).startswith('ENR-'):
            transaction = get_object_or_404(PaymentTransaction, metadata__enrollment_code=transaction_id)
        elif str(transaction_id).isdigit():
            transaction = get_object_or_404(PaymentTransaction, id=transaction_id)
        else:
            # Try as provider reference
            transaction = PaymentTransaction.objects.filter(provider_reference=transaction_id).first()
            if not transaction:
                # Last resort: try checking metadata for any match
                transaction = PaymentTransaction.objects.filter(metadata__enrollment_code=transaction_id).first()
            
            if not transaction:
                return Response({'error': 'Transaction not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Security check: Only allow simulation if the transaction or provider is in sandbox mode
        is_sandbox = False
        if transaction.provider_config:
            is_sandbox = getattr(transaction.provider_config, 'is_sandbox', True)
        
        if not is_sandbox and not settings.DEBUG:
            return Response({
                'error': 'Simulation only allowed in sandbox mode or debug mode'
            }, status=status.HTTP_403_FORBIDDEN)
            
        if transaction.status == PaymentStatus.SUCCESSFUL:
            return Response({
                'message': 'Transaction already successful',
                'status': transaction.status
            })

        # Update transaction status
        transaction.status = PaymentStatus.SUCCESSFUL
        transaction.completed_at = timezone.now()
        transaction.metadata['simulated'] = True
        transaction.metadata['simulated_at'] = timezone.now().isoformat()
        transaction.save()
        
        # Trigger post-payment actions
        payment_service._handle_successful_payment(transaction)
        
        logger.info(f"Simulated payment success for transaction {transaction.id}")
        
        return Response({
            'status': 'success',
            'message': 'Payment simulation successful',
            'transaction_id': str(transaction.id)
        })
        
    except Exception as e:
        logger.error(f"Payment simulation failed: {str(e)}", exc_info=True)
        return Response({
            'error': f'Simulation failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
