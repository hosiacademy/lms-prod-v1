import logging
from rest_framework import views, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.shortcuts import get_object_or_404
from ..models import Order, PaymentTransaction, ProviderCountryConfig
from ..services.payment_service import PaymentService, PaymentError

logger = logging.getLogger(__name__)

class InitiatePaymentView(views.APIView):
    """
    POST /api/payments/initiate/

    Initiate payment with a provider.
    Body:
        - order_id: Order tracking ID (required)
        - provider_code: Payment provider code (required)
        - payment_method: Payment method (optional: card, mobile_money, etc.)
        - phone_number: Phone number for mobile money (optional)
        - redirect_url: URL to redirect after payment (optional)
        - metadata: Additional metadata (optional)
    """
    permission_classes = [AllowAny]

    def _get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip

    def post(self, request):
        try:
            order_id = request.data.get('order_id') or request.data.get('reference')
            provider_code = request.data.get('provider') or request.data.get('provider_code')
            payment_method = request.data.get('payment_method', 'card')
            phone_number = request.data.get('phone_number')
            redirect_url = request.data.get('redirect_url')
            metadata = request.data.get('metadata', {})

            # ✅ Handle generic card payment - use SmatPay as the card gateway
            if provider_code in ('generic_card', 'flutterwave', 'payfast', 'paystack', 'stripe', 'peach', 'ozow', 'yoco', 'dpo'):
                provider_code = 'smatpay'
                payment_method = 'card'

            # === GUEST USER HANDLING ===
            user = request.user
            if not (user and user.is_authenticated):
                # Check for user details in metadata
                individual_details = metadata.get('individual_details')
                corporate_details = metadata.get('corporate_details')
                
                email = request.data.get('email') or metadata.get('email')
                if not email:
                    if individual_details:
                        email = individual_details.get('email')
                    elif corporate_details:
                        email = corporate_details.get('contact_email')
                
                if email:
                    from django.contrib.auth import get_user_model
                    User = get_user_model()
                    try:
                        user = User.objects.get(email=email.lower())
                    except User.DoesNotExist:
                        # Create provisional user
                        username = email.lower()
                        user = User.objects.create_user(username=username, email=email.lower())
                        if individual_details and 'full_name' in individual_details:
                             names = individual_details['full_name'].split(' ', 1)
                             user.first_name = names[0]
                             if len(names) > 1:
                                 user.last_name = names[1]
                        user.save()
                else:
                    # If we still don't have a user, payment_service might handle anonymous or fail
                    user = None

            # === ORDER CREATION (If order_id is missing) ===
            if not order_id:
                program_id = request.data.get('program_id')
                amount_raw = request.data.get('amount')  # This is LOCALIZED amount from frontend
                currency = request.data.get('currency', 'USD')

                if program_id and amount_raw is not None:
                    # CRITICAL: Get the USD price from the training item, not the localized amount
                    from django.contrib.contenttypes.models import ContentType
                    enrollment_type = metadata.get('enrollment_type', 'masterclass')
                    
                    # Map enrollment type to model
                    model_map = {
                        'masterclass': ('masterclasses', 'Masterclass'),
                        'learnership': ('learnerships', 'LearnershipProgramme'),
                        'industry_training': ('industry_based_training', 'AiCertsCourse'),
                        'role_training': ('industry_based_training', 'Offering'),
                    }
                    
                    app_label, model_name = model_map.get(enrollment_type, ('masterclasses', 'Masterclass'))
                    content_type = ContentType.objects.get(app_label=app_label, model=model_name.lower())
                    model_class = content_type.model_class()
                    
                    try:
                        training_item = model_class.objects.get(pk=program_id)
                        # Get the USD price based on the training type
                        if enrollment_type == 'masterclass':
                            # Masterclass has price_physical and price_online
                            usd_amount = float(getattr(training_item, 'price_online', 0) or getattr(training_item, 'price_physical', 0))
                        elif enrollment_type == 'learnership':
                            # Learnership has cost_usd
                            usd_amount = float(getattr(training_item, 'cost_usd', 0))
                        elif enrollment_type in ('industry_training', 'role_training'):
                            # Industry training has price_usd
                            usd_amount = float(getattr(training_item, 'price_usd', 0))
                        else:
                            # Fallback to price or cost_usd
                            usd_amount = float(getattr(training_item, 'price', getattr(training_item, 'cost_usd', 0)))
                        
                        logger.info(f"Order Creation: {enrollment_type} ID {program_id} - USD Price: ${usd_amount}, Localized: {amount_raw} {currency}")
                    except Exception as e:
                        logger.error(f"Could not fetch USD price for {enrollment_type} {program_id}: {e}")
                        # Fallback to localized amount if we can't get USD
                        usd_amount = float(amount_raw)
                    
                    import uuid
                    tracking_id = f"ORD-{uuid.uuid4().hex[:12].upper()}"
                    
                    enrollment_metadata = {
                        'enrollment_type': enrollment_type,
                        'program_id': program_id,
                        'amount_usd': usd_amount,  # Store the USD price for SmatPay
                        **metadata
                    }

                    order = Order.objects.create(
                        user=user,
                        tracking=tracking_id,
                        amount=usd_amount,  # EXACT backend USD amount - what customer pays
                        currency='USD',
                        status='pending',
                        metadata=enrollment_metadata
                    )
                    order_id = order.tracking

                    if not provider_code:
                        return Response({
                            'reference': order.tracking,
                            'order_id': order.tracking,
                            'amount': float(order.amount),
                            'currency': order.currency,
                            'status': order.status,
                        }, status=status.HTTP_201_CREATED)
                else:
                    return Response({
                        'error': 'order_id or (program_id and amount) is required'
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get existing order
            try:
                # If user is None, we might search by tracking only if system allows
                if user:
                    order = Order.objects.get(tracking=order_id, user=user)
                else:
                    order = Order.objects.get(tracking=order_id)
            except Order.DoesNotExist:
                return Response({
                    'error': 'Order not found'
                }, status=status.HTTP_404_NOT_FOUND)

            if order.status == 'completed':
                return Response({
                    'error': 'Order already paid',
                    'order_id': order.tracking
                }, status=status.HTTP_400_BAD_REQUEST)

            country = request.data.get('country') or order.metadata.get('country') or 'ZA'
            enrollment_type = metadata.get('enrollment_type') or order.metadata.get('enrollment_type', 'masterclass')
            is_corporate = metadata.get('is_corporate') or order.metadata.get('is_corporate', False)

            # CRITICAL FIX: For card payments (SmatPay), use USD amount from metadata
            # Check if order has amount_usd in metadata (for card payments)
            if provider_code == 'smatpay' and order.metadata.get('amount_usd'):
                final_amount = order.metadata.get('amount_usd')
                payment_currency = 'USD'
                logger.info(f"SmatPay Payment: Using USD amount ${final_amount} from order metadata")
            else:
                # For other payment methods (EFT, etc.), use localized amount
                final_amount = round(float(order.amount))
                payment_currency = order.currency
            
            ps = PaymentService()
            result = ps.initiate_payment(
                user=user,
                amount=float(final_amount),
                currency=payment_currency,
                country=country,
                provider_code=provider_code,
                description=f"Payment for order {order.tracking}",
                metadata={
                    **metadata,
                    'order_id': order.id,
                    'order_tracking': order.tracking,
                    'enrollment_type': enrollment_type,
                    'amount_usd': final_amount if payment_currency == 'USD' else None,
                },
                payment_method=payment_method,
                phone_number=phone_number,
                redirect_url=redirect_url,
                ip_address=self._get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
            )

            transaction = result['transaction']
            order.payment_method = provider_code
            order.status = 'processing'
            order.save()

            return Response({
                'reference': str(transaction.id),
                'transaction_id': str(transaction.id),
                'provider_reference': transaction.provider_reference,
                'checkout_url': result.get('checkout_url'),
                'requires_redirect': result.get('requires_redirect', False),
                'requires_stk_push': result.get('requires_stk_push', False),
                'status': transaction.status,
                'amount': float(transaction.amount),
                'currency': transaction.currency,
                'provider': transaction.provider,
                'additional_data': result.get('additional_data', {}),
            }, status=status.HTTP_201_CREATED)

        except PaymentError as e:
            logger.error(f"Payment initiation failed: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Unexpected error: {str(e)}", exc_info=True)
            return Response({'error': 'An internal error occurred'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
