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

    def post(self, request):
        try:
            order_id = request.data.get('order_id')
            provider_code = request.data.get('provider_code')
            payment_method = request.data.get('payment_method', 'card')
            phone_number = request.data.get('phone_number')
            redirect_url = request.data.get('redirect_url')
            metadata = request.data.get('metadata', {})

            # ✅ Handle generic card payment - use Flutterwave as default international gateway
            if provider_code == 'generic_card':
                provider_code = 'flutterwave'
                payment_method = 'card'

            # === GUEST USER HANDLING ===
            user = request.user
            if not user.is_authenticated:
                # Check for user details in metadata
                individual_details = metadata.get('individual_details')
                corporate_details = metadata.get('corporate_details')
                
                email = None
                if individual_details:
                    email = individual_details.get('email')
                elif corporate_details:
                    email = corporate_details.get('contact_email')
                
                if email:
                    from django.contrib.auth import get_user_model
                    User = get_user_model()
                    try:
                        user = User.objects.get(email=email)
                    except User.DoesNotExist:
                        # Create provisional user
                        username = email.split('@')[0]
                        # Ensure username uniqueness
                        base_username = username
                        counter = 1
                        while User.objects.filter(username=username).exists():
                            username = f"{base_username}{counter}"
                            counter += 1
                            
                        user = User.objects.create_user(username=username, email=email)
                        if individual_details and 'full_name' in individual_details:
                             names = individual_details['full_name'].split(' ', 1)
                             user.first_name = names[0]
                             if len(names) > 1:
                                 user.last_name = names[1]
                        user.save()
                else:
                    return Response({
                        'error': 'Authentication credentials were not provided and no guest email found.'
                    }, status=status.HTTP_401_UNAUTHORIZED)

            # === ORDER CREATION (If order_id is missing) ===
            if not order_id:
                # Frontend might be sending initiation data without creating order first
                program_id = request.data.get('program_id')
                amount = request.data.get('amount')
                currency = request.data.get('currency', 'USD')

                if program_id and amount is not None:
                    # Create Order on the fly
                    import uuid
                    tracking_id = f"ORD-{uuid.uuid4().hex[:12].upper()}"

                    # Try to create Enrollment key metadata
                    enrollment_metadata = {
                        'enrollment_type': metadata.get('enrollment_type', 'masterclass'),
                        'program_id': program_id,
                        **metadata
                    }

                    order = Order.objects.create(
                        user=user,
                        tracking=tracking_id,
                        amount=amount,
                        currency=currency,
                        status='pending',
                        metadata=enrollment_metadata
                    )
                    order_id = order.tracking

                    # If no provider_code supplied this is the order-creation step only.
                    # Return the order reference so the frontend can show the provider
                    # selection UI; actual payment initiation comes in the next call.
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
                        'error': 'order_id is required'
                    }, status=status.HTTP_400_BAD_REQUEST)
            else:
                # Get existing order
                try:
                    order = Order.objects.get(tracking=order_id, user=user)
                except Order.DoesNotExist:
                    return Response({
                        'error': 'Order not found'
                    }, status=status.HTTP_404_NOT_FOUND)

            # Check if order already paid
            if order.status == 'completed':
                return Response({
                    'error': 'Order already paid',
                    'order_id': order.tracking
                }, status=status.HTTP_400_BAD_REQUEST)

            # Get country from order metadata or user profile
            country = order.metadata.get('country') or getattr(user, 'country', 'KE')

            # Get enrollment info from order or request
            enrollment_type = metadata.get('enrollment_type') or order.metadata.get('enrollment_type', 'masterclass')
            is_corporate = metadata.get('is_corporate') or order.metadata.get('is_corporate', False)
            corporate_details = metadata.get('corporate_details') or order.metadata.get('corporate_details')
            individual_details = metadata.get('individual_details') or order.metadata.get('individual_details')

            # Initiate payment
            payment_service = PaymentService()

            result = payment_service.initiate_payment(
                user=user,
                amount=float(order.amount),
                currency=order.currency,
                country=country,
                provider_code=provider_code,
                description=f"Payment for order {order.tracking}",
                enrollment_type=enrollment_type,
                is_corporate=is_corporate,
                corporate_details=corporate_details,
                individual_details=individual_details,
                metadata={
                    **metadata,
                    'order_id': order.id,
                    'order_tracking': order.tracking,
                    'enrollment_type': enrollment_type,
                },
                payment_method=payment_method,
                phone_number=phone_number,
                redirect_url=redirect_url,
                ip_address=self._get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
            )

            transaction = result['transaction']

            # Update order with payment transaction
            order.payment_method = provider_code
            order.metadata['payment_transaction_id'] = str(transaction.id)
            order.status = 'processing'
            order.save()

            logger.info(
                f"Payment initiated for order {order.tracking}",
                extra={
                    'order_id': str(order.id),
                    'transaction_id': str(transaction.id),
                    'provider': provider_code,
                    'amount': float(order.amount),
                }
            )

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
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            logger.error(f"Unexpected error initiating payment: {str(e)}", exc_info=True)