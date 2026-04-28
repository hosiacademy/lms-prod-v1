# apps/payments/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.viewsets import ModelViewSet
from django.shortcuts import get_object_or_404
from django.conf import settings
from .models import Order, PaymentTransaction, Cart
from .serializers import OrderSerializer
from .services.payment_service import payment_service


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
    """Get available payment providers for a country"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        country = request.query_params.get('country')
        amount = request.query_params.get('amount')
        currency = request.query_params.get('currency')
        
        if not country:
            return Response(
                {'error': 'Country parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            providers = payment_service.get_available_providers(
                country=country,
                amount=float(amount) if amount else None,
                currency=currency
            )
            return Response(providers)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class InitiatePaymentView(APIView):
    """Initiate a payment"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        # Extract required fields
        data = request.data
        
        required_fields = ['amount', 'currency', 'country', 'provider']
        for field in required_fields:
            if field not in data:
                return Response(
                    {'error': f'{field} is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        try:
            result = payment_service.initiate_payment(
                user=request.user,
                amount=float(data['amount']),
                currency=data['currency'],
                country=data['country'],
                provider_code=data['provider'],
                description=data.get('description', ''),
                metadata=data.get('metadata', {}),
                callback_url=data.get('callback_url'),
                redirect_url=data.get('redirect_url'),
                ip_address=request.META.get('REMOTE_ADDR'),
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
            )
            
            return Response(result)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class VerifyPaymentView(APIView):
    """Verify payment status"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request, transaction_id):
        try:
            result = payment_service.verify_payment(transaction_id)
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